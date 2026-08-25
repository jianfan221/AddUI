local _, ns = ...

-- 自身增益监控法术列表默认值 {[法术ID]=boolean}（true=启用, false=取消；ADDON_LOADED 时由 AddUIDB 合并进 AddUIDB）
ns.AddUIDefaultDB.SelfBuffAuraList = {
    --[1263768] = true,   --光塔核心
    --[1236616] = true,   --圣光潜力
    --[1236994] = true,   --圣鲁莽药水
}

ns.tips("自身增益光环容器:监控列表中的BUFF,编辑模式拖动位置,编辑模式下右键打开列表")

-- ══════════════════════════════════════════════════════════════
-- 默认表（用户自行增删）：[法术ID] = "法术名"
-- 合并规则：用户表里没有的法术会自动补入（默认启用）；
--          用户表里已有但被取消启用的，保持不动。
-- ══════════════════════════════════════════════════════════════
ns.DefaultSelfBuffAuraList = {
	-- 12345,
}

local function MergeDefaults()
	AddUIDB.SelfBuffAuraList = AddUIDB.SelfBuffAuraList or {}
	for _, id in ipairs(ns.DefaultSelfBuffAuraList) do
		if AddUIDB.SelfBuffAuraList[id] == nil then
			AddUIDB.SelfBuffAuraList[id] = true
		end
	end
end

-- ════════════════════════ 法术名解析 ════════════════════════
local function GetSpellDisplayName(spellId)
	if not spellId then return nil end
	local spellName = C_Spell.GetSpellName(spellId)
	if spellName and spellName ~= "" then return spellName end
	local spellInfo = C_Spell.GetSpellInfo(spellId)
	if spellInfo and spellInfo.name and spellInfo.name ~= "" then
		return spellInfo.name
	end
	return nil
end

local function NormalizeSpellId(text)
	if not text then return nil end
	local spellId = tonumber(text)
	if spellId then return spellId end
	local resolvedId = C_Spell.GetSpellIDForSpellIdentifier(text)
	if resolvedId and resolvedId > 0 then return resolvedId end
	return nil
end

-- ════════════════════════ 光环容器 ════════════════════════
local container

-- 根据列表中"启用"的法术生成过滤集合
local function GetEnabledSpellIDs()
	local include = {}
	for id, enabled in pairs(AddUIDB.SelfBuffAuraList or {}) do
		if enabled ~= false then
			include[id] = true
		end
	end
	return include
end

-- 列表变化时调用：让容器按最新的启用集合过滤
function ns.UpdateSelfBuffAuraFilters()
	if container then
		container:SetAuraGroupCandidateFilters("selfBuff", { includeSpellIDs = GetEnabledSpellIDs() })
	end
end

ns.event("PLAYER_LOGIN", function()
	MergeDefaults()

	-- 外框框架（光环容器按钮尺寸），负责编辑模式拖动
	local holder = CreateFrame("Frame", "ADUISelfBuffAuraFrame", UIParent, "BackdropTemplate")
	holder:SetSize(285, 45)
	holder:SetPoint("CENTER", 0, -100)
	holder:Show()
	-- 非编辑模式下禁用鼠标并透传点击：外框无背景且常显，避免隐形拦截挡住下层 UI / 右键转视角
	holder:EnableMouse(false)
	pcall(holder.SetPropagateMouseClicks, holder, true)

	container = CreateFrame("AuraContainer", "ADUISelfBuffAura", holder, "CustomAuraContainerTemplate")
	container:SetPoint("CENTER", holder, "CENTER", 0, 0)
	container:SetUnit("player")
	-- AuraContainer 属 ScriptRegion，鼠标拦截由 SetMouseClickEnabled/SetMouseMotionEnabled 控制，标准 EnableMouse 对其无效。
	-- 非编辑模式下完全禁用鼠标并透传点击：空容器不再拦截点击，鼠标可穿透（不影响右键转视角、下层拖动）。
	-- 编辑模式拖动走 holder 外框，容器本身无需接收鼠标，故可一直保持禁用。
	container:SetMouseClickEnabled(false)
	container:SetMouseMotionEnabled(false)
	pcall(container.SetPropagateMouseClicks, container, true)

	container:AddAuraGroup("selfBuff", "HELPFUL|PLAYER", {
		maxFrameCount = 10,
		sortMethod = AuraContainerSortMethod.Expiration, -- 按到期时间排序
		sortDirection = AuraContainerSortDirection.Normal,
		initializeFrame = function(auraButton)
			auraButton:SetSize(40, 40)
			auraButton:SetTooltipAnchorPoint("ANCHOR_TOP") -- 工具提示锚点
			auraButton:SetHideTooltipInCombat(true)          -- 战斗中隐藏工具提示

			local icon = auraButton:CreateTexture(nil, "ARTWORK")
			icon:SetAllPoints(auraButton)
			icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
			auraButton:SetIcon(icon)

			local cooldown = CreateFrame("Cooldown", nil, auraButton, "CooldownFrameTemplate")
			cooldown:SetAllPoints(auraButton)
			cooldown:SetDrawBling(false)
			cooldown:SetDrawEdge(false)
			cooldown:SetReverse(true) -- 反转冷却动画方向
			auraButton:SetDurationCooldown(cooldown)

			-- 叠层数：独立 overlay 容器（层级在冷却之上，不随冷却隐藏）
			local overlay = CreateFrame("Frame", nil, auraButton)
			overlay:SetAllPoints(auraButton)
			overlay:SetFrameLevel(auraButton:GetFrameLevel() + 2)
			local count = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			count:SetPoint("BOTTOMRIGHT", auraButton, 0, 0)
			count:SetVertexColor(1, 1, 1)
			count:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
			auraButton:SetApplicationCount(count, {})
		end,
		candidateFilters = {
			includeSpellIDs = GetEnabledSpellIDs(),
		},
	})

	container:Show()

	-- 编辑模式拖动位置（拖外框），center=true 进入编辑模式自动水平居中
	ns.AddEdit(holder, "自身BUFF右键添加", true)

	-- 编辑模式下右键打开添加法术列表
	holder:SetScript("OnMouseDown", function(self, button)
		if button == "RightButton" and EditModeManagerFrame and EditModeManagerFrame:IsShown() then
			ns.OpenSelfBuffAuraList()
		end
	end)

	-- 编辑模式预览：暴雪会让 AuraContainer 改用假数据源（示例BUFF）显示预览。
	-- 但我们的 includeSpellIDs 会把这些假BUFF过滤掉 → 预览不显示。
	-- 所以在编辑模式临时去掉 includeSpellIDs 过滤，让假数据预览能显示；退出恢复。
	local function SetEditModeFilter(editing)
		if not container then return end
		if editing then
			container:SetAuraGroupCandidateFilters("selfBuff", {})
		else
			container:SetAuraGroupCandidateFilters("selfBuff", { includeSpellIDs = GetEnabledSpellIDs() })
		end
	end
	if EditModeManagerFrame then
		EditModeManagerFrame:HookScript("OnShow", function() SetEditModeFilter(true) end)
		EditModeManagerFrame:HookScript("OnHide", function() SetEditModeFilter(false) end)
	end

	-- 冷却管理器设置界面标题栏按钮：打开自身BUFF监控法术列表
	if CooldownViewerSettings and CooldownViewerSettings.TitleContainer and not CooldownViewerSettings.SelfBuffButton then
		CooldownViewerSettings.SelfBuffButton = CreateFrame("Button", nil, CooldownViewerSettings.TitleContainer, "UIPanelButtonTemplate")
		CooldownViewerSettings.SelfBuffButton:SetSize(100, 22)
		CooldownViewerSettings.SelfBuffButton:SetPoint("LEFT", CooldownViewerSettings.TitleContainer, "LEFT", 10, 0)
		CooldownViewerSettings.SelfBuffButton:SetText("自身BUFF")
		CooldownViewerSettings.SelfBuffButton:SetScript("OnClick", function()
			ns.OpenSelfBuffAuraList()
		end)
		CooldownViewerSettings.SelfBuffButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:SetText("打开自身BUFF监控法术列表")
			GameTooltip:Show()
		end)
		CooldownViewerSettings.SelfBuffButton:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end

end)

-- ════════════════════════ 法术列表窗口 ════════════════════════
local function BuildRows()
	local rows = {}
	for spellId in pairs(AddUIDB.SelfBuffAuraList or {}) do
		rows[#rows + 1] = spellId
	end
	table.sort(rows, function(a, b) return tonumber(a) < tonumber(b) end)
	return rows
end

local function MatchSearch(spellId, searchText)
	if not searchText or searchText == "" then return true end
	local spellName = GetSpellDisplayName(spellId) or ""
	local spellIdText = tostring(spellId)
	local needle = string.lower(searchText)
	return string.find(string.lower(spellIdText), needle, 1, true)
		or string.find(string.lower(spellName), needle, 1, true)
end

local function EnsureListWindow()
	if _G.ADUISelfBuffAuraList then return _G.ADUISelfBuffAuraList end

	local frame = CreateFrame("Frame", "ADUISelfBuffAuraList", UIParent, "BackdropTemplate")
	frame:SetSize(460, 420)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:SetClampedToScreen(true)
	frame:Hide()
	frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	frame:SetBackdropColor(0.08, 0.08, 0.08, 1)

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
	title:SetPoint("TOP", 0, -8)
	title:SetText("自身BUFF监控列表")

	-- 左上角：鼠标提示显示法术ID开关（勾选状态由 cvar 决定，点击临时切换不持久）
	local spellIDCheck = CreateFrame("CheckButton", nil, frame, "InterfaceOptionsCheckButtonTemplate")
	spellIDCheck:SetPoint("TOPLEFT", 8, -4)
	spellIDCheck:SetSize(30, 30)
	local function RefreshSpellIDCheck()
		spellIDCheck:SetChecked(GetCVar("tooltipShowAuraSpellIDs") == "1")
	end
	RefreshSpellIDCheck()
	spellIDCheck:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText("|cffFFFFFF鼠标提示显示法术ID|r",1,1,1,1)
		GameTooltip:Show()
	end)
	spellIDCheck:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	spellIDCheck:SetScript("OnClick", function()
		-- 点击后写入 cvar，控制"鼠标提示显示法术ID"
		C_CVar.SetCVar("tooltipShowAuraSpellIDs", spellIDCheck:GetChecked() and "1" or "0")
	end)

	-- 按钮右侧文本
	local spellIDLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	spellIDLabel:SetPoint("LEFT", spellIDCheck, "RIGHT", 2, 0)
	spellIDLabel:SetText("显示法术ID")

	-- 提示文字：位于标题下方、输入框上方
	local tip = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	tip:SetPoint("TOPLEFT", 10, -30)
	tip:SetText("输入法术ID添加,编辑模式拖动位置")

	local searchBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
	searchBox:SetSize(240, 24)
	searchBox:SetPoint("TOPLEFT", 16, -44)
	searchBox:SetAutoFocus(false)
	searchBox:SetTextInsets(8, 8, 4, 4)
	searchBox:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
		self:SetText("")
		self:GetParent():RefreshList()
	end)
	searchBox:SetScript("OnEnterPressed", function(self)
		local spellId = NormalizeSpellId(self:GetText())
		if spellId then
			local spellName = GetSpellDisplayName(spellId)
			if spellName then
				AddUIDB.SelfBuffAuraList[spellId] = true
				self:SetText("")
				self:GetParent():RefreshList()
				ns.UpdateSelfBuffAuraFilters()
				return
			end
		end
		self:ClearFocus()
		self:GetParent():RefreshList()
	end)
	searchBox:SetScript("OnTextChanged", function(self)
		self:GetParent():RefreshList()
	end)

	local addButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	addButton:SetSize(80, 24)
	addButton:SetPoint("LEFT", searchBox, "RIGHT", 10, 0)
	addButton:SetText(ADD)

	local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	closeButton:SetPoint("TOPRIGHT", 2, 2)

	local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "ScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", 16, -78)
	scrollFrame:SetPoint("BOTTOMRIGHT", -30, 16)
	local content = CreateFrame("Frame", nil, scrollFrame)
	content:SetSize(1, 1)
	scrollFrame:SetScrollChild(content)

	local headerID = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	headerID:SetPoint("TOPLEFT", 20, 0)
	headerID:SetText("ID")
	headerID:SetWidth(60)
	headerID:SetJustifyH("LEFT")

	local headerName = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	headerName:SetPoint("TOPLEFT", 95, 0)
	headerName:SetText(SPELLS .. NAME)
	headerName:SetWidth(130)
	headerName:SetJustifyH("LEFT")

	local headerEnable = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	headerEnable:SetPoint("TOPLEFT", 250, 0)
	headerEnable:SetText(ENABLE)
	headerEnable:SetWidth(55)
	headerEnable:SetJustifyH("LEFT")

	local headerAction = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	headerAction:SetPoint("TOPLEFT", 340, 0)
	headerAction:SetText(DELETE)
	headerAction:SetWidth(60)
	headerAction:SetJustifyH("LEFT")

	frame.rows = {}
	frame.searchBox = searchBox
	frame.scrollFrame = scrollFrame
	frame.content = content

	local function ClearRows()
		for _, row in ipairs(frame.rows) do
			row:Hide()
			row:SetParent(nil)
		end
		wipe(frame.rows)
	end

	function frame:RefreshList()
		ClearRows()

		local searchText = self.searchBox:GetText()
		local lastRow

		for _, spellId in ipairs(BuildRows()) do
			if MatchSearch(spellId, searchText) then
				local row = CreateFrame("Frame", nil, self.content)
				row:SetSize(400, 24)
				if lastRow then
					row:SetPoint("TOPLEFT", lastRow, "BOTTOMLEFT", 0, -4)
				else
					row:SetPoint("TOPLEFT", 0, -24)
				end

				local bg = row:CreateTexture(nil, "BACKGROUND")
				bg:SetAllPoints(row)
				bg:SetColorTexture(0.5, 0.5, 0.5, 1)

				local function SetRowHighlighted(highlighted)
					if highlighted then
						bg:SetColorTexture(0.75, 0.75, 0.75, 1)
					else
						bg:SetColorTexture(0.5, 0.5, 0.5, 1)
					end
				end

				local idText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
				idText:SetPoint("LEFT", 20, 0)
				idText:SetWidth(60)
				idText:SetJustifyH("LEFT")
				idText:SetText(tostring(spellId))

				local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
				nameText:SetPoint("LEFT", 95, 0)
				nameText:SetWidth(140)
				nameText:SetJustifyH("LEFT")
				nameText:SetText(GetSpellDisplayName(spellId) or UNKNOWN)

				local enabled = AddUIDB.SelfBuffAuraList[spellId]

				local enableCheck = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
				enableCheck:SetPoint("LEFT", 252, 0)
				enableCheck:SetSize(24, 24)
				enableCheck:SetChecked(enabled ~= false)
				enableCheck:SetScript("OnClick", function(self)
					AddUIDB.SelfBuffAuraList[spellId] = self:GetChecked()
					ns.UpdateSelfBuffAuraFilters()
				end)
				enableCheck:SetScript("OnEnter", function() SetRowHighlighted(true) end)
				enableCheck:SetScript("OnLeave", function() SetRowHighlighted(false) end)

				local deleteButton = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
				deleteButton:SetSize(55, 20)
				deleteButton:SetPoint("LEFT", 335, 0)
				deleteButton:SetText(DELETE)
				deleteButton:SetScript("OnClick", function()
					AddUIDB.SelfBuffAuraList[spellId] = nil
					frame:RefreshList()
					ns.UpdateSelfBuffAuraFilters()
				end)
				deleteButton:SetScript("OnEnter", function() SetRowHighlighted(true) end)
				deleteButton:SetScript("OnLeave", function() SetRowHighlighted(false) end)

				frame.rows[#frame.rows + 1] = row
				lastRow = row
			end
		end

		if lastRow then
			self.content:SetHeight(24 + (#frame.rows * 28))
		else
			self.content:SetHeight(48)
		end
	end

	addButton:SetScript("OnClick", function()
		local input = searchBox:GetText()
		local spellId = NormalizeSpellId(input)
		if not spellId then
			print("自身BUFF列表: " .. UNKNOWN .. SPELLS)
			return
		end
		local spellName = GetSpellDisplayName(spellId)
		if not spellName then
			print("自身BUFF列表: " .. UNKNOWN .. SPELLS)
			return
		end
		AddUIDB.SelfBuffAuraList[spellId] = true
		searchBox:SetText("")
		frame:RefreshList()
		ns.UpdateSelfBuffAuraFilters()
	end)

	frame:SetScript("OnShow", function(self)
		self:RefreshList()
		RefreshSpellIDCheck() -- 重新打开时按 cvar 恢复勾选（临时切换不持久）
	end)

	frame:RefreshList()

	_G.ADUISelfBuffAuraList = frame
	return frame
end

function ns.OpenSelfBuffAuraList()
	local frame = EnsureListWindow()
	frame:Show()
	frame:Raise()
end
