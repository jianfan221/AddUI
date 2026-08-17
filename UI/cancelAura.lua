local _,ns = ...

ns.tips("奥术涌动4秒声音提醒")
EventRegistry:RegisterFrameEventAndCallback("UNIT_SPELLCAST_SUCCEEDED",function(_,unit,_,spellID)
	if unit ~= "player" then return end
	if spellID ~= 365350 then return end
	if not C_SpellBook.IsSpellKnown(449619) then return end
	local s = C_SpellBook.IsSpellKnown(449412) and 17.4 or 15
	C_Timer.After(s-4.1, function()
		if UnitIsDead("player") then return end
		PlaySoundFile("Interface\\AddOns\\AddUI\\UI\\media\\568154.mp3", "Master")
	end)
end)


ns.tips("BUFF栏左侧取消光环按钮")

local needcancel = [[
/cancelAura 操控时间
]]

local button

local function HideAura()
	if not button then return end
	button.text:Hide()
	button.text:SetText("")
	button.T:Hide()
	button.T:SetTexture(nil)
	button.Cooldown:SetCooldown(0, 0)
	button.SAA:Hide()
	button.SAA.ProcStartAnim:Stop()
end

local function ShowAura()
	if not button then return end
	button.text:Show()
	button.text:SetText(string.format("%d%%", UnitHealthPercent("player", true, CurveConstants.ScaleTo100)))
	button.T:Show()
	button.T:SetTexture(985088)
	button.Cooldown:SetCooldown(GetTime(), 10)
	button.SAA:Show()
	button.SAA.ProcStartAnim:Play()
	PlaySoundFile("Interface\\AddOns\\AddUI\\UI\\media\\342247.mp3", "Master")
end

local function CreateFrames()
	if button then return end

	-- 主框架
	local f = CreateFrame("Frame", "ADDUIcancelAuraButton", UIParent)
	f:SetSize(60, 60)
	f:SetPoint("TOP", UIParent, "TOP", 300, -10)
	ns.AddEdit(f, "取消\n操控")
	button = f

	-- 背景
	f.Background = f:CreateTexture(nil, "BACKGROUND")
	f.Background:SetTexture(130937)
	f.Background:SetAllPoints(f)
	f.Background:SetColorTexture(0, 0, 0, 0)

	-- 悬停提示
	f.tiptext = f:CreateFontString(nil, "BACKGROUND")
	f.tiptext:SetFont(SystemFont_Outline_Small:GetFont(), 20, "OUTLINE")
	f.tiptext:SetPoint("CENTER", f, "CENTER", 0, 0)
	f.tiptext:SetText("取消\n操控")
	f.tiptext:SetTextColor(0.5, 0.5, 0.5)
	f.tiptext:Hide()

	-- 安全取消按钮
	local btn = CreateFrame("CheckButton", "ADcancelAuraButton", f, "SecureActionButtonTemplate")
	btn:SetAttribute("type", "macro")
	btn:SetAttribute("macrotext", needcancel)
	btn:SetAllPoints(f)
	btn:RegisterForClicks("AnyDown", "AnyUp")
	btn:SetScript("OnEnter", function()
		f.Background:SetColorTexture(0, 0, 0, .5)
		f.tiptext:Show()
	end)
	btn:SetScript("OnLeave", function()
		f.Background:SetColorTexture(0, 0, 0, 0)
		f.tiptext:Hide()
	end)
	btn:SetScript("OnClick", HideAura)

	-- 子按钮覆盖父框架拦截拖动 → 编辑模式下让子按钮也响应拖动
	local function ToggleChildDrag()
		if InCombatLockdown() then return end
		local inEditMode = EditModeManagerFrame and EditModeManagerFrame:IsShown()
		if inEditMode then
			btn:RegisterForDrag("LeftButton")
			btn:SetScript("OnDragStart", function()
				f:StartMoving()
			end)
			btn:SetScript("OnDragStop", function()
				f:StopMovingOrSizing()
				if not AddUIDB then AddUIDB = {} end
				local left, bottom = f:GetLeft(), f:GetBottom()
				AddUIDB["ADDUIcancelAuraButton_Edit"] = {"BOTTOMLEFT", "UIParent", "BOTTOMLEFT", left, bottom}
			end)
		else
			btn:RegisterForDrag()
			btn:SetScript("OnDragStart", nil)
			btn:SetScript("OnDragStop", nil)
		end
	end
	EditModeManagerFrame:HookScript("OnShow", ToggleChildDrag)
	EditModeManagerFrame:HookScript("OnHide", ToggleChildDrag)
	ToggleChildDrag()

	-- 操控时间图标
	f.T = f:CreateTexture()
	f.T:SetAllPoints(f)
	f.T:SetTexture(985088)
	f.T:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	f.T:Hide()

	-- 血量百分比
	f.text = f:CreateFontString(nil)
	f.text:SetFont(SystemFont_Outline_Small:GetFont(), 30, "OUTLINE")
	f.text:SetPoint("TOP", f, "BOTTOM", 0, 0)
	f.text:Hide()

	-- 冷却（10 秒转圈）
	f.Cooldown = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
	f.Cooldown:SetAllPoints(f.T)
	f.Cooldown:SetHideCountdownNumbers(false)
	f.Cooldown:SetUseCircularEdge(true)
	f.Cooldown:SetReverse(true)
	f.Cooldown:SetScript("OnCooldownDone", function()
		HideAura()
	end)
	local regon = f.Cooldown:GetRegions()
	if regon and regon.GetText then
		regon:SetFont(STANDARD_TEXT_FONT, 30, "OUTLINE")
	end

	-- SAA 法术警示动画
	f.SAA = CreateFrame("Frame", nil, f, "ActionButtonSpellAlertTemplate")
	local w, h = f:GetSize()
	f.SAA:SetSize(w * 1.4, h * 1.4)
	f.SAA:SetPoint("CENTER", f, "CENTER", 0, 0)
	f.SAA:Hide()
end

local function OnCancelAuraEvent(event, unit, _, spellId)
	if event == "PLAYER_ENTERING_WORLD" then
		CreateFrames()
		return
	end
	if unit ~= "player" then return end

	if spellId == 342245 then      -- 施放操控时间 → 显示
		ShowAura()
	elseif spellId == 342247 then  -- 操控时间结束 → 隐藏
		HideAura()
	end
end

local _, cls = UnitClass("player")
if cls == "MAGE" then
	ns.event('PLAYER_ENTERING_WORLD', OnCancelAuraEvent)
	ns.event('UNIT_SPELLCAST_SUCCEEDED', OnCancelAuraEvent)
end



