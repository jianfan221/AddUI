local _,ns = ...
ns.event("PLAYER_ENTERING_WORLD", function()
if C_AddOns.IsAddOnLoaded("Dominos") then return end
if C_AddOns.IsAddOnLoaded("Bartender4") then return end
if C_AddOns.IsAddOnLoaded("ElvUI") then	return end
if C_AddOns.IsAddOnLoaded("BigFoot") then return end
if C_AddOns.IsAddOnLoaded("NDui") then return end

if AddUIDB.mmb ==  false  then return end
ns.StyleButton()
C_Timer.After(5,function()
	if InCombatLockdown() then return end
	ns.StyleButton()
end)
hooksecurefunc(EditModeSystemMixin, "OnEditModeExit", function()
	ns.StyleButton()
end)

--动作条@简繁NGA:zhangzhanxian3

if InCombatLockdown() then return end		--战斗中不执行

-- 动作条按键范围着色
hooksecurefunc("ActionButton_UpdateRangeIndicator", function(self, checksRange, inRange)
if self.action == nil then return end
local isUsable, notEnoughMana = IsUsableAction(self.action)
	if ( checksRange and not inRange ) then
		_G[self:GetName().."Icon"]:SetVertexColor(0.5, 0.1, 0.1)
	elseif isUsable ~= true or notEnoughMana == true then
		_G[self:GetName().."Icon"]:SetVertexColor(0.4, 0.4, 0.4)
	else
		_G[self:GetName().."Icon"]:SetVertexColor(1, 1, 1)
	end
end)

--宏颜色--
local r={"MultiBarBottomLeft", "MultiBarBottomRight", "Action", "MultiBarLeft", "MultiBarRight","MultiBar5","MultiBar6","MultiBar7"} 
for b=1,#r do for i=1,12 do _G[r[b].."Button"..i.."Name"]:SetVertexColor(0, 255, 255) end end

--经验条
StatusTrackingBarManager:SetScale(.73)

--队伍查找器
QueueStatusButton:ClearAllPoints()
QueueStatusButton:SetPoint("TOPRIGHT", Minimap,"BOTTOMLEFT", 7, 7)
QueueStatusButton:HookScript("OnUpdate",function()
	QueueStatusButton:ClearAllPoints()
	QueueStatusButton:SetPoint("TOPRIGHT", Minimap,"BOTTOMLEFT", 7, 7)
end)



end)
--EditModeSettingDisplayInfoManager.systemSettingDisplayInfo[Enum.EditModeSystem.ActionBar][3]["minValue"] = 3