local _,ns = ...
ns.event("PLAYER_ENTERING_WORLD", function()
if AddUIDB.mmba ==  false then return end
if C_AddOns.IsAddOnLoaded("Dominos") then return end
if C_AddOns.IsAddOnLoaded("Bartender4") then return end
if C_AddOns.IsAddOnLoaded("ElvUI") then	return end
if C_AddOns.IsAddOnLoaded("BigFoot") then return end
if C_AddOns.IsAddOnLoaded("NDui") then return end


--隐藏动作条按钮相关改动HideActionbarAnimations
local function StyleButton(Button)
	local Name = Button:GetName()
	local InterruptDisplay = _G[Name].InterruptDisplay -- 打断施法红色
	local SpellCastAnimFrame = _G[Name].SpellCastAnimFrame -- 施法进度
	local TargetReticleAnimFrame = _G[Name].TargetReticleAnimFrame -- 地板法术圈
	for _, v in pairs ({
		InterruptDisplay,
		SpellCastAnimFrame,
		TargetReticleAnimFrame,
	}) do 
		hooksecurefunc(v, "Show", function(s)
			s:Hide()
		end)
		v:Show()
	end
end
local bar={"MultiBarBottomLeft", "MultiBarBottomRight", "Action", "MultiBarLeft", "MultiBarRight","MultiBar5","MultiBar6","MultiBar7"} 
for buttons=1,#bar do for i=1,12 do 
	StyleButton(_G[bar[buttons].."Button"..i])
end end
for i = 1, 6 do
	StyleButton(_G["OverrideActionBarButton"..i])
end

end)