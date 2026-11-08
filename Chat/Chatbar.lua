local _,ns = ...
ns.event("PLAYER_LOGIN", function()
if not AddUIDB.chatb then return end

--JoinChannelByName("寻求组队")
local chatFrame = SELECTED_DOCK_FRAME
COLORSCHEME_BORDER = { 0.3,0.3,0.3,1 }

local chat = CreateFrame("Frame","chat",UIParent)
chat:SetWidth(23)
chat:SetHeight(23)
chat:SetPoint("BOTTOMLEFT",ChatFrame1,0,-50)

-- 创建按钮的公共函数
local offset = 0
local function CreateChatButton(name, text, color, onClick, offX)
	if offX then
		offset = offset + offX
	end
	local btn = CreateFrame("Button", name, chat)
	btn:SetWidth(25)
	btn:SetHeight(25)
	btn:SetPoint("TOPLEFT", chat, "TOPLEFT", offset*30, 0)
	offset = offset + 1
	btn:RegisterForClicks("AnyUp")
	btn:SetScript("OnClick", onClick)
	
	btn.text = btn:CreateFontString(nil, "OVERLAY")
	btn.text:SetFont("fonts\\ARHei.ttf", 15, "OUTLINE")
	btn.text:SetJustifyH("CENTER")
	btn.text:SetWidth(30)
	btn.text:SetHeight(25)
	btn.text:SetText(text)
	btn.text:SetPoint("CENTER", 0, 0)
	btn.text:SetTextColor(color[1], color[2], color[3])
	return btn
end

-- 说
local Say = CreateChatButton("ChannelSay", "说", {1, 1, 1},
	function() ChatFrame_OpenChat("/s ", chatFrame) end)

-- 喊
local Yell = CreateChatButton("ChannelYell", "喊", {255/255, 64/255, 64/255},
	function() ChatFrame_OpenChat("/y ", chatFrame) end)

-- 队伍
local Party = CreateChatButton("ChannelParty", "队", {170/255, 170/255, 255/255},
	function() ChatFrame_OpenChat("/p ", chatFrame) end)

-- 公会
local Guild = CreateChatButton("ChannelGuild", "会", {64/255, 255/255, 64/255},
	function() ChatFrame_OpenChat("/g ", chatFrame) end)

-- 团队
local Raid = CreateChatButton("ChannelRaid", "团", {255/255, 127/255, 0},
	function() ChatFrame_OpenChat("/raid ", chatFrame) end)

-- 副本
local BG = CreateChatButton("Channel_03", "副", {255/255, 127/255, 0},
	function() ChatFrame_OpenChat("/bg ", chatFrame) end)

-- 综合频道
local General = CreateChatButton("Channel_01", "综", {210/255, 180/255, 140/255},
	function()
		local jiaoyi = GetChannelName("综合")
		if jiaoyi == 0 then print("你没有综合频道") return end
		ChatFrame_OpenChat("/"..jiaoyi.." ", chatFrame)
	end)

-- 交易频道
local Trade = CreateChatButton("Channel_02", "交", {255/255, 130/255, 130/255},
	function()
		local jiaoyi = GetChannelName("交易")
		if jiaoyi == 0 then print("你不在交易频道,请去主城加入") return end
		ChatFrame_OpenChat("/"..jiaoyi.." ", chatFrame)
	end)


-- 大脚世界频道
local World = CreateChatButton("Channel_05", "世", {200/255, 255/255, 150/255},
	function(self, button)
	if button == "RightButton" then
		local _, channelName = GetChannelName("大脚世界频道")
		if not channelName then
			JoinPermanentChannel("大脚世界频道", nil, 1, 1)
			print("|cff00d200已加入大脚世界频道|r,右键点击>|cffC8FF96世|r<加入/离开")
		else
			LeaveChannelByName("大脚世界频道")
			print("|cffd20000已离开大脚世界频道|r")
		end
	else
		local channel, channelName = GetChannelName("大脚世界频道")
		if not channelName then
			JoinPermanentChannel("大脚世界频道", nil, 1, 1)
			C_Timer.After(0.3, function()
				local ch = GetChannelName("大脚世界频道")
				ChatFrame_OpenChat("/"..ch.." ", chatFrame)
			end)
		else
			ChatFrame_OpenChat("/"..channel.." ", chatFrame)
		end
	end
end)

-- 报告按钮
local report = CreateChatButton(nil, "报", {255/255, 255/255, 0/255},
	function()
	local S_C = UnitStat("player", 1)
	local AG_C = UnitStat("player", 2)
	local IN_C = UnitStat("player", 4)
	local stat1 = "装等:" .. format("%.1F", select(2, GetAverageItemLevel())) .. "/" .. format("%.1F", select(1, GetAverageItemLevel()))
	local stat2 = "职业:" .. UnitClass("player")
	local stat3 = "天赋:" .. select(2, GetSpecializationInfo(GetSpecialization()))
	local stat4 = ""
	if S_C > AG_C and S_C > IN_C then
		stat4 = "力量:" .. S_C
	elseif AG_C > S_C and AG_C > IN_C then
		stat4 = "敏捷:" .. AG_C
	elseif IN_C > S_C and IN_C > AG_C then
		stat4 = "智力:" .. IN_C
	end
	
	local line = stat1 .. " " .. stat2 .. " " .. stat3 .. " " .. stat4 .. 
		" 爆击:" .. format("%.2F%%", GetSpellCritChance(2)) ..
		" 急速:" .. format("%.2F%%", GetHaste()) ..
		" 精通:" .. format("%.2F%%", select(1, GetMasteryEffect())) ..
		" 全能:" .. format("%.2F%%", GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE))
	ChatFrame_OpenChat(line, chatFrame)
end)


-- Roll 按钮
local roll = CreateFrame("Button", "rollMacro", chat)
roll:SetWidth(23)
roll:SetHeight(23)
roll:SetPoint("TOPRIGHT", chat, "TOPRIGHT", 300, -1)
roll:RegisterForClicks("AnyUp")
roll:SetScript("OnClick", function() RandomRoll(1, 100) end)
roll.texture = roll:CreateTexture("Button", nil, frame)
roll.texture:SetWidth(23)
roll.texture:SetHeight(23)
roll.texture:SetTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Up")
roll.texture:SetPoint("CENTER", 0, 0)

-- 就位按钮
local ChatReady = CreateFrame("Button", "ChatReady", chat)
ChatReady:SetWidth(33)
ChatReady:SetHeight(33)
ChatReady:SetPoint("TOPRIGHT", chat, "TOPRIGHT", 338, 6)
ChatReady:RegisterForClicks("AnyUp")
ChatReady:SetScript("OnClick", function(self, button)
	if button == "RightButton" then
		if C_PartyInfo and C_PartyInfo.DoCountdown then
			C_PartyInfo.DoCountdown(10)
		end
	else
		DoReadyCheck()
	end
end)
ChatReady:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_CURSOR", 20, -20)
	GameTooltip:SetText("|cff00FF00左键就位|r |cffFFFF00右键倒数|r",1,1,1)
	GameTooltip:Show()
end)
ChatReady:SetScript("OnLeave", function(self)
	GameTooltip:Hide()
end)
ChatReady.texture = ChatReady:CreateTexture("Button", nil, frame)
ChatReady.texture:SetWidth(30)
ChatReady.texture:SetHeight(30)
ChatReady.texture:SetAtlas(READY_CHECK_READY_TEXTURE_RAID)
ChatReady.texture:SetPoint("CENTER", 0, 0)

--log记录开启和关闭
if not AddUIDB.lotbnt then return end
-- 客户端差异：正式服按难度分（大秘境 + 普通/英雄/史诗/弹性史诗团本）；无限服 1.60.1（WOW_PROJECT_CAMELOT = 18）按人数分（10/20/40 人团本）
local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local SceneList = isRetail and {
	{ key = "mplus", text = "大秘境" },
	{ key = "raidNormal", text = "团本 · 普通", diff = 14 },
	{ key = "raidHeroic", text = "团本 · 英雄", diff = 15 },
	{ key = "raidMythic", text = "团本 · 史诗", diff = 16 },
	{ key = "raidMythicFlex", text = "团本 · 弹性史诗", diff = 233 },
} or {
	{ key = "raid10", text = "团本 · 10 人", size = 10 },
	{ key = "raid20", text = "团本 · 20 人", size = 20 },
	{ key = "raid40", text = "团本 · 40 人", size = 40 },
}

local logbtn, menu, RefreshMenu

local function Notify(text)
	print(text)
	ns.AATEXT(text)
end

-- 场景是否勾选（未设置过视为勾选）
local function IsSceneOn(key)
	if not key then return end
	local modes = AddUIDB.AutoLogModes
	return modes == nil or modes[key] ~= false
end

-- 是否真的会自动开启（总开关开 + 至少勾了一个场景）
local function IsArmed()
	if not AddUIDB.AutoLog then return end
	for _, s in ipairs(SceneList) do
		if IsSceneOn(s.key) then return true end
	end
end

-- 当前所在场景，nil = 不在任何已支持的场景
local function GetCurrentScene()
	local inInstance, instanceType = IsInInstance()
	if not inInstance then return end
	if isRetail and C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive() then
		return "mplus"
	end
	if instanceType ~= "raid" then return end
	local _, _, difficultyID, _, maxPlayers = GetInstanceInfo()
	for _, s in ipairs(SceneList) do
		if (s.diff and s.diff == difficultyID) or (s.size and s.size == maxPlayers) then return s.key end
	end
end

local function UpdateColor()
	local color = LoggingCombat() and {0, 1, 0} or (not IsArmed() and {0.5, 0.5, 0.5} or {1, 0, 0})
	logbtn.text:SetTextColor(unpack(color))
end

-- 取消“离开场景后关日志”的待执行计时
local function CancelStopTimer()
	if logbtn.StopTimer then
		logbtn.StopTimer:Cancel()
		logbtn.StopTimer = nil
	end
end

-- 开关战斗日志（已是目标状态则什么都不做）
local function SetLog(on)
	CancelStopTimer()
	if LoggingCombat() == on then return end
	LoggingCombat(on)
	Notify(on and "|cff00d200已开启战斗日志|r" or "|cffd20000已关闭战斗日志|r")
	UpdateColor()
end

-- 按当前场景自动开/关（离开场景 10 秒后停）
local function CheckScene()
	if not AddUIDB.AutoLog then return end
	if IsSceneOn(GetCurrentScene()) then
		SetLog(true)
	elseif LoggingCombat() and not logbtn.StopTimer then
		logbtn.StopTimer = C_Timer.NewTimer(10, function()
			logbtn.StopTimer = nil
			SetLog(false)
		end)
	end
end

local sceneRows = {}
local function PlayCheckSound()
	if SOUNDKIT and SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON then
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
	end
end

-- 一行 = 复选框 + 文字 + 整行可点的热区
local function CreateMenuRow(parent, text, fontSize, y, onClick, hitHeight)
	local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	cb:SetPoint("TOPLEFT", 8, y)
	cb:SetSize(20, 20)
	cb:EnableMouse(false)
	cb.Text:ClearAllPoints()
	cb.Text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
	cb.Text:SetFont("fonts\\ARHei.ttf", fontSize, "OUTLINE")
	cb.Text:SetText(text)

	local hit = CreateFrame("Button", nil, parent)
	hit:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, y + 2)
	hit:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, y + 2)
	hit:SetHeight(hitHeight or 20)

	local hl = hit:CreateTexture(nil, "BACKGROUND")
	hl:SetAllPoints()
	hl:SetColorTexture(1, 1, 1, 0.08)
	hl:Hide()
	hit:SetScript("OnEnter", function() hl:Show() end)
	hit:SetScript("OnLeave", function() hl:Hide() end)
	hit:SetScript("OnClick", function()
		if cb.locked then return end
		local checked = not cb:GetChecked()
		cb:SetChecked(checked)
		PlayCheckSound()
		if onClick then onClick(cb, checked) end
	end)
	cb.hit = hit
	return cb
end

local function BuildMenu()
	menu = CreateFrame("Frame", "AddUI_LogMenu", UIParent, "BackdropTemplate")
	menu:SetWidth(210)
	menu:SetPoint("BOTTOM", logbtn, "TOP", 0, 4)
	menu:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		edgeSize = 12,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	menu:SetBackdropColor(0.03, 0.03, 0.03, 0.95)
	menu:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)
	menu:SetClampedToScreen(true)
	menu:SetFrameStrata("DIALOG")
	menu:EnableMouse(true)
	menu:Hide()
	-- 鼠标移出菜单 1 秒后关闭，中途回来则取消
	local function MouseOverMenu()
		local foci = GetMouseFoci()
		if not foci then return end
		for _, region in ipairs(foci) do
			if region == menu then return true end
			local parent = region:GetParent()
			while parent do
				if parent == menu then return true end
				parent = parent:GetParent()
			end
		end
	end

	local ScheduleClose
	ScheduleClose = function(delay)
		if menu.HideTimer then return end
		menu.HideTimer = C_Timer.NewTimer(delay, function()
			menu.HideTimer = nil
			-- 鼠标其实还停在菜单上（点开关会导致误判离开），继续等
			if MouseOverMenu() then
				ScheduleClose(0.5)
				return
			end
			menu:Hide()
		end)
	end

	local function CancelHideTimer()
		if menu.HideTimer then
			menu.HideTimer:Cancel()
			menu.HideTimer = nil
		end
	end

	menu:SetScript("OnEnter", CancelHideTimer)
	menu:SetScript("OnLeave", function() ScheduleClose(1) end)
	menu:SetScript("OnHide", CancelHideTimer)
	table.insert(UISpecialFrames, "AddUI_LogMenu")

	-- 总开关（大字）
	menu.master = CreateMenuRow(menu, "以下场景自动开启", 16, -10, function(_, checked)
		AddUIDB.AutoLog = checked
		AddUIDB.AutoLogModes = AddUIDB.AutoLogModes or {}
		Notify(checked and "|cff00d200已启用场景自动开启战斗日志|r" or "|cffd20000已禁用场景自动开启战斗日志|r")
		-- 关掉总开关时一并关掉正在记录的战斗日志
		if not checked then SetLog(false) end
		RefreshMenu()
		UpdateColor()
		CheckScene()
	end, 24)
	menu.master:SetSize(24, 24)

	local line = menu:CreateTexture(nil, "ARTWORK")
	line:SetColorTexture(0.3, 0.3, 0.3, 1)
	line:SetHeight(1)
	line:SetPoint("TOPLEFT", 10, -38)
	line:SetPoint("TOPRIGHT", -10, -38)

	local y = -46
	for _, s in ipairs(SceneList) do
		local cb = CreateMenuRow(menu, s.text, 13, y, function(_, checked)
			AddUIDB.AutoLogModes = AddUIDB.AutoLogModes or {}
			AddUIDB.AutoLogModes[s.key] = checked
			UpdateColor()
			CheckScene()
		end)
		cb.sceneKey = s.key
		table.insert(sceneRows, cb)
		y = y - 22
	end
	menu:SetHeight(-y + 4)
end

RefreshMenu = function()
	local on = AddUIDB.AutoLog
	menu.master:SetChecked(on)
	if on then
		menu.master.Text:SetTextColor(1, 0.82, 0)
	else
		menu.master.Text:SetTextColor(0.55, 0.45, 0.3)
	end
	for _, cb in ipairs(sceneRows) do
		cb:SetChecked(IsSceneOn(cb.sceneKey))
		cb.locked = not on
		cb:SetAlpha(on and 1 or 0.4)
	end
end

logbtn = CreateChatButton("Channel_02", "Log",
	LoggingCombat() and {0,1,0} or (not IsArmed() and {0.5, 0.5, 0.5} or {1,0,0}),
	function(self, button)
		if button == "RightButton" then
			if menu:IsShown() then
				menu:Hide()
			else
				RefreshMenu()
				menu:Show()
			end
			return
		end
		SetLog(not LoggingCombat())
	end,2.2)
BuildMenu()
logbtn:RegisterEvent("PLAYER_ENTERING_WORLD")
logbtn:RegisterEvent("ZONE_CHANGED_NEW_AREA")
logbtn:RegisterEvent("CHALLENGE_MODE_START")
logbtn:RegisterEvent("CHALLENGE_MODE_COMPLETED")
logbtn:SetScript("OnEvent", CheckScene)



end)