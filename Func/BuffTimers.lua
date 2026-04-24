local _,ns = ...

SetCVar("buffDurations", 1)	--显示buff持续时间,有些插件会给关了


ns.tips("装备面板显示当前等级和最高等级")
hooksecurefunc('PaperDollFrame_SetItemLevel', function(self, unit) 
   if (unit ~= 'player') then return end 

   local total, equip = GetAverageItemLevel() 
   if (total > 0) then total = string.format('%.1f', total) end 
   if (equip > 0) then equip = string.format('%.1f', equip) end 

   local ilvl = equip 
   if (equip < total) then 
      ilvl = equip .. ' / ' .. total 
   end
   
   local total2,equip2 = GetAverageItemLevel() 
   if (total2 > 0) then total2 = string.format('%.3f', total2) end 
   if (equip2 > 0) then equip2 = string.format('%.3f', equip2) end
   local ilvl2 = equip2
   if (equip2 < total2) then 
      ilvl2 = equip2 .. ' / ' .. total2
   end 

   -- local ilvlLine = _G[self:GetName() .. 'StatText'] 
   CharacterStatsPane.ItemLevelFrame.Value:SetText(ilvl) 

   self.tooltip =  "|cffffffff".. STAT_AVERAGE_ITEM_LEVEL .. ' ' .. ilvl2 
end)
--[[
ns.tips("给装备面板增加移动速度")--http://bbs.ngacn.cc/read.php?&tid=9727518
table.insert(PAPERDOLL_STATCATEGORIES[1].stats,{ stat = "MOVESPEED" }) 
   
--关于移动速度代码(不然会出现错乱) 
local tempstatFrame
hooksecurefunc("PaperDollFrame_SetMovementSpeed",function(statFrame, unit) 
      if(tempstatFrame and tempstatFrame~=statFrame)then 
        tempstatFrame:SetScript("OnUpdate",nil); 
      end 
      statFrame:SetScript("OnUpdate", MovementSpeed_OnUpdate); 
      tempstatFrame = statFrame; 
      statFrame:Show(); 
end) ]]