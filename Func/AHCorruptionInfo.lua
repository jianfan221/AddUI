local _,ns = ...
------------------------------------
-- Auction House Bonus Stats Info 
-- https://wago.io/V4_C0sbxw
-- Author: Hasicz (Modified to show only bonus stats)
-- https://ngabbs.com/read.php?tid=45261418
------------------------------------

-- 创建字体字符串的函数
local function createFS(row, color, x)
    local fs = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    local font, size, flags = fs:GetFont()
    fs:SetFont(font, 12, flags)
    fs:SetTextColor(unpack(color))
    fs:SetPoint("LEFT", row, x, 0);
    fs:Hide()
    fs:SetText("")
    
    return fs
end

-- 更新行数据的函数 - 使用更可靠的方法获取副属性
local function rowUpdate(row)
    if row and row.rowData then
        local data = row.rowData
        
        -- 重置副属性显示
        row.bonus:SetText("")
        row.bonus:Hide()
        
        if data.itemLink then          
            -- 方法2: 如果GetItemStats失败，使用更精确的物品链接解析
            local itemString = data.itemLink:match("item[%-?%d:]+")
            if itemString then
                local parts = {strsplit(":", itemString)}
                
                -- 物品链接中副属性ID通常在特定位置
                -- 对于现代物品链接，副属性ID通常在位置14-17
                for i = 14, 17 do
                    if parts[i] and parts[i] ~= "" then
                        local bonusId = parts[i]
                        if bonusId == "40" then
                            row.bonus:SetText(ITEM_MOD_CR_AVOIDANCE_SHORT)
                            row.bonus:Show()
                            return
                        elseif bonusId == "41" then
                            row.bonus:SetText(ITEM_MOD_CR_LIFESTEAL_SHORT)
                            row.bonus:Show()
                            return
                        elseif bonusId == "42" then
                            row.bonus:SetText(ITEM_MOD_CR_SPEED_SHORT)
                            row.bonus:Show()
                            return
                        elseif bonusId == "43" then
                            row.bonus:SetText(ITEM_MOD_CR_STURDINESS_SHORT)
                            row.bonus:Show()
                            return
                        end
                    end
                end
            end
        end
    end
end

-- 处理所有行的函数
local function processRows()
    -- 检查拍卖行框架和相关组件是否存在
    if AuctionHouseFrame
        and AuctionHouseFrame.ItemBuyFrame
        and AuctionHouseFrame.ItemBuyFrame.ItemList
        and AuctionHouseFrame.ItemBuyFrame.ItemList.tableBuilder
    then
        -- 遍历所有表格行
        for rowIndex, row in pairs(AuctionHouseFrame.ItemBuyFrame.ItemList.tableBuilder.rows) do
            -- 如果行没有副属性显示字段，则创建
            if not row.bonus then
                row.bonus = createFS(row, {30 / 255, 1, 0}, 475)  -- 绿色
            end
            -- 更新行显示
            rowUpdate(row)
        end
    end
end

-- 定时器变量
local ticker

-- 注册事件
ns.event("AUCTION_HOUSE_SHOW", function(event)
if ticker then ticker:Cancel() end
end)

ns.event("ITEM_SEARCH_RESULTS_UPDATED", function(event)
if ticker then ticker:Cancel() end
ticker = C_Timer.NewTicker(0.01, processRows, 50)
end)

ns.event("AUCTION_HOUSE_BROWSE_RESULTS_ADDED", function(event)
if ticker then ticker:Cancel() end
ticker = C_Timer.NewTicker(0.01, processRows, 50)
end)

ns.event("AUCTION_HOUSE_CLOSED", function(event)
if ticker then ticker:Cancel() end
end)

ns.event("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", function(event)
if ticker then ticker:Cancel() end
ticker = C_Timer.NewTicker(0.01, processRows, 50)
end)

ns.event("AUCTION_HOUSE_BROWSE_FAILURE", function(event)
if ticker then ticker:Cancel() end
end)
