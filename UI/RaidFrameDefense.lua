local _, ns = ...

-- 团队框架监控玩家减伤BUFF（手动维护法术ID表）
-- 使用 AuraContainer 单一分组，锚定在成员框架上层（同 RaidFrameAbsorb 思路）：
--   过滤 HELPFUL + includeSpellIDs = 下方手动表（仅显示表里的减伤增益）
-- 说明：只显示手动表里配置的减伤BUFF；吸收盾(RaidFrameAbsorb)层级高于本层。

-- ═══════════ 手动维护的减伤法术ID表 ═══════════
-- 在此固定维护需要额外监控的减伤法术ID，如：[法术ID] = "法术名"
local CustomDefenseSpellIDs = {
	--通用
	[58984] = true, --影遁

	--牧师
	[10060] = true, --能量灌注
	[62618] = true, --真言术：障(团队减伤屏障)
	[47585] = true, --消散
	[47788] = true, --守护之魂(外)
	[33206] = true, --痛苦压制(外)
	[19236] = true, --绝望祷言
	[193065] = true, --防护圣光(自愈后减伤10%)

	--萨满
	[381755] = true, --萨满土元素+15%血
	[98008] = true, --灵魂链接图腾(团队减伤)
	[108271] = true, --星界转移
	[260881] = true, --幽魂之狼(减伤5%)
	[355634] = true, --打断减伤

	--法师
	[235450] = true, --棱光护体(吸收盾+魔法减伤15%)
	[449336] = true, --挫折而已,日怒奥盾后减伤
	[55342] = true, --镜像(需要学会折射镜像)
	[110960] = true, --强化隐身术
	[414664] = true, --群体隐身
	[45438] = true, --寒冰屏障(冰棺,免伤10s)
	[414658] = true, --深寒凝冰

	--圣骑士
	[211210] = true, --光环掌握(队友身上)
	[1044] = true, --自由之手
	[642] = true, --圣盾术
	[498] = true, --圣佑术
	[86659] = true, --远古列王守卫
	[31850] = true, --炽热防御者
	[1022] = true, --保护祝福(外)
	[6940] = true, --牺牲祝福(外)
	[204018] = true, --破咒祝福(外)

	--战士
	[97463] = true, --集结呐喊
	[12975] = true, --破釜沉舟
	[871] = true, --盾墙(减伤40%)
	[118038] = true, --剑在人在(减伤30%,武器/狂暴)
	[184364] = true, --狂怒回复(减伤30%+吸血)
	[190456] = true, --无视苦痛(吸收盾,防战)
	[23920] = true,--盾反

	--死亡骑士
	[48707] = true, --反魔法护罩(吸收魔法伤害)
	[48792] = true, --冰封之韧(减伤30%)
	[55233] = true, --吸血鬼之血
	[51052] = true, --反魔法领域(团队魔法减伤15%)
	[145629] = true, --反魔法领域12.1

	--恶魔猎手
	[212800] = true, --疾影
	[187827] = true, --恶魔变形
	[207771] = true, --烈火烙印
	[196718] = true, --黑暗(团队减伤)

	--德鲁伊
	[22812] = true, --树皮术
	[61336] = true, --生存本能
	[22842] = true, --狂暴回复(熊形态回血)
	[106898] = true, --狂奔怒吼
	[29166] = true, --激活
	[1850] = true, --疾奔

	--唤魔师
	[363916] = true, --黑曜鳞片(减伤30%)
	[374227] = true, --微风

	--猎人
	[186265] = true, --灵龟守护
	[264735] = true, --优胜劣汰

	--武僧
	[115203] = true, --壮胆酒
	[116849] = true, --作茧缚命(给队友大盾)
	[125174] = true, --业报之触
	[132578] = true, --玄牛下凡(召唤玄牛,吸收40%醉拳)
	[322507] = true, --天神酒(吸收盾)

	--潜行者
	[31224] = true, --暗影斗篷
	[5277] = true, --闪避
	[1966] = true, --佯攻
	[185311] = true, --猩红之瓶

	--术士
	[104773] = true, --不灭决心
	[108416] = true, --黑暗契约(牺牲生命换吸收盾)
	[132413] = true, --暗影壁垒(+30%生命)
	[387636] = true, --灵魂燃烧:治疗石(+20%生命)
}

-- 图标尺寸跟随框架高度（GetRaidFrameHeight 读的是滑动条 setting 值，不含渲染偏移）
-- 小队用小尺寸（Party），团队用大尺寸（Raid）
local function GetFrameSize()
	if IsInRaid() then
		return EditModeManagerFrame:GetRaidFrameHeight(Enum.EditModeUnitFrameSystemIndices.Raid, 36)/2.5
	else
		return EditModeManagerFrame:GetRaidFrameHeight(Enum.EditModeUnitFrameSystemIndices.Party, 36)/2.5
	end
end

-- 光环按钮样式初始化
local function InitDefenseButton(btn)
	local size = GetFrameSize()
	btn:SetSize(size, size)
	btn:EnableMouse(false)--完全鼠标穿透，不阻挡点击
	local icon = btn:CreateTexture(nil, "OVERLAY")
	icon:SetAllPoints(btn)
	btn:SetIcon(icon)
	local cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
	cooldown:SetAllPoints(btn)
	cooldown:SetReverse(true)
	-- 冷却倒数文本字号为光环尺寸的比例（同 PlateAuras，用 SetFontHeight 保留模板字体）
	local cdRegion = cooldown:GetRegions()
	if cdRegion and type(cdRegion.SetFontHeight) == "function" then
		cdRegion:SetFontHeight(size/1.8)
	end
	btn:SetDurationCooldown(cooldown)

	-- 叠层数：独立 overlay 容器（层级在冷却之上，不随冷却隐藏）
	local overlay = CreateFrame("Frame", nil, btn)
	overlay:SetAllPoints(btn)
	overlay:SetFrameLevel(btn:GetFrameLevel() + 2)
	local count = overlay:CreateFontString(nil, "OVERLAY")
	count:SetPoint("BOTTOMRIGHT", btn, 3, -3)
	count:SetVertexColor(1, 1, 1)
	count:SetFont(STANDARD_TEXT_FONT, size/2, "OUTLINE")
	btn:SetApplicationCount(count, {})
end

-- 查找单位对应的暴雪自带团队/小队框架
local function FindUnitFrame(unit)
	local raidframe
	if IsInRaid() then
		for i = 1, 8 do
			for j = 1, 5 do
				raidframe = _G["CompactRaidGroup"..i.."Member"..j]
				if raidframe and raidframe.unit and not ns.MM(raidframe.unit) and UnitIsUnit(raidframe.unit, unit) then
					return raidframe
				end
			end
		end
	elseif IsInGroup() then
		for i = 1, 5 do
			raidframe = _G["CompactPartyFrameMember"..i]
			if raidframe and raidframe.unit and not ns.MM(raidframe.unit) and UnitIsUnit(raidframe.unit, unit) then
				return raidframe
			end
		end
	end
end

-- 在每个框架上创建（或复用）减伤光环容器
local function SetupFrameContainer(frame, unit)
	-- 上层容器：让光环显示在成员框架自带内容之上（同 RaidFrameAbsorb 思路）
	if not frame.RDF_Overlay then
		frame.RDF_Overlay = CreateFrame("Frame", nil, frame)
		frame.RDF_Overlay:SetAllPoints(frame)
		frame.RDF_Overlay:SetFrameStrata("MEDIUM")
	end

	local container = frame.RDF_Defense
	if container then
		container:SetUnit(unit)
		return
	end

	container = CreateFrame("AuraContainer", nil, frame.RDF_Overlay, "CustomAuraContainerTemplate")
	frame.RDF_Defense = container
	container:EnableMouse(false)
	container:SetUnit(unit)
	-- 仅显示手动表里配置的减伤增益（HELPFUL + includeSpellIDs）
	container:AddAuraGroup("customDefense", "HELPFUL", {
		initializeFrame = InitDefenseButton,
		layout = { elementSpacing = 0, groupSpacing = 0 },
		candidateFilters = { includeSpellIDs = CustomDefenseSpellIDs },
	})
	-- 居中显示在团队成员框架上层
	container:SetPoint("CENTER", frame.RDF_Overlay, "CENTER", 0, 0)
	container:Show()
end

local function RefreshDefense()
	if not (AddUIDB and AddUIDB.raidframeDefense) then return end
	local num = GetNumGroupMembers()
	if IsInRaid() then
		for i = 1, num do
			local frame = FindUnitFrame("raid"..i)
			if frame then SetupFrameContainer(frame, "raid"..i) end
		end
	elseif IsInGroup() then
		local pframe = FindUnitFrame("player") or CompactPartyFrameMember1
		if pframe then SetupFrameContainer(pframe, "player") end
		for i = 1, num - 1 do
			local frame = FindUnitFrame("party"..i)
			if frame then SetupFrameContainer(frame, "party"..i) end
		end
	end
end

ns.event("GROUP_ROSTER_UPDATE", RefreshDefense)
ns.event("PLAYER_ENTERING_WORLD", RefreshDefense)

-- 启用时关闭暴雪自带的"重要防御技能居中"，避免与我们的居中减伤显示重叠
ns.event("PLAYER_LOGIN", function()
	if AddUIDB and AddUIDB.raidframeDefense then
		SetCVar("raidFramesCenterBigDefensive", 0)
	else
		SetCVar("raidFramesCenterBigDefensive", 1)
	end
end)
