local _,ns = ...

-- 打断未命中提醒：按下打断后 0.02 秒内没有同一时间的打断事件，就播放提示音
-- 注意：打断普通读条触发 UNIT_SPELLCAST_INTERRUPTED，打断引导施法只触发 UNIT_SPELLCAST_CHANNEL_STOP，两个都要监听
-- 只统计敌对单位被打断（UnitCanAttack），队友或自己被打断不算；副本内令牌是秘密值无法判断，保守算断中

local MISS_SOUND = "Interface\\AddOns\\AddUI\\UI\\media\\InterruptNo.mp3"

-- 各职业打断技能（12.x 正式服）
local INTERRUPT_SPELLS = {
	[6552]   = true, --战士-拳击
	[96231]  = true, --圣骑士-责难
	[47528]  = true, --死亡骑士-心灵冰冻
	[147362] = true, --猎人-反制射击
	[1766]   = true, --盗贼-脚踢
	[57994]  = true, --萨满祭司-风剪
	[2139]   = true, --法师-法术反制
	[116705] = true, --武僧-切喉手
	[106839] = true, --德鲁伊-迎头痛击
	[183752] = true, --恶魔猎手-瓦解
	[351338] = true, --唤魔师-镇压
}

local pressTime        -- 按下打断的时间
local interruptTime    -- 按下后是否真的打断了

-- 有怪被打断：只认敌对单位被打断（队友/自己被打断不算，避免误判成自己断中了）
local function markInterrupted(event, unitTarget,_,_, guid)
	if not pressTime or interruptTime then return end
	if guid == nil then return end
	if not ns.MM(unitTarget) and not UnitCanAttack("player", unitTarget) then return end
	interruptTime = true
end

ns.event("UNIT_SPELLCAST_INTERRUPTED", markInterrupted)   -- 普通读条被打断
ns.event("UNIT_SPELLCAST_CHANNEL_STOP", markInterrupted)  -- 引导施法被打断（不会触发 INTERRUPTED）

-- 按下打断：记录按下时间，0.01 秒后没断到就响一声
ns.event("UNIT_SPELLCAST_SUCCEEDED", function(event, unitTarget, castGUID, spellID)
	if not (AddUIDB and AddUIDB.interruptAlert) then return end
	if unitTarget ~= "player" or not INTERRUPT_SPELLS[spellID] then return end

	pressTime = GetTime()

	C_Timer.NewTimer(0.01, function()
		if not interruptTime then
			PlaySoundFile(MISS_SOUND, "Master")
		end
		pressTime = nil
		interruptTime = nil
	end)
end)
