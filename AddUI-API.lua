local _,ns = ...

--判断是否是秘密值
function ns.MM(value)
	if issecretvalue(value) or issecrettable(value) then
		return true
	else
		return false
	end
end

--无用功能
ns.ADDUISET = function() end

--事件加载
local onceEvents = {
    ["PLAYER_ENTERING_WORLD"] = true,
    ["PLAYER_LOGIN"] = true,
}
function ns.event(event, handler, isOnce)--ns.event(event, handler, true)只执行一次的事件
    EventRegistry:RegisterFrameEventAndCallback(event, function(self, ...)
        if (isOnce or onceEvents[event]) and self then
            EventRegistry:UnregisterFrameEventAndCallback(event, self)
        end
        handler(event, ...)
    end)
end

ns.hook = hooksecurefunc

--脱战后执行
local postCombatQueue = {}
function ns.COMBAT(func, ...)--调用这个
	if InCombatLockdown() then
        local args = {...}
        print("正在战斗中,脱战后执行")
        table.insert(postCombatQueue, function()
            func(unpack(args))
        end)
    else
        func(...)
    end
end

ns.event("PLAYER_REGEN_ENABLED", function()
    for _, func in ipairs(postCombatQueue) do
        local success, err = pcall(func)
        if not success then
            print("执行错误:", err)
        end
    end
    wipe(postCombatQueue)
end)

--编辑模式拖动位置
-- 可选参数 center：为 true 时进入编辑模式自动水平居中
-- 防重复：以 frame.highlight 是否存在判断是否已处理（避免重复创建高亮层、重复注册编辑模式 hook）
function ns.AddEdit(frame,name,center)
    local dbName = frame:GetName() and frame:GetName().."_Edit"
    -- 先加载保存的位置（即使已处理过也重新应用，便于单独调用只加载位置）
    if dbName and AddUIDB and AddUIDB[dbName] then
        frame:ClearAllPoints()
        frame:SetPoint(unpack(AddUIDB[dbName]))
    end
    -- 防重复：已创建过高亮层则不再重复初始化
    if frame.highlight then return end
    if not dbName or not EditModeManagerFrame then
        print("编辑模式拖动位置功能缺少框体名或编辑模式框架")
        return
    end

    frame:SetClampedToScreen(true)
    frame:SetClampRectInsets(30, -30, -30, 30)

    -- 高亮层：独立高层级子框架，显示在 frame 内容之上（挂到 frame 上，重复调用只覆盖不累积）
    frame.highlight = CreateFrame("Frame", nil, frame)
    frame.highlight:SetAllPoints(frame)
    frame.highlight:SetFrameLevel(100)
    frame.highlight:Hide()

    -- 高亮材质（暴雪 editmode-actionbar 九宫格）
    local selectionLayout = {
        TopLeftCorner = { atlas = "%s-NineSlice-Corner", x = -8, y = 8 },
        TopRightCorner = { atlas = "%s-NineSlice-Corner", mirrorLayout = true, x = 8, y = 8 },
        BottomLeftCorner = { atlas = "%s-NineSlice-Corner", mirrorLayout = true, x = -8, y = -8 },
        BottomRightCorner = { atlas = "%s-NineSlice-Corner", mirrorLayout = true, x = 8, y = -8 },
        TopEdge = { atlas = "_%s-NineSlice-EdgeTop" },
        BottomEdge = { atlas = "_%s-NineSlice-EdgeBottom" },
        LeftEdge = { atlas = "!%s-NineSlice-EdgeLeft" },
        RightEdge = { atlas = "!%s-NineSlice-EdgeRight" },
        Center = { atlas = "%s-NineSlice-Center", x = -8, y = 8, x1 = 8, y1 = -8 },
    }

    frame.text = frame.highlight:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.text:SetPoint("CENTER", 0, 0)
    frame.text:SetFont("fonts\\ARHei.ttf", 30, "OUTLINE")
    frame.text:SetText(name or "AddUI")
    frame.text:SetVertexColor(1,1,1,0.7)

    -- 高亮材质切换（"selected" 选中 / "highlight" 未选中）
    local function ApplyHighlight(kit)
        pcall(NineSliceUtil.ApplyLayout, frame.highlight, selectionLayout, "editmode-actionbar-"..kit)
    end

    -- 自动水平居中（保持垂直位置）
    local function CenterFrame()
        local bottom = frame:GetBottom()
        local height = frame:GetHeight() or 0
        local X, Y = UIParent:GetWidth() / 2, bottom + height
        frame:ClearAllPoints()
        frame:SetPoint("TOP", UIParent, "BOTTOMLEFT", X, Y)
        return X, Y
    end

    -- 拖动松手后保存位置
    local function SavePosition()
        AddUIDB = AddUIDB or {}
        if center then
            local X, Y = CenterFrame()
            AddUIDB[dbName] = {"TOP", "UIParent", "BOTTOMLEFT", X, Y}
        else
            local left, bottom = frame:GetLeft(), frame:GetBottom()
            AddUIDB[dbName] = {"BOTTOMLEFT", "UIParent", "BOTTOMLEFT", left, bottom}
        end
    end

    local isshow = frame:IsShown() -- 储存框体原始显示状态
    local isalpha = frame:GetAlpha() -- 储存框体原始透明度

    local function EnterEditMode()
        frame:Show()
        frame:SetAlpha(1)
        if center and not InCombatLockdown() then
            CenterFrame()
        end
        frame.highlight:Show()
        ApplyHighlight("highlight") -- 进入编辑模式默认显示未选中高亮框
        frame.text:Hide() -- 文字默认隐藏，鼠标指向时才显示
        frame:SetMovable(true) -- frame 负责移动，frame.highlight 负责接收鼠标（层级最高，避免被内部元素遮挡拖不动）
        frame.highlight:EnableMouse(true)
        frame.highlight:RegisterForDrag("LeftButton")
        frame.highlight:SetScript("OnDragStart", function() frame:StartMoving() end)
        frame.highlight:SetScript("OnDragStop", function()
            frame:StopMovingOrSizing()
            SavePosition()
        end)
        frame.highlight:SetScript("OnEnter", function()
            ApplyHighlight("selected")
            frame.text:Show()
        end)
        frame.highlight:SetScript("OnLeave", function()
            ApplyHighlight("highlight")
            frame.text:Hide()
        end)
    end

    local function LeaveEditMode()
        frame:SetShown(isshow)
        frame:SetAlpha(isalpha)
        frame.highlight:Hide()
        frame.text:Hide()
        frame:SetMovable(false)
        frame.highlight:EnableMouse(false)
        frame.highlight:SetScript("OnDragStart", nil)
        frame.highlight:SetScript("OnDragStop", nil)
        frame.highlight:SetScript("OnEnter", nil)
        frame.highlight:SetScript("OnLeave", nil)
    end

    EditModeManagerFrame:HookScript("OnShow", EnterEditMode)
    EditModeManagerFrame:HookScript("OnHide", LeaveEditMode)

    if EditModeManagerFrame:IsShown() then
        EnterEditMode()
    end
end

--提醒文本
local adcfont = UIParent:CreateFontString("adcfont", "ARTWORK", "GameFontNormalLarge")
adcfont:SetPoint("LEFT", QuickJoinToastButton, "RIGHT", 0, -1)
adcfont:SetFont("fonts\\ARHei.ttf", 16, "OUTLINE")
adcfont:SetVertexColor(0,1,1)
local adcfontbg = UIParent:CreateTexture(nil, "BACKGROUND")
adcfontbg:SetPoint("CENTER", adcfont, "CENTER", 0, 0)
adcfontbg:SetTexture(130937)
adcfontbg:SetVertexColor(0, 0, 0, 0)

function ns.AATEXT(text)
	adcfont:SetText(text)
	adcfontbg:SetSize(adcfont:GetStringWidth() + 10, adcfont:GetStringHeight() + 10)
	
	if adcfont.fadeTimer then
        adcfont.fadeTimer:Cancel()
        adcfont.fadeTimer = nil
    end

    adcfont:SetAlpha(0)
    UIFrameFadeIn(adcfont, 0.5, 0, 1)
	UIFrameFadeIn(adcfontbg, 0.5, 0, 1)
	

    adcfont.fadeTimer = C_Timer.NewTicker(6, function()
        UIFrameFadeOut(adcfont, 1.5, 1, 0)
		UIFrameFadeOut(adcfontbg, 1.5, 1, 0)
        adcfont.fadeTimer:Cancel()
        adcfont.fadeTimer = nil
    end, 1)
end

--驱散颜色
ns.dispelColor = C_CurveUtil.CreateColorCurve()
ns.dispelColor:SetType(Enum.LuaCurveType.Step)
ns.dispelColor:AddPoint(0, CreateColor(0,  0,  0,  0))--无
ns.dispelColor:AddPoint(1, CreateColor(1,  1,  1,  1))--魔法
ns.dispelColor:AddPoint(2, CreateColor(0.5,0,  1,  1))--诅咒
ns.dispelColor:AddPoint(3, CreateColor(1,0.5,  0,  1))--疾病
ns.dispelColor:AddPoint(4, CreateColor(0,  1,  0,  1))--中毒
ns.dispelColor:AddPoint(9, CreateColor(1,  0,  0,  1))--激怒

--格式化
ns.buffFmt = C_StringUtil.CreateNumericRuleFormatter()
ns.buffFmt:AddBreakpoint({ threshold = 356400, format = "%d d", components = {{ div = 86400, step = 1, rounding = 1 }} })
ns.buffFmt:AddBreakpoint({ threshold = 5940,   format = "%d h", components = {{ div = 3600, step = 1, rounding = 1 }} })
ns.buffFmt:AddBreakpoint({ threshold = 600,    format = "%d m", components = {{ div = 60, step = 1, rounding = 1 }} })
ns.buffFmt:AddBreakpoint({ threshold = 60,     format = "%d:%02d", components = {{ div = 60 }, { mod = 60 }} })
ns.buffFmt:AddBreakpoint({ threshold = 0.001,  format = "%d s" })

--数值简化
local NumberData = {
	[1] = {
		config = CreateAbbreviateConfig({
			{
				breakpoint = 1e10,--123亿
				abbreviation = "亿",
				significandDivisor = 1e8,
				fractionDivisor = 1,
				abbreviationIsGlobal = false
			},
			{
				breakpoint = 1e9,--12.3亿
				abbreviation = "亿",
				significandDivisor = 1e7,
				fractionDivisor = 10,
				abbreviationIsGlobal = false
			},
			{
				breakpoint = 1e8,--1.23亿
				abbreviation = "亿",
				significandDivisor = 1e6,
				fractionDivisor = 100,
				abbreviationIsGlobal = false
			},
			{
				breakpoint = 1e5,--1234万
				abbreviation = "万",
				significandDivisor = 1e4,
				fractionDivisor = 1,
				abbreviationIsGlobal = false
			},
			{
				breakpoint = 1e4,--1.2万
				abbreviation = "万",
				significandDivisor = 1e3,
				fractionDivisor = 10,
				abbreviationIsGlobal = false
			},
			{
				breakpoint = 1,
				abbreviation = "",
				significandDivisor = 1,
				fractionDivisor = 1,
				abbreviationIsGlobal = false
			},
		})
	},
	[2] = {
		config = CreateAbbreviateConfig({
			{
				breakpoint = 1e10,--12B
				abbreviation = "B",
				significandDivisor = 1e9,
				fractionDivisor = 1,
				abbreviationIsGlobal = false
			},
			{
				breakpoint = 1e9,--1.2B
				abbreviation = "B",
				significandDivisor = 1e8,
				fractionDivisor = 10,
				abbreviationIsGlobal = false
			},
			{
				breakpoint = 1e7,--12M
				abbreviation = "M",
				significandDivisor = 1e6,
				fractionDivisor = 1,
				abbreviationIsGlobal = false
			},
			{
				breakpoint = 1e6,--1.2M
				abbreviation = "M",
				significandDivisor = 1e5,
				fractionDivisor = 10,
				abbreviationIsGlobal = false
			},
			{
				breakpoint = 1e4,--12K
				abbreviation = "K",
				significandDivisor = 1e3,
				fractionDivisor = 1,
				abbreviationIsGlobal = false
			},
			{
				breakpoint = 1e3,--1.2K
				abbreviation = "K",
				significandDivisor = 1e2,
				fractionDivisor = 10,
				abbreviationIsGlobal = false
			},
			{
				breakpoint = 1,
				abbreviation = "",
				significandDivisor = 1,
				fractionDivisor = 1,
				abbreviationIsGlobal = false
			},
		})
	},
}
function ns.value(numbers)
	if AddUIDB and NumberData[AddUIDB.value] and NumberData[AddUIDB.value] ~= 3 then
		return AbbreviateNumbers(numbers,NumberData[AddUIDB.value])
	else
		return AbbreviateNumbers(numbers)
	end
end



--百分比功能
local PercentData = {
	config = CreateAbbreviateConfig({
		{
			breakpoint = 100,--100%
			abbreviation = "%",
			significandDivisor = 1,
			fractionDivisor = 1,
			abbreviationIsGlobal = false
		},
		{
			breakpoint = 1,--1.2%
			abbreviation = "%",
			significandDivisor = 0.1,
			fractionDivisor = 10,
			abbreviationIsGlobal = false
		},
		{
			breakpoint = 0.0000000000000000000001,--0.12%
			abbreviation = "%",
			significandDivisor = 0.01,
			fractionDivisor = 100,
			abbreviationIsGlobal = false
		},
	})
}
--百分比简化
function ns.percent(number)
	return AbbreviateNumbers(number,PercentData)
end

ns.TIPTEXTS = {}
local tipsindex = 1
function ns.tips(text)
	table.insert(ns.TIPTEXTS, "|cffFFFFFF"..tipsindex..": "..text.."|r")
	tipsindex = tipsindex + 1
end
ns.tips("这里是一些没有开关的功能,如需开关联系我")

