-- Setting-Core.lua：AddUI 新设置界面核心（已在 toc 中加载，替代 Options.lua）
-- 负责：
--   1. 创建设置页面（插件名、/ad /addui 命令、Settings 分类）
--   2. 左右布局（左侧标签栏 + 右侧内容区）
--   3. 提供所有行构建工具（类似 PlateColor 的 API-Options.lua），供 Setting.lua 构建右侧滚动菜单
--
-- 结构：
--   上方：基础设施 + 页面构建
--   下方：ns.Add* 行构建 API（Setting.lua 使用）
local addonName, ns = ...

-- ═══════════════════════════════════════════════════════════════════
-- 基础设施（页面构建与 API 共用）
-- ═══════════════════════════════════════════════════════════════════
local Cur = {}  -- 当前正在构建的标签上下文：Cur.content（右侧内容框）、Cur.y（标签序号）

-- 每个标签页的行计数器（key = 标签序号）
ns.RowCount = {}

-- 标签页注册表（由 Setting.lua 通过 ns.AddSettingsTab 填充）
ns.SettingsTabs = {}

-- 懒构建：frame 首次显示时才执行 builder（只执行一次）
function ns.LazyBuild(frame, builder)
	local built = false
	frame:HookScript("OnShow", function()
		if built then return end
		built = true
		builder()
	end)
end

-- 滚动内容构造（每个标签一个）
local function NewScrollContent(tabFrame)
	local scroll = CreateFrame("ScrollFrame", nil, tabFrame, "ScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", 0, -2)
	scroll:SetPoint("BOTTOMRIGHT", tabFrame, "BOTTOMRIGHT", -20, 0)
	scroll:SetScript("OnMouseWheel", function(self, value)
		local step = 35
		local pos = self:GetVerticalScroll()
		local range = self:GetVerticalScrollRange()
		if value > 0 then
			self:SetVerticalScroll(math.max(0, pos - step))
		else
			self:SetVerticalScroll(math.min(range, pos + step))
		end
	end)
	local content = CreateFrame("Frame", nil, scroll)
	scroll:SetScrollChild(content)
	return scroll, content
end

-- ═══════════════════════════════════════════════════════════════════
-- 页面构建
-- ═══════════════════════════════════════════════════════════════════
local SettingsFrame = CreateFrame("Frame", addonName .. "SettingsFrame", UIParent)
local category = Settings.RegisterCanvasLayoutCategory(SettingsFrame, addonName)
Settings.RegisterAddOnCategory(category)

ns.LazyBuild(SettingsFrame, function()
	-- ═══════ 底部：联系方式（左）+ 重载（右）═══════
	local qqun = SettingsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	qqun:SetPoint("BOTTOMLEFT", SettingsFrame, "BOTTOMLEFT", 0, -28)
	qqun:SetJustifyH("LEFT")
	if ns.Contact then qqun:SetText(ns.Contact) else qqun:Hide() end

	local reload = CreateFrame("Button", addonName .. "rl", SettingsFrame, "UIPanelButtonTemplate")
	reload:SetText("重载")
	reload:SetWidth(92)
	reload:SetHeight(22)
	reload:SetPoint("BOTTOMRIGHT", SettingsFrame, "BOTTOMRIGHT", -132, -31)
	reload:SetScript("OnClick", function()
		ReloadUI()
	end)

	-- ═══════ 上部分标题 ═══════
	local divider = SettingsFrame:CreateTexture(nil, "ARTWORK")
	divider:SetPoint("TOPLEFT", SettingsFrame, "TOPLEFT", -14, -42)
	divider:SetPoint("TOPRIGHT", SettingsFrame, "TOPRIGHT", 0, -42)
	divider:SetHeight(1)
	divider:SetColorTexture(1, 1, 1, 0.3)

	local title = SettingsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("BOTTOMLEFT", divider, "TOPLEFT", 10, 0)
	title:SetFontHeight(33)
	title:SetText(addonName)

	local subtitle = SettingsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	subtitle:SetPoint("BOTTOMLEFT", divider, "TOPLEFT", 110, 5)
	if ns.Subtitle then subtitle:SetText(ns.Subtitle) else subtitle:Hide() end

	local versionText = SettingsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	versionText:SetPoint("BOTTOMRIGHT", divider, "TOPRIGHT", 0, 3)
	versionText:SetTextColor(0.8, 0.8, 0.8)
	versionText:SetText("版本: |cff00FFFF"..(C_AddOns.GetAddOnMetadata(addonName, "Version") or "").."|r")

	-- ═══════ 搜索框（可搜索左侧标签名或右侧设置内容）═══════
	local searchBox = CreateFrame("EditBox", nil, SettingsFrame, "SearchBoxTemplate")
	searchBox:SetPoint("TOPLEFT", SettingsFrame, "TOPLEFT", 0, -50)
	searchBox:SetWidth(230)
	searchBox:SetHeight(22)

	-- ═══════ 主体：左标签栏 + 右内容区 ═══════
	local mainBG = CreateFrame("Frame", nil, SettingsFrame, "BackdropTemplate")
	mainBG:SetPoint("TOPLEFT", SettingsFrame, "TOPLEFT", -14, -78)
	mainBG:SetPoint("BOTTOMRIGHT", SettingsFrame, "BOTTOMRIGHT", 0, 0)
	mainBG:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background" })
	mainBG:SetBackdropColor(0, 0, 0, 0.55)

	-- 左侧标签栏（可滚动，无滚动条）
	local tabBar = CreateFrame("ScrollFrame", nil, mainBG)
	tabBar:SetPoint("TOPLEFT", mainBG, "TOPLEFT", 2, -2)
	tabBar:SetPoint("BOTTOMLEFT", mainBG, "BOTTOMLEFT", 2, 2)
	tabBar:SetWidth(116)
	local tabBarBG = tabBar:CreateTexture(nil, "BACKGROUND")
	tabBarBG:SetAllPoints(tabBar)
	tabBarBG:SetColorTexture(0, 0, 0, 0.3)
	local tabBarContent = CreateFrame("Frame", nil, tabBar)
	tabBarContent:SetSize(116, 10)
	tabBar:SetScrollChild(tabBarContent)
	tabBar:SetScript("OnMouseWheel", function(self, value)
		local step = 30
		local pos = self:GetVerticalScroll()
		local range = self:GetVerticalScrollRange()
		if value > 0 then
			self:SetVerticalScroll(math.max(0, pos - step))
		else
			self:SetVerticalScroll(math.min(range, pos + step))
		end
	end)

	-- 右侧内容区
	local rightRegion = CreateFrame("Frame", nil, mainBG)
	rightRegion:SetPoint("TOPLEFT", tabBar, "TOPRIGHT", 0, 0)
	rightRegion:SetPoint("BOTTOMRIGHT", mainBG, "BOTTOMRIGHT", -2, 2)

	-- ═══════ 构建所有标签页 + 左侧标签按钮 ═══════
	local tabs = ns.SettingsTabs
	local tabButtons = {}
	-- 定位左侧标签按钮到第 y 行（清除原有锚点）
	local function SetTabButtonPos(btn, y)
		btn:ClearAllPoints()
		btn:SetPoint("TOPLEFT", tabBarContent, "TOPLEFT", 4, -4 - y * 30)
		btn:SetSize(tabBarContent:GetWidth() - 8, 26)
	end
	local selected = 1
	-- 搜索栏右边：提示文本 + "设置"按钮（MDTimer 现代风格，一键勾选本页面所有选项）
	local toggleAllOn = false
	local toggleBtn = CreateFrame("Button", nil, SettingsFrame)
	toggleBtn:SetSize(56, 22)
	toggleBtn:SetNormalFontObject("GameFontNormal")
	toggleBtn:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]])
	toggleBtn:SetPoint("TOPRIGHT", SettingsFrame, "TOPRIGHT", -30, -50)
	toggleBtn:SetText("设置")
	local toggleLabel = SettingsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	toggleLabel:SetPoint("RIGHT", toggleBtn, "LEFT", -6, 0)
	toggleLabel:SetJustifyH("RIGHT")
	toggleLabel:SetText("一键勾选本页面所有选项")
	toggleBtn.bg = toggleBtn:CreateTexture(nil, "BACKGROUND")
	toggleBtn.bg:SetAllPoints()
	toggleBtn.bg:SetColorTexture(0.2, 0.2, 0.2, 0.7)
	toggleBtn:SetScript("OnEnter", function()
		if toggleBtn:IsEnabled() then toggleBtn.bg:SetColorTexture(0.35, 0.35, 0.35, 0.9) end
	end)
	toggleBtn:SetScript("OnLeave", function()
		if toggleBtn:IsEnabled() then toggleBtn.bg:SetColorTexture(0.2, 0.2, 0.2, 0.7) end
	end)
	local function UpdateToggleButton()
		local tab = tabs[selected]
		local hasCheck = tab and tab.hasCheck
		local fs = toggleBtn:GetFontString()
		if hasCheck then
			toggleBtn:SetEnabled(true)
			toggleBtn.bg:SetColorTexture(0.2, 0.2, 0.2, 0.7)
			if fs then fs:SetTextColor(1, 0.82, 0) end  -- 金色：与右侧选项文字一致
			toggleLabel:SetTextColor(1, 1, 1)
		else
			toggleBtn:SetEnabled(false)
			toggleBtn.bg:SetColorTexture(0.3, 0.3, 0.3, 0.5)  -- 灰色底：无勾选
			if fs then fs:SetTextColor(0.5, 0.5, 0.5) end  -- 按钮文字变灰
			toggleLabel:SetTextColor(0.5, 0.5, 0.5)
		end
	end
	toggleBtn:SetScript("OnClick", function()
		local tab = tabs[selected]
		if not tab or not tab.hasCheck then return end
		toggleAllOn = not toggleAllOn
		local on = not toggleAllOn  -- 第一下=关闭，第二下=开启
		for _, row in ipairs(tab.rows) do
			if row.check then
				row.check:SetChecked(on)
				if row.db then ns.DB[row.db] = on end
			end
		end
		-- 重新应用依赖关系（master 被改到则从属项随之变灰/恢复）
		for _, fn in ipairs(tab.depUpdates or {}) do fn() end
	end)
	local function SelectTab(idx)
		selected = idx
		toggleAllOn = false
		for i, tab in ipairs(tabs) do
			if tab.frame then tab.frame:SetShown(i == idx) end
			local btn = tabButtons[i]
			if btn then
				btn.selected = (i == idx)
				local fs = btn.fs
				if fs then
					if btn.selected then
						fs:SetTextColor(1, 0.82, 0)
						btn.bg:SetColorTexture(1, 1, 1, 0.15)
					else
						fs:SetTextColor(0.9, 0.9, 0.9)
						btn.bg:SetColorTexture(0, 0, 0, 0)
					end
				end
			end
		end
		UpdateToggleButton()
	end

	for i, tab in ipairs(tabs) do
		-- 标签页内容框
		local tf = CreateFrame("Frame", nil, rightRegion)
		tf:SetAllPoints(rightRegion)
		tab.frame = tf

		local scroll, content = NewScrollContent(tf)
		tab.scroll, tab.content = scroll, content

		-- 设置当前构建上下文 + 行计数器/行表初始化，再构建
		Cur.content = content
		Cur.y = i
		ns.RowCount[i] = 0
		Cur.rows = {}
		Cur.dependencies = {}
		Cur.maxContentHeight = nil
		local ok, err = pcall(tab.build)
		if not ok then
			print("|cffff0000["..addonName.."]|r 设置界面 ["..tab.name.."] 构建出错: " .. tostring(err))
		end
		tab.rows = Cur.rows
		tab.maxContentHeight = Cur.maxContentHeight or 0
		-- 记录该标签是否含勾选框（决定"全部开启/关闭"按钮是否可点）
		tab.hasCheck = false
		for _, row in ipairs(tab.rows) do
			if row.check then tab.hasCheck = true break end
		end
		-- 挂接依赖控制：master 勾选框控制 dependent 行的启用/禁用
		for _, dep in ipairs(Cur.dependencies or {}) do
			local masterRow = nil
			local dependentRows = {}
			for _, row in ipairs(tab.rows) do
				if row.db == dep.master then masterRow = row end
			end
			for _, rdb in ipairs(dep.dependents) do
				for _, row in ipairs(tab.rows) do
					if row.db == rdb then table.insert(dependentRows, row) end
				end
			end
			-- 从属行标题往右缩进，以示层级
			for _, r in ipairs(dependentRows) do
				if r.text and not r.indented then
					r.text:ClearAllPoints()
					r.text:SetPoint("LEFT", r.frame, "LEFT", 36, 0)
					r.indented = true
				end
			end
			if masterRow and masterRow.check then
				local function Update()
					local enabled = masterRow.check:GetChecked()
					for _, r in ipairs(dependentRows) do
						if r.SetEnabled then r:SetEnabled(enabled) end
					end
				end
				tab.depUpdates = tab.depUpdates or {}
				table.insert(tab.depUpdates, Update)
				masterRow.check:HookScript("OnClick", Update)
				Update()
			end
		end

		-- 设置内容高度（根据行数 + 自定义文本高度）
		content:SetHeight(math.max(ns.RowCount[i] * 35 + 40, tab.maxContentHeight))

		-- 左侧标签按钮
		local btn = CreateFrame("Button", nil, tabBarContent)
		SetTabButtonPos(btn, i - 1)
		btn.bg = btn:CreateTexture(nil, "BACKGROUND")
		btn.bg:SetAllPoints(btn)
		btn.bg:SetColorTexture(0, 0, 0, 0)
		local fs = btn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		fs:SetPoint("LEFT", btn, "LEFT", 12, 0)
		fs:SetText(tab.name)
		fs:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
		fs:SetTextColor(0.9, 0.9, 0.9)
		btn.fs = fs
		btn:SetScript("OnClick", function() SelectTab(i) end)
		btn:SetScript("OnEnter", function()
			if not btn.selected then btn.bg:SetColorTexture(1, 1, 1, 0.08) end
		end)
		btn:SetScript("OnLeave", function()
			if not btn.selected then btn.bg:SetColorTexture(0, 0, 0, 0) end
		end)
		tabButtons[i] = btn
		tab.button = btn

		tf:Hide()
	end
	tabBarContent:SetHeight(#tabs * 30 + 10)
	SelectTab(1)

	-- ═══════ 搜索过滤 ═══════
	local function ApplyFilter(query)
		query = query and strlower(query) or ""
		if query == "" then
			-- 清空搜索：恢复所有行与标签按钮
			for i, tab in ipairs(tabs) do
				for _, row in ipairs(tab.rows or {}) do
					if row.restore then row.restore() end
					row.frame:Show()
				end
				tab.content:SetHeight(math.max(ns.RowCount[i] * 35 + 40, tab.maxContentHeight or 0))
				if tab.button then
					SetTabButtonPos(tab.button, i - 1)
					tab.button:Show()
				end
			end
			tabBarContent:SetHeight(#tabs * 30 + 10)
			tabBar:SetVerticalScroll(0)
			SelectTab(selected)
			return
		end
		-- 判断每个标签是否命中（标签名 或 行名称/鼠标提示），保留命中的标签
		local firstVisible = nil
		for i, tab in ipairs(tabs) do
			local m = false
			if tab.searchable ~= false then
				if strfind(strlower(tab.name), query, 1, true) ~= nil then
					m = true
				elseif tab.extraSearch and strfind(strlower(tab.extraSearch), query, 1, true) ~= nil then
					m = true
				else
					for _, row in ipairs(tab.rows or {}) do
						if strfind(strlower(row.searchText), query, 1, true) ~= nil then
							m = true
							break
						end
					end
				end
			end
			tab.matching = m
			if tab.matching and firstVisible == nil then firstVisible = i end
		end
		-- 左侧标签按钮：隐藏未命中，命中的重新堆叠
		local y = 0
		for i, tab in ipairs(tabs) do
			if tab.matching and tab.button then
				SetTabButtonPos(tab.button, y)
				tab.button:Show()
				y = y + 1
			elseif tab.button then
				tab.button:Hide()
			end
		end
		tabBarContent:SetHeight(math.max(y, 1) * 30 + 10)
		-- 显示命中的标签并过滤其行内容
		SelectTab(firstVisible or 1)
		for i, tab in ipairs(tabs) do
			if tab.noRowFilter then
				-- 特殊标签（如配置）：整页显示，不缩行、不改内容高度
				tab.content:SetHeight(math.max(ns.RowCount[i] * 35 + 40, tab.maxContentHeight or 0))
			else
				local yy = 0
				for _, row in ipairs(tab.rows or {}) do
					local matched = tab.matching
						and (strfind(strlower(tab.name), query, 1, true) ~= nil
							or strfind(strlower(row.searchText), query, 1, true) ~= nil)
					if matched then
						row.setY(yy)
						row.frame:Show()
						yy = yy + 1
					else
						row.frame:Hide()
					end
				end
				tab.content:SetHeight(yy * 35 + 40)
			end
		end
	end
	searchBox:HookScript("OnTextChanged", function(self)
		ApplyFilter(self:GetText())
	end)

	-- 首次显示后校正内容宽度（保证右侧对齐滚动区宽度）
	local attempts = 0
	local function Init()
		attempts = attempts + 1
		if SettingsFrame:GetWidth() <= 1 or SettingsFrame:GetHeight() <= 1 then
			SettingsFrame:SetSize(680, 540)
		end
		local needRetry = false
		for i, tab in ipairs(tabs) do
			local w = tab.scroll:GetWidth()
			if w and w > 10 then
				tab.content:SetWidth(w)
			else
				needRetry = true
			end
		end
		if needRetry and attempts < 20 then
			C_Timer.After(0.1, Init)
		end
	end
	C_Timer.After(0, Init)
end)

-- ═══════════════════════════════════════════════════════════════════
-- ns.Add* 行构建 API（类似 PlateColor 的 API-Options.lua，数据读写使用 ns.DB，可复用）
-- 通过隐式"当前构建上下文"（Cur）工作：AddSettingsTab 构建某个标签时，
-- Setting.lua 里的行调用无需再传 content、y 参数。
-- ═══════════════════════════════════════════════════════════════════

-- 标签页注册（由 Setting.lua 调用；build 无参数，内部直接使用下方行工具）
function ns.AddTab(name, build)
	local t = { name = name, build = build }
	table.insert(ns.SettingsTabs, t)
	return t
end

-- 悬停高亮 + 鼠标提示（背景半透明白高亮）
local function SetRowHover(frame, bg, tip, owner)
	frame:SetScript("OnEnter", function()
		bg:SetColorTexture(0.5, 0.5, 0.5, 0.2)
		if tip then
			GameTooltip:SetOwner(owner or frame, "ANCHOR_TOP")
			GameTooltip:AddLine("|cffFFFFFF"..tip.."|r")
			GameTooltip:Show()
		end
	end)
	frame:SetScript("OnLeave", function()
		bg:SetColorTexture(0, 0, 0, 0)
		if tip then GameTooltip:Hide() end
	end)
end

-- 登记一行（或标题）到当前标签的行表，用于搜索过滤
-- 记录 setY（过滤时按新序号重排）与 restore（恢复原位），并捕获创建时的父内容框
local function RegisterRow(frame, isTitle, ox, originalIndex)
	local parent = Cur.content
	local row = { frame = frame, isTitle = isTitle, searchText = "", enabled = true }
	row.setY = function(y)
		frame:ClearAllPoints()
		if isTitle then
			frame:SetPoint("TOPLEFT", parent, "TOPLEFT", ox, -12 + y * -35)
		else
			frame:SetPoint("TOPLEFT", parent, "TOPLEFT", ox, -8 + y * -35)
			frame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -ox, -8 + y * -35)
		end
	end
	row.restore = function() row.setY(originalIndex) end
	-- 启用/禁用该行（禁用控件 + 置灰文本/数值 + 整行变暗，更直观）
	row.SetEnabled = function(self, flag)
		self.enabled = flag
		if self.control and self.control.SetEnabled then
			self.control:SetEnabled(flag)
		end
		if self.text then
			if flag then
				self.text:SetTextColor(1, 0.82, 0)
			else
				self.text:SetTextColor(0.5, 0.5, 0.5)
			end
		end
		if self.righttext then
			if flag then
				self.righttext:SetTextColor(0, 1, 0)
			else
				self.righttext:SetTextColor(0.4, 0.4, 0.4)
			end
		end
		if self.frame then
			self.frame:SetAlpha(flag and 1 or 0.45)
		end
	end
	table.insert(Cur.rows, row)
	return row
end

-- 行框架（PlateColor 样式：悬停高亮 + 左侧金色文本）
local function NewRow()
	local rowFrame = CreateFrame("Frame", nil, Cur.content)
	rowFrame:SetHeight(26)
	local idx = ns.RowCount[Cur.y]
	local top = -8 + idx * -35
	rowFrame:SetPoint("TOPLEFT", Cur.content, "TOPLEFT", 8, top)
	rowFrame:SetPoint("TOPRIGHT", Cur.content, "TOPRIGHT", -8, top)
	local bg = rowFrame:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints(rowFrame)
	bg:SetColorTexture(0, 0, 0, 0)
	local lefttext = rowFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	lefttext:SetPoint("LEFT", rowFrame, "LEFT", 16, 0)
	lefttext:SetText("")
	lefttext:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
	lefttext:SetTextColor(1, .82, 0)
	rowFrame.__row = RegisterRow(rowFrame, false, 8, idx)
	rowFrame.__row.text = lefttext
	ns.RowCount[Cur.y] = ns.RowCount[Cur.y] + 1
	return rowFrame, bg, lefttext
end

-- 分类标题
function ns.AddSection(text)
	local t = Cur.content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	local idx = ns.RowCount[Cur.y]
	t:SetPoint("TOPLEFT", Cur.content, "TOPLEFT", 10, -12 + idx * -35)
	t:SetText(text)
	t:SetFont(STANDARD_TEXT_FONT, 20, "OUTLINE")
	t:SetTextColor(1, 1, 1)
	RegisterRow(t, true, 10, idx).searchText = text
	ns.RowCount[Cur.y] = ns.RowCount[Cur.y] + 1
	return t
end

-- 勾选框
-- name: 行名称  tip: 提示  db: DB字段  setfun: (可选)点击后回调，收到勾选状态 checked
function ns.AddCheck(name, tip, db, setfun)
	local rowFrame, bg, lefttext = NewRow()
	lefttext:SetText(name)
	rowFrame.__row.searchText = name .. " " .. (tip or "")
	rowFrame.__row.db = db
	rowFrame:EnableMouse(true)
	SetRowHover(rowFrame, bg, tip)
	local check = CreateFrame("CheckButton", nil, rowFrame, "InterfaceOptionsCheckButtonTemplate")
	check:SetPoint("RIGHT", rowFrame, "RIGHT", -8, 0)
	check:SetSize(30, 30)
	check:SetChecked(ns.DB[db])
	check:SetScript("OnClick", function()
		ns.DB[db] = check:GetChecked()
		if InCombatLockdown() then return end
		if setfun then setfun(check:GetChecked()) end
	end)
	rowFrame.__row.check = check
	rowFrame.__row.control = check
	SetRowHover(check, bg, tip, rowFrame)
	return { text = lefttext, check = check }
end

-- 滑动条（右侧绿色数值）
function ns.AddSlider(name, tip, min, max, step, fmt, db, setfun)
	local rowFrame, bg, lefttext = NewRow()
	lefttext:SetText(name)
	rowFrame.__row.searchText = name .. " " .. (tip or "")
	rowFrame.__row.db = db
	rowFrame:EnableMouse(true)
	SetRowHover(rowFrame, bg, tip)
	local slider = CreateFrame("Slider", nil, rowFrame, "MinimalSliderWithSteppersTemplate")
	slider:SetPoint("RIGHT", rowFrame, "RIGHT", -2, 0)
	slider:SetSize(230, 20)
	local righttext = rowFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	righttext:SetPoint("RIGHT", slider, "LEFT", -10, 0)
	righttext:SetFont(STANDARD_TEXT_FONT, 15, "OUTLINE")
	righttext:SetTextColor(0, 1, 0)
	righttext:SetText(string.format(fmt, ns.DB[db] or min))
	slider:Init(ns.DB[db] or min, min, max, (max - min) / (step or 1))
	slider:RegisterCallback("OnValueChanged", function(self, value)
		value = tonumber(string.format(fmt, value))
		righttext:SetText(string.format(fmt, value))
		ns.DB[db] = value
		if InCombatLockdown() then return end
		if setfun then setfun(value) end
	end)
	SetRowHover(slider.Slider or slider, bg, tip, rowFrame)
	SetRowHover(slider.Back or slider, bg, tip, rowFrame)
	SetRowHover(slider.Forward or slider, bg, tip, rowFrame)
	rowFrame.__row.control = slider
	rowFrame.__row.righttext = righttext
	return { check = slider, text = lefttext, righttext = righttext }
end

-- 下拉菜单（简单单选）
function ns.AddDropdown(name, tip, opts, db, setfun)
	local rowFrame, bg, lefttext = NewRow()
	lefttext:SetText(name)
	rowFrame.__row.searchText = name .. " " .. (tip or "")
	rowFrame:EnableMouse(true)
	SetRowHover(rowFrame, bg, tip)
	local dd = CreateFrame("DropdownButton", nil, rowFrame, "WowStyle1DropdownTemplate")
	dd:SetPoint("RIGHT", rowFrame, "RIGHT", -8, 0)
	dd:SetWidth(170)
	local function IsSelected(v) return v == ns.DB[db] end
	local function SetSelected(v)
		ns.DB[db] = v
		if setfun then setfun(v) end
	end
	rowFrame.__row.db = db
	rowFrame.__row.control = dd
	MenuUtil.CreateRadioMenu(dd, IsSelected, SetSelected, unpack(opts))
	SetRowHover(dd, bg, tip, rowFrame)
	return { text = lefttext, control = dd }
end

-- 读取位域 CVar 的单个位
local function GetCVarBit(cvar, bitIndex)
	local mask = 0
	for i = 1, 8 do
		if CVarCallbackRegistry:GetCVarBitfieldIndex(cvar, i) then
			mask = bit.bor(mask, bit.lshift(1, i - 1))
		end
	end
	return bit.band(mask, bit.lshift(1, bitIndex - 1)) ~= 0
end

-- 写入位域 CVar 的单个位
local function SetCVarBit(cvar, bitIndex, enabled)
	local mask = 0
	for i = 1, 8 do
		if CVarCallbackRegistry:GetCVarBitfieldIndex(cvar, i) then
			mask = bit.bor(mask, bit.lshift(1, i - 1))
		end
	end
	if enabled then
		mask = bit.bor(mask, bit.lshift(1, bitIndex - 1))
	else
		mask = bit.band(mask, bit.bnot(bit.lshift(1, bitIndex - 1)))
	end
	CVarCallbackRegistry:SetCVarBitfieldMask(cvar, mask)
end

-- 基于 CVar 的勾选框（不保存到 DB，状态由 CVar 决定，自动同步外部变化）
-- cvarName: CVar 名称  enumValue: (可选)位域 CVar 的位索引，传则按位读写
-- setfun: (可选)切换后回调，收到 checked
function ns.AddCVarCheck(name, tip, cvarName, enumValue, setfun)
	if not C_CVar.GetCVar(cvarName) then return end
	local rowFrame, bg, lefttext = NewRow()
	lefttext:SetText(name)
	rowFrame.__row.searchText = name .. " " .. (tip or "")
	rowFrame:EnableMouse(true)
	SetRowHover(rowFrame, bg, tip)
	local check = CreateFrame("CheckButton", nil, rowFrame, "InterfaceOptionsCheckButtonTemplate")
	check:SetPoint("RIGHT", rowFrame, "RIGHT", -8, 0)
	check:SetSize(30, 30)
	local function GetState()
		if enumValue then
			return GetCVarBit(cvarName, enumValue)
		else
			return C_CVar.GetCVar(cvarName) == "1"
		end
	end
	check:SetChecked(GetState())
	check:SetScript("OnClick", function()
		local checked = check:GetChecked()
		if enumValue then
			SetCVarBit(cvarName, enumValue, checked)
		else
			C_CVar.SetCVar(cvarName, checked and "1" or "0")
		end
		if InCombatLockdown() then return end
		if setfun then setfun(checked) end
	end)
	SetRowHover(check, bg, tip, rowFrame)
	rowFrame.__row.db = cvarName
	rowFrame.__row.control = check
	CVarCallbackRegistry:RegisterCallback(cvarName, function()
		check:SetChecked(GetState())
	end)
	return { text = lefttext, check = check }
end

-- 基于 CVar 的滑条（不保存到 DB，值由 CVar 决定，自动同步外部变化）
-- cvarName: CVar 名称  setfun: (可选)值变化后回调，收到当前值
function ns.AddCVarSlider(name, tip, min, max, step, fmt, cvarName, setfun)
	if not C_CVar.GetCVar(cvarName) then return end
	local rowFrame, bg, lefttext = NewRow()
	lefttext:SetText(name)
	rowFrame.__row.searchText = name .. " " .. (tip or "")
	rowFrame:EnableMouse(true)
	SetRowHover(rowFrame, bg, tip)
	local slider = CreateFrame("Slider", nil, rowFrame, "MinimalSliderWithSteppersTemplate")
	slider:SetPoint("RIGHT", rowFrame, "RIGHT", -2, 0)
	slider:SetSize(230, 20)
	local righttext = rowFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	righttext:SetPoint("RIGHT", slider, "LEFT", -10, 0)
	righttext:SetFont(STANDARD_TEXT_FONT, 15, "OUTLINE")
	righttext:SetTextColor(0, 1, 0)
	local function GetValue()
		return tonumber(C_CVar.GetCVar(cvarName)) or min
	end
	local function Refresh(v)
		righttext:SetText(string.format(fmt, v))
	end
	slider:Init(GetValue(), min, max, (max - min) / (step or 1))
	Refresh(GetValue())
	slider:RegisterCallback("OnValueChanged", function(self, value)
		value = tonumber(string.format(fmt, value))
		Refresh(value)
		if InCombatLockdown() then return end
		C_CVar.SetCVar(cvarName, value)
		if setfun then setfun(value) end
	end)
	SetRowHover(slider.Slider or slider, bg, tip, rowFrame)
	SetRowHover(slider.Back or slider, bg, tip, rowFrame)
	SetRowHover(slider.Forward or slider, bg, tip, rowFrame)
	rowFrame.__row.db = cvarName
	rowFrame.__row.control = slider
	rowFrame.__row.righttext = righttext
	CVarCallbackRegistry:RegisterCallback(cvarName, function()
		local v = GetValue()
		slider:SetValue(v)
		Refresh(v)
	end)
	return { check = slider, text = lefttext, righttext = righttext }
end

-- 依赖控制：masterDb 勾选框控制一组行（按 DB 字段）的启用/禁用
-- 在标签 build 内调用；masterDb 未勾选时，dependents 对应的行不可点击并置灰
function ns.AddDep(masterDb, dependents)
	table.insert(Cur.dependencies, { master = masterDb, dependents = dependents })
end

-- 判断纹理路径是否属于本插件自带（按插件名过滤目录）
local function IsOwnTexture(path)
	if not path or path == "" then return false end
	return strfind(strlower(path), strlower("\\" .. addonName .. "\\"), 1, true) ~= nil
end

-- 材质下拉（带预览纹理）
-- name: 行名称  tip: 鼠标提示  db: 保存的 DB 字段  textureTable: 纹理表 { key = 路径/图集 }
function ns.AddTexture(name, tip, db, textureTable, setfun)
	local rowFrame, bg, lefttext = NewRow()
	lefttext:SetText(name)
	rowFrame.__row.searchText = name .. " " .. (tip or "")
	rowFrame:EnableMouse(true)
	SetRowHover(rowFrame, bg, tip)
	local dd = CreateFrame("DropdownButton", nil, rowFrame, "WowStyle1DropdownTemplate")
	dd:SetPoint("RIGHT", rowFrame, "RIGHT", -8, 0)
	dd:SetWidth(170)
	-- 当前值不在表中时回退：优先默认 DB，其次取第一个非空材质
	if not textureTable[ns.DB[db]] then
		local def = ns.DB[db .. "Default"] or (ns.Defaults and ns.Defaults[db])
		if def and textureTable[def] then
			ns.DB[db] = def
		else
			for k, v in pairs(textureTable) do
				if v and v ~= "" then ns.DB[db] = k break end
			end
		end
	end
	dd:SetDefaultText(ns.DB[db])
	dd.selectTexture = dd:CreateTexture(nil, "ARTWORK")
	dd.selectTexture:SetPoint("TOPLEFT", dd, "TOPLEFT", 5, -5)
	dd.selectTexture:SetPoint("BOTTOMRIGHT", dd, "BOTTOMRIGHT", -15, 5)
	dd.selectTexture:SetVertexColor(1, 1, 1, 1)
	local function ApplyTexture(key)
		local t = textureTable[key]
		if string.match(t, "Interface\\") then
			dd.selectTexture:SetTexture(t)
		else
			dd.selectTexture:SetAtlas(t)
		end
	end
	ApplyTexture(ns.DB[db])
	local function IsSelected(v) return v == ns.DB[db] end
	local function SetSelected(v)
		ns.DB[db] = v
		dd:SetDefaultText(v)
		ApplyTexture(v)
		if setfun then setfun(v) end
	end
	local sorted = {}
	for k in pairs(textureTable) do table.insert(sorted, k) end
	table.sort(sorted)
	local function Generator(dropdown, root)
		root:SetScrollMode(400)
		for _, text in ipairs(sorted) do
			local texts = text
			if IsOwnTexture(textureTable[text]) then
				texts = "|cff00FFFF" .. text
			end
			local radio = root:CreateRadio(texts, IsSelected, SetSelected, text)
			radio:AddInitializer(function(button)
				local b = button:AttachTexture()
				b:SetSize(170, 18)
				b:SetPoint("LEFT", 15, 0)
				if string.match(textureTable[text], "Interface\\") then
					b:SetTexture(textureTable[text])
				else
					b:SetAtlas(textureTable[text])
				end
				b:SetDrawLayer("BACKGROUND")
			end)
		end
	end
	dd:SetupMenu(Generator)
	rowFrame.__row.db = db
	rowFrame.__row.control = dd
	SetRowHover(dd, bg, tip, rowFrame)
	return { text = lefttext, control = dd }
end

-- 按钮行
-- name: 行名称  tip: 提示  callback: 点击回调
function ns.AddButton(name, tip, callback)
	local rowFrame, bg, lefttext = NewRow()
	lefttext:SetText(name)
	rowFrame.__row.searchText = name .. " " .. (tip or "")
	rowFrame:EnableMouse(true)
	SetRowHover(rowFrame, bg, tip)
	local btn = CreateFrame("Button", nil, rowFrame, "UIPanelButtonTemplate")
	btn:SetPoint("RIGHT", rowFrame, "RIGHT", -8, 0)
	btn:SetSize(130, 24)
	btn:SetText(name)
	btn:SetScript("OnClick", callback)
	rowFrame.__row.control = btn
	SetRowHover(btn, bg, tip, rowFrame)
	return { text = lefttext, control = btn }
end

-- 文本显示行（多行文本，高度按内容估算；用于更新日志等）
function ns.AddLog(text)
	local idx = ns.RowCount[Cur.y]
	local top = -8 + idx * -35
	local rowFrame = CreateFrame("Frame", nil, Cur.content)
	rowFrame:SetPoint("TOPLEFT", Cur.content, "TOPLEFT", 8, top)
	rowFrame:SetPoint("TOPRIGHT", Cur.content, "TOPRIGHT", -8, top)
	local t = rowFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	t:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", 8, -4)
	t:SetPoint("BOTTOMRIGHT", rowFrame, "BOTTOMRIGHT", -8, 4)
	t:SetJustifyH("LEFT")
	t:SetJustifyV("TOP")
	t:SetWordWrap(true)
	t:SetTextColor(1, 1, 1)
	t:SetSpacing(4) -- 增加行间距，让更新日志更易读
	t:SetText(text or "")
	-- 用实际渲染高度；build 早期宽度未定时，按 SettingsFrame 布局估算宽度再测量
	local width = rowFrame:GetWidth() or (Cur.content and Cur.content:GetWidth())
	if not width or width <= 0 then
		width = (SettingsFrame and SettingsFrame:GetWidth() or 680) - 130
	end
	t:SetWidth(width - 16)
	local height = t:GetStringHeight() + 8
	height = math.max(height, 24)
	rowFrame:SetHeight(height)
	local row = RegisterRow(rowFrame, false, 8, idx)
	row.searchText = text or ""
	-- 记录内容所需最大高度（供滚动区高度计算，padding 尽量小贴合文本）
	Cur.maxContentHeight = math.max(Cur.maxContentHeight or 0, -top + height + 16)
	ns.RowCount[Cur.y] = ns.RowCount[Cur.y] + 1
	return { frame = rowFrame, text = t }
end

-- ═══════════════════════════════════════════════════════════════════
-- 核心附加标签：配置（恢复默认/导入导出）与更新日志
-- 由 Setting.lua 末尾调用 ns.BuildCoreTabs() 以排在最后
-- ═══════════════════════════════════════════════════════════════════
function ns.BuildCoreTabs()
	-- ═══════ 配置 ═══════
	local cfgTab = ns.AddTab("配置", function()
		local cf = Cur.content
		-- 导入数据中转（局部变量闭包传递，避免使用全局变量 ADDUIImportData）
		local importData
		-- 校验并合并导入的配置（缺失 key 用默认值补全，同 PlateColor 思路）
		local function ValidateAndMergeImport(importDB)
			if type(importDB) ~= "table" then return nil, "配置格式错误" end
			local hasAny = false
			for k in pairs(ns.Defaults) do
				if importDB[k] ~= nil then hasAny = true break end
			end
			if not hasAny then return nil, "配置与当前版本不匹配" end
			-- 收集导入配置缺失的字段，用默认值补全并打印
			local missing = {}
			for k, v in pairs(ns.Defaults) do
				if type(v) == "table" then
					if importDB[k] == nil then
						importDB[k] = {}
						table.insert(missing, tostring(k))
					end
					for k2, v2 in pairs(v) do
						if type(k2) ~= "number" and importDB[k][k2] == nil then
							importDB[k][k2] = v2
							table.insert(missing, tostring(k) .. "." .. tostring(k2))
						end
					end
				else
					if importDB[k] == nil then
						importDB[k] = v
						table.insert(missing, tostring(k))
					end
				end
			end
			if #missing > 0 then
				print("|cff00FFFF["..addonName.."]|r 导入配置缺失以下字段，已用默认值补全：")
				for _, m in ipairs(missing) do
					print("  |cffCCCCCC" .. m .. "|r")
				end
			end
			return importDB, nil
		end
		-- 恢复默认确认弹窗
		StaticPopupDialogs[addonName .. "CONFIG_RESET"] = {
			text = "即将恢复默认设置并重载，是否继续？",
			button1 = "重载",
			button2 = "取消",
			OnAccept = function()
				-- 恢复默认：遍历默认表，默认值为空表的字段（收藏、副本记录、冷却布局等用户数据）直接排除、保留原数据
				for k, v in pairs(ns.Defaults) do
					if type(v) == "table" and not next(v) then
						-- 空表默认字段 = 用户数据容器，保留 ns.DB 原有数据
					else
						ns.DB[k] = type(v) == "table" and CopyTable(v) or v
					end
				end
				ReloadUI()
			end,
			timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
		}
		-- 导入确认弹窗
		StaticPopupDialogs[addonName .. "CONFIG_IMPORT"] = {
			text = "即将导入配置并重载，是否继续？",
			button1 = "重载",
			button2 = "取消",
			OnAccept = function()
				if type(importData) == "table" then
					-- 导入：原地清空重填 ns.DB（保持同一引用，重载后存档才生效）
					wipe(ns.DB)
					for k, v in pairs(importData) do
						ns.DB[k] = type(v) == "table" and CopyTable(v) or v
					end
					ReloadUI()
				end
			end,
			timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
		}
		-- 多行字符串框（完全参照 PlateColor/Options/EditBox.lua 的写法）
		local box = CreateFrame("ScrollFrame", nil, cf, "InputScrollFrameTemplate")
		box:SetPoint("TOPLEFT", cf, "TOPLEFT", 15, -80)
		box:SetPoint("BOTTOMRIGHT", cf, "TOPRIGHT", -20, -500)
		local ebox = box.EditBox
		ebox:SetMultiLine(true)
		ebox:SetAutoFocus(false)
		ebox:SetFontObject("GameFontNormal")
		ebox:SetTextColor(1, 1, 1)
		ebox:SetMaxLetters(0)
		ebox:SetTextInsets(8, 8, 6, 6)
		-- 隐藏字符计数（避免 SetMaxLetters(0) 显示成负数，如 -30742）
		if box.CharCount then box.CharCount:Hide() end
		-- 点击输入框内时全选文本（方便一键复制）
		ebox:SetScript("OnEditFocusGained", function(self)
			self:HighlightText()
		end)
		-- 创建时 cf 内容区可能尚未布局（GetWidth 为 0），需延迟到尺寸确定后再设宽度；
		-- 高度由多行文本自动决定才能产生滚动范围（若锁死高度则无法滚动）
		local function SizeEBox()
			local w = box:GetWidth()
			if w > 0 then ebox:SetWidth(w - 20) end
		end
		box:SetScript("OnSizeChanged", SizeEBox)
		box:SetScript("OnShow", SizeEBox)
		local function MakeBtn(text, callback)
			local btn = CreateFrame("Button", nil, cf, "UIPanelButtonTemplate")
			btn:SetText(text)
			btn:SetSize(110, 24)
			btn:SetScript("OnClick", callback)
			return btn
		end
		-- 第一行：恢复默认
		local resetBtn = MakeBtn("恢复默认", function()
			StaticPopup_Show(addonName .. "CONFIG_RESET")
		end)
		resetBtn:SetPoint("TOPLEFT", cf, "TOPLEFT", 10, -8)
		-- 第二行：导出 / 导入
		local exportBtn = MakeBtn("导出配置", function()
			-- CBOR 直接序列化整表：保留数字键等所有 Lua 类型，无需净化；再转 Base64 便于复制分享
			ebox:SetText(C_EncodingUtil.EncodeBase64(C_EncodingUtil.SerializeCBOR(ns.DB)))
		end)
		exportBtn:SetPoint("TOPLEFT", cf, "TOPLEFT", 10, -42)
		local importBtn = MakeBtn("导入配置", function()
			-- CBOR 反序列化：Base64 解码后直接还原整表，数字键原样保留，无需额外处理
			local text = (ebox:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", "")
			local ok, data = pcall(C_EncodingUtil.DeserializeCBOR, C_EncodingUtil.DecodeBase64(text))
			if not ok then
				print("|cffff0000["..addonName.."]|r 导入失败（解析错误）：" .. tostring(data))
				return
			end
			if type(data) ~= "table" then
				print("|cffff0000["..addonName.."]|r 导入失败：字符串不是有效配置")
				return
			end
			local merged, err = ValidateAndMergeImport(data)
			if not merged then
				print("|cffff0000["..addonName.."]|r 导入失败：" .. tostring(err))
				return
			end
			importData = merged
			StaticPopup_Show(addonName .. "CONFIG_IMPORT")
		end)
		importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 8, 0)
		Cur.maxContentHeight = 430
	end)
	-- 配置标签：整页显示（不参与行过滤），可通过标签名或按钮名搜索命中
	cfgTab.extraSearch = "恢复默认 导出配置 导入配置"
	cfgTab.noRowFilter = true

	-- ═══════ 更新日志 ═══════
	local logTab = ns.AddTab("更新日志", function()
		ns.AddSection("更新记录")
		ns.AddLog(ns.UpdateText or "暂无更新记录")
	end)
	-- 更新日志不参与搜索
	logTab.searchable = false
end

-- 配置/更新日志标签需在所有标签（Setting.lua 的界面/战斗等）注册完成后才追加，
-- 否则会排在最前而非末尾。Setting-Core 先于 Setting.lua 加载，故延迟到下一帧再注册。
C_Timer.After(0, function()
	ns.BuildCoreTabs()
	-- 动态注册 slash 命令：命令字符串由 Setting.lua 通过 ns.opensetting1/2/... 提供
	local slashKey = "Open" .. addonName
	SlashCmdList[slashKey] = function()
		Settings.OpenToCategory(category:GetID())
	end
	local i = 1
	while ns["opensetting" .. i] do
		_G["SLASH_" .. slashKey .. i] = ns["opensetting" .. i]
		i = i + 1
	end
end)
