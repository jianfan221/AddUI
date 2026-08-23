local _,ns = ...

-- 萨满专属：自然守护者(31616)触发30秒倒数,显示在头像位置
local _, cls = UnitClass("player")
if cls == "SHAMAN" then
	ns.tips("萨满自然守护者触发30秒倒数(头像位置)")

	local SpellID = 31616
	local DURATION = 30

	local frame = CreateFrame("Frame", "AddUIClassShamanCountdown", PlayerFrame, "CooldownViewerBuffIconItemTemplate")
	local size = PlayerFrame.PlayerFrameContainer.PlayerPortrait:GetSize()
	frame:SetSize(size, size)
	frame:SetPoint("LEFT", PlayerFrame.PlayerFrameContainer.PlayerPortrait or UIParent, "LEFT", 0, 0)
	frame:Hide()
	frame.Icon:SetTexture(C_Spell.GetSpellTexture(SpellID))
	frame.Cooldown:SetReverse(false)
	frame.Cooldown:SetCountdownAbbrevThreshold(600)
	frame.Cooldown:GetCountdownFontString():SetFont(STANDARD_TEXT_FONT, 25, "OUTLINE")

	-- 圆形遮罩，与头像一致裁剪（图标 + 冷却圈内部纹理）
	local mask = frame:CreateMaskTexture()
	mask:SetAllPoints(frame.Icon)
	mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
	frame.Icon:AddMaskTexture(mask)
	local function MaskRegions(parent)
		for _, region in ipairs({parent:GetRegions()}) do
			if region.AddMaskTexture then
				region:AddMaskTexture(mask)
			end
		end
		for _, child in ipairs({parent:GetChildren()}) do
			MaskRegions(child)
		end
	end
	MaskRegions(frame.Cooldown)

	ns.event("SPELL_UPDATE_COOLDOWN", function(event, spellID)
		if spellID ~= SpellID then return end
		if frame:IsShown() then return end -- 已在倒数中，避免重复重置
		frame:Show()
		frame.Cooldown:SetCooldown(GetTime(), DURATION)
	end)

	-- 冷却结束自动隐藏
	frame.Cooldown:SetScript("OnCooldownDone", function()
		frame:Hide()
	end)
end
