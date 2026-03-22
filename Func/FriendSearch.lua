local _,ns = ...
ns.tips("好友列表添加搜索好友按钮")
--抄自FriendListHelper
local function UpdateFriendList(searchText)
	if not FriendsListFrame or not FriendsListFrame:IsShown() then return end
    local dataProvider = CreateDataProvider()
	--好友请求
	if ( BNGetNumFriendInvites() > 0 ) then
		--dataProvider:Insert({buttonType=FRIENDS_BUTTON_TYPE_INVITE_HEADER});--展开加好友的列表
		for i = 1, BNGetNumFriendInvites() do
			dataProvider:Insert({id=i, buttonType=FRIENDS_BUTTON_TYPE_INVITE});
		end
	end
	--在线
	if C_FriendList.GetNumOnlineFriends() and C_FriendList.GetNumOnlineFriends() > 0 then
		for i = 1, C_FriendList.GetNumOnlineFriends() do
			local accountInfo = C_FriendList.GetFriendInfoByIndex(i)
			
			if accountInfo then
				local battleTag = (accountInfo.battleTag or ""):lower()
				local characterName = (accountInfo.name or ""):lower()
				local characterClass = (accountInfo.className or ""):lower()
				local characterAreaName = (accountInfo.areaName or ""):lower()
				if #searchText == 0 
					or characterName:find(searchText, 1, true) 
					or characterClass:find(searchText, 1, true) 
					or characterAreaName:find(searchText, 1, true) 
					then
					dataProvider:Insert({id = i, buttonType = FRIENDS_BUTTON_TYPE_WOW})
				end
			end
		end
	end
	
	--战网好友
	if BNGetNumFriends() and BNGetNumFriends() > 0 then
		for i = 1, BNGetNumFriends() do
			local accountInfo = C_BattleNet.GetFriendAccountInfo(i)
			if accountInfo then
				local battleTag = (accountInfo.battleTag or ""):lower()
				local characterName = (accountInfo.gameAccountInfo.characterName or ""):lower()
				local characterClass = (accountInfo.gameAccountInfo.className or ""):lower()
				local characterAreaName = (accountInfo.gameAccountInfo.areaName or ""):lower()
				if #searchText == 0 or battleTag:find(searchText, 1, true) 
					or characterName:find(searchText, 1, true) 
					or characterClass:find(searchText, 1, true) 
					or characterAreaName:find(searchText, 1, true) 
					then
					dataProvider:Insert({id = i, buttonType = FRIENDS_BUTTON_TYPE_BNET})
				end
			end
		end
	end
	--离线
	if C_FriendList.GetNumFriends() and C_FriendList.GetNumOnlineFriends() and C_FriendList.GetNumFriends() >= (C_FriendList.GetNumOnlineFriends()+1) then
		for i = C_FriendList.GetNumOnlineFriends()+1,C_FriendList.GetNumFriends() do
			local accountInfo = C_FriendList.GetFriendInfoByIndex(i)
			if accountInfo then
				local battleTag = (accountInfo.battleTag or ""):lower()
				local characterName = (accountInfo.name or ""):lower()
				local characterClass = (accountInfo.className or ""):lower()
				if #searchText == 0 
					or characterName:find(searchText, 1, true) 
					or characterClass:find(searchText, 1, true) 
					then
					dataProvider:Insert({id = i, buttonType = FRIENDS_BUTTON_TYPE_WOW})
				end
			end
		end
	end

    FriendsListFrame.ScrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)
end

local function AddSearchBar()
    if not FriendsListFrame then return end
	if FriendListHelper_SearchBar then return end

    local searchBar = CreateFrame("EditBox", "FriendListHelper_SearchBar", FriendsListFrame, "InputBoxTemplate")
    searchBar:SetSize(130, 20)--大小
	searchBar:SetScale(1.1)
    searchBar:SetPoint("BOTTOMRIGHT", FriendsFrameInset, "TOPRIGHT", 0, 0)--位置
    searchBar:SetAutoFocus(false)
    searchBar:SetText("")
    searchBar:ClearFocus()
    searchBar:Show()

    local placeholder = searchBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
    placeholder:SetPoint("LEFT", searchBar, "LEFT", 0, 0)
    placeholder:SetText(SEARCH..":"..NAME.."/"..CLASS)--默认文本
    placeholder:SetTextColor(0.5, 0.5, 0.5, 0.7)


    local activeSearchText = ""
    local isSearchActive = false

	--添加清除按钮
	local ClearBox = CreateFrame("Button", nil, searchBar)
	ClearBox:SetPoint("RIGHT", -5, 0)
	ClearBox:SetSize(13, 13)
	ClearBox:SetNormalTexture("common-search-clearbutton")
	ClearBox:SetHighlightTexture("common-search-clearbutton")
	ClearBox:SetScript("OnClick", function()
		searchBar:SetText("")
		searchBar:GetScript("OnTextChanged")(searchBar)
	end)
	
	searchBar:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()  -- 回车取消焦点
	end)
	
	local function UpdatePlaceholder()
        if searchBar:GetText() == "" then
            placeholder:Show()
        else
            placeholder:Hide()
        end
    end
	
    searchBar:SetScript("OnTextChanged", function(self)
		ClearBox:SetShown(self:GetText() ~= "" or self:HasFocus())
        UpdatePlaceholder()
        activeSearchText = self:GetText():lower()

        isSearchActive = (#activeSearchText > 0)

        UpdateFriendList(activeSearchText)
    end)

    hooksecurefunc("FriendsList_Update", function()
        if isSearchActive and activeSearchText then
            UpdateFriendList(activeSearchText)
        else
            UpdateFriendList("")
        end
    end)

    searchBar:SetScript("OnEditFocusGained", function()
        placeholder:Hide()
		ClearBox:Show()
    end)

    searchBar:SetScript("OnEditFocusLost", function(self)
		ClearBox:SetShown(self:GetText() ~= "" or self:HasFocus())
        UpdatePlaceholder()
    end)

    UpdatePlaceholder()

    return searchBar
end

ns.event("PLAYER_LOGIN", function()
	if not AddUIDB.Friend then return end
    AddSearchBar()
end)