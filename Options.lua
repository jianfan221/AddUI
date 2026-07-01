local addonName,ns = ...
------------------
local ADDUIGUI = CreateFrame("Frame")
local category = Settings.RegisterCanvasLayoutCategory(ADDUIGUI, "|cffff5900A|cffffb300d|cfff0ff00d|cff96ff00U|cff3cff00I|r")
Settings.RegisterAddOnCategory(category)



SlashCmdList["AddUIC"] = function()
	ns.COMBAT(Settings.OpenToCategory,category:GetID())
end
SLASH_AddUIC1 = "/ad"
SLASH_AddUIC2 = "/addui"

local function newFont(offx, offy, createframe, anchora, anchroframe, anchorb, text, fontsize)
	local font = createframe:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	font:SetPoint(anchora, anchroframe, anchorb, offx, offy)
	font:SetText(text)
	font:SetFont(STANDARD_TEXT_FONT, fontsize, "OUTLINE")	
	return font
end

local clickXOffset1,clickXOffset2,clickXOffset3 = 0,0,0
local function newCheckbox(clickX,text, tip, db)
	local x,y
	if clickX == 1 then
		x = 16
		y = clickXOffset1*-30-100
		clickXOffset1 = clickXOffset1 + 1
	elseif clickX == 2 then
		x = 226
		y = clickXOffset2*-30-100
		clickXOffset2 = clickXOffset2 + 1
	elseif clickX == 3 then
		x = 446
		y = clickXOffset3*-30-100
		clickXOffset3 = clickXOffset3 + 1
	end
	if text == "" then return end
	local check = CreateFrame("CheckButton", "ADDUICheck" .. text, ADDUIGUI, "InterfaceOptionsCheckButtonTemplate")
	check:SetPoint("TOPLEFT", ADDUIGUI, "TOPLEFT", x, y)
	check:SetChecked(AddUIDB[db])
	check.text:SetText(text)
	check:SetScript("OnEnter",function(self) 
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT") 
		GameTooltip:AddLine("|cffFFFFFF"..tip.."|r") 
		GameTooltip:Show() 
	end)
	check:SetScript("OnLeave", function(self)    
		GameTooltip:Hide()
	end)

	check:SetScript("OnClick", function ( ... )
		AddUIDB[db] = check:GetChecked()
	end)
	
	return check
end


ns.event("PLAYER_LOGIN", function()

local clear = CreateFrame("Button", "AddUISaveButton", ADDUIGUI, "UIPanelButtonTemplate")
clear:SetText("恢复默认并重载界面")
clear:SetWidth(177)
clear:SetHeight(24)
clear:SetPoint("TOPLEFT", 450, 77)
clear:SetScript("OnClick", function()
	local DungeonTime = {}
	if AddUIDB.DungeonBossKill then
		DungeonTime = AddUIDB.DungeonBossKill
	end
	AddUIDB = ns.AddUIDefaultDB
	AddUIDB.DungeonBossKill = DungeonTime
	ReloadUI()
end)

local AddUI = newFont(16, 0 , ADDUIGUI, "TOPLEFT", ADDUIGUI, "TOPLEFT", "|cffff5900A|cffffb300d|cfff0ff00d|cff96ff00U|cff3cff00I|r", 30)
local AddUI2 = newFont(0, 5 , ADDUIGUI, "BOTTOMLEFT", AddUI, "BOTTOMRIGHT", "|cff00ffd2源生界面增强|r", 15)
local somep = ADDUIGUI:CreateFontString(nil, "OVERLAY");
somep:SetFontObject("GameFontHighlight");
somep:SetPoint("TOPLEFT", ADDUIGUI, "TOPLEFT", 16, -30 );   
somep:SetJustifyH("LEFT")
somep:SetText("此界面只是一些功能的开关,大部分功能改动后需要重载界面\n/aa 重载界面  /ab 打开网格线  /chat 配置聊天框\n/sc 删除所有宏并恢复默认按键     /cc打开冷却管理器界面\n/sd 配置esc-选项-里面的大部分东西");

local ppc = ADDUIGUI:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
ppc:SetPoint("TOPRIGHT", -5, 10)
ppc:SetText("|cff00FF7F/ad|r快速打开此界面")
ppc:SetJustifyH("RIGHT")
ppc:SetFont(STANDARD_TEXT_FONT, 12, 'OUTLINE')


--鼠标提示写一些没开关的功能
local TIPFrame = CreateFrame("Frame", nil, ADDUIGUI)
TIPFrame:SetSize(115, 20)
TIPFrame:SetPoint("TOPRIGHT", -8, -10)
local TIPtext = TIPFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
TIPtext:SetPoint("CENTER")
TIPtext:SetVertexColor(0, 1, 0)
TIPtext:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
C_Timer.After(2,function()
	TIPtext:SetText("|cffFFFFFF其他功能: |r"..#ns.TIPTEXTS)
end)
local TIPBackground = TIPFrame:CreateTexture(nil, "BACKGROUND")
TIPBackground:SetTexture(130937)
TIPBackground:SetAllPoints(TIPFrame)
TIPBackground:SetColorTexture(0, 0, 0, 0.5) -- 设置背景颜色为黑色，透明度为0.5
TIPBackground:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(TIPBackground, "ANCHOR_RIGHT")
	GameTooltip:AddLine("以下是一些没有开关的功能\n")
	for i,text in ipairs(ns.TIPTEXTS) do
		GameTooltip:AddLine(text) 
	end
	GameTooltip:Show()
	TIPtext:SetText("|cffFFFFFF其他功能: |r"..#ns.TIPTEXTS)
end)
TIPBackground:SetScript("OnLeave", function(self)
	GameTooltip:Hide()
end)

local qqun = ADDUIGUI:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
qqun:SetPoint("BOTTOMLEFT", 30, -30)
qqun:SetText("抖音:简繁       版本:|cff00FFFF"..ns.ADDUIBB)
qqun:SetJustifyH("RIGHT")

local pcrl = CreateFrame("Button", "AddUIrl", ADDUIGUI, "UIPanelButtonTemplate")
pcrl:SetText("重载")
pcrl:SetWidth(92)
pcrl:SetHeight(22)
pcrl:SetPoint("BOTTOMRIGHT", -132, -31)
pcrl:SetScript("OnClick", function()
	 ReloadUI()
end)

local unitc = newCheckbox(1,"头像模块","改变头像样式", "unitf")
local mmbbc = newCheckbox(1,"动作条模块","改变动作条样式", "mmb")
local mmbac = newCheckbox(1,"禁用动作条额外动画","禁用动作条的施法进度+指向技能圆圈+被断变红!", "mmba")
local jsnjc = newCheckbox(1,"角色面板耐久","C键面板装备栏下面的耐久度百分比", "syd")
local smapc = newCheckbox(1,"小地图模块","方形小地图", "smap")
local smicc = newCheckbox(1,"小地图图标","自动排列小地图图标,指向显示+离开时渐隐", "smapicon")
local chatc = newCheckbox(1,"聊天窗模块","聊天窗口样式,tab可以切换聊天频道", "chatm")
local chabc = newCheckbox(1,"聊天频道按钮","提供一行可以切换频道的按钮", "chatb")
local Friend= newCheckbox(1,"好友列表搜索","此功能会导致不能传送家宅好友", "Friend")
local zdmhc = newCheckbox(1,"自动卖灰","自动卖垃圾", "mh")
local kssqc = newCheckbox(1,"快速拾取","增加拾取速度", "sq")
local castc = newCheckbox(1,"施法条模块","改变施法条样式", "cast")
local rcast = newCheckbox(1,"|cff00BFFF自定义施法条材质|r","禁用施法条模块此项也会失效", "SCastTexture")

local combc = newCheckbox(2,"进入战斗提示","屏幕中间进入脱离战斗提示", "comb")
local mizuc = newCheckbox(2,"密语自动邀请","别人密你123或者.组.会自动邀请,支持战网密语", "zu")
local lfgkc = newCheckbox(2,"|cff00BFFFLFG增强|r","|r|cff00FF00预创建双击申请,自动邀请,自动进组|r\n!!!!!!如果你用集合石,此项自动失效!!!!!!", "lfgkg")
local raidc = newCheckbox(2,"团队框架模块","血条材质和职责材质和鼠标指向边框", "raidframebuff")
local raidabs = newCheckbox(2,"团队框架吸收盾","团队框架显示治疗吸奶盾和普通吸收盾", "raidabsorb")
local stat  = newCheckbox(2,"|cff00BFFF自身属性框体|r","编辑模式拖动位置", "stat")
local cdset = newCheckbox(2,"冷却管理器美化","冷却管理器美化", "cdset")
local cdcenter = newCheckbox(2,"冷却管理器居中对齐","冷却管理器居中对齐,|cff00BFFF饰品药水BUFF整合|r", "cdcenter")
local redama= newCheckbox(2,"大秘境重置伤害统计","大秘境开始时重置伤害统计", "MDRedamage")
local setdama= newCheckbox(2,"伤害统计样式美化","伤害统计样式美化", "setdama")
local poidama= newCheckbox(2,"伤害统计自动对齐","伤害统计自动对齐", "poidama")
local valueda= newCheckbox(2,"伤害统计数值简化","伤害统计数值简化", "valueda")


local cvac = newCheckbox(3,"CVAR自动设置","自动配置一些CVAR,大部分已移动至|cff00FF00/sd|r命令", "cvar")
local dimic= newCheckbox(3,"|cff00BFFF右下角信息栏|r","|r|cff00FF00右下角显示延迟耐久", "dimi")
local rolls= newCheckbox(3,"装备一键选择器","一键<需求/贪婪/放弃>全部装备", "autoloot")
local lotbnt = newCheckbox(3,"Log快捷开关","聊天按钮后面的log按钮", "lotbnt")
local chatct = newCheckbox(3,"聊天框战斗战复计时器","聊天框右上角战斗战复计时器(战复在编辑模式拖动)", "chatCombatTimer")
local interrupt = newCheckbox(3,"打断记录","小队打断记录,编辑模式拖动位置\n只记录打断成功的人,持续记录20秒", "interrupt")

--材质下拉菜单
local RadioDropdown = CreateFrame("DropdownButton", nil, ADDUIGUI, "WowStyle1DropdownTemplate")
RadioDropdown:SetPoint("TOPLEFT", 20, -490)
RadioDropdown:SetDefaultText(ns.CastBarTextrue[AddUIDB.CastTexture])
RadioDropdown:SetWidth(170)
RadioDropdown.selectTexture = RadioDropdown:CreateTexture(nil, "ARTWORK")--选中材质
RadioDropdown.selectTexture:SetPoint("TOPLEFT",RadioDropdown,"TOPLEFT", 5, -5)
RadioDropdown.selectTexture:SetPoint("BOTTOMRIGHT",RadioDropdown,"BOTTOMRIGHT", -15, 5)
RadioDropdown.selectTexture:SetVertexColor(1,1,1,1)
if not ns.CastBarTextrue[AddUIDB.CastTexture] then
	AddUIDB.CastTexture = ns.AddUIDefaultDB.CastTexture --如果找不到就重新定义
end
if string.match(ns.CastBarTextrue[AddUIDB.CastTexture],"Interface\\")then 
	RadioDropdown.selectTexture:SetTexture(ns.CastBarTextrue[AddUIDB.CastTexture])
else
	RadioDropdown.selectTexture:SetAtlas(ns.CastBarTextrue[AddUIDB.CastTexture])
end
local function IsSelected(value)
	return value == AddUIDB.CastTexture
end
local function SetSelected(value)
	AddUIDB.CastTexture = value
	if string.match(ns.CastBarTextrue[AddUIDB.CastTexture],"Interface\\")then 
		RadioDropdown.selectTexture:SetTexture(ns.CastBarTextrue[AddUIDB.CastTexture])
	else
		RadioDropdown.selectTexture:SetAtlas(ns.CastBarTextrue[AddUIDB.CastTexture])
	end
end
--先对表格进行排序
local sortedTable = {}
for k in pairs(ns.CastBarTextrue) do
	table.insert(sortedTable, k)
end
table.sort(sortedTable)
-- 菜单项生成函数使用排序后的表格
local function GeneratorFunction(dropdown, rootDescription)
	rootDescription:SetScrollMode(400);
	for _, text in pairs(sortedTable) do
		local texts = text
		if string.match(ns.CastBarTextrue[text],"PlateColor\\texture")then 
			texts = "|cff00FFFF"..text
		end
		local radio = rootDescription:CreateRadio(texts, IsSelected, SetSelected, text)
		radio:AddInitializer(function(button, description, menu)
			local bgTexture = button:AttachTexture()
			bgTexture:SetSize(170,18)
			bgTexture:SetPoint("LEFT",15,0);
			if string.match(ns.CastBarTextrue[text],"Interface\\")then 
				bgTexture:SetTexture(ns.CastBarTextrue[text])
			else
				bgTexture:SetAtlas(ns.CastBarTextrue[text])
			end
			bgTexture:SetDrawLayer("BACKGROUND")--12.0
		end)
	end
end
RadioDropdown:SetupMenu(GeneratorFunction)


--鼠标跟随方式
local tipdroptable = {{"鼠标提示:跟随",1},{"鼠标提示:不跟随",0},{"鼠标提示:非战斗跟随",2},{"鼠标提示:禁用",3}}
local RadioDropdown = CreateFrame("DropdownButton", nil, ADDUIGUI, "WowStyle1DropdownTemplate")
RadioDropdown:SetPoint("TOPLEFT", 230, -490)
RadioDropdown:SetWidth(170)
local function IsSelected(value)
	return value == AddUIDB.ftip
end
local function SetSelected(value)
	AddUIDB.ftip = value
end
MenuUtil.CreateRadioMenu(RadioDropdown,IsSelected, SetSelected,	unpack(tipdroptable))

--数值单位
local unitsdrop = {{"中文单位",1},{"英文单位",2},{"暴雪默认",3}}
local unitsDropdown = CreateFrame("DropdownButton", nil, ADDUIGUI, "WowStyle1DropdownTemplate")
unitsDropdown:SetPoint("TOPLEFT", 440, -490)
unitsDropdown:SetWidth(170)
local function IsSelected(value)
	return value == AddUIDB.value
end
local function SetSelected(value)
	AddUIDB.value = value
end
MenuUtil.CreateRadioMenu(unitsDropdown,IsSelected, SetSelected,	unpack(unitsdrop))

local function newSlider(SliderName, x, y, minValue, maxValue, curValue, valueStep, upText, tipText, varformat)
	local pSlider = CreateFrame("Slider", "Slider"..SliderName , ADDUIGUI, "MinimalSliderWithSteppersTemplate")
	pSlider:SetPoint("TOPLEFT", ADDUIGUI, "TOPLEFT", x, y)
	pSlider:SetSize(180, 20)

	-- 右侧数值显示（PlateColor 风格）
	pSlider.righttext = pSlider:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	pSlider.righttext:SetPoint("BOTTOM", pSlider, "TOP", 0, -2)
	pSlider.righttext:SetFont(STANDARD_TEXT_FONT, 15, "OUTLINE")
	pSlider.righttext:SetTextColor(0, 1, 0)
	pSlider.righttext:SetText("|cffFFD700"..upText.." :  "..string.format(varformat, curValue).."|r")

	-- 使用 PlateColor 风格的回调模式
	pSlider:Init(curValue, minValue, maxValue, (maxValue - minValue) / (valueStep or 1))
	pSlider:RegisterCallback("OnValueChanged", function(self, value)
		pSlider.righttext:SetText("|cffFFD700"..upText.." :  "..string.format(varformat, value).."|r")
	end)

	pSlider.tooltipText = tipText
	return pSlider
end

local castWidth = newSlider("castWidth", 15, -538, 200, 400, AddUIDB.castWidth, 1, "施法条宽度", "施法条宽度","%d")
castWidth:RegisterCallback("OnValueChanged", function(self, value)
	AddUIDB.castWidth = tonumber(string.format("%d", value))
end)

local castHeight = newSlider("castHeight", 15, -578, 10, 40, AddUIDB.castHeight, 1, "施法条高度", "施法条高度","%d")
castHeight:RegisterCallback("OnValueChanged", function(self, value)
	AddUIDB.castHeight = tonumber(string.format("%d", value))
end)

local spellqq = newSlider("Spell", 225, -538, 0, 400, AddUIDB.SpellQ, 1, "施法序列延迟", "施法序列延迟","%d")
spellqq:RegisterCallback("OnValueChanged", function(self, value)
	AddUIDB.SpellQ = tonumber(string.format("%d", value))
	SetCVar("SpellQueueWindow", AddUIDB.SpellQ) 
end)

end)