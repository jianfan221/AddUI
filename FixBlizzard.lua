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
        local visibility = f.visibility or f.visibleSetting--可见性
        if f and visibility and visibility == 0 then
            f:Show()
        end
    end
end)