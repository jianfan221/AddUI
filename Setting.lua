-- ⚠️ 备用文件：此新设置界面暂未启用（AddUI.toc 中未加载本文件）
-- 当前正式设置界面为 Options.lua，勿在 toc 中添加本文件，以免冲突。
-- AddUI 新设置界面（滚动框架 + 搜索框 + 全部启用/关闭）
local addonName, ns = ...

local ADDUIGUI = CreateFrame("Frame", "ADDUISettingsFrame", UIParent)
local category = Settings.RegisterCanvasLayoutCategory(ADDUIGUI, "|cffff5900A|cffffb300d|cfff0ff00d|cff96ff00U|cff3cff00I|r")
Settings.RegisterAddOnCategory(category)

SlashCmdList["AddUIC"] = function()
	ns.COMBAT(Settings.OpenToCategory, category:GetID())
end
SLASH_AddUIC1 = "/ad"
SLASH_AddUIC2 = "/addui"

-- 懒构建：frame 首次显示时才执行 builder（只执行一次）
function ns.LazyBuild(frame, builder)
	local built = false
	frame:HookScript("OnShow", function()
		if built then return end
		built = true
		builder()
	end)
end

ns.LazyBuild(ADDUIGUI, function()
	-- 确保保存变量已加载（首次或异常时兜底）
	AddUIDB = AddUIDB or {}

    -- ═══════ 底部：联系方式（左）+ 恢复默认/重载（右，原位置）═══════
	local qqun = ADDUIGUI:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	qqun:SetPoint("BOTTOMLEFT", ADDUIGUI, "BOTTOMLEFT", 16, -28)
	qqun:SetText("简繁:|cff00FFFF32655163@qq.com|r      版本:|cff00FFFF"..(ns.ADDUIBB or "").."|r")
	qqun:SetJustifyH("LEFT")

	local pcrl = CreateFrame("Button", "AddUIrl", ADDUIGUI, "UIPanelButtonTemplate")
	pcrl:SetText("重载")
	pcrl:SetWidth(92)
	pcrl:SetHeight(22)
	pcrl:SetPoint("BOTTOMRIGHT", ADDUIGUI, "BOTTOMRIGHT", -132, -31)
	pcrl:SetScript("OnClick", function()
		ReloadUI()
	end)

	-- ═══════ 分割线和上部分 ═══════
	local divider = ADDUIGUI:CreateTexture(nil, "ARTWORK")
	divider:SetPoint("TOPLEFT", ADDUIGUI, "TOPLEFT", -14, -42)
	divider:SetPoint("TOPRIGHT", ADDUIGUI, "TOPRIGHT", 0, -42)
	divider:SetHeight(1)
	divider:SetColorTexture(1, 1, 1, 0.3)

    local name = ADDUIGUI:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	name:SetPoint("BOTTOMLEFT", divider, "TOPLEFT", 10, 0)
	name:SetFontHeight(33)
	name:SetText("|cffff5900A|cffffb300d|cfff0ff00d|cff96ff00U|cff3cff00I|r")

	local subtitle = ADDUIGUI:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	subtitle:SetPoint("BOTTOMLEFT", divider, "TOPLEFT", 110, 5)
	subtitle:SetText("|cff00ffd2源生界面增强|r")

	local versionText = ADDUIGUI:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	versionText:SetPoint("BOTTOMRIGHT", divider, "TOPRIGHT", 0, 3)
	versionText:SetTextColor(0.8, 0.8, 0.8)
	versionText:SetText("版本: |cff00FFFF"..(ns.ADDUIBB or "").."|r")

    local update = CreateFrame("Button", nil, ADDUIGUI, "UIPanelButtonTemplate")
	update:SetText("更新记录")
	update:SetSize(82, 22)
	update:SetPoint("TOPRIGHT", divider, "BOTTOMRIGHT", 0, 0)

	-- ═══════ 搜索框 + 全部启用/关闭 ═══════
	local searchBox = CreateFrame("EditBox", nil, ADDUIGUI, "SearchBoxTemplate")
	searchBox:SetPoint("TOPLEFT", ADDUIGUI, "TOPLEFT", -10, -42)
    searchBox:SetWidth(230)
	searchBox:SetHeight(22)

    local enableAll = CreateFrame("Button", nil, ADDUIGUI, "UIPanelButtonTemplate")
	enableAll:SetText("全部启用")
	enableAll:SetSize(82, 22)
	enableAll:SetPoint("LEFT", searchBox, "RIGHT", 10, 0)

	local disableAll = CreateFrame("Button", nil, ADDUIGUI, "UIPanelButtonTemplate")
	disableAll:SetText("全部关闭")
	disableAll:SetSize(82, 22)
	disableAll:SetPoint("LEFT", enableAll, "RIGHT", 6, 0)
--[[
    local clear = CreateFrame("Button", "AddUISaveButton", ADDUIGUI, "UIPanelButtonTemplate")
	clear:SetText("恢复默认并重载界面")
	clear:SetWidth(160)
	clear:SetHeight(22)
	clear:SetPoint("LEFT", disableAll, "RIGHT", 6, 0)
	clear:SetScript("OnClick", function()
		local DungeonTime = {}
		if AddUIDB.DungeonBossKill then
			DungeonTime = AddUIDB.DungeonBossKill
		end
		AddUIDB = ns.AddUIDefaultDB
		AddUIDB.DungeonBossKill = DungeonTime
		ReloadUI()
	end)]]


	-- ═══════ 滚动框架（固定坐标锚点，充满搜索框下方到底部按钮上方）═══════
	local scrollBG = CreateFrame("Frame", nil, ADDUIGUI, "BackdropTemplate")
	scrollBG:SetPoint("TOPLEFT", ADDUIGUI, "TOPLEFT", -14, -65)
	scrollBG:SetPoint("BOTTOMRIGHT", ADDUIGUI, "BOTTOMRIGHT", 0, 0)
	scrollBG:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background" })
	scrollBG:SetBackdropColor(0, 0, 0, 0.55)

	local scroll = CreateFrame("ScrollFrame", nil, ADDUIGUI, "ScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", scrollBG, "TOPLEFT", 0, 0)
	scroll:SetPoint("BOTTOMRIGHT", scrollBG, "BOTTOMRIGHT", -20, 0)
	scroll:SetScript("OnMouseWheel", function(self, value)
		local step = 24
		local pos = self:GetVerticalScroll()
		local range = self:GetVerticalScrollRange()
		if value > 0 then
			self:SetVerticalScroll(math.max(0, pos - step))
		else
			self:SetVerticalScroll(math.min(range, pos + step))
		end
	end)

	local content = CreateFrame("Frame", nil, scroll)
	-- 用明确尺寸确保内容显示；宽度在 Init 里动态同步滚动区宽度（保证右侧对齐）
	content:SetSize(600, 1)
	scroll:SetScrollChild(content)

	local rowHeight = 30
	local rows = {}
	local checkRows = {}

	-- 条目构造器（每行左侧统一显示一个合并文本，弃掉鼠标提示）
	local function AddCheckRow(text, db)
		local row = { type = "check", text = text, db = db, searchText = text }
		table.insert(rows, row)
		table.insert(checkRows, row)
	end
	local function AddSliderRow(text, db, min, max, step, formatter, onChanged)
		table.insert(rows, { type = "slider", text = text, db = db, min = min, max = max, step = step, formatter = formatter, onChanged = onChanged, searchText = text })
	end
	local function AddDropdownRow(text, setup)
		table.insert(rows, { type = "dropdown", text = text, setup = setup, searchText = text })
	end

	-- ═══════ 选项定义 ═══════
	-- 勾选框（左侧显示合并后的说明文本）
	AddCheckRow("改变头像样式", "unitf")
	AddCheckRow("改变动作条样式", "mmb")
	AddCheckRow("禁用动作条的施法进度+指向技能圆圈+被断变红", "mmba")
	AddCheckRow("C键面板装备栏下面的耐久度百分比", "syd")
	AddCheckRow("方形小地图", "smap")
	AddCheckRow("自动排列小地图图标,指向显示+离开时渐隐", "smapicon")
	AddCheckRow("聊天窗口样式,tab可以切换聊天频道", "chatm")
	AddCheckRow("提供一行可以切换频道的按钮", "chatb")
	AddCheckRow("此功能会导致不能传送家宅好友", "Friend")
	AddCheckRow("自动卖垃圾", "mh")
	AddCheckRow("增加拾取速度", "sq")
	AddCheckRow("改变施法条样式", "cast")
	AddCheckRow("自定义施法条材质(需启用施法条模块)", "SCastTexture")
	AddCheckRow("屏幕中间进入脱离战斗提示", "comb")
	AddCheckRow("别人密你123或者.组.会自动邀请,支持战网密语", "zu")
	AddCheckRow("预创建双击申请,自动邀请,自动进组 如果你用集合石,此项自动失效", "lfgkg")
	AddCheckRow("团队框架职责材质和鼠标指向边框", "raidframebuff")
	AddCheckRow("团队框架显示治疗吸奶盾和普通吸收盾", "raidabsorb")
	AddCheckRow("自身属性框体,编辑模式拖动位置", "stat")
	AddCheckRow("冷却管理器美化", "cdset")
	AddCheckRow("冷却管理器居中对齐,饰品药水BUFF整合", "cdcenter")
	AddCheckRow("大秘境开始时重置伤害统计", "MDRedamage")
	AddCheckRow("伤害统计样式美化", "setdama")
	AddCheckRow("伤害统计自动对齐", "poidama")
	AddCheckRow("伤害统计数值简化", "valueda")
	AddCheckRow("自动配置部分CVAR,大部分已移动至/sd命令", "cvar")
	AddCheckRow("右下角显示延迟耐久", "dimi")
	AddCheckRow("一键需求/贪婪/放弃全部装备", "autoloot")
	AddCheckRow("聊天按钮后面的log按钮", "lotbnt")
	AddCheckRow("聊天框右上角战斗战复计时器,战复在编辑模式拖动", "chatCombatTimer")
	AddCheckRow("小队打断记录,只记录打断成功的人,持续20秒,编辑模式拖动位置", "interrupt")

	-- 施法条材质（下拉，带预览纹理）
	AddDropdownRow("施法条材质", function(container)
		local dd = CreateFrame("DropdownButton", nil, container, "WowStyle1DropdownTemplate")
		dd:SetPoint("RIGHT", container, "RIGHT", -6, 0)
		dd:SetWidth(170)
		if not ns.CastBarTextrue[AddUIDB.CastTexture] then
			AddUIDB.CastTexture = ns.AddUIDefaultDB.CastTexture
		end
		dd:SetDefaultText(AddUIDB.CastTexture)
		dd.selectTexture = dd:CreateTexture(nil, "ARTWORK")
		dd.selectTexture:SetPoint("TOPLEFT", dd, "TOPLEFT", 5, -5)
		dd.selectTexture:SetPoint("BOTTOMRIGHT", dd, "BOTTOMRIGHT", -15, 5)
		dd.selectTexture:SetVertexColor(1, 1, 1, 1)
		local function ApplyTexture(key)
			local t = ns.CastBarTextrue[key]
			if string.match(t, "Interface\\") then
				dd.selectTexture:SetTexture(t)
			else
				dd.selectTexture:SetAtlas(t)
			end
		end
		ApplyTexture(AddUIDB.CastTexture)
		local function IsSelected(value) return value == AddUIDB.CastTexture end
		local function SetSelected(value)
			AddUIDB.CastTexture = value
			dd:SetDefaultText(value)
			ApplyTexture(value)
		end
		local sorted = {}
		for k in pairs(ns.CastBarTextrue) do table.insert(sorted, k) end
		table.sort(sorted)
		local function Generator(dropdown, root)
			root:SetScrollMode(400)
			for _, text in ipairs(sorted) do
				local texts = text
				if string.match(ns.CastBarTextrue[text], "PlateColor\\texture") then
					texts = "|cff00FFFF" .. text
				end
				local radio = root:CreateRadio(texts, IsSelected, SetSelected, text)
				radio:AddInitializer(function(button)
					local bg = button:AttachTexture()
					bg:SetSize(170, 18)
					bg:SetPoint("LEFT", 15, 0)
					if string.match(ns.CastBarTextrue[text], "Interface\\") then
						bg:SetTexture(ns.CastBarTextrue[text])
					else
						bg:SetAtlas(ns.CastBarTextrue[text])
					end
					bg:SetDrawLayer("BACKGROUND")
				end)
			end
		end
		dd:SetupMenu(Generator)
		return dd
	end)

	-- 鼠标提示跟随方式（下拉）
	AddDropdownRow("鼠标提示跟随方式", function(container)
		local dd = CreateFrame("DropdownButton", nil, container, "WowStyle1DropdownTemplate")
		dd:SetPoint("RIGHT", container, "RIGHT", -6, 0)
		dd:SetWidth(170)
		local opts = { { "鼠标提示:跟随", 1 }, { "鼠标提示:不跟随", 0 }, { "鼠标提示:非战斗跟随", 2 }, { "鼠标提示:禁用", 3 } }
		local function IsSelected(v) return v == AddUIDB.ftip end
		local function SetSelected(v) AddUIDB.ftip = v end
		MenuUtil.CreateRadioMenu(dd, IsSelected, SetSelected, unpack(opts))
		return dd
	end)

	-- 数值单位（下拉）
	AddDropdownRow("数值单位", function(container)
		local dd = CreateFrame("DropdownButton", nil, container, "WowStyle1DropdownTemplate")
		dd:SetPoint("RIGHT", container, "RIGHT", -6, 0)
		dd:SetWidth(170)
		local opts = { { "中文单位", 1 }, { "英文单位", 2 }, { "暴雪默认", 3 } }
		local function IsSelected(v) return v == AddUIDB.value end
		local function SetSelected(v) AddUIDB.value = v end
		MenuUtil.CreateRadioMenu(dd, IsSelected, SetSelected, unpack(opts))
		return dd
	end)

	-- 滑动条
	AddSliderRow("施法条宽度", "castWidth", 200, 400, 1, function(v) return tostring(v) end, function(v)
		AddUIDB.castWidth = v
	end)
	AddSliderRow("施法条高度", "castHeight", 10, 40, 1, function(v) return tostring(v) end, function(v)
		AddUIDB.castHeight = v
	end)
	AddSliderRow("施法序列延迟", "SpellQ", 0, 400, 1, function(v) return tostring(v) end, function(v)
		AddUIDB.SpellQ = v
		SetCVar("SpellQueueWindow", v)
	end)

	-- ═══════ 构建行 ═══════
	local function BuildRows()
		-- 通用悬停变色：鼠标进入 frame 时文本变黄，离开恢复
		local function SetHover(frame, label)
			frame:SetScript("OnEnter", function(self)
				if label then label:SetTextColor(1, 1, 0) end
			end)
			frame:SetScript("OnLeave", function(self)
				if label then label:SetTextColor(0.88, 0.88, 0.88) end
			end)
		end

		for _, row in ipairs(rows) do
			local container = CreateFrame("Frame", nil, content)
			container:SetHeight(rowHeight)
			row.container = container

			-- 左侧文本（标题与说明合并成一个文本：标题白 + 说明灰）
			-- 左侧文本：自然宽度显示（有多少显示多少，不换行）
			local label = container:CreateFontString(nil, "ARTWORK", "GameFontNormal")
			label:SetPoint("LEFT", container, "LEFT", 6, 0)
			label:SetJustifyH("LEFT")
			label:SetWordWrap(false)
			label:SetFontHeight(16)
			label:SetTextColor(0.88, 0.88, 0.88)
			label:SetText(row.text)
			row.label = label

			-- 整行悬停变色（锚定到 container）
			container:EnableMouse(true)
			SetHover(container, label)

			-- 行底分隔线
			local line = container:CreateTexture(nil, "BACKGROUND")
			line:SetHeight(1)
			line:SetColorTexture(1, 1, 1, 0.08)
			line:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 0, 0)
			line:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", 0, 0)
			row.line = line

			-- 右侧控件
			if row.type == "check" then
				local check = CreateFrame("CheckButton", nil, container, "UICheckButtonTemplate")
				check:SetPoint("RIGHT", container, "RIGHT", -12, 0)
				check:SetChecked(AddUIDB[row.db])
				check:SetScript("OnClick", function(self)
					AddUIDB[row.db] = self:GetChecked()
				end)
				-- 悬停在勾选框时文本变黄
				SetHover(check, label)
				row.check = check
			elseif row.type == "slider" then
				local slider = CreateFrame("Slider", nil, container, "MinimalSliderWithSteppersTemplate")
				slider:SetPoint("RIGHT", container, "RIGHT", 0, 0)
				slider:SetSize(340, 16)
				local valueText = container:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
				valueText:SetPoint("RIGHT", slider, "LEFT", -6, 0)
				valueText:SetFont(STANDARD_TEXT_FONT, 16, "OUTLINE")
				slider:Init(AddUIDB[row.db] or row.min, row.min, row.max, (row.max - row.min) / row.step)
				local function Refresh(v)
					v = math.floor(v)
					valueText:SetText(row.formatter and row.formatter(v) or tostring(v))
				end
				Refresh(AddUIDB[row.db] or row.min)
				slider:RegisterCallback("OnValueChanged", function(self, v)
					v = math.floor(v)
					Refresh(v)
					if row.onChanged then row.onChanged(v) end
				end)
				-- 悬停在滑动条时文本变黄（绑定到内部滑轨 slider.Slider，覆盖整条滑轨）
				SetHover(slider.Slider or slider, label)
				row.slider = slider
			elseif row.type == "dropdown" then
				row.control = row.setup(container)
				-- 悬停在下拉菜单时文本变黄
				SetHover(row.control, label)
			end
		end
	end

	-- ═══════ 过滤显示（搜索匹配标题+说明，固定行高）═══════
	local function FilterRows(query)
		query = query and strlower(query) or ""
		local y = 0
		for _, row in ipairs(rows) do
			if row.container then
				local matched = query == "" or strfind(strlower(row.searchText), query, 1, true) ~= nil
				if matched then
					row.container:ClearAllPoints()
					row.container:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
					row.container:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -y)
					row.container:Show()
					y = y + rowHeight
				else
					row.container:Hide()
				end
			end
		end
		content:SetHeight(math.max(y, 1))
		scroll:SetVerticalScroll(0)
	end

	-- 全部启用/关闭
	enableAll:SetScript("OnClick", function()
		for _, row in ipairs(checkRows) do
			AddUIDB[row.db] = true
			if row.check then row.check:SetChecked(true) end
		end
	end)
	disableAll:SetScript("OnClick", function()
		for _, row in ipairs(checkRows) do
			AddUIDB[row.db] = false
			if row.check then row.check:SetChecked(false) end
		end
	end)

	-- 用 HookScript 保留模板自带的占位文字隐藏逻辑（SearchBoxTemplate_OnTextChanged），再追加过滤
	searchBox:HookScript("OnTextChanged", function(self)
		FilterRows(self:GetText())
	end)

	-- 立即同步构建所有行（出错不中断，打印便于诊断）
	local ok, err = pcall(BuildRows)
	if not ok then
		print("|cffff0000[AddUI]|r 设置界面构建出错: " .. tostring(err))
	end

	-- 首次显示后校正滚动范围；若画布/滚动区仍无尺寸则兜底并重试
	local attempts = 0
	local function Init()
		attempts = attempts + 1
		if ADDUIGUI:GetWidth() <= 1 or ADDUIGUI:GetHeight() <= 1 then
			ADDUIGUI:SetSize(680, 540)
		end
		if scroll:GetHeight() <= 1 then
			scroll:SetHeight(400)
		end
		local w = scroll:GetWidth()
		if w and w > 10 then
			content:SetWidth(w)
		end
		FilterRows("")
		if ADDUIGUI:IsShown() then
			FilterRows(searchBox:GetText() or "")
		end
		if (scroll:GetHeight() <= 1 or content:GetHeight() <= 1 or (w ~= nil and w <= 10)) and attempts < 20 then
			C_Timer.After(0.1, Init)
		end
	end
	C_Timer.After(0, Init)
end)
