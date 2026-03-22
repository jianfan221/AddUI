local _,ns = ...
ns.tips("观察界面显示装等")
hooksecurefunc("ShowUIPanel", function(self)
	if self ~= InspectFrame then return end
	if not InspectPaperDollItemsFrame then return end
	if not ADInspectLevel then 
		local ADInspectLevel = InspectPaperDollItemsFrame:CreateFontString("ADInspectLevel", "ARTWORK")
		ADInspectLevel:SetFont("fonts\\ARHei.ttf", 25, "OUTLINE") 
		ADInspectLevel:SetPoint("RIGHT",InspectFrame.TopTileStreaks,"RIGHT",-3, 0)
	end
	if ADInspectLevel then
		ADInspectLevel:SetText(C_PaperDollInfo.GetInspectItemLevel(InspectFrame.unit))
	end
	if self.moveinspectframe then return end
	self.moveinspectframe = true
	InspectFrame:SetMovable(true)
	InspectFrame:HookScript("OnMouseDown", function()
		InspectFrame:StartMoving()
	end)
	InspectFrame:HookScript('OnMouseUp', function(self, button)
		InspectFrame:StopMovingOrSizing()
	end)
end)