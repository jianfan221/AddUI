local addonName,ns = ...

-- 创建文本（原 ns.AddText，独立于此文件定义）
local function AddText(frame,size)
	local text = frame:CreateFontString(nil, "ARTWORK")
	text:SetFont(STANDARD_TEXT_FONT, size, 'OUTLINE')
	return text
end

ns.event("PLAYER_LOGIN", function()
if not AddUIDB.dimi then return end
--金币
local gold = CreateFrame("Frame", nil, UIParent)
gold:SetFrameLevel(50)
gold:SetPoint("BOTTOMRIGHT",UIParent,-10,0)
local goldText = gold:CreateFontString(nil, "ARTWORK")
goldText:SetFont(STANDARD_TEXT_FONT, 13, 'OUTLINE')
goldText:SetPoint("RIGHT", gold, "RIGHT", 0, 0)

--耐久
local durable = AddText(UIParent,13)
durable:SetPoint("BOTTOMRIGHT",UIParent,-120,0)

--帧数
local fps = AddText(UIParent,13)
fps:SetPoint("BOTTOMRIGHT",UIParent,-240,0)

-----------金币----------
local GoldIcon = "\124TInterface\\MoneyFrame\\UI-GoldIcon:0:0:1:0\124t"
local Profit	= 0
local Spent		= 0
local OldMoney	= 0

local function formatMoney(money)
	-- 只保留金币，银铜直接舍掉（不四舍五入）
	return BreakUpLargeNumbers(floor(math.abs(money) / 10000))..GoldIcon
end

local function formatTextMoney(money)
	-- 只保留金币，银铜直接舍掉（不四舍五入）
	return floor(money / 10000).."|cffffd700"..GOLD_AMOUNT_SYMBOL
end

-----------金币记录（每个战网一个组，逐角色记录）----------
-- 保存结构：AddUIDB.GoldTracker = {
--   ["战网ID"] = {
--     ["角色名-服务器"] = { n = 角色名, g = 铜币, c = 职业 },
--     warband = 战团银行铜币,
--   },
-- }
local GOLD_MIN = 100 * 10000 -- 显示时过滤低于 100金 的角色

-- 角色名按职业配色
local function ClassNameText(name, class)
	local color = class and C_ClassColor.GetClassColor(class)
	if color then return color:WrapTextInColorCode(name) end
	return name
end

local function GetGoldTrack()
	local db = AddUIDB.GoldTracker
	if type(db) ~= "table" then db = {} AddUIDB.GoldTracker = db end
	return db
end

-- 当前战网 ID（如 Name#1234），未连接时用 unknown 兜底
local function GetAccountTag()
	return select(2, BNGetInfo()) or "unknown"
end

-- 当前战网对应的角色组
local function GetAccountGroup()
	local db = GetGoldTrack()
	local tag = GetAccountTag()
	if type(db[tag]) ~= "table" then db[tag] = {} end
	return db[tag]
end

local function GetCharKey()
	return format("%s-%s", UnitFullName("player"), GetNormalizedRealmName() or GetRealmName())
end

-- 记录当前角色的金币
local function SaveCharMoney()
	local name, class = UnitName("player"), select(2, UnitClass("player"))
	if not name then return end
	GetAccountGroup()[GetCharKey()] = { n = name, g = GetMoney(), c = class }
end

-- 战团银行金币：实时读取，读不到时用 DB 缓存值（存在当前战网组内）
local function GetWarbandMoney()
	local group = GetAccountGroup()
	local ok, money = pcall(C_Bank.FetchDepositedMoney, Enum.BankType.Account)
	if ok and type(money) == "number" and not ns.MM(money) then
		local canRead = money > 0
		if not canRead then
			local ok2, canView = pcall(C_Bank.CanViewBank, Enum.BankType.Account)
			canRead = ok2 and canView
		end
		if canRead then
			group.warband = money
			return money
		end
	end
	local cached = group.warband
	if type(cached) == "number" then return cached end
	return 0
end

-- 当前战网下各角色的金币（当前角色固定排第一；其余过滤 < 100金，按金币从多到少）
-- 组内的 warband 是数字不是表，会被下面的 type 判断自然跳过
local function GetChars()
	local list = {}
	local curKey = GetCharKey()
	for key, entry in pairs(GetAccountGroup()) do
		local g = type(entry) == "table" and entry.g
		if type(g) == "number" and (key == curKey or g >= GOLD_MIN) then
			list[#list + 1] = { n = entry.n or key, g = g, c = entry.c, cur = key == curKey }
		end
	end
	table.sort(list, function(a, b)
		if a.cur ~= b.cur then return a.cur == true end
		return a.g > b.g
	end)
	return list
end

SaveCharMoney()
ns.event("PLAYER_MONEY", SaveCharMoney)
ns.event("PLAYER_ENTERING_WORLD", SaveCharMoney)
ns.event("ACCOUNT_MONEY", function() GetWarbandMoney() end)

local function OnMoneyEvent(event)
	if event == "PLAYER_ENTERING_WORLD" then
		OldMoney = GetMoney()
	end
	local NewMoney = GetMoney()
	local Change = NewMoney-OldMoney -- Positive if we gain money
	
	if OldMoney > NewMoney then		-- Lost Money
		Spent = Spent - Change
	else							-- Gained Moeny
		Profit = Profit + Change
	end
	goldText:SetText(formatTextMoney(NewMoney))
	local w = goldText:GetStringWidth()
	if w and w > 0 then
		gold:SetWidth(w + 4)
		gold:SetHeight(goldText:GetStringHeight() + 2)
	end
	-- 脚本绑在Frame上（避免了FontString鼠标事件不可靠的问题）
	gold:SetScript("OnEnter", function()
		GameTooltip:SetOwner(gold, "ANCHOR_TOP", 0, 6);
		GameTooltip:ClearAllPoints()
		GameTooltip:SetPoint("BOTTOM", gold, "TOP", 0, 1)
		GameTooltip:ClearLines()
		GameTooltip:AddLine(CURRENCY,0,.6,1)
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("本次登陆: ",.6,.8,1)
		GameTooltip:AddDoubleLine("获得:", formatMoney(Profit), 1, 1, 1, 1, 1, 1)
		GameTooltip:AddDoubleLine("花费:", formatMoney(Spent), 1, 1, 1, 1, 1, 1)
		if Profit < Spent then
			GameTooltip:AddDoubleLine("亏损:", formatMoney(Profit-Spent), 1, 0, 0, 1, 1, 1)
		elseif (Profit-Spent)>0 then
			GameTooltip:AddDoubleLine("盈利:", formatMoney(Profit-Spent), 0, 1, 0, 1, 1, 1)
		end				
		local chars = GetChars()
		local warband = GetWarbandMoney()
		local total = warband
		GameTooltip:AddLine(" ")
		for _, c in ipairs(chars) do
			GameTooltip:AddDoubleLine(ClassNameText(c.n, c.c), formatMoney(c.g), 1, 1, 1, 1, 1, 1)
			total = total + c.g
		end
		GameTooltip:AddDoubleLine("战团银行:", formatMoney(warband), 1, 1, 1, 1, 1, 1)
		GameTooltip:AddDoubleLine("总计:", formatMoney(total), 0, .8, 0, 0, 1, 0)
		GameTooltip:Show()
	end)
	gold:SetScript("OnLeave", function() GameTooltip:Hide() end)
	OldMoney = GetMoney()
end

ns.event("PLAYER_MONEY", OnMoneyEvent)
ns.event("SEND_MAIL_MONEY_CHANGED", OnMoneyEvent)
ns.event("SEND_MAIL_COD_CHANGED", OnMoneyEvent)
ns.event("PLAYER_TRADE_MONEY", OnMoneyEvent)
ns.event("TRADE_MONEY_CHANGED", OnMoneyEvent)
ns.event("PLAYER_ENTERING_WORLD", OnMoneyEvent)

-----------耐久----------
local gradient = function(perc)
	perc = perc > 1 and 1 or perc < 0 and 0 or perc -- Stay between 0-1
	local seg, relperc = math.modf(perc*2)
	local r1,g1,b1,r2,g2,b2 = select(seg*3+1,1,0,0,1,1,0,0,1,0,0,0,0) -- R -> Y -> G
	local r,g,b = r1+(r2-r1)*relperc,g1+(g2-g1)*relperc,b1+(b2-b1)*relperc
	return format("|cff%02x%02x%02x",r*255,g*255,b*255),r,g,b
end
-- 耐久槽位（提升为外层变量，供事件处理与鼠标提示共用）
local localSlots = {
	[1] = {1, "头部", 1000},
	[2] = {3, "肩部", 1000},
	[3] = {5, "胸部", 1000},
	[4] = {6, "腰部", 1000},
	[5] = {9, "手腕", 1000},
	[6] = {10, "手", 1000},
	[7] = {7, "腿部", 1000},
	[8] = {8, "脚", 1000},
	[9] = {16, "主手", 1000},
	[10] = {17, "副手", 1000},
	[11] = {18, "远程", 1000}
}
-- 鼠标提示（初始化时设置一次）
durable:SetScript("OnEnter", function()
	local total, equipped = GetAverageItemLevel()
	GameTooltip:SetOwner(durable, "ANCHOR_TOP", 0, 6);
	GameTooltip:ClearAllPoints()
	GameTooltip:SetPoint("BOTTOM", durable, "TOP", 0, 1)
	GameTooltip:ClearLines()
	GameTooltip:AddDoubleLine(DURABILITY,format("%s: %d/%d", STAT_AVERAGE_ITEM_LEVEL, equipped, total),0,.6,1,0,.6,1)
	GameTooltip:AddLine(" ")
	for i = 1, 11 do
		if localSlots[i][3] ~= 1000 then
			local green = localSlots[i][3]*2
			local red = 1 - green
			GameTooltip:AddDoubleLine(localSlots[i][2], floor(localSlots[i][3]*100).."%", 1, 1, 1, red + 1, green, 0)
		end
	end
	GameTooltip:AddDoubleLine(" ","--------------",1,1,1,0.5,0.5,0.5)
	GameTooltip:Show()
end)
durable:SetScript("OnLeave", function() GameTooltip:Hide() end)

local function OnDurabilityEvent(event)
	local Total = 0
	local current, max
	for i = 1, 11 do
		if GetInventoryItemLink("player", localSlots[i][1]) ~= nil then
			current, max = GetInventoryItemDurability(localSlots[i][1])
			if current then 
				localSlots[i][3] = current/max
				Total = Total + 1
			end
		end
	end
	table.sort(localSlots, function(a, b) return a[3] < b[3] end)
	
	if Total > 0 then
		durable:SetText(format(gsub("[color]%d|r%%".."耐久","%[color%]",(gradient(floor(localSlots[1][3]*100)/100))), floor(localSlots[1][3]*100)))
	end
end

ns.event("UPDATE_INVENTORY_DURABILITY", OnDurabilityEvent)
ns.event("MERCHANT_SHOW", OnDurabilityEvent)
ns.event("PLAYER_ENTERING_WORLD", OnDurabilityEvent)

-----帧数
local function colorlatency(latency)
	if latency < 300 then
		return "|cff0CD809"..latency
	elseif (latency >= 300 and latency < 500) then
		return "|cffE8DA0F"..latency
	else
		return "|cffD80909"..latency
	end
end

C_Timer.NewTicker(1, function()
	local _, _, latencyHome, latencyWorld = GetNetStats()
	local lat = math.max(latencyHome, latencyWorld)
	local fpscolor
	if floor(GetFramerate()) >= 30 then
		fpscolor = "|cff0CD809"
	elseif (floor(GetFramerate()) > 15 and floor(GetFramerate()) < 30) then
		fpscolor = "|cffE8DA0F"
	else
		fpscolor = "|cffD80909"
	end
	fps:SetText(fpscolor..floor(GetFramerate()).."|r".." Fps "..colorlatency(lat).."|r".."Ms")
end)

--fps鼠标提示加上内存
local function formatTotal(Total)
	if Total >= 1024 then
		return format("%.1fmb", Total / 1024)
	else
		return format("%dkb", Total)
	end
end

local function GetAllAddonsMemory()
    local memoryUsage = 0
	UpdateAddOnMemoryUsage()
    for i = 1, C_AddOns.GetNumAddOns() do
        local usage = GetAddOnMemoryUsage(i)
		memoryUsage = memoryUsage + usage
    end
    return memoryUsage
end
local MemoryTabel = {}
fps:SetScript("OnLeave", function() GameTooltip:Hide() end)
fps:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(fps, "ANCHOR_TOP", 0, 6);
	GameTooltip:AddDoubleLine("总内存使用:",formatTotal(GetAllAddonsMemory()),.6,.8,1,1,1,1)
	GameTooltip:AddLine(" ")
	for i = 1, C_AddOns.GetNumAddOns() do
		local Mem = GetAddOnMemoryUsage(i)
		MemoryTabel[i] = { select(2, C_AddOns.GetAddOnInfo(i)), Mem, C_AddOns.IsAddOnLoaded(i) }
	end
	table.sort(MemoryTabel, function(a, b)
		if a and b then
			return a[2] > b[2]
		end
		return false
	end)
	for i = 1, #MemoryTabel  do
		if MemoryTabel[i][3] then
			local color = MemoryTabel[i][2] <= 102.4 and {0,1} -- 0 - 100
			or MemoryTabel[i][2] <= 512 and {0.75,1} -- 100 - 512
			or MemoryTabel[i][2] <= 1024 and {1,1} -- 512 - 1mb
			or MemoryTabel[i][2] <= 2560 and {1,0.75} -- 1mb - 2.5mb
			or MemoryTabel[i][2] <= 5120 and {1,0.5} -- 2.5mb - 5mb
			or {1,0.1} -- 5mb +
			GameTooltip:AddDoubleLine(MemoryTabel[i][1], formatTotal(MemoryTabel[i][2]), 1, 1, 1, color[1], color[2], 0)						
		end
    end
	GameTooltip:Show()
end)
fps:SetScript("OnMouseDown", function(self, btn)
	if btn == "LeftButton" then
		local before = collectgarbage("count")
		collectgarbage("collect")
		print(format("|cff66C6FF%s:|r %s","释放內存",formatTotal(before - collectgarbage("count"))))
		self:GetScript("OnEnter")(self)
	end
end)

end)