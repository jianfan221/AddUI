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
	PlayerCastingBarFrame.TextBorder:SetTexture(nil)	--文字框大背景
	PlayerCastingBarFrame.Border:SetTexture(nil)	--施法条边框
	PlayerCastingBarFrame.Border:Hide()
	PlayerCastingBarFrame.BorderMask:SetTexture(nil)--闪光尾巴
	PlayerCastingBarFrame.Icon:Show()
	PlayerCastingBarFrame.Icon:ClearAllPoints()
	PlayerCastingBarFrame.Icon:Show()--施法条图标显示
	PlayerCastingBarFrame.Icon:SetSize(AddUIDB.castHeight, AddUIDB.castHeight)--施法条图标大小
	PlayerCastingBarFrame.Icon:SetPoint("RIGHT", PlayerCastingBarFrame, "LEFT", -2, 0)--图标位置
	--裁切图标边缘并添加细黑边
	PlayerCastingBarFrame.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	if not PlayerCastingBarFrame.IconBorder then
		PlayerCastingBarFrame.IconBorder = PlayerCastingBarFrame:CreateTexture(nil, "ARTWORK", nil, 3)
		PlayerCastingBarFrame.IconBorder:SetColorTexture(0, 0, 0, 1)
		PlayerCastingBarFrame.IconBorder:SetPoint("TOPLEFT", PlayerCastingBarFrame.Icon, -1, 1)
		PlayerCastingBarFrame.IconBorder:SetPoint("BOTTOMRIGHT", PlayerCastingBarFrame.Icon, 1, -1)
	end
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
PlayerCastingBarFrame:HookScript("OnShow", function(self)
	OnCastingEvent(nil, 'player')
end)

local function HideAnims(self)
	if not AddUIDB.cast then return end
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
ns.hook(PlayerCastingBarFrame, "PlayFadeAnim", function(self)
    HideAnims(self)
end)
ns.hook(PlayerCastingBarFrame, "PlayInterruptAnims", function(self)
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


-- 通道分段法术表：spellID → 分段波数(ticks)，后续新增技能只需在此添加
local ChannelTickMap = {
	[5143] = 7, -- 奥术飞弹
}
local ArcaneMissileLines = {}
ns.event('UNIT_SPELLCAST_CHANNEL_START', function(event, unit, castGUID, spellID)
	if unit ~= "player" then return end
	-- 先隐藏所有分割线：既清理上次分段比本次多的残留，也覆盖非分段法术
	for _, line in ipairs(ArcaneMissileLines) do line:Hide() end
	local ticks = ChannelTickMap[spellID]
	if not AddUIDB.cast or not ticks then
		return
	end
	for i = 1, ticks - 1 do
		local line = ArcaneMissileLines[i]
		if not line then
			line = PlayerCastingBarFrame:CreateTexture(nil, "OVERLAY")
			line:SetWidth(1)
			line:SetHeight(AddUIDB.castHeight)
			line:SetColorTexture(1, 1, 1, 0.8)
			ArcaneMissileLines[i] = line
		end
		line:ClearAllPoints()
		line:SetPoint("LEFT", PlayerCastingBarFrame, "LEFT", AddUIDB.castWidth * i / ticks, 0)
		line:Show()
	end
end)
ns.event('UNIT_SPELLCAST_CHANNEL_STOP', function(event, unit, castGUID, spellID)
	if unit ~= "player" then return end
	for _, line in ipairs(ArcaneMissileLines) do line:Hide() end
end)

-- ═══════════════════════════════════════════════════════════════
-- 平砍闪光条（仅无限服 Camelot：客户端提供 PLAYER_SWING / C_SwingTimer）
-- 施法条正下方一条等宽细线，每个正在挥砍的武器一个光点，自左向右跑表示进度
-- 主手/副手/远程不预先判断，收到对应 swingType 的事件就显示，有几把就几个光点
-- ═══════════════════════════════════════════════════════════════
if C_SwingTimer and Enum.PlayerSwingType then
	local SPARK_TEXTURE = "Interface\\CastingBar\\UI-CastingBar-Spark"
	local SPARK_WIDTH = 8
	local SPARK_HEIGHT = 12
	-- 主手白、副手淡蓝、远程淡黄，双持时同起点也能分清
	local SPARK_COLORS = {
		[Enum.PlayerSwingType.MainHand] = {1.0, 1.0, 1.0},
		[Enum.PlayerSwingType.OffHand] = {0.6, 0.85, 1.0},
		[Enum.PlayerSwingType.Ranged] = {1.0, 0.85, 0.45},
	}
	-- 垂直错开，避免同速双持时两个光点完全重叠
	local SPARK_OFFSET_Y = {
		[Enum.PlayerSwingType.MainHand] = 0,
		[Enum.PlayerSwingType.OffHand] = -5,
		[Enum.PlayerSwingType.Ranged] = 5,
	}

	local swingLine = CreateFrame("Frame", nil, UIParent)
	swingLine:SetPoint("TOPLEFT", PlayerCastingBarFrame, "BOTTOMLEFT", 0, -2)
	swingLine:SetPoint("TOPRIGHT", PlayerCastingBarFrame, "BOTTOMRIGHT", 0, -2)
	swingLine:SetHeight(1)

	local lineTexture = swingLine:CreateTexture(nil, "BACKGROUND")
	lineTexture:SetAllPoints(swingLine)
	lineTexture:SetColorTexture(1, 1, 1, 0.25)

	local sparks = {} -- swingType → {texture = 光点, endTime = 出手时间, duration = 本次间隔}

	local function LaySpark(data, progress)
		local offset = progress * (swingLine:GetWidth() - SPARK_WIDTH)
		data.texture:ClearAllPoints()
		data.texture:SetPoint("LEFT", swingLine, "LEFT", offset, data.yOffset)
	end

	local function OnSwingUpdate()
		local now = GetTime()
		local anyActive = false
		for _, data in pairs(sparks) do
			if data.endTime then
				local remain = data.endTime - now
				if remain <= 0 then
					-- 已出手：光点消失，等下一次 PLAYER_SWING
					data.endTime = nil
					data.texture:Hide()
				else
					anyActive = true
					LaySpark(data, (data.duration - remain) / data.duration)
				end
			end
		end
		if not anyActive then
			-- 没有光点在跑（停手/没目标/超出距离）：线也一起隐藏，真正做到“自动停”
			swingLine:SetScript("OnUpdate", nil)
			swingLine:Hide()
		end
	end

	local function GetSpark(swingType)
		local data = sparks[swingType]
		if not data then
			local texture = swingLine:CreateTexture(nil, "OVERLAY")
			texture:SetTexture(SPARK_TEXTURE)
			texture:SetSize(SPARK_WIDTH, SPARK_HEIGHT)
			texture:SetBlendMode("ADD")
			local color = SPARK_COLORS[swingType]
			if color then
				texture:SetVertexColor(color[1], color[2], color[3])
			end
			texture:Hide()
			data = {texture = texture, yOffset = SPARK_OFFSET_Y[swingType] or 0}
			sparks[swingType] = data
		end
		return data
	end

	-- 卸下副手/远程武器后：光点跑完自动消失，之后不再收到对应 PLAYER_SWING，无需额外清理

	swingLine:RegisterEvent("PLAYER_SWING")
	swingLine:SetScript("OnEvent", function(self, event, arg1, arg2)
		if event == "PLAYER_SWING" then
			if not AddUIDB or not AddUIDB.cast then
				self:Hide()
				return
			end
			local swingDuration, swingType = arg1, arg2
			-- 先校验再显示：duration 无效的事件不能把线亮起来，否则没有 OnUpdate 收尾会一直留着
			if not swingDuration or swingDuration <= 0 then return end
			self:SetFrameStrata(PlayerCastingBarFrame:GetFrameStrata())
			self:Show()
			local data = GetSpark(swingType)
			data.duration = swingDuration
			data.endTime = GetTime() + swingDuration
			LaySpark(data, 0)
			data.texture:Show()
			self:SetScript("OnUpdate", OnSwingUpdate)
		end
	end)
	swingLine:Hide() -- 文件加载时 AddUIDB 可能还未创建，等事件里再判断
end