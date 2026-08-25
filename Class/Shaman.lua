local _,ns = ...

-- 萨满专属：自然守护者(31616)触发30秒倒数,显示在头像位置
local _, cls = UnitClass("player")
if cls == "SHAMAN" then
	ns.tips("萨满自然守护者触发30秒倒数(头像位置)")

	local SpellID = 31616
	local DURATION = 30
	local _,hh = CompactPartyFrameMember1:GetSize()
	local size = hh

	local frame = CreateFrame("Frame", "AddUIClassShamanCountdown", CompactPartyFrameMember1, "CooldownViewerBuffIconItemTemplate")
	
	frame:SetSize(size, size)
	frame:SetPoint("TOPRIGHT", CompactPartyFrameMember1, "TOPLEFT", -1, 0)
	frame.DebuffBorder = nil -- 去掉减益边框
	frame:Show() -- 常驻显示
	frame.Icon:SetTexture(136060)--C_Spell.GetSpellTexture(SpellID)
	frame.Cooldown:SetReverse(false)
	frame.Cooldown:SetCountdownAbbrevThreshold(600)
	frame.Cooldown:GetCountdownFontString():SetFont(STANDARD_TEXT_FONT, size*0.5, "OUTLINE")

	-- 触发时闪光
	frame.SAA = CreateFrame("Frame", nil, frame, "ActionButtonSpellAlertTemplate")
	frame.SAA:SetSize(size * 1.4, size * 1.4)
	frame.SAA:SetPoint("CENTER", frame, "CENTER", 0, 0)
	-- 青蓝色
	if frame.SAA.ProcStartFlipbook then frame.SAA.ProcStartFlipbook:SetVertexColor(0, 0.8, 1) end
	if frame.SAA.ProcLoopFlipbook then frame.SAA.ProcLoopFlipbook:SetVertexColor(0, 0.8, 1) end
	if frame.SAA.ProcAltGlow then frame.SAA.ProcAltGlow:SetVertexColor(0, 0.8, 1) end
	frame.SAA:Hide()

	ns.event("SPELL_UPDATE_COOLDOWN", function(event, spellID)
		if spellID ~= SpellID then return end
		if frame:IsShown() and frame.Icon:IsDesaturated() then return end -- 已在倒数中，避免重复重置
		frame.Cooldown:SetCooldown(GetTime(), DURATION)
		frame.Icon:SetDesaturated(true) -- 触发后褪色
		frame.SAA:Show()
		frame.SAA.ProcStartAnim:Play()
		C_Timer.After(5, function()
			if frame.SAA then
				frame.SAA.ProcStartAnim:Stop()
				frame.SAA:Hide()
			end
		end)
	end)

	-- 冷却结束取消褪色（常驻显示，不隐藏）
	frame.Cooldown:SetScript("OnCooldownDone", function()
		frame.Icon:SetDesaturated(false)
	end)
end
