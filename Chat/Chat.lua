local _,ns = ...
ns.event("PLAYER_LOGIN", function()
if AddUIDB.chatm ==  false  then return end

--部分修改自NGA链接http://bbs.ngacn.cc/read.php?tid=9706946

-- 配置聊天框分页------------------------------------

local function GetChatFrame(cname)
	local index = 0
	for i = 1, NUM_CHAT_WINDOWS do
		name, _, _, _, _, _, _, _, _, _ = GetChatWindowInfo(i)
		if name == cname then
			index = i
			break
		end
	end
    return _G['ChatFrame' .. index]
end

local function ChatAddWindow(name)
    FCF_OpenNewWindow(name)
	FCF_DockUpdate();
    local chatFrame = GetChatFrame(name)
    ChatFrame_RemoveAllChannels(chatFrame)
    ChatFrame_RemoveAllMessageGroups(chatFrame)
    if name == "综合" then
        JoinChannelByName("大脚世界频道")
       -- AddChatWindowChannel(chatFrame, "大脚世界频道")
        ChatFrame_AddMessageGroup(chatFrame, "WHISPER")
    end
    if name == "聊天" then
		ChatFrame_AddMessageGroup(chatFrame, "SAY")--说
		ChatFrame_AddMessageGroup(chatFrame, "YELL")--喊
		ChatFrame_AddMessageGroup(chatFrame, "EMOTE")--表情
        ChatFrame_AddMessageGroup(chatFrame, "GUILD")--公会
        ChatFrame_AddMessageGroup(chatFrame, "OFFICER")--官员
        ChatFrame_AddMessageGroup(chatFrame, "GUILD_ACHIEVEMENT")--公会通告
		ChatFrame_AddMessageGroup(chatFrame, "ACHIEVEMENT")--成就通告
		ChatFrame_AddMessageGroup(chatFrame, "WHISPER")--密语
		ChatFrame_AddMessageGroup(chatFrame, "BN_WHISPER")--战网密语
        ChatFrame_AddMessageGroup(chatFrame, "PARTY")--小队
        ChatFrame_AddMessageGroup(chatFrame, "PARTY_LEADER")--队长
        ChatFrame_AddMessageGroup(chatFrame, "RAID")--团队
        ChatFrame_AddMessageGroup(chatFrame, "RAID_LEADER")--团队领袖
        ChatFrame_AddMessageGroup(chatFrame, "RAID_WARNING")--团队警报
        ChatFrame_AddMessageGroup(chatFrame, "INSTANCE_CHAT")--副本队伍
        ChatFrame_AddMessageGroup(chatFrame, "INSTANCE_CHAT_LEADER")--副本领袖
		
		--ChatFrame_AddMessageGroup(chatFrame, "COMBAT_XP_GAIN")--经验
		--ChatFrame_AddMessageGroup(chatFrame, "COMBAT_GUILD_XP_GAIN")--公会经验
		ChatFrame_AddMessageGroup(chatFrame, "COMBAT_HONOR_GAIN")--荣誉
		ChatFrame_AddMessageGroup(chatFrame, "COMBAT_FACTION_CHANGE")--声望
		ChatFrame_AddMessageGroup(chatFrame, "SKILL")--技能提升
		ChatFrame_AddMessageGroup(chatFrame, "LOOT")--物品拾取
		ChatFrame_AddMessageGroup(chatFrame, "CURRENCY")--货币
		ChatFrame_AddMessageGroup(chatFrame, "MONEY")--金钱拾取
		--ChatFrame_AddMessageGroup(chatFrame, "TRADESKILLS")--商业技能
		ChatFrame_AddMessageGroup(chatFrame, "OPENING")--正在打开
		ChatFrame_AddMessageGroup(chatFrame, "PET_INFO")--宠物信息
		ChatFrame_AddMessageGroup(chatFrame, "COMBAT_MISC_INFO")--其他信息
		
		ChatFrame_AddMessageGroup(chatFrame, "BG_HORDE")--战场部落
		ChatFrame_AddMessageGroup(chatFrame, "BG_ALLIANCE")--战场联盟
		ChatFrame_AddMessageGroup(chatFrame, "BG_NEUTRAL")--战场中立
		
		ChatFrame_AddMessageGroup(chatFrame, "SYSTEM")--系统
		ChatFrame_AddMessageGroup(chatFrame, "ERRORS")--错误
		ChatFrame_AddMessageGroup(chatFrame, "IGNORED")--已屏蔽
		ChatFrame_AddMessageGroup(chatFrame, "TARGETICONS")--目标图标
		ChatFrame_AddMessageGroup(chatFrame, "BN_INLINE_TOAST_ALERT")--战网提示
		--ChatFrame_AddMessageGroup(chatFrame, "PET_BATTLE_COMBAT_LOG")--宠物对战
		--ChatFrame_AddMessageGroup(chatFrame, "PET_BATTLE_INFO")--宠物对战信息
		
		ChatFrame_AddMessageGroup(chatFrame, "MONSTER_SAY")--怪物说
		ChatFrame_AddMessageGroup(chatFrame, "MONSTER_EMOTE")--怪物表情
		ChatFrame_AddMessageGroup(chatFrame, "MONSTER_YELL")--怪物喊
		ChatFrame_AddMessageGroup(chatFrame, "MONSTER_WHISPER")--怪物密语
		ChatFrame_AddMessageGroup(chatFrame, "MONSTER_BOSS_EMOTE")--首领台词
		ChatFrame_AddMessageGroup(chatFrame, "MONSTER_BOSS_WHISPER")--首领密语
	
    end
    if name == "密语" then
        ChatFrame_AddMessageGroup(chatFrame, "WHISPER")
        ChatFrame_AddMessageGroup(chatFrame, "BN_WHISPER")
		ChatFrame_AddMessageGroup(chatFrame, "MONSTER_PARTY")
    end
end
--AddChatWindowChannel
local function Chat()
    FCF_ResetChatWindows()
    ChatAddWindow("聊天")
    ChatAddWindow("密语")
	SetCVar("whisperMode","inline")

    for k,v in pairs(CHAT_CONFIG_CHAT_LEFT) do
        SetChatColorNameByClass(v.type, true)
    end
    for k,v in pairs({GetChannelList()}) do
        local id = tonumber(v)
        if id then
            SetChatColorNameByClass("CHANNEL"..id, true)
        end
    end

	--DEFAULT_CHAT_FRAME:SetPoint("BOTTOMLEFT", "UIParent", "BOTTOMLEFT", 0, 50);
	--DEFAULT_CHAT_FRAME:SetSize(400, 200)
	--聊天信息职业着色
    for k,v in pairs(CHAT_CONFIG_CHAT_LEFT) do
        SetChatColorNameByClass(v.type, true)
    end
    for k,v in pairs({GetChannelList()}) do
        local id = tonumber(v)
        if id then
            SetChatColorNameByClass("CHANNEL"..id, true)
        end
    end
	SetCVar("remoteTextToSpeech",0)	--在语音聊天中为我发言
end

SLASH_CHAT1 = "/chat"		--输入命令执行
SlashCmdList["CHAT"] = function (msg, editbox)
    if msg == "" then Chat()end
end


--聊天框指向显示装备详情
---------------------------------------------------------------------------------------- 
--   Based on tekKompare(by Tekkub) 
---------------------------------------------------------------------------------------- 
local orig1, orig2, GameTooltip = {}, {}, GameTooltip 
local linktypes = {item = true, enchant = true, spell = true, quest = true, unit = true, talent = true, achievement = true, glyph = true, instancelock = true, currency = true} 

local function OnHyperlinkEnter(frame, link, ...) 
if not link then return end
   local linktype = link:match("^([^:]+)") 
   if linktype and linktype == "battlepet" then 
      GameTooltip:SetOwner(frame, "ANCHOR_TOPRIGHT", 250, 0) 
      GameTooltip:Show() 
      local _, speciesID, level, breedQuality, maxHealth, power, speed = strsplit(":", link) 
      BattlePetToolTip_Show(tonumber(speciesID), tonumber(level), tonumber(breedQuality), tonumber(maxHealth), tonumber(power), tonumber(speed)) 
   elseif linktype and linktypes[linktype] then 
      GameTooltip:SetOwner(frame, "ANCHOR_TOPRIGHT", 250, 0) 
      GameTooltip:SetHyperlink(link) 
      GameTooltip:Show() 
   end 

   if orig1[frame] then return orig1[frame](frame, link, ...) end 
end 

local function OnHyperlinkLeave(frame, link, ...) 
   --local linktype = link:match("^([^:]+)") 
   --if linktype and linktype == "battlepet" then 
      BattlePetTooltip:Hide() 
   --elseif linktype and linktypes[linktype] then 
      GameTooltip:Hide() 
   --end 

   if orig1[frame] then return orig1[frame](frame, link, ...) end 
end 

for i = 1, NUM_CHAT_WINDOWS do 
   local frame = _G["ChatFrame"..i] 
   orig1[frame] = frame:GetScript("OnHyperlinkEnter") 
   frame:HookScript("OnHyperlinkEnter", OnHyperlinkEnter) 

   orig2[frame] = frame:GetScript("OnHyperlinkLeave") 
   frame:HookScript("OnHyperlinkLeave", OnHyperlinkLeave) 
end

--标签染色------------------------------------------------------------------------------------------------
local Fane = CreateFrame'Frame' 
local inherit = GameFontNormalSmall 
local color = RAID_CLASS_COLORS[select(2, UnitClass("player"))] 
local updateFS = function(self, inc, flags, ...) 
local fstring = self:GetFontString() 
local font, fontSize = inherit:GetFont() 
   if(inc) then 
      fstring:SetFont(font, fontSize + 1, flags) 
   else 
      fstring:SetFont(font, fontSize, flags) 
   end 
   if((...)) then 
      fstring:SetTextColor(...) 
   end 
end 
local OnEnter = function(self) 
   updateFS(self, nil, "OUTLINE", color.r, color.g, color.b)--鼠標指向顏色 
end 
local OnLeave = function(self) 
   local r, g, b 
   local id = self:GetID() 
   local emphasis = _G["ChatFrame"..id..'TabFlash']:IsShown() 
   if (_G["ChatFrame"..id] == SELECTED_CHAT_FRAME) then 
      r, g, b = color.r, color.g, color.b                       --鼠標停留后顏色 
   elseif emphasis then 
      r, g, b = 1, 1, 1 
   else 
      r, g, b = 1, 1, 1 
   end 
   updateFS(self, emphasis, nil, r, g, b) 
end 

local faneifyTab = function(frame, sel) 
   local i = frame:GetID()
   if(not frame.Fane) then
	  frame.HighlightLeft:SetTexture(nil)
	  frame.ActiveLeft:SetTexture(nil)
	  frame.Left:SetTexture(nil)
	  frame.HighlightRight:SetTexture(nil)
	  frame.ActiveRight:SetTexture(nil)
	  frame.Right:SetTexture(nil)
	  frame.Middle:SetTexture(nil)
	  frame.HighlightMiddle:SetTexture(nil)
	  frame.ActiveMiddle:SetTexture(nil)
	  frame.ActiveLeft:SetTexture(nil)
	  frame.ActiveRight:SetTexture(nil)
	  frame.ActiveMiddle:SetTexture(nil)

      frame:HookScript('OnEnter', OnEnter) 
      frame:HookScript('OnLeave', OnLeave) 
      frame:SetAlpha(1) 
      end 
      frame.Fane = true 
   -- We can't trust sel. :( 
   if(i == SELECTED_CHAT_FRAME:GetID()) then 
      updateFS(frame, nil, nil, color.r, color.g, color.b) 
   else 
      updateFS(frame, nil, nil, 1, 1, 1) 
   end 
end 
hooksecurefunc('FCF_StartAlertFlash', function(frame) 
   local tab = _G['ChatFrame' .. frame:GetID() .. 'Tab'] 
   --updateFS(tab, true, nil, 1, 0, 0) 
   updateFS(tab, true, nil, color.r, color.g, color.b)
end) 
hooksecurefunc('FCFTab_UpdateColors', faneifyTab) 
for i=1,7 do 
   faneifyTab(_G['ChatFrame' .. i .. 'Tab']) 
end 
function Fane:ADDON_LOADED(event, addon) 
   if(addon == 'Blizzard_CombatLog') then 
      self:UnregisterEvent(event) 
      self[event] = nil 
      return CombatLogQuickButtonFrame_Custom:SetAlpha(.4) 
   end 
end 
Fane:RegisterEvent'ADDON_LOADED' 
Fane:SetScript('OnEvent', function(self, event, ...) 
   return self[event](self, event, ...) 
end)

end)