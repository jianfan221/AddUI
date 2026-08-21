local _,ns = ...

--12.07更新后,切换地图偶尔出现以下窗口被隐藏
local showtable = {
    "DamageMeter",              --伤害统计
    "BuffIconCooldownViewer",   --冷却管理器BUFF
    "EssentialCooldownViewer",  --冷却管理器重要技能
    "UtilityCooldownViewer",    --冷却管理器次要技能
    "BuffBarCooldownViewer",    --冷却管理器BUFF条
}
EventRegistry:RegisterFrameEventAndCallback("PLAYER_ENTERING_WORLD", function()
    for i, v in ipairs(showtable) do
        local f = _G[v]
        if f then
            local isDM = v == "DamageMeter"
            local vis = isDM and f.visibility or f.visibleSetting
            if vis == 0 and C_CVar.GetCVar(isDM and "damageMeterEnabled" or "cooldownViewerEnabled") == "1" then
                f:Show()
            end
        end
    end
end)


--12.1更新后各种帮助气泡 拦截掉参考https://addons.wago.io/addons/hide-help-frames
if HelpTipTemplateMixin and HelpTipTemplateMixin.OnShow then
    hooksecurefunc(HelpTipTemplateMixin, "OnShow", function(self)
        self:Hide()
    end)
end


-- 屏蔽空的 CHAT_MSG_SYSTEM 消息（空行会导致聊天框信息被莫名压缩）
ChatFrameUtil.AddMessageEventFilter("CHAT_MSG_SYSTEM", function(self, event, msg, ...)
    if msg == "" then
        return true
    end
    return false
end)