local _,ns = ...
ns.tips("按alt一次买一组,去除二次确认框")
local savedMerchantItemButton_OnModifiedClick = MerchantItemButton_OnModifiedClick
function MerchantItemButton_OnModifiedClick(self, ...)
	if IsAltKeyDown() then
		local stack = GetMerchantItemMaxStack(self:GetID()) or 1
		BuyMerchantItem(self:GetID(), stack)
	end
	savedMerchantItemButton_OnModifiedClick(self, ...)
end

ns.tips("拍卖行收藏夹会自动保存并恢复")
local function CopyItemKey(itemKey)
	if not itemKey then
		return
	end

	return {
		itemID = itemKey.itemID,
		itemLevel = itemKey.itemLevel or 0,
		itemSuffix = itemKey.itemSuffix or 0,
		battlePetSpeciesID = itemKey.battlePetSpeciesID or 0,
	}
end

local function GetItemKeyHash(itemKey)
	if not itemKey then
		return
	end

	return string.format("%d:%d:%d:%d", itemKey.itemID or 0, itemKey.itemLevel or 0, itemKey.itemSuffix or 0, itemKey.battlePetSpeciesID or 0)
end

--拍卖行保存过滤AHFilterRestoreDB
local favoriteHooked
local restoringFavorites
local pendingRestore

local function EnsureFavoriteHook()
	if favoriteHooked then
		return
	end
	favoriteHooked = true

	hooksecurefunc(C_AuctionHouse, "SetFavoriteItem", function(itemKey, setFavorite)
		if restoringFavorites or not itemKey then
			return
		end

		if type(AddUIDB.AHFavoritesDB) ~= "table" then
			AddUIDB.AHFavoritesDB = {}
		end

		local key = GetItemKeyHash(itemKey)
		if setFavorite then
			AddUIDB.AHFavoritesDB[key] = CopyItemKey(itemKey)
		else
			AddUIDB.AHFavoritesDB[key] = nil
		end
	end)
end

local function RestoreFavorites()
	if type(AddUIDB.AHFavoritesDB) ~= "table" or not next(AddUIDB.AHFavoritesDB) then
		return
	end

	local apiReady = C_AuctionHouse and C_AuctionHouse.FavoritesAreAvailable and C_AuctionHouse.FavoritesAreAvailable()
	if not apiReady then
		if not pendingRestore then
			pendingRestore = true
			C_Timer.After(0.25, function()
				pendingRestore = nil
				RestoreFavorites()
			end)
		end
		return
	end

	restoringFavorites = true
	for _, itemKey in pairs(AddUIDB.AHFavoritesDB) do
		if type(itemKey) == "table" and itemKey.itemID then
			C_AuctionHouse.SetFavoriteItem(CopyItemKey(itemKey), true)
		end
	end
	restoringFavorites = nil
end

local ahHooked
local function OnAuctionHouseShow(event)
	AddUIDB.AHFilterRestoreDB = AddUIDB.AHFilterRestoreDB or {}
	AddUIDB.AHFavoritesDB = AddUIDB.AHFavoritesDB or {}
	--设置拍卖行
	AuctionHouseFrame.SearchBar.FilterButton.filters = next(AddUIDB.AHFilterRestoreDB) and AddUIDB.AHFilterRestoreDB or
	CopyTable(AUCTION_HOUSE_DEFAULT_FILTERS)
	AuctionHouseFrame.SearchBar:UpdateClearFiltersButton()
	--设置hook
	if not ahHooked then
		hooksecurefunc(AuctionHouseFrame.SearchBar, "OnFilterToggled", function()
			local newFilter = AuctionHouseFrame.SearchBar.FilterButton:GetFilters()
			AddUIDB.AHFilterRestoreDB = newFilter
		end)
		
		AuctionHouseFrame.SearchBar.FilterButton.ClearFiltersButton:SetScript("OnClick", function()
			AuctionHouseFrame.SearchBar.FilterButton.filters = CopyTable(AUCTION_HOUSE_DEFAULT_FILTERS)
			AuctionHouseFrame.SearchBar.FilterButton.minLevel = 0
			AuctionHouseFrame.SearchBar.FilterButton.maxLevel = 0
			AuctionHouseFrame.SearchBar.FilterButton.ClearFiltersButton:Hide()
			wipe(AddUIDB.AHFilterRestoreDB)
		end)
		
		ahHooked = true
	end

	EnsureFavoriteHook()
	RestoreFavorites()
end

ns.event("AUCTION_HOUSE_SHOW", OnAuctionHouseShow)

--BlizzardInterfaceCode\Interface\FrameXML\UIParent
ns.tips("让拍卖行和专业界面可以同时打开")
function CanShowRightUIPanel(frame)
	local width = frame and GetUIPanelWidth(frame) or UIParent:GetAttribute("DEFAULT_FRAME_WIDTH");
	local rightSide = UIParent:GetAttribute("RIGHT_OFFSET") + width;
	if frame == AuctionHouseFrame or frame == ProfessionsFrame then
		return true
	else
		return rightSide <= GetMaxUIPanelsWidth();
	end
end
