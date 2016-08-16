--[[
1. Summary
2. Details
3. Structure
4. Changes
5. To Do

--========================== 1. Summary ===============================
	Interface options for the addon: control which modules are loaded, 
	and the settings for each module.
--========================== 2. Details ===============================
	Each module has its own function for loading itself, unloading itself, 
	and displaying options. This module provides a method of calling the modules
	functions, and will eventually provide a few other general options.
	
--========================== 3. Structure =============================
	
--========================== 4. Changes ===============================
1.52:
	Each module now stores its own settings. This module loads other modules
	settings and displays them in the interface options menu.
1.40:
	Made each module properly modular, added toggling of each module.
--========================== 5. To do =================================
	Add method of removing alts if they changed guilds
	integrate the alts feature into all of the other modules that need it.
]]

--[[
1. About
2. Changes
3. To do.
4. Known Issues

--========================== 1. About ===============================

--========================== 2. Changes ==============================

--========================== 3. To do ================================
	
	Need to sync settings

]]

function RemoveInterfaceOptions(Parent, Child) --remove the interface option frame
		local bChildPanel = true;
		if (Child == nil) then -- Assume we are removing the whole panel if no child was specified
			Child = Parent;
			bChildPanel = false;
		else

		end;

		for Key,Value in pairs(INTERFACEOPTIONS_ADDONCATEGORIES) do
			if (bChildPanel and ((Value.parent == Parent) and (Value.name == Child))) then -- We are looking for a child panel and this is it...
				INTERFACEOPTIONS_ADDONCATEGORIES[Key] = nil;
			end;
			
			if (not(bChildPanel) and ((Value.parent == nil) and (Value.name == Child))) then -- We are looking for a parent and this is it...
				INTERFACEOPTIONS_ADDONCATEGORIES[Key] = nil;
			elseif (not(bChildPanel) and ((Value.parent == Parent))) then -- We are looking for a parent and this is it's child...
				INTERFACEOPTIONS_ADDONCATEGORIES[Key] = nil;
			end;
		end;

		InterfaceAddOnsList_Update();
 end;



function GMaster.GMSettings()

	local GMConfiger = CreateFrame("Frame") -- all config stuff
	GMConfiger.name = "GuildMaster"
	GMConfiger.Sync = CreateFrame("Frame")
	GMConfiger.Sync.name = "GM-Sync"
	GMConfiger.Sync.parent = "GuildMaster"
	InterfaceOptions_AddCategory(GMConfiger)

	---[[
	for name, value in pairs(GMaster.LoadOrder) do
		
		if GMSettings.modules[name] and GMSettings.modules[name].active and GMaster.ModuleSettings[name] then
			local setting = GMaster.ModuleSettings[name]()
			setting.parent = "GuildMaster"
			setting.name = name
		
			InterfaceOptions_AddCategory(setting)
		end
	end
	--]]


--========================== Main Page ==========================
	GMConfiger.titleText = GMConfiger:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	GMConfiger.titleText:SetPoint("TOPLEFT", GMConfiger, "TOPLEFT", 30, -40)
	GMConfiger.titleText:SetPoint("BOTTOMRIGHT", GMConfiger, "BOTTOMRIGHT", -30, 40)
	GMConfiger.titleText:SetJustifyH("LEFT")
	GMConfiger.titleText:SetJustifyV("TOP")


--=============== GuildMaster =============================

--enable storing data in guild info?
--[[
fonstring: while most of the data and settings can be synced between addons, some features require settings 
				to use them, you can allow the addon to use the guild information to store the settings. any text currently in the guild information can be posted
				to the forum instead.:
				
				check button: export guild info to forum
				
				settings that need to be stored server side: 
				addon version number
				oldest date of posts
				oldest date of synced data.
				
				if they enabled this setting:
				
				show options for dates.
				
				settings for which modules to use?
--]]
	do 
		local GM = GMConfiger
		GM.CheckBox = CreateFrame("CheckButton", "GMDebugCB", GM, "ChatConfigCheckButtonTemplate") -- check button
		_G[GM.CheckBox:GetName().."Text"]:SetText ("Enable Debugging")
		GM.CheckBox:SetSize(25, 25)
		GM.CheckBox:SetPoint("TOPLEFT", 30, -130)
		GM.CheckBox:SetScript("OnClick", function(self) if GMSettings.Debug then GMSettings.Debug = false else GMSettings.Debug = true end end)
		GM.CheckBox:SetScript("OnShow", function(self) if GMSettings.Debug then self:SetChecked(true) else self:SetChecked(false) end end)
		GM.CheckBox.tooltip = ("Prints information on what is being sent and received by the addon")
		
		GM.CheckBox2 = CreateFrame("CheckButton", "GMUseInfoCB", GM, "ChatConfigCheckButtonTemplate") -- check button
		_G[GM.CheckBox2:GetName().."Text"]:SetText ("Use guild info for settings")
		GM.CheckBox2:SetSize(25, 25)
		GM.CheckBox2:SetPoint("TOPLEFT", 200, -150)
		GM.CheckBox2:SetScript("OnClick", function(self) if GMSettings.Debug then GMSettings.Debug = false else GMSettings.Debug = true end end)
		GM.CheckBox2:SetScript("OnShow", function(self) if GMSettings.Debug then self:SetChecked(true) else self:SetChecked(false) end end)
		GM.CheckBox2:Hide()
		local x = 30
			local y = -180
			
			
		for name, value in pairs(GMaster.LoadOrder) do
			
			
			local button = CreateFrame("CheckButton", "GMSett"..name, GM, "ChatConfigCheckButtonTemplate") -- check button
			button:SetChecked(GMaster.loaded[name])
			button:SetHitRectInsets(0, -70, 0, 0)
			button:SetScript("OnClick", function(self) 
															if self:GetChecked() then 
																if GMaster.loaded[name]  then
																	print("Loading module "..name..".. Module already loaded")
																else
																	
																	if GMaster.ModuleSettings[name] then
																		local setting = GMaster.ModuleSettings[name]()
																			GMaster.ModuleLoad[name]()
																		
																			GMSettings.modules[name] = GMSettings.modules[name] or {}
																			GMSettings.modules[name].active = true
																			GMaster.loaded[name]  = true
																			print("Loading module "..name)
																			
																			
																			if setting then
																				setting.name = name
																				setting.parent = "GuildMaster"
																				InterfaceOptions_AddCategory(setting)
																			end
																			
																	end
																end
															else
																local removed
																if GMaster.ModuleRemove[name] then
																	removed = GMaster.ModuleRemove[name]()
																end
																
																if removed then
																	print("Module: "..name.." unloaded")
																else
																	print("Module: "..name.." unloaded, requires UI reload to take effect")
																end
																GMSettings.modules[name].active = nil 
																GMaster.loaded[name] = nil
																RemoveInterfaceOptions("GuildMaster", name)
																
																
																--GMaster.loaded["GM"..name]  = false
															end 
														end)
			_G[button:GetName().."Text"]:SetText(name)
			_G[button:GetName().."Text"]:SetWidth(110)
			button:SetSize(25, 25)
			button:SetPoint("TOPLEFT", x, y)
			x = x + 110
			if x > 345 then
				x = 30
				y = y - 50
			end
			
		end
		GM.Reload = CreateFrame("Button", nil, GM, "UIPanelButtonTemplate")
		GM.Reload:SetSize(120, 30)
		GM.Reload:SetText("Reload Interface")
		GM.Reload:SetPoint("BOTTOM", 0, 30)
		GM.Reload:SetScript("OnClick", function(self) ReloadUI() end)
		
	end




--==================== GM RECRUIT ====================
--[[
	needs: a slider to set the delay from 5 minutes - 1 hour
	a dropdown to either make a new recruitment message, or edit an old one
	an edit box to change the message (with a char limite of 250)
	
--]]
	--[[
	do
	local Rec = GMConfiger.GMRecruit



	Rec.SliderText = Rec:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	Rec.SliderText:SetHeight(20)
	Rec.SliderText:SetPoint("LEFT", Rec, "LEFT", 30, 0)
	Rec.SliderText:SetPoint("RIGHT", Rec, "RIGHT", -30, 0)
	Rec.SliderText:SetText("Frequency of guild recruitment messages:")
	Rec.SliderText:SetPoint("TOP", Rec, "TOP", 0, -20 )

	Rec.delaySlide =  CreateFrame("Slider", "GMRecSlide", Rec, "OptionsSliderTemplate")
	Rec.delaySlide:SetWidth(300)
	Rec.delaySlide:SetHeight(20)
	Rec.delaySlide:SetMinMaxValues(10, 60)
	Rec.delaySlide:SetValueStep(1)

	Rec.delaySlide:SetPoint("TOP", Rec.SliderText, "BOTTOM", 0 , -20)
	Rec.delaySlide:SetScript("OnValueChanged", function(self, value) GMSettings.GMRecruit.delay = value end)


	GMRecSlideLow:SetText("10 minutes")
	GMRecSlideHigh:SetText("1 hour")


	Rec.EditBox = CreateFrame("EditBox", "GMRecruitEB", Rec)
	Rec.EditBox:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE, MONOCHROME")
	Rec.EditBox:SetTextInsets(10,10,15,15)
	Rec.EditBox:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
												edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
												tile = true, tileSize = 16, edgeSize = 16, 
												insets = { left = 4, right = 4, top = 4, bottom = 4 }});
	Rec.EditBox:SetBackdropColor(0,0,0,0.8)
	Rec.EditBox:SetMultiLine(true)
	Rec.EditBox:SetPoint("TOPLEFT", 10, -150)

	Rec.EditBox:SetPoint("BOTTOMRIGHT", Rec, "TOPRIGHT",  -10, -250)
	Rec.EditBox:SetScript("OnEscapePressed", function() InterfaceOptionsFrame:Hide() end)
	Rec:Hide()
	--ontext changed make sure its less than 250 and save

		Rec.Save = CreateFrame("Button", nil, Rec, "UIPanelButtonTemplate")
		Rec.Save:SetSize(70, 25)
		Rec.Save:SetText("Save")
		Rec.Save:SetPoint("TOPRIGHT", Rec.EditBox, "BOTTOMRIGHT", 0, -5)
		Rec.Save:SetScript("OnClick", function(self)
															--need to check the length of the message.
															--also add the duration.
															GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMRecruitNew", Rec.value.."|"..time().."|"..Rec.EditBox:GetText()}
															end)

		local GMRecruitDD = CreateFrame("Frame", "GMRecruitDD", Rec, "UIDropDownMenuTemplate")
		GMRecruitDD:SetPoint("TOP", Rec.delaySlide, "BOTTOM", 0, -30)
		GMRecruitDD:SetPoint("RIGHT", Rec, "RIGHT", -30, 0)
		UIDropDownMenu_SetWidth(GMRecruitDD, 120)
		UIDropDownMenu_SetButtonWidth(GMRecruitDD, 80)


		function GMRecruitDD_Initialize()
			level = 1
			local info = UIDropDownMenu_CreateInfo()
			
			if GMSettings.GMRecruit and GMSettings.GMRecruit.list then
				for i = 1, #GMSettings.GMRecruit.list do
					info = UIDropDownMenu_CreateInfo()
					info.notCheckable = true
					info.text =  i
					info.value = i
					info.checked = nil
					info.func = function() Rec.EditBox:SetText(GMSettings.GMRecruit.list[i].msg) UIDropDownMenu_SetText(GMRecruitDD, i) Rec.value = i end
					UIDropDownMenu_AddButton(info, level)
				end
			end
			
			info = UIDropDownMenu_CreateInfo()
			info.notCheckable = true
			info.text = "New Message"
			info.value = "New"
			info.func = function() Rec.value = #GMSettings.GMRecruit.list + 1 Rec.EditBox:SetText("")end
			UIDropDownMenu_AddButton(info, level)
		end
		
		UIDropDownMenu_Initialize(GMRecruitDD, GMRecruitDD_Initialize)
		Rec:SetScript("OnShow", function(self) self.value = #GMSettings.GMRecruit.list+ 1 UIDropDownMenu_SetText(GMRecruitDD, "New") end)

	end
	--]]
end
