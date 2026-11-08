local _,ns = ...
ns.tips("任务物品放左面")
local function moveQuestObjectiveItems(self)
	local a = {self:GetPoint()}
	self:ClearAllPoints()
	self:SetPoint("TOPRIGHT", a[2], "TOPLEFT", -25, 3)
	self:SetScale(1.5)
end

ns.hook(QuestObjectiveItemButtonMixin,"OnUpdate", function(self, elapsed)
	moveQuestObjectiveItems(self)
end)

--通报
local function OnQuestEvent(event, ...)
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
	if IsInInstance() then return end
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


--核心逻辑来源 AutoQuests 3.1.0（unverz06）
--https://github.com/unverz06/AutoQuests
--多任务连续处理为本插件扩展
local ADDUIAutoQuestCheck
local questHandled = {}--本次对话已尝试过的 questID，防止同一个任务反复重试
local nextScheduled

local function OnAutoQuestEvent(event, ...)
	
	if event == "PLAYER_ENTERING_WORLD" then
		if not ADDUIAutoQuestCheck then
			--AddUIDB.AutoQuestCheck = false
			ADDUIAutoQuestCheck = CreateFrame("CheckButton", "ADDUIAutoQuestCheck", ObjectiveTrackerFrame.Header,"InterfaceOptionsCheckButtonTemplate")
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
    
	if event == "GOSSIP_SHOW" then
		for k in pairs(questHandled) do questHandled[k] = nil end
		local gossipOptions = C_GossipInfo.GetOptions()

		if #gossipOptions == 1 and bit.band(gossipOptions[1].flags, Enum.GossipOptionRecFlags.QuestLabelPrepend) ~= 0 then
			C_GossipInfo.SelectOption(gossipOptions[1].gossipOptionID)
		else
			local questOptionsCount = 0
			local firstQuestOption = nil
			for _, option in ipairs(gossipOptions) do
				if bit.band(option.flags, Enum.GossipOptionRecFlags.QuestLabelPrepend) ~= 0 then
					questOptionsCount = questOptionsCount + 1
					if firstQuestOption == nil then
						firstQuestOption = option
					end
				end
			end
			if questOptionsCount > 0 then
				--多个任务选项时只点第一个，并提示需要手动选择
				if questOptionsCount > 1 then
					PlaySound(5274, "master")
				end
				if firstQuestOption then
					C_GossipInfo.SelectOption(firstQuestOption.gossipOptionID)
				end
			end
		end

		--对话选项会改变界面，等它生效后再读任务列表，否则拿到的是旧数据
		C_Timer.After(0.2, function()
			if not AddUIDB.AutoQuestCheck then return end
			if not (GossipFrame and GossipFrame:IsShown()) then return end
			--优先交已完成的任务，没有再按顺序接可接任务
			for _, quest in ipairs(C_GossipInfo.GetActiveQuests()) do
				if quest.isComplete and not questHandled[quest.questID] then
					questHandled[quest.questID] = true
					C_GossipInfo.SelectActiveQuest(quest.questID)
					return
				end
			end
			for _, quest in ipairs(C_GossipInfo.GetAvailableQuests()) do
				if not questHandled[quest.questID] then
					questHandled[quest.questID] = true
					C_GossipInfo.SelectAvailableQuest(quest.questID)
					return
				end
			end
		end)
	elseif event == "QUEST_GREETING" then
		for k in pairs(questHandled) do questHandled[k] = nil end
		--旧全局 API，参数是列表序号（见暴雪 QuestFrame.lua）
		for i = 1, GetNumActiveQuests() do
			local questID = GetActiveQuestID(i)
			local _, isComplete = GetActiveTitle(i)
			if isComplete and questID and not questHandled[questID] then
				questHandled[questID] = true
				SelectActiveQuest(i)
				return
			end
		end
		for i = 1, GetNumAvailableQuests() do
			local _, _, _, _, questID = GetAvailableQuestInfo(i)
			if questID and not questHandled[questID] then
				questHandled[questID] = true
				SelectAvailableQuest(i)
				return
			end
		end
	elseif event == "QUEST_DETAIL" then
		AcceptQuest()
	elseif event == "QUEST_PROGRESS" then
		CompleteQuest()
	elseif event == "QUEST_COMPLETE" then
		if GetNumQuestChoices() > 1 then
			--选择奖励
			PlaySound(5274, "master")
		else
			GetQuestReward(1)
		end
	elseif event == "QUEST_ACCEPTED" or event == "QUEST_TURNED_IN" then
		--处理完一个后等界面刷新，再继续下一个
		if nextScheduled then return end
		nextScheduled = true
		C_Timer.After(0.3, function()
			nextScheduled = false
			if not AddUIDB.AutoQuestCheck then return end
			if QuestFrameGreetingPanel and QuestFrameGreetingPanel:IsShown() then
				for i = 1, GetNumActiveQuests() do
					local questID = GetActiveQuestID(i)
					local _, isComplete = GetActiveTitle(i)
					if isComplete and questID and not questHandled[questID] then
						questHandled[questID] = true
						SelectActiveQuest(i)
						return
					end
				end
				for i = 1, GetNumAvailableQuests() do
					local _, _, _, _, questID = GetAvailableQuestInfo(i)
					if questID and not questHandled[questID] then
						questHandled[questID] = true
						SelectAvailableQuest(i)
						return
					end
				end
			elseif GossipFrame and GossipFrame:IsShown() then
				for _, quest in ipairs(C_GossipInfo.GetActiveQuests()) do
					if quest.isComplete and not questHandled[quest.questID] then
						questHandled[quest.questID] = true
						C_GossipInfo.SelectActiveQuest(quest.questID)
						return
					end
				end
				for _, quest in ipairs(C_GossipInfo.GetAvailableQuests()) do
					if not questHandled[quest.questID] then
						questHandled[quest.questID] = true
						C_GossipInfo.SelectAvailableQuest(quest.questID)
						return
					end
				end
			end
		end)
	end
end

ns.event("PLAYER_ENTERING_WORLD", OnAutoQuestEvent)
ns.event("MODIFIER_STATE_CHANGED", OnAutoQuestEvent)
ns.event("GOSSIP_SHOW", OnAutoQuestEvent)
ns.event("QUEST_PROGRESS", OnAutoQuestEvent)
ns.event("QUEST_DETAIL", OnAutoQuestEvent)
ns.event("QUEST_COMPLETE", OnAutoQuestEvent)
ns.event("QUEST_GREETING", OnAutoQuestEvent)
ns.event("QUEST_ACCEPTED", OnAutoQuestEvent)--接完后继续处理下一个
ns.event("QUEST_TURNED_IN", OnAutoQuestEvent)--交完后继续处理下一个