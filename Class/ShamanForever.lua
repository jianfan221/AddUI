local _,ns = ...

--无限服（1.60/Camelot）萨满专属：
--强化风暴打击(1223031，2/2) 让自己躲闪/招架时重置风暴打击(17364)冷却，
--触发时给动作条上的风暴打击按钮高亮 2 秒 + 播放音效

local _, cls = UnitClass("player")
if cls ~= "SHAMAN" then return end
if WOW_PROJECT_ID ~= WOW_PROJECT_CAMELOT then return end

local STORMSTRIKE_ID = 17364	--风暴打击
local TALENT_ID = 1223031	--强化风暴打击（等级2）
local HIGHLIGHT_TIME = 3	--高亮持续秒数（施放成功会提前关掉）
local SOUND_FILE = 568154	--触发音效

--用暴雪工具查找绑定指定法术的动作条按钮（同 Class\ActionBarIcon.lua）
local function FindActionButton(spellID)
	local actionButtonUtil = _G.ActionButtonUtil
	return actionButtonUtil and actionButtonUtil.GetActionButtonBySpellID(spellID)
end

--开关：AddUIDB.shamanStormstrikeAlert（设置界面 → 职业 → 萨满，默认开）
local function IsEnabled()
	return AddUIDB and AddUIDB.shamanStormstrikeAlert
end

local alertTimer
local alertButton
local soundHandle
local lastCast = 0	--上次自己施放风暴打击的时间
local onCooldown = false	--风暴打击当前是否处于冷却中
local CD_LENGTH = 8	--风暴打击冷却秒数（自然结束也会发 SPELL_UPDATE_COOLDOWN，用它排除）

--关掉高亮
local function HideAlert()
	if alertTimer then
		alertTimer:Cancel()
		alertTimer = nil
	end
	if alertButton and ActionButtonSpellAlertManager then
		ActionButtonSpellAlertManager:HideAlert(alertButton)
	end
	alertButton = nil
end

local function FlashStormstrike()
	if not IsEnabled() then return end
	if not C_SpellBook.IsSpellKnown(TALENT_ID) then return end
	local button = FindActionButton(STORMSTRIKE_ID)
	if not (button and ActionButtonSpellAlertManager) then return end
	ActionButtonSpellAlertManager:ShowAlert(button)
	alertButton = button
	if soundHandle then StopSound(soundHandle) end	--重复触发：掐掉上一次的音效，从头播
	_, soundHandle = PlaySoundFile(SOUND_FILE, "Master")
	if alertTimer then alertTimer:Cancel() end	--重复触发：取消旧计时，重新计时
	alertTimer = C_Timer.NewTimer(HIGHLIGHT_TIME, HideAlert)
end

--记录自己施放风暴打击的时间（SENT 最早、SUCCEEDED 兜底）
local castFrame = CreateFrame("Frame")
castFrame:RegisterUnitEvent("UNIT_SPELLCAST_SENT", "player")
castFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
castFrame:SetScript("OnEvent", function(_, event, ...)
	--SENT: unit, target, castGUID, spellID / SUCCEEDED: unit, castGUID, spellID
	local spellID = event == "UNIT_SPELLCAST_SENT" and select(4, ...) or select(3, ...)
	if spellID == STORMSTRIKE_ID then
		lastCast = GetTime()
		if event == "UNIT_SPELLCAST_SUCCEEDED" then
			HideAlert()	--施放成功：立刻关掉高亮
		end
	end
end)

--只看冷却变化：施放引起的不算、自然结束的不算、已经冷却好的也不再提示
local cdFrame = CreateFrame("Frame")
cdFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
cdFrame:SetScript("OnEvent", function(_, _, spellID)
	if spellID ~= STORMSTRIKE_ID or lastCast == 0 then return end
	local delta = GetTime() - lastCast
	if delta < 0.2 then
		onCooldown = true	--施放引起：冷却开始
		return
	end
	if delta > CD_LENGTH - 0.5 then
		onCooldown = false	--自然结束
		return
	end
	if not onCooldown then return end	--已经冷却好了（上次重置后没再按），不再提示
	onCooldown = false
	FlashStormstrike()
end)
