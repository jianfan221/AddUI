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
	GameTooltip:SetText("|cff00FF00左键就位|r |cffFFFF00右键倒数|r")
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
local logbtn = CreateChatButton("Channel_02", "Log",
	LoggingCombat() and {0,1,0} or (not AddUIDB.AutoLog and {0.5, 0.5, 0.5} or {1,0,0}),
	function(self, button)
		local logtrue = LoggingCombat()
		if IsShiftKeyDown() then
			if AddUIDB.AutoLog then
				AddUIDB.AutoLog = false
				print("|cffd20000已禁用大秘境自动开启战斗日志|r")
				ns.AATEXT("|cffd20000已禁用大秘境自动开启战斗日志|r")
			else
				AddUIDB.AutoLog = true
				print("|cff00d200已启用大秘境自动开启战斗日志|r")
				ns.AATEXT("|cff00d200已启用大秘境自动开启战斗日志|r")
			end
		else
			if logtrue then
				logtrue = false
				LoggingCombat(false)
				print("|cffd20000已关闭战斗日志|r")
				ns.AATEXT("|cffd20000已关闭战斗日志|r")
			else
				logtrue = true
				LoggingCombat(true)
				print("|cff00d200已开启战斗日志|r")
				ns.AATEXT("|cff00d200已开启战斗日志|r")
			end
		end
		local color = logtrue and {0,1,0} or (not AddUIDB.AutoLog and {0.5, 0.5, 0.5} or {1,0,0})
		self.text:SetTextColor(unpack(color))
	end,2.2)
	logbtn:RegisterEvent("PLAYER_ENTERING_WORLD")
	logbtn:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	logbtn:RegisterEvent("CHALLENGE_MODE_START")
	logbtn:RegisterEvent("CHALLENGE_MODE_COMPLETED")
	logbtn:SetScript("OnEvent", function(self, event)
		if not AddUIDB.AutoLog then return end
		if not LoggingCombat() and (event == "CHALLENGE_MODE_START" or C_ChallengeMode.IsChallengeModeActive()) then
			LoggingCombat(true)
			self.text:SetTextColor(0,1,0)
			print("|cff00d200已开启战斗日志|r")
			ns.AATEXT("|cff00d200已开启战斗日志|r")
			logbtn.Timer = nil
		end
		if event == "CHALLENGE_MODE_COMPLETED" or not IsInInstance() then
			if logbtn.Timer then return end
			logbtn.Timer = C_Timer.NewTicker(10, function()
				if not LoggingCombat() then return end
				LoggingCombat(false)
				self.text:SetTextColor(1,0,0)
				print("|cffd20000已关闭战斗日志|r")
				ns.AATEXT("|cffd20000已关闭战斗日志|r")
				logbtn.Timer = nil
			end, 1)
		end
	end)
	logbtn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_CURSOR", 20, -20)
		local MText = AddUIDB.AutoLog and "|cff00FF00启用|r" or "|cffd20000禁用|r"
		GameTooltip:SetText("|cff00FF00战斗记录开关|r (点击切换)\n|cffFFFF00大秘境自动开启:|r " .. MText .. " (按shift切换)")
		GameTooltip:Show()
	end)
	logbtn:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)



end)