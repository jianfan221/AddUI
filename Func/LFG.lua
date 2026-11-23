local _,ns = ...

-- 无限服（Camelot）寻求组队：在游戏风格后面显示队伍备注（正式服同类做法见下方 LFGList 部分）
if WOW_PROJECT_ID == WOW_PROJECT_CAMELOT then
	local function ShowComment(entry)
		local label = entry.PlaystyleLabel
		if not label then return end
		local info = entry.resultID and C_LFGList.GetSearchResultInfo(entry.resultID)
		local comment = info and info.comment
		if not entry.AddUIComment then
			entry.AddUIComment = entry:CreateFontString(nil, "ARTWORK")
			entry.AddUIComment:SetFont(STANDARD_TEXT_FONT, 15, "OUTLINE")
			entry.AddUIComment:SetWordWrap(false)
		end
		local text = entry.AddUIComment
		text:ClearAllPoints()
		-- 有游戏风格时贴在其右边；没有时直接占用游戏风格原来的位置
		local playstyle = label:GetText()
		if playstyle and playstyle ~= "" then
			text:SetPoint("LEFT", label, "RIGHT", 4, 0)
		else
			text:SetPoint("TOPLEFT", label, "TOPLEFT")
		end
		text:SetText(comment or "")
		if info and info.isDelisted then
			text:SetTextColor(0.3, 0.3, 0.3)
		else
			text:SetTextColor(0.9, 0.9, 0.9)
		end
	end

	local function HookVanillaLFG()
		if ns.vanillaLFGHooked or not LFGBrowseSearchEntry_Update then return end
		ns.vanillaLFGHooked = true
		ns.hook("LFGBrowseSearchEntry_Update", ShowComment)
	end

	-- 谁列表：每行加一键私聊求跨位面按钮
	local DEFAULT_WHISPER = "有空组个,求跨个位面,谢谢"

	local function GetWhisperText()
		local text = AddUIDB and AddUIDB.whoWhisperText
		if not text or text == "" then return DEFAULT_WHISPER end
		return text
	end

	-- 自己当前所在区域（谁列表里的「区域」是子区域名，尘泥沼泽 → 奥卡兹岛）
	local function GetMyZone()
		local zone = GetSubZoneText()
		if not zone or zone == "" then zone = GetZoneText() end
		return zone
	end

	local function InitWhoRow(self, elementData)
		if not self.AddUIWhisper then
			local btn = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
			btn:SetSize(60, 22)
			btn:SetPoint("TOPRIGHT", self, "TOPRIGHT", -80, -23)
			btn:SetText("密语")
			btn:SetScript("OnClick", function(button)
				if not button.whoName then return end
				C_ChatInfo.SendChatMessage(GetWhisperText(), "WHISPER", nil, button.whoName)
			end)
			btn:SetScript("OnEnter", function(button)
				if not button.whoName then return end
				GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
				GameTooltip:SetText("私聊 " .. button.whoName)
				GameTooltip:AddLine(GetWhisperText(), 1, 1, 1)
				GameTooltip:Show()
			end)
			btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
			self.AddUIWhisper = btn
		end
		local info = elementData.info
		local whoName = info and info.fullName
		local area = info and info.area
		local zone = GetMyZone()
		-- 只在「对方和自己同一区域」的行显示按钮
		local sameZone = area and zone and area ~= "" and
			(area == zone or area:find(zone, 1, true) or zone:find(area, 1, true))
		self.AddUIWhisper.whoName = whoName
		self.AddUIWhisper:SetShown(sameZone and whoName ~= nil and whoName ~= GetUnitName("player"))
	end

	-- 打开谁列表时输入框默认填本区域
	local function FillWhoZone()
		if not WhoFrameEditBox then return end
		local zone = GetMyZone()
		if zone and zone ~= "" then
			WhoFrameEditBox:SetText(zone)
		end
	end

	local function HookWhoList()
		if ns.whoListHooked or not LFGWhoListButtonMixin or not LFGWhoListFrame then return end
		ns.whoListHooked = true
		ns.hook(LFGWhoListButtonMixin, "InitButton", InitWhoRow)
		-- 帧的 OnShow 是注册到 C 侧的回调，hooksecurefunc 改字段无效，必须 HookScript
		LFGWhoListFrame:HookScript("OnShow", FillWhoZone)
		-- 关面板时本来就停在这一页的话子页不会重新 OnShow，这里兜一层
		if LFGParentFrame then
			LFGParentFrame:HookScript("OnShow", FillWhoZone)
		end
		-- 窗口底部：密语内容编辑框（改完立即写入 DB，点按钮时读 DB）
		local eb = CreateFrame("EditBox", "AddUIWhoWhisperBox", LFGWhoListFrame, "InputBoxTemplate")
		eb:SetHeight(20)
		eb:SetPoint("BOTTOMLEFT", LFGWhoListFrame, "BOTTOMLEFT", 84, 10)
		eb:SetPoint("RIGHT", LFGWhoListFrame, "RIGHT", -110, 0)
		eb:SetAutoFocus(false)
		eb:SetMaxLetters(120)
		eb:SetText(GetWhisperText())
		eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
		eb:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
		eb:SetScript("OnTextChanged", function(self, userInput)
			if not userInput or not AddUIDB then return end
			AddUIDB.whoWhisperText = self:GetText()
		end)
		eb:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText("点“密语”按钮时发送这段话，可直接修改")
			GameTooltip:Show()
		end)
		eb:SetScript("OnLeave", function() GameTooltip:Hide() end)
		local title = LFGWhoListFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
		title:SetPoint("RIGHT", eb, "LEFT", -6, 0)
		title:SetText("密语内容")
		-- 人数统计挪到右下，给底部的密语框让位
		if LFGWhoListFrame.WhoFrameTotals then
			LFGWhoListFrame.WhoFrameTotals:ClearAllPoints()
			LFGWhoListFrame.WhoFrameTotals:SetPoint("BOTTOMRIGHT", LFGWhoListFrame, "BOTTOMRIGHT", -14, 12)
		end
	end

	ns.event("ADDON_LOADED", function(event, addon)
		if addon == "Blizzard_GroupFinder_VanillaStyle" then
			HookVanillaLFG()
			HookWhoList()
		end
	end)
	HookVanillaLFG()
	HookWhoList()
end

ns.event("PLAYER_ENTERING_WORLD", function()
    if not AddUIDB.lfgkg then return end
    if not LFGListFrame then return end--无限服没有预创建组队界面
    if C_AddOns.IsAddOnLoaded("MeetingStone") then return end
    --配置PGF
    if C_AddOns.IsAddOnLoaded("PremadeGroupsFilter") then
	if UsePGFButtonText then 
		UsePGFButton:ClearAllPoints()
		UsePGFButton:SetPoint("LEFT", LFGListFrame.SearchPanel.RefreshButton, "LEFT", -62, 0)
		UsePGFButton:SetPoint("TOP", LFGListFrame.SearchPanel.RefreshButton, "TOP", 0, -3)
	end
	if PremadeGroupsFilterSettings then
		PremadeGroupsFilterSettings.ratingInfo = false	--队长评分
		PremadeGroupsFilterSettings.classBar = false	--职业颜色栏
		PremadeGroupsFilterSettings.leaderCrown = false	--显示队长标记
		PremadeGroupsFilterSettings.oneClickSignUp = false	--点击申请
	end
	--12.1暴雪把刷新按钮和搜索框大小改了,恢复到之前的布局
	if LFGListFrame.SearchPanel.RefreshButton then
		LFGListFrame.SearchPanel.RefreshButton:ClearAllPoints()
		LFGListFrame.SearchPanel.RefreshButton:SetPoint("LEFT", LFGListFrame.SearchPanel.CategoryName, "RIGHT", 15, 1)
		LFGListFrame.SearchPanel.SearchBox:ClearAllPoints()
		LFGListFrame.SearchPanel.SearchBox:SetPoint("TOPLEFT", LFGListFrame.SearchPanel.CategoryName, "BOTTOMLEFT", 4, -7)
		LFGListFrame.SearchPanel.SearchBox:SetPoint("RIGHT", LFGListFrame.SearchPanel.FilterButton, "LEFT", -2, 0)
	end
end

--[[解决预创建GetPlaystyleString报错问题https://github.com/0xbs/premade-groups-filter/issues/64
function LFMPlus_GetPlaystyleString(playstyle,activityInfo)
  if activityInfo and playstyle ~= (0 or nil) and C_LFGList.GetLfgCategoryInfo(activityInfo.categoryID).showPlaystyleDropdown then
    local typeStr
    if activityInfo.isMythicPlusActivity then
      typeStr = "GROUP_FINDER_PVE_PLAYSTYLE"
    elseif activityInfo.isRatedPvpActivity then
      typeStr = "GROUP_FINDER_PVP_PLAYSTYLE"
    elseif activityInfo.isCurrentRaidActivity then
      typeStr = "GROUP_FINDER_PVE_RAID_PLAYSTYLE"
    elseif activityInfo.isMythicActivity then
      typeStr = "GROUP_FINDER_PVE_MYTHICZERO_PLAYSTYLE"
    end
    return typeStr and _G[typeStr .. tostring(playstyle)] or nil
  else
    return nil
  end
end

C_LFGList.GetPlaystyleString = function(playstyle,activityInfo)
  return LFMPlus_GetPlaystyleString(playstyle, activityInfo)
end]]
--双击申请
local function HookApplicationClick()
	if LFGListFrame.SearchPanel.SignUpButton:IsEnabled() then
		LFGListFrame.SearchPanel.SignUpButton:Click()
	end
	if (not IsAltKeyDown()) and LFGListApplicationDialog:IsShown() and LFGListApplicationDialog.SignUpButton:IsEnabled() then
		LFGListApplicationDialog.SignUpButton:Click()
	end
end
ns.hook("LFGListSearchEntry_OnLoad", function(self)
	self:HookScript("OnDoubleClick", HookApplicationClick)
	LFGListFrame.SearchPanel.FilterButton.ResetButton:SetPoint("TOPLEFT",LFGListFrame.SearchPanel.FilterButton,"BOTTOMRIGHT",-20,2)
end)

--搜索页分数
ns.hook("LFGListSearchEntry_Update", function(self)
	if not PVEFrame:IsShown() then return end
    local resultID = self.resultID
	if not resultID or not C_LFGList.HasSearchResultInfo(resultID) then
		return;
	end
	
    local resultInfo = C_LFGList.GetSearchResultInfo(resultID)
    local leaderName = resultInfo.leaderName
	self.ActivityName:SetScale(.9)
	self.ActivityName:SetWidth(200)
    self.leaderMPlusRating = resultInfo.leaderOverallDungeonScore
	if not self.leaderMPlusRating then return end
	local scoreColor = C_ChallengeMode.GetDungeonScoreRarityColor(self.leaderMPlusRating) or HIGHLIGHT_FONT_COLOR
	if not self.score then--分数
		self.score = self:CreateFontString(nil, "ARTWORK")
		self.score:SetFont(STANDARD_TEXT_FONT, 15, 'OUTLINE')
	end
	if self.score then
		self.score:SetText(self.leaderMPlusRating)
		if resultInfo.isDelisted then
			self.score:SetTextColor(0.5,0.5,0.5)
		else
			self.score:SetTextColor(scoreColor.r, scoreColor.g, scoreColor.b)
		end
	end

	if self.Playstyle then
		self.Playstyle:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0)
		if resultInfo.isDelisted then
			self.Playstyle:SetTextColor(0.3,0.3,0.3)
		else
			self.Playstyle:SetTextColor(0,1,0)
		end
	end
	if not self.infotext then--说明
		self.infotext = self:CreateFontString(nil, "ARTWORK")
		self.infotext:SetFont(STANDARD_TEXT_FONT, 13, 'OUTLINE')
		self.infotext:SetPoint("BOTTOMLEFT", self.Playstyle, "BOTTOMRIGHT", 0, 3)
	end
	if self.infotext then
		self.infotext:SetText(resultInfo.comment)
		if resultInfo.isDelisted then
			self.infotext:SetTextColor(0.3,0.3,0.3)
		else
			self.infotext:SetTextColor(0.9,0.9,0.9)
		end
	end
	if not self.Name then return end
	if (LFGListFrame.CategorySelection.selectedCategory == 2) then
		self.score:SetPoint("LEFT", self, "CENTER", 15, 0)
		self.score:Show() 
	elseif (LFGListFrame.CategorySelection.selectedCategory == 3) then
		self.score:SetPoint("LEFT", self, "CENTER", 0, 0)
		self.score:Show() 
	elseif (LFGListFrame.CategorySelection.selectedCategory == 6) then
		self.score:SetPoint("LEFT", self, "CENTER", 0, 0)
		self.score:Show() 
	else
		self.score:Hide()
    end
end)

--保留搜索内容LFGList.lua
function LFGListSearchPanel_Clear(self)
	--C_LFGList.ClearSearchResults();
	--C_LFGList.ClearSearchTextFields();
	self.selectedResult = nil;
	LFGListSearchPanel_UpdateResultList(self);
end

--保留申请留言LFGList.lua
function LFGListApplicationDialog_Show(self, resultID)
	local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID);
	--if ( searchResultInfo.activityID ~= self.activityID ) then
		--C_LFGList.ClearApplicationTextFields();
	--end

	self.resultID = resultID;
	self.activityID = searchResultInfo.activityID;
	LFGListApplicationDialog_UpdateRoles(self);
	StaticPopupSpecial_Show(self);
end
--申请列表
ns.hook("LFGListApplicationViewer_UpdateApplicantMember", function(self, appID, memberIdx, status, pendingStatus)
	self:SetHeight(13)
	local info = C_LFGList.GetApplicantInfo(appID)
	
	if not self.infotext then--说明
		self.infotext = self:CreateFontString(nil, "ARTWORK")
		self.infotext:SetFont(STANDARD_TEXT_FONT, 11, 'OUTLINE')
		self.infotext:SetTextColor(0.9,0.9,0.9)
		self.infotext:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 5, 0)
	end
	if self.infotext then
		self.infotext:SetText(info.comment)
		if info.applicationStatus ~= "applied" and info.applicationStatus ~= "invited" and info.applicationStatus ~= "inviteaccepted" then
			self.infotext:SetTextColor(0.3,0.3,0.3)
		end
	end
end)

--不是队长也显示查找队伍按钮
ns.hook("LFGListApplicationViewer_UpdateInfo", function(self)
	LFGListFrame.ApplicationViewer.BrowseGroupsButton:Show()
end)
--浏览队伍按钮改成回到初始菜单
LFGListFrame.ApplicationViewer.BrowseGroupsButton:SetScript("OnClick", function()
	LFGListFrame_SetActivePanel(LFGListFrame,LFGListFrame.CategorySelection)
end)
--非队长/助理时，暴雪用 UnempoweredCover（enableMouse、frameLevel 15）盖住申请列表，右键全被它吃掉
--empowered = 队长 或 助理（LFGListUtil_IsEntryEmpowered，LFGList.lua:4216；SetShown 见 :1837）
--整个隐藏该遮罩（不再显示「你的队伍正在组建中。」）→ 右键穿透到申请者条目
--（密语 + 复制角色名/WCL/Raider.IO，菜单见 Func/WCL.lua）
ns.hook("LFGListApplicationViewer_UpdateAvailability", function(self)
	if self.UnempoweredCover then self.UnempoweredCover:Hide() end
end)

local f = CreateFrame("Frame")
f:RegisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED")
f:SetScript("OnEvent", function(self, event, resultid, status, prevstatus, title)
	if not resultid or status ~= "inviteaccepted" then return end
	local info = C_LFGList.GetSearchResultInfo(resultid)
	if not info or not info.activityIDs or #info.activityIDs == 0 then return end
	local activityID = info.activityIDs[1]
	local name = C_LFGList.GetActivityFullName(activityID) or "未知活动"
	local msg = "已加入: " .. name .. " " .. (title or "")
	print("|cffb044a2ADDUI|r " .. msg .. " " .. (info.leaderName or ""))
	ns.AATEXT(msg)
end)


end)
