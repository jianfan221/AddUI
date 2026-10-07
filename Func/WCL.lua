local _, ns = ...

--菜单里加我们那组：复制角色名 + WCL + Raider.IO，点开是可复制文本框（Ctrl+C / Ctrl+X 后自动关）
--位置：目标框架、好友/聊天框/公会/社区，以及预创建队伍（申请者、搜索结果=查队长）
--加项走官方 Menu.ModifyMenu（tag 见 UnitPopupShared.lua:106、LFGList.lua:2170、:3463）；暴雪那项「复制角色名」见文件末尾

--区服：自动判断（CN→cn / US→us / EU→eu / TW→tw；拿到的 KR 其实是台服，见下）
--REGION 决定网址里的区服路径段；用不用简体中文站由下面的 ZH_SITE 单独判断
--⚠️ 别用 GetCurrentRegion()：它只读启动时的 portal CVar，台服会误报成 KR
local REGION = (GetCurrentRegionName() or "CN"):lower()
--台服 realm 走韩国 Battle.net 门户，上面拿到的就是 kr；本插件没韩服用户，一律当台服
if REGION == "kr" then REGION = "tw" end

--中文用户（国服 + 台服）统一走简体中文站：WCL 是 cn. 子域名，Raider.IO 是 cn/ 语言段
local ZH_SITE = REGION == "cn" or REGION == "tw"

--WCL 只有简体中文站有独立子域名，其它大区一律用 www（美/欧）
local WCL_HOST = ZH_SITE and "cn.warcraftlogs.com" or "www.warcraftlogs.com"

local WCL_URL = "https://"..WCL_HOST.."/character/"..REGION.."/%s/%s"
--地城（5人本/大秘境）额外带 zone + metric（换赛季要改 55：数字在 WCL 大秘境排行榜地址 /zone/rankings/<id> 里）
--metric=points_and_damage：按「大秘境评分 + 伤害」出榜，不是 WCL 默认视图
local WCL_URL_MPLUS = WCL_URL.."?zone=55&metric=points_and_damage"
--Raider.IO 角色页（不需要 zone）
--开头那段是它自己的站点语言（简体中文 cn/，英文默认就省略）：中文用户都带上
local RIO_LANG = ZH_SITE and "cn/" or ""
local RIO_URL = "https://raider.io/"..RIO_LANG.."characters/"..REGION.."/%s/%s"

--通用「可复制文本」弹窗：data = { title = 标题, text = 内容 }
--4 个 StaticPopup 共用一个 EditBox：第一次用到时挂一次 OnKeyDown，复制/剪切后关掉弹窗
--⚠️ 必须延迟再关：关窗会走 StaticPopup_OnHide 把 EditBox 清空（StaticPopup.lua:631），
--抢在原生复制落地之前关 = 复制到空白。1 帧不够，0.1 秒实测可用
local hooked = {}
local function HookKeyDown(editBox)
	if hooked[editBox] then return end
	hooked[editBox] = true
	editBox:HookScript("OnKeyDown", function(self, key)
		if self:GetParent().which == "ADDUI_COPY" and IsControlKeyDown() and (key == "C" or key == "X") then
			C_Timer.After(0.1, function() StaticPopup_Hide("ADDUI_COPY") end)
		end
	end)
end

StaticPopupDialogs["ADDUI_COPY"] = {
	text = "",	--标题在 OnShow 里按 data.title 设
	button1 = CLOSE,
	hasEditBox = 1,
	editBoxWidth = 320,
	maxLetters = 255,	--必须重设：同一个 EditBox 会被别的弹窗改过 maxLetters
	whileDead = 1,
	hideOnEscape = 1,
	timeout = 0,
	EditBoxOnEscapePressed = function(editBox) editBox:GetParent():Hide() end,	--输入框有焦点时 ESC 也能关
	OnShow = function(dialog, data)
		local editBox = dialog:GetEditBox()
		HookKeyDown(editBox)
		if data and data.title then dialog:SetText(data.title) end
		local content = data and data.text
		if content == nil then content = "" end	--内容可能是秘密值：只能跟 nil 比较
		editBox:SetText(content)
		editBox:SetFocus()
		editBox:HighlightText()
	end,
}

--弹出可复制文本框
local function ShowCopyPopup(title, content)
	StaticPopup_Show("ADDUI_COPY", nil, nil, {title = title, text = content})
end

--复制角色名弹窗：和 URL 用同一份数据（名字-服务器；标题用暴雪的全局字符串，自动本地化）
local function ShowCopyName(name, server)
	ShowCopyPopup(COPY_CHARACTER_NAME, name.."-"..server)
end

--我们那一组（追加在 root 末尾）：复制角色名 + WCL + Raider.IO；isDungeon 为真时 WCL 用带 zone 的地址
--WCL / Raider.IO 两项各有开关（设置-其他-右键菜单），关掉就不建；复制角色名恒有
local function AddOurButtons(root, name, server, isDungeon)
	root:CreateDivider()
	root:CreateButton(COPY_CHARACTER_NAME, function()
		ShowCopyName(name, server)
	end)

	if AddUIDB.wcl then
		local wclURL = (isDungeon and WCL_URL_MPLUS or WCL_URL):format(server, name)
		root:CreateButton("WCL", function()
			ShowCopyPopup("Warcraft Logs", wclURL)
		end)
	end

	if AddUIDB.rio then
		root:CreateButton("Raider.IO", function()
			ShowCopyPopup("Raider.IO", RIO_URL:format(server, name))
		end)
	end
end

--名字/服务器直接用暴雪在 UnitPopupManager:OpenMenu 里填好的（不用 UnitFullName：它的返回值可能是秘密值）
--⚠️ 拿不到「角色名」就返回 nil（不给按钮）：名字可能是秘密值（聊天里），也可能是空串/战网昵称（好友列表里含 #）
local function CheckName(name, server)
	if name == nil or issecretvalue(name) or issecretvalue(server) then return end
	if name == "" or name:find("#", 1, true) then return end
	if server == nil or server == "" then server = GetRealmName() end
	return name, server
end

--战网好友 / 战网群组成员：没有角色名，取账号信息里的「当前角色」（跨区的不给按钮）
--角色好友 / 公会成员 / 社区成员这些：OpenMenu 已经把 "名字-服务器" 拆到 contextData.name / .server
local function GetMenuPlayer(contextData)
	local clubInfo = contextData.clubInfo
	if contextData.bnetIDAccount or contextData.battleTag
		or (clubInfo ~= nil and clubInfo.clubType == Enum.ClubType.BattleNet) then
		local gameInfo = contextData.accountInfo and contextData.accountInfo.gameAccountInfo
		if not gameInfo or not gameInfo.isInCurrentRegion then return end
		return CheckName(gameInfo.characterName, gameInfo.realmDisplayName)
	end

	return CheckName(contextData.name, contextData.server)
end

--暴雪的「复制角色名」就是我们的开关：它的 CanShow 只排除「自己」和战网好友，跟是哪个菜单无关
--（UnitPopupSharedButtonMixins.lua:1448），所以直接复用原版 —— 暴雪会在哪显示那一项，我们就在哪显示三项
--原版函数在文件末尾存进这里
local BlizzardCanShow

--目标框架上的非玩家单位（NPC）：它走的是 which=TARGET 那套菜单，暴雪在里面没放「复制角色名」
--（TargetFrame.lua:657；好友/公会菜单的 contextData.unit 是 "friend-1" 这种非单位串，UnitExists 为 nil，不会误判）
local function IsNpcUnit(contextData)
	if not contextData then return false end
	local unit = contextData.unit
	return unit ~= nil and UnitExists(unit) and not UnitIsPlayer(unit)
end

--该不该按「玩家」出我们那三项？和「藏掉暴雪那项」共用这一个判断，保证两边永远同步
local function ShouldShow(contextData)
	if not contextData or not BlizzardCanShow or IsNpcUnit(contextData) then return false end
	return BlizzardCanShow(nil, contextData) and true
end

--NPC 查不了 WCL / Raider.IO（那不是角色名），只给「复制名字」；文案沿用暴雪的全局字符串
local function AddNpcButtons(root, contextData)
	local name = contextData.name
	if name == nil or issecretvalue(name) then return end
	root:CreateDivider()
	root:CreateButton(COPY_CHARACTER_NAME, function()
		ShowCopyPopup(COPY_CHARACTER_NAME, name)
	end)
end

--玩家：复制角色名 + WCL + Raider.IO；NPC：只有复制名字（暴雪那套菜单里本来就没有）
local function AddPlayerMenu(owner, root, contextData)
	if ShouldShow(contextData) then
		local name, server = GetMenuPlayer(contextData)
		if not name then return end
		AddOurButtons(root, name, server, true)	--这组一律给带 zone 的页
		return
	end

	if IsNpcUnit(contextData) then AddNpcButtons(root, contextData) end
end

--把回调挂到全部 UnitPopup 菜单：UnitPopupMenus 是全局表、键就是 which（UnitPopupShared.lua:2）
--它分两个包填（Shared 填通用菜单、UnitPopup 填 RAF_RECRUIT 等），所以两处各扫一次
--⚠️ Menu.ModifyMenu 是累积注册：同一个 tag 注册两次 → 菜单里会出现两组按钮，必须去重
local registered = {}
local function RegisterAllMenus()
	for which in pairs(UnitPopupMenus) do
		if not registered[which] then
			registered[which] = true
			Menu.ModifyMenu("MENU_UNIT_"..which, AddPlayerMenu)
		end
	end
end

--"名字-服务器" → 名字 / 服务器；同服只有名字，服务器用本服补
---@param fullName string
---@return string, string
local function SplitFullName(fullName)
	local name, server = fullName:match("^([^-]+)%-(.+)$")
	if name then return name, server end
	return fullName, GetRealmName()
end

--预创建里地城类（5人本/大秘境）才带 zone，其它活动（团本/战场/宠物/自定义）走总览页
local CATEGORY_DUNGEONS = 2	--GROUP_FINDER_CATEGORY_ID_DUNGEONS，见 Blizzard_GroupFinder/Mainline/LFGList.lua:9
local function IsDungeon(activityIDs)
	if issecretvalue(activityIDs) or type(activityIDs) ~= "table" or not activityIDs[1] then return false end
	local activityInfo = C_LFGList.GetActivityInfoTable(activityIDs[1])
	return activityInfo and activityInfo.categoryID == CATEGORY_DUNGEONS or false
end

--预创建这两条菜单：拿到全名（可能是秘密值）+ 是不是地城类目就够了
local function AddLfgButtons(root, fullName, isDungeon)
	if fullName == nil or issecretvalue(fullName) then return end	--聊天受限读不到就不给按钮
	local name, server = SplitFullName(fullName)
	AddOurButtons(root, name, server, isDungeon)
end

--预创建队伍-申请者列表：这条菜单没带 contextData，从 owner（申请者条目）自己取
local function AddApplicantMenu(owner, root)
	local applicantID = owner and owner.GetParent and owner:GetParent().applicantID
	local memberIdx = owner and owner.memberIdx
	if not applicantID or not memberIdx then return end

	--自己那条（申请者们申请的就是它）是什么类目；聊天受限读不到时当不是地城
	local entryInfo = C_LFGList.GetActiveEntryInfo()
	local isDungeon = false
	if not issecretvalue(entryInfo) and entryInfo ~= nil then
		isDungeon = IsDungeon(entryInfo.activityIDs)
	end

	AddLfgButtons(root, C_LFGList.GetApplicantMemberInfo(applicantID, memberIdx), isDungeon)
end

Menu.ModifyMenu("MENU_LFG_FRAME_MEMBER_APPLY", AddApplicantMenu)

--预创建队伍-搜索结果列表：右键一条队伍 = 查队长
local function AddSearchEntryMenu(owner, root)
	local resultID = owner and owner.resultID
	if not resultID then return end

	--⚠️ GetSearchResultInfo 带 SecretInChatMessagingLockdown：聊天受限时整张表都是秘密值
	--（秘密值不能用于 and/or 这类布尔判断，所以拆成两个变量分开取）
	local info = C_LFGList.GetSearchResultInfo(resultID)
	local fullName, isDungeon = nil, false
	if not issecretvalue(info) and info ~= nil then
		fullName, isDungeon = info.leaderName, IsDungeon(info.activityIDs)
	end

	AddLfgButtons(root, fullName, isDungeon)
end

Menu.ModifyMenu("MENU_LFG_FRAME_SEARCH_ENTRY", AddSearchEntryMenu)

--暴雪的「复制角色名」（那个 mixin 被 20+ 个菜单共享）：
--① 我们出按钮的位置藏掉它（我们那份已含「复制角色名」），其它位置保持原样
--② 点击换成我们这套：它原生只复制 contextData.name（服务器早被 OpenMenu 拆走，见 UnitPopupShared.lua:42），
--   跨服贴出去没用；而且它用 CopyToClipboard，对插件是 HasRestrictions 的
--③ 文案不动：它自己的 GetText 返回全局字符串 COPY_CHARACTER_NAME，自动本地化
--⚠️ 这个包按需加载 → 用 ContinueOnAddOnLoaded（已加载立即回调）；且这段必须在文件末尾，闭包要捕获上面的局部函数
EventUtil.ContinueOnAddOnLoaded("Blizzard_UnitPopupShared", function()
	local mixin = UnitPopupCopyCharacterNameButtonMixin
	if not mixin then return end

	BlizzardCanShow = mixin.CanShow	--先存原版给 ShouldShow 用
	--⚠️ CanShow 返回 true 是「显示」：这里必须给 false 才是藏掉（原版是冒号调用，见 UnitPopupShared.lua:66）
	mixin.CanShow = function(_, contextData)
		--我们出按钮的位置（玩家三项 / NPC 复制名字）都藏掉它，免得重复
		if ShouldShow(contextData) or IsNpcUnit(contextData) then return false end
		return BlizzardCanShow(nil, contextData)
	end

	mixin.OnClick = function(_, contextData)
		if not contextData then return end
		local name, server = CheckName(contextData.name, contextData.server)
		if name then ShowCopyName(name, server) end
	end

	RegisterAllMenus()
end)

--还有几个菜单在 UnitPopup 包里注册（RAF_RECRUIT 等），晚于 Shared，这里再扫一遍
EventUtil.ContinueOnAddOnLoaded("Blizzard_UnitPopup", RegisterAllMenus)
