local _,ns = ...
ns.event("PLAYER_LOGIN", function()
if AddUIDB.ftip ~=  3  then 
--鼠标提示位置
local mode = AddUIDB.ftip
--跟随鼠标
hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
	if mode == 1 then
		if parent and parent:GetName() and string.match(parent:GetName(),"CompactPartyFrameMember") then
			tooltip:ClearAllPoints()
			tooltip:SetOwner(CompactPartyFrameMember1, "ANCHOR_TOPLEFT", 0, 13)
		elseif parent and parent:GetName() and string.match(parent:GetName(),"CompactRaidGroup") then
			tooltip:ClearAllPoints()
			tooltip:SetOwner(CompactRaidGroup1Member1, "ANCHOR_TOPLEFT", 0, 13)
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
			if parent and parent:GetName() and string.match(parent:GetName(),"CompactPartyFrameMember") then
				tooltip:ClearAllPoints()
				tooltip:SetOwner(CompactPartyFrameMember1, "ANCHOR_TOPLEFT", 0, 13)
			elseif parent and parent:GetName() and string.match(parent:GetName(),"CompactRaidGroup") then
				tooltip:ClearAllPoints()
				tooltip:SetOwner(CompactRaidGroup1Member1, "ANCHOR_TOPLEFT", 0, 13)
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
GameTooltipStatusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-TargetingFrame-BarFill")
GameTooltipStatusBar:SetHeight(3)
GameTooltipStatusBar:SetHeight(3)
GameTooltipStatusBar:ClearAllPoints()
GameTooltipStatusBar:SetPoint("BOTTOMLEFT", GameTooltipStatusBar:GetParent(), "TOPLEFT", 5, -4)	--血条左边
GameTooltipStatusBar:SetPoint("BOTTOMRIGHT", GameTooltipStatusBar:GetParent(), "TOPRIGHT", -5, -4)	--血条右边


local function TooltipBar(self)
	
	--血条职业着色
	if UnitIsPlayer("mouseover") and UnitClass("mouseover") then
		local _, class = UnitClass("mouseover")
		local color = class and (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
		if color and color.r and color.g and color.b then
			GameTooltipStatusBar:SetStatusBarColor(color.r,color.g,color.b)
			GameTooltipStatusBar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar") --血条材质，自己改喜欢的
		end
	end

	--目名字和公会
	if UnitIsPlayer("mouseover") then
		local text = GameTooltipTextLeft1:GetText()
		if ns.MM(text) then return end
		local guild, gRank, gRankId = GetGuildInfo("mouseover")
		local hasText = GameTooltipTextLeft2:GetText()
		GameTooltipTextLeft1:SetText(ns.ADDUICOLOR(text,"mouseover"))
		if guild and hasText then
			if (gRank and gRankId) then
				gRank = gRank.."("..gRankId..")"
			end
			GameTooltipTextLeft2:SetFormattedText("|cffE41F9B<%s>|r |cffA0A0A0%s|r", guild, gRank or "")
		end
		if guild and GameTooltipTextLeft4 then
			local text4 = GameTooltipTextLeft4:GetText()
			GameTooltipTextLeft4:SetText(ns.ADDUICOLOR(text4,"mouseover"))
		elseif GameTooltipTextLeft3 then
			local text3 = GameTooltipTextLeft3:GetText()
			GameTooltipTextLeft3:SetText(ns.ADDUICOLOR(text3,"mouseover"))
		end
	end
	--显示目标
	if not ns.MM(UnitName("mouseovertarget")) then
		local targetText = ns.ADDUICOLOR(UnitName("mouseovertarget"),"mouseovertarget")
		GameTooltip:AddDoubleLine(targetText and "目标: "..targetText or "")
	end

	--大秘境分数
	local summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("mouseover")
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
		local source
		if aura and aura.sourceUnit then source = ns.ADDUICOLOR(UnitName(aura.sourceUnit),aura.sourceUnit) end
		self:AddDoubleLine("|cffBA55D3法术ID:|r|cff00FF00"..data.id.."|r",source)
	end
end
-- https://github.com/Stanzilla/WoWUIBugs/issues/298

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, ShowID)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, ShowID)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, ShowID)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.UnitAura, ShowID)

end
end)