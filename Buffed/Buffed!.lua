--http://wowuidev.pastey.net/113773
local floor, select, UnitAura, UnitName, GetTime, next, pairs = floor, select, UnitAura, UnitName, GetTime, next, pairs

BuffedSettings = {FrameCreation = {TargetBuff = 8, Buff = 16, Debuff = 8, Wep = 2, TargetDebuff = 8, Master = 1, Filter = 20,}, duration = false, }
local texturelist = {"Interface\\AddOns\\Buffed!\\Flat","Interface\\AddOns\\Buffed!\\BantoBar"}

local FontColour = {r = 1, g = 1, b = 1, a = 1}
local scale = UIParent:GetScale()
local BuffedSorter = {}
local ConfigShown
local ActiveButton
BuffedProfiles = {}

local function BGetPoint(frame)
	local x = (floor((frame:GetLeft()+ frame:GetRight())/2*100))/100
	local y = (floor((frame:GetTop()+ frame:GetBottom())/2*100))/100
	return x, y
end

local function BSetPoint(frame, x, y, relativeTo, relativePoint)
	if not relativeTo then
		relativeTo = UIParent
	end
	if not relativePoint then
		relativePoint = "BOTTOMLEFT"
	end
	frame:ClearAllPoints()
	frame:SetPoint("CENTER", relativeTo, relativePoint, x, y)
end

local FrameColours = {TargetBuff = {r = 0, g = 0.4, b = 0},
							Buff = {r = 0, g = 1, b = 0},
							Debuff = {r = 1, g = 0, b = 0},
							Wep = {r = 1, g = 0, b = 1},
							TargetDebuff =	{r = 0.4, g = 0, b = 0},
							Master = {r = 1, g = 1, b = 1},
							Filter = {r = 0, g = 0, b = 1}, }

local LoadOrder = { "Buff", "Debuff","TargetBuff", "TargetDebuff", "Wep", "Master", "Filter", }

local function BuffedOnDragStart(self, index, button) -- start dragging config frames
	local BuffButton = _G[self..index]
	if (button == "LeftButton") then
		BuffButton:StartMoving()
		if (BuffButton.padding == 10) then
			BuffButton.pa:Show()
			BuffButton.pb:Show()
		end
	elseif (button == "RightButton") then
		ActiveButton = BuffButton
		ToggleDropDownMenu(1, nil, _G["BuffedBuffConfig"], BuffButton, 30, 20)
	end
end

local function ForAllFrames(func1, func2)
	for FrameName, FrameNum in pairs(BuffedSettings.FrameCreation) do
		for i = 1, FrameNum do
			local f = _G["Buffed"..FrameName..i]
			if f then
				func1(f, FrameName, FrameNum, i)
			end
		end
	end
end

local function ToggleLock(msg) -- show/hide config frames and hide the extra frames if the number has changed
	if not ConfigShown then
		ForAllFrames(function(f) if f.enabled then f:Show() end end)
		ConfigShown = 1
	else
	ForAllFrames(function(f, FrameName, FrameNum, i)
										local f = _G["Buffed"..FrameName..i]
										local x, y = BGetPoint(f)
										local width, height = floor(f:GetWidth() + 0.5), floor(f:GetHeight() + 0.5)
										if not BuffedProfiles[UnitName("player")].nocombat["Buffed"..FrameName..i] then
											BuffedProfiles[UnitName("player")].nocombat["Buffed"..FrameName..i] = {bar = {}, durationb = {}}
										end
										local t = BuffedProfiles[UnitName("player")].nocombat["Buffed"..FrameName..i]
										t.width = width	t.height = height t.x = x t.y = y t.alpha = f.alpha	 x, y = BGetPoint(f.bar)
										 local r, g, b, a = f.bar.tex:GetVertexColor()
										 width, height = floor(f.bar:GetWidth() + 0.5), floor(f.bar:GetHeight() + 0.5)
										t.bar.shown = f.bar:IsShown()
										t.bar.horiz = f.bar.horiz
										t.bar.width = width
										t.bar.height = height
										t.bar.x = x t.bar.y = y	t.bar.r = r	t.bar.g = g	t.bar.b = b	t.bar.a = a
										t.bar.texture = f.bar.tex:GetTexture()
										 x, y = BGetPoint(f.durationb)
										 width, height = floor(f.durationb:GetWidth() + 0.5), floor(f.durationb:GetHeight() + 0.5)
										t.durationb.shown = f.durationb:IsShown()
										t.durationb.width = width t.durationb.height = height
										t.durationb.x = x t.durationb.y = y
										if FrameName == "Filter" then
											t.enabled = f.enabled
											t.Btype = f.Btype
											t.name = f.name
										end
								end)
		ForAllFrames(function(f, FrameName, FrameNum, i) f:Hide()
							if (i > FrameNum) then
								f = _G["Buffed"..FrameName.."Button"..i]
								if f then
									f:Hide()
								end
							end
						end)
		if _G["SwishAlphaSlider"] then
			_G["SwishAlphaSlider"]:Hide()
		end
		ConfigShown = nil
	end
end

local function BuffedOnDragStop(self, index, button) -- stop dragging config frames and set positions
 if (button == "LeftButton") then
	local BuffButton = _G[self..index]
	BuffButton:StopMovingOrSizing()
	local left, right, top, bottom = BuffButton:GetLeft(),  BuffButton:GetRight(),  BuffButton:GetTop(),  BuffButton:GetBottom()
	local width, height = BuffButton:GetWidth(), BuffButton:GetHeight()
		for FrameName, FrameNum in pairs(BuffedSettings.FrameCreation) do
			for i = 1, FrameNum do
				local frame = _G["Buffed"..FrameName..i]
				if not (frame:GetName() == BuffButton:GetName()) then
					local BLeft, BRight, BTop, BBottom = frame:GetLeft(),  frame:GetRight(),  frame:GetTop(),  frame:GetBottom()
					local BWidth, BHeight = frame:GetWidth(), frame:GetHeight()
					local BBCenterX = (right+left)/2
					local BBCenterY = (top+bottom)/2
					local FCenterX = (BRight+BLeft)/2
					local FCenterY = (BTop+BBottom)/2
					if (BBCenterX < (FCenterX + 100)) and (BBCenterX > (FCenterX - 100)) and (BBCenterY < (FCenterY + 100)) and (BBCenterY > (FCenterY - 100)) then
						if BuffButton.StickySize then
							BuffButton:SetWidth(BWidth)
							BuffButton:SetHeight(BHeight)
						end
						if BuffButton.StickyPos then
							if (BBCenterX < (FCenterX + 20)) and (BBCenterX > (FCenterX - 20)) then
								BuffButton:ClearAllPoints()
								BuffButton:SetPoint("CENTER", UIParent, "BOTTOMLEFT", FCenterX, BBCenterY )
							end
							if (BBCenterY < (FCenterY + 20)) and (BBCenterY > (FCenterY - 20)) then
								BuffButton:ClearAllPoints()
								BuffButton:SetPoint("CENTER", UIParent, "BOTTOMLEFT", BBCenterX, FCenterY )
							end
						end
					end
					if (BuffButton.padding ~= 0) then
						if ((left > (BLeft - BuffButton.padding) and left < (BRight + BuffButton.padding)) or (right > (BLeft - BuffButton.padding) and right < (BRight + BuffButton.padding) )) and ((top > (BBottom - BuffButton.padding) and top < (BTop + BuffButton.padding)) or (bottom > (BBottom - BuffButton.padding) and bottom < (BTop + BuffButton.padding)) ) then
							local Xdir = (BBCenterX - FCenterX)/abs(BBCenterX - FCenterX)
							local Ydir = (BBCenterY - FCenterY)/abs(BBCenterY - FCenterY)
							local x = FCenterX + Xdir*((BRight-BLeft)/2 + (right-left)/2 + BuffButton.padding)
							local y = FCenterY + Ydir*((BTop-BBottom)/2 + (top-bottom)/2 + BuffButton.padding)
							if abs(BBCenterX - FCenterX) < 10 then
								x = FCenterX
							elseif abs(BBCenterY - FCenterY) < 10 then
								y = FCenterY
							end
							BuffButton:ClearAllPoints()
									BuffButton:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y )
						end
					end
				end
			end
		end
	end
end


local function CreateConfigFrames() -- first creation of config frames
local count = 40
	for j = 1, #LoadOrder do
	local FrameName = LoadOrder[j]
	local FrameNum = BuffedSettings.FrameCreation[LoadOrder[j]]
	--print(LoadOrder[j])
		for i = 1, FrameNum do
		count = count + 1
			if not _G["Buffed"..FrameName..i] then
				local f = CreateFrame("Button", "Buffed"..FrameName..i, UIParent)
				f:SetWidth(20)
				f:SetHeight(20)
				f:SetMovable(true)
				f.corner = CreateFrame("Button", "Buffed"..FrameName.."Corner"..i, f)
				f.corner:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT")
				f.corner:SetPoint("TOPLEFT", f, "CENTER", 5, -5)
				f.corner:SetMovable(true)
				f.cornerT = f.corner:CreateTexture()
				f.cornerT:SetTexture("Interface\\AddOns\\Buffed!\\ResizerButton")
				f.cornerT:SetAllPoints(f.corner)
				f.corner:Hide()
				f.StickyPos = 1
				f.StickySize = 1
				f.padding = 10
				f.resizing = nil
				f.verbose = true
				f.alpha = false
				f.enabled = true
				f:SetResizable(true)
				f:SetFrameStrata("HIGH")
				f:SetMaxResize(80,80)
				f:SetMinResize(15,15)
				f.corner:SetResizable(true)
				f.duration = f:CreateFontString(f:GetName().."Duration", "OVERLAY", "GameFontNormal")
				f.duration:SetText("0:00")
				f.duration:SetVertexColor(FontColour.r, FontColour.g, FontColour.b, FontColour.a)
				f.durationb = CreateFrame("Frame", f)
				f.durationb:SetParent(f)
				f.durationb:SetWidth(30)
				f.durationb:SetHeight(10)
				f.durationb:SetPoint("LEFT", f, "RIGHT", 104, 0)
				f.durationb:EnableMouse(true)
				f.durationb:SetMovable(true)
				f.duration:ClearAllPoints()
				f.duration:SetAllPoints(f.durationb)
				f.durationb:SetScript("OnMouseDown", function(self)  self:StartMoving() end)
				f.durationb:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() local x, y = BGetPoint(self) local Bx, By = BGetPoint(f) BSetPoint(self, x-Bx, y-By, f, "CENTER")  end)
				f:EnableMouseWheel(true)
				f:SetScript("OnMouseWheel", function(self, value) local x, y = BGetPoint(f) if IsShiftKeyDown() then BSetPoint(f, x + value, y) else BSetPoint(f, x, y + value) end end)
				f.corner:EnableMouse(true)
				f.pa = f:CreateTexture()
				f.pa:SetTexture("Interface\\AddOns\\Buffed!\\ConfTexture")
				f.pa:SetPoint("TOPLEFT", f, "TOPLEFT", -f.padding, f.padding)
				f.pa:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", f.padding, -f.padding)
				f.pa:SetVertexColor(1,1,1)
				f.pa:SetTexCoord(1,0,0,1);
				f.pa:SetAlpha(0.3)
				f.pa:Hide()
				f.pb = f:CreateTexture()
				f.pb:SetTexture("Interface\\AddOns\\Buffed!\\ConfTexture")
				f.pb:SetPoint("TOPLEFT", f, "TOPLEFT", -f.padding, f.padding)
				f.pb:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", f.padding, -f.padding)
				f.pb:SetVertexColor(1,1,1)
				f.pb:SetAlpha(0.3)
				f.pb:Hide()
				f:SetScript("OnMouseDown", function(self, button)  BuffedOnDragStart("Buffed"..FrameName, i, button); end)
				f:SetScript("OnMouseUp", function(self, button)  f.pa:Hide(); f.pb:Hide(); BuffedOnDragStop("Buffed"..FrameName, i, button) end)
				f.corner:SetScript("OnMouseDown", function()  f:StartSizing(); f.resizing = true; end)
				f.corner:SetScript("OnUpdate", function() if f.resizing then f:SetWidth(math.max(f:GetWidth(), f:GetHeight())); f:SetHeight(math.max(f:GetWidth(), f:GetHeight())) end end)
				f.corner:SetScript("OnMouseUp", function() --if its the master frame, set all other frames the same size
												f.resizing = nil
												f:StopMovingOrSizing()
												BuffedUpdate("force")
													if (FrameName == "Master" ) then
														for FrameName, FrameNum in pairs(BuffedSettings.FrameCreation) do
															for i = 1, FrameNum do
																local fr = _G["Buffed"..FrameName..i]
																fr:SetWidth(f:GetWidth())
																fr:SetHeight(f:GetHeight())
															end
														end
													end
												end)
				f.fs = f:CreateFontString( FrameName.."FS"..i, "OVERLAY", "GameFontNormal")
				f.bar = CreateFrame("Frame", nil, f)
				f.bar:SetWidth(100)
				f.bar:SetHeight(20)
				f.bar:SetPoint("LEFT", f, "RIGHT", 3, 0)
				f.bar.tex = f.bar:CreateTexture(nil, "OVERLAY")
				f.bar.tex:SetAllPoints(f.bar)
				f.bar.tex:SetTexture("Interface\\AddOns\\Buffed!\\Flat")
				f.bar.tex:SetVertexColor(FrameColours[FrameName].r,FrameColours[FrameName].g,FrameColours[FrameName].b, 0.6)
				f.bar:EnableMouse(true)
				f.bar:SetMovable(true)
				f.bar:SetResizable(true)
				f.bar:SetScript("OnMouseDown", function(self, button) if (button == "LeftButton") then self:StartMoving() elseif IsShiftKeyDown() then self:StartSizing("RIGHT") else self:StartSizing("BOTTOM") end end)
				f.bar:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() local x, y = BGetPoint(self) local Bx, By = BGetPoint(f) BSetPoint(self, x-Bx, y-By, f, "CENTER")  end)
				f.bar.horiz = true
				f.fs:SetText(i)
					if (FrameName == "Master" )then -- make the master frame larger, change its label
						f.fs:SetWidth(20)
						f.fs:SetText("M")
						f.durationb:SetScript("OnMouseUp", function(self)
															self:StopMovingOrSizing()
															local x, y = BGetPoint(self)
															local Bx, By = BGetPoint(f)
																for FrameName, FrameNum in pairs(BuffedSettings.FrameCreation) do
																	for i = 1, FrameNum do
																		local frame = _G["Buffed"..FrameName..i]
																		BSetPoint(frame.durationb, x-Bx, y-By, frame, "CENTER")
																	end
																end
														end)
						f.bar:SetScript("OnMouseUp", function(self, button)
															self:StopMovingOrSizing()
															local x, y = BGetPoint(self)
															local Bx, By = BGetPoint(f)
																for FrameName, FrameNum in pairs(BuffedSettings.FrameCreation) do
																	for i = 1, FrameNum do
																		local frame = _G["Buffed"..FrameName..i]
																		BSetPoint(frame.bar, x-Bx, y-By, frame, "CENTER")
																		frame.bar:SetHeight(self:GetHeight())
																		frame.bar:SetWidth(self:GetWidth())
																	end
																end
														end)
					end
				f.fs:SetPoint("CENTER")
				local x = cos((360/25)*count)*4*count
				local y = sin((360/25)*count)*4*count
				if i ~= 1 then
					f:SetPoint("TOP", _G["Buffed"..FrameName..i-1], "BOTTOM", 0, -2)
				elseif FrameName == "Buff" then
					f:SetPoint("CENTER", UIParent, "TOPRIGHT", -330, -20)
				elseif FrameName == "Debuff" then
					f:SetPoint("CENTER", UIParent, "TOPRIGHT", -490, -20)
				else
					f:SetPoint("CENTER", UIParent, "CENTER", x , y)
				end
				
				f.t = f:CreateTexture()
				f.t:SetTexture("Interface\\AddOns\\Buffed!\\ConfTexture")
				f.t:SetAllPoints(f)
				f.t:SetVertexColor(FrameColours[FrameName].r,FrameColours[FrameName].g,FrameColours[FrameName].b)
				f.ti = f:CreateTexture()
				f.ti:SetTexture("Interface\\AddOns\\Buffed!\\ConfTexture")
				f.ti:SetAllPoints(f)
				f.ti:SetVertexColor(0,0,0)
				f.ti:SetTexCoord(1,0,0,1);
				if (FrameName == "Filter" )then
					f.enabled = false
					f.fs:SetPoint("BOTTOM", f, "TOP", 10, 0)
					f.fs:SetWidth(80)
				end
				f:Hide()
			end
		end
	end
end

local function CreateSettingsMenu()
	local ConFrame = CreateFrame("Frame")
	local ConfigLayout = {
	BuffSlider = { Ftype = "Slider", Inherits = "OptionsSliderTemplate",
		FName = "BuffedBuffSlider", Location = "CENTER", Xoff = 0,Yoff = 150, Parent = ConFrame,
		Min = 0, Max = 32, Step = 1, StartVal = BuffedSettings.FrameCreation.Buff,LowText = 0, HighText = 32,
		Script1 = {event = "OnValueChanged", func = function(self) BuffedSettings.FrameCreation.Buff = self:GetValue(); _G["BuffString"]:SetText(self:GetValue()) end,},
		Script2 = {event = "OnMouseUp", func = function()  CreateConfigFrames(); ToggleLock("config"); ToggleLock("config"); end,}
				},
	DebuffSlider = { Ftype = "Slider", Inherits = "OptionsSliderTemplate",
		FName = "BuffedDebuffSlider", Location = "CENTER", Xoff = 0, Yoff = 100, Parent = ConFrame,
		Min = 0, Max = 16, Step = 1, StartVal = BuffedSettings.FrameCreation.Debuff, LowText = 1, HighText = 16,
		Script1 = {event = "OnValueChanged", func = function(self) BuffedSettings.FrameCreation.Debuff = self:GetValue(); _G["DebuffString"]:SetText(self:GetValue()) end,},
		Script2 = {event = "OnMouseUp", func = function() CreateConfigFrames(); ToggleLock("config"); ToggleLock("config"); end,}
				},
	TargetBuffSlider = { Ftype = "Slider", Inherits = "OptionsSliderTemplate",
		FName = "BuffedTargetBuffSlider", Location = "CENTER", Xoff = 0, Yoff = 50, Parent = ConFrame,
		Min = 0, Max = 16, Step = 1, StartVal = BuffedSettings.FrameCreation.TargetBuff, LowText = 1, HighText = 16,
		Script1 = {event = "OnValueChanged", func = function(self) BuffedSettings.FrameCreation.TargetBuff = self:GetValue(); _G["TargBuffString"]:SetText(self:GetValue())end,},
		Script2 = {event = "OnMouseUp", func = function() CreateConfigFrames(); ToggleLock("config"); ToggleLock("config"); end,}
				},
	TargetDebuffSlider = { Ftype = "Slider", Inherits = "OptionsSliderTemplate",
		FName = "BuffedTargetDebuffSlider", Location = "CENTER", Xoff = 0, Yoff = 0, Parent = ConFrame,
		Min = 0, Max = 16, Step = 1, StartVal = BuffedSettings.FrameCreation.TargetDebuff, LowText = 1, HighText = 16,
		Script1 = {event = "OnValueChanged", func = function(self) BuffedSettings.FrameCreation.TargetDebuff = self:GetValue(); _G["TargDebuffString"]:SetText(self:GetValue())end,},
		Script2 = {event = "OnMouseUp", func = function() CreateConfigFrames(); ToggleLock("config"); ToggleLock("config"); end,}
				},
	BuffString = { Ftype = "FontString", Location = "CENTER", Xoff = 110, Yoff = 150, Parent = ConFrame["BuffSlider"],
					R = 1, G = 1, B = 1, Width = 60, Height = 15,
				},
	DebuffString = { Ftype = "FontString", Location = "CENTER", Xoff = 110, Yoff = 100, Parent = ConFrame,
					R = 1, G = 1, B = 1, Width = 60, Height = 15,
				},
	TargBuffString = { Ftype = "FontString", Location = "CENTER", Xoff = 110, Yoff = 50, Parent = ConFrame,
					R = 1, G = 1, B = 1, Width = 60, Height = 15,
				},
	TargDebuffString = { Ftype = "FontString", Location = "CENTER", Xoff = 110, Yoff = 0, Parent = ConFrame,
					R = 1, G = 1, B = 1, Width = 60, Height = 15,
				},
	TitleString = { Ftype = "FontString", Location = "CENTER", Xoff = 0, Yoff = 200, Parent = ConFrame,
					R = 1, G = 1, B = 1, Width = 150, Height = 15, StringVal = "Buffed! Options",
				},
	BuffLabel = { Ftype = "FontString", Location = "CENTER", Xoff = -120, Yoff = 150, Parent = ConFrame,
					R = 1, G = 1, B = 1, Width = 150, Height = 15, StringVal = "Buff Count:",
				},
	DebuffLabel = { Ftype = "FontString", Location = "CENTER", Xoff = -120, Yoff = 100, Parent = ConFrame,
					R = 1, G = 1, B = 1, Width = 150, Height = 15, StringVal = "Debuff Count:",
				},
	TargetBuffLabel = { Ftype = "FontString", Location = "CENTER", Xoff = -120, Yoff = 50, Parent = ConFrame,
					R = 1, G = 1, B = 1, Width = 150, Height = 15, StringVal = "Target buff:",
				},
	TargetDebuffLabel = { Ftype = "FontString", Location = "CENTER", Xoff = -120, Yoff = 0, Parent = ConFrame,
					R = 1, G = 1, B = 1, Width = 150, Height = 15, StringVal = "Target debuff:",
				},
	WepEnchLabel = { Ftype = "FontString", Location = "CENTER", Xoff = -120, Yoff = -50, Parent = ConFrame,
					R = 1, G = 1, B = 1, Width = 200, Height = 15, StringVal = "Show Weapon Enchants:",
				},
	WepEnchToggle = { Ftype = "CheckButton", Inherits = "InterfaceOptionsCheckButtonTemplate",
				FName = "BuffedTargetDebuffSlider", Location = "CENTER", Xoff = 0, Yoff = -50, Parent = ConFrame,
				Script1 = {event = "OnMouseUp", func = function(self)  if TemporaryEnchantFrame:IsShown() then BuffedSettings.FrameCreation.Wep = 0; TemporaryEnchantFrame:Hide()	else BuffedSettings.FrameCreation.Wep = 2; TemporaryEnchantFrame:Show() BuffedUpdate("force") end;
						ToggleLock("config"); ToggleLock("config");
					end, variable = TemporaryEnchantFrame:IsShown()},
				},
		}

local Text = {}
	for Name, values in pairs(ConfigLayout) do
		if ( values.Ftype == "Frame" ) or ( values.Ftype == "Slider" ) or  ( values.Ftype == "CheckButton" ) then
			ConFrame[Name] = CreateFrame(values.Ftype, values.FName, values.Parent, values.Inherits)
			if ( values.Ftype == "Slider" ) then
				ConFrame[Name]:SetMinMaxValues(values.Min,values.Max)
				ConFrame[Name]:SetValueStep(values.Step)
				ConFrame[Name]:SetValue(values.StartVal)
				_G[values.FName.."Low"]:SetText(values.LowText)
				_G[values.FName.."High"]:SetText(values.HighText)
			end
			if (values.Ftype == "CheckButton") then
				if values.variable then
					ConFrame[Name]:SetChecked(true)
				else
					ConFrame[Name]:SetChecked(false)
				end
			end
			if values["Script1"] then
					ConFrame[Name]:SetScript(values["Script1"].event, values["Script1"].func)
			end
				ConFrame[Name]:SetScript(values["Script1"].event, values["Script1"].func)
			if values["Script2"] then
				ConFrame[Name]:SetScript(values["Script2"].event, values["Script2"].func)
			end

		end
		if ( values.Ftype == "FontString" ) then
			ConFrame[Name] = ConFrame:CreateFontString(Name, "OVERLAY", "GameFontNormal")
			ConFrame[Name]:SetWidth(values.Width)
			ConFrame[Name]:SetHeight(values.Height)
			ConFrame[Name]:SetTextColor(values.R,values.G,values.B)
			if values.StringVal then
				ConFrame[Name]:SetText(values.StringVal)
			end
		end
	ConFrame[Name]:SetPoint(values.Location,values.Xoff,values.Yoff)
	end

ConFrame.name = "Buffed!"
InterfaceOptions_AddCategory(ConFrame)

end

local function SetConfigVars(pos, f)
	if not pos then return end
	BSetPoint(f, pos.x, pos.y)
	f:SetWidth(pos.width)
	f:SetHeight(pos.height)
	f.alpha = pos.alpha
	if pos.bar and pos.bar.shown then f.bar:Show() else f.bar:Hide() end
	f.bar.horiz = pos.bar.horiz
	f.bar:SetWidth(pos.bar.width)
	f.bar:SetHeight(pos.bar.height)
	f.bar.tex:SetTexture(pos.bar.texture)
	f.bar.tex:SetVertexColor(0,0,0)
	f.bar.tex:SetVertexColor(pos.bar.r, pos.bar.g, pos.bar.b, pos.bar.a)
	BSetPoint(f.bar, pos.bar.x-pos.x, pos.bar.y-pos.y, f, "CENTER")
	BSetPoint(f.durationb, pos.durationb.x-pos.x, pos.durationb.y-pos.y, f, "CENTER")
end

local function BuffedOnLoad(self, event, ...)
	if event == "ADDON_LOADED" then
		if select(1, ...) == "Buffed!" then
			CreateConfigFrames()
			CreateSettingsMenu()
		end
	elseif event == "PLAYER_ENTERING_WORLD" then
		for FrameName, FrameNum in pairs(BuffedSettings.FrameCreation) do
			for i = 1, 32 do
				local f = _G["Buffed"..FrameName..i]
				if f then
					if not BuffedProfiles[UnitName("player")] then
						BuffedProfiles[UnitName("player")] = {combat = {}, nocombat = {}, filterframes = {BuffedBuffButton = {}, BuffedDebuffButton = {}, TargetBuffedButton = {}, TargetDebuffedButton = {},},}
					end
					if BuffedProfiles[UnitName("player")].nocombat["Buffed"..FrameName..i] then
						local pos = BuffedProfiles[UnitName("player")].nocombat["Buffed"..FrameName..i]
						SetConfigVars(pos, f)
						if FrameName == "Filter" then
							f.enabled = pos.enabled
							f.Btype = pos.Btype
							f.name = pos.name
							f.fs:SetText(pos.name)
						end
					end
				end
			end
		end
		BuffedUpdate("force")
		if (BuffedSettings.FrameCreation.Wep == 0) then
			TemporaryEnchantFrame:Hide()
		end
	end
end

local moop = CreateFrame("Frame")
moop:RegisterEvent("ADDON_LOADED")
moop:RegisterEvent("PLAYER_ENTERING_WORLD")
moop:SetScript("OnEvent", BuffedOnLoad)

local DropDownTest = CreateFrame("Frame", "BuffedBuffConfig", UIParent, "UIDropDownMenuTemplate")
DropDownTest:SetPoint("CENTER")
UIDropDownMenu_SetWidth(DropDownTest, 65)
UIDropDownMenu_SetButtonWidth(DropDownTest, 20)
DropDownTest:Hide()
local function DropDownTest_ItemClick()
	UIDropDownMenu_SetSelectedValue(this.owner, this.value);
end

local function AlphaSlider()
	local Slider = _G["SwishAlphaSlider"]
	if not Slider then
		 Slider = CreateFrame("Slider", "SwishAlphaSlider", UIParent, "OptionsSliderTemplate")
		
		Slider:SetMinMaxValues(0,1)
		Slider:SetValueStep(0.05)
		SwishAlphaSliderLow:SetText(0)
		SwishAlphaSliderHigh:SetText(1)
		Slider:SetScript("OnValueChanged", function(self) 
												ActiveButton.ti:SetAlpha(self:GetValue()); 
												ActiveButton.alpha = self:GetValue(); 
													if (ActiveButton:GetName() == "BuffedMaster1") then 
														for FrameName, FrameNum in pairs(BuffedSettings.FrameCreation) do
															for i = 1, FrameNum do 
																local f = _G["Buffed"..FrameName..i] 
																f.ti:SetAlpha(self:GetValue())
																f.alpha = self:GetValue()
															end
														end
													end
												end)
		Slider:SetScript("OnMouseUp", function(self) self:Hide(); BuffedUpdate("force") end)
		
	end
		Slider:SetWidth(ActiveButton:GetWidth() + 30)
		if ActiveButton.alpha then
			Slider:SetValue(ActiveButton.alpha)
		else
			Slider:SetValue(0.5)
		end
	Slider:ClearAllPoints()
	Slider:SetPoint("CENTER", ActiveButton, "TOP", 0, 10)
	Slider:Show()
end



local function DropDownTest_Initialize(self, level) -- the menu items, needs a cleanup
	level = level or 1
	local info = UIDropDownMenu_CreateInfo()
	local value = UIDROPDOWNMENU_MENU_VALUE
	if ActiveButton then
		if (level == 1) then
			info.text = "Sticky Positioning"
			info.value = 1
			info.checked = ActiveButton.StickyPos
			info.tooltipTitle = "Sticky Positioning"
			info.tooltipText = "Aligns the buffs with other nearby buffs"
			if (ActiveButton:GetName() == "BuffedMaster1") then
				info.func = function() if ActiveButton.StickyPos then
					 ForAllFrames(function(f)f.StickyPos = nil end)
				else
					 ForAllFrames(function(f)f.StickyPos = nil end)
				end end
			else
				info.func = function() if ActiveButton.StickyPos then ActiveButton.StickyPos = nil else ActiveButton.StickyPos = 1 end end
			end
			UIDropDownMenu_AddButton(info, level)

			info.text = "Sticky Sizing"
			info.value = 2
			info.checked = ActiveButton.StickySize
			info.tooltipTitle = "Sticky Sizing"
			info.tooltipText = "Sets the size of the buff to other nearby buffs"
			if (ActiveButton:GetName() == "BuffedMaster1") then
				info.func = function() if ActiveButton.StickySize then
					 ForAllFrames(function(f)f.StickySize = nil end)
				else
					ForAllFrames(function(f)f.StickySize = 1 end)
				end end
			else
				info.func = function() if ActiveButton.StickySize then ActiveButton.StickySize = nil else ActiveButton.StickySize = 1 end end
			end
			UIDropDownMenu_AddButton(info, level)

			info.text = "Sticky Padding"
			info.value = 3
			info.checked = function() if (ActiveButton.padding == 10) then return true else return false end end
			info.tooltipTitle = "Sticky Padding"
			info.tooltipText = "Attempts to even out the padding between nearby buffs"
			if (ActiveButton:GetName() == "BuffedMaster1") then
				info.func = function()
					if (ActiveButton.padding == 10) then
						ForAllFrames(function(f)f.padding = 0 end)
					else
						ForAllFrames(function(f)f.padding = 10 end)
					end
				end
			else
				info.func = function() if (ActiveButton.padding == 10) then ActiveButton.padding = 0 else ActiveButton.padding = 10 end end
			end
			UIDropDownMenu_AddButton(info, level)

			info.text = "Alpha"
			info.value = "Alpha"
			info.checked = nil
			info.tooltipTitle = "Alpha"
			info.tooltipText = "Set the Alpha for this frame"
			info.func = function() AlphaSlider() end
			UIDropDownMenu_AddButton(info, level)
			
			info.hasOpacity = nil
			info.hasArrow = false
			info.text = "Show Dummy Timers"
			info.value = 3
			info.checked =  ActiveButton.duration:IsShown()
			info.tooltipTitle = "Show Dummy Timer"
			info.tooltipText = "Show a fake timer to help with positioning."
			if (ActiveButton:GetName() == "BuffedMaster1") then
				info.func = function()
					if ActiveButton.duration:IsShown() then
						ForAllFrames(function(f) f.duration:Hide() end)
					else
						ForAllFrames(function(f) f.duration:Show() end)
					end
				end
			else
				info.func = function() if ActiveButton.duration:IsShown() then ActiveButton.duration:Hide() else ActiveButton.duration:Show()	end	end
			end
			UIDropDownMenu_AddButton(info, level)

			info.text = "Resizable"
			info.value = 4
			info.checked = ActiveButton.corner:IsShown()
			info.tooltipTitle = "Resizable"
			info.tooltipText = "Shows a draggable icon to allow buff resizing"
			if (ActiveButton:GetName() == "BuffedMaster1") then
				info.func = function()
					if ActiveButton.corner:IsShown() then
						ForAllFrames(function(f) f.corner:Hide() end)
					else
						ForAllFrames(function(f) f.corner:Show() end)
					end
				end
			else
				info.func = function() if ActiveButton.corner:IsShown() then ActiveButton.corner:Hide() else ActiveButton.corner:Show()  end end
			end
			UIDropDownMenu_AddButton(info, level)

			info.text = "Reset Size"
			info.value = 5
			info.checked = nil
			info.tooltipTitle = "Reset Size"
			info.tooltipText = "Resets the size of the buff to default values"
			if (ActiveButton:GetName() == "BuffedMaster1") then
				info.func = function() ForAllFrames(function(f) f:SetWidth(30) f:SetHeight(30) end) end
			else
				info.func = function() ActiveButton:SetWidth(30) ActiveButton:SetHeight(30)  end
			end
			UIDropDownMenu_AddButton(info, level)

			info.text = "Buff Bars"
			info.value = "Bars"
			info.checked = ActiveButton.bar:IsShown()
			info.tooltipTitle = "Buff Bars"
			info.tooltipText = "Show timer bars alongside the buff icon."
			info.func = function() if ActiveButton.bar:IsShown() then ActiveButton.bar:Hide() else ActiveButton.bar:Show() end end
			if (ActiveButton:GetName() == "BuffedMaster1") then
				info.func = function()
					if ActiveButton.bar:IsShown() then
						ForAllFrames(function(f) f.bar:Hide() end)
					else
						ForAllFrames(function(f) f.bar:Show() end)
					end
				end
			else
				info.func = function() if ActiveButton.bar:IsShown() then ActiveButton.bar:Hide() else ActiveButton.bar:Show()  end end
			end
			info.hasArrow = true
			UIDropDownMenu_AddButton(info, level)

			for i = 1, 16 do
				if (ActiveButton:GetName() == "BuffedFilter"..i) then
					info.text = "Delete Filter"
					info.value = 3
					info.checked =  nil
					info.tooltipTitle = "Delete Filter"
					info.tooltipText = "Deletes the filter, sending the buff back to the default stack"
					info.hasArrow = false
					info.func = function()
							ActiveButton.enabled = false
							BuffedProfiles[UnitName()].filterframes[ActiveButton.Btype][ActiveButton.name] = nil
							print(ActiveButton.name.." filter deleted")
							ActiveButton.name = nil
							ActiveButton.Btype = nil
							ToggleLock()
							ToggleLock()
							BuffedUpdate("force")
					end
					UIDropDownMenu_AddButton(info, level)
				end
			end
			if (ActiveButton:GetName() == "BuffedMaster1") then

				info.text = "Sort By Duration"
				info.value = 3
				info.checked = BuffedSettings.duration
				info.tooltipTitle = "Sort By Duration"
				info.tooltipText = "Sort the buffs by time remaining"
				info.hasArrow = false
				info.func = function()  if BuffedSettings.duration then BuffedSettings.duration = false; BuffedUpdate("force"); else BuffedSettings.duration = true BuffedUpdate("force") end 	end
				UIDropDownMenu_AddButton(info, level)

				info.text = "Filter Target Buffs"
				info.value = 3
				info.checked =  BuffedSettings.BuffIsMine
				info.tooltipTitle = "Filter Target Buffs"
				info.tooltipText = "Only show the target buffs that are yours."
				info.hasArrow = false
				info.func = function()
								if BuffedSettings.BuffIsMine then
									BuffedSettings.BuffIsMine = false
								else
									BuffedSettings.BuffIsMine = true
								end
								BuffedUpdate("force")
							end
				UIDropDownMenu_AddButton(info, level)

				info.text = "Filter Target Debuffs"
				info.value = 3
				info.checked =  BuffedSettings.DebuffIsMine
				info.tooltipTitle = "Filter Target Debuffs"
				info.tooltipText = "Only show the target debuffs that are yours."
				info.func = function()
								if BuffedSettings.DebuffIsMine then
									BuffedSettings.DebuffIsMine = false
								else
									BuffedSettings.DebuffIsMine = true
								end
								BuffedUpdate("force")
							end
				UIDropDownMenu_AddButton(info, level)

				info.text = "Save Combat Positions"
				info.value = 3
				info.checked =  nil
				info.tooltipTitle = "Save Combat Positions"
				info.tooltipText = "Save the current buff position as the location for buffs in combat"
				info.func = function()
								ForAllFrames(function(f, FrameName, FrameNum, i)
										local f = _G["Buffed"..FrameName..i]
										local x, y = BGetPoint(f)
										local width, height = floor(f:GetWidth() + 0.5), floor(f:GetHeight() + 0.5)
										if not BuffedProfiles[UnitName("player")].combat["Buffed"..FrameName..i] then
											BuffedProfiles[UnitName("player")].combat["Buffed"..FrameName..i] = {bar = {}, durationb = {}}
										end
										local t = BuffedProfiles[UnitName("player")].combat["Buffed"..FrameName..i]
										t.width = width	t.height = height t.x = x t.y = y t.alpha = f.alpha	 x, y = BGetPoint(f.bar)
										 local r, g, b, a = f.bar.tex:GetVertexColor()
										 width, height = floor(f.bar:GetWidth() + 0.5), floor(f.bar:GetHeight() + 0.5)
										t.bar.shown = f.bar:IsShown()	t.bar.horiz = f.bar.horiz
										t.bar.width = width	t.bar.height = height
										t.bar.x = x t.bar.y = y	t.bar.r = r	t.bar.g = g	t.bar.b = b	t.bar.a = a
										t.bar.texture = f.bar.tex:GetTexture()
										 x, y = BGetPoint(f.durationb)
										 width, height = floor(f.durationb:GetWidth() + 0.5), floor(f.durationb:GetHeight() + 0.5)
										t.durationb.shown = f.durationb:IsShown()
										t.durationb.width = width t.durationb.height = height
										t.durationb.x = x t.durationb.y = y
										if FrameName == "Filter" then
											t.enabled = f.enabled
											t.Btype = f.Btype
											t.name = f.name
										end
								end)
							end
				UIDropDownMenu_AddButton(info, level)

				info.text = "Load Profile"
				info.tooltipTitle = "Load Character Profile"
				info.tooltipText = "Load the settings from another Character"
				info.value = "Profiles"
				info.hasArrow = true
				UIDropDownMenu_AddButton(info, level)

				info.text = "Load Presets"
				info.tooltipTitle = "Load Preset"
				info.tooltipText = "Load Presetconfigurations"
				info.value = "Presets"
				info.hasArrow = true
				UIDropDownMenu_AddButton(info, level)

			end
		elseif level == 2 then
			if value == "Bars" then
				info.text = "Orientation"
				info.value = "Orientation"
				info.tooltipTitle = ""
				info.tooltipText = ""
				info.hasArrow = true
				UIDropDownMenu_AddButton(info, level)

				info.text = "Texture"
				info.value = "Texture"
				info.tooltipTitle = ""
				info.tooltipText = ""
				UIDropDownMenu_AddButton(info, level)

				info.text = "Colour"
				info.value = "Colour"
				info.tooltipTitle = "Colour"
				info.tooltipText = "Choose a Colour for the duration bar."
				info.hasArrow = false
				info.hasColorSwatch = 1
				info.hasOpacity = 1
				local r, g, b, a = ActiveButton.bar.tex:GetVertexColor()
				info.r = r
				info.g = g
				info.b = b
				info.opacity = 1-a
				info.swatchFunc = function() local R,G,B = ColorPickerFrame:GetColorRGB() ActiveButton.bar.tex:SetVertexColor(R,G,B) end
				info.opacityFunc = function() local A = OpacitySliderFrame:GetValue() local R,G,B = ColorPickerFrame:GetColorRGB() ActiveButton.bar.tex:SetVertexColor(R,G,B, 1-A) end
				UIDropDownMenu_AddButton(info, level)

			elseif value == "Profiles" then
				for name, tables in pairs(BuffedProfiles) do
					info.text = name
					info.func = function()
											for FrameName, FrameNum in pairs(BuffedSettings.FrameCreation) do
												for i = 1, 32 do
													local f = _G["Buffed"..FrameName..i]
													if f then
														if BuffedProfiles[name].nocombat["Buffed"..FrameName..i] then
															local pos = BuffedProfiles[name].nocombat["Buffed"..FrameName..i]
															SetConfigVars(pos, f)
															if FrameName == "Filter" then
																f.enabled = pos.enabled
																f.Btype = pos.Btype
																f.name = pos.name
																f.fs:SetText(pos.name)
															end
															BuffedProfiles[UnitName("player")] = BuffedProfiles[name]
														end
													end
												end
											end
						BuffedUpdate("force")
					end
					UIDropDownMenu_AddButton(info, level)
				end
			elseif value == "Presets" then
				info.text = "SBB/Elk"
				info.func = function() ForAllFrames(function(f, FrameName, FrameNum, i)
								if i ~= 1 then
								f:ClearAllPoints()
									f:SetPoint("TOP", _G["Buffed"..FrameName..i-1], "BOTTOM", 0, -2)
								end
								f:SetHeight(20)
								f:SetWidth(20)
								f.bar:SetHeight(20)
								f.bar:SetWidth(100)
								f.bar:ClearAllPoints()
								f.bar:SetPoint("LEFT", f, "RIGHT", 2, 0)
								f.durationb:ClearAllPoints()
								f.durationb:SetPoint("LEFT", f, "RIGHT", 104, 0)
								f.bar:Show()
							end)
							end
				UIDropDownMenu_AddButton(info, level)
				
				info.text = "Buffalo/Bison"
				info.func = function() ForAllFrames(function(f, FrameName, FrameNum, i)
								if i ~= 1 then
									f:ClearAllPoints()
									f:SetPoint("LEFT", _G["Buffed"..FrameName..i-1], "RIGHT", 5, 0)
								end
								f:SetHeight(30)
								f:SetWidth(30)
								f.bar:SetHeight(20)
								f.bar:SetWidth(100)
								f.bar:ClearAllPoints()
								f.bar:SetPoint("LEFT", f, "RIGHT", 2, 0)
								f.durationb:ClearAllPoints()
								f.durationb:SetPoint("TOP", f, "BOTTOM", 0, -5)
								f.bar:Hide()
							end)
							end
				UIDropDownMenu_AddButton(info, level)

			end
		elseif level == 3 then
			if  value == "Orientation" then
				info.text = "Horizontal"
				info.value = "Horizontal"
				info.tooltipTitle = ""
				info.tooltipText = ""
				info.checked = ActiveButton.bar.horiz
				if (ActiveButton:GetName() == "BuffedMaster1") then
					info.func = function() ForAllFrames(function(f) f.bar.horiz = true end) end
				else
					info.func = function() ActiveButton.bar.horiz = true end
				end
				UIDropDownMenu_AddButton(info, level)

				info.text = "Vertical"
				info.value = "Vertical"
				info.tooltipTitle = ""
				info.tooltipText = ""
				info.checked = not ActiveButton.bar.horiz
				if (ActiveButton:GetName() == "BuffedMaster1") then
					info.func = function() ForAllFrames(function(f) f.bar.horiz = false end) end
				else
					info.func = function() ActiveButton.bar.horiz = false end
				end
				UIDropDownMenu_AddButton(info, level)
			elseif value == "Texture" then
				for num, val in ipairs(texturelist) do
					local valshort = val:match("([^\\]+)$")
					info.text = valshort
					info.value = val
					info.tooltipTitle = val
					info.checked = ActiveButton.bar.tex:GetTexture() == val

				if (ActiveButton:GetName() == "BuffedMaster1") then
					info.func = function() ForAllFrames(function(f) f.bar.tex:SetTexture(val) end) end
				else
					info.func = function() ActiveButton.bar.tex:SetTexture(val) end
				end
					UIDropDownMenu_AddButton(info, level)
				end
			end
		end
	end
end
UIDropDownMenu_Initialize(DropDownTest, DropDownTest_Initialize, "MENU")

--------------------------------- anchor all buff frames ---------------------------------

local function BuffedBuffButtonAnchors(buttonName, index, IsMine, buffname, tag)
	local buff = _G[buttonName..index]
	local confbuff = _G[tag..index-HiddenCount]
	if BuffedSettings.BuffIsMine and not (IsMine == "player") then
		buff:Hide()
		HiddenCount = HiddenCount + 1
		return
	end
	if next(BuffedSorter) then
		for i = 1, #BuffedSorter do
			if (BuffedSorter[i].number == index) then
					confbuff = _G[tag..i-HiddenCount]
			end
		end
	end
	if BuffedProfiles[UnitName("player")].filterframes[buttonName][buffname] then
		confbuff = _G[BuffedProfiles[UnitName("player")].filterframes[buttonName][buffname]]
		HiddenCount = HiddenCount + 1
	end
	local duration = _G[confbuff:GetName().."Duration"]
	local bduration = _G[buttonName..index.."Duration"]
	bduration:SetAllPoints(duration)
	buff:ClearAllPoints()
	if confbuff.alpha then
		buff:SetAlpha(confbuff.alpha)
	end
	buff:SetAllPoints(confbuff)
	buff.parent = confbuff
end

local function OpenConfig()
	InterfaceOptionsFrame_OpenToCategory(ConFrame)
end

SLASH_Buffed1 = "/buffed";
SlashCmdList["Buffed"] = ToggleLock;

local function BuffedTimeFormat(self, timer) -- format the time
local hours = floor(timer/3600)
local minutes = floor((timer-hours*3600)/60)
local seconds = floor((timer-hours*3600 -minutes*60))
	if self.verbose then
	else
		if hours > 0 and minutes > 0 then
			if minutes >= 10 then
				return hours..":"..minutes
			else
				return hours..":0"..minutes
			end
		elseif minutes > 0 then
			if minutes > 10 then
				return minutes.."m"
			else
				if seconds >= 10 then
					return minutes..":"..seconds
				else
					return minutes..":0"..seconds
				end
			end
		else
			return seconds
		end
	end
end

local function BuffedButtonUpdateDuration(self, timeLeft)
	if timeLeft then
		self.duration:SetFormattedText(BuffedTimeFormat(self, timeLeft));
		self.duration:Show();
		if ( timeLeft < BUFF_DURATION_WARNING_TIME ) then
			self.duration:SetVertexColor(1, 1, 1)
		end
	else
		self.duration:Hide();
	end
end

local function BuffedButtonOnUpdate(self, elapsed, unit, index)
	if not self.divider then
		self.divider = 0
	end
	self.divider = self.divider + elapsed
	self.timeLeft = max(self.timeLeft - elapsed, 0);
	if self.divider > 0.1 then
		self.dbar:SetValue(self.timeLeft)
		if self.parent and self.parent.bar then
			if not self.parent.bar:IsShown() then
				self.dbar:Hide()
			end
		end
		BuffedButtonUpdateDuration(self, self.timeLeft);
		--self.timeLeft = max(self.timeLeft - elapsed, 0);
		if self.parent then
			if not self.alpha then -- just in case it isnt parented to the config frames
				self:SetAlpha(math.max(0.3,(1 - (self.timeLeft-60)/777)))
			elseif self.alpha then
				self:SetAlpha(self.alpha)
			end
		end
		if ( GameTooltip:IsOwned(self) ) then
			GameTooltip:SetUnitAura(unit, index, self.filter);
		end
		self.divider = 0
	end
end

local function BuffedRightClick(self, button)
	if ( button == "RightButton" ) then
		CancelUnitBuff(self.unit, self:GetID(), self.filter)
	elseif ( button == "LeftButton" ) then
		if IsShiftKeyDown() then
			if not BuffedProfiles[UnitName("player")].filterframes[self.namePrefix][self.name] then
				for i = 1, 16 do
					local frame = _G["BuffedFilter"..i]
					if frame and (not frame.name) then
						print("Added "..self.name.." to filter frames")
						BuffedProfiles[UnitName("player")].filterframes[self.namePrefix][self.name] = "BuffedFilter"..i
						frame.name = self.name
						frame.Btype = self.namePrefix
						frame.enabled = true
						frame.fs:SetText(self.name)
						ToggleLock() ToggleLock()
						BuffedUpdate("force")
						return
					end
				end
			end
		end
	end
end

local function BuffedButtonUpdate(buttonName, index, filter, unit, tag)	--ideally these need to be integrated into the config frames
	local name, rank, texture, count, debuffType, duration, expirationTime, IsMine = UnitAura(unit, index, filter);
	local buffName = buttonName..index;
	local buff = _G[buffName]
	local parent
	if not name then
		if buff then
			buff:Hide();
			buff.duration:Hide();
		end
		return nil
	else
		local helpful = (filter == "HELPFUL");
		if not buff then -- If button doesn't exist make it
			buff = CreateFrame("Button", buffName, UIParent)
			buff.duration = buff:CreateFontString(buff:GetName().."Duration", "OVERLAY", "GameFontNormal")
			buff.duration:SetWidth(30)
			buff.duration:SetHeight(15)
			buff.duration:SetPoint("TOP", buff, "BOTTOM")
			buff.duration:SetVertexColor(FontColour.r, FontColour.g, FontColour.b, FontColour.a)
			 buff.count = buff:CreateFontString(buff:GetName().."Count", "OVERLAY", "GameFontNormal")
			 buff.count:SetWidth(15)
			 buff.count:SetHeight(15)
			 buff.count:SetPoint("BOTTOMRIGHT", buff, "BOTTOMRIGHT")
			 buff.count:SetVertexColor(FontColour.r, FontColour.g, FontColour.b, FontColour.a)
			buff.dbar = CreateFrame("StatusBar", nil, buff)
			buff.dbar:SetWidth(70)
			buff.dbar:SetHeight(20)
			buff.dbar:SetPoint("LEFT", buff, "RIGHT", 3, 0)
			buff.dbar:SetOrientation("HORIZONTAL")
			buff.dbar:SetStatusBarTexture("Interface\\AddOns\\Buffed!\\Flat")
			buff.dbar:SetStatusBarColor(0.2, 1, 0.2)
			buff.dbar:Hide()
			 buff.icon = buff:CreateTexture(buff:GetName().."Icon", "HIGH")
			 buff.icon:SetAllPoints(buff)
			buff:SetScript("OnMouseUp", function(self, button)  BuffedRightClick(self, button) end)
			buff:SetScript("OnEnter", function(self)
			 GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT");
			 GameTooltip:SetUnitAura(unit, self:GetID(), self.filter); end)
			buff:SetScript("OnLeave", function() GameTooltip:Hide() end)
			if not helpful then
				buff.border = buff:CreateTexture(buff:GetName().."Border", "OVERLAY")
				buff.border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
				buff.border:SetTexCoord(0.3,0.5703125,0,0.515625)
				buff.border:SetAllPoints(buff)
			end
		end
		buff.namePrefix = buttonName;
		buff.name = name
		buff:SetID(index);
		buff.unit = unit;
		buff.filter = filter;
		buff:Show();
			BuffedBuffButtonAnchors(buttonName, index, IsMine, name, tag)
		if not helpful then
			if ( buff.border ) then
				local color;
				if ( debuffType ) then
					color = DebuffTypeColor[debuffType];
				else
					color = DebuffTypeColor["none"];
				end
				buff.border:SetVertexColor(color.r, color.g, color.b);
			end
		end
		local parent = buff.parent
		if parent then
			if parent.alpha then
				buff.alpha = parent.alpha
			end
		end
		if ( duration > 0 and expirationTime ) then
			buff.duration:Show();
			if parent and parent.bar and parent.bar:IsShown() then
				buff.dbar:SetWidth(parent.bar:GetWidth())   --this whole chunk needs moving
				buff.dbar:SetHeight(parent.bar:GetHeight())
				if parent.bar.horiz then
					buff.dbar:SetOrientation("HORIZONTAL")
				else
					buff.dbar:SetOrientation("VERTICAL")
				end
				buff.dbar:SetStatusBarTexture(parent.bar.tex:GetTexture())
				buff.dbar:SetStatusBarColor(parent.bar.tex:GetVertexColor())
				buff.dbar:SetAllPoints(parent.bar)
				buff.dbar:Show()
			end
			buff.dbar:SetMinMaxValues(0, duration)
			if not buff.timeLeft then
				buff.timeLeft = expirationTime - GetTime();
				buff:SetScript("OnUpdate", function(self, elapsed)
				BuffedButtonOnUpdate(self, elapsed, unit, index) end);
			else
				buff.timeLeft = expirationTime - GetTime();
			end
			buff.duration:SetFormattedText(BuffedTimeFormat(buff, buff.timeLeft))
		else
			if not buff.alpha  then -- just in case it isnt parented to the config frames
				buff:SetAlpha(0.5)
			elseif buff.alpha then
				buff:SetAlpha(buff.alpha)
			end
			buff.duration:Hide();
			buff.dbar:Hide()
			if ( buff.timeLeft ) then
				buff:SetScript("OnUpdate", nil);
			end
			buff.timeLeft = nil;
		end
		buff.icon:SetTexture(texture);
		if ( count > 1 ) then
			buff.count:SetText(count);
			buff.count:Show();
		else
			buff.count:Hide();
		end
		if ( GameTooltip:IsOwned(buff) ) then -- Refresh tooltip
			GameTooltip:SetUnitAura(unit, index, filter);
		end
	end
	return true;
end

local function BuffedSort(num, unit, filter)
	BuffedSorter = wipe(BuffedSorter)
	if BuffedSettings.duration then
		for i = 1,num do
		local name, rank, texture, count, debuffType, duration, expirationTime, IsMine = UnitAura(unit, i, filter);
			if (expirationTime == 0 ) or (expirationTime == nil ) then
				expirationTime =  GetTime() + 100000 + i
			end
			BuffedSorter[i] = {expTime = expirationTime, number = i }
		end
		if next(BuffedSorter) then
			table.sort(BuffedSorter, function (a,b) return a.expTime < b.expTime end)
		end
	end
end

function BuffedUpdate(self, event, unit, ...)
	if (event == "UNIT_AURA") and (unit == "player") or (self == "force") then
		HiddenCount = 0 -- reset each time
		BuffedSort(BuffedSettings.FrameCreation.Buff, "player", "HELPFUL")
		for i=1, BuffedSettings.FrameCreation.Buff do
			BuffedButtonUpdate("BuffedBuffButton", i, "HELPFUL", "player", "BuffedBuff")
		end
		BuffedSort(BuffedSettings.FrameCreation.Debuff, "player", "HARMFUL")
		HiddenCount = 0
		for i=1, BuffedSettings.FrameCreation.Debuff do
			BuffedButtonUpdate("BuffedDebuffButton", i, "HARMFUL", "player", "BuffedDebuff")
		end
	end
	if (event == "UNIT_AURA") and (unit == "target") or (event == "PLAYER_TARGET_CHANGED") or (self == "force") then
		HiddenCount = 0
		BuffedSort(BuffedSettings.FrameCreation.TargetBuff, "target", "HELPFUL")
		for i=1, BuffedSettings.FrameCreation.TargetBuff do
			BuffedButtonUpdate("TargetBuffedButton", i, "HELPFUL", "target", "BuffedTargetBuff")
		end
		BuffedSort(BuffedSettings.FrameCreation.TargetDebuff, "target", "HARMFUL")
		HiddenCount = 0
		for i=1, BuffedSettings.FrameCreation.TargetDebuff do
			BuffedButtonUpdate("TargetDebuffedButton", i, "HARMFUL", "target", "BuffedTargetDebuff")
		end
	end
	for i = 1,2 do -- weapon enchant placement
		local buff = _G["TempEnchant"..i]
		local mooop = _G["BuffedWep"..i]
		if buff and mooop then
			local point, relativeTo, relativePoint, xOfs, yOfs = mooop:GetPoint()
			buff:ClearAllPoints()
			buff:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs)
		end
	end
end

local h = CreateFrame("Frame")
h:RegisterEvent("UNIT_AURA")
h:RegisterEvent("PLAYER_TARGET_CHANGED")
h:SetScript("OnEvent", BuffedUpdate)

local function BuffedPositioning(self, event, ...)
	if (event == "PLAYER_REGEN_ENABLED") then
		ForAllFrames(function(f, FrameName, FrameNum, i)
			if  BuffedProfiles[UnitName("player")].nocombat["Buffed"..FrameName..i] then
				SetConfigVars(BuffedProfiles[UnitName("player")].nocombat["Buffed"..FrameName..i], f)
			end
		end)
		BuffedUpdate("force")
	elseif (event == "PLAYER_REGEN_DISABLED") then
		ForAllFrames(function(f, FrameName, FrameNum, i)
			if BuffedProfiles[UnitName("player")].combat["Buffed"..FrameName..i] then
				SetConfigVars(BuffedProfiles[UnitName("player")].combat["Buffed"..FrameName..i], f)
			end
		end)
		BuffedUpdate("force")
	end
end

local g = CreateFrame("Frame")
g:RegisterEvent("PLAYER_REGEN_ENABLED")
g:RegisterEvent("PLAYER_REGEN_DISABLED")
g:SetScript("OnEvent", BuffedPositioning)

function BuffFrame_Update() end
function TargetFrame_UpdateAuras (self) end
