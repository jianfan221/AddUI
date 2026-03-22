local _,ns = ...
ns.tips("小地图标题栏显示位面ID")
ns.tips("大地图输入坐标标记")
ns.event("PLAYER_ENTERING_WORLD", function()
if AddUIDB.smap ==  false  then return end

--隐藏一些东西
MinimapBackdrop:Hide()	--圆形材质
MinimapCluster:SetScale(.8)	--大小
Minimap:SetQuestBlobRingScalar(0)	--任务追踪环形网格
--微调小地图位置
Minimap:SetPoint("CENTER",MinimapCluster,"TOP", 15,-125)

--边框材质
Minimap:SetMaskTexture([=[Interface\ChatFrame\ChatFrameBackground]=])
function GetMinimapShape() return "SQUARE" end

local function CreateShadow(f)
	if f.shadow then return end
	--local color = RAID_CLASS_COLORS[select(2, UnitClass("player"))]
	local shadow = CreateFrame("Frame", nil, f, "BackdropTemplate")
	shadow:SetFrameLevel(0)
	shadow:SetFrameStrata(f:GetFrameStrata())
	shadow:SetPoint("TOPLEFT", -1, 1)
	shadow:SetPoint("BOTTOMRIGHT", 1, -1)
	shadow:SetBackdrop({edgeFile = 'Interface\\Buttons\\WHITE8x8',edgeSize = 2})
	--shadow:SetBackdropBorderColor(color.r, color.g, color.b, 1)
	shadow:SetBackdropBorderColor(0, 0, 0, 1)
	f.shadow = shadow
	return shadow
end
CreateShadow(Minimap)

--时钟
--LoadAddOn('Blizzard_TimeManager')
local clockFrame, clockTime = TimeManagerClockButton:GetRegions()
clockFrame:Show()
clockTime:Hide()
TimeManagerClockButton:ClearAllPoints()
TimeManagerClockButton:SetPoint("CENTER",Minimap,"BOTTOM",0,-2)
clockFrame:SetFont("fonts\\ARHei.ttf", 17, "OUTLINE")


--插件按钮
AddonCompartmentFrame:ClearAllPoints()
AddonCompartmentFrame:SetPoint("RIGHT",MinimapCluster.Tracking,"LEFT", -2,0)
AddonCompartmentFrame:SetFrameStrata("MEDIUM")
--副本难度框

--副本挑战模式难度框
local mc = MinimapCluster.InstanceDifficulty
mc:ClearAllPoints()
mc:SetPoint("TOPLEFT", MinimapCluster, 0, -25)
mc:SetScale(1)

--小地图要塞按钮位置和大小
local function MinimapButtonE(self)
self:SetParent(Minimap)
self:ClearAllPoints()
self:SetSize(40,40)
self:SetPoint("TOPRIGHT", Minimap,"TOPRIGHT",  -5, -5)
end
MinimapButtonE(ExpansionLandingPageMinimapButton)
ExpansionLandingPageMinimapButton:HookScript("OnShow", MinimapButtonE)
hooksecurefunc(ExpansionLandingPageMinimapButton, "UpdateIcon", MinimapButtonE)


--不显示位面ID的NPC
local NoID={
--[]=true, --
[181059]=true,  --波可波克：类型：Creature  NPCID：181059
[25146]=true,   --佩奇：类型：Creature     NPCID：25146
[62821]=true,   --秘法师鸟羽帽：类型：Creature     NPCID：62821
[62822]=true,   --表弟慢热手：类型：Creature     NPCID：62822
[142666]=true,  --收集者温塔：类型：Creature     NPCID：142666
[142668]=true,  --商人马库：类型：Creature     NPCID：142668

}
local idframe = CreateFrame("Frame","mapid",UIParent)
idframe:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
idframe:RegisterEvent("ZONE_CHANGED_NEW_AREA")
idframe:SetFrameStrata("BACKGROUND")
local weimian = idframe:CreateFontString(nil, "ARTWORK")
weimian:SetFont("fonts\\ARHei.ttf", 11, "OUTLINE") 
weimian:SetPoint("RIGHT",MinimapCluster.BorderTop,"RIGHT",0,1)
idframe:SetScript("OnEvent", function(self,event,aaaa)
if event == "UPDATE_MOUSEOVER_UNIT" then
	if issecretvalue(UnitGUID("mouseover")) then return end
    local guid = UnitGUID("mouseover")
	if not guid then return end
    local types, _, _, _, zoneID, unitID = strsplit("-", guid)
	local ids = tonumber(unitID)
	if types == "Pet" then return end;
	if zoneID == nil then return end;
    if NoID[ids] then return end;
	weimian:SetText("位面:"..zoneID)	
elseif event == "ZONE_CHANGED_NEW_AREA" then
	weimian:SetText("")
end
		
end)

--大地图输入坐标https://bbs.nga.cn/read.php?tid=24183736&_fp=3
-- 输入坐标标记位置
local WayPointPositionButton = CreateFrame("Button", "WayPointPositionButton", WorldMapFrame.BorderFrame.TitleContainer, "UIPanelButtonTemplate")
WayPointPositionButton:SetWidth(50)
WayPointPositionButton:SetHeight(18)
-- WayPointPositionButton.Font = WayPointPositionButton:CreateFontString(nil,nil)
-- WayPointPositionButton.Font:SetFont("Fonts\\ZYKai_T.ttf",12)
-- WayPointPositionButton:SetFontString(WayPointPositionButton.Font)
WayPointPositionButton:SetText("定位")
WayPointPositionButton:SetPoint("LEFT", WorldMapFrame.BorderFrame.Tutorial, "RIGHT", -20, 1)
WayPointPositionButton:SetScript("OnShow", function() WayPointContainer:Close() end)

-- 设置目标位置
function WayPointPositionButton:SetWayPoint(desX, desY)
    local currentViewMapID = WorldMapFrame:GetMapID()
    if C_Map.CanSetUserWaypointOnMap(currentViewMapID) then
        local point = UiMapPoint.CreateFromCoordinates(currentViewMapID, desX / 100, desY / 100)
        C_Map.SetUserWaypoint(point)
        C_SuperTrack.SetSuperTrackedUserWaypoint(true);
    else
        print("|cFFFF0000当前地图无法标记！|r")
    end
end

-- 点击定位按钮
function WayPointPositionButton.OnClick(button, down)
    local currentViewMapID = WorldMapFrame:GetMapID()
    if not C_Map.CanSetUserWaypointOnMap(currentViewMapID) then
        print("|cFFFF0000当前地图无法标记！|r")
        return
    end
    C_Map.ClearUserWaypoint()
    C_SuperTrack.SetSuperTrackedUserWaypoint(false);
    if WayPointContainer then
        if WayPointContainer:IsShown() then
            local xl = WayPointContainer.CoordX:GetText():len()
            local yl = WayPointContainer.CoordY:GetText():len()
            if xl ~= 0 and yl ~= 0 then
                local x = WayPointContainer.CoordX:GetNumber()
                local y = WayPointContainer.CoordY:GetNumber()
                WayPointPositionButton:SetWayPoint(x, y)
            end
            WayPointContainer:Close()
        else
            WayPointContainer:Show()
            WayPointContainer.CoordX:SetFocus()
        end
    end
end
WayPointPositionButton:SetScript("OnClick", WayPointPositionButton.OnClick)

local WayPointContainer = CreateFrame("Frame", "WayPointContainer", WorldMapFrame)
WayPointContainer:SetFrameStrata("DIALOG")
WayPointContainer:SetPoint("BOTTOM", WayPointPositionButton, "TOP", 0, 5)
WayPointContainer:SetWidth(100)
WayPointContainer:SetHeight(25)

function WayPointContainer:Close()
    WayPointContainer.CoordX:SetText("")
    WayPointContainer.CoordX:ClearFocus()
    WayPointContainer.CoordY:SetText("")
    WayPointContainer.CoordY:ClearFocus()
    WayPointContainer:Hide()
end

-- 输入tab
local function OnCoordTabPressed(editBox)
    if editBox == WayPointContainer.CoordX then
        WayPointContainer.CoordX:ClearFocus()
        WayPointContainer.CoordY:SetFocus()
    else
        WayPointContainer.CoordY:ClearFocus()
        WayPointContainer.CoordX:SetFocus()
    end
end

-- 输入回车
local function OnCoordEnterPressed(editBox)
    if editBox == WayPointContainer.CoordX then
        if editBox:GetText():len() ~= 0 then
            WayPointContainer.CoordX:ClearFocus()
            WayPointContainer.CoordY:SetFocus()
        end
    else
        if WayPointContainer.CoordX:GetText():len() ~= 0 and
            WayPointContainer.CoordY:GetText():len() ~= 0 then
            local x = WayPointContainer.CoordX:GetNumber()
            local y = WayPointContainer.CoordY:GetNumber()
            WayPointPositionButton:SetWayPoint(x, y)
            WayPointContainer:Close()
        elseif WayPointContainer.CoordY:GetText():len() ~= 0 and
            WayPointContainer.CoordX:GetText():len() == 0 then
            WayPointContainer.CoordY:ClearFocus()
            WayPointContainer.CoordX:SetFocus()
        end
    end
end

WayPointContainer.CoordY = CreateFrame("EditBox", "WayPointCoordY", WayPointContainer, "InputBoxTemplate")
WayPointContainer.CoordY:SetAutoFocus(false)
WayPointContainer.CoordY:SetSize(30, 20)
WayPointContainer.CoordY:SetNumeric(true)
WayPointContainer.CoordY:SetMaxLetters(2)
WayPointContainer.CoordY:SetPoint("LEFT", WayPointContainer, "CENTER", 75, -25)
WayPointContainer.CoordY:SetScript("OnTabPressed", OnCoordTabPressed)
WayPointContainer.CoordY:SetScript("OnEnterPressed", OnCoordEnterPressed)

WayPointContainer.CoordX = CreateFrame("EditBox", "WayPointCoordX", WayPointContainer, "InputBoxTemplate")
WayPointContainer.CoordX:SetAutoFocus(false)
WayPointContainer.CoordX:SetSize(30, 20)
WayPointContainer.CoordX:SetNumeric(true)
WayPointContainer.CoordX:SetMaxLetters(2)
WayPointContainer.CoordX:SetPoint("RIGHT", WayPointContainer, "CENTER", 65, -25)
WayPointContainer.CoordX:SetScript("OnTabPressed", OnCoordTabPressed)
WayPointContainer.CoordX:SetScript("OnEnterPressed", OnCoordEnterPressed)

WayPointContainer:Hide()

end)