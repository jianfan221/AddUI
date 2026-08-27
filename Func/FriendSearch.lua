local _,ns = ...

-- SocialUIFrame 搜索框即时搜索（12.1 PTR 新好友列表）
-- 暴雪默认只在按回车时触发搜索，改为文字改变时即时触发
do
	local view = SocialUIFrame and SocialUIFrame.FriendsList
	local sb = view and view.FilterBar and view.FilterBar.SearchBar

	local function DoSearch()
		if not view or not view.OnSearchEnterPressed then return end
		local text = sb:GetText():lower()
		if text == "" then
			view:OnSearchEnterPressed("")
			return
		end
		local filtered = {}
		for i = 1, BNGetNumFriends() do
			local info = C_BattleNet.GetFriendAccountInfo(i)
			if info then
				local match = (info.battleTag or ""):lower():find(text, 1, true)
					or (info.gameAccountInfo.characterName or ""):lower():find(text, 1, true)
					or (info.gameAccountInfo.className or ""):lower():find(text, 1, true)
					or (info.gameAccountInfo.areaName or ""):lower():find(text, 1, true)
					or (info.gameAccountInfo.realmDisplayName or ""):lower():find(text, 1, true)
				if match then tinsert(filtered, i) end
			end
		end
		C_Timer.After(0, function()
			view.ScrollBox:SetDataProvider(view:GenerateDataProvider(filtered), ScrollBoxConstants.DiscardScrollPosition)
		end)
	end

	if sb then
		sb:HookScript("OnTextChanged", DoSearch)--搜索框文字改变时触发搜索
		sb:HookScript("OnShow", DoSearch)-- 显示时也触发搜索，避免搜索框隐藏后再显示时列表不刷新
		ns.hook(view, "Refresh", DoSearch)-- 好友列表刷新（上线/下线等）后重新搜索
		sb:SetScript("OnEnterPressed", function() sb:ClearFocus() end)--回车取消焦点
	end

end

--判断好友信息是否匹配搜索文本（空文本表示不过滤）
local function Matches(searchText, ...)
	if #searchText == 0 then return true end
	for i = 1, select("#", ...) do
		local field = select(i, ...)
		if field and field:find(searchText, 1, true) then
			return true
		end
	end
	return false
end

--抄自FriendListHelper
local function UpdateFriendList(searchText)
	if not FriendsListFrame or not FriendsListFrame:IsShown() then return end
	local dataProvider = CreateDataProvider()
	local numOnline = C_FriendList.GetNumOnlineFriends() or 0
	local numFriends = C_FriendList.GetNumFriends() or 0

	--好友请求
	if BNGetNumFriendInvites() > 0 then
		for i = 1, BNGetNumFriendInvites() do
			dataProvider:Insert({id=i, buttonType=FRIENDS_BUTTON_TYPE_INVITE})
		end
	end
	--在线
	for i = 1, numOnline do
		local accountInfo = C_FriendList.GetFriendInfoByIndex(i)
		if accountInfo then
			if Matches(searchText,
				(accountInfo.name or ""):lower(),
				(accountInfo.className or ""):lower(),
				(accountInfo.areaName or ""):lower()) then
				dataProvider:Insert({id = i, buttonType = FRIENDS_BUTTON_TYPE_WOW})
			end
		end
	end

	--战网好友
	for i = 1, BNGetNumFriends() do
		local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
		if accountInfo then
			local gai = accountInfo.gameAccountInfo
			if Matches(searchText,
				(accountInfo.battleTag or ""):lower(),
				(gai.characterName or ""):lower(),
				(gai.className or ""):lower(),
				(gai.areaName or ""):lower()) then
				dataProvider:Insert({id = i, buttonType = FRIENDS_BUTTON_TYPE_BNET})
			end
		end
	end
	--离线
	for i = numOnline + 1, numFriends do
		local accountInfo = C_FriendList.GetFriendInfoByIndex(i)
		if accountInfo then
			if Matches(searchText,
				(accountInfo.name or ""):lower(),
				(accountInfo.className or ""):lower()) then
				dataProvider:Insert({id = i, buttonType = FRIENDS_BUTTON_TYPE_WOW})
			end
		end
	end

	FriendsListFrame.ScrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)
end

local function AddSearchBar()
    if not FriendsListFrame then return end
	if FriendListHelper_SearchBar then return end

    local searchBar = CreateFrame("EditBox", "FriendListHelper_SearchBar", FriendsListFrame, "SearchBoxTemplate")
    searchBar:SetSize(130, 22)--大小
	searchBar:SetScale(1.1)
    searchBar:SetPoint("BOTTOMRIGHT", FriendsFrameInset, "TOPRIGHT", 0, 0)--位置
    searchBar:SetAutoFocus(false)
    SearchBoxTemplate_OnLoad(searchBar)

    local activeSearchText = ""
    local isSearchActive = false

    -- 用户输入搜索时：始终刷新列表（含清空恢复全量）
    local function DoSearch()
        UpdateFriendList(activeSearchText or "")
    end

    -- 好友列表被暴雪刷新时：只在有搜索时重新应用过滤；无搜索时交给暴雪维护
    -- 避免每次刷新都重建全量 provider（叠加暴雪自己的 SetDataProvider）导致内存增长
    local function DoSearchOnRefresh()
        if isSearchActive and activeSearchText then
            UpdateFriendList(activeSearchText)
        end
    end

    searchBar:SetScript("OnTextChanged", function(self)
        SearchBoxTemplate_OnTextChanged(self)--让清除按钮/提示文本正常显隐
        activeSearchText = self:GetText():lower()

        isSearchActive = (#activeSearchText > 0)

        DoSearch()
    end)

    searchBar:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()  -- 回车取消焦点
    end)

    -- 好友列表刷新（好友上线/下线、信息变化、请求变化等）时重新应用搜索
    ns.hook("FriendsList_Update", DoSearchOnRefresh)

    return searchBar
end

ns.event("PLAYER_LOGIN", function()
	if not AddUIDB.Friend then return end
    AddSearchBar()
end)