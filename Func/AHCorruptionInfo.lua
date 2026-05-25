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
        local font, size, flags = row.bonus:GetFont()
        row.bonus:SetFont(font, 12, flags)
        row.bonus:SetTextColor(unpack(COLOR))
        row.bonus:SetPoint("LEFT", row, 475, 0)
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

local function refreshAllRows()
    if not AuctionHouseFrame or not AuctionHouseFrame.ItemBuyFrame then return end
    local tb = AuctionHouseFrame.ItemBuyFrame.ItemList and AuctionHouseFrame.ItemBuyFrame.ItemList.tableBuilder
    if not tb or not tb.rows then return end
    for _, row in pairs(tb.rows) do
        updateRow(row)
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
