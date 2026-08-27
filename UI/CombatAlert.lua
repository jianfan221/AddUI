local _,ns = ...
ns.event("PLAYER_LOGIN", function()
if AddUIDB.comb ==  false  then return end

-----------------------------------
-- 離開和進入戰鬥,大文字提示
-----------------------------------
local locale = GetLocale()
local L = {
    enterCombat = { default = "Enter Combat", zhTW = "進入戰鬥", zhCN = "进入战斗" },
    leaveCombat = { default = "Leave Combat", zhTW = "離開戰鬥", zhCN = "离开战斗" },
}
local alertFrame = CreateFrame("Frame","进入战斗",UIParent)
alertFrame:SetSize(360, 59) -- 原 400×65 缩放 0.9 的视觉尺寸，去掉 SetScale 后直接用视觉尺寸
alertFrame:SetPoint("TOP", 0, -280)
alertFrame:Hide()
ns.AddEdit(alertFrame,"ADDUI进入战斗",true)
alertFrame.Bg = alertFrame:CreateTexture(nil, "BACKGROUND")
alertFrame.Bg:SetTexture("Interface\\LevelUp\\MinorTalents")
alertFrame.Bg:SetPoint("TOP")
alertFrame.Bg:SetSize(360, 60) -- 与 frame 视觉尺寸同步（原 400×67×0.9）
alertFrame.Bg:SetTexCoord(0, 400/512, 341/512, 407/512)
alertFrame.Bg:SetVertexColor(1, 1, 1, 0.4)
alertFrame.text = alertFrame:CreateFontString(nil, "ARTWORK", "GameFont_Gigantic")
alertFrame.text:SetPoint("CENTER")
alertFrame:SetScript("OnEvent", function(self, event, ...)

    if (event == "PLAYER_REGEN_DISABLED") then
        self.text:SetText(L.enterCombat[locale] or L.enterCombat.default)
    elseif (event == "PLAYER_REGEN_ENABLED") then
        self.text:SetText(L.leaveCombat[locale] or L.leaveCombat.default)
    end
    if self.fadeTimer then
        self.fadeTimer:Cancel()
        self.fadeTimer = nil
    end
    self:SetAlpha(0)
    UIFrameFadeIn(self, 0.5, 0, 1)
    self.fadeTimer = C_Timer.NewTicker(1, function()
        UIFrameFadeOut(self, 1, 1, 0)
        self.fadeTimer:Cancel()
        self.fadeTimer = nil
    end, 1)
end)
alertFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
alertFrame:RegisterEvent("PLAYER_REGEN_DISABLED")

end)