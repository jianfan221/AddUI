local _,ns = ...
ns.event("CHALLENGE_MODE_START", function()
	if not AddUIDB.MDRedamage then return end
	if C_CVar.GetCVar("damageMeterEnabled") == "0" then return end
	C_DamageMeter.ResetAllCombatSessions();
	print("|cffb044a2ADDUI:|r " .."已重置伤害统计")
end)
ns.event("PLAYER_ENTERING_WORLD", function()
	if DamageMeter  then
		local function DamageWindowsSetting(count)
			if not count then return end
			local self = _G["DamageMeterSessionWindow"..count]
			--窗口美化
			if AddUIDB.setdama then
				local alpha = 0.6
				
				if not self then return end
				----
				self.DamageMeterTypeDropdown:SetAlpha(alpha)
				self.SessionDropdown:SetAlpha(alpha)
				self.SettingsDropdown:SetAlpha(alpha)
				self.Header:SetAlpha(alpha)
				self.Header:SetVertexColor(0, 0, 0)
			end
			--自动贴附对齐
			if not AddUIDB.poidama or count < 2 then return end
			local prior = _G["DamageMeterSessionWindow"..count-1] or _G["DamageMeterSessionWindow"..count-2]
			self:ClearAllPoints()
			self:SetPoint("BOTTOMLEFT", prior,"TOPLEFT",0,-3)
			self:SetPoint("BOTTOMRIGHT", prior,"TOPRIGHT",0,-3)
			self:SetUserPlaced(true)
			self:GetResizeButton():HookScript("OnMouseUp", function(button, mouseButtonName, _down)
				if not self:CanMoveOrResize() then
					return;
				end
				if mouseButtonName == "LeftButton" then
					self:ClearAllPoints()
					self:SetPoint("BOTTOMLEFT", prior,"TOPLEFT",0,-3)
					self:SetPoint("BOTTOMRIGHT", prior,"TOPRIGHT",0,-3)
				end
			end);
		end
		--新建窗口
		hooksecurefunc(DamageMeter,'SetupSessionWindow',function(self,data,count) 
			DamageWindowsSetting(count)
		end)
		--编辑模式
		hooksecurefunc(DamageMeter, "SetIsEditing", function(self)
			C_Timer.After(0,function()
				for i = 1,3 do--self:GetMaxSessionWindowCount()
					DamageWindowsSetting(i)
				end
			end)
		end)
		--计量条美化
		local function DamageWindowsStatusBar(self)
			if self.MyStyle then return end
			if not AddUIDB.setdama then return end
			self:GetStatusBar():SetStatusBarTexture("Interface\\AddOns\\AddUI\\UI\\Textures\\Raid-Bar-Hp-Fill")
			self:GetIcon():SetSize(self:GetBarHeight(),self:GetBarHeight())
			self:GetBackgroundEdge():SetAtlas(nil)
			self:GetBackground():SetAtlas(nil)
			self.MyStyle = true
		end
		--初始化计量条
		hooksecurefunc(DamageMeterEntryMixin, "Init", function(self)
			C_Timer.After(0,function()
				DamageWindowsStatusBar(self)
			end)
		end)
		--加载一次
		DamageMeter:ForEachSessionWindow(function(sessionWindow)
			if not sessionWindow then
				return;
			end
			local count = sessionWindow.sessionWindowIndex
			DamageWindowsSetting(count)

			sessionWindow:ForEachEntryFrame(function(child)
				DamageWindowsStatusBar(child)
			end)
		end)
	end
	
end)