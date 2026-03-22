local _,ns = ...
ns.tips("套装管理器20套上限")
ns.event("PLAYER_ENTERING_WORLD", function()

SetCVar('predictedHealth', 1)	--解决团队框架加血延迟
SetCVar('autoStand', 1)	--施法自动站起来
SetCVar("autoUnshift", 1)--施法自动解除变形
SetCVar("cameraDistanceMaxZoomFactor", 2.6)	--39码镜头
SetCVar("minimapTrackingShowAll",1) --小地图追踪显示镇民
SetCVar("combatLogRetentionTime", 300)	--10.2更新后有些人会变成0,导致报错或游戏内log不生效以及部分插件不生效https://nga.178.com/read.php?tid=38597630&_fp=2
SetCVar("SpellQueueWindow", AddUIDB.SpellQ)	--延迟容限
SetCVar("timeMgrUseMilitaryTime", 1)	--小地图时间24小时模式
SetCVar("timeMgrUseLocalTime", 1)	--小地图时间使用本地时间

--Enum.EditModeLayoutType.Server=2--编辑模式角色专属无法删除问题

if AddUIDB.cvar ==  false then return end
if InCombatLockdown() then return end		--战斗中不执行

if WeeklyRewardExpirationWarningDialog then
WeeklyRewardExpirationWarningDialog:Hide() end--有wa会自动打开

SetCVar("remoteTextToSpeech",0)	--在语音聊天中为我发言
SetCVar("worldPreloadNonCritical", 0)	--加快蓝条，读完蓝条再载入游戏模组

SetCVar("chatMouseScroll", 1)	--聊天框鼠标滚轮翻页
SetCVar("alwaysCompareItems", 1)	--装备对比
SetCVar("scriptErrors", 0) 	--屏蔽lua错误

SetCVar("UberTooltips", 1) 	--显示技能说明
SetCVar("ActionButtonUseKeyDown", 1)	--按下按键释放技能
SetCVar("mapFade", 0)	--移动时地图不透明
SetCVar("cameraSmoothTrackingStyle",  0)	--引导技能不转视角
SetCVar("camerasmooth",  0)--引导技能不转视角

SetCVar("Sound_EnableErrorSpeech", 0)	--错误提示音

C_Container.SetSortBagsRightToLeft(true)	--正序整理背包，反序改成false
C_Container.SetInsertItemsLeftToRight(true)	--新物品放在最右侧背包，左侧改成false

--SetCVar("rawMouseEnable", 1)				--在7.1.5更新中添加了：如果你的鼠标光标消失会自动帮你重置到屏幕中心

--隐藏中间团队拾取界面
BossBanner:UnregisterAllEvents()

setglobal("MAX_EQUIPMENT_SETS_PER_PLAYER",100)

end)
