local _, ns = ...

-- 团队框架紫色数值显示吸收治疗盾数值
hooksecurefunc('DefaultCompactUnitFrameSetup', function(frame)
	if not AddUIDB.raidframebuff then return end
    if not frame.healAbsorbText then
        frame.healAbsorbText = frame.healthBar:CreateFontString(nil, "OVERLAY")
        frame.healAbsorbText:SetFont(STANDARD_TEXT_FONT, 15, "OUTLINE")
        frame.healAbsorbText:SetPoint("CENTER", frame.healthBar, "CENTER", 0, 0)
		frame.healAbsorbText:SetTextColor(1, 0, 1)
		frame.healAbsorbText:SetAlpha(0)
    end
end)

local function UpdateRaidFrameAbsorb(event,unit)
	if not AddUIDB.raidframebuff then return end
	if ns.MM(unit) then return end
	if unit ~= "player" and not string.match(unit,"party") and not string.match(unit,"raid") then return end

	local amount = UnitGetTotalHealAbsorbs(unit)

	if IsInRaid() then
		for i = 1,8 do
			for j = 1, 5 do
				local frame = _G["CompactRaidGroup"..i.."Member"..j]
				if frame and not frame:IsForbidden() and frame.unit and not ns.MM(frame.unit) and UnitIsUnit(frame.unit, unit) then
					frame.healAbsorbText:SetText(ns.value(amount))
					if amount == nil then
						frame.healAbsorbText:SetAlpha(0)
					else
						frame.healAbsorbText:SetAlpha(amount)
					end
					return
				end
			end
		end
	elseif IsInGroup() then
		for i = 1, 5 do
			local frame = _G["CompactPartyFrameMember"..i]
			if frame and not frame:IsForbidden() and frame.unit and not ns.MM(frame.unit) and UnitIsUnit(frame.unit, unit) then
				frame.healAbsorbText:SetText(ns.value(amount))
				if amount == nil then
					frame.healAbsorbText:SetAlpha(0)
				else
					frame.healAbsorbText:SetAlpha(amount)
				end
				return
			end
		end
	end
end

ns.event("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", UpdateRaidFrameAbsorb)
--ns.event("UNIT_ABSORB_AMOUNT_CHANGED", UpdateRaidFrameAbsorb)
--local amount = UnitGetTotalAbsorbs(unit)