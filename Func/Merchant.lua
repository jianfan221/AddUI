local _,ns = ...
ns.event("PLAYER_LOGIN", function()
if AddUIDB.mh ==  true  then
--自动卖灰
ns.event("MERCHANT_SHOW", function() 
	local p,N,c,n=0
		for b=0,4 do
		    for s=1,C_Container.GetContainerNumSlots (b) do
			    n=C_Container.GetContainerItemLink(b,s)--https://warcraft.wiki.gg/wiki/UI_escape_sequences 
                    if n and string.find(n,"|cnIQ0") then--9d9d9d--Q0灰色123456---https://warcraft.wiki.gg/wiki/Enum.ItemQuality
					    N={C_Item.GetItemInfo(n)} 
                        c=C_Item.GetItemCount(n)
						p= p+(N[11]*c)
						C_Container.UseContainerItem(b,s)
					end
			end
		end 
		--C_MerchantFrame.SellAllJunkItems()
    if p ~= 0 then
	    print("|cff44CCFF售卖垃圾: |r"..C_CurrencyInfo.GetCoinText(p))
	end
end)
end

--NPC一键售卖按钮装备
--需要过滤的装备
local nosell = {
	[63352] = true,--协作披风
	[63206] = true,--协和披风
	[65360] = true,--协同披风
	[63353] = true,--部落协作披风
	[63207] = true,--部落协和披风
	[65274] = true,--部落协同披风
	[152094]= true,--泰沙拉克
	[103678]= true,--传送永恒岛
}

-- 客户端限制：一次连续调用最多只能卖掉约 10 件，所以拆到多帧里逐件卖（每 0.05 秒一件）
local sellTicker

local function FreeSlots()
	local n = 0
	for b = 0, 4 do
		n = n + C_Container.GetContainerNumFreeSlots(b)
	end
	return n
end

local function IsSellable(link, BoxLevel)
	local level = C_Item.GetDetailedItemLevelInfo(link)
	local N = {C_Item.GetItemInfo(link)}
	local itemID = tonumber(string.match(link, "item:(%d+)")) or 1
	return level and BoxLevel and BoxLevel > level and level > 1 and (N[6] == ARMOR or N[6] == WEAPON) and not nosell[itemID] and not string.find(link, "|cnIQ5") and (N[11] or 0) > 0 and not C_Item.GetItemSpell(link)
end

local function StartSell(BoxLevel)
	if sellTicker then return end
	local freeAtStart = FreeSlots()
	local lastBag, lastSlot, lastLink, lastFree, stall = nil, nil, nil, nil, 0
	sellTicker = C_Timer.NewTicker(0.05, function(ticker)
		local free = FreeSlots()
		-- 上一件还没真正卖出去（被节流）就先等，避免对同一个格子重复操作
		if lastBag then
			if free > lastFree or C_Container.GetContainerItemLink(lastBag, lastSlot) ~= lastLink then
				lastBag, stall = nil, 0
			else
				stall = stall + 1
				if stall >= 60 then
					ticker:Cancel()
					sellTicker = nil
					print("|cff44CCFF一键售卖: |r" .. (free - freeAtStart) .. " 件（剩余物品无法出售，已停止）")
				end
				return
			end
		end

		if not MerchantFrame:IsShown() then
			ticker:Cancel()
			sellTicker = nil
			return
		end

		for b = 0, 4 do
			for s = 1, C_Container.GetContainerNumSlots(b) do
				local link = C_Container.GetContainerItemLink(b, s)
				if link and IsSellable(link, BoxLevel) then
					C_Container.UseContainerItem(b, s)
					lastBag, lastSlot, lastLink, lastFree = b, s, link, free
					return
				end
			end
		end

		ticker:Cancel()
		sellTicker = nil
		if free > freeAtStart then
			print("|cff44CCFF一键售卖: |r" .. (free - freeAtStart) .. " 件")
		end
	end)
end

StaticPopupDialogs.MerchantFrame_Sell = {
    text = "即将自动售卖\n售卖低于多少装等的装备?",  -- 提示文本
    button1 = "确认",          -- 确认按钮
    button2 = "取消",          -- 取消按钮
    timeout = 0,               -- 不自动关闭
    whileDead = true,          -- 死亡时可用
    hideOnEscape = true,       -- 按ESC关闭
    hasEditBox = true,         -- 包含输入框
    -- ESC 关闭走暴雪原生回调（12.1 起 EditBox 不再由插件 SetScript，避免污染共享弹窗对象）
    EditBoxOnEscapePressed = StaticPopup_StandardEditBoxOnEscapePressed,
    OnAccept = function(self)  -- 点击确认后的回调
		local BoxLevel = tonumber(self.EditBox:GetText())
		if not BoxLevel then return end
		StartSell(BoxLevel)
    end,
}
local Sell = CreateFrame("Button", "AddUISell", MerchantFrame.NineSlice, "UIPanelButtonTemplate")
Sell:SetText("售卖")
Sell:SetWidth(55)
Sell:SetHeight(22)
Sell:SetPoint("TOPLEFT", 57, 0)
Sell:SetScript("OnClick", function()
	StaticPopup_Show("MerchantFrame_Sell")
end)

-- 快速拾取（最快：LOOT_READY 最早时机立即全收）
-- 思路参考 Plumber（作者 Peterodox）Modules/LootUI/FastLoot.lua
if AddUIDB.sq == true then
	local slotProcessed, retryPending
	local function LootAll()
		for i = 1, GetNumLootItems() do
			if LootSlotHasItem(i) and not (slotProcessed and slotProcessed[i]) then
				slotProcessed = slotProcessed or {}
				slotProcessed[i] = true
				LootSlot(i)
			end
		end
	end

	ns.event("LOOT_READY", function()
		LootAll()
	end)
	ns.event("LOOT_CLOSED", function()
		slotProcessed, retryPending = nil, nil
	end)
	ns.event("LOOT_SLOT_CLEARED", function(_, slot)
		if slotProcessed then slotProcessed[slot] = true end
	end)
	ns.event("LOOT_SLOT_CHANGED", function(_, slot)
		if not slotProcessed or retryPending then return end
		slotProcessed[slot] = false
		retryPending = true
		C_Timer.After(0.4, function()
			retryPending = nil
			LootAll()
		end)
	end)
end

end)