local _,ns = ...
ns.event("PLAYER_LOGIN", function()
if AddUIDB.ftip ~=  3  then 
--鼠标提示位置
local mode = AddUIDB.ftip
--跟随鼠标
ns.hook("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
	--12.1：姓名板光环按钮等 Forbidden 父对象不能传给 SetOwner，跳过（保留暴雪默认锚点）
	if parent:IsForbidden() then return end
	if mode == 1 then
		local pname = parent:GetName()
		if pname and string.match(pname,"CompactPartyFrameMember") then
			tooltip:ClearAllPoints()
			tooltip:SetOwner(CompactPartyFrameMember1 or parent, "ANCHOR_TOPLEFT", 0, 13)
		elseif pname and string.match(pname,"CompactRaidGroup") then
			tooltip:ClearAllPoints()
			tooltip:SetOwner(CompactRaidGroup1Member1 or parent, "ANCHOR_TOPLEFT", 0, 13)
		elseif parent and UnitExists("mouseover") then
			tooltip:ClearAllPoints()
			tooltip:SetOwner(parent, "ANCHOR_CURSOR_RIGHT", 40, -145)
		else
			tooltip:ClearAllPoints()
			tooltip:SetOwner(parent, "ANCHOR_CURSOR")
		end
	elseif mode == 0 then
			tooltip:SetOwner(parent, "ANCHOR_NONE");
	elseif mode == 2 then
		if InCombatLockdown() then 
			tooltip:SetOwner(parent, "ANCHOR_NONE");
		else
			local pname = parent:GetName()
			if pname and string.match(pname,"CompactPartyFrameMember") then
				tooltip:ClearAllPoints()
				tooltip:SetOwner(CompactPartyFrameMember1 or parent, "ANCHOR_TOPLEFT", 0, 13)
			elseif pname and string.match(pname,"CompactRaidGroup") then
				tooltip:ClearAllPoints()
				tooltip:SetOwner(CompactRaidGroup1Member1 or parent, "ANCHOR_TOPLEFT", 0, 13)
			elseif parent and UnitExists("mouseover")  then
				tooltip:ClearAllPoints()
				tooltip:SetOwner(parent, "ANCHOR_CURSOR_RIGHT", 40, -145)
			else
				tooltip:ClearAllPoints()
				tooltip:SetOwner(parent, "ANCHOR_CURSOR")
			end
		end
	end
end)


--隐藏一些背景
local function style(frame)
    frame:SetScale(1)
	frame.NineSlice:SetCenterColor(0,0,0,.75)
	frame.NineSlice:SetBorderColor(0,0,0,0)

	if (frame.BackdropFrame) then----隐藏大地图鼠标提示边框
		frame.BackdropFrame:Hide()
	end
	if (frame.Border) or (frame.Background) then----隐藏鼠标提示边框及背景
		frame.BorderTop:Hide()
		frame.BorderBottom:Hide()
		frame.BorderLeft:Hide()
		frame.BorderRight:Hide()
		frame.BorderTopLeft:Hide()
		frame.BorderTopRight:Hide()
		frame.BorderBottomLeft:Hide()
		frame.BorderBottomRight:Hide()
		frame.Background:Hide()
		frame.BackdropBorder:Hide()
	end
end
style(GameTooltip)

--字体描边
GameTooltipText:SetFont("Fonts\\ARKai_T.ttf",13, "OUTLINE")	--普通字体
GameTooltipTextSmall:SetFont("Fonts\\ARKai_T.ttf", 13, "OUTLINE")	--装备比较字体
GameTooltipHeaderText:SetFont("Fonts\\ARKai_T.ttf", 16, "OUTLINE")	--提示名字
--鼠标提示血条样式
GameTooltipStatusBar:SetStatusBarTexture(130937)
GameTooltipStatusBar:SetStatusBarColor(0,1,0,0.75)
GameTooltipStatusBar:SetHeight(3)
GameTooltipStatusBar:ClearAllPoints()
GameTooltipStatusBar:SetPoint("BOTTOMLEFT", GameTooltipStatusBar:GetParent(), "TOPLEFT", 3, -3)	--血条左边
GameTooltipStatusBar:SetPoint("BOTTOMRIGHT", GameTooltipStatusBar:GetParent(), "TOPRIGHT", -3, -3)	--血条右边

local function GetUnitColor(unit)
	local UnitNameColor = {r=1,g=1,b=1}--目标职业颜色
	if UnitIsPlayer(unit) then
		local class = UnitClassBase(unit)
		if class then
			UnitNameColor = C_ClassColor.GetClassColor(class)
		end
	elseif UnitReaction(unit, "player") then
		UnitNameColor = FACTION_BAR_COLORS and FACTION_BAR_COLORS[UnitReaction(unit, "player")]
	end
	return UnitNameColor
end
local function TooltipBar(self, lineData)
	local unit = "mouseover"
	local foci = GetMouseFoci()
	local mouseFocus = foci[1] -- 获取数组中的第一个，即最顶层的框体
	if mouseFocus and mouseFocus.unit then
		unit = mouseFocus.unit
	end

	--目标职业颜色
	local TargetClassColor = GetUnitColor(unit)
	if TargetClassColor then
		GameTooltipTextLeft1:SetTextColor(TargetClassColor.r, TargetClassColor.g, TargetClassColor.b)
	end

	--公会染色
	if UnitIsPlayer(unit) and TargetClassColor then
		local guild, gRank, gRankId = GetGuildInfo(unit)
		local hasText = GameTooltipTextLeft2:GetText()
		if guild and hasText then
			if (gRank and gRankId) then
				gRank = gRank.."("..gRankId..")"
			end
			GameTooltipTextLeft2:SetFormattedText("|cffE41F9B<%s>|r |cffA0A0A0%s|r", guild, gRank or "")
		end
		if guild and GameTooltipTextLeft4 then
			GameTooltipTextLeft4:SetTextColor(TargetClassColor.r, TargetClassColor.g, TargetClassColor.b)
		elseif GameTooltipTextLeft3 then
			GameTooltipTextLeft3:SetTextColor(TargetClassColor.r, TargetClassColor.g, TargetClassColor.b)
		end
	end
	--目标的目标
	if UnitExists(unit.."target") then
		local TOTClassColor = GetUnitColor(unit.."target")
		local totname = C_ColorUtil.WrapTextInColor(UnitName(unit.."target"), TOTClassColor)
		GameTooltip:AddDoubleLine(TARGET..": "..totname)
	end
	local _,_,per = C_ScenarioInfo.GetUnitCriteriaProgressValues(unit)
	if per ~= nil then
		GameTooltip:AddLine("|cffFFFFFF"..PET_BATTLE_COMBAT_LOG_ENEMY_TEAM..": |r"..per.."%")
	end

	--大秘境分数
	local summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(unit)
	if not summary then return end		
	local score = summary and summary.currentSeasonScore
	if score and score > 0 then
		local color = C_ChallengeMode.GetDungeonScoreRarityColor(score) or HIGHLIGHT_FONT_COLOR
		GameTooltip:AddDoubleLine("史诗评分", score, 0, 0.7, 1, color.r, color.g, color.b)
	end
	local runs = summary and summary.runs
	if runs and (IsAltKeyDown() or IsShiftKeyDown() or IsControlKeyDown()) then
		GameTooltip:AddLine("     ")
		GameTooltip:AddDoubleLine("副本", "评分层数", 1, 1, 1, 1, 1, 1)
		for i, info in pairs(runs) do
			local map = C_ChallengeMode.GetMapUIInfo(info.challengeModeID)
			local colort = C_ChallengeMode.GetDungeonScoreRarityColor(info.mapScore*8) or HIGHLIGHT_FONT_COLOR
				GameTooltip:AddDoubleLine(map, info.mapScore.."("..info.bestRunLevel..")", 1, 1, 1, colort.r, colort.g, colort.b)
		end
	end
end
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, TooltipBar)

--法术ID
local function ShowID(self,data)
	if self:IsForbidden() then return end
	if InCombatLockdown() then return end
	if self:IsTooltipType(Enum.TooltipDataType.Item) and not ns.MM(data.id) then
			self:AddDoubleLine("|cffBA55D3物品ID:|r|cff00FF00"..data.id.."|r")
	elseif self:IsTooltipType(Enum.TooltipDataType.Unit) and not ns.MM(data.guid) then
		local npcid = tonumber(data.guid:match("-(%d+)-%x+$"), 10)
		if npcid and data.guid:match("%a+") ~= "Player" then
			self:AddDoubleLine("|cffBA55D3NPCID:|r|cff00FF00"..npcid.."|r")
		end
	elseif data.id and not ns.MM(data.id) then
		local aura = C_UnitAuras.GetPlayerAuraBySpellID(data.id)
		local ClassColor = {r=1,g=1,b=1}
		local SourceName = ""
		if aura and aura.sourceUnit then 
			SourceName = UnitName(aura.sourceUnit)
			ClassColor = GetUnitColor(aura.sourceUnit)
		end
		self:AddDoubleLine("|cffBA55D3法术ID:|r|cff00FF00"..data.id.."|r",SourceName,1,1,1,ClassColor.r,ClassColor.g,ClassColor.b)
	end
end
-- https://github.com/Stanzilla/WoWUIBugs/issues/298

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, ShowID)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, ShowID)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, ShowID)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.UnitAura, ShowID)

end

--无限服：鼠标提示显示目标玩家天赋（观察读取）
--思路参考 HuTip（TalentInfo.lua / ItemLevel.lua）：先放占位行，数据回来后原地替换，不重绘提示
if WOW_PROJECT_ID == WOW_PROJECT_CAMELOT then
	local INSPECT_CONFIG = (Constants and Constants.TraitConsts and Constants.TraitConsts.INSPECT_TRAIT_CONFIG_ID) or -1
	--分组名读不到时按职业 + 主系序号兜底
	local SPEC_NAMES = {
		WARRIOR = {"武器", "狂怒", "防护"},
		PALADIN = {"神圣", "防护", "惩戒"},
		HUNTER = {"野兽控制", "射击", "生存"},
		ROGUE = {"刺杀", "战斗", "敏锐"},
		PRIEST = {"戒律", "神圣", "暗影"},
		SHAMAN = {"元素", "增强", "恢复"},
		MAGE = {"奥术", "火焰", "冰霜"},
		WARLOCK = {"痛苦", "恶魔学识", "毁灭"},
		DRUID = {"平衡", "野性战斗", "恢复"},
	}
	local cache = {}	-- guid -> {text = 天赋文本或""、time = 缓存时间}
	local pending = {}	-- guid -> {tooltip = 提示框、index = 占位行行号}
	local lastAsk = {}	-- guid -> 上次请求观察时间

	local function GetTipUnit()
		local foci = GetMouseFoci()
		local f = foci and foci[1]
		if f then
			local u = f.unit
			if u then
				local e = UnitExists(u)
				if e and not ns.MM(e) then return u end
			end
		end
		if UnitExists("mouseover") then return "mouseover" end
	end

	--按天赋树分组读三系名称与已用点数
	local function ReadByGroup(configID, treeID)
		local infos = C_Traits.GetGroupDisplayInfoByTreeID(treeID)
		if not infos or #infos ~= 3 then return end
		local gids = {}
		for i, info in ipairs(infos) do
			if ns.MM(info.groupID) or ns.MM(info.displayName) then return end
			gids[i] = info.groupID
		end
		local spent = {}
		local gcis = C_Traits.GetGroupCurrencyInfo(configID, gids)
		if gcis then
			for _, gci in ipairs(gcis) do
				local ci = gci.currencyInfos and gci.currencyInfos[1]
				if ci and ci.spent and not ns.MM(ci.spent) then
					spent[gci.traitNodeGroupID] = ci.spent
				end
			end
		end
		local names, points = {}, {}
		for i, info in ipairs(infos) do
			names[i] = info.displayName
			points[i] = spent[info.groupID] or 0
		end
		return names, points
	end

	--兜底：分组数据缺失时，按节点横坐标三等分累加
	local function ReadByPosX(configID, treeID)
		local nodes = C_Traits.GetTreeNodes(treeID)
		if not nodes then return end
		local list, minX, maxX = {}, nil, nil
		for _, nodeID in ipairs(nodes) do
			local ok, node = pcall(C_Traits.GetNodeInfo, configID, nodeID)
			if ok and node then
				local x, rank = node.posX, node.currentRank
				if x and not ns.MM(x) and rank and not ns.MM(rank) then
					list[#list + 1] = {x = x, rank = rank}
					minX = minX and math.min(minX, x) or x
					maxX = maxX and math.max(maxX, x) or x
				end
			end
		end
		if not minX or maxX <= minX then return end
		local width = (maxX - minX) / 3
		local points = {0, 0, 0}
		for _, node in ipairs(list) do
			local i = math.min(3, math.floor((node.x - minX) / width) + 1)
			points[i] = points[i] + node.rank
		end
		return points
	end

	local function BuildLine(configID, treeID, classFile)
		if not configID or not treeID or ns.MM(configID) or ns.MM(treeID) then return end
		local names, points = ReadByGroup(configID, treeID)
		if not points then points = ReadByPosX(configID, treeID) end
		if not points then return end
		local total = 0
		for i = 1, #points do total = total + (points[i] or 0) end
		if total == 0 then return end	--没点天赋或数据还没到
		local best = 1
		for i = 2, #points do
			if points[i] > points[best] then best = i end
		end
		local name = names and names[best] or (SPEC_NAMES[classFile] and SPEC_NAMES[classFile][best])
		--秘密值不参与比较与拼接
		if not name or ns.MM(name) then return end
		return name.." ("..table.concat(points, "/")..")"
	end

	local function FormatLine(text)
		return "|cff00FF00天赋:|r |cffFFFFFF"..text.."|r"
	end

	--提示重建时清掉占位记录
	GameTooltip:HookScript("OnTooltipCleared", function()
		pending = {}
	end)

	ns.event("INSPECT_READY", function(event, guid)
		if not guid or ns.MM(guid) then return end
		local foci = GetMouseFoci()
		local f = foci and foci[1]
		if not f or not f.unit then return end
		local unit = f.unit
		local exists = UnitExists(unit)
		if not exists or ns.MM(exists) then return end
		local uguid = UnitGUID(unit)
		if not uguid or ns.MM(uguid) or uguid ~= guid then return end
		local specID = C_SpecializationInfo.GetInspectSpecialization(unit)
		if not specID or ns.MM(specID) then return end
		local classFile = select(2, UnitClass(unit))
		if not classFile or ns.MM(classFile) then return end
		local line = BuildLine(INSPECT_CONFIG, C_ClassTalents.GetTraitTreeForSpec(specID), classFile)
		cache[guid] = {text = line or "", time = GetTime()}
		--原地替换占位行，不重绘提示
		local p = pending[guid]
		if p and p.tooltip:IsShown() and p.tooltip:GetName() then
			local fs = _G[p.tooltip:GetName().."TextLeft"..p.index]
			if fs then
				if line then
					fs:SetText(FormatLine(line))
				else
					fs:SetText("")
					fs:Hide()
				end
				p.tooltip:Show()
			end
		end
		pending[guid] = nil
	end)

	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(self)
		local unit = GetTipUnit()
		if not unit then return end
		local isPlayer = UnitIsPlayer(unit)
		if ns.MM(isPlayer) or not isPlayer then return end
		local guid = UnitGUID(unit)
		if not guid or ns.MM(guid) then return end
		local pguid = UnitGUID("player")
		if pguid and not ns.MM(pguid) and pguid == guid then return end
		local cached = cache[guid]
		if cached and GetTime() - cached.time < 180 then
			if cached.text ~= "" then self:AddLine(FormatLine(cached.text)) end
			return
		end
		--先占位，数据回来后替换
		self:AddLine("|cff00FF00天赋:|r |cff888888加载中...|r")
		pending[guid] = {tooltip = self, index = self:NumLines()}
		local canInspect = CanInspect(unit)
		if not ns.MM(canInspect) and canInspect and GetTime() - (lastAsk[guid] or 0) > 5 then
			lastAsk[guid] = GetTime()
			NotifyInspect(unit)
		end
	end)
end
end)