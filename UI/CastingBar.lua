local _,ns = ...
SetCVar("ShakeStrengthUI",1)

--------------施法条-------------
local useTexture,empowerCast	--储存材质
local stageColors = {
	{r=1.0, g=0.1, b=0.5}, --粉红变粉
	{r=0.0, g=0.5, b=1.0}, --蓝色变青
	{r=1.0, g=0.5, b=0.0}, --橙色变黄
	{r=0.5, g=0.0, b=1.0}, --紫色变粉
	{r=0.5, g=1.0, b=0.1}, --青绿变黄
}

local function OnCastingEvent(event, castunit)
	if not AddUIDB.cast then return end
	if castunit ~= "player"  then return end	--判断是不是自己的施法条

	-------------------------------------
	--自身施法条修改
	PlayerCastingBarFrame:SetHeight(AddUIDB.castHeight)--施法条高度
	PlayerCastingBarFrame:SetWidth(AddUIDB.castWidth)--施法条宽度
	PlayerCastingBarFrame.Spark:SetSize(2,AddUIDB.castHeight*1.5)--施法条闪光大小
	PlayerCastingBarFrame.Icon:Show()--施法条图标显示
	PlayerCastingBarFrame.Icon:SetSize(AddUIDB.castHeight,AddUIDB.castHeight)--施法条图标大小
	PlayerCastingBarFrame.Icon:SetPoint("RIGHT",PlayerCastingBarFrame,"LEFT",-1,0)--图标位置
	PlayerCastingBarFrame.TextBorder:SetTexture(nil)	--文字框大背景
	PlayerCastingBarFrame.Border:SetTexture(nil)	--施法条边框
	PlayerCastingBarFrame.Border:Hide()
	PlayerCastingBarFrame.BorderMask:SetTexture(nil)--闪光尾巴
	
	PlayerCastingBarFrame:SetFrameStrata("TOOLTIP")	--施法条框架优先级
	PlayerCastingBarFrame.Text:ClearAllPoints()--文本位置
	PlayerCastingBarFrame.Text:SetPoint("CENTER",PlayerCastingBarFrame,"CENTER",0,0)--文本位置
	
	
	if not AddUIDB.SCastTexture then return end
	PlayerCastingBarFrame.Background:SetTexture(130937)--背景材质
	PlayerCastingBarFrame.Background:SetColorTexture(0,0,0,.5)--背景颜色
	PlayerCastingBarFrame.Background:ClearAllPoints();--背景位置
	PlayerCastingBarFrame.Background:SetPoint("TOPLEFT",0,0)
	PlayerCastingBarFrame.Background:SetPoint("BOTTOMRIGHT",0,0)
	empowerCast = false
	if event == 'UNIT_SPELLCAST_EMPOWER_START' then
		for i = 1, PlayerCastingBarFrame.NumStages - 1, 1 do
			local chargeTierName = "ChargeTier" .. i
			local tierFrame = PlayerCastingBarFrame.ChargeTierPool[chargeTierName]
			local color = stageColors[i] or {r=1, g=1, b=1}
			
			if tierFrame then
				tierFrame.Normal:SetTexture(130937)
				tierFrame.Normal:SetVertexColor(color.r, color.g, color.b)
				
				tierFrame.Disabled:SetTexture(130937)
				tierFrame.Disabled:SetVertexColor(color.r, color.g, color.b)

				tierFrame.Glow:SetTexture(130937)
				tierFrame.Glow:SetVertexColor(color.r, color.g, color.b)
			end
		end
		empowerCast = true
		return
	end
	PlayerCastingBarFrame.ChargeFlash:Hide()
	
	useTexture = ns.RerollTextrue[math.random(1, #ns.RerollTextrue)]
	if AddUIDB.CastTexture == "随机使用材质" then
		PlayerCastingBarFrame:SetStatusBarTexture(ns.CastBarTextrue[useTexture])
	else
		PlayerCastingBarFrame:SetStatusBarTexture(ns.CastBarTextrue[AddUIDB.CastTexture])
	end
	
end

ns.event('UNIT_SPELLCAST_EMPOWER_START', OnCastingEvent)	--蓄力
ns.event('UNIT_SPELLCAST_CHANNEL_START', OnCastingEvent)	--引导
ns.event('UNIT_SPELLCAST_START', OnCastingEvent)	--读条

local function HideAnims(self)
	if not AddUIDB.SCastTexture then return end
	if empowerCast then return end
       -- self.FadeOutAnim:Stop() --淡出
	self.InterruptGlow:Hide()--打断内红色材质
    self.Flash:Hide()--内边框闪光

    if AddUIDB.CastTexture == "随机使用材质" and useTexture then
		PlayerCastingBarFrame:SetStatusBarTexture(ns.CastBarTextrue[useTexture])
	else
		PlayerCastingBarFrame:SetStatusBarTexture(ns.CastBarTextrue[AddUIDB.CastTexture])
	end
end
hooksecurefunc(PlayerCastingBarFrame, "PlayFadeAnim", function(self)
    HideAnims(self)
end)
hooksecurefunc(PlayerCastingBarFrame, "PlayInterruptAnims", function(self)
    HideAnims(self)
end)


--施法条计时
local function ShowMyCasting(self)
if not AddUIDB.cast then return end
if not self.maxValue or ns.MM(self.maxValue) then return end
if not self.Cooldown  then
	self.Cooldown = self:CreateFontString(nil)
    self.Cooldown:SetFont(SystemFont_Outline_Small:GetFont(), 16, "OUTLINE")	--施法时间文字大小
    self.Cooldown:SetJustifyH("RIGHT")
    self.Cooldown:SetPoint("RIGHT", self, "RIGHT", 0, 0)
elseif self.maxValue-self.value < 0 then
	self.Cooldown:SetText(" ")
elseif UnitCastingInfo(self.unit) then
	self.Cooldown:SetText(format("%.1f/%.1f",self.maxValue-self.value,self.maxValue))
elseif UnitChannelInfo(self.unit) then
	self.Cooldown:SetText(format("%.1f",self.value,0))
else
	self.Cooldown:SetText(" ")
end
end
PlayerCastingBarFrame:HookScript("OnUpdate", ShowMyCasting)