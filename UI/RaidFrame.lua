local _,ns = ...

ns.event("PLAYER_LOGIN", function()
if not AddUIDB.raidframebuff then return end

hooksecurefunc('CompactUnitFrame_UtilSetDebuff', function(self,debuffFrame, aura)
--[[
	if not debuffFrame.DispelBorder then
		debuffFrame.DispelBorder = debuffFrame:CreateTexture(nil, "OVERLAY")
		debuffFrame.DispelBorder:SetTexture(237671)
		debuffFrame.DispelBorder:SetPoint("TOPLEFT",-4,4)
		debuffFrame.DispelBorder:SetPoint("BOTTOMRIGHT",4,-4)
		debuffFrame.DispelBorder:SetBlendMode("ADD") 
	end
	if aura.dispelName == nil then
		debuffFrame.DispelBorder:SetVertexColor(0,0,0,0)
	else
		AuraUtil.SetAuraBorderColor(debuffFrame.DispelBorder, aura.dispelName)
	end
--]]	
	
	if not debuffFrame.border then return end
	debuffFrame.border:SetPoint("TOPLEFT",-1,1)
	debuffFrame.border:SetPoint("BOTTOMRIGHT",1,-1)
	debuffFrame.border:SetTexture("Interface\\AddOns\\AddUI\\UI\\Textures\\AuraBorder.png")
	debuffFrame.border:SetTexCoord(0,1,0,1)
	if aura.dispelName == nil then
		debuffFrame.border:Hide()
	else
		debuffFrame.border:Show()
	end
end)

hooksecurefunc("CompactUnitFrame_UpdateRoleIcon",function(frame)
	C_Timer.After(0,function()
		if not frame.roleIcon then return end
		local role = UnitGroupRolesAssigned(frame.unit)
		if role == "TANK" then
			frame.roleIcon:SetTexture("Interface\\AddOns\\AddUI\\UI\\Textures\\ROLE-TDPS",true)
			frame.roleIcon:SetTexCoord(0.02,.28,.35,.63)
		elseif role == "HEALER" then
			frame.roleIcon:SetTexture("Interface\\AddOns\\AddUI\\UI\\Textures\\ROLE-N",true)
			frame.roleIcon:SetTexCoord(.35,.6,.05,.3)
		elseif role == "DAMAGER" then
			frame.roleIcon:SetTexture("Interface\\AddOns\\AddUI\\UI\\Textures\\ROLE-TDPS",true)
			frame.roleIcon:SetTexCoord(.35,.6,.35,.65)
		end
		frame.roleIcon:SetDrawLayer("OVERLAY")
	end)
end)

hooksecurefunc('DefaultCompactUnitFrameSetup', function(frame)
	frame.healthBar:SetStatusBarTexture("Interface\\AddOns\\AddUI\\UI\\Textures\\Raid-Bar-Hp-Fill")
	frame.powerBar:SetStatusBarTexture("Interface\\AddOns\\AddUI\\UI\\Textures\\Raid-Bar-Hp-Fill")
	for i=1, #frame.buffFrames do
		frame.buffFrames[i].cooldown:GetRegions():SetFont(STANDARD_TEXT_FONT, frame.buffFrames[i]:GetHeight()/1.6, "OUTLINE")
		frame.buffFrames[i].cooldown:SetHideCountdownNumbers(false)
	end
	for i=1, #frame.debuffFrames do
		frame.debuffFrames[i].cooldown:GetRegions():SetFont(STANDARD_TEXT_FONT, frame.debuffFrames[i]:GetHeight()/1.6, "OUTLINE")
		frame.debuffFrames[i].cooldown:SetHideCountdownNumbers(false)
	end
	for i=1, #frame.dispelDebuffFrames do
		frame.dispelDebuffFrames[i]:SetScale(1.6)
	end
	if frame.CenterDefensiveBuff then
		frame.CenterDefensiveBuff:SetScale(0.7)
		frame.CenterDefensiveBuff.cooldown:GetRegions():SetFont(STANDARD_TEXT_FONT, frame.CenterDefensiveBuff:GetHeight()/1.6, "OUTLINE")
		frame.CenterDefensiveBuff.cooldown:SetHideCountdownNumbers(false)
	end
end)


local function SetMouseHighlight(frame)
	frame:HookScript("OnEnter", function(self)
		self.selectionHighlight:SetVertexColor(0,1,1)
		self.selectionHighlight:Show()
	end)
	frame:HookScript("OnLeave", function(self)
		if  UnitIsUnit(self.unit,"target") then--not ns.MM(self.unit) and not ns.MM(UnitIsUnit(self.unit,"target")) and
			self.selectionHighlight:SetVertexColor(1,1,1)
		else
			self.selectionHighlight:Hide()
		end
	end)
end
for i = 1,5 do
	SetMouseHighlight(_G["CompactPartyFrameMember"..i])
end
hooksecurefunc("CompactRaidGroup_UpdateUnits",function(frame)
	for i = 1,5 do
		SetMouseHighlight(_G[frame:GetName().."Member"..i])
	end
end)

end)