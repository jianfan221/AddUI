--Author: 简繁
local _,ns = ...

local ADCVAR,ADCVARCOPY

ns.event('CVAR_UPDATE', function(event, msg, a)
	if not ADCVAR then return end
	local _,defcvar = C_CVar.GetCVarInfo(msg)
	print(msg,a,"默认值:",defcvar)--打印具体改变的cvar
	if not ADCVARCOPY then return end
	local text = 'SetCVar("'..msg..'", '..a..')'
	ChatFrame_OpenChat(text, SELECTED_DOCK_FRAME)
end)
SlashCmdList["PRINTCVAR"] = function(msg)
	ADCVAR = not ADCVAR
	if msg ~= "" and ADCVAR then
		ADCVARCOPY = ADCVAR
		print("|cff3cff00已开启CVar打印和复制")
	elseif ADCVAR then
		print("|cff3cff00已开启CVar打印")
	else
		ADCVARCOPY = ADCVAR
		print("|cffff5900CVar打印已关闭")
	end
end 
SLASH_PRINTCVAR1 = "/adc"
--界面自动化
local function uiconfig()
    --恢复默认
    --InterfaceOptionsFrame_SetAllToDefaults()
--其他
SetCVar("UnitNamePlayerPVPTitle", 1)	--头衔
SetCVar("UnitNamePlayerGuild",1)	--公会名
SetCVar("UnitNameGuildTitle", 1)	--公会会阶
SetCVar("chatStyle","im")	--聊天风格-即时通讯风格"classic","im"
C_Container.SetSortBagsRightToLeft(true)	--正序整理背包，反序改成false
C_Container.SetInsertItemsLeftToRight(true)	--新物品放在最右侧背包，左侧改成false
SetCVar("floatingCombatTextCombatDamageDirectionalScale_v2", 0)--伤害数字显示在血条上方,改数字0123456789
SetCVar("WorldTextScale_v2", 2)								--战斗伤害字体大小
SetCVar("floatingCombatTextCombatDamage_v2", 1)				--显示伤害数字
SetCVar("floatingCombatTextCombatHealing_v2", 1)			--显示治疗数字
SetCVar("enableFloatingCombatText",  0)						--滚动战斗记录
SetCVar("floatingCombatTextFloatMode",  1)					--滚动方向
SetCVar("floatingCombatTextAuras", 0)  						--光环
SetCVar("floatingCombatTextComboPoints", 0) 				--連擊點 
SetCVar("floatingCombatTextEnergyGains", 0) 				--資源獲得(法力、怒氣、能量、真氣，和連擊點不同) 
SetCVar("floatingCombatTextPeriodicEnergyGains", 0)   		--周期性能量   
SetCVar("floatingCombatTextHonorGains", 1)   				--榮譽擊殺 
SetCVar("floatingCombatTextRepChanges", 0)   				--聲望變化
SetCVar("floatingCombatTextPetMeleeDamage", 1)   			--普攻 
SetCVar("floatingCombatTextPetSpellDamage", 1)  			--技能 
SetCVar("floatingCombatTextCombatHealingAbsorbTarget", 1)	--對目標上盾/護甲提示 
SetCVar("floatingCombatTextCombatHealingAbsorbSelf", 1) 	--自身得盾/護甲提示 
SetCVar("floatingCombatTextCombatDamageAllAutos", 1) 	  	--顯示所有的白字 
SetCVar("floatingCombatTextDodgeParryMiss", 1)   			--閃招 
SetCVar("floatingCombatTextDamageReduction", 1)  			--傷害減免/抵抗 
SetCVar("floatingCombatTextCombatLogPeriodicSpells", 1) 	--周期性傷害 
SetCVar("floatingCombatTextReactives", 1)   				--法術警示 
SetCVar("floatingCombatTextSpellMechanics", 0)				--顯示目標受到的糾纏效果，(例如 誘補(xxxx-xxxx)，沉默緩速之類) 
SetCVar("floatingCombatTextSpellMechanicsOther", 0)  		--顯示其他玩家受到的糾纏效果 
SetCVar("floatingCombatTextCombatState", 0)   				--進入/離開戰鬥文字提示 
SetCVar("floatingCombatTextLowManaHealth", 0)   			--低MP/低HP文字提示 
SetCVar("floatingCombatTextFriendlyHealers", 0)   			--友方治療者名稱 


SetCVar("xpBarText", 1) --经验条
SetCVar("statusText",1) --状态文字


--时钟
	SetCVar("timeMgrAlarmEnabled",0) --关闭时钟提醒
	SetCVar("timeMgrUseMilitaryTime",1)	--24小时模式
	SetCVar("timeMgrUseLocalTime",1)	--使用本地时间

--控制
	SetCVar("deselectOnClick",0) --目标锁定
    SetCVar("autoDismountFlying",1) --自动取消飞行
	SetCVar("autoClearAFK",1) --自动解除离开状态
	SetCVar("interactOnLeftClick",1) --左键点击操作
	SetCVar("lootUnderMouse",1) --鼠标位置打开拾取框
	SetCVar("autoLootDefault",1) --自动拾取
	SetCVar("combinedBags",1)	--组合背包
	--镜头
	SetCVar("cameraWaterCollision",0)--水体碰撞
    SetCVar("cameraSmoothStyle",0) --镜头跟随模式
	SetCVar("SoftTargetInteract",3)--开启交互键
--界面
	--显示
	SetCVar("hideAdventureJournalAlerts","none")	--隐藏冒险指南
	SetCVar("showTutorials",0)
	SetCVar("statusText",1) --状态文字
    SetCVar("statusTextDisplay","NUMERIC")--头像状态文字形式："NUMERIC"数值"PERCENT"百分比"BOTH"同时显示
	SetCVar("chatBubbles",1)--聊天泡泡
	SetCVar("chatBubblesParty",1)--小队聊天泡泡
	SetCVar("chatBubblesRaid",1)--团队聊天泡泡
	--团队界面配置
	SetCVar("useCompactPartyFrames",1) --使用团队风格的小队框体界面
	SetCVar("raidFramesDisplayPowerBars",1)	--显示能量条
	SetCVar("raidFramesDisplayOnlyHealerPowerBars",0)	--只显示治疗能量条
	SetCVar("raidFramesDisplayIncomingHeals",1)	--预计治疗
	SetCVar("raidFramesDisplayAggroHighlight",1)	--高亮仇恨目标
	SetCVar("raidFramesDisplayClassColor",1)	--职业颜色
	SetCVar("raidOptionDisplayPets",0)	--显示宠物
	SetCVar("raidOptionDisplayMainTankAndAssist",0)	--主坦克主助理
	SetCVar("raidFramesDisplayDebuffs",1)	--显示负面效果
	SetCVar("raidFramesDisplayLargerRoleSpecificDebuffs",1)--放大职责减益
	SetCVar("raidFramesDisplayOnlyDispellableDebuffs",0)	--只显示可供驱散的负面效果
	SetCVar("raidFramesDisplayBigDefensive",1)--重要防御技能居中
	SetCVar("raidFramesDispellndicatorType",2)--可驱散减益指示器
	SetCVar("raidFramesDispellndicatorOverlay",0)--可驱散减益颜色
	SetCVar("raidFramesHealthText","none")	--生命值
	SetCVar("pvpFramesDisplayPowerBars",1)	--竞技场对手框能量条
	SetCVar("pvpFramesDisplayOnlyHealerPowerBars",0)	--竞技场对手框仅显示治疗能量条
	SetCVar("pvpFramesDisplayClassColor",1)	--竞技场对手框能量条
	
--动作条
    --SHOW_MULTI_ACTIONBAR_1="1" --左下方动作条
    --SHOW_MULTI_ACTIONBAR_2="0" --右下方动作条
	--SHOW_MULTI_ACTIONBAR_3="1" --右侧右边动作条
	--SHOW_MULTI_ACTIONBAR_4="1" --右侧左边动作条
	-- 显示动作条2-5
   --local bar1, bar2, bar3, bar4, _, _, _ = GetActionBarToggles()
   --if (not bar1 or not bar2 or not bar3 or not bar4) then
		--Settings.SetValue("PROXY_SHOW_ACTIONBAR_1", true)
        Settings.SetValue("PROXY_SHOW_ACTIONBAR_2", true)
        Settings.SetValue("PROXY_SHOW_ACTIONBAR_3", false)
        Settings.SetValue("PROXY_SHOW_ACTIONBAR_4", true)
        Settings.SetValue("PROXY_SHOW_ACTIONBAR_5", true)
		Settings.SetValue("PROXY_SHOW_ACTIONBAR_6", false)
		Settings.SetValue("PROXY_SHOW_ACTIONBAR_7", false)
		Settings.SetValue("PROXY_SHOW_ACTIONBAR_8", false)
    --end
	--刷新动作条
	--MultiActionBar_Update()
    --StatusTrackingBarManager:UpdateBarTicks()
    --EventRegistry:TriggerEvent("ActionBarShownSettingUpdated")
	
	SetCVar("lockActionBars",1)--锁定动作条
	
	SetCVar("alwaysShowActionBars",1)--始终显示动作条
    SetCVar("countdownForCooldowns",1) --显示冷却时间


--战斗
	SetCVar("nameplateShowSelf",1) --显示个人资源
	SetCVar("nameplateResourceOnTarget",0) --在敌方目标显示玩家资源
    SetCVar("showTargetOfTarget",1) --目标的目标
    SetCVar("doNotFlashLowHealthWarning",1) --生命值过低时不闪烁屏幕
    SetCVar("lossOfControl",1) --失控警报
	SetCVar("enableFloatingCombatText",  0)	--滚动战斗记录
	SetCVar("autoSelfCast",1) --自动自我施法


--社交
    SetCVar("profanityFilter",0) --语言过滤器
    SetCVar("spamFilter",0) --垃圾信息过滤
    SetCVar("guildMemberNotify",0) --公会成员提示
    SetCVar("showToastBroadcast",1) --通告更新
    SetCVar("showToastWindow",0) --显示浮窗
    SetCVar("showTimestamps","none") --聊天时间戳
	SetCVar("whisperMode","inline")	--新的悄悄话
--信号
	SetCVar("enablePings",1)	--开启信号
	
--游戏增强
	SetCVar("combatWarningsEnabled",1)	--首领警报
	SetCVar("encounterWarningsEnabled",1)--文字警报
	SetCVar("encounterTimelineEnabled",1)--首领时间轴
	SetCVar("encounterTimelinelocnographyEnabled",1)--法术辅助图标
	SetCVar("cooldownViewerEnabled",1)--冷却管理器
	SetCVar("externalDefensivesEnabled",1)--外部防御技能
	SetCVar("damageMeterEnabled", 1)--伤害统计
	SetCVar("spellDiminishPVPEnemiesEnabled",1)--收益递减追踪
	
--姓名版
	SetCVar("UnitNameOwn",1) --我的名字
	SetCVar("UnitNameFriendlySpecialNPCName", 0);
	SetCVar("UnitNameHostleNPC", 0);
	SetCVar("UnitNameInteractiveNPC", 0);
	SetCVar("UnitNameNPC", 1);
	SetCVar("ShowQuestUnitCircles", 1);
	SetCVar("UnitNameNonCombatCreatureName",1) --小动物小伙伴
	SetCVar("UnitNameFriendlyPlayerName",1) --友方玩家
	SetCVar("UnitNameFriendlyMinionName",0) --友方玩家仆从
	SetCVar("UnitNameEnemyPlayerName",1) --敌对玩家
	SetCVar("UnitNameEnemyMinionName",1) --敌对玩家仆从
	SetCVar("nameplateShowFriends",0) --友方玩家血条
	SetCVar("nameplateShowFriendlyMinions",0) --友方玩家仆从血条
	SetCVar("nameplateShowEnemies",1) --敌对玩家血条
	SetCVar("nameplateShowEnemyMinions",1) --敌对玩家仆从血条
	SetCVar("nameplateShowEnemyMinus",1) --敌对玩家杂兵血条
	SetCVar("nameplateShowAll",1) --显示所有姓名版
	SetCVar("nameplateShowFriendlyNpcs",1) --友方NPC姓名版
	SetCVar("nameplateShowOffscreen",1) --屏幕外姓名版
	SetCVar("nameplateInfoDisplay","D") --姓名版信息
	SetCVar("nameplateCastBarDisplay","O") --施法条信息
	SetCVar("nameplateThreatDisplay","B") --仇恨显示
	SetCVar("nameplateEnemyNpcAuraDisplay","G") --敌方NPC减益状态
	SetCVar("nameplateEnemyPlayerAuraDisplay","G") --敌方玩家减益状态
	SetCVar("nameplateFriendlyPlayerAuraDisplay","G") --友方玩家减益状态
	SetCVar("nameplateSimplifiedTypes","") --简化姓名版
	
    --NamePlateDriverFrame:UpdateNamePlateOptions() 
--综合
	SetCVar("WorldTextMinSize",12)	--名字尺寸
	SetCVar("CameraKeepCharacterCentered",0)	--动态眩晕
	SetCVar("CameraReduceUnexpectedMovement",1)	--动态眩晕
	SetCVar("ShakeStrengthCamera",0)	--视角晃动
	SetCVar("ShakeStrengthUI",0)	--视角晃动
	SetCVar("empowerTapControls",1)	--蓄力法术
	SetCVar("spellActivationOverlayOpacity",0.6)	--法术警报不透明度
--色盲模式
	SetCVar("colorblindMode",0)
	
--易用性
    SetCVar("speechToText",0)	--语音转文本
	SetCVar("textToSpeech",0)	--文本转语音
	SetCVar("remoteTextToSpeech",0)	--在语音聊天中为我发言
--坐骑
	SetCVar("motionSicknessLandscapeDarkening",0)	--晕动症
	SetCVar("DisableAdvancedFlyingFullScreenEffects",1)	--动态飞行屏幕效果
	SetCVar("DisableAdvancedFlyingVelocityVFX",1)	--动态飞行速度效果
	SetCVar("advFlyPitchControl",3)				--仰角控制
	SetCVar("advFlyPitchControlGroundDebounce",1)	--防抖倾角输入
--系统相关
--图形
	SetCVar("useUiScale", 1)	--启用UI缩放
	SetCVar("uiScale", 0.75)	--UI缩放
	SetCVar("cameraFov", 90)	--镜头视野范围
--音频
	SetCVar("Sound_MasterVolume", 0.3)	--主音量
	SetCVar("Sound_MusicVolume", 0)	--音乐
	SetCVar("Sound_SFXVolume", 0.25)	--效果
	SetCVar("Sound_AmbienceVolume", 0.1)	--环境音
	SetCVar("Sound_DialogVolume", 0.5)	--对话
	SetCVar("Sound_EnableErrorSpeech", 0)	--错误提示音
	SetCVar("Sound_EnableSoundWhenGameIsInBG", 1)	--背景声音

print("|cff00BFFFAddUI:|r已设置界面配置")
end
--SetCVar("",)

--界面自动化命令 
SlashCmdList["UICONFIGG"] = function() uiconfig() end 
SLASH_UICONFIGG1 = "/sd"
SLASH_UICONFIGG2 = "/sdd"

--选择编辑模式配置3
SlashCmdList["EDITMODE"] = function()
EditModeManagerFrame:SelectLayout(3)
end 
SLASH_EDITMODE1 = "/ed"
SLASH_EDITMODE2 = "/edd"


--恢复默认按键
local function Bindings()
	LoadBindings(DEFAULT_BINDINGS)
	SaveBindings(1)
	--设置几个默认的
	SetBinding("F12","REPLY")
	SetBinding("F11","REPLY2")
	SetBinding("F9","TOGGLEAUTORUN")
	SetBinding("A","STRAFELEFT")
	SetBinding("D","STRAFERIGHT")
end

--删除所有宏
local function UIcfg()
	for i = 1,9999 do 
		local t=10000-i
		DeleteMacro(t)   --删除所有宏
	end 
end 

-----删除宏和按键
StaticPopupDialogs.SC_MACRO = { 
        text = "你确定要删除所有宏并恢复默认按键？", 
        button1 = ACCEPT, 
        button2 = CANCEL, 
		--功能调用
        OnAccept =  function() Bindings(); UIcfg() end, 
        timeout = 0, 
        whileDead = 1, 
        hideOnEscape = true, 
        preferredIndex = 5, 
}
--斜杠线命令
SLASH_SCMACRO1 = "/sc" 
SLASH_SCMACRO2 = "/SC" 
SlashCmdList["SCMACRO"] = function() 
        StaticPopup_Show("SC_MACRO") 
end
-----删除宏
StaticPopupDialogs.SH_MACROO = { 
        text = "你确定要删除所有宏？", 
        button1 = ACCEPT, 
        button2 = CANCEL, 
		--功能调用
        OnAccept =  function() UIcfg() end, 
        timeout = 0, 
        whileDead = 1, 
        hideOnEscape = true, 
        preferredIndex = 5, 
}
--斜杠线命令
SLASH_SHMACROO1 = "/sh" 
SLASH_SHMACROO2 = "/SH" 
SlashCmdList["SHMACROO"] = function() 
        StaticPopup_Show("SH_MACROO") 
end