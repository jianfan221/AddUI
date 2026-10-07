local _,ns = ...

-- 萨满专属：自然守护者(31616)触发30秒倒数,显示在头像位置
local _, cls = UnitClass("player")
if cls == "SHAMAN" then
	ns.event("PLAYER_LOGIN", function()
		if not (AddUIDB and AddUIDB.shamanGuardianCountdown) then return end

		local SpellID = 31616
		local DURATION = 30
		-- 尺寸跟随小队框体高度（GetRaidFrameHeight 读的是滑动条 setting 值，不含渲染偏移）
		local size = EditModeManagerFrame:GetRaidFrameHeight(Enum.EditModeUnitFrameSystemIndices.Party, 36)/1.8

		-- holder 只做锚定容器（本身无外观），图标挂在它下面：未学会天赋时只隐藏图标，不影响雷霆之爪
		-- 父级初始 UIParent，AnchorToSelf 时会随锚定目标切换（团队→anchor，小队→小队框体）
		local holder = CreateFrame("Frame", "AddUIClassShamanCountdown", UIParent)
		holder:SetSize(size, size)

		-- 自然守护者图标（需学会天赋 30884 才显示）
		local frame = CreateFrame("Frame", "AddUIClassShamanGuardianIcon", holder, "CooldownViewerBuffIconItemTemplate")
		frame:SetAllPoints(holder)

		-- 可拖动的锚定框架（UIParent），团队时自然守护者锚到这里，尺寸 40*40
		local anchor = CreateFrame("Frame", "AddUIClassShamanAnchor", UIParent)
		anchor:SetSize(40, 40)
		anchor:SetPoint("LEFT", UIParent, "LEFT", 100, 0)
		ns.AddEdit(anchor, "自然守护者")

		-- 锚定到自己所在的小队框体（1-5 谁是自己就锚到谁）
		local function FindSelfMember()
			for i = 1, 5 do
				local member = _G["CompactPartyFrameMember"..i]
				if member and member.unit == "player" then
					return member
				end
			end
			return CompactPartyFrameMember1 -- 不在小队时回退到框体1
		end

		-- 团队时锚到可拖动框架(40x40)，否则锚到小队框体(原尺寸)，野外无小队时回退到可拖动框架
		local function AnchorToSelf()
			local target, tsize
			if IsInRaid() then
				target, tsize = anchor, 40
			else
				target = FindSelfMember()
				if target then
					tsize = size
				else
					target, tsize = anchor, 40 -- 不在小队时回退到可拖动框架
				end
			end
			holder:SetParent(target) -- 父框体跟随锚定目标
			holder:ClearAllPoints()
			if IsInRaid() then
				-- 团队：居中显示在可拖动框架上
				holder:SetPoint("CENTER", target, "CENTER", 0, 0)
				ns.AddEdit(anchor, "自然守护者")
			else
				-- 小队/野外：显示在目标左侧
				holder:SetPoint("TOPRIGHT", target, "TOPLEFT", -1, 0)
			end
			holder:SetSize(tsize, tsize)
			frame.Cooldown:GetCountdownFontString():SetFont(STANDARD_TEXT_FONT, tsize*0.5, "OUTLINE")
			if frame.SAA then frame.SAA:SetSize(tsize * 1.4, tsize * 1.4) end
		end

		ns.event("GROUP_ROSTER_UPDATE", AnchorToSelf)
		ns.event("PLAYER_ENTERING_WORLD", AnchorToSelf)

		frame.DebuffBorder = nil -- 去掉减益边框
		frame.Icon:SetTexture(136060)--C_Spell.GetSpellTexture(SpellID)
		frame.Cooldown:SetReverse(false)
		frame.Cooldown:SetCountdownAbbrevThreshold(600)
		frame.Cooldown:GetCountdownFontString():SetFont(STANDARD_TEXT_FONT, size*0.5, "OUTLINE")

		-- 触发时闪光
		frame.SAA = CreateFrame("Frame", nil, frame, "ActionButtonSpellAlertTemplate")
		frame.SAA:SetSize(size * 1.4, size * 1.4)
		frame.SAA:SetPoint("CENTER", frame, "CENTER", 0, 0)
		-- 青蓝色
		if frame.SAA.ProcStartFlipbook then frame.SAA.ProcStartFlipbook:SetVertexColor(0, 0.8, 1) end
		if frame.SAA.ProcLoopFlipbook then frame.SAA.ProcLoopFlipbook:SetVertexColor(0, 0.8, 1) end
		if frame.SAA.ProcAltGlow then frame.SAA.ProcAltGlow:SetVertexColor(0, 0.8, 1) end
		frame.SAA:Hide()

		-- 需要学会自然守护者天赋(30884)才显示图标（雷霆之爪图标挂在 holder 上，不受影响）
		local GUARDIAN_ID = 30884
		local function UpdateGuardianVisible()
			local known = C_SpellBook.IsSpellKnown(GUARDIAN_ID)
			frame:SetShown(known)
			if not known then frame.SAA:Hide() end
		end
		-- 切天赋/换专精是同步事件，当帧法术表还没刷新（IsSpellKnown 读到的还是旧值），延迟 0.1 秒再确认
		local function GuardianTalentChanged()
			UpdateGuardianVisible()
			C_Timer.After(0.1, UpdateGuardianVisible)
		end
		ns.event("PLAYER_SPECIALIZATION_CHANGED", GuardianTalentChanged)
		ns.event("TRAIT_CONFIG_UPDATED", GuardianTalentChanged)
		UpdateGuardianVisible()

		ns.event("SPELL_UPDATE_COOLDOWN", function(event, spellID)
			if spellID ~= SpellID then return end
			frame.Cooldown:SetCooldown(GetTime(), DURATION)
			frame.Icon:SetDesaturated(true) -- 触发后褪色
			frame.SAA:Show()
			frame.SAA.ProcStartAnim:Play()
			C_Timer.After(5, function()
				if frame.SAA then
					frame.SAA.ProcStartAnim:Stop()
					frame.SAA:Hide()
				end
			end)
		end)

		-- 冷却结束取消褪色（常驻显示，不隐藏）
		frame.Cooldown:SetScript("OnCooldownDone", function()
			frame.Icon:SetDesaturated(false)
		end)

		-- 雷霆之爪：自然守护者左侧监控 378076 图标（判断学会用 378075，冷却20秒）
		-- 父级用 holder，独立于自然守护者图标的显隐（图标没学会时雷霆之爪照样显示）
		local MONITOR_ID = 378076
		local KNOWN_ID = 378075
		local MONITOR_DURATION = 20
		local monitor
		local function UpdateMonitor()
			local known = (AddUIDB and AddUIDB.shamanThunderClaw) and C_SpellBook.IsSpellKnown(KNOWN_ID)
			if not known then
				if monitor then
					monitor:Hide()
				end
				return
			end
			if not monitor then
				monitor = CreateFrame("Frame", "AddUIClassShamanMonitorIcon", holder, "CooldownViewerBuffIconItemTemplate")
				monitor:SetSize(size , size)
				monitor:SetPoint("RIGHT", holder, "LEFT", 0, 0)
				monitor.DebuffBorder = nil -- 去掉减益边框
				monitor.Icon:SetTexture(C_Spell.GetSpellTexture(MONITOR_ID))
				monitor.Cooldown:SetReverse(false)
				monitor.Cooldown:SetCountdownAbbrevThreshold(600)
				monitor.Cooldown:GetCountdownFontString():SetFont(STANDARD_TEXT_FONT, size*0.4, "OUTLINE")
				-- 冷却时图标褪色，冷却结束恢复（与自然守护者一致）
				monitor.Cooldown:SetScript("OnCooldownDone", function()
					monitor.Icon:SetDesaturated(false)
				end)
				ns.event("SPELL_UPDATE_COOLDOWN", function(event, spellID)
					if spellID ~= MONITOR_ID then return end
					monitor.Cooldown:SetCooldown(GetTime(), MONITOR_DURATION)
					monitor.Icon:SetDesaturated(true) -- 冷却时褪色
				end)
			end
			monitor:Show() -- 已创建过也要显示：取消天赋后再学会要能恢复
		end
		-- 切天赋/换专精是同步事件，当帧法术表还没刷新（IsSpellKnown 读到的还是旧值），延迟 0.1 秒再确认
		local function MonitorTalentChanged()
			UpdateMonitor()
			C_Timer.After(0.1, UpdateMonitor)
		end
		ns.event("PLAYER_SPECIALIZATION_CHANGED", MonitorTalentChanged)
		ns.event("TRAIT_CONFIG_UPDATED", MonitorTalentChanged)
		UpdateMonitor()
	end)
end
