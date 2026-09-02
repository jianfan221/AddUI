local _, ns = ...

-- 团队框架显示吸收治疗数值
local function UpdateRaidFrameAbsorb(event, unit)
	if not AddUIDB.raidabsorb then return end
	if ns.MM(unit) then return end
	if unit ~= "player" and (string.match(unit,"target") or string.match(unit,"pet")) then return end
	if unit ~= "player" and not string.match(unit,"raid") and not string.match(unit,"party") then return end

	-- 找到对应的框架
	local frame,raidframe
	if IsInRaid() then
		for i = 1, 8 do
			for j = 1, 5 do
				raidframe = C_AddOns.IsAddOnLoaded("DandersFrames") and _G["DandersRaidGroup"..i.."HeaderUnitButton"..j] or _G["CompactRaidGroup"..i.."Member"..j]
				if raidframe and raidframe.unit and not ns.MM(raidframe.unit) and UnitIsUnit(raidframe.unit, unit) then
					frame = raidframe
					break
				end
			end
			if frame then break end
		end
	elseif IsInGroup() then
		for i = 1, 5 do
			raidframe = C_AddOns.IsAddOnLoaded("DandersFrames") and _G["DandersPartyHeaderUnitButton"..i] or _G["CompactPartyFrameMember"..i]
			if raidframe and raidframe.unit and not ns.MM(raidframe.unit) and UnitIsUnit(raidframe.unit, unit) then
				frame = raidframe
				break
			end
		end
	end
	if not frame then return end

	if not frame.healAbsorbText then
        -- 创建一个独立的系统级置顶 Frame
        local topContainer = CreateFrame("Frame", nil, frame)
        topContainer:SetAllPoints(frame)
        topContainer:SetFrameStrata("HIGH")
        
        -- 创建治疗吸收数值（紫色）
        frame.healAbsorbText = topContainer:CreateFontString(nil, "OVERLAY")
        frame.healAbsorbText:SetFont(STANDARD_TEXT_FONT, 15, "OUTLINE")
        frame.healAbsorbText:SetPoint("CENTER", topContainer, 0, 0)
        frame.healAbsorbText:SetTextColor(1, 0, 1)
        frame.healAbsorbText:SetAlpha(0)

        -- 创建普通吸收盾数值（白色）
        frame.absorbText = topContainer:CreateFontString(nil, "OVERLAY")
        frame.absorbText:SetFont(STANDARD_TEXT_FONT, 15, "OUTLINE")
        frame.absorbText:SetPoint("RIGHT", topContainer, 0, 6)
        frame.absorbText:SetTextColor(1, 1, 1)
        frame.absorbText:SetAlpha(0)
    end

	--非普通吸收事件更新治疗吸收
	if event ~= "UNIT_ABSORB_AMOUNT_CHANGED" then
		local amount = UnitGetTotalHealAbsorbs(unit)
		frame.healAbsorbText:SetText(ns.value(amount))
		if amount == nil then
			frame.healAbsorbText:SetAlpha(0)
		else
			frame.healAbsorbText:SetAlpha(amount)
		end
	end
	--非治疗吸收事件更新普通吸收
	if event ~= "UNIT_HEAL_ABSORB_AMOUNT_CHANGED" then
		local amount = UnitGetTotalAbsorbs(unit)
		frame.absorbText:SetText(ns.value(amount))
		if amount == nil then
			frame.absorbText:SetAlpha(0)
		else
			frame.absorbText:SetAlpha(amount)
		end
	end
end

ns.event("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", UpdateRaidFrameAbsorb)
ns.event("UNIT_ABSORB_AMOUNT_CHANGED", UpdateRaidFrameAbsorb)
local function RefreshRaidFrameAbsorb()
	local num = GetNumGroupMembers()
	if IsInRaid() then
		for i = 1, num do
			UpdateRaidFrameAbsorb(nil, "raid"..i)
		end
	elseif IsInGroup() then
		UpdateRaidFrameAbsorb(nil, "player")
		for i = 1, num - 1 do
			UpdateRaidFrameAbsorb(nil, "party"..i)
		end
	end
end
ns.event("PLAYER_REGEN_ENABLED", RefreshRaidFrameAbsorb)
ns.event("ZONE_CHANGED_NEW_AREA", RefreshRaidFrameAbsorb)
--ns.event("PLAYER_ENTERING_WORLD", RefreshRaidFrameAbsorb)
----DandersPartyHeaderUnitButton3.