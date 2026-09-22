local _,ns = ...
ns.event("PLAYER_LOGIN", function()
ns.tips("让暴雪的一些框体可以移动")
--按住alt移动--if (IsAltKeyDown()) then

--背包初始位置
hooksecurefunc("UpdateContainerFrameAnchors", function()
	ContainerFrameCombinedBags:ClearAllPoints()
	ContainerFrameCombinedBags:SetPoint("RIGHT",UIParent,"RIGHT",-80,0)
end)


local function MakeMovable(frame)
	if not frame then return end
	frame:SetMovable(true)
	frame:HookScript("OnMouseDown", function() frame:StartMoving() end)
	frame:HookScript("OnMouseUp", function() frame:StopMovingOrSizing() end)
end

local function SetMove(arg1, arg2)
	if arg2 then
		EventUtil.ContinueOnAddOnLoaded(arg2, function() MakeMovable(_G[arg1]) end)
	else
		MakeMovable(_G[arg1])
	end
end

SetMove("CharacterFrame")				--角色
SetMove("FriendsFrame")				--好友
SetMove("SocialUIFrame")				--社交(12.1新好友)
SetMove("PVEFrame")					--地下城与PVP
SetMove("ContainerFrameCombinedBags")	--背包
SetMove("WorldMapFrame")				--大地图
SetMove("GameMenuFrame")				--菜单
SetMove("SettingsPanel")				--esc菜单界面
SetMove("MerchantFrame")				--售卖
SetMove("MailFrame")					--邮箱
SetMove("BankFrame")					--银行
SetMove("GuildBankFrame")				--公会银行
SetMove("SpellBookFrame")				--技能书
SetMove("TabardFrame")					--会徽
SetMove("QuestFrame")					--任务
SetMove("ItemUpgradeFrame")			--物品升级
SetMove("CooldownViewerSettings")		--冷却管理器设置界面

SetMove("MacroFrame", "Blizzard_MacroUI")		--宏命令
SetMove("ProfessionsFrame", "Blizzard_Professions")		--制造业
SetMove("CommunitiesFrame", "Blizzard_Communities")		--公会
SetMove("ClassTalentFrame", "Blizzard_ClassTalentUI")		--天赋
SetMove("AuctionHouseFrame", "Blizzard_AuctionHouseUI")	--拍卖行
SetMove("ChallengesKeystoneFrame", "Blizzard_ChallengesUI")--大秘境
SetMove("PlayerSpellsFrame", "Blizzard_PlayerSpells")		--法术书
SetMove("ProfessionsCustomerOrdersFrame", "Blizzard_ProfessionsCustomerOrders")	--制造订单
SetMove("ProfessionsBookFrame", "Blizzard_ProfessionsBook")	--专业书(K键)
SetMove("AchievementFrame", "Blizzard_AchievementUI")		--成就
SetMove("CollectionsJournal", "Blizzard_Collections")		--收藏（坐骑/宠物）
SetMove("EncounterJournal", "Blizzard_EncounterJournal")	--冒险指南
SetMove("HousingDashboardFrame", "Blizzard_HousingDashboard")	--住宅信息板

-- 聆听对话框（小地图下方部件）固定到屏幕正上方（布局后被拉回则再钉回）
hooksecurefunc("ManageFramePositions", function()
	local f = UIWidgetBelowMinimapContainerFrame
	if f then f:ClearAllPoints(); f:SetPoint("TOP", UIParent, "TOP", 0, -5) end
end)

-- K键专业页面添加打开订单按钮
EventUtil.ContinueOnAddOnLoaded("Blizzard_ProfessionsBook", function()
	if bookOpenPro then return end
	local bookOpenPro = CreateFrame("Button", "bookOpenPro", ProfessionsBookFrame.TitleContainer, "UIPanelButtonTemplate")
	bookOpenPro:SetSize(120, 22)
	bookOpenPro:SetText("打开制造订单")
	bookOpenPro:SetPoint("LEFT", ProfessionsBookFrame.TitleContainer, "LEFT",30,0)
	bookOpenPro:SetScript("OnClick", function()
		if not ProfessionsCustomerOrdersFrame then
			C_AddOns.LoadAddOn("Blizzard_ProfessionsCustomerOrders")

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
end)

-- 拍卖行页面添加打开订单按钮
EventUtil.ContinueOnAddOnLoaded("Blizzard_AuctionHouseUI", function()
	if AuctionOpenPro then return end
	local AuctionOpenPro = CreateFrame("Button", "AuctionOpenPro", AuctionHouseFrame.TitleContainer, "UIPanelButtonTemplate")
	AuctionOpenPro:SetSize(120, 22)
	AuctionOpenPro:SetText("打开制造订单")
	AuctionOpenPro:SetPoint("LEFT", AuctionHouseFrame.TitleContainer, "LEFT",0,0)
	AuctionOpenPro:SetScript("OnClick", function()
		if not ProfessionsCustomerOrdersFrame then
			C_AddOns.LoadAddOn("Blizzard_ProfessionsCustomerOrders")
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
end)

ns.tips("宏命令窗口尺寸调整")
EventUtil.ContinueOnAddOnLoaded("Blizzard_MacroUI", function()
    -- 窗口原 338 x 424 → 440 x 561（宽 +102，高 +137）
    MacroFrame:SetWidth(338+102);
    MacroFrame:SetHeight(424+47+90);                            -- 网格 +47（4 行），输入区 +90

    -- 宏按钮网格区：原 319 x 146，宽 +102，高 +47，每行 6→8 个
    -- 4 行高 = 5 + 4*36 + 3*13 + 5 = 193
    MacroFrame.MacroSelector:SetWidth(319+102);
    MacroFrame.MacroSelector:SetHeight(146+47);
    MacroFrame.MacroSelector:SetCustomStride(8);

    -- 网格区下方元素整体下移 47
    MacroHorizontalBarLeft:SetWidth(256+102);                   -- 分隔条（右侧尾条自动跟随）
    MacroHorizontalBarLeft:ClearAllPoints();
    MacroHorizontalBarLeft:SetPoint("TOPLEFT", 2, -210-47);
    MacroFrameSelectedMacroBackground:ClearAllPoints();         -- 选中宏图标框
    MacroFrameSelectedMacroBackground:SetPoint("TOPLEFT", 5, -218-47);
    MacroFrameSelectedMacroName:SetWidth(256+102);              -- 选中宏名称

    -- 输入区：原 95 / 85，高各 +90，整体下移 47
    MacroFrameTextBackground:SetWidth(322+102);
    MacroFrameTextBackground:SetHeight(95+90);
    MacroFrameTextBackground:ClearAllPoints();
    MacroFrameTextBackground:SetPoint("TOPLEFT", MacroFrame, "TOPLEFT", 6, -289-47);
    MacroFrameScrollFrame:SetWidth(286+102);                    -- 宏文本滚动框
    MacroFrameScrollFrame:SetHeight(85+90);
    MacroFrameText:SetWidth(286+102);                           -- 宏文本输入框
    MacroFrameText:SetHeight(85+90);
    MacroFrameTextButton:SetWidth(286+102);                     -- 宏文本点击层
    MacroFrameTextButton:SetHeight(85+90);
end)

end)
