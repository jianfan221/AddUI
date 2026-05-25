local _, ns = ...
local BP,BPT = false, false
local oldfunction = ItemUtil.GetCraftingReagentCount
ns.event("ADDON_LOADED", function(event, addon)
    if ProfessionsFrame then
        BP,BPT = true, true
    end
    if addon == "Blizzard_Professions" then BP = true end
    if addon == "Blizzard_ProfessionsTemplates" then BPT = true end
    if not BP or not BPT then return end
    if ProfessionsFrame.UnlockAll then return end
    ProfessionsFrame.UnlockAll = CreateFrame("CheckButton", "UnlockAllReagentsButton", ProfessionsFrame.CraftingPage.SchematicForm, "UICheckButtonTemplate")
    ProfessionsFrame.UnlockAll:SetSize(26,26)
    ProfessionsFrame.UnlockAll:SetPoint("BOTTOMLEFT", 30, 0)
    ProfessionsFrame.UnlockAll.text:SetText(LIGHTGRAY_FONT_COLOR:WrapTextInColorCode("解锁所有材料以方便查看星级"))
    ProfessionsFrame.UnlockAll:SetScript("OnClick", function(self)
        if self:GetChecked() then
            ItemUtil.GetCraftingReagentCount = function() return 999 end
        else
            ItemUtil.GetCraftingReagentCount = oldfunction
        end
        --事件刷新抄的EnhancedCrafting
        if ProfessionsFrame and ProfessionsFrame.OrdersPage and ProfessionsFrame.OrdersPage.OrderView and ProfessionsFrame.OrdersPage.OrderView.OrderDetails then
            local f = ProfessionsFrame.OrdersPage.OrderView.OrderDetails.SchematicForm
            if f and f.UpdateAllSlots then f:UpdateAllSlots() end
        end
        if ProfessionsCustomerOrdersFrame and ProfessionsCustomerOrdersFrame.Form then
            ProfessionsCustomerOrdersFrame.Form:OnEvent("BAG_UPDATE")
        end
        if ProfessionsFrame and ProfessionsFrame.CraftingPage and ProfessionsFrame.CraftingPage.SchematicForm then
            ProfessionsFrame.CraftingPage.SchematicForm:UpdateAllSlots()
        end
        -- Re-setup quality dialog if open
        local rc = ProfessionsFrame and ProfessionsFrame.CraftingPage and ProfessionsFrame.CraftingPage.SchematicForm and ProfessionsFrame.CraftingPage.SchematicForm.ReagentContainer
        local qd = rc and rc.QualityDialog
        if qd and qd.recipeID and qd.Setup then qd:Setup() end
    end)
end)