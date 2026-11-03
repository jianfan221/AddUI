local AddonName, ns = ...

ns.tips("拍卖行购买可一键补满一组")

--只有药水 / 其它两个子分类按真实堆叠补满一组, 其余消耗品一律按 20
local FULL_STACK_SUBCLASSES = {
	[Enum.ItemConsumableSubclass.Potion] = true,
	[Enum.ItemConsumableSubclass.Other] = true,
}
local OTHER_STACK = 20

--购买两个字直接用暴雪按钮本地化
local BUY_TEXT = _G.AUCTION_HOUSE_BUY_BUTTON or "购买"

local buyButton
local hooked
--本次已买但还在邮箱的记录 [itemID] = { quantity = 已买数量, bagCount = 购买时背包数量 }
local boughtInfo = {}
--点按钮后等购买结果落地, 用于累加已买数量
local pendingPurchase

local function GetDisplay()
	local frame = AuctionHouseFrame
	return frame and frame.CommoditiesBuyFrame and frame.CommoditiesBuyFrame.BuyDisplay
end

--背包内该物品数量(含本次已买还在邮箱的),秘密值时返回 nil
local function GetOwnedCount(itemID)
	local count = C_Item.GetItemCount(itemID)
	if not count or ns.MM(count) then
		return
	end

	local info = boughtInfo[itemID]
	if info then
		--邮件已经进背包(或背包变少)就作废记录
		if count >= info.bagCount + info.quantity or count < info.bagCount then
			boughtInfo[itemID] = nil
		else
			return info.bagCount + info.quantity
		end
	end
	return count
end

--一组的大小: 药水/其它按真实堆叠, 其余消耗品固定 20
--非消耗品、不可堆叠的物品返回 nil(不显示按钮)
local function GetGroupSize(itemID)
	local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(itemID)
	if not classID or ns.MM(classID) or classID ~= Enum.ItemClass.Consumable then
		return
	end

	local maxStack = C_Item.GetItemMaxStackSizeByID(itemID)
	if not maxStack or ns.MM(maxStack) or maxStack <= 1 then
		return
	end

	if subClassID and not ns.MM(subClassID) and FULL_STACK_SUBCLASSES[subClassID] then
		return maxStack
	end
	return OTHER_STACK
end

--补满一组还需要买的数量: 背包 10 个、一组 200 → 190; 背包 230 → 170; 空背包 → 200
local function GetFillQuantity(itemID, groupSize)
	local ownedCount = GetOwnedCount(itemID)
	if not ownedCount then
		return groupSize
	end
	return groupSize - ownedCount % groupSize
end

local function Refresh(itemID)
	if not buyButton then return end
	if not itemID then
		local display = GetDisplay()
		itemID = display and display:GetItemID()
	end

	local groupSize = itemID and GetGroupSize(itemID)
	if not groupSize then
		buyButton:Hide()
		return
	end

	if not buyButton:IsShown() then
		buyButton:Show()
	end
	buyButton:SetText(BUY_TEXT .. "( |cff00ff00" .. GetFillQuantity(itemID, groupSize) .. "|r )")
end

--按官方数量变更回调刷新数量/单价/总价(等价于玩家手动输入数量)
local function SetQuantity(display, quantity)
	local frame = display:GetAuctionHouseFrame()
	local event = AuctionHouseFrameMixin and AuctionHouseFrameMixin.Event and
		AuctionHouseFrameMixin.Event.CommoditiesQuantitySelectionChanged
	if event then
		frame:TriggerEvent(event, quantity)
	else
		display:SetQuantitySelected(quantity)
	end
end

local function OnClick()
	local display = GetDisplay()
	if not display then return end
	local itemID = display:GetItemID()
	if not itemID or not display.resultsLoaded then return end

	local groupSize = GetGroupSize(itemID)
	if not groupSize then return end

	Refresh(itemID)
	SetQuantity(display, GetFillQuantity(itemID, groupSize))

	local quantity = display.QuantityInput:GetQuantity()
	if quantity <= 0 then return end

	--记下这次要买多少, 购买成功后按钮按"背包 + 已买"显示
	local bagCount = C_Item.GetItemCount(itemID)
	if not bagCount or ns.MM(bagCount) then
		bagCount = 0
	end
	pendingPurchase = { itemID = itemID, quantity = quantity, bagCount = bagCount }

	--走暴雪原生购买流程(含价格确认)
	display.BuyButton:Click()
end

local function CreateButton()
	if buyButton then return end
	local display = GetDisplay()
	if not display or not display.BuyButton then return end

	buyButton = CreateFrame("Button", "AddUIAHStackBuyButton", display, "UIPanelButtonTemplate")
	buyButton:SetSize(196, 22)
	buyButton:SetPoint("TOP", display.BuyButton, "BOTTOM", 0, -10)
	buyButton:SetText(BUY_TEXT)
	buyButton:Hide()
	buyButton:SetScript("OnClick", OnClick)
	buyButton:SetScript("OnShow", function() Refresh() end)

	if not hooked then
		hooked = true
		ns.hook(display, "SetItemIDAndPrice", function(_, itemID)
			Refresh(itemID)
		end)
	end

	Refresh()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("AUCTION_HOUSE_SHOW")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
eventFrame:RegisterEvent("ITEM_COUNT_CHANGED")
eventFrame:RegisterEvent("COMMODITY_SEARCH_RESULTS_RECEIVED")
eventFrame:RegisterEvent("COMMODITY_PURCHASE_SUCCEEDED")
eventFrame:SetScript("OnEvent", function(self, event)
	if event == "AUCTION_HOUSE_SHOW" then
		wipe(boughtInfo)
		pendingPurchase = nil
		CreateButton()
		Refresh()
		return
	end

	if event == "COMMODITY_PURCHASE_SUCCEEDED" then
		--买的东西先进邮箱,背包数量不变,先按已买数量补上
		local display = GetDisplay()
		if pendingPurchase and display and display:GetItemID() == pendingPurchase.itemID then
			local info = pendingPurchase
			local old = boughtInfo[info.itemID]
			if old then
				info.quantity = info.quantity + old.quantity
				info.bagCount = old.bagCount
			end
			boughtInfo[info.itemID] = info
		end
		pendingPurchase = nil
		Refresh()
		return
	end

	if buyButton and buyButton:IsShown() then
		Refresh()
	end
end)
