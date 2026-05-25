local _, ns = ...
ns.tips("已学物品着绿色")

-- 已学缓存（避免重复扫描tooltip）
local cache = {}
-- 任务物品映射（任务做完=物品已学）
local questMap = {
	[128491] = 39359, [128251] = 39359,
	[128250] = 39358, [128489] = 39358,
}
local COLOR = { r = .1, g = .1, b = .7 }
local PET_KNOWN = strmatch(ITEM_PET_KNOWN, "[^%(]+")

-- 扫描tooltip判断是否已学
local tip = CreateFrame("GameTooltip", "AKScanningTooltip", nil, "GameTooltipTemplate")
tip:SetOwner(UIParent, "ANCHOR_NONE")

local function isKnown(link)
	if cache[link] then return true end

	local id = tonumber(link:match("item:(%d+)"))
	if id and questMap[id] and IsQuestFlaggedCompleted(questMap[id]) then
		cache[link] = true; return true
	end

	if link:match("|H(.-):") == "battlepet" then
		local _, pid = strsplit(":", link)
		if C_PetJournal.GetNumCollectedInfo(pid) > 0 then
			cache[link] = true; return true
		end
		return false
	end

	tip:ClearLines()
	tip:SetHyperlink(link)

	local n = tip:NumLines()
	for i = 2, n do
		local text = _G["AKScanningTooltipTextLeft" .. i]:GetText()
		if text == ITEM_SPELL_KNOWN or strmatch(text, PET_KNOWN) then
			if n - i <= 3 then cache[link] = true end
		elseif text == TOY and _G["AKScanningTooltipTextLeft" .. i + 2] and
			_G["AKScanningTooltipTextLeft" .. i + 2]:GetText() == ITEM_SPELL_KNOWN then
			cache[link] = true
		end
	end
	return cache[link] and true or false
end

-- 拍卖行浏览着色
local bc = {}
local function buildBC()
	for i = 1, NUM_BROWSE_TO_DISPLAY do
		bc[i] = {
			item = _G["BrowseButton" .. i .. "Item"],
			icon = _G["BrowseButton" .. i .. "ItemIconTexture"],
			btn = _G["BrowseButton" .. i],
		}
	end
end

local function colorAH()
	local off = FauxScrollFrame_GetOffset(BrowseScrollFrame)
	for i = 1, NUM_BROWSE_TO_DISPLAY do
		local c = bc[i]
		if not (c.item and c.icon) and not c.btn.id then return end
		local link = c.btn.id and GetAuctionItemLink('list', c.btn.id) or GetAuctionItemLink('list', off + i)
		local known = link and isKnown(link)
		local t = c.btn.id and c.btn.Icon or c.icon
		t:SetVertexColor(known and COLOR.r or 1, known and COLOR.g or 1, known and COLOR.b or 1)
	end
end

-- 商人着色
local mc = {}
local function buildMC()
	for i = 1, MERCHANT_ITEMS_PER_PAGE do
		mc[i] = {
			itemBtn = _G["MerchantItem" .. i .. "ItemButton"],
			merBtn = _G["MerchantItem" .. i],
			icon = _G["MerchantItem" .. i .. "ItemButtonIconTexture"],
		}
	end
end

local function colorMerchant()
	for i = 1, MERCHANT_ITEMS_PER_PAGE do
		local c = mc[i]
		local idx = ((MerchantFrame.page - 1) * MERCHANT_ITEMS_PER_PAGE) + i
		local link = GetMerchantItemLink(idx)
		if link and isKnown(link) then
			SetItemButtonNameFrameVertexColor(c.merBtn, COLOR.r, COLOR.g, COLOR.b)
			SetItemButtonSlotVertexColor(c.merBtn, COLOR.r, COLOR.g, COLOR.b)
			SetItemButtonTextureVertexColor(c.itemBtn, 0.9 * COLOR.r, 0.9 * COLOR.g, 0.9 * COLOR.b)
			SetItemButtonNormalTextureVertexColor(c.itemBtn, 0.9 * COLOR.r, 0.9 * COLOR.g, 0.9 * COLOR.b)
		end
	end
end

-- 初始化
ns.event("ADDON_LOADED", function()
	if AuctionFrameBrowse_Update then
		buildBC()
		ns.hook("AuctionFrameBrowse_Update", colorAH)
	end
	buildMC()
	ns.hook("MerchantFrame_UpdateMerchantInfo", colorMerchant)
end, true)
