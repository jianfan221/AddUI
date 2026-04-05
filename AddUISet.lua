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
        if (isOnce or event == "PLAYER_ENTERING_WORLD") and self then
            EventRegistry:UnregisterFrameEventAndCallback(event, self)
        end
        handler(event, ...)
    end)
end

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

function ns.AddEdit(frame,name)
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
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", frame, "TOPLEFT", -5, 5)
	bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 5, -5)
    bg:SetAtlas("editmode-actionbar-highlight-nineslice-center")
	bg:SetAlpha(0.5)
    bg:Hide()
	
	local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
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
    local function EnterEditMode()
		frame:Show()
        bg:Show()
		text:Show()
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", function(self)
			self:StartMoving()
		end)
        frame:SetScript("OnDragStop", function()
            frame:StopMovingOrSizing()
            if not AddUIDB then AddUIDB = {} end
            local left, bottom = frame:GetLeft(), frame:GetBottom()
			AddUIDB[dbName] = {"BOTTOMLEFT", "UIParent", "BOTTOMLEFT", left, bottom}
        end)
		frame:SetScript("OnEnter", function(self)
			bg:SetAlpha(1.0)
		end)

		frame:SetScript("OnLeave", function(self)
			bg:SetAlpha(0.5)
		end)
    end
    
    local function LeaveEditMode()
		frame:SetShown(isshow)
        bg:Hide()
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
ns.discolor = C_CurveUtil.CreateColorCurve()
ns.discolor:SetType(Enum.LuaCurveType.Step)
ns.discolor:AddPoint(0, CreateColor(0,  0,  0,  0))--无
ns.discolor:AddPoint(1, CreateColor(1,  1,  1,  1))--魔法
ns.discolor:AddPoint(2, CreateColor(0.5,0,  1,  1))--诅咒
ns.discolor:AddPoint(3, CreateColor(1,0.5,  0,  1))--疾病
ns.discolor:AddPoint(4, CreateColor(0,  1,  0,  1))--中毒
ns.discolor:AddPoint(9, CreateColor(1,  0,  0,  1))--激怒

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
function ns.ADDUIBFB(nownumber,maxnumber)
	if not nownumber or not maxnumber then return end
	if tonumber(nownumber) == 0 or tonumber(maxnumber) == 0 then return end
	local text = tonumber(nownumber)/tonumber(maxnumber) * 100
	if text == 100 then
		return format("%d",text).."%"
	elseif text> 10 then
		return format("%.1f",text).."%"
	elseif text > 0 then
		return format("%.2f",text).."%"
	else
		return ""
	end
end

--获取职业颜色RGB
function ns.ClassRGB(unit)
	local Stylecolor
	if UnitIsPlayer(unit) then
		local _, class = UnitClass(unit)
		Stylecolor = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
	elseif UnitReaction(unit, "player") then
		Stylecolor = FACTION_BAR_COLORS and FACTION_BAR_COLORS[UnitReaction(unit, "player")]
	end
	if (not UnitIsConnected(unit)) then	
		return 0.5, 0.5, 0.5
	elseif Stylecolor and Stylecolor.r and Stylecolor.g and Stylecolor.b then
		return Stylecolor.r, Stylecolor.g, Stylecolor.b
	else
		return 0.5, 0.5, 0.5
	end
end


ns.TIPTEXTS = {}
local tipsindex = 1
function ns.tips(text)
	table.insert(ns.TIPTEXTS, "|cffFFFFFF"..tipsindex..": "..text.."|r")
	tipsindex = tipsindex + 1
end

