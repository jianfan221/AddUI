local _,ns = ...
--hooksecurefunc(DamageMeterEntryMixin, "Init", function(self)
ns.event("PLAYER_LOGIN", function()
	if AddUIDB.cdset then
		ns.tips("快速打开冷却管理器/cc")
		SlashCmdList["OPENCOOL"] = function() 
			ns.COMBAT(ShowUIPanel,CooldownViewerSettings)
		end 
		SLASH_OPENCOOL1 = "/cc"
		if not AddUI_OpenCC then
			local AddUI_OpenCC = CreateFrame("Button", "AddUI_OpenCC", UIParent, "VoiceToggleButtonTemplate")
			AddUI_OpenCC:SetSize(28, 23)
			AddUI_OpenCC:SetPoint("BOTTOM", ChatFrameChannelButton, "TOP", 0, 2)
			AddUI_OpenCC:Show()
			AddUI_OpenCC.Text = AddUI_OpenCC:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			AddUI_OpenCC.Text:SetPoint("CENTER", AddUI_OpenCC, "CENTER", 0, 0)
			AddUI_OpenCC.Text:SetText("CC")
			AddUI_OpenCC:SetScript("OnClick", function()
				if not CooldownViewerSettings:IsShown() then
					ns.COMBAT(ShowUIPanel,CooldownViewerSettings)
				else
					ns.COMBAT(HideUIPanel,CooldownViewerSettings)
				end
			end)
			AddUI_OpenCC:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:SetText("点击打开|cff00ff00冷却管理器|r\n/cc打开|cff00ff00冷却管理器")
				GameTooltip:Show()
			end)
			AddUI_OpenCC:SetScript("OnLeave", function()
				GameTooltip:Hide()
			end)
		end
		local function CreateShadow(f)
			if f.shadow then return end
			
			--去除遮罩
			if type(f.GetRegions) == "function" then
				for _, region in ipairs({f:GetRegions()}) do
					if region:IsObjectType("MaskTexture") then
						if region.SetTexture then
							region:SetTexture(nil)
						end
						region:Hide()
					end
					if region:IsObjectType("Texture") then
						region:SetTexCoord(0.07, 0.93, 0.07, 0.93)
						region:ClearAllPoints()
						region:SetPoint("TOPLEFT", f, 3, -3)
						region:SetPoint("BOTTOMRIGHT", f, -3, 3)
						if region:GetAtlas() =="UI-HUD-CoolDownManager-IconOverlay" then
							region:SetTexture(nil)
							region:Hide()
							region:SetAlpha(0)
						end
					end
					
				end
			end
			if f.Bar then
				f.Bar:SetPoint("TOPRIGHT", f, -2, -3)
				f.Bar:SetPoint("BOTTOMRIGHT", f, -2, 3)
				f.Bar:SetStatusBarTexture('Interface\\Buttons\\WHITE8x8')
				if f.Bar.Pip then
					local height = f.GetHeight and f:GetHeight() or 30
					f.Bar.Pip:SetSize(10,height*1.8)
				end
				if f.Bar.Duration then
					f.Bar.Duration:SetScale(1.5)
					f.Bar.Duration:SetPoint("RIGHT", f.Bar, -2, 0)
				end
				if f.Bar.BarBG  then
					f.Bar.BarBG:SetTexture('Interface\\Buttons\\WHITE8x8')
					f.Bar.BarBG:SetColorTexture(0,0,0,0.5)
					f.Bar.BarBG:SetPoint("TOPLEFT", f.Bar, 0, 0)
					f.Bar.BarBG:SetPoint("BOTTOMRIGHT", f.Bar, 0, 0)
				end
				return --Bar直接返回
			end
			--加边框
			f.shadow = CreateFrame("Frame", nil, f, "BackdropTemplate")
			f.shadow:SetFrameLevel(3)
			f.shadow:SetFrameStrata(f:GetFrameStrata())
			f.shadow:SetPoint("TOPLEFT", 2, -2)
			f.shadow:SetPoint("BOTTOMRIGHT", -2, 2)
			f.shadow:SetBackdrop({edgeFile = 'Interface\\Buttons\\WHITE8x8',edgeSize = 1})
			f.shadow:SetBackdropBorderColor(0, 0, 0, 1)
			if f.Cooldown then
				f.Cooldown:SetPoint("TOPLEFT",f.shadow, "TOPLEFT", -1, 1)
				f.Cooldown:SetPoint("BOTTOMRIGHT",f.shadow, "BOTTOMRIGHT", 1, -1)
			end
			return f.shadow
		end
		hooksecurefunc(BuffIconCooldownViewer, "RefreshData", function(self,event)
			for itemFrame in self.itemFramePool:EnumerateActive() do
				CreateShadow(itemFrame)
			end
		end)
		hooksecurefunc(EssentialCooldownViewer, "RefreshData", function(self,event)
			for itemFrame in self.itemFramePool:EnumerateActive() do
				CreateShadow(itemFrame)
			end
		end)
		hooksecurefunc(UtilityCooldownViewer,"RefreshData", function(self,event)
			for itemFrame in self.itemFramePool:EnumerateActive() do
				CreateShadow(itemFrame)
			end
		end)
		
		hooksecurefunc(BuffBarCooldownViewer,"RefreshData", function(self,event)
			for itemFrame in self.itemFramePool:EnumerateActive() do
				CreateShadow(itemFrame)
			end
		end)
	end
	if AddUIDB.cdcenter then
		--BUFF居中生长
		function ns.SetBuffIconPoint(self)
			local activeFrames = {}
			for itemFrame in self.itemFramePool:EnumerateActive() do
				if itemFrame:IsShown() then
					table.insert(activeFrames, itemFrame)
				end
				if itemFrame.DebuffBorder then
					itemFrame.DebuffBorder = nil--CooldownViewerItemMixin:RefreshIconBorder()
				end
			end
			--获取CooldownItem
			ns.ItemBuffTable = ns.ItemBuffTable or {}
			for i, frame in pairs(ns.ItemBuffTable) do
				if frame["frame"] and frame["frame"]:IsShown() then
					frame["frame"]:SetScale(self.iconScale or 1)
					table.insert(activeFrames, frame["frame"])
				end
			end
			
			local count = #activeFrames
			if count == 0 then return end
			
			if self:IsHorizontal() then
				local container = self:GetItemContainerFrame()
				local padding = self.iconPadding + self:GetAdditionalPaddingOffset()
				local itemWidth = activeFrames[1]:GetWidth() or 40
				for i, frame in ipairs(activeFrames) do
					local offsetFromCenter = (i - (count + 1) / 2) * (itemWidth + padding)
					offsetFromCenter = -offsetFromCenter  -- 反转方向
					frame:ClearAllPoints()
					frame:SetPoint("CENTER", container, "CENTER", offsetFromCenter, 0)
				end
			end
		end
		hooksecurefunc(BuffIconCooldownViewer, "OnUnitAura", function(self)
			ns.SetBuffIconPoint(self)
		end)
		hooksecurefunc(BuffIconCooldownViewer, "RefreshLayout", function(self)
			ns.SetBuffIconPoint(self)
		end)
		hooksecurefunc(BuffIconCooldownViewer, "RefreshData", function(self,event)
			ns.SetBuffIconPoint(self)
		end)
		--位置居中
		local function CooldowPoint(self)
			if InCombatLockdown() then return end
			if not self then return end
			local bottom = self:GetBottom()
			local height = self:GetHeight() or 0
			local X,Y = UIParent:GetWidth()/2, bottom + height
			self:ClearAllPoints()
			self:SetPoint("TOP",UIParent,"BOTTOMLEFT",X,Y)
			if EditModeManagerFrame and EditModeManagerFrame.UpdateSystemAnchorInfo then
				-- UpdateSystemAnchorInfo 会读取当前 SetPoint 的值并更新到 layoutInfo 缓存中
				local hasChanged = EditModeManagerFrame:UpdateSystemAnchorInfo(self)
				if hasChanged then
					-- 标记当前框体有变动，使编辑模式界面的“保存”按钮亮起
					if self.SetHasActiveChanges then
						self:SetHasActiveChanges(true)
					end
					-- 通知管理器检查整体状态
					EditModeManagerFrame:CheckForSystemActiveChanges()
				end
			end
		end
		hooksecurefunc(EditModeManagerFrame, "OnSystemPositionChange", function(self,frame)
			if frame and frame == BuffIconCooldownViewer then
				CooldowPoint(BuffIconCooldownViewer)
			end
			if frame and frame == EssentialCooldownViewer then
				CooldowPoint(EssentialCooldownViewer)
			end
			if frame and frame == UtilityCooldownViewer then
				CooldowPoint(UtilityCooldownViewer)
				self:OnEditModeSystemAnchorChanged();
			end
		end)
	end
end)