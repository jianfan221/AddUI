local _,ns = ...
local statTimer
ns.event("PLAYER_LOGIN", function()
	if not AddUIDB.stat then return end
	
	local StatSheet = CreateFrame("Frame", "StatSheet", UIParent)
	StatSheet:SetSize(150, 115)
	StatSheet:SetPoint("BOTTOMRIGHT", MainActionBar, "BOTTOMLEFT", -3, -3)
	ns.AddEdit(StatSheet)
	
	local Y = 0
	local scale = 17
	local StatList = {}
	local function CreateText(text1,text2,color)
		local Text1 = StatSheet:CreateFontString("Text", "OVERLAY")
		Text1:SetFont("fonts\\ARHei.ttf", scale, "OUTLINE")
		Text1:SetText(text1..":")
		Text1:SetPoint("TOPLEFT", 0, (-scale-2) * Y)
		Text1:SetTextColor(unpack(color))
		local Text2 = StatSheet:CreateFontString("Text", "OVERLAY")
		Text2:SetFont("fonts\\ARHei.ttf", scale, "OUTLINE")
		Text2:SetText(text2)
		Text2:SetPoint("TOPRIGHT", 0, (-scale-2) * Y)
		Text2:SetTextColor(unpack(color))
		Y = Y + 1
		StatList[text2] = Text2
	end
	
	if statTimer then return end
	statTimer = C_Timer.NewTicker(0.3, function()
		if StatList["主属性"] then
			StatList["主属性"]:SetText(format("%d", math.max(UnitStat("player", 1), UnitStat("player", 2), UnitStat("player", 4))))
		else
			CreateText("主属性","主属性",{1, 0, 1})
		end
		
		if StatList["装等"] then
			StatList["装等"]:SetText(format("%.1f", GetAverageItemLevel()))
		else
			CreateText("装等","装等",{0, 1, 1})
		end
		
		if StatList[STAT_CRITICAL_STRIKE] then
			StatList[STAT_CRITICAL_STRIKE]:SetText(format("%.2f%%", GetSpellCritChance(2)))
		else
			CreateText(STAT_CRITICAL_STRIKE,STAT_CRITICAL_STRIKE,{1, 0.5, 0})
		end
		
		if StatList[STAT_HASTE] then
			StatList[STAT_HASTE]:SetText(format("%.2f%%",GetHaste()))
		else
			CreateText(STAT_HASTE,STAT_HASTE,{0,1,0})
		end
		
		if StatList[STAT_MASTERY] then
			StatList[STAT_MASTERY]:SetText(format("%.2f%%", GetMasteryEffect()))
		else
			CreateText(STAT_MASTERY,STAT_MASTERY,{0, 0.5, 1})
		end
		
		if StatList[STAT_VERSATILITY] then
			StatList[STAT_VERSATILITY]:SetText(format("%.2f%%", GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE)))
		else
			CreateText(STAT_VERSATILITY,STAT_VERSATILITY,{1, 1, 0})
		end
	end)
end)