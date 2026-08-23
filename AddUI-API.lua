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
function ns.AddEdit(frame,name,center)
    -- 自动生成数据库键名
    local dbName = frame:GetName() and frame:GetName().."_Edit"
	if not dbName then
		print("编辑模式拖动位置功能没有找到框体名")
		return
	end
	if not EditModeManagerFrame then
		print("编辑模式拖动位置功能没有找到编辑模式框架")
		return
	end
	
    frame:SetClampedToScreen(true)  --限制拖动范围
	frame:SetClampRectInsets(30, -30, -30, 30)  --允许拖出屏幕30像素左右上下
	-- 创建背景框
    -- 高亮层：独立的高层级子框架，确保编辑模式下显示在所有内容（如光环预览图标）之上
    local highlight = CreateFrame("Frame", nil, frame)
    highlight:SetAllPoints(frame)
    highlight:SetFrameLevel(100)
    highlight:Hide()

    -- 用暴雪编辑模式系统框的九宫格材质（不选中高亮），鼠标指向时调亮
    -- 暴雪 EditModeSystemSelectionBaseTemplate 的 texture kit：editmode-actionbar-highlight（不选中/高亮）、-selected（选中）
    local bg
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
    if NineSliceUtil and NineSliceUtil.ApplyLayout
        and C_Texture and C_Texture.GetAtlasInfo("editmode-actionbar-highlight-NineSlice-Center") then
        pcall(NineSliceUtil.ApplyLayout, highlight, selectionLayout, "editmode-actionbar-highlight")
        highlight:SetAlpha(1) -- 默认半透明高亮，鼠标指向时调亮到 1
    else
        bg = highlight:CreateTexture(nil, "OVERLAY")
        bg:SetPoint("TOPLEFT", frame, "TOPLEFT", -5, 5)
        bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 5, -5)
        bg:SetAtlas("editmode-actionbar-highlight-nineslice-center")
        bg:SetAlpha(0.5)
        bg:Hide()
    end

	local text = highlight:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	text:SetPoint("CENTER", 0, 0)
	text:SetFont("fonts\\ARHei.ttf", 30, "OUTLINE")
	text:SetText(name or "AddUI")
	text:Hide()
	text:SetVertexColor(1,1,1,0.7)
    
    -- 加载保存的位置
    if AddUIDB and AddUIDB[dbName] then
		frame:ClearAllPoints()
        frame:SetPoint(unpack(AddUIDB[dbName]))
    end
	
    
    -- 编辑模式切换函数
	local isshow = frame:IsShown()--储存框体原始显示状态
	local isalpha = frame:GetAlpha()--储存框体原始透明度
    local function EnterEditMode()
		frame:Show()
		frame:SetAlpha(1)
        -- 可选：编辑模式自动水平居中（仿 Cooldown.lua：TOP 锚到 UIParent 水平中心，保持垂直位置）
        if center then
            if not InCombatLockdown() then
                local bottom = frame:GetBottom()
                local height = frame:GetHeight() or 0
                local X, Y = UIParent:GetWidth() / 2, bottom + height
                frame:ClearAllPoints()
                frame:SetPoint("TOP", UIParent, "BOTTOMLEFT", X, Y)
            end
        end
        highlight:Show()
        if bg then bg:Show() end
		text:Hide() -- 文字默认隐藏，鼠标指向时才显示
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", function(self)
			self:StartMoving()
		end)
        frame:SetScript("OnDragStop", function()
            frame:StopMovingOrSizing()
            if center then
                -- 每次拖动松手后自动水平居中（垂直保持拖后位置）
                local bottom = frame:GetBottom()
                local height = frame:GetHeight() or 0
                local X, Y = UIParent:GetWidth() / 2, bottom + height
                frame:ClearAllPoints()
                frame:SetPoint("TOP", UIParent, "BOTTOMLEFT", X, Y)
                -- 保存位置（直接用上面算好的 TOP 锚点，保证与加载/居中逻辑一致）
                if not AddUIDB then AddUIDB = {} end
                AddUIDB[dbName] = {"TOP", "UIParent", "BOTTOMLEFT", X, Y}
            else
                if not AddUIDB then AddUIDB = {} end
                local left, bottom = frame:GetLeft(), frame:GetBottom()
				AddUIDB[dbName] = {"BOTTOMLEFT", "UIParent", "BOTTOMLEFT", left, bottom}
            end
        end)
		frame:SetScript("OnEnter", function(self)
			-- 鼠标指向：换成选中材质 + 显示文字
			if not bg then pcall(NineSliceUtil.ApplyLayout, highlight, selectionLayout, "editmode-actionbar-selected") end
			if bg then bg:SetAlpha(1.0) end
			text:Show()
		end)

		frame:SetScript("OnLeave", function(self)
			-- 离开：换回不选中高亮材质 + 隐藏文字
			if not bg then pcall(NineSliceUtil.ApplyLayout, highlight, selectionLayout, "editmode-actionbar-highlight") end
			if bg then bg:SetAlpha(0.5) end
			text:Hide()
		end)
    end
    
    local function LeaveEditMode()
		frame:SetShown(isshow)
        frame:SetAlpha(isalpha)
        highlight:Hide()
        if bg then bg:Hide() end
		text:Hide()
        frame:SetMovable(false)
        frame:EnableMouse(false)
        frame:SetScript("OnDragStart", nil)
        frame:SetScript("OnDragStop", nil)
    end
    
    -- 注册编辑模式事件
    EditModeManagerFrame:HookScript("OnShow", EnterEditMode)
    EditModeManagerFrame:HookScript("OnHide", LeaveEditMode)
    
    -- 初始检查
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

--创建文本
function ns.AddText(frame,size)
	local text = frame:CreateFontString(nil, "ARTWORK")
	text:SetFont(STANDARD_TEXT_FONT, size, 'OUTLINE')
	
	return text
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

