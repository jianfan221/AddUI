local _,ns = ...
ns.tips("让Details昵称可以改中文")
ns.event("PLAYER_ENTERING_WORLD", function()
--details昵称扩展器https://wago.io/uq0Uox6Ta/3
--details改昵称新版https://wago.io/gyf9vnUCZ
if _G._detalhes then
    
    local nickVersion = _G.LibStub.minors["NickTag-1.0"]
    
    function _G.NickTag:CheckName (name)
        return true
    end
    
    function _G._detalhes:SetNickname (name)
        --> check data before
        assert (type (name) == "string", "NickTag 'SetNickname' expects a string on #1 argument.")
        
        --> check if the nickname is okey to allowed to use.
        local okey, errortype = _G.NickTag:CheckName(name)
        if (not okey) then
            _G.NickTag:Msg ("SetNickname() invalid name ", name)
            return false, errortype
        end
        
        local playerName = UnitName ("player")
        
        --> get the full nick table.
        local nickTable = _G.NickTag:GetNicknameTable (playerName)
        if (not nickTable) then
            nickTable = _G.NickTag:Create (playerName, true)
        end
        
        --> change the nickname for the player nick table.
        if (nickTable [1] ~= name) then
            nickTable [1] = name
            
            --increase the table revision
            _G.NickTag:IncRevision()
            
            --> send the update for script which need it.
            _G.NickTag.callbacks:Fire ("NickTag_Update", CONST_INDEX_NICKNAME)
            
            --> schedule a update for revision and broadcast full persona.
            --> this is a kind of protection for scripts which call SetNickname, SetColor and SetAvatar one after other, so scheduling here avoid three revisions upgrades and 3 broadcasts to the guild.            
            if (not _G.NickTag.send_scheduled) then
                _G.NickTag.send_scheduled = true
                _G.NickTag:ScheduleTimer ("SendPersona", 1)
            end
            
        else
            _G.NickTag:Msg ("SetNickname() name is the same on the pool ", name, nickTable [1])
        end
        
        return true
    end
    
    function _G.NickTag:SendPersona()
        
        --check if the player has a persona
        local nickTable = _G.NickTag:GetNicknameTable (UnitName ("player"), true)
        if (not nickTable) then
            return
        end
        _G.NickTag:Msg ("SendPersona() -> broadcast")
        
        if (_G.NickTag.EventFrame.ScheduledSend and not _G.NickTag.EventFrame.ScheduledSend._cancelled) then
            _G.NickTag.EventFrame.ScheduledSend:Cancel()
        end
        _G.NickTag.EventFrame.ScheduledSend = nil
        _G.NickTag.EventFrame.InfoSendCooldown = time() + 29
        
        --> updating my own persona
        _G.NickTag.send_scheduled = false
        
        --> auto change nickname if we have an invalid nickname
        if (_G.NickTag:GetNickname (UnitName ("player")) == _G.LibStub ("AceLocale-3.0"):GetLocale ("NickTag-1.0")["STRING_INVALID_NAME"]) then
            nickTable [CONST_INDEX_NICKNAME] = UnitName ("player")
        end
        
        --> broadcast over guild channel
        if (IsInGuild()) then
            if (isMaster) then
                _G.NickTag:SyncSiblings()
            end
            _G.NickTag:SendCommMessage ("NickTag", _G.NickTag:Serialize (1, 0, _G.NickTag:GetNicknameTable (UnitName ("player")), nickVersion), "GUILD")
        end
        
        _G.NickTag:SendCommMessage ("NickTag", _G.NickTag:Serialize (1, 0, _G.NickTag:GetNicknameTable (UnitName ("player")), nickVersion), "RAID")
        
    end
    
end


end)