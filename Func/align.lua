local _,ns = ...

SetCVar("overrideArchive", 0) --和谐国服  1:开启      0:关闭
--[重载命令] 
ns.tips("重载快捷命令/rl或/aa")
SlashCmdList["RELOADUI"] = function() ReloadUI() end 
SLASH_RELOADUI1 = "/rl"
SLASH_RELOADUI2 = "/aa"


ns.tips("倒计时置顶防止被钥匙框体遮挡")
ns.event('START_TIMER', function()
	if InCombatLockdown() then return end
	if not TimerTrackerTimer1 then return end
	TimerTrackerTimer1:SetFrameStrata("TOOLTIP")
end)
ns.tips("就位确认置顶防止被钥匙框体遮挡")
ns.event('READY_CHECK', function()
	if InCombatLockdown() then return end
	ReadyCheckFrame:SetFrameStrata("TOOLTIP")
end)

ns.tips("区域文字位置(大秘境开门快速选怪会碍事)")
EventToastManagerFrame:HookScript("OnShow",function(self)
	self:ClearAllPoints()
	if C_Secrets and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret() then
		self:SetPoint("TOP",UIParent,"TOP",0,-30)
	else
		self:SetPoint("TOP",UIParent,"TOP",0,-190)
	end
end)


ns.tips("聊天反和谐")
local function fuckyou()
--ConsoleExec("portal TW")
ConsoleExec("profanityFilter 0")
end
ns.event("ADDON_LOADED", fuckyou)

--9.1反和谐好友不能组队https://bbs.nga.cn/read.php?&tid=27432996
local pre = C_BattleNet.GetFriendGameAccountInfo
C_BattleNet.GetFriendGameAccountInfo = function(...)
	local gameAccountInfo = pre(...)
	gameAccountInfo.isInCurrentRegion = true
	return gameAccountInfo;
end

ns.tips("重置喊话")
ns.event('CHAT_MSG_SYSTEM', function(event, msg)
	if ns.MM(msg) then return end
	if (msg:lower():match("无法重置") or msg:lower():match("已被重置")) and IsInGroup() and UnitIsGroupLeader("player") then
		SendChatMessage(msg,'PARTY')
	end
end)

--就位声音
ns.event('READY_CHECK', function()
	PlaySoundFile(567478, "Master")
	--PlaySoundFile("Interface\\AddOns\\AddUI\\Func\\call\\准备好了吗.mp3", "Master")
end)

ns.tips("/cd或者/cd 10倒数,/cdd停止倒数")
--倒数/cd默认10秒
SlashCmdList["COUNTDOWN"] = function(msg)
	local num1 = gsub(msg, "(%s*)(%d+)", "%2");
	local number = tonumber(num1);
	if not number then number = 10 end
	if(number and number <= MAX_COUNTDOWN_SECONDS) then
		C_PartyInfo.DoCountdown(number);
	end
end
--停止倒数
SlashCmdList["COUNTDOWNSTOP"] = function()
	C_PartyInfo.DoCountdown(0);
end
SLASH_COUNTDOWNSTOP1 = "/cdd"

ns.tips("地下城页面添加按钮查看低保按钮")
local clear = CreateFrame("Button", "AddUISaveButton", PVEFrame.NineSlice, "UIPanelButtonTemplate")
clear:SetText("宏伟宝库奖励")
clear:SetWidth(110)
clear:SetHeight(22)
clear:SetPoint("TOPLEFT", 57, 0)
clear:SetScript("OnClick", function()
	if (WeeklyRewardsFrame and WeeklyRewardsFrame:IsShown()) then
	HideUIPanel(WeeklyRewardsFrame);
	else
	C_AddOns.LoadAddOn("Blizzard_WeeklyRewards"); WeeklyRewardsFrame:Show()
	end
end)

ns.tips("角色界面创建离开队伍按钮")
local CHLP = CreateFrame("Button", "离开队伍", PaperDollItemsFrame, "UIPanelButtonTemplate")
CHLP:SetText("退队")
CHLP:SetWidth(50)
CHLP:SetHeight(22)
CHLP:SetPoint("BOTTOMLEFT", 7, 9)
CHLP:SetScript("OnClick", function()
	if IsInGroup() then
		UIErrorsFrame:AddExternalWarningMessage(ERR_LEFT_GROUP_YOU)--https://wowpedia.fandom.com/wiki/UI_ERROR_MESSAGE
	end
	C_PartyInfo.LeaveParty()
end)

ns.tips("地下城页面创建离开队伍按钮")
local LFGLP = CreateFrame("Button", "离开队伍", PVEFrame, "UIPanelButtonTemplate")
LFGLP:SetText("退队")
LFGLP:SetWidth(50)
LFGLP:SetHeight(22)
LFGLP:SetPoint("BOTTOMLEFT", 10, 10)
LFGLP:SetScript("OnClick", function()
	if IsInGroup() then
		UIErrorsFrame:AddExternalWarningMessage(ERR_LEFT_GROUP_YOU)--https://wowpedia.fandom.com/wiki/UI_ERROR_MESSAGE
	end
	C_PartyInfo.LeaveParty()
end)

ns.tips("删除自动输入DELETE")--exwind
local DELETE_STR = DELETE_ITEM_CONFIRM_STRING or "DELETE"
local deletePopups = {
    DELETE_GOOD_ITEM        = true,
    DELETE_GOOD_QUEST_ITEM  = true,
    DELETE_QUEST_ITEM       = true,
}
local function FillDeleteText(dialog)
    local editBox = dialog and dialog.GetEditBox and dialog:GetEditBox()
    if editBox then
        editBox:SetText(DELETE_STR)
    end
end

hooksecurefunc("StaticPopup_Show", function(which, text, text_arg2, data)
	if deletePopups[which] then
		C_Timer.After(0, function()
				FillDeleteText(StaticPopup_FindVisible(which, text))
		end)
	end
end)

--隐藏中间团队拾取框,鼠标会点不动
GroupLootContainer:Hide()

--始终显示额外能量条的数值
hooksecurefunc("UnitPowerBarAlt_SetUp", function(self)
	local statusFrame = self.statusFrame
	if statusFrame.enabled then
		statusFrame:Show()
		statusFrame.Hide = statusFrame.Show
	end
end)

--[网格界面校正] 
SLASH_EA1 = "/ab" 

local f

SlashCmdList["EA"] = function()
	if f then
		f:Hide()
		f = nil		
	else
		f = CreateFrame('Frame', nil, UIParent) 
		f:SetAllPoints(UIParent)
		local w = GetScreenWidth() / 64
		local h = GetScreenHeight() / 36
		for i = 0, 64 do
			local t = f:CreateTexture(nil, 'BACKGROUND')
			if i == 32 then
				t:SetColorTexture(1, 0, 0, 0.5)
			else
				t:SetColorTexture(0, 0, 0, 0.5)
			end
			t:SetPoint('TOPLEFT', f, 'TOPLEFT', i * w - 1, 0)
			t:SetPoint('BOTTOMRIGHT', f, 'BOTTOMLEFT', i * w + 1, 0)
		end
		for i = 0, 36 do
			local t = f:CreateTexture(nil, 'BACKGROUND')
			if i == 18 then
				t:SetColorTexture(1, 0, 0, 0.5)
			else
				t:SetColorTexture(0, 0, 0, 0.5)
			end
			t:SetPoint('TOPLEFT', f, 'TOPLEFT', 0, -i * h + 1)
			t:SetPoint('BOTTOMRIGHT', f, 'TOPRIGHT', 0, -i * h - 1)
		end	
	end
end

--预创建报错http://bbs.ngacn.cc/read.php?&tid=12561149&pid=245895632&to=1
if GetLocale() == "zhCN" then 
StaticPopupDialogs["LFG_LIST_ENTRY_EXPIRED_TOO_MANY_PLAYERS"] = { 
text = "针对此项活动，你的队伍人数已满，将被移出列表。", 
button1 = OKAY, 
timeout = 0, 
whileDead = 1, 
preferredIndex = 3 
} 
end
--社区报错--eke提供
GuildControlUIRankSettingsFrameRosterLabel = CreateFrame("Frame")
GuildControlUIRankSettingsFrameRosterLabel:Hide()
ns.tips("隐藏系统自带的界面NPC对话框")
C_AddOns.LoadAddOn('Blizzard_TalkingHeadUI')
TalkingHeadFrame:UnregisterAllEvents()
--hooksecurefunc(TalkingHeadFrame,"PlayCurrent", function()
	--TalkingHeadFrame:Hide()
--end)


ns.tips("自动修理部分(优先使用公会修理)")
ns.event("MERCHANT_SHOW", function()
	if CanMerchantRepair() then
		local cost = GetRepairAllCost()
		local gbwm = GetGuildBankWithdrawMoney() - cost
		local gbk = GetGuildBankMoney()
		if cost > 0 then
			local money = GetMoney()
			if IsInGuild() then
				local guildMoney = GetGuildBankWithdrawMoney()
				if guildMoney > GetGuildBankMoney() then
					guildMoney = GetGuildBankMoney()
				end
				if guildMoney >= cost and CanGuildBankRepair() then
				   RepairAllItems(1)
				   PlaySound("7994")
				   print("|cff00FFFF本次使用公会维修：|r"..C_CurrencyInfo.GetCoinTextureString(cost))
				   if gbk >= gbwm then
				   print("剩余可用公修：".. C_CurrencyInfo.GetCoinTextureString(gbwm))
				   else 
				   print("剩余可用公修：".. C_CurrencyInfo.GetCoinTextureString(gbk))
				   end
				   return
				end
			end
			if money > cost then
				PlaySound("7994")
				RepairAllItems()
				print("|cffFF0000自费修理：|r"..C_CurrencyInfo.GetCoinTextureString(cost))
			else
				print("|cff99CCFF".."没钱修装备了。".."|r")
			end
		end
	end
end)