local _,ns = ...

-- 萨满：施放 470057 后 51505 按钮图标换成 1259491，施放 51505 后恢复
local _, cls = UnitClass("player")
if cls == "SHAMAN" then
	ns.event("PLAYER_LOGIN", function()
		if not (ns.DB and ns.DB.shamanIconSwap) then return end

		local BUFF_ID = 1259491      -- 替换成的图标(法术)-净化烈焰
		local BAR_SPELL_ID = 51505   -- 被替换图标的按钮法术-熔岩爆裂
		local TRIGGER_ID = 470057    -- 施放它时触发图标切换-流电炽焰
		local ICON_FILE = C_Spell.GetSpellTexture(BUFF_ID)
		local ACTIONBARS = {"Action","MultiBarBottomLeft","MultiBarBottomRight","MultiBarLeft","MultiBarRight","MultiBar5","MultiBar6","MultiBar7"}

		-- 遍历动作条找绑定指定法术的按钮
		local function FindActionButton(spellID)
			for _, bar in ipairs(ACTIONBARS) do
				for i = 1, 12 do
					local btn = _G[bar.."Button"..i]
					local action = btn and btn.action
					if action then
						local _, id = GetActionInfo(action)
						if id == spellID then return btn end
					end
				end
			end
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

		-- 进游戏：找到按钮并 hook，刷新时按状态保持图标
		ns.event("PLAYER_ENTERING_WORLD", function()
			targetBtn = FindActionButton(BAR_SPELL_ID)
			if not targetBtn then
				print("未在动作条找到法术 "..BAR_SPELL_ID.." "..(C_Spell.GetSpellName(BAR_SPELL_ID) or ""))
				return
			end
			pcall(hooksecurefunc, targetBtn, "Update", function(self)
				if swapped then SetIcon(self, ICON_FILE) end
			end)
		end)

		-- 施放 470057 换图标，施放 51505 恢复
		ns.event("UNIT_SPELLCAST_SUCCEEDED", function(event, unit, _, spellID)
			if unit ~= "player" then return end
			if spellID == TRIGGER_ID then
				swapped = true
				if targetBtn then SetIcon(targetBtn, ICON_FILE) end
			elseif spellID == BAR_SPELL_ID and swapped then
				swapped = false
				if targetBtn then RestoreIcon(targetBtn) end
			end
		end)
	end)
end
