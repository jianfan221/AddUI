local _,ns = ...
ns.tips("BUFF栏左侧取消光环按钮")

local needcancel = [[
/cancelAura 操控时间
]]

local function CreateFrames()
	if ADDUIcancelAuraButton then return end
	--创建框架
	local ADDUIcancelAuraButton = CreateFrame("Frame", "ADDUIcancelAuraButton", BuffFrame);
	ADDUIcancelAuraButton:SetSize(60, 60)
	ADDUIcancelAuraButton:SetPoint("TOPRIGHT",BuffFrame.Selection,"TOPLEFT",0,0); 
	--创建背景
	ADDUIcancelAuraButton.Background = ADDUIcancelAuraButton:CreateTexture(nil, "BACKGROUND")
	ADDUIcancelAuraButton.Background:SetTexture(130937)
	ADDUIcancelAuraButton.Background:SetAllPoints(ADDUIcancelAuraButton)
	ADDUIcancelAuraButton.Background:SetColorTexture(0, 0, 0, 0)
	ADDUIcancelAuraButton.tiptext = ADDUIcancelAuraButton:CreateFontString(nil, "BACKGROUND")
	ADDUIcancelAuraButton.tiptext:SetFont(SystemFont_Outline_Small:GetFont(), 20, "OUTLINE")
	ADDUIcancelAuraButton.tiptext:SetPoint("CENTER", ADDUIcancelAuraButton, "CENTER", 0, 0)
	ADDUIcancelAuraButton.tiptext:SetText("取消\n操控")
	ADDUIcancelAuraButton.tiptext:SetTextColor(0.5,0.5,0.5)
	ADDUIcancelAuraButton.tiptext:Hide()
	--取消按钮
	ADDUIcancelAuraButton.ADcancelAuraButton = CreateFrame("CheckButton", "ADcancelAuraButton", ADDUIcancelAuraButton, "SecureActionButtonTemplate")
	ADDUIcancelAuraButton.ADcancelAuraButton:SetAttribute("type", "macro")
	ADDUIcancelAuraButton.ADcancelAuraButton:SetAttribute("macrotext", needcancel)
	ADDUIcancelAuraButton.ADcancelAuraButton:SetAllPoints(ADDUIcancelAuraButton)
	ADDUIcancelAuraButton.ADcancelAuraButton:RegisterForClicks("AnyDown", "AnyUp")
	ADDUIcancelAuraButton.ADcancelAuraButton:SetScript("OnEnter", function(self)
		ADDUIcancelAuraButton.Background:SetColorTexture(0, 0, 0, .5)
		ADDUIcancelAuraButton.tiptext:Show()
	end)
	ADDUIcancelAuraButton.ADcancelAuraButton:SetScript("OnLeave", function(self)
		ADDUIcancelAuraButton.Background:SetColorTexture(0, 0, 0, 0)
		ADDUIcancelAuraButton.tiptext:Hide()
	end)
	--图标材质
	ADDUIcancelAuraButton.T = ADDUIcancelAuraButton:CreateTexture()
	ADDUIcancelAuraButton.T:SetAllPoints(ADDUIcancelAuraButton)
	ADDUIcancelAuraButton.T:Hide()
	--操控时间的百分比
	ADDUIcancelAuraButton.text = ADDUIcancelAuraButton:CreateFontString(nil)
	ADDUIcancelAuraButton.text:SetFont(SystemFont_Outline_Small:GetFont(), 30, "OUTLINE")
	ADDUIcancelAuraButton.text:SetPoint("TOP", ADDUIcancelAuraButton, "BOTTOM", 0, 0)
	ADDUIcancelAuraButton.text:Hide()
	--冷却时间
	ADDUIcancelAuraButton.Cooldown = CreateFrame("Cooldown", nil, ADDUIcancelAuraButton, "CooldownFrameTemplate")
	ADDUIcancelAuraButton.Cooldown:SetAllPoints(ADDUIcancelAuraButton.T)
	ADDUIcancelAuraButton.Cooldown:SetHideCountdownNumbers(false)
	ADDUIcancelAuraButton.Cooldown:SetUseCircularEdge(true)
	ADDUIcancelAuraButton.Cooldown:SetReverse(true)
	ADDUIcancelAuraButton.Cooldown:SetScript("OnCooldownDone", function(self)
		ADDUIcancelAuraButton.T:SetTexture(nil)
		ADDUIcancelAuraButton.text:Hide()
		ADDUIcancelAuraButton.SAA:Hide()
		ADDUIcancelAuraButton.SAA.ProcStartAnim:Stop();
	end)
	local regon = ADDUIcancelAuraButton.Cooldown:GetRegions()
	if regon.GetText then 
		regon:SetFont(STANDARD_TEXT_FONT, 30, "OUTLINE")
	end
	
	
	ADDUIcancelAuraButton.SAA = CreateFrame("Frame", nil, ADDUIcancelAuraButton, "ActionButtonSpellAlertTemplate");
	local frameWidth, frameHeight = ADDUIcancelAuraButton:GetSize();
	ADDUIcancelAuraButton.SAA:SetSize(frameWidth * 1.4, frameHeight * 1.4);
	ADDUIcancelAuraButton.SAA:SetPoint("CENTER", ADDUIcancelAuraButton, "CENTER", 0, 0);
	
	ADDUIcancelAuraButton.ADcancelAuraButton:HookScript("OnClick", function()
		ADDUIcancelAuraButton.text:Hide()
		ADDUIcancelAuraButton.T:Hide()
		ADDUIcancelAuraButton.T:SetTexture(nil)
		ADDUIcancelAuraButton.Cooldown:SetCooldown(0,0)
		ADDUIcancelAuraButton.SAA:Hide()
		ADDUIcancelAuraButton.SAA.ProcStartAnim:Stop();
	end)
	
end

--设置光环
local function MYAURA(spellId)
	if spellId == 342247 then
		if not ADDUIcancelAuraButton.text:IsShown() then
			PlaySoundFile("Interface\\AddOns\\AddUI\\UI\\media\\342247.mp3","Master")
			local HealthPercent = UnitHealthPercent("player", true, CurveConstants.ScaleTo100)
			ADDUIcancelAuraButton.text:Show()
			ADDUIcancelAuraButton.text:SetText(string.format("%d%%",HealthPercent))
			ADDUIcancelAuraButton.T:Show()
			ADDUIcancelAuraButton.T:SetTexture(985088)
			ADDUIcancelAuraButton.Cooldown:SetCooldown(GetTime(),10)
			ADDUIcancelAuraButton.SAA:Show()
			ADDUIcancelAuraButton.SAA.ProcStartAnim:Play();
		else
			ADDUIcancelAuraButton.text:Hide()
			ADDUIcancelAuraButton.text:SetText("")
			ADDUIcancelAuraButton.T:Hide()
			ADDUIcancelAuraButton.T:SetTexture(nil)
			ADDUIcancelAuraButton.Cooldown:SetCooldown(0,0)
			ADDUIcancelAuraButton.SAA:Hide()
			ADDUIcancelAuraButton.SAA.ProcStartAnim:Stop();
		end
	end
end

local playerClass
local function OnCancelAuraEvent(event, unit, _, spellId)
	if not playerClass then
		_,playerClass = UnitClass("player")
	end
	if playerClass ~= "MAGE" then return end
	
	if event == "PLAYER_ENTERING_WORLD" then 
		CreateFrames()
	elseif event == 'UNIT_SPELLCAST_SUCCEEDED' and unit == "player" then
		MYAURA(spellId)
	end
end

ns.event('UNIT_AURA', OnCancelAuraEvent)
ns.event('PLAYER_ENTERING_WORLD', OnCancelAuraEvent)
ns.event('UNIT_SPELLCAST_SUCCEEDED', OnCancelAuraEvent)



