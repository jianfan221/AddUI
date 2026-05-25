local _,ns = ...
ns.event("PLAYER_LOGIN", function()
	if not AddUIDB.interrupt then return end

	local MAX_BARS = 6
	local Max_Time = 20
	local width = 170
	local height = 30
	local gap = 1

	-- 打断进度条容器
	local frame = CreateFrame("Frame", "AddUIInterruptFrame", UIParent)
	frame:SetPoint("LEFT", 150, 100)
	frame:SetSize(width, MAX_BARS * (height + gap))
	frame:Hide()
	ns.AddEdit(frame,"打断记录")

	local bars = {}
	for i = 1, MAX_BARS do
		local bar = CreateFrame("StatusBar", nil, frame)
		bar:SetSize(width, height)
		bar:SetStatusBarTexture("Interface\\AddOns\\AddUI\\UI\\Textures\\Raid-Bar-Hp-Fill")
		bar:SetMinMaxValues(0, Max_Time)
		bar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, (i - 1) * (height + gap))
		bar:Hide()

		bar.bg = bar:CreateTexture(nil, "BORDER")
		bar.bg:SetPoint("TOPLEFT", -1, 1)
		bar.bg:SetPoint("BOTTOMRIGHT", 1, -1)
		bar.bg:SetColorTexture(0, 0, 0, 0.7)

		bar.name = bar:CreateFontString(nil, "OVERLAY")
		bar.name:SetPoint("LEFT", 4, 0)
		bar.name:SetFont(STANDARD_TEXT_FONT, height * 0.6, "OUTLINE")

		bar.time = bar:CreateFontString(nil, "OVERLAY")
		bar.time:SetPoint("RIGHT", -4, 0)
		bar.time:SetFont(STANDARD_TEXT_FONT, height * 0.6, "OUTLINE")

		bars[i] = bar
	end

	local function Layout()
		local t = {}
		for _, bar in ipairs(bars) do
			if bar:IsShown() then tinsert(t, bar) end
		end
		sort(t, function(a, b) return a.elapsed > b.elapsed end)

		for i, bar in ipairs(t) do
			bar:ClearAllPoints()
			bar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, (i - 1) * (height + gap))
		end

		if #t > 0 then frame:Show() else frame:Hide() end
	end

	frame:SetScript("OnUpdate", function(self, elapsed)
		local changed
		for _, bar in ipairs(bars) do
			if bar:IsShown() then
				bar.elapsed = bar.elapsed + elapsed
				local r = math.min(Max_Time, bar.elapsed)
				bar:SetValue(r)
				bar.time:SetText(string.format("%d", r))
				if r >= Max_Time then bar:Hide() changed = true end
			end
		end
		if changed then Layout() end
	end)

	ns.event("UNIT_SPELLCAST_INTERRUPTED", function(event, unitTarget, castGUID, spellID, interruptedBy, castBarID)
		if not IsInGroup() then return end
		if not string.match(unitTarget, "nameplate") or interruptedBy ==nil then return end

		local bar
		for _, b in ipairs(bars) do
			if not b:IsShown() then bar = b; break end
		end
		if not bar then return end

		bar.name:SetText(UnitNameFromGUID(interruptedBy))
		local _, classFilename = UnitClassFromGUID(interruptedBy)
		local color = C_ClassColor.GetClassColor(classFilename)
		if color then bar:SetStatusBarColor(color.r, color.g, color.b) else bar:SetStatusBarColor(1, 1, 1) end
		bar.elapsed = 0
		bar:Show()
		Layout()
	end)
end)