local _,ns = ...

ns.event("PLAYER_ENTERING_WORLD", function()
	AddUIDB.CooldownDate = AddUIDB.CooldownDate or {}
	-------------------------------
	CooldownViewerSettings:HookScript("OnShow", function(self)
		self.LayoutDropdown:SetWidth(150)
	end)
	hooksecurefunc(CooldownViewerSettings, "SetupLayoutManagerDropdown", function(self)
		self.LayoutDropdown:SetWidth(150)
	end)
	-------------------------------
	local CLM = CooldownViewerSettings:GetLayoutManager() --主界面布局管理器
	-------------------------------
	local function UseDate(string)
		local ClassName = UnitClass("player")
		if string.match(string,ClassName) then--标签名必须包含职业名
			local CreatOK,CreatRet = pcall(function() 
				return CLM:CreateLayoutsFromSerializedData(AddUIDB.CooldownDate[string])--创建布局
			end)
			if CreatOK then
				local strID = CreatRet and CreatRet[1]
				local tag = CLM:GetLayout(strID)--获取布局对象
				local CanRet = CLM:CanActivateLayout(tag) --检查布局是否可以应用
				--local ClassAndSpecTag = CooldownManagerLayout_GetClassAndSpecTag(tag)--获取职业专精标签
				--local loyoutName = CooldownViewerUtil.GetClassAndSpecTagText(ClassAndSpecTag)--获取职业专精标签文本
				local UsedText = CanRet and "已应用" or "当前专精无法应用"
				CooldownManagerLayout_SetName(tag, string)
				if CanRet then
					securecall(function()
						CooldownViewerSettings:SetActiveLayoutByID(strID)
					end)
				end
				print("|cff00ff00已导入:  |cff00ffff"..UsedText.."|r "..string.."|r")
			else
				print("|cffff0000冷却管理器加载失败: |r"..CreatRet)
			end
		else
			print("|cffff0000加载失败,字符串不属于该职业: "..string.."|r")
		end
	end
	-------------------------------
	local function DeleteAll()
		CLM:ResetToDefaults()
		print("|cffff0000冷却管理器已重置到默认配置|r")
	end
	-------------------------------
	local function AddDate()
		local UsetdID = CLM:GetActiveLayoutID()
		if not UsetdID then 
			print("|cffff0000入门配置无法存储,请先切换到其他配置|r")
			return  --排除入门布局
		end
		local StrOK,StrRet = pcall(function() --字符串编码
			return CooldownViewerSettings:GetLayoutManager():GetSerializer():SerializeLayouts(UsetdID)
		end)
		if StrOK and StrRet then
			local CalendarTime = C_DateAndTime.GetCurrentCalendarTime() --获取时间
			local nowTime = CalendarTime.year.."."..CalendarTime.month.."."..CalendarTime.monthDay--.."-"..CalendarTime.hour..":"..CalendarTime.minute
			local _,SpecName = C_SpecializationInfo.GetSpecializationInfo(GetSpecialization()) --获取当前专精
			local dateName = SpecName.. " " .. nowTime .." "..UnitClass("player").." " ..UnitName("player")  --组合成存储名字
			if AddUIDB.CooldownDate[dateName] then
				print("|cffff0000已存在|cff00ffff同名存档|r:  "..dateName.."|r")
			else
				AddUIDB.CooldownDate[dateName] = StrRet
				print("|cff00ff00已存储:  "..dateName.."|r")
			end
		else
			print("|cffff0000冷却管理器配置存储失败: 无法获取当前布局字符串|r"..StrRet)
		end
	end
	-------------------------------
	if not CooldownViewerSettings.MyDateDropdown then
		CooldownViewerSettings.MyDateDropdown = CreateFrame("DropdownButton", nil, CooldownViewerSettings, "WowStyle1DropdownTemplate")
		CooldownViewerSettings.MyDateDropdown:SetPoint("BOTTOMRIGHT",CooldownViewerSettings.NineSlice.BottomEdge,"BOTTOMRIGHT" ,-60, 4)
		CooldownViewerSettings.MyDateDropdown:SetWidth(80)
		CooldownViewerSettings.MyDateDropdown.Text1 = CooldownViewerSettings.MyDateDropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		CooldownViewerSettings.MyDateDropdown.Text1:SetText("配置")
		CooldownViewerSettings.MyDateDropdown.Text1:SetVertexColor(1,1,1,1)
		CooldownViewerSettings.MyDateDropdown.Text1:SetPoint("CENTER", CooldownViewerSettings.MyDateDropdown, "CENTER", -8, 0)
		CooldownViewerSettings.MyDateDropdown.Text1:Show()
		local function IsSelected()
		end
		local function SetSelected(value)--返回选中的字符串
			UseDate(value)
		end
		CooldownViewerSettings.MyDateDropdown:SetupMenu(function(dropdown, rootDescription)
			for layoutID, layoutInfo in pairs(AddUIDB.CooldownDate) do
				local ClassName = UnitClass("player")
				local text = layoutID
				if not string.match(layoutID,ClassName) then
					text = "|cff808080"..layoutID.."|r"
				end
				local layoutButton = rootDescription:CreateRadio(text, IsSelected, SetSelected, layoutID)
				layoutButton:DeactivateSubmenu();
				layoutButton:AddInitializer(function(button, description, menu)
					local deleteLayoutButton = MenuTemplates.AttachAutoHideCancelButton(button);
					MenuTemplates.SetUtilityButtonLockedEnabledState(deleteLayoutButton, true);
					MenuTemplates.SetUtilityButtonTooltipText(deleteLayoutButton, COOLDOWN_VIEWER_SETTINGS_DELETE_LAYOUT);
					MenuTemplates.SetUtilityButtonAnchor(deleteLayoutButton, MenuVariants.CancelButtonAnchor, true);
					MenuTemplates.SetUtilityButtonClickHandler(deleteLayoutButton, function()
						AddUIDB.CooldownDate[layoutID] = nil  -- 假设你是按键值删除
						dropdown:GenerateMenu()	--刷新菜单
						print("|cffff0000已删除: " .. layoutID)
					end);
				end);
			end
		end)
	end
	-------------------------------
	if not CooldownViewerSettings.SetDateButton then
		CooldownViewerSettings.SetDateButton = CreateFrame("Button", nil, CooldownViewerSettings,"UIPanelButtonTemplate")
		CooldownViewerSettings.SetDateButton:SetWidth(60)
		CooldownViewerSettings.SetDateButton:SetPoint("BOTTOM", -8, 4)
		CooldownViewerSettings.SetDateButton:Show()
		CooldownViewerSettings.SetDateButton.Text = CooldownViewerSettings.SetDateButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		CooldownViewerSettings.SetDateButton.Text:SetPoint("CENTER", CooldownViewerSettings.SetDateButton, "CENTER", 0, 0)
		CooldownViewerSettings.SetDateButton.Text:SetText("存储")
		CooldownViewerSettings.SetDateButton:SetScript("OnClick", function()
			if IsShiftKeyDown() and IsControlKeyDown() and IsAltKeyDown() then
				DeleteAll()
			else
				AddDate()
			end
		end)
		CooldownViewerSettings.SetDateButton:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:SetText("|cff00ff00点击保存到右边本地配置|r\n|cffff0000按Ctrl+Shift+Alt+点击删除|cff00ffff左边|r全部布局|r")
			GameTooltip:Show()
		end)
		CooldownViewerSettings.SetDateButton:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end

end)