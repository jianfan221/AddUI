local _,ns = ...

--0放弃,1需求,2贪婪,3分解,4幻化
-- 创建主框体
local RollItems = {}
local rollFrame = CreateFrame("Frame", "AllRollFrame", UIParent, "BasicFrameTemplate")
rollFrame:SetSize(200, 75)
rollFrame:SetPoint("CENTER",0,68)
rollFrame:SetFrameStrata("FULLSCREEN_DIALOG")
rollFrame.title = rollFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
rollFrame.title:SetPoint("CENTER", rollFrame.TitleBg, "CENTER", 0, 0)
rollFrame.title:SetText("装备一键选择器")
rollFrame:Hide()
-- 注册事件
ns.event("START_LOOT_ROLL", function(event,arg1, arg2)
	if not AddUIDB.autoloot then return end
	table.insert(RollItems, arg1)
	rollFrame:Show()
end)
--[[
ns.event("CONFIRM_LOOT_ROLL", function(event,rollID, rollType)--绑定确认
	print("绑定确认",rollID, rollType)
	ConfirmLootRoll(rollID, rollType)
	StaticPopup1Button1:Click()
end)

ns.event("CONFIRM_DISENCHANT_ROLL", function(event,rollID, rollType)--分解确认
	print("分解确认",rollID, rollType)
	ConfirmDisenchantRoll(rollID, rollType)
	StaticPopup1Button1:Click()
end)]]

--需求按钮
local needIcon = rollFrame:CreateTexture(nil, "ARTWORK")
needIcon:SetSize(40, 40)
needIcon:SetPoint("LEFT", rollFrame, "LEFT", 15, -12)
needIcon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Up")
local needIconbutton = CreateFrame("Button", nil,rollFrame)
needIconbutton:SetAllPoints(needIcon)
needIconbutton:RegisterForClicks("AnyUp");
needIconbutton:SetScript("OnClick", function()
	for _, value in ipairs(RollItems) do
		RollOnLoot(value,1)
		ConfirmLootRoll(value,1)
		StaticPopup1Button1:Click()
		RollOnLoot(value,2)
		RollOnLoot(value,4)
	end
	rollFrame:Hide()
	RollItems = {}
end)
needIconbutton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_CURSOR", 20, -20)
	GameTooltip:SetText("|cff00FF00"..ALL..NEED.."|r")
	GameTooltip:Show()
end)
needIconbutton:SetScript("OnLeave", function(self)
	GameTooltip:Hide()
end)
--贪婪按钮
local greedIcon = rollFrame:CreateTexture(nil, "ARTWORK")
greedIcon:SetSize(40, 40)
greedIcon:SetPoint("CENTER", rollFrame, "CENTER", 0, -15)
greedIcon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Coin-Up")
local greedIconbutton = CreateFrame("Button", nil,rollFrame)
greedIconbutton:SetAllPoints(greedIcon)
greedIconbutton:RegisterForClicks("AnyUp");
greedIconbutton:SetScript("OnClick", function()
    for _, value in ipairs(RollItems) do
		RollOnLoot(value,2)
		ConfirmLootRoll(value,2)
		StaticPopup1Button1:Click()
		RollOnLoot(value,4)
	end
	rollFrame:Hide()
	RollItems = {}
end)
greedIconbutton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_CURSOR", 20, -20)
	GameTooltip:SetText("|cff00FFFF"..ALL..GREED.."|r")
	GameTooltip:Show()
end)
greedIconbutton:SetScript("OnLeave", function(self)
	GameTooltip:Hide()
end)
--放弃按钮
local passIcon = rollFrame:CreateTexture(nil, "ARTWORK")
passIcon:SetSize(35, 35)
passIcon:SetPoint("RIGHT", rollFrame, "RIGHT", -15, -9)
passIcon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
local passIconbutton = CreateFrame("Button", nil,rollFrame)
passIconbutton:SetAllPoints(passIcon)
passIconbutton:RegisterForClicks("AnyUp");
passIconbutton:SetScript("OnClick", function()
    for _, value in ipairs(RollItems) do
		RollOnLoot(value,0)
	end
	rollFrame:Hide()
	RollItems = {}
end)
passIconbutton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_CURSOR", 20, -20)
	GameTooltip:SetText("|cffFFFFFF"..ALL..PASS.."|r")
	GameTooltip:Show()
end)
passIconbutton:SetScript("OnLeave", function(self)
	GameTooltip:Hide()
end)