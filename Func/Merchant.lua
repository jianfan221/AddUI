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

-- 带使用效果的装备一律不卖（传送装备、收藏道具等都有“使用：”效果，比维护 ID 可靠）
local function HasUseEffect(link)
	local spellName = C_Item.GetItemSpell(link)
	if spellName == nil then
		-- 物品信息未缓存时无法判断，保守按“不卖”处理，避免误售传送装备
		return C_Item.GetItemInfo(link) == nil
	end
	return spellName ~= ""
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

		local total, money, rounds = 0, 0, 0

		local function SellOnce()
			local sold = 0
			for b = 0, 4 do
				for s = 1, C_Container.GetContainerNumSlots(b) do
					local link = C_Container.GetContainerItemLink(b, s)
					if link then
						local level = C_Item.GetDetailedItemLevelInfo(link)
						local N = {C_Item.GetItemInfo(link)}
						local itemID = tonumber(string.match(link, "item:(%d+)")) or 1
						if level and BoxLevel > level and level > 1 and (N[6] == ARMOR or N[6] == WEAPON) and not nosell[itemID] and not string.find(link, "|cnIQ5") and not HasUseEffect(link) then
							local info = C_Container.GetContainerItemInfo(b, s)
							total = total + 1
							money = money + (N[11] or 0) * (info and info.stackCount or 1)
							C_Container.UseContainerItem(b, s)
							sold = sold + 1
						end
					end
				end
			end
			rounds = rounds + 1
			-- 一轮没卖完就隔 0.3 秒继续，直到没有符合条件的装备（规避单次批量出售节流）
			if sold > 0 and rounds < 30 then
				C_Timer.After(0.3, SellOnce)
			elseif total > 0 then
				print("|cff44CCFF一键售卖: |r" .. total .. " 件，共 " .. C_CurrencyInfo.GetCoinText(money))
			end
		end

		SellOnce()
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