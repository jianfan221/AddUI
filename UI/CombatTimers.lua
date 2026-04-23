local _,ns = ...
local floor, max = math.floor, math.max

local function FormatTime(seconds)
	seconds = max(0, seconds)
	return string.format("%d:%02d.%1d", floor(seconds / 60), floor(seconds) % 60, floor(seconds * 10) % 10)
end

ns.event("PLAYER_LOGIN", function()
	if not AddUIDB or not AddUIDB.chatCombatTimer then return end
	local refreshInterval = 0.1
	local combatRunning = InCombatLockdown()
	local combatStart = GetTime()
	local combatElapsed = 0
	local combatUpdateElapsed = 0
	local combatFrame = CreateFrame("Frame", "AddUICombatTimer", UIParent)
	combatFrame:SetSize(70, 22)
	combatFrame:SetPoint("TOPRIGHT", ChatFrame1Background, "TOPRIGHT", 0, 0)
	combatFrame.bg = combatFrame:CreateTexture(nil, "BACKGROUND")
	combatFrame.bg:SetAllPoints()
	combatFrame.bg:SetTexture("Interface/Buttons/WHITE8x8")
	combatFrame.bg:SetVertexColor(0, 0, 0, 0.5)
	combatFrame.text = combatFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	combatFrame.text:SetAllPoints()
	combatFrame.text:SetFont(STANDARD_TEXT_FONT, 17, "")
	combatFrame.text:SetTextColor(1, 1, 1, 1)
	combatFrame.text:SetText(FormatTime(combatRunning and (GetTime() - combatStart) or combatElapsed))
	combatFrame:SetScript("OnUpdate", function(self, elapsed)
		if not combatRunning then return end
		combatUpdateElapsed = combatUpdateElapsed + elapsed
		if combatUpdateElapsed < refreshInterval then return end
		combatUpdateElapsed = combatUpdateElapsed - refreshInterval
		self.text:SetText(FormatTime(GetTime() - combatStart))
	end)
	ns.event("PLAYER_REGEN_DISABLED", function()
		combatElapsed = 0
		combatRunning = true
		combatStart = GetTime()
	end)

	ns.event("PLAYER_REGEN_ENABLED", function()
		combatElapsed = GetTime() - combatStart
		combatRunning = false
		combatFrame.text:SetText(FormatTime(combatElapsed))
	end)

	local battleFrame = CreateFrame("Frame", "AddUIBattleResTimer", UIParent, "CooldownViewerBuffIconItemTemplate")
	battleFrame:SetSize(50, 50)
	battleFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -5, -185)
	battleFrame:Show()
	ns.AddEdit(battleFrame,"战复")
	battleFrame.Icon:SetTexture(C_Spell.GetSpellTexture(20484))
	battleFrame.Cooldown:SetReverse(false)
	battleFrame.Applications:SetScale(1.2)
	local battleUpdateElapsed = 0
	battleFrame:SetScript("OnUpdate", function(self, elapsed)
		battleUpdateElapsed = battleUpdateElapsed + elapsed
		if battleUpdateElapsed < 1 then return end
		battleUpdateElapsed = battleUpdateElapsed - 1
		local chargeInfo = C_Spell.GetSpellCharges(20484)
		if chargeInfo then
			local charges = chargeInfo.currentCharges or 0
			battleFrame.Cooldown:SetCooldown(chargeInfo.cooldownStartTime or 0, chargeInfo.cooldownDuration or 0)
			if charges > 0 then
				battleFrame.Applications.Applications:SetText(charges)
				battleFrame.Applications.Applications:SetTextColor(1, 1, 1)
			else
				battleFrame.Applications.Applications:SetText("0")
				battleFrame.Applications.Applications:SetTextColor(1, 0, 0)
			end
		else
			battleFrame.Cooldown:Clear()
			battleFrame.Applications.Applications:SetText("")
		end
	end)
end)