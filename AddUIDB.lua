local AddonName,ns = ...
ns.ADDUIBB = C_AddOns.GetAddOnMetadata(AddonName,"Version")
ns.AddUIDefaultDB = {
	Gname = nil, -- 存放插件名（内部字段）

	-- 第一列（界面选项顺序）
	unitf = true, -- 头像模块
	unitbt = true, -- 头像buff
	mmb = true, -- 动作条模块
	mmba = true, -- 禁用动作条额外动画
	syd = true, -- 角色面板耐久
	smap = true, -- 小地图模块
	smapicon = true, -- 小地图图标
	chatm = true, -- 聊天窗模块
	chatb = true, -- 聊天频道按钮
	raidframebuff = true, -- 团队框架相关
	mh = true, -- 自动卖灰
	sq = true, -- 快速拾取
	cast = true, -- 施法条模块
	nameplatecast = false, -- 周围怪物施法监控（默认关闭）
	castWidth = 260, -- 施法条宽度
	castHeight = 20, -- 施法条高度
	SCastTexture = true, -- 自定义施法条材质
	CastTexture = "Rainbow", -- 材质选择（默认为 Rainbow）

	-- 第二列（界面选项顺序）	
	comb = true, -- 进入战斗提示
	zu = true, -- 密语自动邀请
	lfgkg = true, -- LFG增强
	Friend = false, -- 好友列表搜索
	stat = true, -- 自身属性框体
	itembuff = true, -- 伪饰品BUFF监控
	cdset = true, -- 冷却管理器美化
	cdcenter = true, -- 冷却管理器居中对齐
	MDRedamage = true, -- 大秘境开始重置伤害统计
	setdama = true, -- 伤害统计样式美化
	poidama = true, -- 伤害统计自动对齐
	valueda = true, -- 伤害统计数值简化

	-- 第三列（界面选项顺序）
	cvar = true, -- CVAR自动设置
	dimi = true, -- 右下角信息栏
	lotbnt = true, -- Log快捷开关
	chatCombatTimer = true, -- 聊天框战斗计时器
	autoloot = true, -- 装备一键选择器

	-- 其他辅助功能（未在界面中直接暴露）
	dbm = true, -- DBM相关
	exrt = true, -- ExRT相关
	skada = true, -- Skada相关
	tiny = true, -- TinyDPS相关
	ui = true, -- 系统UI增强
	chat = true, -- 聊天增强
	jbtext = true, -- 职业条文本
	SAT = 10, -- 通用延迟设置
	icon = true, -- 图标模块
	ct = true, -- 计时条模块
	ctp = false, -- 计时条插件选项
	quest = true, -- 任务相关
	minimb = true, -- 小地图迷你按钮
	chatp = true, -- 聊天浮动面板
	stop = true, -- 停止指示器
	sf = true, -- 额外功能开关
	lfgautoinv = true, -- LFG自动邀请
	debuff = false, -- 目标减益显示
	buffcall = true, -- BUFF提醒
	iconcall = true, -- 图标提醒
	sayfocus = false, -- 关注说话

	-- 其他设置
	ftip = 1, -- 鼠标提示跟随方式
	SpellQ = 200, -- 施法序列延迟
	hpUnits = 1, -- 单位数量
	value = 3, -- 数值单位
	DungeonBossKill = {}, -- 地城BOSS击杀时间记录（保留，不随“恢复默认”清除）
	AutoQuestCheck = false,--自动交接
	QuestCheck = true, -- 任务进度通报

	-- 
	AutoLog = false, --大秘境自动开启战斗记录
	AHFavoritesDB = {}, -- 拍卖行收藏夹
	AHFilterRestoreDB = {}, -- 拍卖行筛选恢复
	CooldownDate = {}, -- 冷却管理器布局存储
	OpenTalentScale = false, -- 天赋界面小窗缩放
}

ns.CastBarTextrue = {
	["Rainbow"] = "Interface\\Addons\\AddUI\\UI\\Textures\\colorbar.tga",
	["Class-EvokerEbon"] = "Unit_Evoker_EbonMight_Fill",
	["Class-DemonHunter"] = "Unit_DemonHunter_Fury_Fill",
	["Class-Priest"] = "Unit_Priest_Insanity_Fill",
	["Class-Druid"] = "Unit_Druid_AstralPower_Fill",
	["Class-Shaman"] = "Unit_Shaman_Maelstrom_Fill",
	["Class-MonkGreen"] = "Unit_Monk_Stagger_Fill_Green",
	["Class-MonkYellow"] = "Unit_Monk_Stagger_Fill_Yellow",
	["Class-MonkRed"] = "Unit_Monk_Stagger_Fill_Red",

	["!Rurutia01"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\!Rurutia01.tga",
	["!Rurutia02"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\!Rurutia02.tga",
	["!Rurutia03"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\!Rurutia03.tga",
	["!Rurutia04"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\!Rurutia04.tga",
	["!Rurutia05"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\!Rurutia05.tga",
	["!Rurutia06"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\!Rurutia06.tga",
	["!Rurutia07"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\!Rurutia07.tga",
	["!Rurutia08"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\!Rurutia08.tga",
	["!Rurutia09"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\!Rurutia09.tga",
	["!Rurutia10"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\!Rurutia10.tga",
	["!Rurutia11"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\!Rurutia11.tga",
	["!Rurutia12"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\!Rurutia12.tga",
	["!Rurutia13"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\!Rurutia13.tga",
	["!Rurutia14"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\!Rurutia14.tga",
	["!Rurutia15"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\!Rurutia15.tga",
	["!Rurutia16"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\!Rurutia16.tga",
	["!Rurutia17"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\!Rurutia17.tga",
	["!Rurutia18"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\!Rurutia18.tga",
	["!Rurutia19"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\!Rurutia19.tga",
	["!Rurutia20"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\!Rurutia20.tga",
	["!Rurutia21"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\!Rurutia21.tga",
	["!Rurutia22"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\!Rurutia22.tga",
	["!Rurutia23"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\!Rurutia23.tga",
	["!Rurutia24"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\!Rurutia24.tga",
	["!Rurutia25"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\!Rurutia25.tga",
	["!Rurutia26"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\!Rurutia26.tga",
	["!Rurutia27"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\!Rurutia27.tga",
	["!Rurutia28"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\!Rurutia28.tga",
	["!Rurutia29"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\!Rurutia29.tga",
	["BlueDuo"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\BlueDuo.blp",
	["BlueGreeHalf"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\BlueGreeHalf.blp",
	["BlueLavender"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\BlueLavender.blp",
	["BluredRainbow"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\BluredRainbow.blp",
	["MaUI5"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\MaUI5.tga",
	["MaUI6"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\MaUI6.tga",
	["MaUI7"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\MaUI7.tga",
	["Rainbow1"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\Rainbow1.tga",
	["Rainbow2"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\Rainbow2.tga",
	["RedWarning"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\RedWarning.blp",
	["StopLight"] = "Interface\\Addons\\AddUI\\UI\\StatusBar\\StopLight.blp",

	["随机使用材质"] = "",
	--["Hunter"] = "_DemonHunter-DemonicPainBar",
	--["Mana"] = "UI-HUD-UnitFrame-Player-PortraitOff-Bar-Mana",
	--["Rage"] = "UI-HUD-UnitFrame-Player-PortraitOff-Bar-Rage",
	--["Focus"] = "UI-HUD-UnitFrame-Player-PortraitOff-Bar-Focus",
	--["Energy"] = "UI-HUD-UnitFrame-Player-PortraitOff-Bar-Energy",
	--["RunicPower"] = "UI-HUD-UnitFrame-Player-PortraitOff-Bar-RunicPower",
	--["PortraitOn"] = "UI-HUD-UnitFrame-Player-PortraitOn-Bar-TempHPLoss",--斜
}
ns.RerollTextrue = {}
for key in pairs(ns.CastBarTextrue) do
	if key ~= "随机使用材质" then
		table.insert(ns.RerollTextrue, key)
	end
end

----------ONLOAD EVENT---------
local loadFrame = CreateFrame("FRAME"); 
loadFrame:RegisterEvent("ADDON_LOADED"); 
loadFrame:RegisterEvent("PLAYER_LOGOUT"); 
loadFrame:SetScript("OnEvent", function()
	if type(AddUIDB) ~= "table" then AddUIDB = {} end
	for i, j in pairs(ns.AddUIDefaultDB) do
		if type(j) == "table" then
			if AddUIDB[i] == nil then AddUIDB[i] = {} end
			for k, v in pairs(j) do
				if AddUIDB[i][k] == nil then
					AddUIDB[i][k] = v
				end
			end
		else
			if AddUIDB[i] == nil then AddUIDB[i] = j end
		end
	end
end)
----------------------------------