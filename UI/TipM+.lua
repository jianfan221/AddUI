local _,ns = ...
ns.tips("大秘境分数界面鼠标提示优化")--https://ngabbs.com/read.php?tid=42357797

local function HookDungeonIcons()
	if not ChallengesFrame then
		return
	end
	
	for _, icon in ipairs(ChallengesFrame.DungeonIcons) do
		icon:HookScript("OnEnter", function(self)
				local mapChallengeModeID = self.mapID
				if not mapChallengeModeID then return end
				
				-- 副本完成时间记录为UTC，需手动调整为当地时间
				local offset = 8
				
				local dungeonName, _, timeLimit = C_ChallengeMode.GetMapUIInfo(mapChallengeModeID)
				if not dungeonName or not timeLimit then return end
				
				local intimeInfo, overtimeInfo = C_MythicPlus.GetSeasonBestForMap(mapChallengeModeID)
				
				
				GameTooltip:ClearLines()
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				
				if intimeInfo then
					GameTooltip:AddLine(dungeonName, 1, 1, 1)
					
					local scoreColor = C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor(intimeInfo.dungeonScore)
					if scoreColor then
						GameTooltip:AddLine("评分: |c" .. scoreColor:GenerateHexColor() .. intimeInfo.dungeonScore .. "|r")
					else
						GameTooltip:AddLine("评分: " .. intimeInfo.dungeonScore)
					end
					
					GameTooltip:AddLine(" ")
					GameTooltip:AddLine("最佳记录", 1, 0.75, 0)
					GameTooltip:AddLine("等级 " .. intimeInfo.level, 1, 1, 1)
					
					local completionTimeFormatted = string.format("%02d:%02d", math.floor(intimeInfo.durationSec / 60), intimeInfo.durationSec % 60)
					local remainingTime = timeLimit - intimeInfo.durationSec
					local remainingTimeFormatted
					
					if remainingTime >= 0 then
						remainingTimeFormatted = string.format("还剩 %02d:%02d", math.floor(remainingTime / 60), remainingTime % 60)
					else
						remainingTimeFormatted = string.format("超时 %02d:%02d", math.abs(math.floor(remainingTime / 60)), math.abs(remainingTime % 60))
					end
					
					GameTooltip:AddLine("时间 " .. completionTimeFormatted .. " (" .. remainingTimeFormatted .. ")", 1, 1, 1)
					GameTooltip:AddLine(" ")
					
					GameTooltip:AddLine("队伍成员", 1, 0.75, 0)
					if intimeInfo.members then
						for _, member in ipairs(intimeInfo.members) do
							if member then
								local className = select(2,GetClassInfo(member.classID)) or "未知职业"
								local color = RAID_CLASS_COLORS[className] or {r = 255, g = 255, b = 255}
								local memberName = member.name or "未知"
								local specName = select(2,GetSpecializationInfoByID(member.specID)) or "未知专精"
								GameTooltip:AddLine(memberName.."("..specName..")", color.r, color.g, color.b)
							end
						end
					end
					
					GameTooltip:AddLine(" ")
					local totalTimeFormatted = string.format("%02d:%02d", math.floor(timeLimit / 60), timeLimit % 60)
					GameTooltip:AddLine("副本时间: " .. totalTimeFormatted, 1, 1, 1)
					
					local completionDate = intimeInfo.completionDate
					if completionDate then
						local adjustedYear = completionDate.year
						local adjustedMonth = completionDate.month
						local adjustedDay = completionDate.day
						local adjustedHour = completionDate.hour + offset
						local adjustedMinute = completionDate.minute
						
						if adjustedHour >= 24 then
							adjustedHour = adjustedHour - 24
							adjustedDay = adjustedDay + 1
						end
						
						GameTooltip:AddLine(string.format("完成日期: %d/%02d/%02d %02d:%02d", adjustedYear, adjustedMonth, adjustedDay, adjustedHour, adjustedMinute), 1, 1, 1)
					else
						GameTooltip:AddLine("日期: 无法获取", 1, 1, 1)
					end
				else
					GameTooltip:AddLine("本赛季尚未有记录", 1, 0.5, 0.5)
				end
				
				GameTooltip:Show()
		end)
		
		icon:HookScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end
end

local T=CreateFrame("frame")
T:RegisterEvent('ADDON_LOADED')
T:SetScript("OnEvent",function(_,_,msg)
	if msg == 'Blizzard_ChallengesUI' then
		HookDungeonIcons()
		ChallengesFrame:HookScript("OnShow",HookDungeonIcons)
	end
end)