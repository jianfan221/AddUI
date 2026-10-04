local _, ns = ...

-- ══════════════════════════════════════════════════════════════
-- 奇袭盗贼（奇袭天赋）专用：附近敌方姓名板的 双 DOT 监控网格
-- 进游戏时把 8 列 x 5 行 共 40 个格子全部建好放进池里，用到就拿一个
-- 总开关进游戏读一次；「只监控仇恨列表」「格子大小」「最小剩余时间倒数」设置里改可实时生效
-- 只有奇袭天赋才启用（切天赋即时生效）；默认只认「已上仇恨列表」的姓名板
-- 姓名板按出现顺序从左往右填，满 8 个换行（紧凑排列，不留空洞）
-- 格子：白底；锁喉(703) + 割裂(1943) 同时存在 → 变红（容器嵌套实现 AND）
-- 每个格子正中再挂一个容器，显示两个 DOT 里最早到期那个的剩余时间（只留冷却倒数，无转圈；可开关）
-- ══════════════════════════════════════════════════════════════

ns.event("PLAYER_LOGIN", function()
	-- 非盗贼不建
	local _, class = UnitClass("player")
	if class ~= "ROGUE" then return end

	local COLS, ROWS = 8, 5
	local GAP = 2
	local TOTAL = COLS * ROWS

	local ASSASSINATION = 259 -- 奇袭专精 ID（狂徒 260 / 敏锐 261）

	-- 光环容器模板是按需加载的，先确保它在
	if not DoesTemplateExist("CustomAuraContainerTemplate") then
		local load = C_AddOns and C_AddOns.LoadAddOn or LoadAddOn
		if type(load) == "function" then pcall(load, "Blizzard_AuraContainer") end
	end

	local function Clamp(v, lo, hi)
		if v < lo then return lo end
		if v > hi then return hi end
		return v
	end

	-- 当前是不是奇袭天赋
	local function IsAssassination()
		local specIndex = C_SpecializationInfo.GetSpecialization()
		if not specIndex or specIndex == 0 then return false end
		return C_SpecializationInfo.GetSpecializationInfo(specIndex) == ASSASSINATION
	end

	-- ═══════ 读设置（总开关进游戏读一次；其余可实时改） ═══════

	local db = ns.DB or AddUIDB
	local ENABLED = not (db and db.rogueDotGrid == false)
	local THREAT_ONLY = not (db and db.rogueDotGridThreatOnly == false)
	local TIMER_ON = not (db and db.rogueDotGridTimer == false)
	local CELL = Clamp(tonumber(db and db.rogueDotGridCell) or 15, 8, 30)

	-- 格子里的倒数文本：字号随格子缩放
	local function TextH() return math.max(9, math.floor(CELL * 0.9)) end

	local function IsOn()
		return ENABLED and IsAssassination()
	end

	-- ═══════ 外框 ═══════

	local grid = CreateFrame("Frame", "ADURogueDotGrid", UIParent)
	grid:SetSize(COLS * CELL + (COLS - 1) * GAP, ROWS * CELL + (ROWS - 1) * GAP)
	grid:SetPoint("CENTER", UIParent, "CENTER", 0, -350)
	ns.AddEdit(grid, "奇袭DOT") -- 编辑模式拖动位置

	local pool = {}     -- 空闲格子
	local inUse = {}    -- unit -> 格子
	local allCells = {} -- 全部格子（改尺寸时要遍历）
	local order = {}    -- 有序的显示列表（决定格子摆在哪）

	-- 给一个格子建容器
	local function BuildContainers(cell)
		-- 外层容器：锁喉（自身不画东西，只当"有没有锁喉"的开关）
		local outer = CreateFrame("AuraContainer", nil, cell, "CustomAuraContainerTemplate")
		outer:SetAllPoints(cell)
		outer:AddAuraSlot("garrote", "HARMFUL|PLAYER", {
			candidateFilters = { includeSpellIDs = {[703] = true} },
			initializeFrame = function(btn)
				btn:SetSize(CELL, CELL)
				btn:EnableMouse(false)
				-- slot 的锚点必须在这里设：initializeFrame 是非污染上下文，
				-- 在外面（tainted）对 AuraButton 调 SetPoint 会被拦
				btn:SetPoint("TOPLEFT", cell, "TOPLEFT", 0, 0)

				-- 内层容器：割裂。父级 = 外层按钮，外层按钮隐藏时它不渲染 → 两个都在才红
				local inner = CreateFrame("AuraContainer", nil, btn, "CustomAuraContainerTemplate")
				inner:SetAllPoints(cell)
				inner:SetEnabled(false) -- 默认就是 true，先禁用再启用才能触发一次事件注册
				local innerSlot = inner:AddAuraSlot("rupture", "HARMFUL|PLAYER", {
					candidateFilters = { includeSpellIDs = {[1943] = true} },
					initializeFrame = function(btn2)
						btn2:EnableMouse(false)
						local tex = btn2:CreateTexture(nil, "OVERLAY")
						tex:SetAllPoints(cell) -- 锚到格子：显隐由按钮决定，位置不依赖按钮尺寸
						tex:SetColorTexture(1, 0, 0, 1) -- 红
					end,
				})
				innerSlot:SetPoint("TOPLEFT", cell, "TOPLEFT", 0, 0)
				inner:SetEnabled(true)
				cell.inner = inner
			end,
		})
		cell.outer = outer

		-- 格子里的倒数容器：只显示「最早到期」那个 dot 的剩余时间
		-- maxFrameCount = 1 + 到期时间升序 → 留下的那个就是两个 dot 里剩余时间最小的
		local timer = CreateFrame("AuraContainer", nil, cell, "CustomAuraContainerTemplate")
		timer:SetAllPoints(cell)
		timer:SetFrameLevel(cell:GetFrameLevel() + 10) -- 倒数要盖在红底之上（红纹理比格子高好几层）
		timer:AddAuraGroup("minDot", "HARMFUL|PLAYER", {
			maxFrameCount = 1,
			sortMethod = AuraContainerSortMethod.ExpirationOnly,
			candidateFilters = { includeSpellIDs = {[703] = true, [1943] = true} },
			initializeFrame = function(btn)
				btn:EnableMouse(false)
				-- 只留倒数：冷却框架去掉转圈 / 暗色 / 边缘 / 闪光，数字保留
				local cd = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
				cd:ClearAllPoints() -- 模板自带 setAllPoints，先清掉
				cd:SetAllPoints(cell) -- 盖满整个格子，倒数自动居中
				cd:SetDrawSwipe(false)
				cd:SetDrawEdge(false)
				cd:SetDrawBling(false)
				cd:SetHideCountdownNumbers(false)
				local num = cd:GetCountdownFontString()
				num:SetFont(STANDARD_TEXT_FONT, TextH())
				num:SetTextColor(0, 1, 0) -- 格子是白底，用黑字
				btn:SetDurationCooldown(cd)
				cell.timerNum = num
			end,
		})
		cell.timer = timer
	end

	-- 进游戏就把 40 个格子建好放进池里
	-- （此刻 grid 可见，容器才注册得上；建完先隐藏，用到再显示）
	for _ = 1, TOTAL do
		local cell = CreateFrame("Frame", nil, grid)
		cell:SetSize(CELL, CELL)

		local white = cell:CreateTexture(nil, "BACKGROUND")
		white:SetAllPoints(cell)
		white:SetColorTexture(1, 1, 1, 1) -- 白底

		BuildContainers(cell)
		cell:Hide()

		allCells[#allCells + 1] = cell
		pool[#pool + 1] = cell
	end

	-- 倒数开关：开启才把倒数容器挂到单位上（关掉时禁用容器，什么都不渲染）
	-- 必须在格子可见时 SetUnit，容器才注册得上
	local function UpdateTimer(cell)
		if TIMER_ON and cell.unit then
			cell.timer:SetUnit(cell.unit)
			cell.timer:SetEnabled(true)
		else
			cell.timer:SetEnabled(false)
		end
	end

	-- 取一个格子给姓名板
	local function Acquire(unit)
		local cell = table.remove(pool)
		if not cell then return end

		cell.unit = unit
		inUse[unit] = cell

		cell:Show()
		cell.outer:SetUnit(unit)
		cell.outer:SetEnabled(true)
		if cell.inner then cell.inner:SetUnit(unit) end
		UpdateTimer(cell)
	end

	-- 归还格子
	local function Release(cell)
		if cell.unit then
			inUse[cell.unit] = nil
			cell.unit = nil
		end
		cell:Hide()
		cell.outer:SetEnabled(false)
		cell.timer:SetEnabled(false)
		pool[#pool + 1] = cell
	end

	-- 按显示顺序摆放格子（满 8 个换行）；序号没变的格子不动
	local function Layout()
		for index, unit in ipairs(order) do
			local cell = inUse[unit]
			if cell and cell.index ~= index then
				cell.index = index
				local col = (index - 1) % COLS
				local row = math.floor((index - 1) / COLS)
				cell:ClearAllPoints()
				cell:SetPoint("TOPLEFT", grid, "TOPLEFT", col * (CELL + GAP), -row * (CELL + GAP))
			end
		end
	end

	-- 这个单位该不该显示：默认只认已上仇恨列表（被拉到的）的姓名板
	local function ShouldShow(unit)
		if not THREAT_ONLY then return true end
		local threat = UnitThreatSituation("player", unit) -- 不在仇恨列表 → nil
		if ns.MM(threat) then return false end              -- 秘密值跳过
		return (threat or -1) >= 0
	end

	-- 重新对齐显示列表：保持已有顺序，掉出条件的移走、新出现的追加在后面
	local function Refresh()
		if not IsOn() then return end

		local valid, seen = {}, {}
		for _, nameplate in ipairs(C_NamePlate.GetNamePlates()) do
			local uf = nameplate.UnitFrame --[[@as any]]
			local unit = uf and uf.displayedUnit --[[@as UnitToken]]
			if unit and not seen[unit] and ShouldShow(unit) then
				seen[unit] = true
				valid[#valid + 1] = unit
			end
		end

		-- 移除已消失 / 掉出仇恨列表的
		for i = #order, 1, -1 do
			local unit = order[i]
			if not seen[unit] then
				table.remove(order, i)
				local cell = inUse[unit]
				if cell then Release(cell) end
			end
		end

		-- 追加新出现的（超出格子数就排队不显示）
		for _, unit in ipairs(valid) do
			if #order >= TOTAL then break end
			if not inUse[unit] then
				order[#order + 1] = unit
				Acquire(unit)
			end
		end

		Layout()
	end

	-- 姓名板 / 仇恨变动很密集，攒到下一帧只算一次
	local pending = false
	local function QueueRefresh()
		if pending then return end
		pending = true
		C_Timer.After(0, function()
			pending = false
			Refresh()
		end)
	end

	-- 开关应用：登录、切天赋、进入世界时调用
	local function Apply()
		if not IsOn() then
			for i = #order, 1, -1 do
				local unit = table.remove(order, i)
				local cell = inUse[unit]
				if cell then Release(cell) end
			end
			grid:Hide()
			return
		end

		grid:Show()
		Refresh()
	end

	-- 设置界面实时生效：只监控仇恨列表 / 最小剩余时间倒数 / 格子大小
	ns.RogueDotGridRefresh = function()
		local cfg = ns.DB or AddUIDB
		THREAT_ONLY = not (cfg and cfg.rogueDotGridThreatOnly == false)

		local timerOn = not (cfg and cfg.rogueDotGridTimer == false)
		if timerOn ~= TIMER_ON then
			TIMER_ON = timerOn
			for _, cell in ipairs(allCells) do
				if cell.unit then UpdateTimer(cell) end -- 在用的格子立即开/关倒数
			end
		end

		local size = Clamp(tonumber(cfg and cfg.rogueDotGridCell) or 15, 8, 30)
		if size ~= CELL then
			CELL = size
			grid:SetSize(COLS * CELL + (COLS - 1) * GAP, ROWS * CELL + (ROWS - 1) * GAP)
			for _, cell in ipairs(allCells) do
				cell:SetSize(CELL, CELL)
				cell.index = nil -- 尺寸变了，位置全部重算
				if cell.timerNum then
					cell.timerNum:SetFont(STANDARD_TEXT_FONT, TextH())
				end
			end
		end

		Refresh() -- 重扫一遍：范围/尺寸变了都要重新对齐
	end

	ns.event("PLAYER_SPECIALIZATION_CHANGED", Apply)        -- 切天赋
	ns.event("ACTIVE_PLAYER_SPECIALIZATION_CHANGED", Apply) -- 切天赋（激活专精变更）
	ns.event("NAME_PLATE_UNIT_ADDED", QueueRefresh)
	ns.event("NAME_PLATE_UNIT_REMOVED", QueueRefresh)
	ns.event("UNIT_THREAT_LIST_UPDATE", QueueRefresh) -- 上/掉仇恨列表
	ns.event("PLAYER_ENTERING_WORLD", Apply)

	Apply()
end)
