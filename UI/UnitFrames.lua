local _,ns = ...

--头像血条数值文本
local function ADDUIUpdateHealthBar(s)
	if not AddUIDB.unitf then return end
	if s.unit == "targettarget" or s.unit == "focustarget" then
		if not s.PCTargetPercent then
			s.PCTargetPercent = s:CreateFontString("PCTargetPercent", "OVERLAY")
			s.PCTargetPercent:SetVertexColor(1, 1, 1)
		end
		s.PCTargetPercent:SetFont("Fonts\\ARHei.ttf", 13, "OUTLINE")
		s.PCTargetPercent:ClearAllPoints()
		s.PCTargetPercent:SetPoint("TOP", s, "TOP", 2, 14)
		local HealthPercent = UnitHealthPercent(s.unit, true, CurveConstants.ScaleTo100)
		s.PCTargetPercent:SetText(string.format("%d%%", HealthPercent))
	end
	if GetCVar("statusTextDisplay") ~= "PERCENT" then 
		if 	s.TextString and s.currValue then 
			s.TextString:SetText(ns.ADDUIWK(s:GetValue())) 
		end
		if 	s.RightText and s.currValue then
			s.RightText:SetText(ns.ADDUIWK(s:GetValue()))
		end
	end
end

local function ADDUIUpdateManaBar(s)
	if not AddUIDB.unitf then return end
	if GetCVar("statusTextDisplay") ~= "PERCENT" then 
		if 	s.TextString and s.currValue then 
			s.TextString:SetText(ns.ADDUIWK(s:GetValue())) 
		end
		if 	s.RightText and s.currValue then
			s.RightText:SetText(ns.ADDUIWK(s:GetValue()))
		end
	end
end

hooksecurefunc("UnitFrameHealthBar_OnUpdate", ADDUIUpdateHealthBar)
hooksecurefunc("UnitFrameManaBar_OnUpdate", ADDUIUpdateManaBar)

local function SetTargetSpellBar(self)
	if not AddUIDB.unitf then return end
	local parentFrame = self:GetParent();
	if parentFrame.buffsOnTop then
		self:ClearAllPoints();
		self:SetPoint("BOTTOMLEFT", parentFrame, "TOPLEFT", 47,parentFrame.auraRows*27-15);
	else--暴雪原来的逻辑
		local useSpellbarAnchor = (not parentFrame.buffsOnTop) and ((parentFrame.haveToT and parentFrame.auraRows > 2) or ((not parentFrame.haveToT) and parentFrame.auraRows > 0));

		local relativeKey = useSpellbarAnchor and parentFrame.spellbarAnchor or parentFrame;
		local pointX = useSpellbarAnchor and 18 or  (parentFrame.smallSize and 38 or 43);
		local pointY = useSpellbarAnchor and -10 or (parentFrame.smallSize and 3 or 5);

		if ((not useSpellbarAnchor) and parentFrame.haveToT) then
			pointY = parentFrame.smallSize and -48 or -46;
		end

		self:SetPoint("TOPLEFT", relativeKey, "BOTTOMLEFT", pointX, pointY);
	end
end
hooksecurefunc(TargetFrameSpellBar, "AdjustPosition", SetTargetSpellBar)
TargetFrameSpellBar:HookScript("OnShow", SetTargetSpellBar)

ns.event("PLAYER_LOGIN", function()
	if not AddUIDB.unitf then return end

	------------------------------------------------
	-- 修改默认头像
	------------------------------------------------
	SetCVar("threatShowNumeric", 0)	 --目标头像显示仇恨
	SetCVar("showTargetcastbar", 1)	--显示目标施法条

	SetCVar("noBuffDebuffFilterOnTarget", 0)--目标头像显示所有debuff

	hooksecurefunc("TargetFrame_UpdateBuffAnchor", function(self, buff, index)
		local aura = C_UnitAuras.GetBuffDataByIndex(self.unit, index)
		if not aura then return end
		if not buff.Stealable then return end
		local color = C_UnitAuras.GetAuraDispelTypeColor(self.unit, aura.auraInstanceID, ns.discolor)
		if color then
			buff.Stealable:SetVertexColor(color:GetRGBA())
			buff.Stealable:Show()
		else
			buff.Stealable:Hide()
		end
	end)

	local hptexture1 = "Interface\\AddOns\\AddUI\\UI\\media\\AD-TargetingFrame"
	local hptexture2 = "Interface\\AddOns\\AddUI\\UI\\media\\Raid-Bar-Hp-Fill"
	local hptexture3 = "UI-HUD-UnitFrame-Player-PortraitOff-Bar-Health-Status"
	local function BOSSHP()
		for i = 1, MAX_BOSS_FRAMES do
			local bossTargetFrame = _G["Boss"..i.."TargetFrame"];--Boss1TargetFrame
			bossTargetFrame.TargetFrameContent.TargetFrameContentMain.Name:SetWidth(150)
			--bossTargetFrame.TargetFrameContent.TargetFrameContentMain.Name:SetVertexColor(1, 1, 0)
			bossTargetFrame.TargetFrameContent.TargetFrameContentMain.Name:SetFont("Fonts\\ARHei.ttf", 12, "")
			bossTargetFrame.TargetFrameContent.TargetFrameContentMain.Name:SetPoint("TOPLEFT",77,-32)
			bossTargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar.HealthBarTexture:SetTexture(hptexture1)
			bossTargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar:SetStatusBarColor(ns.ADUnitClassColor(bossTargetFrame.unit))
		end
	end

	--头像颜色
	local function FrameBar(self)
		if self.TargetFrameContent then
			self.TargetFrameContainer.FrameTexture:SetVertexColor(0, 0, 0, 1)
			self.TargetFrameContent.TargetFrameContentMain.ReputationColor:Hide()
			self.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar:SetStatusBarTexture(hptexture1)
			self.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar:SetStatusBarColor(ns.ADUnitClassColor(self.unit))
		elseif self.HealthBar then
			if not self.HealthBar.SetStatusBarColor then return end
			self.HealthBar:SetStatusBarTexture(hptexture1)
			self.HealthBar:SetStatusBarColor(ns.ADUnitClassColor(self.unit))
		end
	end
	hooksecurefunc(TargetFrame, "CheckClassification", FrameBar)
	hooksecurefunc(FocusFrame, "CheckClassification", FrameBar)
	hooksecurefunc(TargetFrameToT, "Update", FrameBar)
	hooksecurefunc(FocusFrameToT, "Update", FrameBar)

	--头像材质
	local hp = CreateFrame("Frame")
	hp:RegisterEvent("PLAYER_ENTERING_WORLD")
	hp:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
	hp:RegisterEvent("PLAYER_SOFT_ENEMY_CHANGED")
	hp:RegisterEvent("PLAYER_SOFT_FRIEND_CHANGED")
	hp:SetScript("OnEvent", function(self, event, frame)
		if event == "PLAYER_ENTERING_WORLD" then
			PetFrameTexture:SetVertexColor(0, 0, 0, 1)
			PlayerFrame.PlayerFrameContainer.FrameTexture:SetVertexColor(0, 0, 0, 1)
			PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PlayerPortraitCornerIcon:SetVertexColor(0, 0, 0, 1)
			local playerHB = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar
			playerHB:SetStatusBarTexture(hptexture1)
			playerHB:SetStatusBarColor(ns.ADUnitClassColor("player"))

			local attackIcon = PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.AttackIcon
			attackIcon:SetPoint("TOPLEFT", PlayerName, "TOPLEFT", -13, 13)
			attackIcon:SetPoint("BOTTOMRIGHT", PlayerName, "TOPLEFT", 0, 0)
			attackIcon:SetScale(1.2)

			local targetName = TargetFrame.TargetFrameContent.TargetFrameContentMain.Name
			targetName:SetWidth(150)
			targetName:SetPoint("TOPLEFT", 40, -25)

			TargetFrameToT.HealthBar:SetStatusBarTexture(hptexture2)
			TargetFrameToT:SetFrameStrata("BACKGROUND")
			FocusFrameToT.HealthBar:SetStatusBarTexture(hptexture2)
			FocusFrameToT:SetFrameStrata("BACKGROUND")

		elseif event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" then
			BOSSHP()

		elseif event == "PLAYER_SOFT_ENEMY_CHANGED" or event == "PLAYER_SOFT_FRIEND_CHANGED" then
			FrameBar(TargetFrame)
			FrameBar(FocusFrame)
			BOSSHP()
		end
	end)

	--目标头像相关
	TargetFrameToT:ClearAllPoints()
	TargetFrameToT:SetPoint("RIGHT",TargetFrame,"RIGHT",15,-45)
	TargetFrameToT.Name:ClearAllPoints()
	TargetFrameToT.Name:SetPoint("TOPLEFT",TargetFrameToT,"BOTTOMLEFT",40,10)
	TargetFrameSpellBar.TextBorder:SetTexture(nil)
	TargetFrameSpellBar.TextBorder = ns.ADDUISET
	TargetFrameSpellBar:SetHeight(15)
	TargetFrameSpellBar.Icon:SetPoint("RIGHT",TargetFrameSpellBar,"LEFT",-3,0)
	TargetFrameSpellBar.Text:ClearAllPoints()
	TargetFrameSpellBar.Text:SetPoint("CENTER",TargetFrameSpellBar,"CENTER",0,0)
	TargetFrameSpellBar.Text.SetPoint = ns.ADDUISET
	TargetFrameSpellBar.Spark:SetHeight(30)		--施法条闪光高度
	--焦点头像相关
	FocusFrameToT:ClearAllPoints()
	FocusFrameToT:SetPoint("RIGHT",FocusFrame,"RIGHT",15,-45)
	FocusFrameToT.Name:ClearAllPoints()
	FocusFrameToT.Name:SetPoint("TOPLEFT",FocusFrameToT,"BOTTOMLEFT",40,10)
	FocusFrameSpellBar.TextBorder:SetTexture(nil)
	FocusFrameSpellBar.TextBorder = ns.ADDUISET
	FocusFrameSpellBar:SetHeight(15)
	FocusFrameSpellBar.Icon:SetPoint("RIGHT",FocusFrameSpellBar,"LEFT",-3,0)
	FocusFrameSpellBar.Text:ClearAllPoints()
	FocusFrameSpellBar.Text:SetPoint("CENTER",FocusFrameSpellBar,"CENTER",0,0)
	FocusFrameSpellBar.Text.SetPoint = ns.ADDUISET
	FocusFrameSpellBar.Spark:SetHeight(30)		--施法条闪光高度
	--施法条剩余时间
	local function ShowUnitCasting(self)
		if not self.Cooldown  then
			self.Cooldown = self:CreateFontString(nil)
			self.Cooldown:SetFont(SystemFont_Outline_Small:GetFont(), 15, "OUTLINE")	--施法时间文字大小
			self.Cooldown:SetJustifyH("RIGHT")
			self.Cooldown:SetPoint("LEFT", self, "RIGHT", 0, 0)
		end
		if self.casting and UnitCastingDuration and UnitCastingDuration(self.unit) then
			self.Cooldown:SetText(string.format("%.1f", UnitCastingDuration(self.unit):GetRemainingDuration()))
		elseif self.channeling and UnitChannelDuration and UnitChannelDuration(self.unit) then
			self.Cooldown:SetText(string.format("%.1f", UnitChannelDuration(self.unit):GetRemainingDuration()))
		end
	end
	TargetFrameSpellBar:HookScript("OnUpdate", ShowUnitCasting)
	FocusFrameSpellBar:HookScript("OnUpdate", ShowUnitCasting)

	--boss框体施法条
	for i = 1, MAX_BOSS_FRAMES do
		local bossTargetFrameSpellBar = _G["Boss"..i.."TargetFrameSpellBar"];
		bossTargetFrameSpellBar.TextBorder:SetTexture(nil)
		bossTargetFrameSpellBar.TextBorder = ns.ADDUISET
		bossTargetFrameSpellBar:SetHeight(12)
		bossTargetFrameSpellBar.Icon:SetSize(15,15)
		bossTargetFrameSpellBar.Icon:SetPoint("RIGHT",bossTargetFrameSpellBar,"LEFT",-3,0)
		bossTargetFrameSpellBar.Text:ClearAllPoints()
		bossTargetFrameSpellBar.Text:SetPoint("CENTER",bossTargetFrameSpellBar,"CENTER",0,0)
		bossTargetFrameSpellBar.Text.SetPoint = ns.ADDUISET
	end

	-- 隐藏头像伤害数字
	--------------------------------------------------
	PlayerFrame:UnregisterEvent("UNIT_COMBAT")
	PetFrame:UnregisterEvent("UNIT_COMBAT")
	PetName:SetFont("fonts\\ARHei.ttf", 12)


end)