local _, ns = ...
local frameName = "AddUINamePlateCastWatcher"
local frame

globalNameplateCastBars = globalNameplateCastBars or {} -- 保持全局以避免重复创建
local bars = globalNameplateCastBars

local activeList = {}
local barHeight = 20 -- 改为20
local rowSpacing = 1 -- 施法条间隔 1
local castBarWidth = 160

local function IsModuleEnabled()
    return AddUIDB and AddUIDB.nameplatecast
end

local function RefreshLayout()
    wipe(activeList)
    for _, bar in pairs(bars) do
        if bar:IsShown() then
            table.insert(activeList, bar)
        end
    end
    -- 不排序：避免 taint 比较问题导致错误，保持原始显示顺序
    for i, bar in ipairs(activeList) do
        bar:ClearAllPoints()
        bar:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -16 - (i-1) * (barHeight + rowSpacing))
    end
end

local function CreateCastRow(unit)
    if bars[unit] then
        return bars[unit]
    end

    local bar = CreateFrame("StatusBar", frameName .. "_Row_" .. unit, frame)
    bar.unit = unit
    bar:SetSize(castBarWidth, barHeight)
    bar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(bar)
    bg:SetColorTexture(0, 0, 0, 0.35)

    -- 取消边框（不需要）

    local icon = bar:CreateTexture(nil, "ARTWORK")
    icon:SetSize(barHeight, barHeight)
    icon:SetPoint("RIGHT", bar, "LEFT", -3, 0)
    icon:SetTexture(136222)

    local spellName = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    spellName:SetPoint("LEFT", bar, "LEFT", 2, 0)
    spellName:SetJustifyH("LEFT")
    spellName:SetTextColor(1, 1, 1)

    local castTime = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    castTime:SetPoint("RIGHT", bar, "RIGHT", -2, 0)
    castTime:SetJustifyH("RIGHT")
    castTime:SetTextColor(1, 0.95, 0.5)

    local targetName = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    targetName:SetPoint("LEFT", bar, "RIGHT", 4, 0)
    targetName:SetJustifyH("LEFT")
    targetName:SetTextColor(1, 1, 1)

    bar.Icon = icon
    bar.SpellName = spellName
    bar.CastTime = castTime
    bar.TargetName = targetName

    bar:Hide()
    bars[unit] = bar
    return bar
end

local function UpdateBar(self)
    if not IsModuleEnabled() then
        local unit = self and self.unit
        if unit and bars[unit] then
            bars[unit]:Hide()
            RefreshLayout()
        end
        return
    end

    if self:IsForbidden() or not self.unit then
        return
    end

    local unit = self.unit
    if not unit then return end

    local isCasting = self.casting
    local isChanneling = self.channeling

    if not isCasting and not isChanneling then
        if bars[unit] then
            bars[unit]:Hide()
            RefreshLayout()
        end
        return
    end

    -- 额外防跳：如果单位没有施法/引导信息，也隐藏
    if not UnitCastingInfo(unit) and not UnitChannelInfo(unit) then
        if bars[unit] then
            bars[unit]:Hide()
            RefreshLayout()
        end
        return
    end

    local spellName, _, spellTexture, startTime, endTime
    if isCasting then
        spellName, _, spellTexture, startTime, endTime = UnitCastingInfo(unit)
    elseif isChanneling then
        spellName, _, spellTexture, startTime, endTime = UnitChannelInfo(unit)
    end

    if not spellName then
        if bars[unit] then
            bars[unit]:Hide()
            RefreshLayout()
        end
        return
    end

    local bar = CreateCastRow(unit)

    if self.casting and self.maxValue then
        local remain = nil
        if UnitCastingDuration and UnitCastingDuration(self.unit) then
            remain = UnitCastingDuration(self.unit):GetRemainingDuration()
            bar.CastTime:SetText(string.format("%.1f", remain))
        else
            bar.CastTime:SetText("")
        end

        bar:SetMinMaxValues(0, self.maxValue)
        bar:SetValue(self.value or 0)
        bar.Remaining = remain or 0
    elseif self.channeling and self.maxValue then
        local remain = nil
        if UnitChannelDuration and UnitChannelDuration(self.unit) then
            remain = UnitChannelDuration(self.unit):GetRemainingDuration()
            bar.CastTime:SetText(string.format("%.1f", remain))
        else
            bar.CastTime:SetText("")
        end

        bar:SetMinMaxValues(0, self.maxValue)
        bar:SetValue(self.value or 0)
        bar.Remaining = remain or 0
    else
        bar:SetMinMaxValues(0, 1)
        bar:SetValue(0)
        bar.CastTime:SetText("")
        bar.Remaining = 0
    end

    bar:SetStatusBarTexture("Interface\\AddOns\\AddUI\\UI\\media\\Raid-Bar-Hp-Fill")

    if spellTexture then
        bar.Icon:SetTexture(spellTexture)
    else
        bar.Icon:SetTexture(136222)
    end

    bar.SpellName:SetText(spellName)

    local target = UnitName(unit .. "target") or "-"
    bar.TargetName:SetText(target)
    local _, targetClass = UnitClass(unit .. "target")
    local tc = targetClass and RAID_CLASS_COLORS[targetClass] or {r = 1, g = 1, b = 1}
    bar.TargetName:SetTextColor(tc.r, tc.g, tc.b)

    if self.casting then
        if self.interruptible == false then
            bar:SetStatusBarColor(0.5, 0.5, 0.5) -- 不可打断灰色
        else
            bar:SetStatusBarColor(1, 0.85, 0) -- 读条黄色
        end
    elseif self.channeling then
        bar:SetStatusBarColor(0, 1, 0) -- 引导绿色
    else
        local _, class = UnitClass(unit)
        local c = class and RAID_CLASS_COLORS[class] or {r = 1, g = 1, b = 1}
        bar:SetStatusBarColor(c.r, c.g, c.b)
    end

    bar:Show()
    RefreshLayout()
end

ns.event("PLAYER_ENTERING_WORLD",function()
    if not IsModuleEnabled() then
        if frame then frame:Hide() end
        return
    end

    frame = CreateFrame("Frame", frameName, UIParent)
    frame:SetSize(240, 260)
    frame:SetPoint("LEFT", UIParent, "LEFT", 50, 250)
    frame:SetFrameStrata("LOW")
    frame:SetClampedToScreen(true)
    ns.AddEdit(frame,"周围怪物施法监控")

    hooksecurefunc(NamePlateCastingBarMixin, "OnUpdate", UpdateBar)
end)
