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
		ns.hook(v, "Show", function(s)
			s:Hide()
		end)
		v:Show()
	end
end
ActionBarButtonEventsFrame:ForEachFrame(StyleButton)

end)