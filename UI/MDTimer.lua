local _,ns = ...
ns.tips("大秘境BOSS击杀时间记录(重置ADDUI配置不会重置历史记录)")
ns.event("ADDON_LOADED", function(event, addon)
	if addon == "Blizzard_ChallengesUI" then
		local keystoneframe = ChallengesKeystoneFrame
		if not keystoneframe then return end
		keystoneframe:HookScript("OnShow", function()
			for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
				for slot = 1, C_Container.GetContainerNumSlots(bag) do
					local link = C_Container.GetContainerItemLink(bag, slot)
					if link and link:match("|Hkeystone:") then
						C_Container.PickupContainerItem(bag, slot)
						if CursorHasItem() then
							C_ChallengeMode.SlotKeystone()
							return
						end
					end
				end
			end
		end)

		-- 钥匙界面按钮 — 就位确认 / 倒计时 / 取消
		local function MakeBtn(text, callback)
			local btn = CreateFrame("Button", nil, keystoneframe)
			btn:SetSize(100, 20)
			btn:SetNormalFontObject("GameFontNormal")
			btn:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]])

			local bg = btn:CreateTexture(nil, "BACKGROUND")
			bg:SetAllPoints()
			bg:SetColorTexture(0.2, 0.2, 0.2, 0.7)
			btn.bg = bg

			local tx = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			tx:SetPoint("CENTER", 0, 1)
			tx:SetText(text)
			btn:SetFontString(tx)

			btn:SetScript("OnEnter", function() bg:SetColorTexture(0.35, 0.35, 0.35, 0.9) end)
			btn:SetScript("OnLeave", function() bg:SetColorTexture(0.2, 0.2, 0.2, 0.7) end)
			btn:SetScript("OnClick", callback)
			return btn
		end

		local btn1 = MakeBtn(READY_CHECK, function() DoReadyCheck() end)
		btn1:SetPoint("TOPLEFT", keystoneframe, "TOPLEFT", 4, -14)

		local btn2 = MakeBtn(PLAYER_COUNTDOWN_BUTTON, function() C_PartyInfo.DoCountdown(10) end)
		btn2:SetPoint("TOPLEFT", btn1, "BOTTOMLEFT", 0, -2)

		local btn3 = MakeBtn(CANCEL, function() C_PartyInfo.DoCountdown(0) end)
		btn3:SetPoint("TOPLEFT", btn2, "BOTTOMLEFT", 0, -2)
	end
end)

--纯文本时间格式（不带颜色代码，用于 SetTextColor 控制颜色的场景）
local function FormatTimePlain(totalSeconds)
    totalSeconds = math.abs(totalSeconds)
    local hours = math.floor(totalSeconds / 3600)
    local minutes = math.floor((totalSeconds % 3600) / 60)
    local seconds = math.floor(totalSeconds % 60)
    if hours > 0 then
        return string.format("%d:%.2d:%.2d", hours, minutes, seconds)
    else
        return string.format("%d:%.2d", minutes, seconds)
    end
end
--计时器-- 处理负数：统一转换为正数，并标记为负
local function GetTimeAsString(totalSeconds,nocolor)
    local isNegative = totalSeconds < 0
    totalSeconds = math.abs(totalSeconds)

    local hours = math.floor(totalSeconds / 3600)
    local minutes = math.floor((totalSeconds % 3600) / 60)
    local seconds = math.floor(totalSeconds % 60)

    local timeString-- 格式化为字符串
    if hours > 0 then
        timeString = string.format("%02d:%02d:%02d", hours, minutes, seconds)
    else
        timeString = string.format("%02d:%02d", minutes, seconds)
    end
	if nocolor == 1 then
		return "|cff00FF00" .. timeString .. "|r"	-- 绿色 (计时)
	elseif nocolor == 2 then
		return "|cffff0000" .. timeString .. "|r"	-- 红色 (超时)
    elseif nocolor == 3 then
		return "|cff996633" .. timeString .. "|r"	-- 棕色 (历史)
	elseif isNegative then-- 直接返回带颜色代码的字符串
        return "|cffff0000" .. timeString .. "|r"	-- 红色（负数）
    else
        return "|cff00ff00" .. timeString .. "|r"	-- 绿色（正数）
    end
end

--注册大秘境事件
local BossKillTime = {}
ns.event("CHALLENGE_MODE_START", function(event,...)
	BossKillTime = {}
end)

ns.event("CHALLENGE_MODE_COMPLETED", function()
	local info = C_ChallengeMode.GetChallengeCompletionInfo()
	local mapName = C_ChallengeMode.GetMapUIInfo(info.mapChallengeModeID)
	local timeMS = info.time/1000
	local keyLevel = info.level
	if not mapName or not timeMS or not keyLevel then return end
	
	AddUIDB.DungeonBossKill = AddUIDB.DungeonBossKill or {}
	AddUIDB.DungeonBossKill[mapName] = AddUIDB.DungeonBossKill[mapName] or {}
	AddUIDB.DungeonBossKill[mapName][keyLevel] = AddUIDB.DungeonBossKill[mapName][keyLevel] or {}
	
	if not AddUIDB.DungeonBossKill[mapName][keyLevel][COMPLETE] then
		AddUIDB.DungeonBossKill[mapName][keyLevel] = BossKillTime[mapName][keyLevel]
		AddUIDB.DungeonBossKill[mapName][keyLevel][COMPLETE] = timeMS
	elseif timeMS < AddUIDB.DungeonBossKill[mapName][keyLevel][COMPLETE] then
		AddUIDB.DungeonBossKill[mapName][keyLevel] = BossKillTime[mapName][keyLevel]
		AddUIDB.DungeonBossKill[mapName][keyLevel][COMPLETE] = timeMS
	end
end)
--
--Hook文本BlizzardInterfaceCode\Interface\AddOns\Blizzard_ObjectiveTracker\Blizzard_ScenarioObjectiveTracker.lua
ns.hook(ScenarioObjectiveTracker.ChallengeModeBlock,"UpdateTime", function(self,elapsedTime)
	if not self.DungeonTime and self.Level then
		self.DungeonTime = self:CreateFontString(nil, "OVERLAY")
		self.DungeonTime:SetFont(STANDARD_TEXT_FONT, 16, 'OUTLINE')
		self.DungeonTime:SetPoint("LEFT",self.Level,"RIGHT",5,0)
	end
	
	if self.DungeonTime then
		local mapID,endtime = C_ChallengeMode.GetActiveChallengeMapID(),0;
		if mapID then
			endtime = select(3,C_ChallengeMode.GetMapUIInfo(mapID))
		end
		if endtime > select(2,GetWorldElapsedTime(1)) then
			self.DungeonTime:SetText(GetTimeAsString(select(2,GetWorldElapsedTime(1)),1))
		else
			self.DungeonTime:SetText(GetTimeAsString(select(2,GetWorldElapsedTime(1)),2))
		end
	end

	-- +2/+3 分割线 & 倒计时（如果装了AngryKeystones 功能重复则跳过）
	if C_AddOns.IsAddOnLoaded("AngryKeystones") then return end
	local time3 = self.timeLimit * 0.6
	local time2 = self.timeLimit * 0.8

	if not self.SplitBar then
		local barW, barH = self.StatusBar:GetSize()

		local f = CreateFrame("Frame", nil, self)
		f:SetFrameLevel(self:GetFrameLevel() + 10)
		f:SetAllPoints(self)

		self.Split_Bar3 = f:CreateTexture(nil, "OVERLAY")
		self.Split_Bar3:SetPoint("TOPLEFT", self.StatusBar, "TOPLEFT", barW * (1 - 0.6), 2)
		self.Split_Bar3:SetSize(3, barH)
		self.Split_Bar3:SetColorTexture(1, 0.843, 0)

		self.Split_Bar2 = f:CreateTexture(nil, "OVERLAY")
		self.Split_Bar2:SetPoint("TOPLEFT", self.StatusBar, "TOPLEFT", barW * (1 - 0.8), 2)
		self.Split_Bar2:SetSize(3, barH)
		self.Split_Bar2:SetColorTexture(0.78, 0.78, 0.812)

		self.Split_Text3 = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
		self.Split_Text3:SetPoint("LEFT", self.TimeLeft, "RIGHT", 4, 0)
		self.Split_Text3:SetTextColor(1, 0.843, 0)

		self.Split_Text2 = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
		self.Split_Text2:SetPoint("LEFT", self.Split_Text3, "RIGHT", 4, 0)
		self.Split_Text2:SetTextColor(0.78, 0.78, 0.812)

		self.SplitBar = true
	end

	if elapsedTime < time3 then
		self.Split_Bar3:Show()
		self.Split_Bar2:Show()
		self.Split_Text3:SetText(FormatTimePlain(time3 - elapsedTime))
		self.Split_Text3:Show()
		self.Split_Text2:SetText(FormatTimePlain(time2 - elapsedTime))
		self.Split_Text2:Show()
	elseif elapsedTime < time2 then
		self.Split_Bar3:Hide()
		self.Split_Bar2:Show()
		self.Split_Text3:SetText(FormatTimePlain(time2 - elapsedTime))
		self.Split_Text3:Show()
		self.Split_Text2:Hide()
	else
		self.Split_Bar3:Hide()
		self.Split_Bar2:Hide()
		self.Split_Text3:Hide()
		self.Split_Text2:Hide()
	end
end)

--Hook文本BlizzardInterfaceCode\Interface\AddOns\Blizzard_ObjectiveTracker\Blizzard_ScenarioObjectiveTracker.lua
ns.hook(ScenarioObjectiveTracker,"UpdateCriteria", function(self,numCriteria)
	--不在大秘境中直接退出
	if not C_ChallengeMode.IsChallengeModeActive() then
		return
	end

	for criteriaIndex = 1, numCriteria do
		local criteriaInfo = C_ScenarioInfo.GetCriteriaInfo(criteriaIndex);
		local bossName = criteriaInfo.description--BOSS名称,备用criteriaID
		local mapID = C_ChallengeMode.GetActiveChallengeMapID();
		local mapName = C_ChallengeMode.GetMapUIInfo(mapID)
		local keyLevel = C_ChallengeMode.GetActiveKeystoneInfo()
		
		AddUIDB.DungeonBossKill = AddUIDB.DungeonBossKill or {}
		AddUIDB.DungeonBossKill[mapName] = AddUIDB.DungeonBossKill[mapName] or {}
		AddUIDB.DungeonBossKill[mapName][keyLevel] = AddUIDB.DungeonBossKill[mapName][keyLevel] or {}
		if not AddUIDB.DungeonBossKill[mapName][keyLevel][bossName] and AddUIDB.DungeonBossKill[mapName][keyLevel][COMPLETE] then
			AddUIDB.DungeonBossKill[mapName][keyLevel][bossName] = AddUIDB.DungeonBossKill[mapName][keyLevel][COMPLETE]
		end
		BossKillTime = BossKillTime or {}
		BossKillTime[mapName] = BossKillTime[mapName] or {}
		BossKillTime[mapName][keyLevel] = BossKillTime[mapName][keyLevel] or {}
		
		if criteriaInfo then
			local objectivesBlock = self.ObjectivesBlock;
			local line = objectivesBlock:GetExistingLine(criteriaIndex)
			local DBdate = AddUIDB.DungeonBossKill[mapName]
			if not DBdate[keyLevel][bossName] and DBdate[keyLevel-1] and DBdate[keyLevel-1][bossName] then
				DBdate[keyLevel][bossName] = DBdate[keyLevel-1][bossName]--如果有历史记录但当前等级没有，尝试从上一个等级继承记录
			end

			if line and criteriaInfo.completed then
				local oldtext = line.Text:GetText()
				local TimeGap = ""
				
				if not BossKillTime[mapName][keyLevel][bossName] then
					BossKillTime[mapName][keyLevel][bossName] = select(2,GetWorldElapsedTime(1))
				end

				if BossKillTime[mapName][keyLevel][bossName] and DBdate[keyLevel][bossName] then
					TimeGap = "("..GetTimeAsString(DBdate[keyLevel][bossName] - BossKillTime[mapName][keyLevel][bossName])..")"
				end
				
				if BossKillTime[mapName][keyLevel][bossName] == 0 then return end
				line.Text:SetText(oldtext..GetTimeAsString(BossKillTime[mapName][keyLevel][bossName])..TimeGap)
			elseif line then
				local oldtext = line.Text:GetText()
				if DBdate[keyLevel][bossName] then
					line.Text:SetText(oldtext..GetTimeAsString(DBdate[keyLevel][bossName],3))
				end
			end
		end
	end
end)

--Hook计量条BlizzardInterfaceCode\Interface\AddOns\Blizzard_ObjectiveTracker\Blizzard_ScenarioObjectiveTracker.lua
ns.hook(ScenarioTrackerProgressBarMixin,"SetValue", function(self)
	local criteriaIndex = select(3, C_Scenario.GetStepInfo())
	local criteriaInfo = C_ScenarioInfo.GetCriteriaInfo(criteriaIndex)
	if criteriaInfo and criteriaInfo.isWeightedProgress and not criteriaInfo.completed and criteriaInfo.quantity and criteriaInfo.totalQuantity then
		local quantity = tonumber((criteriaInfo.quantityString or ""):match("(%d+)") or 0)--暴雪的API有问题
		self.Bar.Label:SetText(string.format("%.2f%%", quantity / criteriaInfo.totalQuantity * 100))
	end
end)