local _, ns = ...

local ICON_SIZE = 12 --每个图标尺寸
local OffsetX = -12
local OffsetY = -23

local function CreateMarkButton(anchorFrame, unit, markIdx)
    if not anchorFrame.Marks then
        anchorFrame.Marks = 0
    end
    anchorFrame.Marks = anchorFrame.Marks + 1
    local btn = CreateFrame("Button", nil, anchorFrame, "SecureActionButtonTemplate")
    btn:SetSize(ICON_SIZE, ICON_SIZE)
    local xx = (ICON_SIZE + 6 ) * anchorFrame.Marks - OffsetX
    btn:SetPoint("BOTTOMLEFT", anchorFrame, "TOPLEFT", xx, OffsetY)
    btn:EnableMouse(true)
    btn:RegisterForClicks("AnyUp", "AnyDown") 

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT", -3, 3)
    bg:SetPoint("BOTTOMRIGHT", 3, -3)
    bg:SetColorTexture(0, 0, 0, 0.3)

    local tex = btn:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. markIdx)

    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    hl:SetBlendMode("ADD")
    hl:SetPoint("TOPLEFT", -6, 6)
    hl:SetPoint("BOTTOMRIGHT", 6, -6)

    btn:SetAttribute("unit", unit) 
    btn:SetAttribute("type", "macro")
    btn:SetAttribute("macrotext", string.format("/tm [@"..unit.."] %d", markIdx))

    RegisterUnitWatch(btn)
    
    return btn
end

ns.event("PLAYER_ENTERING_WORLD", function()
    if not AddUIDB or not AddUIDB.unitf then return end
    
    CreateMarkButton(TargetFrame, "target", 8)
    CreateMarkButton(TargetFrame, "target", 7)
    CreateMarkButton(TargetFrame, "target", 5)
    CreateMarkButton(TargetFrame, "target", 4)
    CreateMarkButton(TargetFrame, "target", 3)
    CreateMarkButton(TargetFrame, "target", 1)

    CreateMarkButton(FocusFrame, "focus", 8)
    CreateMarkButton(FocusFrame, "focus", 7)
    CreateMarkButton(FocusFrame, "focus", 5)
    CreateMarkButton(FocusFrame, "focus", 4)
    CreateMarkButton(FocusFrame, "focus", 3)
    CreateMarkButton(FocusFrame, "focus", 1)
end)