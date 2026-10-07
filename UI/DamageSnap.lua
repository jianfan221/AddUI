local _,ns = ...
--伤害统计窗口自动吸附：拖动副窗口时，靠近前一个窗口就自动贴附
--上下吸=宽度取一致，左右吸=高度取一致
--（窗口拖动与缩放手柄都由本文件接管，Damage.lua 不再处理位置）
--吸附方向存进 AddUIDB.damasnap，登录/进本后重放（layout-local.txt 只存矩形，不存锚点关系）
--思路参考：暴雪编辑模式磁吸 EditModeMagnetismManager（Blizzard_EditMode/Shared/EditModeUtil.lua）

local GAP_X = -3		--左右贴附后的间距
local GAP_Y = 3		--上下贴附后的间距
local RANGE = 15	--触发吸附的距离（像素）

local hooked = setmetatable({}, {__mode = "k"})
local snapped = setmetatable({}, {__mode = "k"})	--已吸附的窗口 → 吸附方向

--贴附：dir 为 src 相对 tgt 的方向
local function ApplySnap(src, tgt, dir)
	src:ClearAllPoints()
	if dir == "UP" then			--src 在 tgt 上方
		src:SetPoint("BOTTOMLEFT", tgt, "TOPLEFT", 0, -GAP_Y)
		src:SetPoint("BOTTOMRIGHT", tgt, "TOPRIGHT", 0, -GAP_Y)
	elseif dir == "DOWN" then	--src 在 tgt 下方
		src:SetPoint("TOPLEFT", tgt, "BOTTOMLEFT", 0, GAP_Y)
		src:SetPoint("TOPRIGHT", tgt, "BOTTOMRIGHT", 0, GAP_Y)
	elseif dir == "LEFT" then	--src 在 tgt 左侧
		src:SetPoint("TOPRIGHT", tgt, "TOPLEFT", -GAP_X, 0)
		src:SetPoint("BOTTOMRIGHT", tgt, "BOTTOMLEFT", -GAP_X, 0)
	elseif dir == "RIGHT" then	--src 在 tgt 右侧
		src:SetPoint("TOPLEFT", tgt, "TOPRIGHT", GAP_X, 0)
		src:SetPoint("BOTTOMLEFT", tgt, "BOTTOMRIGHT", GAP_X, 0)
	end
	src:SetUserPlaced(true)
end

--判定方向：多个方向都满足时取间隙最小的那个（没命中返回 nil）
local function GetSnapDir(src, tgt)
	if not AddUIDB.poidama then return end
	if not (src and tgt and src:IsShown() and tgt:IsShown()) then return end

	local sLeft, sBottom, sWidth, sHeight = src:GetRect()
	local tLeft, tBottom, tWidth, tHeight = tgt:GetRect()
	if not (sLeft and tLeft) then return end
	if ns.MM(sLeft) or ns.MM(tLeft) then return end

	local sRight, sTop = sLeft + sWidth, sBottom + sHeight
	local tRight, tTop = tLeft + tWidth, tBottom + tHeight

	--只在有投影重叠的方向上吸，避免斜着靠近时吸到意外的方向
	local overlapX = math.min(sRight, tRight) - math.max(sLeft, tLeft)
	local overlapY = math.min(sTop, tTop) - math.max(sBottom, tBottom)

	local bestDir, bestDist

	if overlapX > 0 then
		local up = math.abs(sBottom - tTop + GAP_Y)		--离"吸附后位置"的距离
		local down = math.abs(tBottom - sTop + GAP_Y)
		if up < RANGE then bestDir, bestDist = "UP", up end
		if down < RANGE and (not bestDist or down < bestDist) then bestDir, bestDist = "DOWN", down end
	end

	if overlapY > 0 then
		local left = math.abs(tLeft - sRight - GAP_X)
		local right = math.abs(sLeft - tRight - GAP_X)
		if left < RANGE and (not bestDist or left < bestDist) then bestDir, bestDist = "LEFT", left end
		if right < RANGE and (not bestDist or right < bestDist) then bestDir, bestDist = "RIGHT", right end
	end

	return bestDir
end

--吸附目标：前一个可见窗口，都没有就用主窗口
local function GetTarget(index)
	for i = index - 1, 1, -1 do
		local frame = _G["DamageMeterSessionWindow"..i]
		if frame and frame:IsShown() then return frame end
	end
end

--吸附方向存档：layout-local.txt 只存最终矩形，锚点关系靠这里记的方向在登录后重放
local function StoreSnap(index, dir)
	AddUIDB.damasnap = AddUIDB.damasnap or {}
	AddUIDB.damasnap[index] = dir
end

--重放存档的吸附：把副窗口重新贴回它的目标窗口
local function ReplaySnap(index)
	if not AddUIDB or not AddUIDB.poidama then return end
	local dir = AddUIDB.damasnap and AddUIDB.damasnap[index]
	if not dir then return end
	local src = _G["DamageMeterSessionWindow"..index]
	if not src or not src:IsShown() then return end
	local tgt = GetTarget(index)
	if not tgt then return end
	ApplySnap(src, tgt, dir)
	snapped[src] = dir
end

--参考线：拖动中提示松手后会贴到目标框的哪条边
local lineH = UIParent:CreateTexture(nil, "OVERLAY")
local lineV = UIParent:CreateTexture(nil, "OVERLAY")
lineH:SetColorTexture(1, 0.82, 0, 0.9)
lineH:SetHeight(2)
lineV:SetColorTexture(1, 0.82, 0, 0.9)
lineV:SetWidth(2)
lineH:Hide()
lineV:Hide()

local function ShowPreview(tgt, dir)
	local tLeft, tBottom, tWidth, tHeight = tgt:GetRect()
	if not tLeft or ns.MM(tLeft) then return end
	if dir == "UP" or dir == "DOWN" then
		lineH:ClearAllPoints()
		lineH:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", tLeft, dir == "UP" and (tBottom + tHeight) or tBottom)
		lineH:SetWidth(tWidth)
		lineH:Show()
	elseif dir == "LEFT" or dir == "RIGHT" then
		lineV:ClearAllPoints()
		lineV:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", dir == "LEFT" and tLeft or (tLeft + tWidth), tBottom)
		lineV:SetHeight(tHeight)
		lineV:Show()
	end
end

local function HidePreview()
	lineH:Hide()
	lineV:Hide()
end

--拖动期间的判定驱动（只在拖动时显示）：拖动中一直判定，松手才设置位置
local dragSrc, dragTgt, dragDir
local driver = CreateFrame("Frame")
driver:Hide()
driver:SetScript("OnUpdate", function()
	if not (dragSrc and dragTgt) then return end
	if not dragSrc:IsVisible() then		--拖动被中断（窗口被隐藏等），清理避免参考线残留
		dragSrc, dragTgt, dragDir = nil, nil, nil
		HidePreview()
		driver:Hide()
		return
	end
	dragDir = GetSnapDir(dragSrc, dragTgt)
	if dragDir then
		ShowPreview(dragTgt, dragDir)
	else
		HidePreview()
	end
end)

--给窗口 index 挂吸附（吸到前一个可见窗口）
local function SetupSnap(index)
	local src = _G["DamageMeterSessionWindow"..index]
	if not src then return end
	if hooked[src] then return end
	hooked[src] = true

	--开始拖动：开启判定
	src:HookScript("OnDragStart", function(self)
		if not self:CanMoveOrResize() then return end
		local tgt = GetTarget(index)
		if not tgt then return end
		dragSrc, dragTgt, dragDir = self, tgt, nil
		driver:Show()
	end)

	--拖动结束：此时才真正设置位置
	src:HookScript("OnDragStop", function(self)
		if dragSrc ~= self or not dragTgt then return end
		local dir = GetSnapDir(self, dragTgt) or dragDir	--以松手时的位置为准
		if dir then
			ApplySnap(self, dragTgt, dir)
			snapped[self] = dir		--记住吸附关系
			StoreSnap(index, dir)
		else
			snapped[self] = nil		--没吸上，解除记录
			StoreSnap(index, nil)
		end
		dragSrc, dragTgt, dragDir = nil, nil, nil
		HidePreview()
		driver:Hide()
	end)

	--缩放手柄松手：已吸附的窗口重新贴合（缩放会把贴边撞歪）
	local resize = src:GetResizeButton()
	if resize then
		resize:HookScript("OnMouseUp", function(button, mouseButtonName)
			if mouseButtonName ~= "LeftButton" then return end
			if not src:CanMoveOrResize() then return end
			local tgt = GetTarget(index)
			if not tgt then return end
			local dir = snapped[src] or GetSnapDir(src, tgt)
			if dir then
				ApplySnap(src, tgt, dir)
				snapped[src] = dir
				StoreSnap(index, dir)
			end
		end)
	end
end

local inited = false
local function SetupAll()
	if inited or not DamageMeter then return end
	inited = true

	--新建窗口时注册
	ns.hook(DamageMeter, "SetupSessionWindow", function(self, windowDataIndex)
		if windowDataIndex and windowDataIndex > 1 then
			SetupSnap(windowDataIndex)
			--窗口位置随后可能被 layout-local.txt 缓存覆盖，延后一帧重放吸附
			C_Timer.After(0, function() ReplaySnap(windowDataIndex) end)
		end
	end)

	--已存在的窗口补注册
	for i = 2, DamageMeter:GetMaxSessionWindowCount() do
		SetupSnap(i)
	end
end

--Blizzard_DamageMeter 比本插件加载得早，ADDON_LOADED 已经错过，用 ContinueOnAddOnLoaded 补上
EventUtil.ContinueOnAddOnLoaded("Blizzard_DamageMeter", SetupAll)
ns.event("PLAYER_ENTERING_WORLD", function()--兜底：登录/进本后重放存档的吸附
	SetupAll()
	if not DamageMeter then return end
	C_Timer.After(0, function()
		for i = 2, DamageMeter:GetMaxSessionWindowCount() do
			ReplaySnap(i)
		end
	end)
end)
