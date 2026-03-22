local _,ns = ...
ns.event("PLAYER_LOGIN", function()
ns.tips("让暴雪的一些框体可以移动")
--按住alt移动--if (IsAltKeyDown()) then


--C_AddOns.LoadAddOn
local frametable = {
	"CharacterFrame",	--角色
	"FriendsFrame",		--好友
	"PVEFrame",			--地下城与PVP
	"ContainerFrameCombinedBags",	--背包
	"WorldMapFrame",	--大地图
	"GameMenuFrame",	--菜单
	"SettingsPanel",	--esc菜单界面
	"MerchantFrame",	--售卖
	"ProfessionsFrame",	--专业
	"CommunitiesFrame",	--公会
	"MailFrame",		--邮箱（基础UI，非按需加载）
	"BankFrame",		--银行
	"GuildBankFrame",	--公会银行
	"CollectionsJournal",--收藏（坐骑/宠物）
	"SpellBookFrame",	--技能书
	"TabardFrame",		--会徽
	"QuestFrame",		--任务
	"ItemUpgradeFrame",	--物品升级
	"CooldownViewerSettings",	--冷却管理器设置界面
}
for i, v in ipairs(frametable) do
	if _G[v] then
		_G[v]:SetMovable(true)
		_G[v]:HookScript("OnMouseDown", function()
			_G[v]:StartMoving()
		end)
		_G[v]:HookScript('OnMouseUp', function(self, button)
			_G[v]:StopMovingOrSizing()
		end)
	end
end

local function SetBagsPoint()
	ContainerFrameCombinedBags:SetAlpha(0)
	ContainerFrame6:SetAlpha(0)
	C_Timer.After(0,function()
		ContainerFrameCombinedBags:ClearAllPoints()
		ContainerFrameCombinedBags:SetPoint("RIGHT",UIParent,"RIGHT",-80,0)
		ContainerFrameCombinedBags:SetAlpha(1)
		ContainerFrame6:SetAlpha(1)
	end)
end
ContainerFrameCombinedBags:HookScript("OnShow",SetBagsPoint)
ContainerFrame6:HookScript("OnShow",SetBagsPoint)
ContainerFrame6:HookScript("OnHide",SetBagsPoint)

--插件加载后再进行某些框体的移动
ns.event('ADDON_LOADED', function(event, msg)
	if msg == 'Blizzard_Professions' then	--制造业
		ProfessionsFrame:SetMovable(true)
		ProfessionsFrame:HookScript("OnMouseDown", function()
			ProfessionsFrame:StartMoving()
		end)
		ProfessionsFrame:HookScript('OnMouseUp', function(self, button)
			ProfessionsFrame:StopMovingOrSizing()
		end)
	end
	
	if msg == 'Blizzard_Communities' then	--公会
		CommunitiesFrame:SetMovable(true)
		CommunitiesFrame:HookScript("OnMouseDown", function()
			CommunitiesFrame:StartMoving()
		end)
		CommunitiesFrame:HookScript('OnMouseUp', function(self, button)
			CommunitiesFrame:StopMovingOrSizing()
		end)
	end
	
	if msg == 'Blizzard_ClassTalentUI' then
		ClassTalentFrame:SetMovable(true)
		ClassTalentFrame:HookScript("OnMouseDown", function()
			ClassTalentFrame:StartMoving()
		end)
		ClassTalentFrame:HookScript('OnMouseUp', function(self, button)
			ClassTalentFrame:StopMovingOrSizing()
		end)
	end
	if ProfessionsBookFrame and not bookOpenPro then--K键专业页面添加打开订单按钮
		local bookOpenPro = CreateFrame("Button", "bookOpenPro", ProfessionsBookFrame.TitleContainer, "UIPanelButtonTemplate")
		bookOpenPro:SetSize(120, 22)
		bookOpenPro:SetText("打开制造订单")
		bookOpenPro:SetPoint("LEFT", ProfessionsBookFrame.TitleContainer, "LEFT",30,0)
		bookOpenPro:SetScript("OnClick", function()
			if not ProfessionsCustomerOrdersFrame then
				C_AddOns.LoadAddOn("Blizzard_ProfessionsCustomerOrders")
				ProfessionsCustomerOrdersFrame:SetMovable(true)
				ProfessionsCustomerOrdersFrame:HookScript("OnMouseDown", function()
					ProfessionsCustomerOrdersFrame:SetPropagateKeyboardInput(true)
					ProfessionsCustomerOrdersFrame:StartMoving()
				end)
				ProfessionsCustomerOrdersFrame:HookScript('OnMouseUp', function(self, button)
					ProfessionsCustomerOrdersFrame:SetPropagateKeyboardInput(true)
					ProfessionsCustomerOrdersFrame:StopMovingOrSizing()
				end)
				ProfessionsCustomerOrdersFrame:HookScript("OnKeyDown", function(self, key)
					if key == "ESCAPE" then
						ProfessionsCustomerOrdersFrame:Hide()
						ProfessionsCustomerOrdersFrame:SetPropagateKeyboardInput(false)
					else
						ProfessionsCustomerOrdersFrame:SetPropagateKeyboardInput(true)
					end
				end)
			end
			if ProfessionsCustomerOrdersFrame:IsShown() then
				ProfessionsCustomerOrdersFrame:Hide()
			else
				ProfessionsCustomerOrdersFrame:Show()
				ProfessionsCustomerOrdersFrame:ClearAllPoints()
				ProfessionsCustomerOrdersFrame:SetPoint("LEFT",UIParent,"CENTER",-35,130)
			end
		end)
	end
	
	if msg == 'Blizzard_AuctionHouseUI' then--拍卖行
		AuctionHouseFrame:SetMovable(true)
		AuctionHouseFrame:HookScript("OnMouseDown", function()
			AuctionHouseFrame:StartMoving()
		end)
		AuctionHouseFrame:HookScript('OnMouseUp', function(self, button)
			AuctionHouseFrame:StopMovingOrSizing()
		end)
		if AuctionOpenPro then return end--拍卖行页面添加打开订单按钮
		local AuctionOpenPro = CreateFrame("Button", "AuctionOpenPro", AuctionHouseFrame.TitleContainer, "UIPanelButtonTemplate")
		AuctionOpenPro:SetSize(120, 22)
		AuctionOpenPro:SetText("打开制造订单")
		AuctionOpenPro:SetPoint("LEFT", AuctionHouseFrame.TitleContainer, "LEFT",0,0)
		AuctionOpenPro:SetScript("OnClick", function()
			if not ProfessionsCustomerOrdersFrame then
				C_AddOns.LoadAddOn("Blizzard_ProfessionsCustomerOrders")
				ProfessionsCustomerOrdersFrame:SetMovable(true)
				ProfessionsCustomerOrdersFrame:HookScript("OnMouseDown", function()
					ProfessionsCustomerOrdersFrame:StartMoving()
				end)
				ProfessionsCustomerOrdersFrame:HookScript('OnMouseUp', function(self, button)
					ProfessionsCustomerOrdersFrame:StopMovingOrSizing()
				end)
				ProfessionsCustomerOrdersFrame:HookScript("OnKeyDown", function(self, key)
					if key == "ESCAPE" then
						ProfessionsCustomerOrdersFrame:Hide()
						ProfessionsCustomerOrdersFrame:SetPropagateKeyboardInput(false)
					else
						ProfessionsCustomerOrdersFrame:SetPropagateKeyboardInput(true)
					end
				end)
			end
			if ProfessionsCustomerOrdersFrame:IsShown() then
				ProfessionsCustomerOrdersFrame:Hide()
			else
				ProfessionsCustomerOrdersFrame:Show()
				ProfessionsCustomerOrdersFrame:ClearAllPoints()
				ProfessionsCustomerOrdersFrame:SetPoint("LEFT",UIParent,"CENTER",-35,130)
			end
		end)
	end
	
	if msg == 'Blizzard_PlayerSpells' then	--天赋
		local PlayerSpellsFrameScale = 0.5
		local PlayerSpellsCheck = CreateFrame("CheckButton", "PlayerSpellsCheck", PlayerSpellsFrame.TitleContainer,"InterfaceOptionsCheckButtonTemplate")
		PlayerSpellsCheck:SetPoint("TOPRIGHT", -220, 1)
		PlayerSpellsCheck:SetChecked(AddUIDB.OpenTalentScale)
		PlayerSpellsCheck.text:SetText("小窗开启")
		PlayerSpellsCheck:SetScale(0.9)
		PlayerSpellsCheck:SetScript("OnClick", function (self)
			AddUIDB.OpenTalentScale = self:GetChecked()
		end)
		local PlayerSpellsButtom = CreateFrame("Button", "PlayerSpellsButtom", PlayerSpellsFrame.TitleContainer, "UIPanelButtonTemplate")
		PlayerSpellsButtom:SetText("放大")
		PlayerSpellsButtom:SetSize(70,22)
		PlayerSpellsButtom:SetPoint("TOPRIGHT", -30, 1)
		PlayerSpellsButtom:SetScript("OnClick", function()
			if InCombatLockdown() then return end		--战斗中不执行
			if PlayerSpellsFrameScale == 0.9 then 
				PlayerSpellsButtom:SetText("放大")
				PlayerSpellsFrame:SetScale(0.5)
				PlayerSpellsFrameScale = 0.5
			else
				PlayerSpellsButtom:SetText("缩小")
				PlayerSpellsFrame:SetScale(0.9)
				PlayerSpellsFrameScale = 0.9
			end
		end)
		PlayerSpellsFrame:SetMovable(true)
		PlayerSpellsFrame:HookScript("OnMouseDown", function()
			PlayerSpellsFrame:StartMoving()
		end)
		PlayerSpellsFrame:HookScript('OnMouseUp', function(self, button)
			PlayerSpellsFrame:StopMovingOrSizing()
		end)
		PlayerSpellsFrame:HookScript("OnShow", function()
			if InCombatLockdown() then return end		--战斗中不执行
			if PlayerSpellsFrame.TalentsFrame:IsShown() and AddUIDB.OpenTalentScale then
				PlayerSpellsFrame:SetScale(PlayerSpellsFrameScale)
			else
				PlayerSpellsFrame:SetScale(0.9)
			end
			PlayerSpellsFrame:ClearAllPoints()
			PlayerSpellsFrame:SetPoint("LEFT",UIParent,"LEFT",160,50)
			
		end)
	end
	
	if msg == "Blizzard_ChallengesUI" then
		ChallengesKeystoneFrame:SetMovable(true)
		ChallengesKeystoneFrame:HookScript("OnMouseDown", function()
			ChallengesKeystoneFrame:StartMoving()
		end)
		ChallengesKeystoneFrame:HookScript('OnMouseUp', function(self, button)
			ChallengesKeystoneFrame:StopMovingOrSizing()
		end)
		
	end

end)
end)
