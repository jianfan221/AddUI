local _,ns = ...
if 1 == 1 then return end
ns.tips("系统设置(Esc选项) 账号共享设置")

-- ================= 系统设置(Esc→选项)CVar 清单 =================
-- 来源：暴雪 wow-ui-source（live/12.x）Blizzard_SettingsDefinitions_Shared / _Frame 各面板注册代码
-- 功能（同 PlateColor.lua 的暴雪姓名板 CVar 备份/恢复模式）：
--   - 登录时：若存档(AddUIDB.EscCvar)已有 → 应用到游戏；无存档 → 存入当前取值。
--   - CVar 变更时自动同步到存档，保持存档一致。
-- 说明：普通 CVar 用 C_CVar.GetCVar 读原始字符串存储，恢复时 SetCVar 原样写回。
--       动作条显隐(PROXY_SHOW_ACTIONBAR_*)为 Settings 代理值，单独用 Settings 备份/恢复。
--       其余代理设置(PROXY_*)由多个底层 CVar/API 组合，不参与自动备份恢复（见文末说明）。

-- ===== 界面(Interface) =====
local EscCvarList = {
	--显示
	"showInGameNavigation",                          --游戏内导航
	"showTutorials",                                 --新手教程
	"Outline",                                       --NPC轮廓
	"ReplaceOtherPlayerPortraits",                   --其他玩家头像
	"ReplaceMyPlayerPortrait",                       --我的头像
	"chatBubbles",                                   --聊天泡泡
	"chatBubblesParty",                              --小队聊天泡泡
	"chatBubblesRaid",                               --团队聊天泡泡
	--团队界面
	"raidFramesDisplayIncomingHeals",                --预计治疗
	"raidFramesDisplayPowerBars",                    --显示能量条
	"raidFramesDisplayOnlyHealerPowerBars",          --只显示治疗能量条
	"raidFramesDisplayAggroHighlight",               --高亮仇恨目标
	"raidFramesDisplayClassColor",                   --职业颜色
	"raidFramesHealthBarColor",                      --生命条颜色(色板)
	"raidFramesHealthBarColorBG",                    --生命条背景颜色(色板)
	"raidOptionDisplayPets",                         --显示宠物
	"raidOptionDisplayMainTankAndAssist",            --主坦克主助理
	"raidFramesDisplayDebuffs",                      --显示负面效果
	"raidFramesDisplayLargerRoleSpecificDebuffs",    --放大职责减益
	"raidFramesDisplayOnlyDispellableDebuffs",       --只显示可驱散减益
	"raidFramesCenterBigDefensive",                  --重要防御技能居中
	"raidFramesDispelIndicatorType",                 --可驱散减益指示器
	"raidFramesHealthText",                          --生命值文本
	"pvpFramesDisplayPowerBars",                     --竞技场对手框能量条
	"pvpFramesDisplayOnlyHealerPowerBars",           --竞技场对手框仅显示治疗能量条
	"pvpFramesDisplayClassColor",                    --竞技场对手框职业颜色
	"pvpOptionDisplayPets",                          --竞技场对手框显示宠物
	"worldMapShowPlayerCoords",                      --世界地图显示玩家坐标
	"worldMapShowCursorCoords",                      --世界地图显示光标坐标

	-- ===== 游戏(Gameplay) =====
	--控制
	"deselectOnClick",                               --取消选择
	"autoDismountFlying",                            --自动取消飞行
	"autoClearAFK",                                  --自动解除离开状态
	"interactOnLeftClick",                           --左键点击操作
	"lootUnderMouse",                                --鼠标位置打开拾取框
	"autoLootDefault",                               --自动拾取
	"combinedBags",                                  --组合背包
	"softTargettingInteractKeySound",                --交互键音效
	"ClipCursor",                                    --限制鼠标光标
	"mouseInvertPitch",                              --反转俯仰
	"enableMouseSpeed",                              --启用鼠标速度
	"mouseSpeed",                                    --鼠标速度
	"autointeract",                                  --自动交互
	"cameraSmoothTrackingStyle",                     --镜头跟随模式
	"cameraWaterCollision",                          --水体碰撞
	--动作条
	"lockActionBars",                                --锁定动作条
	"countdownForCooldowns",                         --显示冷却时间
	--战斗
	"nameplateShowSelf",                             --显示个人资源
	"showTargetOfTarget",                            --目标的目标
	"doNotFlashLowHealthWarning",                    --低血量不闪屏
	"lossOfControl",                                 --失控警报
	"enableFloatingCombatText",                      --滚动战斗记录
	"occludedSilhouettePlayer",                      --遮挡玩家轮廓
	"enableMouseoverCast",                           --鼠标悬停施法
	"ActionButtonUseKeyHeldSpell",                   --按住按键施法
	--战斗警报/冷却/递减
	"assistedCombatReduceHighlights",                --辅助战斗减弱高亮
	"assistedCombatHighlight",                       --辅助战斗高亮
	"encounterWarningsLevel",                        --首领警报等级
	"encounterWarningsHideIfNotTargetingPlayer",     --非目标隐藏首领警报
	"encounterTimelineHideForOtherRoles",            --隐藏其他职责时间轴
	"cooldownViewerEnabled",                         --冷却管理器
	"spellDiminishPVPEnemiesEnabled",                --收益递减追踪
	"spellDiminishPVPOnlyTriggerableByMe",           --仅我的递减触发
	--姓名板
	"UnitNameOwn",                                   --我的名字
	"UnitNameNonCombatCreatureName",                 --非战斗生物名
	"UnitNameFriendlyPlayerName",                    --友方玩家名
	"UnitNameFriendlyPlayerMinions",                 --友方玩家随从名
	"UnitNameFriendlyPlayerGuardians",               --友方玩家守卫名
	"UnitNameFriendlyPlayerTotems",                  --友方玩家图腾名
	"nameplateShowAll",                              --始终显示姓名板
	"nameplateShowEnemies",                          --敌方单位
	"nameplateShowEnemyMinions",                     --敌方随从
	"nameplateShowEnemyMinus",                       --敌方次级单位
	"nameplateShowFriendlyNpcs",                     --友方NPC
	"nameplateShowFriendlyPlayers",                  --友方玩家
	"nameplateShowOnlyNameForFriendlyPlayerUnits",   --友方玩家仅显示名字
	"nameplateUseClassColorForFriendlyPlayerUnitNames", --友方玩家名字职业颜色
	"nameplateShowFriendlyRealmName",                --友方玩家显示服务器名
	"nameplateShowOffscreen",                        --显示屏外姓名板
	"nameplateSize",                                 --姓名板全局缩放
	"nameplateAuraScale",                            --光环缩放
	"nameplateDebuffPadding",                        --减益图标间距
	--社交
	"profanityFilter",                               --语言过滤器
	"guildMemberNotify",                             --公会成员提示
	"blockTrades",                                   --屏蔽交易
	"restrictCalendarInvites",                       --限制日历邀请
	"blockChannelInvites",                           --屏蔽频道邀请
	"showToastOnline",                               --上线提示
	"showToastOffline",                              --下线提示
	"showToastBroadcast",                            --通告更新
	"showToastFriendRequest",                        --好友请求提示
	"showToastWindow",                               --显示浮窗
	"autoAcceptQuickJoinRequests",                   --自动接受快速加入
	"chatStyle",                                     --聊天风格
	"showTimestamps",                                --聊天时间戳
	"discordDisplayName",                            --Discord显示名
	"enableConnectToPhotoSharing",                   --照片分享
	--信号
	"enablePings",                                   --开启信号
	"pingMode",                                      --信号模式
	"pingTarget",                                    --信号目标
	"showPingsInChat",                               --聊天显示信号
	"showPingsOnRaidFrames",                         --团队框显示信号
	--坐骑
	"DisableAdvancedFlyingFullScreenEffects",        --动态飞行屏幕效果
	"DisableAdvancedFlyingVelocityVFX",              --动态飞行速度效果
	"advFlyPitchControlGroundDebounce",              --防抖倾角输入
	"advFlyPitchControlCameraChase",                 --跟随镜头
	"advFlyKeyboardMinPitchFactor",                  --键盘最小俯仰
	"advFlyKeyboardMaxPitchFactor",                  --键盘最大俯仰
	"advFlyKeyboardMinTurnFactor",                   --键盘最小转向
	"advFlyKeyboardMaxTurnFactor",                   --键盘最大转向
	--易用性
	"enableMovePad",                                 --移动摇杆
	"overrideScreenFlash",                           --覆盖屏幕闪烁
	"cursorSizePreferred",                           --光标尺寸
	"arachnophobiaMode",                             --蜘蛛恐惧模式
	--色盲
	"colorblindMode",                                --色盲模式
	"colorblindSimulator",                           --色盲滤镜
	"colorblindWeaknessFactor",                      --色盲强度

	-- ===== 系统(System) =====
	--声音
	"Sound_EnableAllSound",                          --启用声音
	"Sound_OutputDriverIndex",                       --音频输出设备
	"Sound_MasterVolume",                            --主音量
	"Sound_MusicVolume",                             --音乐
	"Sound_SFXVolume",                               --效果
	"Sound_AmbienceVolume",                          --环境音
	"Sound_DialogVolume",                            --对话
	"Sound_EnableMusic",                             --音乐开关
	"Sound_ZoneMusicNoDelay",                        --区域音乐无延迟
	"Sound_EnablePetBattleMusic",                    --宠物对战音乐
	"Sound_EnableSFX",                               --音效开关
	"Sound_EnablePetSounds",                         --宠物音效
	"Sound_EnableEmoteSounds",                       --表情音效
	"Sound_EnableDialog",                            --对话开关
	"Sound_EnableErrorSpeech",                       --错误提示音
	"Sound_EnableAmbience",                          --环境音开关
	"Sound_EnableSoundWhenGameIsInBG",               --后台声音
	"Sound_EnableReverb",                            --混响
	"Sound_EnablePositionalLowPassFilter",           --定位低通滤波
	"Sound_NumChannels",                             --声道数
	"Sound_MaxCacheSizeInBytes",                     --声音缓存大小
	"Sound_EnablePingSounds",                        --信号音效
	"Sound_PingVolume",                              --信号音量
	"Sound_EnableEncounterWarningsSounds",           --首领警报音效
	"Sound_EncounterWarningsVolume",                 --首领警报音量
	"Sound_EnableGameplaySFX",                       --游戏内音效
	"Sound_GameplaySFX",                             --游戏内音效音量
	--语音(辅助功能)
	"accessibilityScreenNarrationEnabled",           --屏幕朗读
	"accessibilityScreenNarrationVoice",             --朗读语音
	"accessibilityScreenNarrationSpeechRate",        --朗读语速
	"speechToText",                                  --语音转文本
	"textToSpeech",                                  --文本转语音
	"CAAEnabled",                                    --语音助手
	"CAAVoice",                                      --语音助手音色
	"CAASpeed",                                      --语音助手语速
	"CAAVolume",                                     --语音助手音量
	"CAASayCombatStart",                             --开始战斗播报
	"CAASayCombatEnd",                               --结束战斗播报
	"CAAPlayerHealthPercent",                        --玩家血量播报
	"CAAPlayerHealthFormat",                         --血量格式
	"CAASayTargetName",                              --目标名播报
	"CAATargetHealthPercent",                        --目标血量播报
	"CAATargetDeathBehavior",                        --目标死亡播报
	"CAAInterruptCast",                              --打断播报
	"CAAInterruptCastSuccess",                       --打断成功播报
	"CAASayYourDebuffs",                             --自身减益播报
	"CAASayYourDebuffsVoice",                        --减益播报音色
	"CAASayYourDebuffsMinDuration",                  --减益最小持续时间
	"CAAPlayerCastMinTime",                          --施法最小时间
	"CAAPartyHealthPercent",                         --小队血量播报
	"CAAPartyHealthVoice",                           --小队播报音色
	"CAAPartyHealthFrequency",                       --小队播报频率
	--图形
	"Contrast",                                      --对比度
	"Brightness",                                    --亮度
	"Gamma",                                         --伽马
	"shadowrt",                                      --光线追踪阴影
	"ResampleQuality",                               --重采样质量
	"vrsValar",                                      --可变速率着色
	"LowLatencyMode",                                --低延迟模式
	"textureFilteringMode",                          --纹理过滤
	"msaaAlphaTest",                                 --MSAA透明度
	--网络
	"disableServerNagle",                            --优化网络速度
	"useIPv6",                                       --启用IPV6
	"advancedCombatLogging",                         --高级战斗日志
	--字幕
	"movieSubtitle",                                 --电影字幕
	--语言
	"textLocale",                                    --文本语言
	"audioLocale",                                   --音频语言
	--Mac
	"MacDisableOsShortcuts",                         --禁用系统快捷键
	"MacUseCommandLeftClickAsRightClick",            --Command左键作右键
}

-- CVar 快速查找表（供 CVAR_UPDATE 直接比对，避免循环遍历）
local EscCvarMap = {}
for _, cvar in ipairs(EscCvarList) do
	EscCvarMap[cvar] = true
end

-- ===== 代理设置(PROXY_*)参考 =====
-- 说明：以下设置出现在系统设置面板中，但由多个底层 CVar / C_ API 组合而成，
--       无法按单一 CVar 备份/恢复，故不参与上面的自动备份，仅作参考。
-- 动作条显隐：PROXY_SHOW_ACTIONBAR_2..8（主动作条1无显隐开关；GetActionBarToggles/SetActionBarToggles）
-- 图形质量类：PROXY_GRAPHICS_QUALITY(graphicsQuality)、PROXY_SHADOW_QUALITY(graphicsShadowQuality)、
--   PROXY_LIQUID_DETAIL、PROXY_PARTICLE_DENSITY、PROXY_SSAO、PROXY_DEPTH_EFFECTS、PROXY_COMPUTE_EFFECTS、
--   PROXY_OUTLINE_MODE、PROXY_TEXTURE_RESOLUTION、PROXY_SPELL_DENSITY、PROXY_PROJECTED_TEXTURES、
--   PROXY_VIEW_DISTANCE、PROXY_ENVIRONMENT_DETAIL、PROXY_GROUND_CLUTTER，及 RAID_* 对应系列
-- 图形显示：PROXY_USE_UI_SCALE(useUiScale)、PROXY_UI_SCALE(uiscale)、PROXY_CAMERA_FOV(cameraFov)、
--   PROXY_VERTICAL_SYNC(vsync)、PROXY_FXAA、PROXY_MSAA、PROXY_DISPLAY_MODE、PROXY_RESOLUTION、
--   PROXY_RESOLUTION_RENDER_SCALE(RenderScale)、PROXY_PRIMARY_MONITOR、PROXY_GX_ADAPTER、
--   PROXY_TRIPLE_BUFFERING、PROXY_TARGET_FPS、PROXY_FOREGROUND_FPS、PROXY_BACKGROUND_FPS
-- 字幕背景：PROXY_MOVIE_SUBTITLE_BACKGROUND、PROXY_MOVIE_SUBTITLE_BACKGROUND_ALPHA
-- 文本：PROXY_ACCESSIBILITY_FONT_SIZE(userFontScale)、PROXY_QUEST_TEXT_CONTRAST
-- 易用性：PROXY_MINIMUM_CHARACTER_NAME_SIZE(WorldTextMinSize)、PROXY_SICKNESS(CameraKeepCharacterCentered/
--   CameraReduceUnexpectedMovement)、PROXY_SICKNESS_SHAKE(ShakeStrengthCamera/ShakeStrengthUI)、
--   PROXY_TARGET_TOOLTIP、PROXY_INTERACT_ICONS
-- 战斗：PROXY_SELF_HIGHLIGHT(findYourselfAnywhere/findYourselfMode*)
-- 语音聊天：PROXY_VOICE_INPUT_DEVICE/OUTPUT_DEVICE/VOLUME、PROXY_VOICE_DUCKING、PROXY_VOICE_CHAT_MODE（底层 C_VoiceChat）
-- 语音助手：PROXY_CAA_*（底层 C_CombatAudioAlert 存储，非 CVar）
-- 时间轴图标：ENCOUNTER_TIMELINE_ICONOGRAPHY_SETS（位掩码）

-- ================= 备份 / 恢复 =================
local function GetCvarValue(cvar)
	return C_CVar.GetCVar(cvar)
end

-- 把存档应用到游戏（普通 CVar）
local function ApplyAll()
	local s = AddUIDB.EscCvar
	if not s then return end
	for _, cvar in ipairs(EscCvarList) do
		local val = s[cvar]
		if val ~= nil then
			local cur = GetCvarValue(cvar)
			if cur == nil then
				-- 当前 CVar 已被移除：清除存档残留
				s[cvar] = nil
			elseif cur ~= val then
				C_CVar.SetCVar(cvar, val)
			end
		end
	end
end

-- 把当前取值存入存档（普通 CVar）
local function SaveAll()
	local s = AddUIDB.EscCvar
	if not s then return end
	for _, cvar in ipairs(EscCvarList) do
		local val = GetCvarValue(cvar)
		if val ~= nil then
			s[cvar] = val
		end
	end
end

-- CVar 变更同步到存档（用 map 直接比对，无需循环）
ns.event("CVAR_UPDATE", function(_, msg, value)
	if not AddUIDB.EscCvar or not EscCvarMap[msg] then return end
	if value ~= nil then
		AddUIDB.EscCvar[msg] = value
	end
end)

-- 登录时：先恢复已有存档，再补存缺失（战斗中则脱战后执行）
ns.event("PLAYER_ENTERING_WORLD", function()
	AddUIDB.EscCvar = AddUIDB.EscCvar or {}
	ns.COMBAT(function()
		ApplyAll()  -- 先恢复已存储的 CVar
		SaveAll()   -- 再补存缺失的 CVar
	end)
end)

-- ================================================================
-- 动作条显隐（Settings 代理值，非 CVar，用 Settings.GetValue/SetValue 备份/恢复）
-- 注：主动作条(1)始终显示，无显隐开关，暴雪仅提供 PROXY_SHOW_ACTIONBAR_2..8
-- 需在 SETTINGS_LOADED（设置注册完成后）才可 SetValue，否则报 "did not exist"
-- ================================================================
local EscActionBarList = {
	"PROXY_SHOW_ACTIONBAR_2",   --动作条2
	"PROXY_SHOW_ACTIONBAR_3",   --动作条3
	"PROXY_SHOW_ACTIONBAR_4",   --动作条4
	"PROXY_SHOW_ACTIONBAR_5",   --动作条5
	"PROXY_SHOW_ACTIONBAR_6",   --动作条6
	"PROXY_SHOW_ACTIONBAR_7",   --动作条7
	"PROXY_SHOW_ACTIONBAR_8",   --动作条8
}

-- 把存档应用到游戏（动作条显隐）
local function ApplyActionBars()
	local s = AddUIDB.EscCvar
	if not s then return end
	for _, name in ipairs(EscActionBarList) do
		if s[name] ~= nil then
			Settings.SetValue(name, s[name] == "true")
		end
	end
end

-- 把当前取值存入存档（动作条显隐）
local function SaveActionBars()
	local s = AddUIDB.EscCvar
	if not s then return end
	for _, name in ipairs(EscActionBarList) do
		s[name] = tostring(Settings.GetValue(name))
	end
end

-- 动作条显隐（Settings 代理值）变更同步到存档
for _, name in ipairs(EscActionBarList) do
	Settings.SetOnValueChangedCallback(name, function(_, _, value)
		if AddUIDB.EscCvar then
			AddUIDB.EscCvar[name] = tostring(value)
		end
	end)
end

-- 动作条显隐需等 SETTINGS_LOADED（设置注册完成后）才能备份/恢复
ns.event("SETTINGS_LOADED", function()
	if not AddUIDB.EscCvar then return end
	ApplyActionBars()  -- 先恢复已存储的动作条显隐
	SaveActionBars()   -- 再补存当前动作条显隐
end)
