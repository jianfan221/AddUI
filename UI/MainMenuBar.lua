local _,ns = ...
ns.event("PLAYER_ENTERING_WORLD", function()
if C_AddOns.IsAddOnLoaded("Dominos") then return end
if C_AddOns.IsAddOnLoaded("Bartender4") then return end
if C_AddOns.IsAddOnLoaded("ElvUI") then	return end
if C_AddOns.IsAddOnLoaded("BigFoot") then return end
if C_AddOns.IsAddOnLoaded("NDui") then return end

if AddUIDB.mmb ==  false  then return end

--动作条按键范围着色
local function UpdateRangeIcon(self, checksRange, inRange)
	local icon = self.icon or self.Icon or _G[self:GetName().."Icon"]
	if not icon then return end

	local isOutOfRange = checksRange and not inRange
	if isOutOfRange then
		icon:SetVertexColor(0.5, 0.1, 0.1)
	elseif self.action then
		local isUsable, notEnoughMana = C_ActionBar.IsUsableAction(self.action)
		if isUsable ~= true or notEnoughMana == true then
			icon:SetVertexColor(0.4, 0.4, 0.4)
		else
			icon:SetVertexColor(1, 1, 1)
		end
	else
		icon:SetVertexColor(1, 1, 1)
	end
end
ns.hook("ActionButton_UpdateRangeIndicator", UpdateRangeIcon)
ActionBarButtonEventsFrame:ForEachFrame(function(button)
	if not button.UpdateUsable then return end
	ns.hook(button, "UpdateUsable", function(self)
		if not self.action then return end
		local inRange = C_ActionBar.IsActionInRange(self.action)
		if inRange ~= nil then UpdateRangeIcon(self, true, inRange) end
	end)
end)


--宏颜色--
ActionBarButtonEventsFrame:ForEachFrame(function(button)
	local nameText = _G[button:GetName().."Name"]
	if nameText then nameText:SetVertexColor(0, 255, 255) end
end)

--经验条
StatusTrackingBarManager:SetScale(.73)

--队伍查找器
QueueStatusButton:ClearAllPoints()
QueueStatusButton:SetPoint("TOPRIGHT", Minimap,"BOTTOMLEFT", -5, 10)
-- 暴雪的 UpdatePosition 在微菜单布局变化/编辑模式退出时触发，hook 它来保持位置
ns.hook(QueueStatusButton, "UpdatePosition", function()
	QueueStatusButton:ClearAllPoints()
	QueueStatusButton:SetPoint("TOPRIGHT", Minimap,"BOTTOMLEFT", -5, 10)
end)



end)
--EditModeSettingDisplayInfoManager.systemSettingDisplayInfo[Enum.EditModeSystem.ActionBar][3]["minValue"] = 3