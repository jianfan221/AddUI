local _,ns = ...
local function SetItemUseBuff()
	local sp1 = GetInventoryItemID("player", 13) and GetInventoryItemID("player", 13) or "sp1"
	local usesp1 = GetInventoryItemID("player", 13) and C_Item.GetItemIconByID(GetInventoryItemID("player", 13)) or false
	local sp2 = GetInventoryItemID("player", 14) and GetInventoryItemID("player", 14) or "sp2"
	local usesp2 = GetInventoryItemID("player", 14) and C_Item.GetItemIconByID(GetInventoryItemID("player", 14)) or false
	--默认物品存储
	local Item = {
		[sp1] = usesp1,
		[sp2] = usesp2,
		[241309] = true,--圣光潜力药水1
		[241308] = true,--圣光潜力药水2
		[241288] = true,--鲁莽药水2
		[241289] = true,--鲁莽药水1
	}

	ns.ItemBuffTable = {}

	local function SortIcon()
		ns.SetBuffIconPoint(BuffIconCooldownViewer)--整合到冷却管理器里
	end
	local function CreatItemBuffIcon()
		local f = CreateFrame("Frame", "MyCooldownItem", UIParent, "CooldownViewerBuffIconItemTemplate")
		f.Cooldown:SetScript("OnCooldownDone", function()
			f:Hide()
			SortIcon()
		end)
		return f
	end

	--返回法术鼠标提示上的持续时间
	local function PrintSpellTooltip(spellID)
		if not spellID or spellID == 0 then return end
		local tooltipTime
		local itemtooltip = CreateFrame("GameTooltip", "SpellTT", nil, "GameTooltipTemplate")
		itemtooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
		itemtooltip:SetSpellByID(spellID)
		for i = 1, itemtooltip:NumLines() do
			local left = _G["SpellTTTextLeft"..i]
			local leftText = left and left:GetText() or ""
			if not ns.MM(leftText) and string.match(leftText, "(%d+)秒") then--or string.match(leftText,"持续")
				tooltipTime = string.match(leftText, "(%d+)秒")--or string.match(leftText, "持续(%d+)")
			end
		end
		itemtooltip:Hide()
		if tooltipTime then
			tooltipTime = tonumber(tooltipTime)
		end
		return tooltipTime
	end
	
	local function SetItemSpellTable()
		local waitTimer = {}
			local waitTimer2 = {}
			for ItemID,yes in pairs(Item) do
				--print("物品列表",C_Item.GetItemNameByID(ItemID),"状态",yes)
				if yes then
					local _,ItemSpellID = C_Item.GetItemSpell(ItemID)
					local itemIcon = C_Item.GetItemIconByID(ItemID)
					waitTimer[ItemID] = C_Timer.NewTicker(1, function()
						local _,ItemSpellID = C_Item.GetItemSpell(ItemID)
						local itemIcon = C_Item.GetItemIconByID(ItemID)
						--print("检查物品法术ID",C_Item.GetItemNameByID(ItemID),"ID是",ItemSpellID)
						if ItemSpellID then
							ns.ItemBuffTable[ItemSpellID] = {}
							ns.ItemBuffTable[ItemSpellID]["frame"] = CreatItemBuffIcon()
							ns.ItemBuffTable[ItemSpellID]["frame"]["Icon"]:SetTexture(itemIcon)
							local itemTime = PrintSpellTooltip(ItemSpellID)
							waitTimer[ItemID]:Cancel()
							waitTimer[ItemID] = nil
							waitTimer2[ItemID] = C_Timer.NewTicker(1, function()
								local itemTime = PrintSpellTooltip(ItemSpellID)
								--print("检查持续时间",C_Item.GetItemNameByID(ItemID),"持续时间",itemTime)
								if itemTime then
									--print("设置物品",C_Item.GetItemNameByID(ItemID),"法术ID",ItemSpellID,"持续时间",itemTime)
									ns.ItemBuffTable[ItemSpellID]["time"] = itemTime
									waitTimer2[ItemID]:Cancel()
									waitTimer2[ItemID] = nil
								else
									ns.ItemBuffTable[ItemSpellID]["time"] = 1
								end
							end, 10)
						end
					end, 10)
				end
			end
		end

	
	--触发事件
	local ItemUseS = CreateFrame("FRAME")
	ItemUseS:RegisterEvent("PLAYER_ENTERING_WORLD")
	ItemUseS:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	ItemUseS:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	ItemUseS:RegisterEvent("PLAYER_DEAD")
	ItemUseS:SetScript("OnEvent", function(self,event,unit,guid,id)
		if not AddUIDB.cdcenter then return end
		if event == "PLAYER_ENTERING_WORLD" then
			SetItemSpellTable()
		end
		if event == "PLAYER_EQUIPMENT_CHANGED" then
			local sp1 = GetInventoryItemID("player", 13) and GetInventoryItemID("player", 13) or "sp1"
			local usesp1 = GetInventoryItemID("player", 13) and C_Item.GetItemIconByID(GetInventoryItemID("player", 13)) or false
			local sp2 = GetInventoryItemID("player", 14) and GetInventoryItemID("player", 14) or "sp2"
			local usesp2 = GetInventoryItemID("player", 14) and C_Item.GetItemIconByID(GetInventoryItemID("player", 14)) or false
			if not Item[sp1] then Item[sp1] = usesp1 end
			if not Item[sp2] then Item[sp2] = usesp2 end
			SetItemSpellTable()
		end
		if event == "UNIT_SPELLCAST_SUCCEEDED" then
			if unit ~= "player" then return end
			if ns.ItemBuffTable[id] then
				ns.ItemBuffTable[id]["frame"]:Show()
				ns.ItemBuffTable[id]["frame"]["Cooldown"]:SetCooldown(GetTime(),ns.ItemBuffTable[id]["time"])
				SortIcon(ns.ItemBuffTable[id]["frame"])
			end
		end
		if event == "PLAYER_DEAD" then
			for i, frame in pairs(ns.ItemBuffTable) do
				local _,dur = frame["frame"]["Cooldown"]:GetCooldownTimes()
				if dur and dur>1000 then
					frame["frame"]["Cooldown"]:SetCooldown(GetTime(),1)
				end
			end
		end
	end)
end

ns.event("PLAYER_LOGIN", function()
	if not AddUIDB.cdcenter then return end
	SetItemUseBuff()
end)
