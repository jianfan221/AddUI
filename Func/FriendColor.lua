local _,ns = ...

if SocialUIFrame then
	ns.tips("好友列表卡片重新布局")
	-- ⚠️ 卡片是暴雪框体：自建文本别写成 self.AddUIxxx 字段（会染脏暴雪对象），用弱键表存
	local raceTexts = setmetatable({}, {__mode = "k"})
	ns.hook(FriendsListSocialCardMixin, "Initialize", function(self, node)
		-- 重排：一行 战网名 + 角色名，二行 等级 种族 职业，三行 位置-服务器(暴雪默认文本)
		local gameAccountInfo = self.elementData and self.elementData.accountInfo and self.elementData.accountInfo.gameAccountInfo

		self.FriendName:SetPoint("TOPLEFT", self.TextHolder, "TOPLEFT", 5, 8)

		self.Name:ClearAllPoints()
		self.Name:SetPoint("LEFT", self.FriendName, "RIGHT", 4, 0)
		self.Name:SetFontObject(self.FriendName:GetFontObject())
		self.Name:SetWidth(0)

		self.StateDisplay:ClearAllPoints()
		self.StateDisplay:SetPoint("LEFT", self.Name, "RIGHT", 2, 0)

		self.Level:Show()
		self.Level:ClearAllPoints()
		self.Level:SetPoint("TOPLEFT", self.FriendName, "BOTTOMLEFT", 0, -2)

		-- 种族：自建 FontString，跟在职业后面（暴雪没有种族文本）
		local raceText = raceTexts[self]
		if not raceText then
			raceText = self:CreateFontString(nil, "ARTWORK")
			local fontObject = self.Level:GetFontObject()
			if fontObject then
				raceText:SetFontObject(fontObject)
			else
				raceText:SetFont(self.Level:GetFont())
			end
			raceTexts[self] = raceText
		end

		self.Class:Show()
		self.Class:ClearAllPoints()
		self.Class:SetPoint("LEFT", self.Level, "RIGHT", 6, 0)

		local raceName = gameAccountInfo and gameAccountInfo.raceName
		local hasRace = raceName ~= nil and raceName ~= ""
		raceText:ClearAllPoints()
		raceText:SetPoint("LEFT", self.Class, "RIGHT", 6, 0)
		raceText:SetText(hasRace and raceName or "")
		raceText:SetShown(hasRace)

		self.Location:ClearAllPoints()
		self.Location:SetPoint("TOPLEFT", self.Level, "BOTTOMLEFT", 0, -2)

		-- 位置栏按旧版信息栏样式：优先 richPresence，否则 区域-服务器（离线保留暴雪的“上次在线”）
		if gameAccountInfo and gameAccountInfo.isOnline then
			local rich = gameAccountInfo.richPresence
			local areaName = gameAccountInfo.areaName or ""
			local realmName = gameAccountInfo.realmDisplayName or gameAccountInfo.realmName
			local text = (rich ~= nil and rich ~= "") and rich or (areaName ~= "" and realmName and (areaName .. "-" .. realmName) or areaName)
			self.Location:SetText(FRIENDS_GRAY_COLOR:WrapTextInColorCode(text))
		end

		-- Name 改为职业颜色
		if gameAccountInfo and gameAccountInfo.characterName and gameAccountInfo.classFilename and gameAccountInfo.classFilename ~= "" then
			local color = GetClassColorObj(gameAccountInfo.classFilename)
			if color then
				self.Name:SetText(color:WrapTextInColorCode(gameAccountInfo.characterName))
			end
		end

		-- 等级按与自己等级差上色（暴雪等级文本自带内联颜色码，这里重设成带难度色的文本）
		local level = gameAccountInfo and gameAccountInfo.characterLevel
		if level and level > 0 then
			local fmt = SOCIAL_UI_RECENT_ALLIES_CARD_LEVEL_DISPLAY_FORMAT
			local color = GetQuestDifficultyColor(level) or {r = 1, g = 1, b = 1}
			local text = fmt and string.format(fmt, level) or tostring(level)
			self.Level:SetText(CreateColor(color.r, color.g, color.b):WrapTextInColorCode(text))
		end
		-- 不同游戏版本：整卡变暗（暴雪给图标的 0.6 会相乘，复位避免过淡）
		local projectID = gameAccountInfo and gameAccountInfo.wowProjectID
		local dim = projectID and projectID ~= WOW_PROJECT_ID
		self:SetAlpha(dim and 0.33 or 1)
		if dim then
			self.GameIconHolder.Icon:SetAlpha(1)
		end
	end)

	-- 可邀请时变绿色，其他情况恢复默认
	ns.hook(FriendsListSocialCardPartyButtonMixin, "RefreshIcon", function(btn)
		if btn:IsEnabled() and not btn.isInGroup then
			btn.ActionIcon:SetVertexColor(0,1,0)
		else
			btn.ActionIcon:SetVertexColor(1,1,1)
		end
	end)
end


-- SocialUI 取代了原生的好友列表卡片，下面的代码仅在 SocialUI 不存在时生效
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
ns.event("PLAYER_LOGIN", function()
	if FriendsFrameStatusDropdown then
		FriendsFrameStatusDropdown:SetWidth(56)
	end
end)

ns.hook("FriendsFrame_UpdateFriendButton", function(friendbutton)
	if not FriendsListFrame or not FriendsListFrame:IsShown() then return end
	if not friendbutton.id then return end
	if friendbutton.buttonType == 3 then return end
	local info = C_BattleNet.GetFriendAccountInfo(friendbutton.id)
	if not info or not info.gameAccountInfo then return end
	local accountInfo = info.gameAccountInfo
	local areaName = accountInfo.areaName or ""	--区域名
	local realmDisplayName = accountInfo.realmDisplayName	--服务器
	local characterName = accountInfo.characterName --角色名
	local bnname = Ambiguate(info.battleTag,"short")	--战网名
	local level = accountInfo.characterLevel	--等级
	
	--local factionName = accountInfo.factionName--阵营
	local gamename = accountInfo.wowProjectID	--游戏id,1是正式服,11是wlk
	local rich = accountInfo.richPresence	--丰富返回游戏版本-区域-服务器
	--local timerunningSeasonID = accountInfo.timerunningSeasonID --赛季ID用于幻彩服务器

	--标题栏（直接用职业文件名索引 RAID_CLASS_COLORS，无需遍历）
	local classFilename = accountInfo.classFilename
	local class = characterName and classFilename and RAID_CLASS_COLORS[classFilename]
	if class then
		friendbutton.name:SetText(format("%s|c%s (%s)|r    ", bnname, class.colorStr, characterName))
	end
	local realmName = realmDisplayName or ""	--nil 兜底，否则下面 .. 会报 attempt to concatenate a nil value
	local infoText
	if accountInfo.isOnline then
		local rich2 = (rich ~= nil and rich ~= "") and rich or (areaName ~= "" and realmName ~= "" and (areaName.."-"..realmName) or areaName)
		infoText = (level and level > 0) and (rich2 ~= "" and (rich2.." - "..level) or tostring(level)) or rich2
	else
		--离线：显示"上次在线 xxx"（暴雪默认就是这个，别被上面的拼接逻辑清空）
		infoText = FriendsFrame_GetLastOnlineText and FriendsFrame_GetLastOnlineText(info) or FRIENDS_LIST_OFFLINE
	end
	friendbutton.info:SetText(infoText)
	--对比游戏版本：和自己同一个游戏项目 → 不透明，其它版本 → 0.5
	--⚠️ 不能用 gamename == 1 判断（那只代表正式服），要用 WOW_PROJECT_ID，否则在无限服/怀旧服会把同服好友全变暗
	local alpha = (not gamename or gamename == WOW_PROJECT_ID) and 1 or 0.33
	friendbutton.name:SetAlpha(alpha)
	friendbutton.info:SetAlpha(alpha)
end)





