
-------------------------------------
-- 聊天框Tab键切換頻道
-------------------------------------

local IncludeKeywords = {"大脚世界",}
local function checkChannel(id)
    local chanId, chanName = GetChannelName(id)
    if (chanId < 1) then return false end
    if (#IncludeKeywords == 0) then return true end
    for _, word in ipairs(IncludeKeywords) do
        if (strfind(chanName,word)) then return true end
    end
end

local TabChannels = {
    { TypeInfoKey = "SAY", check = false },
	{ TypeInfoKey = "GUILD", check = IsInGuild },					---公会频道
--  { TypeInfoKey = "OFFICER", check = CanEditOfficerNote },		---公会官员频道
    { TypeInfoKey = "PARTY", check = function() return IsInGroup(LE_PARTY_CATEGORY_HOME) end },
    { TypeInfoKey = "RAID", check = function() return IsInRaid(LE_PARTY_CATEGORY_HOME) end },
    { TypeInfoKey = "INSTANCE_CHAT", check = function() return IsInGroup(LE_PARTY_CATEGORY_INSTANCE) end },
    { TypeInfoKey = "CHANNEL1", check = function() return checkChannel(1) end },
    { TypeInfoKey = "CHANNEL2", check = function() return checkChannel(2) end },
    { TypeInfoKey = "CHANNEL3", check = function() return checkChannel(3) end },
    { TypeInfoKey = "CHANNEL4", check = function() return checkChannel(4) end },
    { TypeInfoKey = "CHANNEL5", check = function() return checkChannel(5) end },
    { TypeInfoKey = "CHANNEL6", check = function() return checkChannel(6) end },
    { TypeInfoKey = "CHANNEL7", check = function() return checkChannel(7) end },
    { TypeInfoKey = "CHANNEL8", check = function() return checkChannel(8) end },
    { TypeInfoKey = "CHANNEL9", check = function() return checkChannel(9) end },
}

local function MatchChannel(m, n)
    for i = m, n do
        if (not TabChannels[i].check or TabChannels[i].check()) then
            return i
        end
    end
end

hooksecurefunc("ChatEdit_CustomTabPressed", function(self)

    local attr = self:GetAttribute("chatType")
    local cid = self:GetAttribute("channelTarget")
    local pos = 0
    
    -- 处理频道属性
    if (attr == "CHANNEL" and cid) then 
        attr = attr .. cid 
    end
    
    -- 查找当前位置
    for i, v in ipairs(TabChannels) do
        if (v.TypeInfoKey == attr) then 
            pos = i 
            break
        end
    end
	
    -- 查找下一个可用频道
    local idx = MatchChannel(pos + 1, #TabChannels)
    if (not idx) then
        idx = MatchChannel(1, pos - 1)
    end
    
    -- 切换到找到的频道
    if (idx) then
        local channelType = TabChannels[idx].TypeInfoKey
        local i, j = string.find(channelType, "CHANNEL")
        
        if (i) then
            local channelNum = string.sub(channelType, j + 1)
            self:SetAttribute("channelTarget", tonumber(channelNum))
            self:SetAttribute("chatType", "CHANNEL")
        else
            self:SetAttribute("chatType", channelType)
            self:SetAttribute("channelTarget", nil)
        end
        
        ChatEdit_UpdateHeader(self)
    end
end)