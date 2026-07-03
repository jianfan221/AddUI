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
-- SCV：备份原始值 + 设置 CVar（仅首次备份，后续添加只需改这一处）
local function SCV(name, value)
	if not AddUIDB.MYCVAR then AddUIDB.MYCVAR = {} end
	if AddUIDB.MYCVAR[name] == nil then
		AddUIDB.MYCVAR[name] = GetCVar(name)
	end
	C_CVar.SetCVar(name, value)
end
-- SCVS：备份原始值 + 设置 Settings（同上）
local function SCVS(name, value)
	if not AddUIDB.MYCVAR then AddUIDB.MYCVAR = {} end
	if AddUIDB.MYCVAR[name] == nil then
		AddUIDB.MYCVAR[name] = tostring(Settings.GetValue(name))
	end
	Settings.SetValue(name, value)
end

local function uiconfig()

	--恢复默认
	--InterfaceOptionsFrame_SetAllToDefaults()
--其他
SCV("UnitNamePlayerPVPTitle", 1)	--头衔
SCV("UnitNamePlayerGuild",1)	--公会名
SCV("UnitNameGuildTitle", 1)	--公会会阶
SCV("chatStyle","im")	--聊天风格-即时通讯风格"classic","im"
if AddUIDB.MYCVAR["C_Container.SetSortBagsRightToLeft"] == nil then AddUIDB.MYCVAR["C_Container.SetSortBagsRightToLeft"] = C_Container.GetSortBagsRightToLeft() end
C_Container.SetSortBagsRightToLeft(true)	--正序整理背包，反序改成false
if AddUIDB.MYCVAR["C_Container.SetInsertItemsLeftToRight"] == nil then AddUIDB.MYCVAR["C_Container.SetInsertItemsLeftToRight"] = C_Container.GetInsertItemsLeftToRight() end
C_Container.SetInsertItemsLeftToRight(true)	--新物品放在最右侧背包，左侧改成false
SCV("floatingCombatTextCombatDamageDirectionalScale_v2", 0)--伤害数字显示在血条上方,改数字0123456789
SCV("WorldTextScale_v2", 2)								--战斗伤害字体大小
SCV("floatingCombatTextCombatDamage_v2", 1)				--显示伤害数字
SCV("floatingCombatTextCombatHealing_v2", 1)			--显示治疗数字
SCV("enableFloatingCombatText",  0)						--滚动战斗记录
SCV("floatingCombatTextFloatMode",  1)					--滚动方向
SCV("floatingCombatTextAuras", 0)  						--光环
SCV("floatingCombatTextComboPoints", 0) 				--連擊點 
SCV("floatingCombatTextEnergyGains", 0) 				--資源獲得(法力、怒氣、能量、真氣，和連擊點不同) 
SCV("floatingCombatTextPeriodicEnergyGains", 0)   		--周期性能量   
SCV("floatingCombatTextHonorGains", 1)   				--榮譽擊殺 
SCV("floatingCombatTextRepChanges", 0)   				--聲望變化
SCV("floatingCombatTextPetMeleeDamage", 1)   			--普攻 
SCV("floatingCombatTextPetSpellDamage", 1)  			--技能 
SCV("floatingCombatTextCombatHealingAbsorbTarget", 1)	--對目標上盾/護甲提示 
SCV("floatingCombatTextCombatHealingAbsorbSelf", 1) 	--自身得盾/護甲提示 
SCV("floatingCombatTextCombatDamageAllAutos", 1) 	  	--顯示所有的白字 
SCV("floatingCombatTextDodgeParryMiss", 1)   			--閃招 
SCV("floatingCombatTextDamageReduction", 1)  			--傷害減免/抵抗 
SCV("floatingCombatTextCombatLogPeriodicSpells", 1) 	--周期性傷害 
SCV("floatingCombatTextReactives", 1)   				--法術警示 
SCV("floatingCombatTextSpellMechanics", 0)				--顯示目標受到的糾纏效果，(例如 誘補(xxxx-xxxx)，沉默緩速之類) 
SCV("floatingCombatTextSpellMechanicsOther", 0)  		--顯示其他玩家受到的糾纏效果 
SCV("floatingCombatTextCombatState", 0)   				--進入/離開戰鬥文字提示 
SCV("floatingCombatTextLowManaHealth", 0)   			--低MP/低HP文字提示 
SCV("floatingCombatTextFriendlyHealers", 0)   			--友方治療者名稱 


SCV("xpBarText", 1) --经验条
SCV("statusText",1) --状态文字


--时钟
	SCV("timeMgrAlarmEnabled",0) --关闭时钟提醒
	SCV("timeMgrUseMilitaryTime",1)	--24小时模式
	SCV("timeMgrUseLocalTime",1)	--使用本地时间

--控制
	SCV("deselectOnClick",0) --目标锁定
    SCV("autoDismountFlying",1) --自动取消飞行
	SCV("autoClearAFK",1) --自动解除离开状态
	SCV("interactOnLeftClick",1) --左键点击操作
	SCV("lootUnderMouse",1) --鼠标位置打开拾取框
	SCV("autoLootDefault",1) --自动拾取
	SCV("combinedBags",1)	--组合背包
	--镜头
	SCV("cameraWaterCollision",0)--水体碰撞
    SCV("cameraSmoothStyle",0) --镜头跟随模式
	SCV("SoftTargetInteract",3)--开启交互键
--界面
	--显示
	SCV("hideAdventureJournalAlerts","none")	--隐藏冒险指南
	SCV("showTutorials",0)
	SCV("statusText",1) --状态文字
    SCV("statusTextDisplay","NUMERIC")--头像状态文字形式："NUMERIC"数值"PERCENT"百分比"BOTH"同时显示
	SCV("chatBubbles",1)--聊天泡泡
	SCV("chatBubblesParty",1)--小队聊天泡泡
	SCV("chatBubblesRaid",1)--团队聊天泡泡
	--团队界面配置
	SCV("useCompactPartyFrames",1) --使用团队风格的小队框体界面
	SCV("raidFramesDisplayPowerBars",1)	--显示能量条
	SCV("raidFramesDisplayOnlyHealerPowerBars",0)	--只显示治疗能量条
	SCV("raidFramesDisplayIncomingHeals",1)	--预计治疗
	SCV("raidFramesDisplayAggroHighlight",1)	--高亮仇恨目标
	SCV("raidFramesDisplayClassColor",1)	--职业颜色
	SCV("raidOptionDisplayPets",0)	--显示宠物
	SCV("raidOptionDisplayMainTankAndAssist",0)	--主坦克主助理
	SCV("raidFramesDisplayDebuffs",1)	--显示负面效果
	SCV("raidFramesDisplayLargerRoleSpecificDebuffs",1)--放大职责减益
	SCV("raidFramesDisplayOnlyDispellableDebuffs",0)	--只显示可供驱散的负面效果
	SCV("raidFramesDisplayBigDefensive",1)--重要防御技能居中
	SCV("raidFramesDispellndicatorType",2)--可驱散减益指示器
	SCV("raidFramesDispellndicatorOverlay",0)--可驱散减益颜色
	SCV("raidFramesHealthText","none")	--生命值
	SCV("pvpFramesDisplayPowerBars",1)	--竞技场对手框能量条
	SCV("pvpFramesDisplayOnlyHealerPowerBars",0)	--竞技场对手框仅显示治疗能量条
	SCV("pvpFramesDisplayClassColor",1)	--竞技场对手框能量条
	
--动作条
    --SHOW_MULTI_ACTIONBAR_1="1" --左下方动作条
    --SHOW_MULTI_ACTIONBAR_2="0" --右下方动作条
	--SHOW_MULTI_ACTIONBAR_3="1" --右侧右边动作条
	--SHOW_MULTI_ACTIONBAR_4="1" --右侧左边动作条
	-- 显示动作条2-5
   --local bar1, bar2, bar3, bar4, _, _, _ = GetActionBarToggles()
   --if (not bar1 or not bar2 or not bar3 or not bar4) then
		--Settings.SetValue("PROXY_SHOW_ACTIONBAR_1", true)
        SCVS("PROXY_SHOW_ACTIONBAR_2", true)
        SCVS("PROXY_SHOW_ACTIONBAR_3", false)
        SCVS("PROXY_SHOW_ACTIONBAR_4", true)
        SCVS("PROXY_SHOW_ACTIONBAR_5", true)
		SCVS("PROXY_SHOW_ACTIONBAR_6", false)
		SCVS("PROXY_SHOW_ACTIONBAR_7", false)
		SCVS("PROXY_SHOW_ACTIONBAR_8", false)
    --end
	--刷新动作条
	--MultiActionBar_Update()
    --StatusTrackingBarManager:UpdateBarTicks()
    --EventRegistry:TriggerEvent("ActionBarShownSettingUpdated")
	
	SCV("lockActionBars",1)--锁定动作条
	
	SCV("alwaysShowActionBars",1)--始终显示动作条
    SCV("countdownForCooldowns",1) --显示冷却时间


--战斗
	SCV("nameplateShowSelf",1) --显示个人资源
	SCV("nameplateResourceOnTarget",0) --在敌方目标显示玩家资源
    SCV("showTargetOfTarget",1) --目标的目标
    SCV("doNotFlashLowHealthWarning",1) --生命值过低时不闪烁屏幕
    SCV("lossOfControl",1) --失控警报
	SCV("enableFloatingCombatText",  0)	--滚动战斗记录
	SCV("enableMouseoverCast", 1)--鼠标悬停施法
	SCV("autoSelfCast",1) --自动自我施法


--社交
    SCV("profanityFilter",0) --语言过滤器
    SCV("spamFilter",0) --垃圾信息过滤
    SCV("guildMemberNotify",0) --公会成员提示
    SCV("showToastBroadcast",1) --通告更新
    SCV("showToastWindow",0) --显示浮窗
    SCV("showTimestamps","none") --聊天时间戳
	SCV("whisperMode","inline")	--新的悄悄话
--信号
	SCV("enablePings",1)	--开启信号
	
--游戏增强
	SCV("combatWarningsEnabled",1)	--首领警报
	SCV("encounterWarningsEnabled",1)--文字警报
	SCV("encounterTimelineEnabled",1)--首领时间轴
	SCV("encounterTimelinelocnographyEnabled",1)--法术辅助图标
	SCV("cooldownViewerEnabled",1)--冷却管理器
	SCV("externalDefensivesEnabled",1)--外部防御技能
	SCV("damageMeterEnabled", 1)--伤害统计
	SCV("spellDiminishPVPEnemiesEnabled",1)--收益递减追踪
	
--姓名版
	SCV("UnitNameOwn",1) --我的名字
	SCV("UnitNameFriendlySpecialNPCName", 0);
	SCV("UnitNameHostleNPC", 0);
	SCV("UnitNameInteractiveNPC", 0);
	SCV("UnitNameNPC", 1);
	SCV("ShowQuestUnitCircles", 1);
	SCV("UnitNameNonCombatCreatureName",1) --小动物小伙伴
	SCV("UnitNameFriendlyPlayerName",1) --友方玩家
	SCV("UnitNameFriendlyMinionName",0) --友方玩家仆从
	SCV("UnitNameEnemyPlayerName",1) --敌对玩家
	SCV("UnitNameEnemyMinionName",1) --敌对玩家仆从
	SCV("nameplateShowFriends",0) --友方玩家血条
	SCV("nameplateShowFriendlyMinions",0) --友方玩家仆从血条
	SCV("nameplateShowEnemies",1) --敌对玩家血条
	SCV("nameplateShowEnemyMinions",1) --敌对玩家仆从血条
	SCV("nameplateShowEnemyMinus",1) --敌对玩家杂兵血条
	SCV("nameplateShowAll",1) --显示所有姓名版
	SCV("nameplateShowFriendlyNpcs",1) --友方NPC姓名版
	SCV("nameplateShowOffscreen",1) --屏幕外姓名版
	SCV("nameplateInfoDisplay","D") --姓名版信息
	SCV("nameplateCastBarDisplay","O") --施法条信息
	SCV("nameplateThreatDisplay","B") --仇恨显示
	SCV("nameplateEnemyNpcAuraDisplay","G") --敌方NPC减益状态
	SCV("nameplateEnemyPlayerAuraDisplay","G") --敌方玩家减益状态
	SCV("nameplateFriendlyPlayerAuraDisplay","G") --友方玩家减益状态
	SCV("nameplateSimplifiedTypes","") --简化姓名版
	
    --NamePlateDriverFrame:UpdateNamePlateOptions() 
--综合
	SCV("WorldTextMinSize",12)	--名字尺寸
	SCV("CameraKeepCharacterCentered",0)	--动态眩晕
	SCV("CameraReduceUnexpectedMovement",1)	--动态眩晕
	SCV("ShakeStrengthCamera",0)	--视角晃动
	SCV("ShakeStrengthUI",0)	--视角晃动
	SCV("empowerTapControls",1)	--蓄力法术
	SCV("spellActivationOverlayOpacity",0.6)	--法术警报不透明度
--色盲模式
	SCV("colorblindMode",0)
	
--易用性
    SCV("speechToText",0)	--语音转文本
	SCV("textToSpeech",0)	--文本转语音
	SCV("remoteTextToSpeech",0)	--在语音聊天中为我发言
--坐骑
	SCV("motionSicknessLandscapeDarkening",0)	--晕动症
	SCV("DisableAdvancedFlyingFullScreenEffects",1)	--动态飞行屏幕效果
	SCV("DisableAdvancedFlyingVelocityVFX",1)	--动态飞行速度效果
	SCV("advFlyPitchControl",3)				--仰角控制
	SCV("advFlyPitchControlGroundDebounce",1)	--防抖倾角输入
--系统相关
--图形
	SCV("useUiScale", 1)	--启用UI缩放
	SCV("uiScale", 0.75)	--UI缩放
	SCV("cameraFov", 90)	--镜头视野范围
--音频
	SCV("Sound_MasterVolume", 0.3)	--主音量
	SCV("Sound_MusicVolume", 0)	--音乐
	SCV("Sound_SFXVolume", 0.25)	--效果
	SCV("Sound_AmbienceVolume", 0.1)	--环境音
	SCV("Sound_DialogVolume", 0.5)	--对话
	SCV("Sound_EnableErrorSpeech", 0)	--错误提示音
	SCV("Sound_EnableSoundWhenGameIsInBG", 1)	--背景声音

print("|cff00BFFFAddUI:|r已设置界面配置,/sdold可以恢复之前的设定")
end
--SetCVar("",)

--界面自动化命令 
SlashCmdList["UICONFIGG"] = function() uiconfig() end 
SLASH_UICONFIGG1 = "/sd"
SLASH_UICONFIGG2 = "/sdd"

--从备份恢复 CVar
local function restoreCVar()
	if not AddUIDB.MYCVAR or not next(AddUIDB.MYCVAR) then
		print("|cffff5900没有已保存的CVar备份")
		return
	end
	local count = 0
	for name, value in pairs(AddUIDB.MYCVAR) do
		if name:find("^PROXY_") then
			-- Settings 值，转换回布尔类型
			local boolVal = value == "true" or value == "1"
			Settings.SetValue(name, boolVal)
		elseif name:find("^C_Container") then
			-- C_Container 方法调用
			local method = name:match("%.([^.]+)$")
			if method and C_Container[method] then
				C_Container[method](value)
			end
		else
			C_CVar.SetCVar(name, value)
		end
		count = count + 1
	end
	print("|cff00BFFFAddUI:|r已恢复"..count.."个CVar设置")
end
SlashCmdList["RESTORECVAR"] = function() restoreCVar() end
SLASH_RESTORECVAR1 = "/sdold"

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