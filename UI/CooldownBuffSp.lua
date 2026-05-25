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
		ns.ItemBuffTable = {}
		for ItemID, yes in pairs(Item) do
			if yes then
				local spellID
				local retries = 0
				local maxRetries = 20
				local done
				C_Timer.NewTicker(0.5, function()
					if done then return end
					retries = retries + 1

					-- Phase 1: 等 spellID
					if not spellID then
						_, spellID = C_Item.GetItemSpell(ItemID)
						if not spellID then
							return  -- 次数跑满就自动停
						end
					end

					-- Phase 2: 等 itemTime
					local itemTime = PrintSpellTooltip(spellID)
					if not itemTime then
						if retries >= maxRetries then
							itemTime = 1
						else
							return
						end
					end

					-- 两个都拿到了（或超时 fallback），一次性创建图标
					done = true
					ns.ItemBuffTable[spellID] = {}
					ns.ItemBuffTable[spellID].frame = CreatItemBuffIcon()
					ns.ItemBuffTable[spellID].time = itemTime
					ns.ItemBuffTable[spellID].frame.Icon:SetTexture(C_Item.GetItemIconByID(ItemID))
				end, maxRetries)  -- 跑完 maxRetries 次自动停
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
