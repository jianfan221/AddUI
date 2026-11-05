-- 思路参考 Better Fishing（作者 Yuyuli）：BetterFishing/BetterFishing.lua 中的钓鱼施法检测与临时音效 CVar 处理。
local _, ns = ...

local fishingSpells = {
	[131474] = true,
	[131476] = true,
	[131490] = true,
}

local function IsFishingSpell(spellID)
	if fishingSpells[spellID] then return true end
	return C_Spell.GetSpellName(spellID) == PROFESSIONS_FISHING
end

local savedSFXVolume
local soundsEnhanced = false
local isFishing = false

local function SetFishingSounds(enable)
	if enable == soundsEnhanced then return end
	soundsEnhanced = enable

	if enable then
		savedSFXVolume = C_CVar.GetCVar("Sound_SFXVolume")
		C_CVar.SetCVar("Sound_SFXVolume", "1")
	elseif savedSFXVolume then
		C_CVar.SetCVar("Sound_SFXVolume", savedSFXVolume)
		savedSFXVolume = nil
	end
end

local function UpdateFishingSounds()
	SetFishingSounds(isFishing and AddUIDB.fishingSound)
end
ns.UpdateFishingSounds = UpdateFishingSounds

local frame = CreateFrame("Frame")
frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
frame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:SetScript("OnEvent", function(_, event, unit, _, spellID)
	if event == "PLAYER_LOGOUT" then
		isFishing = false
		SetFishingSounds(false)
	elseif unit == "player" and IsFishingSpell(spellID) then
		isFishing = event == "UNIT_SPELLCAST_CHANNEL_START"
		UpdateFishingSounds()
	end
end)