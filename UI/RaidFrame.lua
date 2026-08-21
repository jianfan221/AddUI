local _,ns = ...

ns.event("PLAYER_LOGIN", function()
	if not AddUIDB.raidframebuff then return end

	ns.hook("CompactUnitFrame_UpdateRoleIcon",function(frame)
		if not frame.roleIcon then return end
		local role = UnitGroupRolesAssigned(frame.unit)
		if ns.MM(role) then return end
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

	local function SetMouseHighlight(frame)
		if frame and not frame.adBorder then
			frame.adBorder = CreateFrame("Frame", nil, frame, "BackdropTemplate")
			frame.adBorder:SetFrameStrata("MEDIUM")
			frame.adBorder:SetPoint("TOPLEFT", 0, 0)
			frame.adBorder:SetPoint("BOTTOMRIGHT", 0, 0)
			frame.adBorder:SetBackdrop({edgeFile = 'Interface\\Buttons\\WHITE8x8',edgeSize = 4})
			frame.adBorder:Hide()
			frame:HookScript("OnEnter", function(self)
				self.adBorder:SetBackdropBorderColor(0,1,1,1)
				self.adBorder:Show()
			end)
			frame:HookScript("OnLeave", function(self)
				self.adBorder:Hide()
			end)
		end
	end
	for i = 1,5 do
		SetMouseHighlight(_G["CompactPartyFrameMember"..i])
	end
	ns.hook("CompactRaidGroup_UpdateUnits",function(frame)
		for i = 1,5 do
			SetMouseHighlight(_G[frame:GetName().."Member"..i])
		end
	end)

end)