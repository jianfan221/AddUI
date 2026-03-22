local _,ns = ...
local londingcolor = RAID_CLASS_COLORS
ns.tips("自动设置误导嫁祸宏(需要有个宏的名字叫嫁祸或者叫误导)")

local WD = {}
WD.InCombat = false

function WD:UpdateMacroTarget()
	if IsInRaid() then
		for i = 1,40 do
			if UnitGroupRolesAssigned("raid"..i) == "TANK" then
				WD.NewName = UnitName("raid"..i)
				WD.Lclass,WD.NewClass = UnitClass("raid"..i)
				break;
			end
		end
	elseif IsInGroup() then
		for i = 1,4 do
			if UnitGroupRolesAssigned("party"..i) == "TANK" then
				WD.NewName = UnitName("party"..i)
				WD.Lclass,WD.NewClass = UnitClass("raid"..i)
				break;
			end
		end
	end
	
	if WD.NewName == WD.OldName then return end
	
	local ClassColor = RAID_CLASS_COLORS[WD.NewClass] and RAID_CLASS_COLORS[WD.NewClass].colorStr or "ffFFFFFF"
	local _,playerclass = UnitClass("player")
	if WD.NewName and GetMacroInfo("误导") and  playerclass == "HUNTER" then
		EditMacro("误导", nil , nil, "#showtooltip\n/cast [@target,help,exists][@"..WD.NewName..",exists][@pet][]误导")
		UIErrorsFrame:AddExternalWarningMessage("设置误导目标:  "..WD.NewName)
		ns.AATEXT("已将误导宏的目标改为:  |T132180:30|t|c"..ClassColor..WD.NewName.."|r")
		print("|cffFF0000已将误导宏的目标改为:  |r|T132180:30|t|c"..ClassColor..WD.NewName.."|r")
		WD.OldName = WD.NewName
	end
	if WD.NewName and GetMacroInfo("嫁祸") and  playerclass == "ROGUE" then
		EditMacro("嫁祸", nil , nil, "#showtooltip\n/cast [@target,help,exists][@"..WD.NewName..",exists][]嫁祸诀窍")
		UIErrorsFrame:AddExternalWarningMessage("设置嫁祸目标:  "..WD.NewName)
		ns.AATEXT("已将嫁祸宏的目标改为:  |T236383:30|t|c"..ClassColor..WD.NewName.."|r")
		print("|cffFF0000已将嫁祸宏的目标改为:  |r|T236383:30|t|c"..ClassColor..WD.NewName.."|r")
		WD.OldName = WD.NewName
	end
end

local function OnWDEvent(event)
	if event == 'GROUP_ROSTER_UPDATE' or event == 'PLAYER_ENTERING_WORLD' then
		if InCombatLockdown() then
			WD.InCombat = true
		else
			WD:UpdateMacroTarget()
		end
	elseif event == 'PLAYER_REGEN_ENABLED' then
		if WD.InCombat then
			WD:UpdateMacroTarget()
			WD.InCombat = false
		end
	end
end

ns.event('GROUP_ROSTER_UPDATE', OnWDEvent)
ns.event('PLAYER_ENTERING_WORLD', OnWDEvent)
ns.event('PLAYER_REGEN_ENABLED', OnWDEvent)