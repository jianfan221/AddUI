local addonName,ns = ...
function ns.StyleButton()
	if C_AddOns.IsAddOnLoaded("Dominos") then return end
	if C_AddOns.IsAddOnLoaded("Bartender4") then return end
	if C_AddOns.IsAddOnLoaded("ElvUI") then	return end
	if C_AddOns.IsAddOnLoaded("BigFoot") then return end
	if C_AddOns.IsAddOnLoaded("NDui") then return end
	local r={"MultiBarBottomLeft", "MultiBarBottomRight", "Action", "MultiBarLeft", "MultiBarRight","MultiBar5","MultiBar6","MultiBar7"} 
	for b=1,#r do for i=1,12 do
		
		_G[r[b].."Button"..i]:SetScale(1.095)
		
		_G[r[b].."Button"..i]:SetNormalTexture("Interface\\AddOns\\AddUI\\UI\\media\\normal")
		_G[r[b].."Button"..i]:SetHighlightTexture("Interface\\AddOns\\AddUI\\UI\\media\\highlight")--鼠标指向高亮
		_G[r[b].."Button"..i]["HighlightTexture"]:SetPoint("TOPLEFT", _G[r[b].."Button"..i], 1.5, -1.5)
		_G[r[b].."Button"..i]["HighlightTexture"]:SetPoint("BOTTOMRIGHT", _G[r[b].."Button"..i], -1.5, 1.5) 
		
		_G[r[b].."Button"..i]:SetCheckedTexture("Interface\\AddOns\\AddUI\\UI\\media\\highlight")--正在施法的材质
		_G[r[b].."Button"..i]["CheckedTexture"]:SetPoint("TOPLEFT", _G[r[b].."Button"..i], 1.5, -1.5)
		_G[r[b].."Button"..i]["CheckedTexture"]:SetPoint("BOTTOMRIGHT", _G[r[b].."Button"..i], -1.5, 1.5) 

		--_G[r[b].."Button"..i]:SetPushedTexture("Interface\\AddOns\\AddUI\\UI\\media\\highlight")--按下材质


		_G[r[b].."Button"..i.."NormalTexture"]:SetPoint("TOPLEFT", _G[r[b].."Button"..i], 1, -1)
		_G[r[b].."Button"..i.."NormalTexture"]:SetPoint("BOTTOMRIGHT", _G[r[b].."Button"..i], -1, 1) 
		_G[r[b].."Button"..i.."Icon"]:SetPoint("TOPLEFT", _G[r[b].."Button"..i], 1, -1)
		_G[r[b].."Button"..i.."Icon"]:SetPoint("BOTTOMRIGHT", _G[r[b].."Button"..i], -1, 1)
		_G[r[b].."Button"..i.."Icon"]:SetTexCoord(.1, .9, .1, .9) 

		_G[r[b].."Button"..i.."Cooldown"]:SetPoint("TOPLEFT", _G[r[b].."Button"..i], 1, -1)
		_G[r[b].."Button"..i.."Cooldown"]:SetPoint("BOTTOMRIGHT", _G[r[b].."Button"..i], -1, 1)

		if ExtraActionButton1.style then ExtraActionButton1.style:Hide() end
		if ZoneAbilityFrame.Style then ZoneAbilityFrame.Style:Hide() end
		if _G[r[b].."Button"..i.."Border"] then _G[r[b].."Button"..i.."Border"]:SetTexture(nil) end
		if _G[r[b].."Button"..i.."FloatingBG"] then _G[r[b].."Button"..i.."FloatingBG"]:Hide() end
		if _G[r[b].."Button"..i.."FlyoutBorder"] then _G[r[b].."Button"..i.."FlyoutBorder"]:SetTexture(nil) end
		if _G[r[b].."Button"..i.."FlyoutBorderShadow"] then _G[r[b].."Button"..i.."FlyoutBorderShadow"]:SetTexture(nil) end

		_G[r[b].."Button"..i.."HotKey"]:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
	end
	end 
end

--快捷键修改抄自nMainbar\ActionButtonSkin.lua
local ActionBarActionButtonMixinHook_UpdateHotkeys = function(self, actionButtonType)
    local hotkey = self.HotKey
    local text = hotkey:GetText()

    text = gsub(text, "(s%-)", "s-")
    text = gsub(text, "(a%-)", "a-")
    text = gsub(text, "(c%-)", "c-")
    text = gsub(text, "(st%-)", "c-") -- German Control "Steuerung"

    for i = 1, 8 do
        text = gsub(text, _G["KEY_BUTTON"..i], "M"..i)
    end

    for i = 0, 9 do
        text = gsub(text, _G["KEY_NUMPAD"..i], "Nu"..i)
    end

    text = gsub(text, KEY_NUMPADDECIMAL, "Nu.")
    text = gsub(text, KEY_NUMPADDIVIDE, "Nu/")
    text = gsub(text, KEY_NUMPADMINUS, "Nu-")
    text = gsub(text, KEY_NUMPADMULTIPLY, "Nu*")
    text = gsub(text, KEY_NUMPADPLUS, "Nu+")
	
	text = gsub(text, CAPSLOCK_KEY_TEXT, "Cap")

    text = gsub(text, KEY_MOUSEWHEELUP, "M↑")
    text = gsub(text, KEY_MOUSEWHEELDOWN, "M↓")
    text = gsub(text, KEY_NUMLOCK, "NuL")
    text = gsub(text, KEY_PAGEUP, "PU")
    text = gsub(text, KEY_PAGEDOWN, "PD")
    text = gsub(text, KEY_SPACE, "_")
    text = gsub(text, KEY_INSERT, "Ins")
    text = gsub(text, KEY_HOME, "Hm")
    text = gsub(text, KEY_DELETE, "Del")

    hotkey:SetText(text)
end
local ActionBarActionButtonMixinHook_OnLoad = function(self)
    ActionBarActionButtonMixinHook_UpdateHotkeys(self)
    hooksecurefunc(self, "UpdateHotkeys", ActionBarActionButtonMixinHook_UpdateHotkeys)
end
-- Force Hotkey Update
ns.event("PLAYER_LOGIN", function(event)
	if C_AddOns.IsAddOnLoaded("Dominos") then return end
	if C_AddOns.IsAddOnLoaded("Bartender4") then return end
	if C_AddOns.IsAddOnLoaded("ElvUI") then	return end
	if C_AddOns.IsAddOnLoaded("BigFoot") then return end
	if C_AddOns.IsAddOnLoaded("NDui") then return end
	if AddUIDB.mmb ==  false  then return end
	-- Hook existing frames.主要这里是怎么hook住的没看懂,我自己hook不了
	local ActionBarActionButtonMixin_OnLoad = ActionBarActionButtonMixin.OnLoad
	local frame = EnumerateFrames()
	while frame do
		if frame.OnLoad == ActionBarActionButtonMixin_OnLoad then
			ActionBarActionButtonMixinHook_OnLoad(frame)
		end

		frame = EnumerateFrames(frame)
	end
end)
