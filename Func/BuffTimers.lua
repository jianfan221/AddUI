local _,ns = ...

SetCVar("buffDurations", 1)	--显示buff持续时间,有些插件会给关了

ns.tips("小于10分钟的BUFF和DEBUFF显示秒")
local function Bufftime(seconds)
if type(seconds) ~="number" then return end 
if seconds > 86400 then 
	return format("%dd", seconds/86400)
elseif seconds > 6000 then 
	return format("%d h", seconds/3600+1)
elseif seconds > 3600 then 
	return format("%d m", seconds/60)
elseif seconds > 600 then 
	return format("%d m", seconds/60)
elseif seconds > 60 then 
	return format("%d:%.2d", seconds/60, seconds%60)
else 
	return format("%d s", seconds)
end
end

local function MyBuffTime(self,timeLeft)
	if timeLeft > 600 or timeLeft < 60 then return end
	self.Duration:SetFormattedText(format("%d:%.2d", timeLeft/60, timeLeft%60))
end

local function BuffTimeNA(aura)
	if aura.buttonInfo.expirationTime ~= 0 then return end
	aura.duration:SetText("|cff00ff00N/A|r")
	aura.duration:Show()
end
local frames = {buffFrame, debuffFrame}
for i = 1, #frames do
	for _, button in ipairs(frames[i].auraFrames) do
		if button then
			hooksecurefunc(button, "OnUpdate", MyBuffTime)
		end
		if button then
			hooksecurefunc(button, "UpdateDuration", MyBuffTime)
		end
	end
end

ns.tips("装备面板显示当前等级和最高等级")
ns.hook('PaperDollFrame_SetItemLevel', function(self, unit) 
   if (unit ~= 'player') then return end 

   local total, equip = GetAverageItemLevel() 
   if (total > 0) then total = string.format('%.1f', total) end 
   if (equip > 0) then equip = string.format('%.1f', equip) end 

   local ilvl = equip 
   if (equip < total) then 
      ilvl = equip .. ' / ' .. total 
   end
   
   local total2,equip2 = GetAverageItemLevel() 
   if (total2 > 0) then total2 = string.format('%.3f', total2) end 
   if (equip2 > 0) then equip2 = string.format('%.3f', equip2) end
   local ilvl2 = equip2
   if (equip2 < total2) then 
      ilvl2 = equip2 .. ' / ' .. total2
   end 

   -- local ilvlLine = _G[self:GetName() .. 'StatText'] 
   CharacterStatsPane.ItemLevelFrame.Value:SetText(ilvl) 

   self.tooltip =  "|cffffffff".. STAT_AVERAGE_ITEM_LEVEL .. ' ' .. ilvl2 
end)


ns.tips("角色面板显示移动速度")

-- 12.0.5 起移动速度变为秘密值，不能做数学运算。
-- 采用独立显示（不插入暴雪统计行，避免污染其刷新循环）：
--   在角色面板背景右下创建独立文本，用 AbbreviateNumbers 兼容秘密值显示百分比。
-- 数值格式简化来自https://bbs.nga.cn/read.php?tid=46650149
local SPEED_FORMAT_OPTIONS = {
    breakpointData = {
        {
            breakpoint = 0,
            abbreviation = "%",
            significandDivisor = 0.06999,
            fractionDivisor = 1,
            abbreviationIsGlobal = false,
        },
    },
}

-- 独立移动速度文本，锚定到角色面板背景右下（左下角对齐背景右下角）
-- 注意：CharacterFrame.Background 是纹理（BACKGROUND 层），在其上创建文字会被盖住，
-- 因此创建在顶层 CharacterFrame 上并提高绘制层级。
-- 必须在 PLAYER_LOGIN（所有暴雪 UI 加载完成）后才 hook，否则 hooksecurefunc 找不到函数。
-- 独立显示方案（激活）：不污染暴雪刷新循环，任何情况都不报错
-- 说明：往 PAPERDOLL_STATCATEGORIES 插入统计行会在 12.0.5 秘密值时代污染
--       PaperDollFrame_UpdateStats 刷新循环导致报错，故用独立 Frame 显示。
ns.event("PLAYER_LOGIN", function()
    if not (AddUIDB and AddUIDB.movspeed) then return end
    if not CharacterFrame or not CharacterFrame.Background then return end
    local frame = CreateFrame("Frame", nil, CharacterFrame)
    frame:SetFrameStrata("HIGH")
    frame:SetSize(1, 1)
    frame:SetPoint("BOTTOMLEFT", CharacterFrame.Background, "BOTTOMRIGHT", -108, 8)

    local speedtext = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    speedtext:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    speedtext:SetTextColor(1, 1, 1, 1)

    local runSpeed, flightSpeed, swimSpeed  -- 缓存，供 tooltip 使用（秘密值）

    -- 鼠标悬停提示：显示奔跑/飞行/游泳速度（暴雪原版 MovementSpeed_OnEnter 的功能）
    -- 速度是秘密值，不能用 %d 运算，需用 AbbreviateNumbers 兼容处理
    -- 注意：FormatSpeed / BuildTooltipLines 必须定义在 UpdateSpeedText 之前，
    --       否则 UpdateSpeedText 内引用它们是全局 nil（Lua 词法作用域）
    local function FormatSpeed(formatString, secretSpeed)
        -- 本地化格式串如 "奔跑速度：%d%%"，把 %d%% 替换为 %s 再传入含 % 的字符串
        return format(formatString:gsub("%%d%%%%", "%%s"), AbbreviateNumbers(secretSpeed, SPEED_FORMAT_OPTIONS))
    end

    local function BuildTooltipLines()
        GameTooltip:ClearLines()
        GameTooltip:AddLine(format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_MOVEMENT_SPEED).." "..AbbreviateNumbers(runSpeed, SPEED_FORMAT_OPTIONS))
        GameTooltip:AddLine(FormatSpeed(STAT_MOVEMENT_GROUND_TOOLTIP, runSpeed))
        GameTooltip:AddLine(FormatSpeed(STAT_MOVEMENT_FLIGHT_TOOLTIP, flightSpeed))
        GameTooltip:AddLine(FormatSpeed(STAT_MOVEMENT_SWIM_TOOLTIP, swimSpeed))
    end

    local function UpdateSpeedText()
        local _, run, flight, swim = GetUnitSpeed("player")
        runSpeed, flightSpeed, swimSpeed = run, flight, swim
        local speed = run
        if IsSwimming("player") then
            speed = swim
        elseif IsFlying("player") then
            speed = flight
        end
        speedtext:SetText(format(PAPERDOLLFRAME_TOOLTIP_FORMAT, STAT_MOVEMENT_SPEED).." "..AbbreviateNumbers(speed, SPEED_FORMAT_OPTIONS))
        -- tooltip 显示中时同步刷新内容，实现实时更新
        if GameTooltip:IsOwned(frame) then
            BuildTooltipLines()
        end
    end

    local function OnEnter()
        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT",-20,15)
        BuildTooltipLines()
        GameTooltip:Show()
    end

    local function OnLeave()
        GameTooltip:Hide()
    end
    speedtext:SetScript("OnEnter", OnEnter)
    speedtext:SetScript("OnLeave", OnLeave)

    -- 暴雪原版是给统计行挂 OnUpdate 每帧调用 MovementSpeed_OnUpdate 来实时刷新，
    -- 而不是靠 SPEED_UPDATE 事件（该事件只在"速度属性值"变化时触发，上下坐骑不触发）。
    -- frame 是 CharacterFrame 的子框架：面板打开时 OnUpdate 每帧更新，
    -- 面板关闭时 frame 随之隐藏、OnUpdate 自动停止，无性能浪费。
    frame:SetScript("OnUpdate", UpdateSpeedText)
    CharacterFrame:HookScript("OnShow", UpdateSpeedText)
end)