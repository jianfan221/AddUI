local _,ns = ...
ns.tips("商人出售物品搜索")

local activeSearch = ""
local perPage = MERCHANT_ITEMS_PER_PAGE
local infoCache = {}  -- C_MerchantFrame.GetItemInfo 缓存
local tipCache = {}   -- 鼠标提示文本缓存

local function ClearSlot(i)
	local btn = _G["MerchantItem"..i.."ItemButton"]
	_G["MerchantItem"..i.."Name"]:SetText("")
	_G["MerchantItem"..i.."MoneyFrame"]:Hide()
	_G["MerchantItem"..i.."AltCurrencyFrame"]:Hide()
	btn:Hide()
	btn.hasItem = nil
	btn.price = nil
	btn.name = nil
	btn.link = nil
	SetItemButtonTexture(btn, "")
	_G["MerchantItem"..i]:Hide()
	_G["MerchantItem"..i]:SetAlpha(0)
	_G["MerchantItem"..i]:EnableMouse(false)
end

ns.hook("MerchantFrame_Update", function()
	if activeSearch == "" then
		for i = 1, perPage do
			_G["MerchantItem"..i]:Show()
			_G["MerchantItem"..i]:SetAlpha(1)
			_G["MerchantItem"..i]:EnableMouse(true)
		end
		return
	end

	if MerchantFrame.selectedTab ~= 1 then return end

	local searchText = activeSearch:lower()
	local matches = {}

	for index = 1, GetMerchantNumItems() do
		if not infoCache[index] then infoCache[index] = C_MerchantFrame.GetItemInfo(index) end
		local info = infoCache[index]
		if not info or not info.name then break end

		local matched = info.name:lower():find(searchText, 1, true)
		if not matched then
			if not tipCache[index] then
				local tipData = C_TooltipInfo.GetMerchantItem(index)
				if tipData and tipData.lines then
					local texts = {}
					for _, line in ipairs(tipData.lines) do
						local t = line.leftText or line.text
						if t then tinsert(texts, t:lower()) end
					end
					tipCache[index] = texts
				else
					tipCache[index] = {}
				end
			end
			for _, t in ipairs(tipCache[index]) do
				if t:find(searchText, 1, true) then
					matched = true
					break
				end
			end
		end

		if matched then
			tinsert(matches, {index = index, info = info})
		end
	end

	for i = 1, perPage do ClearSlot(i) end
	if #matches == 0 then
		MerchantPageText:Hide()
		MerchantPrevPageButton:Hide()
		MerchantNextPageButton:Hide()
		return
	end

	local from = ((MerchantFrame.page - 1) * perPage) + 1
	local to = math.min(#matches, from + perPage - 1)

	for i = from, to do
		local slotIdx = i - (MerchantFrame.page - 1) * perPage
		local match = matches[i]
		local slot = _G["MerchantItem"..slotIdx]
		local btn = _G["MerchantItem"..slotIdx.."ItemButton"]
		local nameText = _G["MerchantItem"..slotIdx.."Name"]
		local moneyFrame = _G["MerchantItem"..slotIdx.."MoneyFrame"]
		local altCurrency = _G["MerchantItem"..slotIdx.."AltCurrencyFrame"]

		nameText:SetText(match.info.name)
		SetItemButtonTexture(btn, match.info.texture)
		SetItemButtonCount(btn, match.info.stackCount or 0)
		SetItemButtonStock(btn, match.info.numAvailable or 0)
		btn:SetID(match.index)
		btn.hasItem = true
		btn.price = match.info.price
		btn.name = match.info.name
		btn.link = GetMerchantItemLink(match.index)
		btn.texture = match.info.texture

		if match.info.price and match.info.price > 0 then
			MoneyFrame_Update(moneyFrame:GetName(), match.info.price)
			moneyFrame:Show()
		else
			moneyFrame:Hide()
		end

		local quality = btn.link and select(3, C_Item.GetItemInfo(btn.link))
		if quality then
			local cd = ColorManager.GetColorDataForItemQuality(quality)
			nameText:SetTextColor(cd.r, cd.g, cd.b)
			btn:SetItemButtonQuality(quality, btn.link, false, false)
		else
			nameText:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
		end

		slot:Show()
		slot:SetAlpha(1)
		slot:EnableMouse(true)
		btn:Show()
	end

	-- 根据搜索结果页数控制分页
	local totalMatchPages = math.ceil(#matches / perPage)
	if totalMatchPages <= 1 then
		MerchantPageText:Hide()
		MerchantPrevPageButton:Hide()
		MerchantNextPageButton:Hide()
	else
		MerchantPageText:SetFormattedText(MERCHANT_PAGE_NUMBER, MerchantFrame.page, totalMatchPages)
		MerchantPrevPageButton:Show()
		MerchantNextPageButton:Show()
		MerchantPrevPageButton:SetEnabled(MerchantFrame.page > 1)
		MerchantNextPageButton:SetEnabled(MerchantFrame.page < totalMatchPages)
	end
end)

ns.event("MERCHANT_SHOW", function()
	if MerchantSearchBox then return end

	local searchBox = CreateFrame("EditBox", "MerchantSearchBox", MerchantFrame, "SearchBoxTemplate")
	searchBox:SetSize(110, 22)
	searchBox:SetPoint("TOPLEFT", MerchantFrame, "TOPLEFT", 60, -30)
	searchBox:SetAutoFocus(false)
	SearchBoxTemplate_OnLoad(searchBox)

	searchBox:SetScript("OnTextChanged", function(self)
		SearchBoxTemplate_OnTextChanged(self)
		local text = self:GetText()
		activeSearch = text

		if text == "" then
			MerchantFrame_Update()
		else
			MerchantFrame.page = 1
			MerchantFrame_Update()
		end
	end)

	searchBox:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
	end)
end)

ns.event("MERCHANT_CLOSED", function()
	wipe(infoCache)
	wipe(tipCache)
end)
