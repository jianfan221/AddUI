local addonName, ns = ...
local HISTORY_LIMIT = 50
local sessionHistory = {}
local unpack = table.unpack or unpack

local function IsCombatChatFrame(frameID)
    if type(frameID) ~= "number" or frameID < 1 then
        return false
    end
    local name = select(1, GetChatWindowInfo(frameID))
    if type(name) ~= "string" then
        return false
    end
    name = name:lower()
    return name:find("combat") or name:find("战斗")
end

local function AddMessageToHistory(frameID, text, r, g, b)
    if type(frameID) ~= "number" or frameID < 1 then return end
    if type(text) ~= "string" then return end

    local storedText
    local ok = pcall(function()
        local rawText = string.gsub(text, "^|cff888888%[%d%d:%d%d:%d%d%]|r%s*", "")
        local timestamp = date("%H:%M:%S")
        storedText = string.format("|cff888888[%s]|r %s", timestamp, rawText)
    end)
    if not ok or type(storedText) ~= "string" then
        storedText = text
    end

    sessionHistory[frameID] = sessionHistory[frameID] or {}
    local entry
    if type(r) == "number" and type(g) == "number" and type(b) == "number" then
        entry = { text = storedText, r = r, g = g, b = b }
    else
        entry = storedText
    end
    table.insert(sessionHistory[frameID], entry)
    if #sessionHistory[frameID] > HISTORY_LIMIT then
        table.remove(sessionHistory[frameID], 1)
    end
end
local function OnChatMessage(frame, text, r, g, b)
    local id
    if type(frame) == "table" and type(frame.GetID) == "function" then
        id = frame:GetID()
    end
    if IsCombatChatFrame(id) then
        return
    end
    if C_Secrets and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret() then
        return
    end
    AddMessageToHistory(id, text, r, g, b)
end
hooksecurefunc("ChatFrame_AddMessage", OnChatMessage)
local function HookChatFrame(frame)
    if not frame or type(frame.AddMessage) ~= "function" then return end
    hooksecurefunc(frame, "AddMessage", OnChatMessage)
end
local function HookAllChatFrames()
    for i = 1, NUM_CHAT_WINDOWS do
        local frame = _G["ChatFrame"..i]
        if frame then
            HookChatFrame(frame)
        end
    end
end
local function SaveHistory()
    AddUICharaDB = AddUICharaDB or {}
    AddUICharaDB.ChatHistory = {}
    local history = AddUICharaDB.ChatHistory
    for frameID, messages in pairs(sessionHistory) do
        if IsCombatChatFrame(frameID) then
            -- don't save combat-log windows
        elseif type(frameID) == "number" and #messages > 0 then
            history[frameID] = { unpack(messages) }
        end
    end
end
local function RestoreHistory()
    if not AddUICharaDB or not AddUICharaDB.ChatHistory then return end
    for frameID, messages in pairs(AddUICharaDB.ChatHistory) do
        if IsCombatChatFrame(frameID) then
            -- skip combat-log windows
        elseif type(frameID) == "number" and type(messages) == "table" and #messages > 0 then
            local frame = _G["ChatFrame"..frameID]
            if frame then
                for _, entry in ipairs(messages) do
                    if type(entry) == "table" and entry.text then
                        frame:AddMessage(entry.text, entry.r, entry.g, entry.b)
                    else
                        frame:AddMessage(entry)
                    end
                end
            end
        end
    end
end
local function eventFrame(event)
    if not AddUIDB or not AddUIDB.chatm then return end
    if event == "PLAYER_LOGOUT" or event == "PLAYER_LEAVING_WORLD" then
        SaveHistory()
    end
    if event == "PLAYER_ENTERING_WORLD" then
        HookAllChatFrames()
        RestoreHistory()
    end
end
ns.event("PLAYER_LOGOUT",eventFrame)
ns.event("PLAYER_LEAVING_WORLD",eventFrame)
ns.event("PLAYER_ENTERING_WORLD",eventFrame)
