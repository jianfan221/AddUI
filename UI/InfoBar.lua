local addonName,ns = ...
ns.event("PLAYER_LOGIN", function()
if not AddUIDB.dimi then return end
--金币
local gold = ns.AddText(UIParent,13)
gold:SetPoint("BOTTOMRIGHT",UIParent,-2,0)

--耐久
local durable = ns.AddText(UIParent,13)
durable:SetPoint("BOTTOMRIGHT",UIParent,-120,0)

--帧数
local fps = ns.AddText(UIParent,13)
fps:SetPoint("BOTTOMRIGHT",UIParent,-230,0)

-----------金币----------
local SILVER_AMOUNT_TEXTURE = "\124TInterface\\MoneyFrame\\UI-SilverIcon:%d:%d:1:0\124t";
local GOLD_AMOUNT_TEXTURE = "\124TInterface\\MoneyFrame\\UI-GoldIcon:%d:%d:1:0\124t";
local COPPER_AMOUNT_TEXTURE = "\124TInterface\\MoneyFrame\\UI-CopperIcon:%d:%d:1:0\124t";
local GoldIcon = format(GOLD_AMOUNT_TEXTURE)
local SilverIcon = format(SILVER_AMOUNT_TEXTURE)
local CopperIcon = format(COPPER_AMOUNT_TEXTURE)
local Profit	= 0
local Spent		= 0
local OldMoney	= 0

local function formatMoney(money)
	local gold = floor(math.abs(money) / 10000)
	local silver = mod(floor(math.abs(money) / 100), 100)
	local copper = mod(floor(math.abs(money)), 100)
	if gold ~= 0 then
		return format("%s"..GoldIcon.." %s"..SilverIcon.." %s"..CopperIcon, gold, silver, copper)
	elseif silver ~= 0 then
		return format("%s"..SilverIcon.." %s"..CopperIcon, silver, copper)
	else
		return format("%s"..CopperIcon, copper)
	end
end

local function formatTextMoney(money)
	return format("%.0f|cffffd700%s", money * 0.0001, GOLD_AMOUNT_SYMBOL)
end

local function FormatTooltipMoney(money)
	local gold, silver, copper = abs(money / 10000), abs(mod(money / 100, 100)), abs(mod(money, 100))
	local cash = ""
	cash = format("%d"..GoldIcon.." %d"..SilverIcon.." %d"..CopperIcon, gold, silver, copper)		
	return cash
end	

local goldupdate = CreateFrame("Frame")
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
	gold:SetText(formatTextMoney(NewMoney))
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
		GameTooltip:Show()
	end)
	OldMoney = GetMoney()
	gold:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

ns.event("PLAYER_MONEY", OnMoneyEvent)
ns.event("SEND_MAIL_MONEY_CHANGED", OnMoneyEvent)
ns.event("SEND_MAIL_COD_CHANGED", OnMoneyEvent)
ns.event("PLAYER_TRADE_MONEY", OnMoneyEvent)
ns.event("TRADE_MONEY_CHANGED", OnMoneyEvent)
ns.event("PLAYER_ENTERING_WORLD", OnMoneyEvent)

-----------耐久----------
local classc = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[select(2,UnitClass('player'))] 
local Colored = ("|cff%.2x%.2x%.2x"):format(classc.r * 255, classc.g * 255, classc.b * 255)
local gradient = function(perc)
	perc = perc > 1 and 1 or perc < 0 and 0 or perc -- Stay between 0-1
	local seg, relperc = math.modf(perc*2)
	local r1,g1,b1,r2,g2,b2 = select(seg*3+1,1,0,0,1,1,0,0,1,0,0,0,0) -- R -> Y -> G
	local r,g,b = r1+(r2-r1)*relperc,g1+(g2-g1)*relperc,b1+(b2-b1)*relperc
	return format("|cff%02x%02x%02x",r*255,g*255,b*255),r,g,b
end
local durableupdate = CreateFrame("Frame")
local function OnDurabilityEvent(event)
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
	else
		durable:SetText(Colored.."无".."|r%D")
	end

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

local fpscolor
local latencycolor
local fpsupdate
if not fpsupdate then
	fpsupdate  = C_Timer.NewTicker(1, function()
		local _, _, latencyHome, latencyWorld = GetNetStats()
		local lat = math.max(latencyHome, latencyWorld)
		if floor(GetFramerate()) >= 30 then
			fpscolor = "|cff0CD809"
		elseif (floor(GetFramerate()) > 15 and floor(GetFramerate()) < 30) then
			fpscolor = "|cffE8DA0F"
		else
			fpscolor = "|cffD80909"
		end
		fps:SetText(fpscolor..floor(GetFramerate()).."|r".." Fps "..colorlatency(lat).."|r".."Ms")
	end)
end

--fps鼠标提示加上内存
local function formatTotal(Total)
	if Total >= 1024 then
		return format("%.1f".."mb|r" or "%.1fmb", Total / 1024)
	else
		return format("%d".."kb|r" or "%dkb", Total)
	end
end

local function GetAllAddonsMemory()
    local memoryUsage = 0
	UpdateAddOnMemoryUsage()
    for i = 1, C_AddOns.GetNumAddOns() do
        local _,name = C_AddOns.GetAddOnInfo(i)
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
		Mem = GetAddOnMemoryUsage(i)
		MemoryTabel[i] = { select(2, C_AddOns.GetAddOnInfo(i)), Mem, C_AddOns.IsAddOnLoaded(i) }
	end
	table.sort(MemoryTabel, function(a, b)
		if a and b then
			return a[2] > b[2]
		end
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