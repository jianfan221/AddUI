local _,ns = ...
ns.event("PLAYER_LOGIN", function()
if AddUIDB.syd ==  false  then return end

--------------------------
-- SyDurGlow.lua
-- Author: Sayoc
-- Date: 10.01.23
--人物面板耐久
--------------------------
local  q, vl
local _G = getfenv(0)
local SlotDurStrs = {}
local items = {
	"Head 1",
	"Neck",
	"Shoulder 2",
	"Shirt",
	"Chest 3",
	"Waist 4",
	"Legs 5",
	"Feet 6",
	"Wrist 7",
	"Hands 8",
	"Finger0",
	"Finger1",
	"Trinket0",
	"Trinket1",
	"Back",
	"MainHand 9",
	"SecondaryHand 10",
	"Tabard",
}

-------------------------------- Durability show 耐久显示---------------------------------

PaperDollFrame:CreateFontString("SyDurRepairCost", "ARTWORK", "NumberFontNormal")
SyDurRepairCost:SetPoint("BOTTOMLEFT", "PaperDollFrame", "BOTTOMLEFT", 8, 13)

local function GetDurStrings(name)
	if(not SlotDurStrs[name]) then
		local slot = _G["Character" .. name .. "Slot"]
		SlotDurStrs[name] = slot:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
		SlotDurStrs[name]:SetPoint("CENTER", slot, "BOTTOM", 0, 8)
	end
	return SlotDurStrs[name]
end

local function UpdateDurability()
	local durcost = 0

	for id, vl in pairs(items) do
		local slot, index = string.split(" ", vl)
		if index then
			--local has, _, cost = tooltip:SetInventoryItem("player", id);
			local value, max = GetInventoryItemDurability(id)
			local SlotDurStr = GetDurStrings(slot)
			if(value and max and max ~= 0) then
				local percent = value / max				
				SlotDurStr:SetText('')
				if(ceil(percent * 100) < 100)then
					SlotDurStr:SetTextColor(1 - percent, percent, 0)
					SlotDurStr:SetText(ceil(percent * 100) .. "%")
				end
				--durcost = durcost + cost
			else
				 SlotDurStr:SetText("")
			end
		end
	end

	--SyDurRepairCost:SetText(GetMoneyString(durcost))
end



----------------------------------- Event --------------------------------------

ns.event("UNIT_INVENTORY_CHANGED", UpdateDurability)
ns.event("UPDATE_INVENTORY_DURABILITY", UpdateDurability)

end)