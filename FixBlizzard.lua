local _, ns = ...

-- 12.07 更新后，切换地图偶尔出现以下窗口被隐藏
local showTable = {
    "DamageMeter",              -- 伤害统计
    "BuffIconCooldownViewer",   -- 冷却管理器 BUFF
    "EssentialCooldownViewer",  -- 冷却管理器重要技能
    "UtilityCooldownViewer",    -- 冷却管理器次要技能
    "BuffBarCooldownViewer",    -- 冷却管理器 BUFF 条
}

EventRegistry:RegisterFrameEventAndCallback("PLAYER_ENTERING_WORLD", function()
    for _, name in ipairs(showTable) do
        local frame = _G[name]
        if frame then
            local isDamageMeter = name == "DamageMeter"
            local visible = isDamageMeter and frame.visibility or frame.visibleSetting
            local cvar = isDamageMeter and "damageMeterEnabled" or "cooldownViewerEnabled"

            if visible == 0 and C_CVar.GetCVar(cvar) == "1" then
                frame:Show()
            end
        end
    end
end)

-- 12.1 更新后，拦截各种帮助气泡
-- 参考：https://addons.wago.io/addons/hide-help-frames
if HelpTipTemplateMixin and HelpTipTemplateMixin.OnShow then
    hooksecurefunc(HelpTipTemplateMixin, "OnShow", function(self)
        self:Hide()
    end)
end

-- 启用地下城手册的套装分页
EventUtil.ContinueOnAddOnLoaded("Blizzard_EncounterJournal", function()
    EncounterJournal:HookScript("OnShow", function(self)
        PanelTemplates_SetAllTabsShown(self, true)
        PanelTemplates_SetNumTabs(self, #self.Tabs)
    end)
end)

-- 屏蔽空的 CHAT_MSG_SYSTEM 消息（空行会导致聊天框信息被莫名压缩）
ChatFrameUtil.AddMessageEventFilter("CHAT_MSG_SYSTEM", function(self, event, msg, ...)
    return msg == ""
end)