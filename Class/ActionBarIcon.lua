local _,ns = ...

-- 萨满：施放 470057 后 51505 按钮图标换成 1259491，施放 51505 后恢复
local _, cls = UnitClass("player")
if cls == "SHAMAN" then
	ns.event("PLAYER_LOGIN", function()
		if not (AddUIDB and AddUIDB.shamanIconSwap) then return end

		local BUFF_ID = 1259491      -- 替换成的图标(法术)-净化烈焰
		local BAR_SPELL_ID = 51505   -- 被替换图标的按钮法术-熔岩爆裂
		local TRIGGER_ID = 470057    -- 施放它时触发图标切换-流电炽焰
		local ICON_FILE = C_Spell.GetSpellTexture(BUFF_ID)
		-- 使用暴雪工具查找绑定指定法术的按钮
		local function FindActionButton(spellID)
			local actionButtonUtil = _G.ActionButtonUtil
			return actionButtonUtil and actionButtonUtil.GetActionButtonBySpellID(spellID)
		end

		local targetBtn
		local swapped = false

		-- 设按钮图标为指定纹理（去黑边）
		local function SetIcon(btn, texture)
			local icon = btn and (btn.Icon or btn.icon)
			if icon then
				icon:SetTexture(texture)
				icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
			end
		end

		-- 恢复按钮原本图标
		local function RestoreIcon(btn)
			local icon = btn and (btn.Icon or btn.icon)
			if icon and btn.action then
				icon:SetTexture(C_ActionBar.GetActionTexture(btn.action))
				icon:SetTexCoord(0, 1, 0, 1)
			end
		end

		local hookedButtons = {}
		local refreshPending = false

		local function RefreshTargetButton()
			local button = FindActionButton(BAR_SPELL_ID)
			if targetBtn and targetBtn ~= button and swapped then RestoreIcon(targetBtn) end
			targetBtn = button
			if not button then return end

			if not hookedButtons[button] then
				local success = pcall(hooksecurefunc, button, "Update", function(self)
					local _, id = GetActionInfo(self.action)
					if swapped and id == BAR_SPELL_ID then SetIcon(self, ICON_FILE) end
				end)
				hookedButtons[button] = success
			end
			if swapped then SetIcon(button, ICON_FILE) end
		end

		local function ScheduleRefresh()
			if refreshPending then return end
			refreshPending = true
			C_Timer.After(0.1, function()
				refreshPending = false
				RefreshTargetButton()
			end)
		end

		-- 动作条会在进入世界时继续初始化，下一帧再定位；动作槽变化时也重新定位
		ns.event("PLAYER_ENTERING_WORLD", ScheduleRefresh)
		ns.event("ACTIONBAR_SLOT_CHANGED", ScheduleRefresh)

		-- 施放 470057 换图标，施放 51505 恢复
		ns.event("UNIT_SPELLCAST_SUCCEEDED", function(event, unit, _, spellID)
			if unit ~= "player" then return end
			if spellID == TRIGGER_ID then
				swapped = true
				if targetBtn then SetIcon(targetBtn, ICON_FILE) end
				ScheduleRefresh()
			elseif spellID == BAR_SPELL_ID and swapped then
				swapped = false
				if targetBtn then RestoreIcon(targetBtn) end
			end
		end)
	end)
end
