local _, ns = ...

local alert = CreateFrame("Button", nil, UIParent)
alert:SetSize(1800, 40)
alert:SetPoint("CENTER", UIParent, "CENTER", 0, 290)
alert:Hide()

local text = alert:CreateFontString(nil, "OVERLAY")
text:SetPoint("CENTER")
text:SetFont(STANDARD_TEXT_FONT, 22, "OUTLINE")
text:SetJustifyH("CENTER")

local generation = 0

function ns.HideDeathRecapAlert()
	generation = generation + 1
	alert:Hide()
end

local function FormatOptional(label, value, color)
	if value == nil then return nil end
	if not ns.MM(value) and value == 0 then return nil end
	return (color or "") .. label .. " " .. ns.value(value) .. "|r"
end

local function GetEventName(event)
	local eventType = event.event
	local eventSpellID = event.spellId
	if eventType == nil or ns.MM(eventType) then return nil, eventSpellID end

	if eventType == "SWING_DAMAGE" then
		return ACTION_SWING, 88163
	end
	if eventType == "ENVIRONMENTAL_DAMAGE" then
		local environmentalType = event.environmentalType
		if environmentalType == nil or ns.MM(environmentalType) then return nil, eventSpellID end
		return _G["ACTION_ENVIRONMENTAL_DAMAGE_" .. string.upper(environmentalType)], eventSpellID
	end

	return event.spellName, eventSpellID
end

local function GetEventIcon(eventSpellID)
	if eventSpellID == nil or ns.MM(eventSpellID) then return nil end
	local texture = C_Spell.GetSpellTexture(eventSpellID)
	if texture == nil or ns.MM(texture) or texture == "" then return nil end
	return "|T" .. texture .. ":16:16:0:0:64:64:5:59:5:59|t"
end

local function ShowDeathRecap()
	if not ns.DB or not ns.DB.deathRecapAlert then return end

	local hasEvents = C_DeathRecap.HasRecapEvents()
	if ns.MM(hasEvents) or not hasEvents then return end

	local events = C_DeathRecap.GetRecapEvents()
	if events == nil or ns.MM(events) then return end

	local event = events[1]
	if event == nil or ns.MM(event) then return end

	local parts = {}
	local function PushPart(part)
		if part ~= nil then
			table.insert(parts, part)
		end
	end

	local eventName, eventSpellID = GetEventName(event)
	if eventName ~= nil then
		local eventIcon = GetEventIcon(eventSpellID)
		local eventText = "|cff66ccff" .. eventName .. "|r"
		if eventIcon ~= nil then
			eventText = eventIcon .. eventText
		end
		PushPart(eventText)
	end

	PushPart(FormatOptional("总伤", event.amount, "|cffffff00"))
	PushPart(FormatOptional("生命值", event.currentHP, "|cff00ff00"))
	PushPart(FormatOptional("过量", event.overkill, "|cffff0000"))
	if event.avoidable ~= nil and not ns.MM(event.avoidable) and event.avoidable then
		PushPart("|cffffffff可规避|r")
	end

	if #parts == 0 then return end

	text:SetText(table.concat(parts, " "))
	local textWidth = text:GetStringWidth()
	if not ns.MM(textWidth) then
		alert:SetWidth(math.min(textWidth + 20, 1800))
	end
	alert:Show()

	local currentGeneration = generation
	C_Timer.After(12, function()
		if currentGeneration == generation then
			alert:Hide()
		end
	end)
end

ns.event("PLAYER_DEAD", function()
	if not ns.DB or not ns.DB.deathRecapAlert then return end

	generation = generation + 1
	local currentGeneration = generation
	alert:Hide()
	C_Timer.After(0.1, function()
		if currentGeneration == generation then
			ShowDeathRecap()
		end
	end)
end)