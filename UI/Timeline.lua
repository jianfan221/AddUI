local _,ns = ...

hooksecurefunc(EncounterTimelineEventFrameMixin,"OnLoad",function(self)
	--EncounterTimelineTextWithIconEventFrameMixin
	if self.NameText then
		self.NameText:SetPoint("RIGHT",self:GetIconFrame(),"LEFT",0,0)
		self.NameText:SetFont(self.NameText:GetFont(), 22,"OUTLINE");
	end
	if self.StatusText then
		self.StatusText:SetPoint("RIGHT",self:GetIconFrame(),"LEFT",0,0)
		self.StatusText:SetFont(self.StatusText:GetFont(), 20,"OUTLINE");
	end
end)