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
		bar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, (i - 1) * (height + gap))
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
			bar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, (i - 1) * (height + gap))
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
				if r >= Max_Time then
					if bar.preview then
						-- 预览条走完一轮后重置循环，持续演示计时效果
						bar.elapsed = 0
						bar:SetValue(0)
						bar.time:SetText("0")
						changed = true
					else
						bar:Hide() changed = true
					end
				end
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

	-- 编辑模式预览：显示几条假数据条，方便调整位置/大小
	local previewData = {
		{ name = "法师",     class = "MAGE",        value = 20, color = { r = 0.25, g = 0.78, b = 0.92 } },
		{ name = "战士",     class = "WARRIOR",     value = 14, color = { r = 0.78, g = 0.61, b = 0.43 } },
		{ name = "萨满祭司", class = "SHAMAN",      value = 12, color = { r = 0.00, g = 0.44, b = 0.87 } },
		{ name = "死亡骑士", class = "DEATHKNIGHT", value = 12, color = { r = 0.77, g = 0.12, b = 0.23 } },
		{ name = "圣骑士",   class = "PALADIN",     value = 15, color = { r = 0.96, g = 0.55, b = 0.73 } },
	}
	local function ShowPreview()
		for i, data in ipairs(previewData) do
			local bar = bars[i]
			if not bar then break end
			local color = C_ClassColor.GetClassColor(data.class) or data.color
			bar.preview = true
			bar.elapsed = data.value
			bar:SetValue(data.value)
			bar.name:SetText(data.name)
			bar:SetStatusBarColor(color.r, color.g, color.b)
			bar.time:SetText(string.format("%d", data.value))
			bar:Show()
		end
		Layout()
	end

	local function HidePreview()
		for _, bar in ipairs(bars) do
			if bar.preview then
				bar.preview = nil
				bar:Hide()
			end
		end
		Layout()
	end

	if EditModeManagerFrame then
		EditModeManagerFrame:HookScript("OnShow", ShowPreview)
		EditModeManagerFrame:HookScript("OnHide", HidePreview)
		if EditModeManagerFrame:IsShown() then ShowPreview() end
	end
end)