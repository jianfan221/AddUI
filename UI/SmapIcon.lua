local _,ns = ...
ns.event("PLAYER_ENTERING_WORLD", function()
	if not AddUIDB.smap then return end
	if not AddUIDB.smapicon  then return end
	if not Minimap then return end

	--不想控制LibDBIcon10框架
	local notbuttons = {

	}
	local needbuttons = {
		["MythicPlusCountMinimapButton"] = true,--MythicPlusCount
	}

	local index = 1
	local maxindex = 6--最大显示数量，超过则换行
	local offset = 32--间隔
	local MinimapButtons = {}
	C_Timer.After(2, function()
		for i, child in ipairs({Minimap:GetChildren()}) do
			local name = child:GetName()
			if name and ((string.match(name,"LibDBIcon10") and not notbuttons[name]) or needbuttons[name]) and child:IsShown() then
				table.insert(MinimapButtons, child)
				child:SetAlpha(0)--先隐藏
				-- 禁止拖动：尝试取消注册拖拽并移除拖拽脚本（用 pcall 避免受保护/报错）
				if child.RegisterForDrag then
					pcall(function() child:RegisterForDrag() end) -- 无参数尝试清除注册
				end
				if child.SetScript then
					pcall(function()
						child:SetScript("OnDragStart", nil)
						child:SetScript("OnDragStop", nil)
						if child.SetMovable then child:SetMovable(false) end
					end)
				end
				if index < maxindex then	--左下往上
					child:ClearAllPoints()
					child:SetPoint("CENTER", Minimap, "BOTTOMLEFT", 0, offset*index)
					index = index + 1
				elseif index< maxindex + 3 then --左下开始往右只留3个
					child:ClearAllPoints()
					child:SetPoint("CENTER", Minimap, "BOTTOMLEFT", offset * (index - maxindex), 0)
					index = index + 1
				elseif index < maxindex * 2 + 2 then--左上往右因为左下是3个但是第一个要占位,所以这里是maxindex*2+2
					child:ClearAllPoints()
					child:SetPoint("CENTER", Minimap, "TOPLEFT", offset * (index - maxindex - 2), 0) --应该-3,但是需要空出邮箱
					index = index + 1
				else	--剩下的全部右上往下跟上面一样的逻辑
					child:ClearAllPoints()
					child:SetPoint("CENTER", Minimap, "TOPRIGHT", 0, -offset* (index-maxindex * 2 -2) )--最后也要*2-2
					index = index + 1

				end
			end
		end
	end)
	C_Timer.After(3, function()--每个图标都要加上鼠标进入和离开事件，不能放在上面那个循环里，因为有些图标可能还没有加载出来，所以等2秒后再添加事件
		for _, button in ipairs(MinimapButtons) do
			button:HookScript('OnEnter', function(self)
				for _, button in ipairs(MinimapButtons) do
					UIFrameFadeIn(button, 0.3, button:GetAlpha(), 1) --鼠标进入小地图出现小地图按钮
				end
			end)
			button:HookScript('OnLeave', function(self)
				for _, button in ipairs(MinimapButtons) do
					UIFrameFadeOut(button, 2, button:GetAlpha(), 0) --鼠标离开小地图渐隐
				end
			end)
		end
	end)
	Minimap:HookScript('OnEnter', function(self)
		for _, button in ipairs(MinimapButtons) do
			UIFrameFadeIn(button, 0.3, button:GetAlpha(), 1) --鼠标进入小地图出现小地图按钮
		end
	end)
	Minimap:HookScript('OnLeave', function(self)
		for _, button in ipairs(MinimapButtons) do
			UIFrameFadeOut(button, 2, button:GetAlpha(), 0) --鼠标离开小地图渐隐
		end
	end)
	

end)