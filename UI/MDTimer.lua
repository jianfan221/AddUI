local _,ns = ...
ns.tips("大秘境BOSS击杀时间记录(重置ADDUI配置不会重置历史记录)")
ns.event("ADDON_LOADED", function(event, addon)
	if addon == "Blizzard_ChallengesUI" then
		local keystoneframe = ChallengesKeystoneFrame
		if not keystoneframe then return end
		--自动放入钥石
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

--自动对话（按住 Shift 跳过）
ns.event("GOSSIP_SHOW", function()
	local inInstance, instanceType = IsInInstance()
	if not (inInstance and instanceType == "party") or IsShiftKeyDown() then return end -- 非5人本/按住Shift跳过
	local opts = C_GossipInfo.GetOptions()
	if not opts or not opts[1] then return end -- 无对话选项跳过
	if #opts ~= 1 then return end -- 非唯一选项跳过（修理/出售等）
	local icon = opts[1].icon
	if icon ~= 132053 and icon ~= 1019848 then return end -- 非八卦图标跳过
	C_GossipInfo.SelectOption(opts[1].gossipOptionID)
	UIErrorsFrame:AddExternalWarningMessage(opts[1].name)
	C_Timer.After(0, function()
		if not StaticPopup_IsAnyDialogShown() then
			C_GossipInfo.CloseGossip()
		end
	end)
end)

--计时器
-- style: 0=纯文本(无颜色), nil=自动(负红正绿), 1=绿, 2=红, 3=棕
-- showMillis: true 则显示3位毫秒
local function GetTimeAsString(totalSeconds, style, showMillis)
    local isNegative = totalSeconds < 0
    totalSeconds = math.abs(totalSeconds)

    local hours = math.floor(totalSeconds / 3600)
    local minutes = math.floor((totalSeconds % 3600) / 60)
    local seconds = math.floor(totalSeconds % 60)

    local timeString
    if hours > 0 then
        timeString = string.format("%d:%.2d:%.2d", hours, minutes, seconds)
    else
        timeString = string.format("%d:%.2d", minutes, seconds)
    end

    if showMillis then
        timeString = timeString .. string.format(".%03d", math.floor((totalSeconds % 1) * 1000))
    end

    if style == 0 then
        return timeString
    elseif style == 1 then
        return "|cff00FF00" .. timeString .. "|r"	-- 绿色 (计时)
    elseif style == 2 then
        return "|cffff0000" .. timeString .. "|r"	-- 红色 (超时)
    elseif style == 3 then
        return "|cff996633" .. timeString .. "|r"	-- 棕色 (历史)
    elseif isNegative then
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

	-- 完成信息：总用时 + 剩余时间（CLOSES_IN = "剩余时间"，超时为负显示红色），整条延迟0.5秒打印
	local completeMsg = mapName .. " +" .. keyLevel .. " " .. CRITERIA_COMPLETED_DATE:format(GetTimeAsString(timeMS, nil, true))
	local timeLimit = select(3, C_ChallengeMode.GetMapUIInfo(info.mapChallengeModeID))
	if timeLimit then
		completeMsg = completeMsg .. " " .. CLOSES_IN .. " " .. GetTimeAsString(timeLimit - timeMS, nil, true)
	end
	C_Timer.After(2, function() print(completeMsg) end)
end)
--
--Hook文本BlizzardInterfaceCode\Interface\AddOns\Blizzard_ObjectiveTracker\Blizzard_ScenarioObjectiveTracker.lua
ns.hook(ScenarioObjectiveTracker.ChallengeModeBlock,"UpdateTime", function(self,elapsedTime)
	if not self.DungeonTime and self.Level then
		self.DungeonTime = self:CreateFontString(nil, "OVERLAY")
		self.DungeonTime:SetFontObject(self.Level:GetFontObject())
		self.DungeonTime:SetPoint("LEFT",self.Level,"RIGHT",2,0)
	end
	if self.DungeonTime then
		if self.timeLimit > elapsedTime then
			self.DungeonTime:SetText(GetTimeAsString(elapsedTime,1) .. " " .. GetTimeAsString(self.timeLimit,3))
		else
			self.DungeonTime:SetText(GetTimeAsString(elapsedTime,2) .. " " .. GetTimeAsString(self.timeLimit,3))
		end
	end

	-- +2/+3 分割线 & 倒计时（如果装了AngryKeystones 功能重复则跳过）
	if C_AddOns.IsAddOnLoaded("AngryKeystones") then return end
	local time3 = self.timeLimit * 0.6
	local time2 = self.timeLimit * 0.8

	if not self.Split then
		local barW, barH = self.StatusBar:GetSize()

		self.Split = CreateFrame("Frame", nil, self)
		self.Split:SetFrameLevel(self:GetFrameLevel() + 10)
		self.Split:SetAllPoints(self)

		self.Split_Bar3 = self.Split:CreateTexture(nil, "OVERLAY")
		self.Split_Bar3:SetPoint("TOPLEFT", self.StatusBar, "TOPLEFT", barW * (1 - 0.6), 1)
		self.Split_Bar3:SetSize(3, barH)
		self.Split_Bar3:SetColorTexture(1, 0.843, 0)

		self.Split_Bar2 = self.Split:CreateTexture(nil, "OVERLAY")
		self.Split_Bar2:SetPoint("TOPLEFT", self.StatusBar, "TOPLEFT", barW * (1 - 0.8), 1)
		self.Split_Bar2:SetSize(3, barH)
		self.Split_Bar2:SetColorTexture(0.78, 0.78, 0.812)

		self.Split_Text3 = self.Split:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
		self.Split_Text3:SetPoint("LEFT", self.TimeLeft, "RIGHT", 4, 0)
		self.Split_Text3:SetTextColor(1, 0.843, 0)

		self.Split_Text2 = self.Split:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
		self.Split_Text2:SetPoint("LEFT", self.Split_Text3, "RIGHT", 4, 0)
		self.Split_Text2:SetTextColor(0.78, 0.78, 0.812)
	end

	if elapsedTime < time3 then
		self.Split_Bar3:Show()
		self.Split_Bar2:Show()
		self.Split_Text3:SetText(GetTimeAsString(time3 - elapsedTime, 0))
		self.Split_Text3:Show()
		self.Split_Text2:SetText(GetTimeAsString(time2 - elapsedTime, 0))
		self.Split_Text2:Show()
	elseif elapsedTime < time2 then
		self.Split_Bar3:Hide()
		self.Split_Bar2:Show()
		self.Split_Text3:SetText(GetTimeAsString(time2 - elapsedTime, 0))
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

--两个文本（都在下面的 Hook 里创建，只建一次）：
--  lefttext  = 进度条左侧，本波合计进度（只算仇恨列表里的怪）
--  righttext = 进度条右侧内部，打完这波的总进度 = 本波合计 + 已完成进度
local lefttext, righttext

--Hook计量条BlizzardInterfaceCode\Interface\AddOns\Blizzard_ObjectiveTracker\Blizzard_ScenarioObjectiveTracker.lua
ns.hook(ScenarioTrackerProgressBarMixin,"SetValue", function(self)
	local criteriaIndex = select(3, C_Scenario.GetStepInfo())
	local criteriaInfo = C_ScenarioInfo.GetCriteriaInfo(criteriaIndex)
	if criteriaInfo and criteriaInfo.isWeightedProgress and not criteriaInfo.completed and criteriaInfo.quantity and criteriaInfo.totalQuantity then
		local quantity = tonumber((criteriaInfo.quantityString or ""):match("(%d+)") or 0)--暴雪的API有问题
		self.Bar.Label:SetText(string.format("%.2f%%", quantity / criteriaInfo.totalQuantity * 100))

		--左：本波合计进度（白色）
		if not lefttext then
			lefttext = self.Bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			lefttext:SetPoint("LEFT", self.Bar, "LEFT", 0, 0)
			lefttext:SetTextColor(1, 1, 1)
		end
		--右：打完这波的总进度（绿色）
		if not righttext then
			righttext = self.Bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			righttext:SetPoint("RIGHT", self.Bar, "RIGHT", 0, 0)
			righttext:SetTextColor(0, 1, 0)
		end
	end
end)

--大秘境玩家死亡次数记录（鼠标指向暴雪自带死亡图标时，tooltip 显示每人带职业颜色的死亡数）
local Deaths = {}
local hooked = false
ns.event("CHALLENGE_MODE_START", function() Deaths = {} end)
ns.event("UNIT_DIED", function(_event, guid)
	if not C_ChallengeMode.IsChallengeModeActive() then return end	-- 只在大秘境统计
	if ns.MM(guid) then return end						-- 秘密值 GUID 跳过
	if not C_PlayerInfo.GUIDIsPlayer(guid) then return end	-- 只统计玩家
	Deaths[guid] = (Deaths[guid] or 0) + 1

	-- 顺带挂一次 tooltip（hooked 防止重复挂载）
	if not hooked then
		local block = ScenarioObjectiveTracker and ScenarioObjectiveTracker.ChallengeModeBlock
		local deathIcon = block and block.DeathCount
		if deathIcon then
			hooked = true
			deathIcon:HookScript("OnEnter", function()
				for guid, count in pairs(Deaths) do
					-- GetPlayerInfoByGUID 返回: localizedClass, classFilename, localizedRace, englishRace, sex, name(角色名), realmName
					local _, class, _, _, _, name = GetPlayerInfoByGUID(guid)
					local color = class and RAID_CLASS_COLORS[class]
					if name then
						GameTooltip:AddDoubleLine("|c" .. (color and color.colorStr or "fff") .. name .. "|r", "|cffff1a1a" .. count .. "|r")	-- 暴雪标准红 RED_FONT_COLOR
					end
				end
				GameTooltip:Show()	-- 已显示的 tooltip 追加行后强制重算背景尺寸
			end)
		end
	end
end)

--=====================================================================
-- 大秘境"本波合计进度"（逻辑照抄 MythicPlusPullReEstimated 的 CalculatePull）
--   lefttext  = 本波合计（当前仇恨列表里的怪）
--   righttext = 打完这波的总进度 = 本波合计 + 已完成
--
-- 难点：副本里 C_ScenarioInfo.GetUnitCriteriaProgressValues 返回的是"秘密值"，
--       既不能相加（secret + secret 报错），也不能相除（换算百分比要 /总量）
--
-- 解法：借 StatusBar 布局链，用"几何"代替加法
--   ① 条宽和量程都 = 总量 totalCount → 填充宽度就是"数量"本身（整数，无换算误差）
--   ② 条首尾相接排开，读最后一根填充纹理的右端坐标 = 各怪数量之和
--   ③ 末尾再接一根"已完成数量"的条 → 链尾坐标 = 打完这波的总数量
--   ④ 用 AbbreviateNumbers（C 函数，可接秘密值）换算成百分比字符串：
--        finalValue = floor(number / significandDivisor) / fractionDivisor
--      → 除数 = significandDivisor × fractionDivisor = 总量/100
--        （sig = 总量/10000、frac = 100 → 读出 ÷ (总量/100) = 百分比，两位小数）
--      除数随副本总量变，所以按总量缓存配置（见 GetPercentCalculator）
--
-- 数据来源（函数名同参考实现）：
--   总量    GetProgressCriteriaInfo().totalQuantity
--   每只怪  GetUnitCriteriaProgressValues(unit) 的第 1 个返回值（数量，不是小数）
--   已完成  同一 criteriaInfo 的 quantityString 抠首个整数
--           （criteriaInfo.quantity 与 totalQuantity 不是一套单位，暴雪老问题，不用）
--=====================================================================
-- 条池：复用框架，不每次新建（照抄参考实现的 statusBarPool）
local barPool = { index = 0, pool = {} }

local function AcquireBar()
	barPool.index = barPool.index + 1
	local bar = barPool.pool[barPool.index]
	if bar then return bar end
	bar = CreateFrame("StatusBar")
	bar:SetAlpha(0)				-- 看不见，只借它的几何
	barPool.pool[barPool.index] = bar
	return bar
end

local function ReleaseAllBars()
	for i = 1, barPool.index do
		local bar = barPool.pool[i]
		if bar then
			bar:Hide()
			bar:ClearAllPoints()
			bar:SetValue(0)
		end
	end
	barPool.index = 0
end

-- 百分比换算配置：按总量缓存（照抄参考实现的 GetPercentCalculator）
-- 除数 = significandDivisor × fractionDivisor = (总量/10000) × 100 = 总量/100
-- → 链尾坐标（数量）÷ 除数 = 百分比；fractionDivisor = 100 决定保留两位小数
local percentCalculators = {}

local function GetPercentCalculator(totalCount)
	local fmt = percentCalculators[totalCount]
	if not fmt then
		fmt = {
			config = CreateAbbreviateConfig({
				{
					breakpoint = 0.00001,
					abbreviation = "%",
					significandDivisor = totalCount / 10000,
					fractionDivisor = 100,
					abbreviationIsGlobal = false,
				},
			}),
		}
		percentCalculators[totalCount] = fmt
	end
	return fmt
end

-- 当前步骤的"加权进度"（敌方部队）criteria：从最后一个 criteria 往前找 isWeightedProgress
local function GetProgressCriteriaInfo()
	local numCriteria = select(3, C_Scenario.GetStepInfo()) or 0
	for index = numCriteria, 1, -1 do
		local info = C_ScenarioInfo.GetCriteriaInfo(index)
		if info and info.isWeightedProgress then
			return info
		end
	end
end

-- 进度总量（数量口径，作所有条的条宽和量程）
local function GetTotalCount()
	local info = GetProgressCriteriaInfo()
	return info and info.totalQuantity or 0
end

-- 已完成数量：criteriaInfo.quantity 口径不对（暴雪老问题），改从 quantityString 抠首个整数
local function GetCurrentCount()
	local info = GetProgressCriteriaInfo()
	if info and info.quantityString then
		return tonumber(info.quantityString:match("%d+")) or 0
	end
	return 0
end

-- 已进仇恨（被拉到的）怪：上了仇恨列表，或宠物正在攻击的目标
local function IsUnitPulled(unit)
	if not UnitCanAttack("player", unit) then return false end
	local threat = UnitThreatSituation("player", unit)	-- 不在仇恨列表 → nil
	if ns.MM(threat) then return false end				-- 秘密值跳过
	return (threat or -1) >= 0 or UnitPlayerControlled(unit .. "target")
end

-- 当前所有被拉到的怪（照抄参考实现：直接扫姓名板，不自己维护列表）
local function GetPulledUnits()
	local pulledUnits = {}
	for _, nameplate in pairs(C_NamePlate.GetNamePlates()) do
		local unitFrame = nameplate.UnitFrame --[[@as any]]
		if unitFrame and unitFrame.unitExists then
			local unit = unitFrame.displayedUnit --[[@as UnitToken]]
			if IsUnitPulled(unit) then
				pulledUnits[#pulledUnits + 1] = unit
			end
		end
	end
	return pulledUnits
end

-- 排布局链，两帧后读链尾坐标（数量），交给 AbbreviateNumbers 换算成百分比
--- @param pulledUnits table 被拉到的怪（UnitToken 列表）
--- @param total number 进度总量（明文）→ 条宽和量程
--- @param currentCount number 已完成数量（明文）
--- @param onDone fun(pullCount:any, estimatedCount:any) 两个值可能仍是秘密值，只能交给 AbbreviateNumbers
local function CalculatePull(pulledUnits, total, currentCount, onDone)
	ReleaseAllBars()

	local mainBar = AcquireBar()
	mainBar:SetSize(total, 10)
	mainBar:SetPoint("LEFT")
	mainBar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")	-- 必须设，否则 GetStatusBarTexture() 返回 nil
	mainBar:SetMinMaxValues(0, total)
	mainBar:SetValue(0)
	mainBar:Show()

	local prevBar = mainBar:GetStatusBarTexture()
	for _, unit in ipairs(pulledUnits) do
		local count = C_ScenarioInfo.GetUnitCriteriaProgressValues(unit)	-- 第 1 个返回值：该怪的数量
		if count then
			local bar = AcquireBar()
			bar:SetSize(total, 10)
			bar:SetPoint("LEFT", prevBar, "RIGHT", 0, 0)
			bar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")
			bar:SetMinMaxValues(0, total)
			bar:SetValue(count)
			bar:Show()
			prevBar = bar:GetStatusBarTexture()
		end
	end

	local currentCountBar = AcquireBar()
	currentCountBar:SetSize(total, 10)
	currentCountBar:SetPoint("LEFT", prevBar, "RIGHT", 0, 0)
	currentCountBar:SetStatusBarTexture("Interface/TargetingFrame/UI-StatusBar")
	currentCountBar:SetMinMaxValues(0, total)
	currentCountBar:SetValue(currentCount)
	currentCountBar:Show()

	RunNextFrame(function()
		RunNextFrame(function()		-- 等两帧，布局算完几何后才能读坐标
			onDone(prevBar:GetRight(), currentCountBar:GetStatusBarTexture():GetRight())
		end)
	end)
end

local gen = 0	-- 代际令牌：回调两帧后才跑，用它作废已过期的计算结果

local function Update()
	if not lefttext then return end					-- 文本还没建好（进度条还没出现）
	if not C_ChallengeMode.IsChallengeModeActive() then return end

	local pulledUnits = GetPulledUnits()
	local total = GetTotalCount()
	if #pulledUnits == 0 or not total or total <= 0 then	-- 没有拉到的怪 / 拿不到总量 → 清空
		gen = gen + 1
		lefttext:SetText("")
		righttext:SetText("")
		return
	end

	local currentCount = GetCurrentCount()

	gen = gen + 1	-- 新的一代：之前排队还没回调的计算全部作废
	local my = gen

	CalculatePull(pulledUnits, total, currentCount, function(pullCount, estimatedCount)
		if my ~= gen then return end						-- 期间又算过一轮 → 丢弃
		if #pulledUnits ~= #GetPulledUnits() then return end	-- 拉怪数量变了 → 丢弃（照抄参考实现）
		local fmt = GetPercentCalculator(total)
		lefttext:SetText(AbbreviateNumbers(pullCount, fmt))			-- 本波合计
		righttext:SetText(AbbreviateNumbers(estimatedCount, fmt))	-- 打完这波的总进度
		-- 本波合计为 0 时左右都不显示：SetAlpha 会自动钳位到 [0,1]（0 → 透明），
		-- 又能直接接秘密值，所以不用做比较（秘密值不能比较）
		lefttext:SetAlpha(pullCount)
		righttext:SetAlpha(pullCount)
	end)
end

ns.event("NAME_PLATE_UNIT_ADDED", function() Update() end)
ns.event("NAME_PLATE_UNIT_REMOVED", function() Update() end)
ns.event("UNIT_THREAT_LIST_UPDATE", Update)		-- 拉怪 / 上仇恨时重算

--进度条每次刷新后重算（进度变化时 SCENARIO_CRITERIA_UPDATE → MarkDirty → 下一帧才会走到这里，
--所以这个 Hook 才是唯一能拿到最新进度条百分比的时机）
ns.hook(ScenarioTrackerProgressBarMixin,"SetValue", Update)
