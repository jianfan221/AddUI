local _, ns = ...

local COLOR = {30 / 255, 1, 0}

-- 第三属性 bonus ID 映射
local TERTIARY_MAP = {
    ["40"] = ITEM_MOD_CR_AVOIDANCE_SHORT,
    ["41"] = ITEM_MOD_CR_LIFESTEAL_SHORT,
    ["42"] = ITEM_MOD_CR_SPEED_SHORT,
    ["43"] = ITEM_MOD_CR_STURDINESS_SHORT,
}

local function updateRow(row)
    if not row or not row.rowData then return end
    if not row.bonus then
        row.bonus = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.bonus:SetFontHeight(13)
        row.bonus:SetTextColor(unpack(COLOR))
        row.bonus:SetPoint("LEFT", row, 475, -1)
    end

    row.bonus:SetText("")
    row.bonus:Hide()

    local link = row.rowData.itemLink
    if not link then return end

    local itemString = link:match("item[%-?%d:]+")
    if not itemString then return end
    local parts = {strsplit(":", itemString)}
    for i = 14, 17 do
        local text = TERTIARY_MAP[parts[i]]
        if text then
            row.bonus:SetText(text)
            row.bonus:Show()
            return
        end
    end
end

-- 副属性（第二属性）：固定 4 列对应 爆击/急速/精通/全能，颜色取自 StatSheet.lua
local SECONDARY_ORDER = {
    { name = ITEM_MOD_CRIT_RATING_SHORT,    color = {1, 0.5, 0} },  -- 爆击 橙
    { name = ITEM_MOD_HASTE_RATING_SHORT,   color = {0, 1, 0} },    -- 急速 绿
    { name = ITEM_MOD_MASTERY_RATING_SHORT, color = {0, 0.5, 1} },  -- 精通 蓝
    { name = ITEM_MOD_VERSATILITY,          color = {1, 1, 0} },    -- 全能 黄
}
-- 副属性显示（独立于 updateRow，互不影响）
-- 用 C_TooltipInfo.GetHyperlink 读取该物品 tooltip 数据，识别其中的爆击/急速/精通/全能
local function updatestats(row)
    if not row or not row.rowData then return end

    -- 懒创建 4 列副属性文本：row.stats[i] 固定对应 SECONDARY_ORDER[i]
    if not row.stats then
        row.stats = {}
        local x0, gap = 250, 45  -- 第 1 列左起点 x 与列间距（紧凑，按实际界面微调）
        for i = 1, 4 do
            local t = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            t:SetFontHeight(13)
            t:SetTextColor(unpack(SECONDARY_ORDER[i].color))  -- 每列颜色固定，创建时设一次
            t:SetPoint("LEFT", row, x0 + (i - 1) * gap, -1)
            row.stats[i] = t
        end
    end

    for i = 1, 4 do
        row.stats[i]:SetText("")
        row.stats[i]:Hide()
    end

    local link = row.rowData.itemLink
    if not link then return end

    local tip = C_TooltipInfo.GetHyperlink(link)
    if not tip or not tip.lines then return end

    for _, line in ipairs(tip.lines) do
        local leftText = line and line.leftText
        if leftText then
            for i, info in ipairs(SECONDARY_ORDER) do
                if strfind(leftText, info.name) then
                    -- 只显示数值（如 "268 爆击" → 268），颜色已在创建时按列设好
                    local value = strmatch(leftText, "(%d[%d,%.]*)")
                    if value then
                        local t = row.stats[i]
                        t:SetText(value)
                        t:Show()
                    end
                    break
                end
            end
        end
    end
end

local function refreshAllRows()
    if not AuctionHouseFrame or not AuctionHouseFrame.ItemBuyFrame then return end
    local tb = AuctionHouseFrame.ItemBuyFrame.ItemList and AuctionHouseFrame.ItemBuyFrame.ItemList.tableBuilder
    if not tb or not tb.rows then return end
    for _, row in pairs(tb.rows) do
        updateRow(row)
        updatestats(row)
    end
end

-- 打开 AH 时启动定时刷新（覆盖初始、搜索、滚动所有场景）
local ticker
ns.event("AUCTION_HOUSE_SHOW", function()
    refreshAllRows()
    if not ticker then
        ticker = C_Timer.NewTicker(0.1, refreshAllRows)
    end
end)
ns.event("AUCTION_HOUSE_CLOSED", function()
    if ticker then ticker:Cancel(); ticker = nil end
end)
ns.event("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", function()
    C_Timer.After(0, refreshAllRows)
end)
ns.event("AUCTION_HOUSE_BROWSE_RESULTS_ADDED", function()
    C_Timer.After(0, refreshAllRows)
end)
ns.event("ITEM_SEARCH_RESULTS_UPDATED", function()
    C_Timer.After(0, refreshAllRows)
end)
