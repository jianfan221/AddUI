-- Setting.lua：AddUI 新设置界面的标签与设置项（已在 toc 中加载）
-- 本文件只负责：左侧标签项 + 各标签对应的右侧设置项
-- 页面创建 / 左右布局 / 行构建工具 均来自 Setting-Core.lua
-- 用法：ns.AddTab("标签名", function()
--     ns.AddSection("分类标题")
--     ns.AddCheck("名称", "提示", "DB字段"[, 回调(勾选状态)])
--     ns.AddSlider("名称", "提示", min, max, step, "%.0f", "DB字段")
--     ns.AddDropdown("名称", "提示", {{"选项",值},...}, "DB字段"[, 回调(值)])
--     ns.AddTexture("名称", "提示", "DB字段", 纹理表[, 回调(值)])
--     ns.AddCVarCheck("名称", "提示", "CVar名"[, 位索引, 回调])
--     ns.AddCVarSlider("名称", "提示", min, max, step, "%.0f", "CVar名"[, 回调])
--     ns.AddDep("master的DB字段", {"从属DB字段1", "从属DB字段2", ...})
-- end)
local addonName, ns = ...

-- 打开设置界面的 slash 命令（Setting-Core 会动态注册）
ns.opensetting1 = "/ad"
ns.opensetting2 = "/addui"

-- 顶部标题副标题与底部联系信息（AddUI 特有内容，注入给通用模块 Setting-Core）
ns.Subtitle = "|cff00ffd2源生界面增强|r"

-- 底部联系方式文本（核心已不内置，AddUI 直接用 ns.SettingsFrame 创建，锚定底部左侧）
local qqun = ns.SettingsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
qqun:SetPoint("BOTTOMLEFT", ns.SettingsFrame, "BOTTOMLEFT", 0, -28)
qqun:SetJustifyH("LEFT")
qqun:SetText("简繁:|cff00FFFF32655163@qq.com|r       修改设置后重载生效")


-- ═══════ 界面 ═══════
ns.AddTab("界面", function()
	ns.AddSection("界面模块")
	ns.AddCheck("头像模块", "改变头像样式", "unitf")
	ns.AddCheck("动作条模块", "改变动作条样式", "mmb")
	ns.AddCheck("禁用动作条额外动画", "禁用动作条的施法进度+指向技能圆圈+被断变红", "mmba")
	ns.AddCheck("角色面板耐久", "C键面板装备栏下面的耐久度百分比", "syd")
	ns.AddCheck("小地图模块", "方形小地图", "smap")
	ns.AddCheck("小地图图标", "自动排列小地图图标,指向显示+离开时渐隐", "smapicon")
	ns.AddCheck("聊天窗模块", "聊天窗口样式,tab可以切换聊天频道", "chatm")
	ns.AddCheck("聊天频道按钮", "提供一行可以切换频道的按钮", "chatb")
	ns.AddCheck("Log快捷开关", "聊天按钮后面的log按钮", "lotbnt")
	ns.AddDep("chatb", {"lotbnt" })
	ns.AddCheck("好友列表搜索", "此功能会导致不能传送家宅好友", "Friend")
	ns.AddCheck("自身属性框体", "编辑模式拖动位置", "stat")
	ns.AddCheck("右下角信息栏", "右下角显示延迟耐久", "dimi")

end)

-- ═══════ 战斗 ═══════
ns.AddTab("战斗", function()
	ns.AddSection("战斗与团队")
	ns.AddCheck("进入战斗提示", "屏幕中间进入脱离战斗提示", "comb")
	
	ns.AddCheck("LFG增强", "预创建双击申请,自动邀请,自动进组 如果你用集合石,此项自动失效", "lfgkg")
	ns.AddCheck("团队框架模块", "血条材质和职责材质和鼠标指向边框", "raidframebuff")
	ns.AddCheck("团队框架吸收盾", "团队框架显示治疗吸奶盾和普通吸收盾", "raidabsorb")
	
	ns.AddCheck("冷却管理器美化", "冷却管理器美化", "cdset")
	ns.AddCheck("冷却管理器居中对齐", "冷却管理器居中对齐,饰品药水BUFF整合", "cdcenter")
	ns.AddCheck("大秘境重置伤害统计", "大秘境开始时重置伤害统计", "MDRedamage")
	ns.AddCheck("伤害统计样式美化", "伤害统计样式美化", "setdama")
	ns.AddCheck("伤害统计自动对齐", "伤害统计自动对齐", "poidama")
	ns.AddCheck("伤害统计数值简化", "伤害统计数值简化", "valueda")
end)

-- ═══════ 职业 ═══════
ns.AddTab("职业", function()
	ns.AddSection("法师")
	ns.AddCheck("奥术涌动倒数", "奥术涌动结束提前4秒声音提醒", "mageCountdown")
	ns.AddCheck("取消操控按钮", "BUFF栏左侧取消操控时间的按钮", "cancelAuraBtn")
	ns.AddSection("萨满")
	ns.AddCheck("升腾倒数", "萨满升腾结束提前4秒声音提醒", "shamanCountdown")
	ns.AddCheck("自然守护者冷却", "小队在队伍旁,团队在编辑模式调位置", "shamanGuardianCountdown")
	ns.AddCheck("雷霆之爪冷却", "自然守护者左侧显示雷霆之爪图标与冷却", "shamanThunderClaw")
	ns.AddDep("shamanGuardianCountdown", {"shamanThunderClaw"})
	ns.AddCheck("动作条图标切换", "施放流电炽焰把熔岩爆裂的图标替换成净化烈焰", "shamanIconSwap")
	
end)

-- ═══════ 其他 ═══════
ns.AddTab("其他", function()
	ns.AddSection("其他功能")
	ns.AddCheck("CVAR自动设置", "自动配置部分CVAR,大部分已移动至/sd命令", "cvar")
	ns.AddCheck("自动卖灰", "自动卖垃圾", "mh")
	ns.AddCheck("快速拾取", "增加拾取速度", "sq")
	ns.AddCheck("密语自动邀请", "别人密你123或者.组.会自动邀请,支持战网密语", "zu")
	ns.AddCheck("装备一键选择器", "一键需求/贪婪/放弃全部装备", "autoloot")
	
	ns.AddCheck("聊天框战斗战复计时器", "聊天框右上角战斗战复计时器,战复在编辑模式拖动", "chatCombatTimer")
	ns.AddCheck("打断记录", "小队打断记录,只记录打断成功的人,持续20秒,编辑模式拖动位置", "interrupt")
	ns.AddCheck("角色面板移动速度", "C键角色面板右下显示移动速度,悬停显示奔跑/飞行/游泳速度", "movspeed")
	ns.AddButton("自身BUFF列表", "打开自身BUFF监控法术列表\n冷却管理器标题栏或编辑模式下右键自身BUFF框体也可打开", function()
		ns.OpenSelfBuffAuraList()
	end)

end)

-- ═══════ 施法条 ═══════
ns.AddTab("施法条", function()
	ns.AddSection("施法条")
	ns.AddCheck("施法条模块", "改变施法条样式", "cast")
	ns.AddCheck("自定义施法条材质", "需启用施法条模块", "SCastTexture")
	ns.AddTexture("施法条材质", "施法条材质选择", "CastTexture", ns.CastBarTextrue)
	ns.AddSlider("施法条宽度", "施法条宽度", 200, 400, 1, "%d", "castWidth")
	ns.AddSlider("施法条高度", "施法条高度", 10, 40, 1, "%d", "castHeight")
	ns.AddSlider("施法序列延迟", "施法序列延迟", 0, 400, 1, "%d", "SpellQ", function(v)
		SetCVar("SpellQueueWindow", v)
	end)
	-- 施法条模块关闭时，以下从属项禁用
	ns.AddDep("cast", { "SCastTexture", "CastTexture", "castWidth", "castHeight", "SpellQ" })
	ns.AddDep("SCastTexture", { "CastTexture" })
end)

-- ═══════ 提示与数值 ═══════
ns.AddTab("提示数值", function()
	ns.AddSection("提示与数值")
	local fopts = { { "鼠标提示:跟随", 1 }, { "鼠标提示:不跟随", 0 }, { "鼠标提示:非战斗跟随", 2 }, { "鼠标提示:禁用", 3 } }
	ns.AddDropdown("鼠标提示跟随方式", "鼠标提示跟随方式", fopts, "ftip")
	local vopts = { { "中文单位", 1 }, { "英文单位", 2 }, { "暴雪默认", 3 } }
	ns.AddDropdown("数值单位", "数值单位", vopts, "value")
end)

-- ═══════ 其他 ═══════
ns.AddTab("小功能", function()
-- 没开关的功能列表（原 Options.lua 的"其他功能"提示）
	if ns.TIPTEXTS and #ns.TIPTEXTS > 0 then
		ns.AddLog(table.concat(ns.TIPTEXTS, "\n"))
	end
end)