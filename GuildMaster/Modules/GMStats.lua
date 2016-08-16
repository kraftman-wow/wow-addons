--[[
1. About
2. Changes
3. To do.
4. Known Issues

--========================== 1. About ===============================
	This module adds a stats frame which will eventually display all of the info that the addon collects on players. 
	Currently the stats frame shows batteground information such as the total healing done, damage done, and honor gained, as well as the highest achieved in a single battleground.
	It also shows some extra guild statistics collected by the addon such as the time spent online/instancing/raiding. 
	This information accurate to the nearest minute.
--========================== 2. Changes ==============================
	1.4
	Total donations now includes donations from looting.
	Mousewheel to scroll
	escape closes the window.
--========================== 3. To do ================================
	Get the graphs working properly.
	sort by name
	check that offline changes are working properly.
	remove players that no longer exist
	change date ranges are working.
	show the guild rep 

	Track some general guild info.
	average level, 
	etc.

	Ideally this module should be integrated into the guild roster:
		main problem is fitting the data into the roster.
]]

function GMaster.AL.GMStats()


--[[
Extra views:
donations: donated, looted, withdrawn, repair, total

--]]

















	local SortBy = 1 --which column of the table to sort by
	local offset = 0 
	local toffset = 0
	local Page = "Activity" -- which panel of the stats frame to shpw
	local duration = "Daily" -- the timescale of the data 

	local TopTabNames = {PvP ={"Name", "Killing Blows", "Deaths", "HK's", "Damage Done", "Healing Done", "Honor"},
										PvPLoc = {0, 10, 11, 12, 13, 14, 15} , --relative locations of the above values
										PvPh = {140, 90, 70, 50, 100, 100, 80}, -- widths of the columns appropriate to each name of the column
										Activity = {"Name", "Online", "BG", "Arena", "Instance", "Raiding", "Chattyness"},
										ActivityLoc = {0, 2, 4, 5, 6, 7, 3},
										Activityh = {130, 70, 80, 70, 100, 100, 80},
										Guild = {"Name", "Donated", "Withdrawn", "Repairs", "Total", "Events Started", "Events Attended"},
										Guildh = {130, 70, 70, 70, 70, 100, 110},
										GuildLoc = {0,22,23,24, 3,8,9},
										
									}

	local GMInfoFrame = CreateFrame("Frame", "GMInfoFrame", UIParent, "ButtonFrameTemplate") -- the guild stats frame
			tinsert(UISpecialFrames, "GMInfoFrame")
			
	local Scroller = CreateFrame("ScrollFrame", "GMInfoScrollFrame", GMInfoFrameInset, "FauxScrollFrameTemplate") -- the scroller for the stats frame
			Scroller:SetWidth(30)
			Scroller:SetHeight(360)
			Scroller:SetPoint("TOPRIGHT", GMInfoFrameInset, "TOPRIGHT", -5, 0)
			Scroller:Show()


	local function SecondsToClock(sSeconds) --convert the seconds into formatteed time
		local nSeconds = tonumber(sSeconds)
		if nSeconds == 0 then
		--return nil;
		return "0";
		else
			local nHours = string.format("%02.f", floor(nSeconds/3600));
			local nMins = string.format("%02.f", floor(nSeconds/60 - (nHours*60)));
			local nSecs = string.format("%02.f", floor(nSeconds - nHours*3600 - nMins *60));
			return nHours..":"..nMins..":"..nSecs
		end
	end	
			
		
	--thsi function returns the time value since the date desired, eg since last sunday for week, or since 12:00 last night for day	
	local function GetDate() 
		local TimeTable = {}
	 --{ ["hour"] = 20, ["min"] = 15, ["wday"] = 5, ["day"] = 2, ["month"] = 12, ["year"] = 2010, ["sec"] = 47, ["yday"] = 336, ["isdst"] = false }
		

		if duration:find("Daily") then
			TimeTable = date("*t", time())
			TimeTable.min = 0
			TimeTable.hour = 0
			TimeTable.sec = 0
			return time(TimeTable)
		elseif duration:find("Weekly") then
			local findtime = time() -86400
			TimeTable = date("%A", findtime)
			while TimeTable ~= "Sunday" do
				findtime = findtime - 86400
				TimeTable = date("%A", findtime)
			end
			TimeTable = date("*t", findtime)
			TimeTable.min = 59
			TimeTable.hour = 23
			TimeTable.sec = 59
			return time(TimeTable) --return the time at 1 second to midnight on the last sunday
		elseif duration:find("Monthly") then
			local month, day
			findtime = time()
			TimeTable = date("*t", findtime)
			local month, year = TimeTable.month, TimeTable.year
			while month == TimeTable.month and year == TimeTable.year do

				findtime = findtime - 86400
				TimeTable = date("*t", findtime)
			end
			TimeTable = date("*t", findtime)
			TimeTable.min = 59
			TimeTable.hour = 23
			TimeTable.sec = 59
			return time(TimeTable) --hopefully returns 1second to midnight of the last day of the last month
		end
	end


	local function GMInfoFrame_Update()
	local TopButton
	local NameList = {}
	local CheckDateStart


			for i = 1, 7 do
				TopButton = _G["GMInfoTopButton"..i]
				if TopButton then
					TopButton = _G["GMInfoTopButton"..i]
					TopButton:SetText(TopTabNames[Page][i])
					TopButton:SetWidth(TopTabNames[Page.."h"][i])
					WhoFrameColumn_SetWidth(TopButton, TopTabNames[Page.."h"][i]);
				end
			end
		
		CheckDateStart = GetDate()
			
			
		local TempTable = {}

		if not GMLogs then return end
		if CheckDateStart then
			for dated, player in pairs(GMLogs) do
				if dated > CheckDateStart then
				--add everything into the current table
					for name, info in pairs(GMLogs[dated]) do
						if name == "LastRecord" then
							--dont do anythign to it
						else
							if TempTable[name] then
								for i = 1, #info do
									if i > 9 and i < 16 then
										--check if its higher
										if TempTable[name][i] then
											if info[i] > TempTable[name][i] then --if its higher 
												TempTable[name][i] = 0 + info[i] --replace it
											end
										else
											TempTable[name][i] = 0 + info[i]
										end
									else
										if TempTable[name][i] then
											TempTable[name][i] = TempTable[name][i] + info[i]
										else
											TempTable[name][i] = 0 +info[i]
										end
									end
								end
							else
								TempTable[name]  = {unpack(info)}
							end
						end
					end
				end
			end
		end
		for name, info in pairs(TempTable) do
			local found 
			tinsert(NameList, {name = name, info = {unpack(info)}})
		end
		
		--if Page:find("PvP") then --should remove any player info for which none of the desired info is found
			for i = #NameList, 1, -1 do
				local found = false --found any data?
				local loc = TopTabNames[Page.."Loc"]
				for j = 2, #loc do
					if  NameList[i].info[loc[j]] and  NameList[i].info[loc[j]] > 0 then
						found = true -- pvp data found
					end
				end
				if not found then
					tremove(NameList, i) --remove tables for which no info is found
				end
			end
		--end
		
		if SortBy then
				table.sort(NameList, function(a, b)
													if a.info[TopTabNames[Page.."Loc"][SortBy]] and b.info[TopTabNames[Page.."Loc"][SortBy]] then
													return a.info[TopTabNames[Page.."Loc"][SortBy]] > b.info[TopTabNames[Page.."Loc"][SortBy]] 
													end end)
		end
		

		
		FauxScrollFrame_Update(Scroller, #NameList, 21, 16)
						
		offset = FauxScrollFrame_GetOffset(Scroller)
		-- if scroller iisshown then make inset smaller

		for i = 1, 30 do
			local button = _G["GMInfoFrameButton"..i]
			if button then
				button:Hide()
				
				local index = i + offset
				if NameList[index] then
					button.texts[1]:SetText(NameList[index].name)
					if GMRoster[NameList[index].name] then
						local class = GMRoster[NameList[index].name].class
						local classColor = RAID_CLASS_COLORS[class];
						if classColor then
							button.texts[1]:SetTextColor(classColor.r, classColor.g, classColor.b);
						end
					end
					for i = 2, 7 do
						if Page == "PvP" then
							button.texts[i]:SetText(NameList[index].info[TopTabNames.PvPLoc[i]+toffset] or "0")
						
						elseif Page == "Activity" then
							local text = NameList[index].info[TopTabNames.ActivityLoc[i]]
							if text then
								if TopTabNames.ActivityLoc[i] ~= 3 then
									text = SecondsToClock(text)
									button.texts[i]:SetText(text)
								else
									button.texts[i]:SetText(text)
								end
									
							else
									button.texts[i]:SetText("0")
							end
						elseif Page == "Guild" then
							local text = NameList[index].info[TopTabNames.GuildLoc[i]]
							if text then
								if i > 1 and i < 6 then
								if i == 5 then
									local loc = NameList[index].info
									text = (loc[22] or 0) - (loc[23] or 0) - (loc[24] or 0 ) + (loc[25] or 0)
								end
								local gold = floor((text/10000) )
								local silver = floor(((text- gold*10000)/100) + 0.5)
								
									button.texts[i]:SetText(gold.."g "..silver.."s")
								else
									button.texts[i]:SetText(text)
								end
							else
									button.texts[i]:SetText("0")
							end
						end
					end
					button:Show()
				else
					button:Hide()
				end
			end
		end
	end

	Scroller:SetScript("OnVerticalScroll", function(self, value) FauxScrollFrame_OnVerticalScroll(self, value, 16, GMInfoFrame_Update)  end)
			
		

	function GMaster.GFL.LoadStats()
		
			local ToggleGMInfo = CreateFrame("Button", nil, GuildFrame) --add a button to the guild emblem that toggles the stats frame
			ToggleGMInfo:SetWidth(50)
			ToggleGMInfo:SetHeight(50)
			ToggleGMInfo:SetPoint("TOPLEFT", GuildFrame, "TOPLEFT")
			ToggleGMInfo:SetScript("OnClick", function() if GMInfoFrame:IsShown() then 
																								GMInfoFrame:Hide() 
																							PlaySound("igCharacterInfoTab");
																						else 
																								GMInfoFrame:Show() 
																								PlaySound("igCharacterInfoTab");
																							end 
																						end)
					
					---[[local parent
			for i = 1, 7 do -- add the tabs allong the bottom
				local b = CreateFrame("Button", "GMInfoTopButton"..i, GMInfoFrame, "GuildRosterColumnButtonTemplate")
				b:SetWidth(50)
				b:SetHeight(24)
				b.ID= i
				if parent then
					b:SetPoint("LEFT", parent, "RIGHT", 0, 0)
					parent = b
				else
					b:SetPoint("BOTTOMLEFT", GMInfoFrameInset, "TOPLEFT", 5, 0)
					parent = b
				end
				b:SetText("test")
				b:Show()
				b:SetScript("OnClick", function(self) SortBy = self.ID GMInfoFrame_Update() end)
			end--]]
					
			for i = 1, 21 do --add the buttons to sthe stats frame
				local button = _G["GMInfoFrameButton"..i]
				for j =1, 7 do
				
					local text = button.texts[j]
						
					if text then
					text:SetPoint("TOP", button, "TOP")
					text:SetPoint("BOTTOM", button, "BOTTOM")
					text:SetPoint("LEFT", _G["GMInfoTopButton"..j], "LEFT")
					text:SetPoint("RIGHT", _G["GMInfoTopButton"..j], "RIGHT")
					text:SetText("Samples TEXT"..j)	
					else
						
					end
				end
			end
	end


	

	GMInfoFrame:SetWidth(650)
	GMInfoFrame:SetHeight(450)
	GMInfoFrame:SetPoint("CENTER")
	GMInfoFrame:SetMovable(true)
	GMInfoFrame:EnableMouse(true)
	GMInfoFrame:SetScript("OnMouseDown", function(self) self:StartMoving() end)
	GMInfoFrame:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() end)
	GMInfoFrame:SetScript("OnShow", GMInfoFrame_Update)
	GMInfoFrame.CheckButtonText = GMInfoFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")

	local ShowTotals = CreateFrame("CheckButton", "testtr", GMInfoFrame, "OptionsSmallCheckButtonTemplate")
	ShowTotals:SetWidth(20)
	ShowTotals:SetHeight(20)
	ShowTotals:SetPoint("TOPRIGHT", GMInfoFrameInset, "BOTTOMRIGHT", -5, 0)
	ShowTotals:SetChecked(false)
	ShowTotals:SetScript("OnClick", function(self) 
														if self:GetChecked()  then 
															toffset = 0
															GMInfoFrame.CheckButtonText:SetText("Show total earned")
															GMInfoFrame_Update()
														else
															toffset = 6
															GMInfoFrame.CheckButtonText:SetText("Show highest achieved in single BG")
															GMInfoFrame_Update()
														end 
													end)


	GMInfoFrame.CheckButtonText:SetHeight(25)
	GMInfoFrame.CheckButtonText:SetWidth(300)
	GMInfoFrame.CheckButtonText:SetPoint("RIGHT", ShowTotals, "LEFT")
	GMInfoFrame.CheckButtonText:SetText("Show total earned")
	GMInfoFrame.CheckButtonText:SetJustifyH("RIGHT")

	GMInfoFrameInset:ClearAllPoints()
	GMInfoFrameInset:SetPoint("TOPLEFT", 5, -55)
	GMInfoFrameInset:SetPoint("BOTTOMRIGHT", -25, 30)

	-- == creates drop down to changed the date of the info shown
	local GMCoreDurDD = CreateFrame("Frame", "GMCoreDurDD", GMInfoFrame, "UIDropDownMenuTemplate")
	GMCoreDurDD:SetPoint("TOPLEFT", GMInfoFrameInset, "BOTTOMLEFT", 0, 0)
	UIDropDownMenu_SetWidth(GMCoreDurDD, 120)
	UIDropDownMenu_SetButtonWidth(GMCoreDurDD, 80)


	function GMCoreDurDD_Initialize()
		level = 1
		local info = UIDropDownMenu_CreateInfo()
		
		
		info = UIDropDownMenu_CreateInfo()
		info.notCheckable = true
		info.text = "Today"
		info.value = "Daily"
		info.checked = nil
		info.func =  function(self) duration = self.value GMInfoFrame_Update()	UIDropDownMenu_SetText(GMCoreDurDD, "Daily")  end
		UIDropDownMenu_AddButton(info, level)
		
		info = UIDropDownMenu_CreateInfo()
		info.notCheckable = true
		info.text =  "This Week"
		info.value = "Weekly"
		info.checked = nil
		info.func = function(self) duration = self.value GMInfoFrame_Update () 	UIDropDownMenu_SetText(GMCoreDurDD, "Weekly") end
		UIDropDownMenu_AddButton(info, level)
		
		info = UIDropDownMenu_CreateInfo()
		info.notCheckable = true
		info.text =  "This Month"
		info.value = "Monthly"
		info.checked = nil
		info.func = function(self) duration = self.value GMInfoFrame_Update () 	UIDropDownMenu_SetText(GMCoreDurDD, "Monthly") end
		UIDropDownMenu_AddButton(info, level)
		
		
	end
	UIDropDownMenu_Initialize(GMCoreDurDD, GMCoreDurDD_Initialize)

	UIDropDownMenu_SetText(GMCoreDurDD, "Daily")

	--========= create tabs allong bottom ======
	local TabNames = {"Activity", "Guild", "PvP"}

	for i = 1, #TabNames do --created the tabs allong the bottom
	   local button = CreateFrame("Button", "GMInfoFrameTab"..i, GMInfoFrame, "CharacterFrameTabButtonTemplate" )
	   button:SetID(i)
	   if i == 1 then
		  button:SetPoint("TOPLEFT", GMInfoFrame, "BOTTOMLEFT", 0, 0)
	   else
		  button:SetPoint("LEFT", _G["GMInfoFrameTab"..(i-1)], "RIGHT", -16, 0)
	   end
	   
	   button:SetText(TabNames[i])
	   button:SetScript("OnClick", function(self) 
																	PanelTemplates_Tab_OnClick(self, GMInfoFrame)
																	Page = self:GetText()
																	GMInfoFrame_Update()
																end)
	   
	end

	local button = _G["GMInfoFrameTab1"]
	ButtonFrameTemplate_HidePortrait(GMInfoFrame)
	PanelTemplates_SetNumTabs(GMInfoFrame, #TabNames)
	GMInfoFrame:Hide()
	GMInfoFrame:Show()
	GMInfoFrame:Hide()
	PanelTemplates_Tab_OnClick(button, GMInfoFrame)

	
	local function GetPlayerData(name)
		local data = {}
		local minX, minY, maxY, maxX 
		for dated, players in pairs(GMLogs) do
			if not minX then
				minX = dated
			end
			if not maxX then 
				maxX = dated
			end
			if dated < minX then
				minX = dated
			end
			if dated > maxX then
				maxX = dated
			end
			if players[name] then
				for i = 1, #players[name] do
					if not minY then
						minY = players[name][i]
					end
					if not maxY then
						maxY = players[name][i]
					end
					if players[name][i] > maxY then
						maxY  = players[name][i]
					end
					if players[name][i] < minY then
						minY = players[name][i]
					end
					if not data[i] then
						data[i] = {}
					end	
					tinsert(data[i], {dated, players[name][i]})
				end
			end
		end
		
		if next(data) then
			return data, minX, maxX, minY, maxY
		end
	end
	--=======================
		--Graph Frame
		--[[
		local GraphFrame = CreateFrame("Frame", nil,  GMInfoFrame)
		GraphFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
												edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
												tile = true, tileSize = 16, edgeSize = 16, 
												insets = { left = 4, right = 4, top = 4, bottom = 4 }})
		GraphFrame:SetBackdropColor(0,0,0,1);
		
		GraphFrame:SetSize(200, 200)
		GraphFrame:SetPoint("TOPLEFT", GMInfoFrame, "TOPRIGHT", 10, 0)
		GraphFrame:Hide()
		
			local Graph=LibStub("LibGraph-2.0")
			local Graph=Graph:CreateGraphLine("TestLineGraph",GraphFrame,"CENTER","CENTER",90,90,180,180)
			
			Graph:SetAxisDrawing(true,true)
			Graph:SetAxisColor({1.0,1.0,1.0,1.0})
			Graph:SetAutoScale(true)

			local Data1={{0.05,0.05},{0.2,0.3},{0.4,0.2},{0.9,0.6}}
			local Data2={{0.05,0.8},{0.3,0.1},{0.5,0.4},{0.95,0.05}}

		
		local function Graph_Update(player)
			local data, minX, maxX, minY, maxY = GetPlayerData(player)
			if not data then return end
			print(data, minX, maxX, minY, maxY)
			Graph:SetXAxis(minX,maxX)
			Graph:SetYAxis(minY,maxY)
			Graph:SetGridSpacing((maxX-minX)/5,(maxY-minY)/5)
			Graph:SetGridColor({0.5,0.5,0.5,0.5})
			for i = 1, #data do
				print(unpack(data[i]))
				Graph:AddDataSeries( data[i], {1, 1, 1, 0.8})
			end
			Graph:AddDataSeries(Data1,{1.0,0.0,0.0,0.8})
			Graph:AddDataSeries(Data2,{0.0,1.0,0.0,0.8})
		end
		
		--]]
	--===================
	
	
	local parent

	for i = 1, 21 do
		local button = CreateFrame("Button", "GMInfoFrameButton"..i, GMInfoFrame, "WorldStateScoreTemplate")

		button:SetPoint("LEFT", GMInfoFrameInset, "LEFT", 4, 0)
		button:SetPoint("RIGHT", GMInfoFrameInset, "RIGHT", -4, 0)
	
		if parent then
			parent = _G["GMInfoFrameButton"..(i-1)]
			button:SetPoint("TOP", parent, "BOTTOM", 0, -1)
		else
			button:SetPoint("TOP", GMInfoFrameInset, "TOP", 0, -4)
			parent = button
		end
		local textureLeft = _G["GMInfoFrameButton"..i.."FactionLeft"]
		local textureRight = _G["GMInfoFrameButton"..i.."FactionRight"]
		textureLeft:SetAlpha(0.5)
		textureRight:SetAlpha(0.5)
		
		button.texts = {}
		button.texts[#button.texts+1] = button.name.text
		button.texts[#button.texts+1] = _G[button:GetName().."Column2Text"] 
		button.texts[#button.texts+1] = button.killlingBlows
		button.texts[#button.texts+1] = button.damage
		button.texts[#button.texts+1] = button.healing
		button.texts[#button.texts+1] = button.honorableKills
		button.texts[#button.texts+1] = _G[button:GetName().."Column1Text"]
		button.texts[#button.texts+1] = button.deaths
	
		button:SetScript("OnMouseWheel", function(self, delta) delta = delta*16 Scroller:SetVerticalScroll(Scroller:GetVerticalScroll() + delta) GMInfoFrame_Update()  end)
			
		button:SetScript("OnClick", function(self) if self:IsShown() then if GraphFrame:IsShown() then else GraphFrame:Show() GraphFrame.name = button.texts[1]:GetText() Graph_Update(GraphFrame.name) end end end)
				--button:Hide()
	end

end

GMaster.LoadOrder.GMStats = true