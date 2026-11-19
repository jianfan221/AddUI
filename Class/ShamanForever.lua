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

---------------------------------------------------------------------------------------------------
--元素之盾缺失高亮：闪电之盾(8134) / 水之护盾(408510)
--办法：借冷却管理器里这两个 buff 图标的显示状态（它能在战斗中拿到真实状态），
--      buff 没了就同步点亮动作条上对应的按钮
---------------------------------------------------------------------------------------------------

local ELEMENT_SHIELD_IDS = {8134, 408510}	--闪电之盾 / 水之护盾（互斥，同一时间只能激活一种）
local ALERT_TINT_R, ALERT_TINT_G, ALERT_TINT_B = 0.2, 1, 0.2	--原贴图是金色，乘算后偏绿

--冷却管理器里这个法术的 buff 图标；没配条目 / 还没加载时返回 nil
local function FindBuffItem(spellID)
	local viewers = {BuffIconCooldownViewer, BuffBarCooldownViewer}

	for i = 1, 2 do
		local viewer = viewers[i]
		if viewer and viewer.itemFramePool then
			for itemFrame in viewer.itemFramePool:EnumerateActive() do
				if itemFrame:GetBaseSpellID() == spellID then
					return itemFrame
				end
			end
		end
	end
end

--动作条上绑定该法术的按钮
local function FindButton(spellID)
	return ActionButtonUtil and ActionButtonUtil.GetActionButtonBySpellID(spellID)
end

--高亮框自己建、挂在 UIParent 下（不挂到受保护按钮下面），
--这样战斗中也能随便建/删，不会污染动作条
local glows = {}	--[spellID] = frame

local function GetGlow(spellID)
	local glow = glows[spellID]
	if not glow then
		glow = CreateFrame("Frame", nil, UIParent, "ActionButtonSpellAlertTemplate")
		glow.ProcStartFlipbook:SetVertexColor(ALERT_TINT_R, ALERT_TINT_G, ALERT_TINT_B)
		glow.ProcLoopFlipbook:SetVertexColor(ALERT_TINT_R, ALERT_TINT_G, ALERT_TINT_B)
		--跟随按钮位置和显隐（按钮翻页/隐藏时一起收起来）
		glow:SetScript("OnUpdate", function(self)
			local button = self.anchorButton
			if not button then return end
			local size = button:GetWidth() * 1.4
			self:SetSize(size, size)
			self:SetPoint("CENTER", button, "CENTER", 0, 0)
			self:SetShown(button:IsVisible())
		end)
		glows[spellID] = glow
	end
	return glow
end

local function SetGlow(spellID, button, on)
	if not on then
		local glow = glows[spellID]
		if glow then
			glow.anchorButton = nil
			glow:Hide()
		end
		return
	end

	local glow = GetGlow(spellID)
	glow.anchorButton = button
	glow:SetFrameStrata(button:GetFrameStrata())
	glow:SetFrameLevel(button:GetFrameLevel() + 5)
	glow:SetSize(button:GetWidth() * 1.4, button:GetHeight() * 1.4)
	glow:SetPoint("CENTER", button, "CENTER", 0, 0)
	glow.animationPlaying = true
	glow.ProcLoop:Play()
	glow:Show()
end

--每个盾各管各的：这个 buff 没了就亮它自己的动作条按钮
local function Update()
	if not ActionButtonUtil then return end

	for _, spellID in ipairs(ELEMENT_SHIELD_IDS) do
		local button = FindButton(spellID)
		if button then
			local item = FindBuffItem(spellID)
			--只在冷却管理器里配了这个 buff、并且它此刻不在时亮
			SetGlow(spellID, button, item and item:IsActive() == false)
		end
	end
end

--冷却管理器在 UNIT_AURA 时会调它，直接挂，下一帧再读（等暴雪把条目刷完）
if CooldownViewer_MarkAuraCacheDirty then
	hooksecurefunc("CooldownViewer_MarkAuraCacheDirty", function()
		C_Timer.After(0, Update)
	end)
end

--buff 变化之外还要补的几个时机：进世界、脱战（战斗中进游戏时要等脱战才能建高亮子框）、换动作条
local refreshFrame = CreateFrame("Frame")
refreshFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
refreshFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
refreshFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
refreshFrame:SetScript("OnEvent", function(_, event)
	C_Timer.After(0, Update)
	if event == "PLAYER_ENTERING_WORLD" then
		C_Timer.After(1, Update)	--冷却管理器的条目可能比我们晚建好
	end
end)

Update()
