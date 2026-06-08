local _,ns = ...

ns.hook(EncounterTimelineEventFrameMixin,"OnLoad",function(self)
	--EncounterTimelineTextWithIconEventFrameMixin
	if self.NameText then
		self.NameText:SetFont(self.NameText:GetFont(), 22,"OUTLINE");
	end
	if self.StatusText then
		self.StatusText:SetFont(self.StatusText:GetFont(), 20,"OUTLINE");
	end
end)