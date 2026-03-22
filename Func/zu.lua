local _,ns = ...
ns.event("PLAYER_LOGIN", function()

--密语自动邀请
local function OnWhisperEvent(event, arg1, arg2, _, _, _, _, _, _, _, _, _, _, arg13)
	if IsInInstance() then return end
	if not AddUIDB.zu then return end
	if (not IsInGroup() or UnitIsGroupLeader("player")) 
		and GetNumGroupMembers() <40			--当队伍小于40人执行邀请 
		and (arg1 == "123") 			--自动邀请“123”
		or (arg1 == "组")			--自动邀请“组”--包含关键字改成or arg1:lower():match("组") )	
	then
	if (event== "CHAT_MSG_BN_WHISPER") then
		local characterName = C_BattleNet.GetAccountInfoByID(arg13).gameAccountInfo.characterName
		local realmName = C_BattleNet.GetAccountInfoByID(arg13).gameAccountInfo.realmDisplayName
		if characterName and realmName then
		C_PartyInfo.InviteUnit(characterName.."-"..realmName)
		else
		print("对方隐身或者无角色在线,无法邀请")
		end
	else
		C_PartyInfo.InviteUnit(arg2)
	end
	end
end

ns.event("CHAT_MSG_WHISPER", OnWhisperEvent)
ns.event("CHAT_MSG_BN_WHISPER", OnWhisperEvent)


end)