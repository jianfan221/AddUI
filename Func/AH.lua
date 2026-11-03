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

--═══════════ 拍卖行收藏夹 ═══════════
ns.tips("拍卖行收藏夹自动保存, 所有角色按同一份清单同步")

local favoriteHooked
local restoringFavorites -- 同步过程中不要让 hook 回写清单
local syncing -- 防止对齐过程重入
local syncedThisOpen -- 本次打开拍卖行是否已完成对齐
local pendingSync

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

--手动增删收藏都记进清单
local function EnsureFavoriteHook()
	if favoriteHooked then
		return
	end
	favoriteHooked = true

	ns.hook(C_AuctionHouse, "SetFavoriteItem", function(itemKey, setFavorite)
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

--按清单把收藏全部加给当前角色
local function AddAllFavorites()
	restoringFavorites = true
	for _, itemKey in pairs(AddUIDB.AHFavoritesDB) do
		if type(itemKey) == "table" and itemKey.itemID and not C_AuctionHouse.HasMaxFavorites() then
			C_AuctionHouse.SetFavoriteItem(CopyItemKey(itemKey), true)
		end
	end
	restoringFavorites = nil
end

--当前角色的收藏列表(暴雪打开拍卖行时会自己查), 没拉完就继续拉
local function GetFavoriteResults()
	if not AuctionHouseFrame or not AuctionHouseFrame.isDisplayingFavorites then
		return
	end

	local results = C_AuctionHouse.GetBrowseResults()
	if not results or not next(results) then
		return
	end

	if not C_AuctionHouse.HasFullBrowseResults() then
		C_AuctionHouse.RequestMoreBrowseResults()
		return
	end
	return results
end

--增删后重新查一次收藏, 让列表刷新(等服务器把增删处理完)
local function RefreshFavoriteList()
	C_Timer.After(0.2, function()
		local frame = AuctionHouseFrame
		if not frame or not frame.isDisplayingFavorites then
			return
		end
		frame:QueryAll(AuctionHouseSearchContext.AllFavorites)
	end)
end

--清单与当前角色收藏双向对齐: 清单里没有的删掉, 清单里缺的补上
local function SyncFavorites(results)
	if syncing or not results then
		return
	end
	syncing = true

	local gameKeys = {}
	for _, info in ipairs(results) do
		local itemKey = info.itemKey
		if itemKey and itemKey.itemID then
			gameKeys[GetItemKeyHash(itemKey)] = CopyItemKey(itemKey)
		end
	end

	local changed
	restoringFavorites = true
	if not next(AddUIDB.AHFavoritesDB) then
		--还没有清单: 把当前角色的收藏全部存下来
		for hash, itemKey in pairs(gameKeys) do
			AddUIDB.AHFavoritesDB[hash] = itemKey
		end
	else
		--游戏里多出来的删掉
		for hash, itemKey in pairs(gameKeys) do
			if not AddUIDB.AHFavoritesDB[hash] then
				C_AuctionHouse.SetFavoriteItem(itemKey, false)
				changed = true
			end
		end
		--清单里缺的补上
		for hash, itemKey in pairs(AddUIDB.AHFavoritesDB) do
			if not gameKeys[hash] and not C_AuctionHouse.HasMaxFavorites() then
				C_AuctionHouse.SetFavoriteItem(CopyItemKey(itemKey), true)
				changed = true
			end
		end
	end
	restoringFavorites = nil

	syncing = nil
	syncedThisOpen = true

	if changed then
		RefreshFavoriteList()
	end
end

--当前角色一个收藏都没有时暴雪不会去查收藏, 直接按清单补齐
local function SyncWithoutResults()
	if syncedThisOpen then
		return
	end

	local apiReady = C_AuctionHouse.FavoritesAreAvailable and C_AuctionHouse.FavoritesAreAvailable()
	if not apiReady then
		if not pendingSync then
			pendingSync = true
			C_Timer.After(0.25, function()
				pendingSync = nil
				SyncWithoutResults()
			end)
		end
		return
	end

	if next(AddUIDB.AHFavoritesDB) and not C_AuctionHouse.HasFavorites() then
		AddAllFavorites()
		syncedThisOpen = true
	end
end

--═══════════ 拍卖行过滤器 ═══════════
ns.tips("拍卖行过滤器每次重载后固定为: 仅限当前内容更新 + 全部品质")

local filterDefaulted

--固定状态: 暴雪默认 + 仅限当前内容更新
local function ApplyFixedFilters(filterState)
	filterState.filters = CopyTable(AUCTION_HOUSE_DEFAULT_FILTERS)
	filterState.filters[Enum.AuctionHouseFilter.CurrentExpansionOnly] = true
	filterState.minLevel, filterState.maxLevel = 0, 0
end

--═══════════ 常驻勾选框: 仅限当前内容更新 ═══════════
ns.tips("过滤器挪到搜索栏左边, 原位放常驻的「仅限当前内容更新」勾选框")

local expansionCheck

--勾选框状态与过滤器状态对齐
local function SyncExpansionCheck()
	local filterState = _G.g_auctionHouseFilters
	if not expansionCheck or not filterState then return end
	expansionCheck:SetChecked(filterState.filters[Enum.AuctionHouseFilter.CurrentExpansionOnly] and true or false)
end

--只在带搜索栏的页面显示, 时光徽章页用不上
local function UpdateExpansionCheckVisible()
	if not expansionCheck then return end
	local mode = AuctionHouseFrame:GetDisplayMode()
	expansionCheck:SetShown(mode ~= AuctionHouseFrameDisplayMode.WoWTokenBuy and mode ~= AuctionHouseFrameDisplayMode.ItemSell
		and mode ~= AuctionHouseFrameDisplayMode.CommoditiesSell and mode ~= AuctionHouseFrameDisplayMode.WoWTokenSell
		and mode ~= AuctionHouseFrameDisplayMode.Auctions)
end

local function CreateExpansionCheck()
	if expansionCheck or not AuctionHouseFrame then return end

	local bar = AuctionHouseFrame.SearchBar

	--过滤器按钮挪到搜索栏左边的空白处, 腾出原来的位置给勾选框
	bar.FilterButton:ClearAllPoints()
	bar.FilterButton:SetPoint("RIGHT", bar.FavoritesSearchButton, "LEFT", -12, 0)

	local check = CreateFrame("CheckButton", nil, bar, "UICheckButtonArtTemplate")
	check:SetSize(25, 25)
	check:SetPoint("LEFT", bar.SearchBox, "RIGHT", 20, 0)

	local label = check:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("LEFT", check, "RIGHT", -2, 0)
	label:SetJustifyH("RIGHT")
	label:SetText(_G.AUCTION_HOUSE_FILTER_CURRENTEXPANSION_ONLY or "仅限当前内容更新")
	

	check:SetScript("OnClick", function(self)
		local filterState = _G.g_auctionHouseFilters
		if not filterState then return end
		filterState.filters[Enum.AuctionHouseFilter.CurrentExpansionOnly] = self:GetChecked() and true or false
		local searchBar = AuctionHouseFrame.SearchBar
		searchBar:UpdateClearFiltersButton()
		--浏览页按新条件立即重查(查看物品/商品详情时不动)
		if AuctionHouseFrame:GetDisplayMode() == AuctionHouseFrameDisplayMode.Buy and not AuctionHouseFrame.isDisplayingFavorites then
			searchBar:StartSearch()
		end
	end)

	expansionCheck = check
	SyncExpansionCheck()
	UpdateExpansionCheckVisible()

	--过滤器下拉里改动或清空时同步过来
	ns.hook(AuctionHouseFrame.SearchBar, "UpdateClearFiltersButton", SyncExpansionCheck)
	ns.hook(AuctionHouseFrame.SearchBar.FilterButton, "Reset", SyncExpansionCheck)
	ns.hook(AuctionHouseFrame, "SetDisplayMode", UpdateExpansionCheckVisible)
end

--═══════════ 事件 ═══════════
ns.event("AUCTION_HOUSE_SHOW", function()
	AddUIDB.AHFavoritesDB = AddUIDB.AHFavoritesDB or {}
	syncedThisOpen = nil

	--过滤器: 重载后第一次打开恢复固定状态
	local filterState = _G.g_auctionHouseFilters
	if filterState and not filterDefaulted then
		filterDefaulted = true
		ApplyFixedFilters(filterState)
	end
	local bar = AuctionHouseFrame.SearchBar
	CreateExpansionCheck()
	bar:UpdateClearFiltersButton()
	SyncExpansionCheck()

	EnsureFavoriteHook()
	SyncWithoutResults()
end)

--暴雪的收藏查询结果回来后与清单对齐
ns.event("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", function()
	if syncedThisOpen or syncing then
		return
	end
	SyncFavorites(GetFavoriteResults())
end)