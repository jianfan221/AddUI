local AddonName,ns = ...

local SetPrice = 0
local SetNumber = 1
local SetAutoKO = false
local SetIsSure = false
local KOAHFrame = CreateFrame("Frame")
KOAHFrame:RegisterEvent("COMMODITY_PRICE_UPDATED")
KOAHFrame:RegisterEvent("COMMODITY_SEARCH_RESULTS_UPDATED")
KOAHFrame:RegisterEvent("AUCTION_HOUSE_SHOW")
KOAHFrame:RegisterEvent("COMMODITY_PURCHASE_FAILED")
KOAHFrame:RegisterEvent("COMMODITY_PURCHASE_SUCCEEDED")
KOAHFrame:RegisterEvent("AUCTION_HOUSE_BROWSE_FAILURE")
KOAHFrame:RegisterEvent("BID_ADDED")
KOAHFrame:RegisterEvent("BIDS_UPDATED")
KOAHFrame:SetScript("OnEvent", function(self, event,...)
	if event == "AUCTION_HOUSE_SHOW" then
		if not KOAH then
			if not AuctionHouseFrame then return end
			if not AuctionHouseFrame.CommoditiesBuyFrame then return end
			if not AuctionHouseFrame.CommoditiesBuyFrame.BuyDisplay then return end
			if not AuctionHouseFrame.CommoditiesBuyFrame.BuyDisplay.Background then return end
			
			
			
			local AHFRAME = AuctionHouseFrame.CommoditiesBuyFrame.BuyDisplay
			local KOAHS = CreateFrame("Frame",AHFRAME)
			KOAHS:SetParent(AHFRAME)
			
			--按空格拍卖
			if AuctionHouseFrame.CommoditiesSellFrame.PostButton then
				local SetAutoPost = false
				if KOAHS.AutoPost then
					KOAHS.AutoPost:SetChecked(SetAutoPost)
					KOAHS.AutoPost2:SetChecked(SetAutoPost)
					return
				end
				KOAHS.AutoPost = CreateFrame("CheckButton", nil, AuctionHouseFrame.CommoditiesSellFrame, "InterfaceOptionsCheckButtonTemplate")
				KOAHS.AutoPost:SetPoint("TOPLEFT", AuctionHouseFrame.CommoditiesSellFrame.PostButton, "BOTTOMLEFT", 0, -10)
				KOAHS.AutoPost:SetFrameStrata("HIGH")
				KOAHS.AutoPost:SetChecked(SetAutoPost)
				KOAHS.AutoPost.text:SetText("按空格创建拍卖")
				KOAHS.AutoPost:SetScript("OnClick", function (self)
					SetAutoPost = self:GetChecked()
				end)
				KOAHS.AutoPost:HookScript("OnKeyDown", function(self, key)
					if key == "SPACE" and SetAutoPost then
						AuctionHouseFrame.CommoditiesSellFrame.PostButton:Click()
						KOAHS.AutoPost:SetPropagateKeyboardInput(false)
					else
						KOAHS.AutoPost:SetPropagateKeyboardInput(true)
					end
				end)

				KOAHS.AutoPost2 = CreateFrame("CheckButton", nil, AuctionHouseFrame.ItemSellFrame, "InterfaceOptionsCheckButtonTemplate")
				KOAHS.AutoPost2:SetPoint("TOPLEFT", AuctionHouseFrame.ItemSellFrame.PostButton, "BOTTOMLEFT", 0, -10)
				KOAHS.AutoPost2:SetFrameStrata("HIGH")
				KOAHS.AutoPost2:SetChecked(SetAutoPost)
				KOAHS.AutoPost2.text:SetText("按空格创建拍卖")
				KOAHS.AutoPost2:SetScript("OnClick", function (self)
					SetAutoPost = self:GetChecked()
				end)
				KOAHS.AutoPost2:HookScript("OnKeyDown", function(self, key)
					if key == "SPACE" and SetAutoPost then
						AuctionHouseFrame.ItemSellFrame.PostButton:Click()
						KOAHS.AutoPost2:SetPropagateKeyboardInput(false)
					else
						KOAHS.AutoPost2:SetPropagateKeyboardInput(true)
					end
				end)
			end
			---空格拍卖只到这里

			--价格输入框
			local GoldIcon = "\124TInterface\\MoneyFrame\\UI-GoldIcon:%d:%d:1:0\124t";
			KOAHS.gold = CreateFrame("EditBox", nil, KOAHS, "InputBoxTemplate")
			KOAHS.gold:SetSize(60, 30)
			KOAHS.gold:SetPoint("BOTTOMLEFT",AHFRAME,"BOTTOMLEFT",85,-3)
			KOAHS.gold:SetAutoFocus(false)
			KOAHS.gold:SetNumeric(true)
			KOAHS.gold:SetJustifyH("RIGHT")
			KOAHS.gold:SetTextInsets(-10, 18, 0, -2)
			KOAHS.gold:SetMaxLetters(50)
			KOAHS.gold:SetTextColor(0,1,1)
			KOAHS.gold:SetText(SetPrice)
			KOAHS.gold:SetCursorPosition(0)
			KOAHS.gold:SetMaxLetters(5)
			KOAHS.gold:HighlightText(0, KOAHS.gold:GetNumLetters())
			
			KOAHS.goldText = KOAHS:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
			KOAHS.goldText:SetPoint("RIGHT",KOAHS.gold,"LEFT",-5,-1)
			KOAHS.goldText:SetFont("Fonts\\ARKai_T.ttf", 16, "OUTLINE")
			KOAHS.goldText:SetTextColor(1,1,1)
			KOAHS.goldText:SetText("目标价格")
			
			KOAHS.goldicon = KOAHS.gold:CreateTexture(nil, "OVERLAY")
			KOAHS.goldicon:SetSize(12, 12)	
			KOAHS.goldicon:SetTexture("Interface\\MoneyFrame\\UI-GoldIcon")
			KOAHS.goldicon:SetPoint("RIGHT",KOAHS.gold,"RIGHT",-3,-1)
			
			KOAHS.gold:SetScript("OnEnterPressed", function(self)
				if self:GetText() and tonumber(self:GetText()) then
					SetPrice = tonumber(self:GetText())
					KOAHS.gold:SetText(SetPrice)
				else
					KOAHS.gold:SetText(0)
					SetPrice = 0
				end
				self:ClearFocus()
			end)
			KOAHS.gold:SetScript("OnTextChanged", function(self)
				if self:GetText() and tonumber(self:GetText()) then
					SetPrice = tonumber(self:GetText())
					KOAHS.gold:SetText(SetPrice)
				else
					KOAHS.gold:SetText(0)
					SetPrice = 0
				end
			end)
			
			
			--数量输入框
			KOAHS.amount = CreateFrame("EditBox", nil, KOAHS, "InputBoxTemplate")
			KOAHS.amount:SetSize(60, 30)
			KOAHS.amount:SetPoint("BOTTOM",AHFRAME,"BOTTOM",40,-3)
			KOAHS.amount:SetAutoFocus(false)
			KOAHS.amount:SetNumeric(true)
			KOAHS.amount:SetJustifyH("CENTER")
			KOAHS.amount:SetTextInsets(-5, 0, 0, -2)
			KOAHS.amount:SetMaxLetters(50)
			KOAHS.amount:SetTextColor(0,1,1)
			KOAHS.amount:SetText(SetNumber)
			KOAHS.amount:SetCursorPosition(1)
			KOAHS.amount:SetMaxLetters(4)
			KOAHS.amount:HighlightText(0, KOAHS.amount:GetNumLetters())
			
			KOAHS.amountText = KOAHS:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
			KOAHS.amountText:SetPoint("RIGHT",KOAHS.amount,"LEFT",-5,-1)
			KOAHS.amountText:SetFont("Fonts\\ARKai_T.ttf", 16, "OUTLINE")
			KOAHS.amountText:SetTextColor(1,1,1)
			KOAHS.amountText:SetText("数量")
			
			KOAHS.amount:SetScript("OnEnterPressed", function(self)
				if self:GetText() and tonumber(self:GetText()) then
					SetNumber = tonumber(self:GetText())
					KOAHS.amount:SetText(SetNumber)
				else
					KOAHS.amount:SetText(1)
					SetNumber = 1
				end
				self:ClearFocus()
			end)
			KOAHS.amount:SetScript("OnTextChanged", function(self)
				if self:GetText() and tonumber(self:GetText()) then
					SetNumber = tonumber(self:GetText())
					KOAHS.amount:SetText(SetNumber)
				else
					KOAHS.amount:SetText(1)
					SetNumber = 1
				end
			end)
			
			--秒杀按钮
			KOAHS.button = CreateFrame("Button", "KOAH", KOAHS, "UIPanelButtonTemplate")
			KOAHS.button:SetSize(88, 22)
			KOAHS.button:SetText("秒杀")
			KOAHS.button:SetPoint("BOTTOMRIGHT", AHFRAME, "BOTTOMRIGHT",-2,1.5)
			KOAHS.button:SetScript("OnClick", function()
				KOAH:SetEnabled(false)
				SetIsSure = true
				self.ItemID = AuctionHouseFrame.CommoditiesBuyFrame.BuyDisplay.ItemDisplay:GetItemID()
				C_AuctionHouse.StartCommoditiesPurchase(self.ItemID,SetNumber)
			end)

			KOAHS:EnableKeyboard(true)
			KOAHS:SetPropagateKeyboardInput(false)
			KOAHS:HookScript("OnKeyDown", function(self, key)
				if key == "SPACE" and SetAutoKO then
					KOAHS.button:Click()
					KOAHS:SetPropagateKeyboardInput(false)
				else
					KOAHS:SetPropagateKeyboardInput(true)
				end
			end)

			--勾选框
			KOAHS.check = CreateFrame("CheckButton", nil, KOAHS, "InterfaceOptionsCheckButtonTemplate")
			KOAHS.check:SetPoint("RIGHT", KOAHS.button, "LEFT", 3, -1)
			KOAHS.check:SetChecked(false)
			KOAHS.check:SetScale(1.1)
			KOAHS.check:SetScript("OnEnter",function(self) 
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT") 
				GameTooltip:AddLine("出现任何问题概不负责,|cffFFFFFF\n勾选此项后,按空格即可秒杀|r") 
				GameTooltip:Show() 
			end)
			KOAHS.check:SetScript("OnLeave", function(self)    
				GameTooltip:Hide()
			end)
			KOAHS.check:SetScript("OnClick", function (self)
				SetAutoKO = self:GetChecked()
			end)
			
			AuctionHouseFrame:HookScript("OnHide", function()
				SetAutoKO = false
				KOAHS.check:SetChecked(false)
			end)
		end
	end
	
	if not KOAH then return end
	if event == "COMMODITY_SEARCH_RESULTS_UPDATED" then
		KOAH:SetEnabled(true)
	end
	if event == "AUCTION_HOUSE_BROWSE_FAILURE" then
		KOAH:SetEnabled(true)
	end
	if event ==  "COMMODITY_PURCHASE_FAILED" or event == "COMMODITY_PURCHASE_SUCCEEDED" then
		KOAH:SetEnabled(true)
	end
	if event == "BID_ADDED" or event == "BIDS_UPDATED" then
        KOAH:SetEnabled(true)
    end
	if not self.ItemID then return end
	if not SetIsSure then return end
	if event == "COMMODITY_PRICE_UPDATED" then
		local itemPrice, itemAllPrice = ...
		if not itemAllPrice then print("未查询到价格") return end
		local itemName = C_Item.GetItemNameByID(self.ItemID)
		local printPrice = GetCoinTextureString(tonumber(itemAllPrice/SetNumber))
		if itemPrice and itemAllPrice <= SetPrice*10000*SetNumber then--and itemPrice <= SetPrice*10000
			C_AuctionHouse.ConfirmCommoditiesPurchase(self.ItemID,SetNumber)
			print("|cff00FFFF购买|r "..itemName.."x"..SetNumber.."|cff00FFFF 等待系统确认,单价|r" ..printPrice)
		else
			--C_AuctionHouse.CancelCommoditiesPurchase()
			KOAH:SetEnabled(true)
			print("|cffDC143C购买|r "..itemName.."x"..SetNumber.."|cffDC143C 失败,当前单价:|r".. printPrice)
		end
		SetIsSure = false
	end
	
	
end)