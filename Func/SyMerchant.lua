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

StaticPopupDialogs.MerchantFrame_Sell = {
    text = "即将自动售卖\n售卖低于多少装等的装备?",  -- 提示文本
    button1 = "确认",          -- 确认按钮
    button2 = "取消",          -- 取消按钮
    timeout = 0,               -- 不自动关闭
    whileDead = true,          -- 死亡时可用
    hideOnEscape = true,       -- 按ESC关闭
    hasEditBox = true,         -- 包含输入框
	OnShow = function(self)
		self.EditBox:SetScript("OnEscapePressed", function(EditBox)
            self:Hide()  -- 直接关闭窗口
        end)
    end,
    OnAccept = function(self)  -- 点击确认后的回调
        local BoxLevel = tonumber(self.EditBox:GetText())
		local N,c,n
		for b=0,4 do
			for s = 1,C_Container.GetContainerNumSlots(b) do
				n = C_Container.GetContainerItemLink(b,s) 
				if n then
					local level = GetDetailedItemLevelInfo(n)
					N={C_Item.GetItemInfo(n)}
					local itemID = tonumber(string.match(n, "item:(%d+)")) or 1
					if BoxLevel and level and BoxLevel > level and level > 1 and (N[6] == ARMOR or N[6] == WEAPON) and not nosell[itemID] and not string.find(n,"|cnIQ5") then
						C_Container.UseContainerItem(b,s)
					end
				end
			end
		end
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

-- 快速拾取
if AddUIDB.sq ==  true  then
	ns.event("LOOT_READY", function(event, ...)
		-- Time delay
		local tDelay = 0
		if GetTime() - tDelay >= 0.1 then
			tDelay = GetTime()
			if GetCVarBool("autoLootDefault") ~= IsModifiedClick("AUTOLOOTTOGGLE") then
				for i = GetNumLootItems(), 1, -1 do
					LootSlot(i)
				end
				tDelay = GetTime()
			end
		end
	end)
end

end)