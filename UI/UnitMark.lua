local _, ns = ...


local ICON_SIZE = 12 --每个图标尺寸
local OffsetX = ICON_SIZE   -- 从目标框左侧开始的初始 X 偏移
local OffsetY = 17 -- 从目标框顶部开始的 Y 偏移 (根据目标框大小调整)
-- 定义 6 个按钮：骷髅、红X、月亮、三角、菱形、星星
local MARKS = {
    {idx = 8, x = 1}, -- 骷髅
    {idx = 7, x = 2}, -- 红X
    {idx = 5, x = 3}, -- 月亮
    {idx = 4, x = 4},  -- 三角
    {idx = 3, x = 5},  -- 菱形
    {idx = 1, x = 6},  -- 星星
}

local function CreateMarkButton(name, anchorFrame, unit, markIdx, x)
    -- 1. 创建安全按钮 (父级设为 UIParent 是最稳妥的)
    local btn = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
    local scale = anchorFrame:GetScale() or 1
    btn:SetSize(ICON_SIZE*scale, ICON_SIZE*scale)
    --btn:SetFrameStrata("HIGH") -- 确保在目标框之上
    local xx = (ICON_SIZE + 6 ) * x * scale - (OffsetX * scale )
    btn:SetPoint("BOTTOMLEFT", anchorFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar, "TOPLEFT", xx, OffsetY*scale) -- 根据目标框大小调整 Y 偏移
    btn:EnableMouse(true)
    btn:RegisterForClicks("AnyUp", "AnyDown") 

    -- 2. 新增背景：每个按钮自带一个小背景块
    -- 使用 BackdropTemplate 可能会失效，所以我们直接用简单的 Texture 做背景
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", -3*scale, 3*scale)
    bg:SetPoint("BOTTOMRIGHT", 3*scale, -3*scale)
    bg:SetColorTexture(0, 0, 0, 0.3) -- 黑色半透明

    -- 3. 图标部分
    local tex = btn:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. markIdx)
    
    -- 4. 鼠标指向效果 (高亮)
    -- 我们把高亮范围调大，让它显眼
    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    hl:SetBlendMode("ADD")
    hl:SetPoint("TOPLEFT", -6, 6) -- 溢出 6 像素，视觉效果更显著
    hl:SetPoint("BOTTOMRIGHT", 6, -6)

    -- 5. 安全属性与宏逻辑
    btn:SetAttribute("unit", unit) 
    btn:SetAttribute("type", "macro")
    btn:SetAttribute("macrotext", string.format("/tm [@"..unit.."] %d", markIdx))
    
    -- 6. 状态监控 (随目标存在而显示)
    RegisterUnitWatch(btn)
    
    return btn
end

ns.event("PLAYER_ENTERING_WORLD", function()
    -- 这里的 AddUIDB.unitf 是你自己的库逻辑，请确保它为 true
    if not AddUIDB or not AddUIDB.unitf then return end
    
    -- 循环创建 6 个按钮
    for _, info in ipairs(MARKS) do
        -- 目标框架按钮
        CreateMarkButton("UnitMarkTargetBtn_" .. info.idx, TargetFrame, "target", info.idx, info.x)
        -- 焦点框架按钮
        CreateMarkButton("UnitMarkFocusBtn_" .. info.idx, FocusFrame, "focus", info.idx, info.x)
    end
end)