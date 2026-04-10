local _, ns = ...

-- 在初始化时为每个框架创建吸收治疗盾文本
hooksecurefunc('DefaultCompactUnitFrameSetup', function(frame)
	if not AddUIDB.raidframebuff then return end
    if not frame.healAbsorbText then
        frame.healAbsorbText = frame.healthBar:CreateFontString(nil, "OVERLAY")
        frame.healAbsorbText:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
        frame.healAbsorbText:SetPoint("CENTER", frame.healthBar, "CENTER", 0, 0)
		frame.healAbsorbText:SetTextColor(1, 0, 1)
		frame.healAbsorbText:SetAlpha(0)
    end
end)

local function UpdateRaidFrameAbsorb(event,unit)
	if not AddUIDB.raidframebuff then return end
	if ns.MM(unit) then return end
	
	local amount = UnitGetTotalHealAbsorbs(unit)	--获取吸收盾数值

	if IsInRaid() then
		if CompactRaidFrameContainer and CompactRaidFrameContainer.flowFrames then
			for _, frame in ipairs(CompactRaidFrameContainer.flowFrames) do
				if frame.unit and UnitIsUnit(frame.unit, unit) then
					frame.healAbsorbText:SetText(ns.value(amount))
					if amount == nil then
						frame.healAbsorbText:SetAlpha(0)
					else
						frame.healAbsorbText:SetAlpha(amount)
					end
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
			end
		end
	end
end

ns.event("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", UpdateRaidFrameAbsorb)
--ns.event("UNIT_ABSORB_AMOUNT_CHANGED", UpdateRaidFrameAbsorb)
--local amount = UnitGetTotalAbsorbs(unit)