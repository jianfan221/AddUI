local _,ns = ...
ns.tips("大秘境BOSS击杀时间记录(重置ADDUI配置不会重置历史记录)")
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
	local info = C_ChallengeMode.GetChallengeCompletionInfo()
	local mapName = C_ChallengeMode.GetMapUIInfo(info.mapChallengeModeID)
	local keyLevel = info.level
	if not mapName or not keyLevel then return end

	AddUIDB.DungeonBossKill = AddUIDB.DungeonBossKill or {}
	AddUIDB.DungeonBossKill[mapName] = AddUIDB.DungeonBossKill[mapName] or {}
	AddUIDB.DungeonBossKill[mapName][keyLevel] = AddUIDB.DungeonBossKill[mapName][keyLevel] or {}
	BossKillTime = BossKillTime or {}
	BossKillTime[mapName] = BossKillTime[mapName] or {}
	BossKillTime[mapName][keyLevel] = {}
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
hooksecurefunc(ScenarioObjectiveTracker.ChallengeModeBlock,"UpdateTime", function(self,elapsedTime)
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
end)
--Hook文本BlizzardInterfaceCode\Interface\AddOns\Blizzard_ObjectiveTracker\Blizzard_ScenarioObjectiveTracker.lua
hooksecurefunc(ScenarioObjectiveTracker,"UpdateCriteria", function(self,numCriteria)
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
		if not AddUIDB.DungeonBossKill[mapName][keyLevel] and AddUIDB.DungeonBossKill[mapName][keyLevel-1] then
			AddUIDB.DungeonBossKill[mapName][keyLevel] = AddUIDB.DungeonBossKill[mapName][keyLevel-1]
		else
			AddUIDB.DungeonBossKill[mapName][keyLevel] = AddUIDB.DungeonBossKill[mapName][keyLevel] or {}
		end

		if not AddUIDB.DungeonBossKill[mapName][keyLevel][bossName] and AddUIDB.DungeonBossKill[mapName][keyLevel][COMPLETE] then
			AddUIDB.DungeonBossKill[mapName][keyLevel][bossName] = AddUIDB.DungeonBossKill[mapName][keyLevel][COMPLETE]
		end
		BossKillTime = BossKillTime or {}
		BossKillTime[mapName] = BossKillTime[mapName] or {}
		BossKillTime[mapName][keyLevel] = BossKillTime[mapName][keyLevel] or {}
		
		if criteriaInfo then
			local objectivesBlock = self.ObjectivesBlock;
			local line = objectivesBlock:GetExistingLine(criteriaIndex)
			if line and criteriaInfo.completed then
				local oldtext = line.Text:GetText()
				local TimeGap = ""
				
				if not BossKillTime[mapName][keyLevel][bossName] then
					BossKillTime[mapName][keyLevel][bossName] = select(2,GetWorldElapsedTime(1))
				end

				if BossKillTime[mapName][keyLevel][bossName] and AddUIDB.DungeonBossKill[mapName][keyLevel][bossName] then
					TimeGap = "("..GetTimeAsString(AddUIDB.DungeonBossKill[mapName][keyLevel][bossName] - BossKillTime[mapName][keyLevel][bossName])..")"
				end
				
				if BossKillTime[mapName][keyLevel][bossName] == 0 then return end
				line.Text:SetText(oldtext..GetTimeAsString(BossKillTime[mapName][keyLevel][bossName])..TimeGap)
			elseif line then
				local oldtext = line.Text:GetText()
				if AddUIDB.DungeonBossKill[mapName][keyLevel][bossName] then
					line.Text:SetText(oldtext..GetTimeAsString(AddUIDB.DungeonBossKill[mapName][keyLevel][bossName],3))
				end
			end
		end
	end
end)