local _,ns = ...
ns.tips("任务物品放左面")
local function moveQuestObjectiveItems(self)
	local a = {self:GetPoint()}
	self:ClearAllPoints()
	self:SetPoint("TOPRIGHT", a[2], "TOPLEFT", -25, 3)
	self:SetScale(1.5)
end

hooksecurefunc(QuestObjectiveItemButtonMixin,"OnUpdate", function(self, elapsed)
	moveQuestObjectiveItems(self)
end)

--通报
local function OnQuestEvent(event, ...)
	if IsInInstance() then return end
	if event == "PLAYER_ENTERING_WORLD" then
		SetCVar("autoQuestWatch", 1)--屏幕中间的任务进度
		SetCVar("showQuestTrackingTooltips", 1)--任务进度鼠标提示
		if not ADDUIQuestCheck then 
			local ADDUIQuestCheck = CreateFrame("CheckButton", "ADDUIQuestCheck", ObjectiveTrackerFrame.Header,"InterfaceOptionsCheckButtonTemplate")
			ADDUIQuestCheck:SetPoint("LEFT", ObjectiveTrackerFrame.Header, "LEFT", 85, 0)
			ADDUIQuestCheck:SetChecked(AddUIDB.QuestCheck)
			ADDUIQuestCheck.text:SetText("通报")
			ADDUIQuestCheck:SetScale(0.9)
			ADDUIQuestCheck:SetScript("OnClick", function (self)
				AddUIDB.QuestCheck = self:GetChecked()
			end)
			ADDUIQuestCheck:SetScript("OnEnter",function(self) 
				GameTooltip:SetOwner(self, "ANCHOR_TOP")
				GameTooltip:AddLine("|cffFFFFFF通报任务进度至|r".."小队") 
				GameTooltip:Show()
			end)
			ADDUIQuestCheck:SetScript("OnLeave", function(self)    
				GameTooltip:Hide()
			end)
		end
	end
	
	if not AddUIDB.QuestCheck then return end
	if not IsInGroup() then return end
	if C_Secrets.ShouldAurasBeSecret() then return end
	if event == "QUEST_WATCH_UPDATE" then
        local questID = ...
		C_Timer.After(0.3,function()
			if C_QuestLog.IsComplete(questID) then
				C_ChatInfo.SendChatMessage(GetQuestLink(questID).."任务完成", "PARTY")
			end
		end)
	end
	if event == "UI_INFO_MESSAGE" then
		local id,text = ...
		if string.find(GetGameMessageInfo(id),"ERR_QUEST_ADD") then
			C_ChatInfo.SendChatMessage(text, "PARTY")
		end
	end
	if event == "QUEST_ACCEPTED" then
        local questID = ...
		if not C_QuestLog.GetLogIndexForQuestID(questID) then return end
		local info = C_QuestLog.GetInfo(C_QuestLog.GetLogIndexForQuestID(questID))
        if info and not info.isHeader and (info.isTask or not info.isHidden) then
			C_ChatInfo.SendChatMessage("接受任务"..GetQuestLink(questID), "PARTY")
		end
	end
end

ns.event("PLAYER_ENTERING_WORLD", OnQuestEvent)
ns.event("QUEST_WATCH_UPDATE", OnQuestEvent)
ns.event("UI_INFO_MESSAGE", OnQuestEvent)
--ns.event("QUEST_ACCEPTED", OnQuestEvent)


local function OnAutoQuestEvent(event, ...)
	
	if event == "PLAYER_ENTERING_WORLD" then
		if not ADDUIAutoQuestCheck then
			--AddUIDB.AutoQuestCheck = false
			local ADDUIAutoQuestCheck = CreateFrame("CheckButton", "ADDUIAutoQuestCheck", ObjectiveTrackerFrame.Header,"InterfaceOptionsCheckButtonTemplate")
			ADDUIAutoQuestCheck:SetPoint("LEFT", ObjectiveTrackerFrame.Header, "LEFT", 150, 0)
			ADDUIAutoQuestCheck:SetChecked(AddUIDB.AutoQuestCheck)
			ADDUIAutoQuestCheck.text:SetText("自动交接")
			ADDUIAutoQuestCheck:SetScale(0.9)
			ADDUIAutoQuestCheck:SetScript("OnClick", function (self)
				AddUIDB.AutoQuestCheck = self:GetChecked()
			end)
			ADDUIAutoQuestCheck:SetScript("OnEnter",function(self) 
				GameTooltip:SetOwner(self, "ANCHOR_TOP")
				GameTooltip:AddLine("|cffFFFFFF按|r".."Ctrl".."|cffFFFFFF或|r".."Shift".."|cffFFFFFF或|r".."Alt".."|cffFFFFFF可以临时关闭|r") 
				GameTooltip:Show()
			end)
			ADDUIAutoQuestCheck:SetScript("OnLeave", function(self)    
				GameTooltip:Hide()
			end)
		end
	end

    if not AddUIDB.AutoQuestCheck or IsShiftKeyDown() or IsControlKeyDown() or IsAltKeyDown() then return end
    
	--来源AutoQuests-2.4.0
	--https://www.curseforge.com/wow/addons/autoquests-unverz
	--https://github.com/unverz06/AutoQuests
	
	if event=="GOSSIP_SHOW" then
			local nActive = C_GossipInfo.GetNumActiveQuests()
			local activeQuests = C_GossipInfo.GetActiveQuests()
			local nAvailable = C_GossipInfo.GetNumAvailableQuests()
			local availableQuests = C_GossipInfo.GetAvailableQuests()
			local gossipOptions = C_GossipInfo.GetOptions()

			if #gossipOptions == 1 and gossipOptions[1].flags == 1 then
				C_GossipInfo.SelectOption(gossipOptions[1].gossipOptionID)
			else
				local questOptionsCount = 0
				local firstQuestOption = nil
				for _, option in ipairs(gossipOptions) do
					if option.flags == 1 then
						questOptionsCount = questOptionsCount + 1
						if firstQuestOption == nil then
							firstQuestOption = option
						end
					end
				end
				if questOptionsCount > 1 then
					PlaySound(5274, "master")
					if firstQuestOption then
						C_GossipInfo.SelectOption(firstQuestOption.gossipOptionID)
					end
				elseif questOptionsCount == 1 then
					C_GossipInfo.SelectOption(gossipOptions[1].gossipOptionID)
				end
			end

			if nAvailable > 0 then
				for i, quest in ipairs(availableQuests) do
					if not quest.repeatable or nAvailable < 2 then
						C_GossipInfo.SelectAvailableQuest(quest.questID)
					end
				end
				if availableQuests[1] then
					if availableQuests[1].repeatable and nAvailable > 1 then
						C_GossipInfo.SelectAvailableQuest(availableQuests[1].questID)
					end
				end
			elseif nActive > 0 then
				for i, quest in ipairs(activeQuests) do
					if quest.isComplete then
						C_GossipInfo.SelectActiveQuest(quest.questID)
					end
				end
			end
	end

	if (event=="QUEST_GREETING") then
		local npcAvailableQuestCount = GetNumAvailableQuests()
		local npcActiveQuestCount = GetNumActiveQuests()

		if (npcAvailableQuestCount > 0) then
			for i = 1, GetNumAvailableQuests() do
				SelectAvailableQuest(i)
			end
		elseif (npcActiveQuestCount > 0) then
			for i = 1, GetNumActiveQuests() do
				SelectActiveQuest(i)
			end
		end
	end

	if (event=="QUEST_DETAIL") then
		AcceptQuest()
	end

	if (event=="QUEST_PROGRESS") then
		CompleteQuest()
	end

	if (event=="QUEST_COMPLETE") then
		local npcQuestRewardsCount = GetNumQuestChoices()
		if (npcQuestRewardsCount > 1) then
			--选择奖励
			PlaySound(5274, "master")
		else
			GetQuestReward(1)
		end
	end
end

ns.event("PLAYER_ENTERING_WORLD", OnAutoQuestEvent)
ns.event("MODIFIER_STATE_CHANGED", OnAutoQuestEvent)
ns.event("GOSSIP_SHOW", OnAutoQuestEvent)
ns.event("QUEST_PROGRESS", OnAutoQuestEvent)
ns.event("QUEST_DETAIL", OnAutoQuestEvent)
ns.event("QUEST_COMPLETE", OnAutoQuestEvent)
ns.event("QUEST_GREETING", OnAutoQuestEvent)