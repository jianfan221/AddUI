local _,ns = ...
--修改自https://nga.178.com/read.php?tid=12269817&_fp=2
--12.1 版：战斗日志（CLEU / COMBAT_LOG_EVENT_UNFILTERED）已对插件关闭，改用 UNIT_COMBAT
--UNIT_COMBAT 就是暴雪头像上那串伤害数字用的数据源，事件本身没受限，但第 4 个参数 amount 是秘密值
--所以：数值能显示（交给 AbbreviateNumbers），但不能比较、不能运算
--拿不到的：法术图标（无 spellID）、过量伤害、吸收量、DOT/HOT/自动攻击 区分

local fontSize = ns.fontSize or 14
local fadeTime = ns.fadeTime or 8
local Fx, Fy = ns.Fx or 250, ns.Fy or -90
local Abbr = ns.value or AbbreviateNumbers	--ns.value = AddUI-API.lua 里的数值简化（可接秘密值）

--开关：AddUIDB.lightCT（设置界面 → 战斗 → 承受伤害提示，默认关闭）
local function IsEnabled()
	return AddUIDB and AddUIDB.lightCT
end

--承受伤害文字（BLOCK/RESIST/ABSORB/MISS 这类没有数值的提示用暴雪同一套全局表）
local function MissText(flagText)
	local text = CombatFeedbackText and CombatFeedbackText[flagText]
	return text or UNKNOWN
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterUnitEvent("UNIT_COMBAT", "player", "vehicle")
eventFrame:SetScript("OnEvent", function(self, event,...)
	if not IsEnabled() then return end
	self[event](self,...)
end)

local LightCTFrame = CreateFrame("ScrollingMessageFrame", "LightCTFrame", UIParent)
LightCTFrame:SetSpacing(3)--间距
LightCTFrame:SetMaxLines(8)--行数
LightCTFrame:SetSize(120, 200)--大小
LightCTFrame:SetFadeDuration(0.5)--淡出
LightCTFrame:SetJustifyH("RIGHT")
LightCTFrame:SetTimeVisible(fadeTime)--持续
LightCTFrame:SetFont("fonts\\ARHei.ttf" , fontSize+6, "OUTLINE")
LightCTFrame:SetPoint("RIGHT", UIParent, "CENTER", Fx, Fy)

function eventFrame:PLAYER_LOGIN()
	if not IsEnabled() then return end

	SetCVar("enableFloatingCombatText", 0)

	--编辑模式可拖动（AddUI-API 的 ns.AddEdit：九宫格高亮框 + 位置存 AddUIDB.LightCTFrame_Edit）
	ns.AddEdit(LightCTFrame, "承受伤害")

	--跟随聆听对话框（ctp）优先，覆盖上面的保存位置
	if AddUIDB and AddUIDB.ctp and TalkingHeadFrame and TalkingHeadFrame.Selection then
		LightCTFrame:ClearAllPoints()
		LightCTFrame:SetPoint("BOTTOMRIGHT", TalkingHeadFrame.Selection, "BOTTOMRIGHT", 0, 0)
	end
end

--秘密值 amount 不能判断是否为 0，所以先看 flagText 再决定显示什么
local function DamageText(flagText, amount, schoolMask)
	if flagText == "ABSORB" then
		return MissText(flagText), 0, 1, 1		--全吸收时 amount 为 0，只有文字
	elseif flagText == "BLOCK" or flagText == "BLOCK_REDUCED" or flagText == "RESIST" or flagText == "MISS" then
		return MissText(flagText), 1, 1, 1
	end

	local text = "-"..Abbr(amount)
	if flagText == "CRITICAL" or flagText == "CRUSHING" then
		text = "C"..text
	end

	if not schoolMask or schoolMask == 0 or schoolMask == 1 then
		return text, 1, 0, 0		--物理
	end
	return text, 1, 0, 1		--法术
end

function eventFrame:UNIT_COMBAT(unitTarget, event, flagText, amount, schoolMask)
	if event == "WOUND" then
		local text, r, g, b = DamageText(flagText, amount, schoolMask)
		LightCTFrame:AddMessage(text, r, g, b)
	elseif event == "HEAL" then
		local text = "+"..Abbr(amount)
		if flagText == "CRITICAL" then
			text = "C"..text
		end
		LightCTFrame:AddMessage(text, 0, 1, 0)
	elseif event == "MISS" or event == "BLOCK" or event == "DODGE" or event == "PARRY" or event == "EVADE" or event == "IMMUNE" or event == "DEFLECT" or event == "RESIST" or event == "INTERRUPT" then
		LightCTFrame:AddMessage(MissText(event), 1, 1, 1)
	end
end
