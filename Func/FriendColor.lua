local _,_,_,mygame = GetBuildInfo()
local _,ns = ...

ns.tips("好友列表卡片重新布局")
if FriendsListSocialCardMixin and FriendsListSocialCardMixin.Initialize then
    local orig = FriendsListSocialCardMixin.Initialize
    FriendsListSocialCardMixin.Initialize = function(self, node)
        orig(self, node)
        self:SetHeight(35)

        -- 重排文字：一行 FriendName Name，二行 Level Class Location
        self.FriendName:SetPoint("TOPLEFT", self.TextHolder, "TOPLEFT", 5, 8)
        self.Name:ClearAllPoints()
        self.Name:SetPoint("BOTTOMLEFT", self.FriendName, "BOTTOMRIGHT", 4, 0)
        self.Name:SetPoint("BOTTOM", self.FriendName)
        self.Name:SetWidth(0)
        self.Name:SetFontObject(self.FriendName:GetFontObject())
        self.StateDisplay:ClearAllPoints()
        self.StateDisplay:SetPoint("BOTTOMLEFT", self.Name, "BOTTOMRIGHT", -2, -1)

        self.Level:Hide()
        self.Class:Hide()

        self.Location:ClearAllPoints()
        self.Location:SetPoint("TOPLEFT", self.FriendName, "BOTTOMLEFT", 0, -2)

        -- Level、Class、realm 都用 Location 的颜色（FRIENDS_GRAY_COLOR）
        local gameAccountInfo = self.elementData and self.elementData.accountInfo and self.elementData.accountInfo.gameAccountInfo
        if gameAccountInfo then
            local parts = {}
            if gameAccountInfo.areaName then tinsert(parts, gameAccountInfo.areaName) end
            if gameAccountInfo.realmDisplayName then tinsert(parts, gameAccountInfo.realmDisplayName) end
            if gameAccountInfo.characterLevel then tinsert(parts, gameAccountInfo.characterLevel) end
            if #parts > 0 then
                self.Location:SetText(FRIENDS_GRAY_COLOR:WrapTextInColorCode(table.concat(parts, " ")))
            end
        end

        -- Name 改为职业颜色
        if gameAccountInfo and gameAccountInfo.characterName and gameAccountInfo.classFilename and gameAccountInfo.classFilename ~= "" then
            local color = GetClassColorObj(gameAccountInfo.classFilename)
            if color then
                self.Name:SetText(color:WrapTextInColorCode(gameAccountInfo.characterName))
            end
        end
    end
end
local view = SocialUIFrame and SocialUIFrame.FriendsList
if view and view.GetTemplateExtent then
    local orig = view.GetTemplateExtent
    view.GetTemplateExtent = function(self, template)
        local extent = orig(self, template)
        if template == "FriendsListSocialCardTemplate" then
            return extent / 2
        end
        return extent
    end
end

ns.tips("隐藏好友列表战网ID,点击时显示") 
if SocialUIFrame then
    local tagFrame = SocialUIFrame.BattleNetBar and SocialUIFrame.BattleNetBar.ControlsContainer and SocialUIFrame.BattleNetBar.ControlsContainer.PersonalBattleTagDisplay
    if tagFrame and tagFrame.ShowBestDisplayTextAndButton then
        local hidden = true

        local cover = CreateFrame("Button", nil, tagFrame)
        cover:SetAllPoints()
        cover:RegisterForClicks("AnyUp")
        cover:SetScript("OnClick", function()
            hidden = not hidden
            tagFrame.DisplayText:SetShown(not hidden)
            tagFrame.CopyBattleTagToClipboardButton:SetShown(not hidden)
        end)

        -- 初始隐藏
        tagFrame.DisplayText:Hide()
        tagFrame.CopyBattleTagToClipboardButton:Hide()

        -- Hook 暴雪的显示方法，根据 hidden 状态决定是否重新隐藏
        -- 暴雪在 BN_CONNECTED/PLAYER_ENTERING_WORLD/FRAMES_LOADED 等事件中
        -- 通过 RefreshElementVisibility → ShowBestDisplayTextAndButton 重新显示
        local origShow = tagFrame.ShowBestDisplayTextAndButton
        tagFrame.ShowBestDisplayTextAndButton = function(self)
            origShow(self)
            if hidden then
                self.DisplayText:Hide()
                self.CopyBattleTagToClipboardButton:Hide()
            end
        end
    end
end

-- 12.1 正式上线后可删除（已被 SocialUI 取代）
--隐藏好友列表战网ID,点击时显示
local HideBattleIDclick = true
local HideBattleID = CreateFrame("Button", "HideBattleID", FriendsFrameBattlenetFrame);
HideBattleID:SetAllPoints(FriendsFrameBattlenetFrame); 
HideBattleID:RegisterForClicks("AnyUp");
HideBattleID:SetScript("OnClick", function() 
	if FriendsFrameBattlenetFrame.Tag:IsShown() then
		HideBattleIDclick = true
		FriendsFrameBattlenetFrame.Tag:Hide()
	else
		HideBattleIDclick = nil
		FriendsFrameBattlenetFrame.Tag:Show()
	end
end)
FriendsFrameBattlenetFrame.Tag:HookScript("OnShow", function(self)
	if HideBattleIDclick then
		self:Hide()
	end
end)

-- 12.1 正式上线后可删除（已被 SocialUI 取代）
ns.hook("FriendsFrame_UpdateFriendButton", function(friendbutton)
	if not FriendsListFrame or not FriendsListFrame:IsShown() then return end
	if not friendbutton.id then return end
	if friendbutton.buttonType == 3 then return end
	local info = C_BattleNet.GetFriendAccountInfo(friendbutton.id)
	if not info then return end
	local accountInfo = info.gameAccountInfo
	local areaName = accountInfo.areaName	--区域名
	local realmDisplayName = accountInfo.realmDisplayName	--服务器
	local characterName = accountInfo.characterName --角色名
	local bnname = Ambiguate(info.battleTag,"short")	--战网名
	local className = accountInfo.className	--职业名
	local level = accountInfo.characterLevel	--等级
	--local factionName = accountInfo.factionName--阵营
	local gamename = accountInfo.wowProjectID	--游戏id,1是正式服,11是wlk
	local rich = accountInfo.richPresence	--丰富返回游戏版本-区域-服务器
	local timerunningSeasonID = accountInfo.timerunningSeasonID --赛季ID用于幻彩服务器
	--标题栏
	local class
	if characterName and className then
		for k, v in pairs(LOCALIZED_CLASS_NAMES_MALE) do
			if v == className then
				class =RAID_CLASS_COLORS[k].colorStr
			end
		end
		friendbutton.name:SetText(bnname.."|c"..class.." ("..characterName..")".."|r    ")
	end

	--信息栏
	if realmDisplayName and areaName and gamename == 1 then
		if timerunningSeasonID then--如果在赛季服
			friendbutton.info:SetText("|A:timerunning-glues-icon:12:12:0:0|a"..areaName.."-"..realmDisplayName.."-"..level)
		else
			friendbutton.info:SetText(areaName.."-"..realmDisplayName.."-"..level)
		end
	elseif areaName and gamename == 14 then
		local _,fwq = strsplit("-",rich)	--怀旧服只要服务器名字
		if realmDisplayName then
			friendbutton.info:SetText("CTM".."-"..areaName.."-"..realmDisplayName.."-"..level)
		elseif fwq then
			friendbutton.info:SetText("CTM".."-"..areaName.."-"..fwq.."-"..level)
		end
	elseif areaName and gamename == 11 then
		local _,fwq = strsplit("-",rich)	--怀旧服只要服务器名字
		if realmDisplayName then
			friendbutton.info:SetText("WLK".."-"..areaName.."-"..realmDisplayName.."-"..level)
		elseif fwq then
			friendbutton.info:SetText("WLK".."-"..areaName.."-"..fwq.."-"..level)
		end
	elseif areaName and gamename == 2 then
		local _,fwq = strsplit("-",rich)	--怀旧服只要服务器名字
		if realmDisplayName then
			friendbutton.info:SetText("(怀旧60)".."-"..areaName.."-"..realmDisplayName.."-"..level)
		elseif fwq then
			friendbutton.info:SetText("(怀旧60)".."-"..areaName.."-"..fwq.."-"..level)
		end
	end
	--对比游戏版本
	if mygame > 90000 then
		if not gamename or gamename == 1 then
			friendbutton.name:SetAlpha(1)
			friendbutton.info:SetAlpha(1)
		else
			friendbutton.name:SetAlpha(.4)
			friendbutton.info:SetAlpha(.4)
		end
	end
end)





