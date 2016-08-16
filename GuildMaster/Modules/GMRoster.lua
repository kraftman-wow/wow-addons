--[[
1. Summary
2. Details
3. Structure
4. Changes
5. To Do

--========================== 1. Summary ===============================
	advanced guild roster allowing searching by class,name, etc, and 
	extra player stats.
--========================== 2. Details ===============================
	This adds a new customised roster into the guild frame, where the old roster was.
	The new roster is searchable, with results showing as you type them. The searches are limited
	to the columns that are shown, for example if only level and name are shown, they will be 
	the only criteria that the searchbox uses to filter results.
	Rather than switching between different views, a custom view can be created
	by adding and removing columns, as well as repositioning and resizing them.
	The right click popup for guildmembers in the roster has been enhanced to allow
	options for promoting, demoting, and removing members.
	A new detail frame has been added which shows extra player stats recorded by the
	addon, including talents and base stats.
--========================== 3. Structure =============================
	Consists of two parts
	The roster itself:
		SearchBox - the editbox for searches
		RosterChild - the frame containing the roster buttons
		Memberdetail - 3 pages of details specific to the player clicked.
		a list of all guild members
		searchbar to filter guild members
		
	The checker
		a function to update the roster when any changes are made
		and to keep the roster up to date
--========================== 4. Changes ===============================
2.0-23
	bug fix:
		search box iis constrain by the show offline button
		resizing the roster columns no longer changes sort order
		class names in the detail frame start with a capital letter.
		added item level
2.0
	Created the new roster
	added talent sharing
1.5
	- moved the roster update functionality into this module
1.4 - CreateModule
--========================== 5. To do =================================
	-Highlight the selected player in the roster
	-add a method of request player stats if they are online
	-better syncing of player stats.
	-MemberDetail:
		Gear
		Personal Note
	Scrollbars
	
	restructure the 'list' table to neaten it up.
	
	Integrate GMStats
	
	Possible future plans:
		Record reason for kicking.
		Auto mail new members
	
]]




local module = {} -- used for adding functions

local tracker = {} --track roster changes
	tracker.names = {}
	tracker.promoted = {}
	tracker.demoted = {}
	tracker.joined = {}
	tracker.levelled = {}
	tracker.quit = {}

GMaster.LoadOrder.GMRoster = true

GMaster.AL.GMRoster = function()
GMaster.GFL.GMRoster = function()

local Settings = GMSettings.modules.GMRoster
if not Settings.TabLayout then 
	Settings.TabLayout = {}
end


--[[
	new members
	quit members
	
	new applications
	new forum posts

--]]

local SideTabList = {{OnClick = function() end, Tooltip = "New Members", color = {0, 1,0}},
										 {OnClick = function() end, Tooltip = "Members that have quit", color = {1,0,0}},
										  {OnClick = function()GuildFrame_TabClicked(GuildFrameTab5)   PanelTemplates_Tab_OnClick(GuildInfoFrameTab3, GuildInfoFrame); GuildInfoFrame_Update() end, Tooltip = "New Applicants", color = {0,0.8,0}}}
local SideTabPosition = {}

local SideTabContainer = CreateFrame("Frame", nil, GuildFrame)
			SideTabContainer:SetWidth(20)
			SideTabContainer:SetPoint("TOPLEFT", GuildFrame, "TOPRIGHT",0,-30)
			SideTabContainer:SetPoint("BOTTOMLEFT", GuildFrame, "BOTTOMRIGHT")

for i = 1, #SideTabList do --create all of the buttons
	local button = CreateFrame("Button", nil, SideTabContainer)
	button:SetSize(16, 20)
	
	button.middle = button:CreateTexture(nil, "BACKGROUND")
	button.middle:SetTexture("Interface\\SpellBook\\SpellBook-SkillLineTab")
	button.middle:SetPoint("LEFT", -2, 0)
	button.middle:SetTexCoord(0, 0.625, 0.21875, 0.640625)
	button.middle:SetSize(20, 10)
	
	button.top = button:CreateTexture(nil, "BACKGROUND")
	button.top:SetTexture("Interface\\SpellBook\\SpellBook-SkillLineTab")
	button.top:SetPoint("BOTTOM", button.middle, "TOP")
	button.top:SetTexCoord(0, 0.625, 0, 0.21875)
	button.top:SetSize(20, 11)
	
	button.bottom = button:CreateTexture(nil, "BACKGROUND")
	button.bottom:SetTexture("Interface\\SpellBook\\SpellBook-SkillLineTab")
	button.bottom:SetPoint("TOP", button.middle, "BOTTOM")
	button.bottom:SetTexCoord(0,0.625,0.640625,0.875)
	button.bottom:SetSize(20, 15)
	
	button.text = button:CreateFontString(nil, "OVERLAY", "GameFontGreenSmall")
	button.text:SetTextColor(unpack(SideTabList[i].color))
	button.text:SetAllPoints(button)
	
	button.tooltip = SideTabList[i].Tooltip
	
	button:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
												GameTooltip:SetText(self.tooltip)
								end)
	button:SetScript("OnLeave", function() GameTooltip:Hide() end)
	
	button:SetScript("OnClick", SideTabList[i].OnClick)
	
	
	
	SideTabList[i].button = button --place the button in the table
	
end 

--if #tracker.joined > 0 then
	local button = SideTabList[1].button
	button:Show()
	button:SetPoint("TOPLEFT", SideTabContainer, "TOPLEFT")
	button.text:SetText(#tracker.joined)
	tinsert(SideTabPosition, button)
--end

--if #tracker.quit > 0 then
	local button = SideTabList[2].button
	button:Show()
	if #SideTabPosition == 0 then
		button:SetPoint("TOPLEFT", SideTabContainer, "TOPLEFT")
	else
		button:SetPoint("TOPLEFT", SideTabPosition[#SideTabPosition], "BOTTOMLEFT", 0, -8)
	end
	tinsert(SideTabPosition, button)
	button.text:SetText(#tracker.quit)
--end

if GetNumGuildApplicants() > 0 then
	local button = SideTabList[3].button
	button:Show()
	if #SideTabPosition == 0 then
		button:SetPoint("TOPLEFT", SideTabContainer, "TOPLEFT")
	else
		button:SetPoint("TOPLEFT", SideTabPosition[#SideTabPosition], "BOTTOMLEFT", 0, -8)
	end
	tinsert(SideTabPosition, button)
	button.text:SetText(GetNumGuildApplicants())
end



local function Update_SideTabs()
	SideTabPosition = {}
end


local RosterCache = {}

local MAX_ROSTER_BUTTONS = 21
local TempRoster = {}
local RosterButtons = {}
local offset = 0
local list = { Donations = {Donated = false, Looted = false, Repaired = false},
							Name = false, Rank = false, Class = false, Location = false, Level = false,
							Note = false, LastSeen = false, Chat = false,
							Joined = false}
							
			list["Guild XP"] = {}
			list["Guild XP"]["Weekly XP"] = false
			list["Guild XP"]["Total XP"] = false
			list["Guild XP"]["Weekly Rank"] = false
			list["Guild XP"]["Total Rank"] = false
			
			list["Achievements"] = {}
			list["Achievements"]["Achv Points"] = false
			list["Achievements"]["Achv Rank"] = false
			
			list["Officer Note"] = false
	
				
				
							--[[
							GetGuildRosterPVPRatings doesnt exist yet?
							--]]
local RosterFrame = CreateFrame("ScrollFrame", nil, GuildFrame)
			RosterFrame:SetPoint("TOPLEFT", GuildFrame, "TOPLEFT", 7, -58)
			RosterFrame:SetPoint("BOTTOMRIGHT", GuildFrame, "BOTTOMRIGHT", -9, 20)

local RosterChild = CreateFrame("Frame", nil, GuildFrame)
			RosterChild:SetSize(200, 1000)
			RosterFrame:SetScrollChild(RosterChild)

RosterChild.TabNames = {}
RosterChild.Tabs = {}


local SearchBox = CreateFrame("EditBox", "GMRosterSearchBox", RosterFrame, "InputBoxTemplate")
			SearchBox:SetAutoFocus(false)
			SearchBox:SetSize(160, 30)
			SearchBox:SetPoint("BOTTOMRIGHT", RosterFrame, "TOPRIGHT", -5, 5)
			
local SearchText = RosterFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			SearchText:SetSize(60, 30)
			SearchText:SetPoint("RIGHT", SearchBox, "LEFT")
			SearchText:SetText("Search:")
			---[[
RosterFrame:SetScript("OnMouseWheel", function(self, delta)
      delta = floor(delta)
      local v = self:GetVerticalScroll()
      local h = self:GetHorizontalScroll()

      v = v + delta*10
      h = h + delta*10
      
      if IsShiftKeyDown() then
         if (h > 0 )and h < self:GetHorizontalScrollRange()then
            self:SetHorizontalScroll(h)
         end
      else
				if delta < 0 and (offset+MAX_ROSTER_BUTTONS) <= #TempRoster then
					offset = offset + 1
				elseif delta > 0 and offset > 0 then
					offset = offset - 1
				end
				GMaster.UpdateRoster()
			
         if (v > 0) and (v < self:GetVerticalScrollRange())  then
            --[[
						self:SetVerticalScroll(v )
						local tab = RosterChild.Tabs[1]
						if tab then
							--this bit stops the top tabs moving
							tab:SetPoint("TOPLEFT", 0, -v)
						end
						--]]
         end
         
      end
      
      
end)--]]

--==================================================================================


local MemberDetail = CreateFrame("Frame", nil, RosterFrame)
			MemberDetail:SetSize(250, 375)
			MemberDetail:SetPoint("TOPLEFT", GuildFrame, "TOPRIGHT", 10, -30)
			
			MemberDetail:SetBackdrop({bgFile = "Interface/DialogFrame/UI-DialogBox-Background", 
										edgeFile = "Interface/DialogFrame/UI-DialogBox-Border", 
										tile = true, tileSize = 32, edgeSize = 32, 
										insets = { left = 11, right = 12, top = 12, bottom = 11}})
			MemberDetail:SetBackdropColor(0,0,0,1);
			
			MemberDetail.Pages = {}
			MemberDetail.Tabs = {}
			
			MemberDetail.PageNames = {"General", "Stats", "Talents"}
	
			MemberDetail.Selected = ""
			
			MemberDetail.close = CreateFrame("Button", nil, MemberDetail, "UIPanelCloseButton")
			MemberDetail.close:SetSize(25, 25)
			MemberDetail.close:SetPoint("TOPRIGHT", -7, -7)
			MemberDetail.close:SetScript("OnClick", function() MemberDetail:Hide() MemberDetail.Selected = "" end)
			
			MemberDetail:Hide()
			
local function MemberDetailTabClicked(self)
	for i = 1, #MemberDetail.Pages do
		if MemberDetail.Pages[i] == self.page then
			MemberDetail.CurrentPage = i
			self.page:Show()
		else
			MemberDetail.Pages[i]:Hide()
		end
	end
	GMaster.RefreshMemberDetails()
end	

		for i, name in pairs(MemberDetail.PageNames) do
			local tab = CreateFrame("Button", "GMRosterDetailFrameTab"..i, MemberDetail, "GuildRosterColumnButtonTemplate")
			tab:SetText(name)
			tab:SetSize(60, 22)
			WhoFrameColumn_SetWidth(tab, 60)
			if i == 1 then
				tab:SetPoint("TOPLEFT", MemberDetail, "TOPLEFT", 10, -10)
			else
				tab:SetPoint("LEFT", MemberDetail.Tabs[i-1], "RIGHT")
			end
			tab:SetScript("OnClick", MemberDetailTabClicked)
			tinsert(MemberDetail.Tabs, tab)
			tab.page = CreateFrame("Frame", nil, MemberDetail)
			tab.page:SetAllPoints(MemberDetail)
			tab.page:Hide()
			tab.page.name = name
			tinsert(MemberDetail.Pages, tab.page)
		end
		
	local GeneralLabels = {
												 NameLabel = {xs = 60, ys = 20, text = "Name:", xof = 15, yof = -40, color = {r = 1, g = 1, b = 0}},
												 NameText = {xs = 100, ys = 20, text = "Nametest", xof = 55, yof = -40, color = {r = 1, g = 1, b = 1}},
												 LevelLabel = {xs = 60, ys = 20, text = "Level:", xof = 15, yof = -60, color = {r = 1, g = 1, b = 0}},
												 LevelText = {xs = 60, ys = 20, text = "level", xof = 55, yof = -60, color = {r = 1, g = 1, b = 1}},
												 ClassLabel = {xs = 60, ys = 20, text = "Class:", xof = 15, yof = -80, color = {r = 1, g = 1, b = 0}},
												 ClassText = {xs = 60, ys = 20, text = "class", xof = 55, yof = -80, color = {r = 1, g = 1, b = 1}},
												 ZoneLabel = {xs = 60, ys = 20, text = "Zone:", xof = 15, yof = -100, color = {r = 1, g = 1, b = 0}},
												 ZoneText = {xs = 150, ys = 20, text = "zone", xof = 55, yof = -100, color = {r = 1, g = 1, b = 1}},
												 RankLabel = {xs = 60, ys = 20, text = "Rank:", xof = 15, yof = -120, color = {r = 1, g = 1, b = 0}},
												 NoteLabel = {xs = 130, ys = 20, text = "Public Note:", xof = 15, yof = -150, color = {r = 1, g = 1, b = 0}},
												 ONoteLabel = {xs = 130, ys = 20, text = "Officer Note:", xof = 15, yof = -230, color = {r = 1, g = 1, b = 0}},
												
													}
	local StatLabels = { RESLabel = {xs = 80, ys = 20, text = "Resilience:", xof = 15, yof = -40, color = {r = 1, g = 1, b = 0}},
											 RESText = {xs = 80, ys = 20, text = "Unkown", xof = 100, yof = -40, color = {r = 1, g = 1, b = 1}},
											 
											 HPLabel = {xs = 80, ys = 20, text = "Health:", xof = 15, yof = -60, color = {r = 1, g = 1, b = 0}},
											 HPText = {xs = 80, ys = 20, text = "Unkown", xof = 100, yof = -60, color = {r = 1, g = 1, b = 1}},
											 
											 SPLabel = {xs = 80, ys = 20, text = "Spell Power:", xof = 15, yof = -80, color = {r = 1, g = 1, b = 0}},
											 SPText = {xs = 80, ys = 20, text = "Unkown", xof = 100, yof = -80, color = {r = 1, g = 1, b = 1}},
											  
											 STRLabel = {xs = 80, ys = 20, text = "Strength:", xof = 15, yof = -100, color = {r = 1, g = 1, b = 0}},
											 STRText = {xs = 80, ys = 20, text = "Unkown", xof = 100, yof = -100, color = {r = 1, g = 1, b = 1}},
											  
											 AGILabel = {xs = 80, ys = 20, text = "Agility:", xof = 15, yof = -120, color = {r = 1, g = 1, b = 0}},
											 AGIText = {xs = 80, ys = 20, text = "Unkown", xof = 100, yof = -120, color = {r = 1, g = 1, b = 1}},
											  
											 STALabel = {xs = 80, ys = 20, text = "Stamina:", xof = 15, yof = -140, color = {r = 1, g = 1, b = 0}},
											 STAText = {xs = 80, ys = 20, text = "Unkown", xof = 100, yof = -140, color = {r = 1, g = 1, b = 1}},
											  
											 INTLabel = {xs = 80, ys = 20, text = "Intellect:", xof = 15, yof = -160, color = {r = 1, g = 1, b = 0}},
											 INTText = {xs = 80, ys = 20, text = "Unkown", xof = 100, yof = -160, color = {r = 1, g = 1, b = 1}},
											  
											 SPILabel = {xs = 80, ys = 20, text = "Spirit:", xof = 15, yof = -180, color = {r = 1, g = 1, b = 0}},
											 SPIText = {xs = 80, ys = 20, text = "Unkown", xof = 100, yof = -180, color = {r = 1, g = 1, b = 1}},
											 
											 ILVLLabel = {xs = 80, ys = 20, text = "Item Level:", xof = 15, yof = -180, color = {r = 1, g = 1, b = 0}},
											 ILVLText = {xs = 80, ys = 20, text = "Unkown", xof = 100, yof = -180, color = {r = 1, g = 1, b = 1}},
											 
											 
											}
	do -- page 1
		local tab = MemberDetail.Pages[1]
		for label, info in pairs(GeneralLabels) do
			tab[label] = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			tab[label]:SetSize(info.xs, info.ys)
			tab[label]:SetText(info.text)
			tab[label]:SetJustifyH("LEFT")
			tab[label]:SetTextColor(info.color.r, info.color.g, info.color.b)
			tab[label]:SetPoint("TOPLEFT", tab, "TOPLEFT", info.xof, info.yof)
		end
		
		tab.personal = CreateFrame("Frame", nil, tab)
		tab.personal:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
                                            edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
                                            tile = true, tileSize = 16, edgeSize = 16, 
                                            insets = { left = 4, right = 4, top = 4, bottom = 4 }});
		tab.personal:SetBackdropColor(0,0,0,1)
		tab.personal:SetHeight(60)
		tab.personal:SetPoint("TOP",0, -170)
		tab.personal:SetPoint("LEFT", 15,0)
		tab.personal:SetPoint("RIGHT", -15,0)
		
		tab.personalEB = CreateFrame("EditBox", "GMRosterPublicEB", tab.personal)
		tab.personalEB:SetPoint("TOPLEFT", 5, -5)
		tab.personalEB:SetPoint("BOTTOMRIGHT", -5,5)
		tab.personalEB:SetFont("Fonts\\FRIZQT__.TTF", 15)
		tab.personalEB:SetAutoFocus(false)
		tab.personalEB:SetMultiLine(true)
		tab.personalEB:SetScript("OnShow", function(self) self:SetTextColor(1,1,1) end)
		tab.personalEB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
		tab.personalEB:SetScript("OnEnterPressed", function(self) self:SetTextColor(1,1,1) GuildRosterSetPublicNote(GMRoster[MemberDetail.Selected].index, self:GetText()) end)
		tab.personalEB:SetScript("OnChar", function(self) self:SetTextColor(0, 1, 0) end)
		tab.personalEB:SetMaxLetters(31)
		
		tab.officer = CreateFrame("Frame", nil, tab)
		tab.officer:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
                                            edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
                                            tile = true, tileSize = 16, edgeSize = 16, 
                                            insets = { left = 4, right = 4, top = 4, bottom = 4 }});
		tab.officer:SetBackdropColor(0,0,0,1)
		tab.officer:SetHeight(60)
		tab.officer:SetPoint("TOP",0, -250)
		tab.officer:SetPoint("LEFT", 15,0)
		tab.officer:SetPoint("RIGHT", -15,0)
		
		
		tab.officerEB = CreateFrame("EditBox", "GMRosterPublicEB", tab.officer)
		tab.officerEB:SetPoint("TOPLEFT", 5, -5)
		tab.officerEB:SetPoint("BOTTOMRIGHT", -5,5)
		tab.officerEB:SetFont("Fonts\\FRIZQT__.TTF", 15)
		tab.officerEB:SetAutoFocus(false)
		tab.officerEB:SetMultiLine(true)
		tab.officerEB:SetScript("OnShow", function(self) self:SetTextColor(1,1,1) end)
		tab.officerEB:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
		tab.officerEB:SetScript("OnEnterPressed", function(self) self:SetTextColor(1,1,1) GuildRosterSetOfficerNote(GMRoster[MemberDetail.Selected].index, self:GetText()) end)
		tab.officerEB:SetScript("OnChar", function(self) self:SetTextColor(0, 1, 0) end)
		tab.officerEB:SetMaxLetters(31)
		
		GuildMemberRankDropdown:SetParent(tab)
		GuildMemberRankDropdown:ClearAllPoints()
		GuildMemberRankDropdown:SetPoint("TOPRIGHT", MemberDetail, "TOPRIGHT", -5, -120)
	end
	do --page 2
		local tab = MemberDetail.Pages[2]
		for label, info in pairs(StatLabels) do
			tab[label] = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			tab[label]:SetSize(info.xs, info.ys)
			tab[label]:SetText(info.text)
			tab[label]:SetJustifyH("LEFT")
			tab[label]:SetTextColor(info.color.r, info.color.g, info.color.b)
			tab[label]:SetPoint("TOPLEFT", tab, "TOPLEFT", info.xof, info.yof)
		end
	end
	do --page 3
		local page = MemberDetail.Pages[3]
		page.tabs = {}
		page.buttons = {}
		page.subtab = 1
			
		for i = 1, 3 do
			local tab = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
			tab:SetPoint("TOPLEFT", (i-1)*75+20, -40)
			tab:SetSize(65, 25)
			tab.i = i
			tab:SetScript("OnClick", function(self) page.subtab = self.i GMaster.RefreshMemberDetails() end)
			tinsert(page.tabs, tab)		
		end
		
			for j = 1, 4 do 
				for k = 1, 7 do
					local button = CreateFrame("Button", "GMRosterTalentButton"..j..k, page, "TalentButtonTemplate")
					button.column = j
					button.row = k
					button:SetSize(35, 35)
					button:SetPoint("TOPLEFT", page, "TOPLEFT", 40*j, -40*k - 30)
					button:SetScript("OnEnter", function(self) if self.name then GameTooltip:SetOwner(self, "ANCHOR_RIGHT") GameTooltip:SetText(self.name) end end)
					button:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
				_G[button:GetName().."NormalTexture"]:ClearAllPoints()
				_G[button:GetName().."NormalTexture"]:SetAllPoints(button)
				_G[button:GetName().."NormalTexture"]:SetDesaturated(true)
				_G[button:GetName().."Slot"]:Hide()
					tinsert(page.buttons, button)
				end
			end
	end

function GMaster.RefreshMemberDetails(name)
	if name then
		MemberDetail.Selected = name
	else
		name = MemberDetail.Selected
	end
	if not MemberDetail.CurrentPage then
		MemberDetail.Pages[1]:Show()
		MemberDetail.CurrentPage = 1
	end
	

	local player = GMRoster[name]

		MemberDetail.Pages[1].NameText:SetText(name)
		MemberDetail.Pages[1].LevelText:SetText(player.level)
		MemberDetail.Pages[1].ClassText:SetText(player.classname)
		MemberDetail.Pages[1].ZoneText:SetText(player.zone)
		
		
		
		if player.Note then
			MemberDetail.Pages[1].personalEB:SetText(player.Note)
		else
			MemberDetail.Pages[1].personalEB:SetText("")
		end
		
		if player.ONote and	CanViewOfficerNote() then
			MemberDetail.Pages[1].officerEB:SetText(player.ONote)
		else
			MemberDetail.Pages[1].officerEB:SetText("")
		end
		
		if CanEditPublicNote() then
			MemberDetail.Pages[1].personalEB:Enable()
		else
			MemberDetail.Pages[1].personalEB:Disable()
		end
		
		if CanEditOfficerNote() then
			MemberDetail.Pages[1].officerEB:Enable()
		else
			MemberDetail.Pages[1].officerEB:Disable()
		end
		
		MemberDetail.Pages[1].personalEB:SetTextColor(1,1,1)
		MemberDetail.Pages[1].officerEB:SetTextColor(1,1,1)
		
		do --page 2
			local Page2 = MemberDetail.Pages[2]
			local stats = {"RES", "HP", "SP", "STR", "AGI", "STA", "INT", "SPI", "ILVL" }
			if player.Stats then
				for i, st in pairs(stats) do
					local value = player.Stats:match(st.."(%d+)|")
					if value then
						Page2[st.."Text"]:SetText(value)
					else
						Page2[st.."Text"]:SetText("Unkown")
					end
				end
			else
				for i, st in pairs(stats) do
					Page2[st.."Text"]:SetText("Unkown")
				end
			end
		end
		
		local pg = MemberDetail.Pages[3]
		local cls = GMRoster[name].classname
		local i = 0
	for i, info in pairs(GMaster.TalentDB[cls]) do
		
		pg.tabs[i]:SetText(info.name)
		if i == pg.subtab then
			
			for _, button in pairs(pg.buttons) do
				
				button:Hide()
			
				_G[button:GetName().."Rank"]:SetText("0")
				_G[button:GetName().."Rank"]:Hide()
				_G[button:GetName().."RankBorder"]:Hide()
			end
		
			for k, but in pairs(info.data) do
				for j = 1, #pg.buttons do
					local button = pg.buttons[j]
					if button.row == but[3] and button.column == but[4] then
						button:SetNormalTexture(but[2])
						
						button.name = but[1]
						button:Show()
					end
				end
			end			
		end
	end	
	
	if player.Spec then
		local i = 0
		for spec in player.Spec:gmatch("||(%d+)") do
			i = i + 1
			if pg.subtab == i then
				for set in spec:gmatch("%d%d%d") do
					for row, column, value in set:gmatch("(%d)(%d)(%d)") do
						for i = 1, #pg.buttons do
							local button = pg.buttons[i]
							if button.column == tonumber(column) and button.row == tonumber(row) then
							local tex = button:GetNormalTexture()
								_G[button:GetName().."NormalTexture"]:SetDesaturated(false)
								if tonumber(value) > 0 then
								_G[button:GetName().."Rank"]:SetText(value)
								_G[button:GetName().."Rank"]:Show()
								_G[button:GetName().."RankBorder"]:Show()
								else
									_G[button:GetName().."NormalTexture"]:SetDesaturated(true)
								end
							end
						end
					end
				end
			end			
		end
	end
	--needs converting
	for i = 1, GetNumGuildMembers(true) do
		local n = GetGuildRosterInfo(i)
		if n == name then
			SetGuildRosterSelection(i)
		end
	end	
	UIDropDownMenu_SetText(GuildMemberRankDropdown, GuildControlGetRankName(GMRoster[name].rank+1));
	MemberDetail:Show()
end

function GuildMemberRankDropdown_OnClick(self, newRankIndex)
	local name, rank, rankIndex = GetGuildRosterInfo(GetGuildRosterSelection());
	SetGuildMemberRank(GetGuildRosterSelection(), newRankIndex);
	UIDropDownMenu_SetText(GuildMemberRankDropdown, GuildControlGetRankName(newRankIndex));
end

local function RosterButton_Clicked(self, button)
	local name = self.strings.Name:GetText()
	local player = GMRoster[name]
	if button == "LeftButton" then
		if player then
			if MemberDetail:IsShown() and MemberDetail.Selected == name then
				MemberDetail.Selected = ""
				MemberDetail:Hide()
			else
				GMaster.RefreshMemberDetails(name)
			end
		end
	else
		if player then
			FriendsFrame_ShowDropdown(name, GMRoster[name].online)
		end
	end
end

local function NewButton()
--create the button
local button = CreateFrame("Button", nil, RosterChild)
	button:EnableMouse(true)
--set its properties
	button:SetHeight(15)
	
	
	button.bg = button:CreateTexture(nil, "BACKGROUND")
	button.bg:SetTexture("Interface\\GuildFrame\\GuildFrame")
	button.bg:SetTexCoord(0.36230469,0.38183594,0.95898438,0.99804688)
	button.bg:SetAllPoints(button)
	
	button.strings = {}
	
	for name, value in pairs(list) do
		if type(value) == "table" then
			for name, v in pairs(value) do
				button.strings[name] = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
				button.strings[name]:SetPoint("TOP", button, "TOP")
				button.strings[name]:SetPoint("BOTTOM", button, "BOTTOM")
				button.strings[name]:SetJustifyH("LEFT")
			end
		else
			button.strings[name] = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			button.strings[name]:SetPoint("TOP", button, "TOP")
			button.strings[name]:SetPoint("BOTTOM", button, "BOTTOM")
			button.strings[name]:SetJustifyH("LEFT")

		end
	end
	
	button.icon = button:CreateTexture()
	button.icon:SetSize(15, 15)
	button.icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
	button.icon:SetPoint("TOP")
	
	button:SetPoint("LEFT", RosterChild, "LEFT", 5, 0)
	button:SetPoint("RIGHT", RosterChild, "RIGHT", -5, 0)
--set its location
	if #RosterButtons < 1 then
		button:SetPoint("TOP", RosterChild, "TOP", 0, -25)
	else
		button:SetPoint("TOP", RosterButtons[#RosterButtons], "BOTTOM")
	end
	button:SetScript("OnMouseUp", RosterButton_Clicked)
	tinsert(RosterButtons, button)
	RosterChild:SetHeight(#RosterButtons*20 + 30)
	return button
end

for i = 1, MAX_ROSTER_BUTTONS do
	NewButton()
end

local function ConvertLastSeen(name)
local lastseen = GMRoster[name].LastSeen
	if lastseen then
		if tonumber(lastseen) == 0 then
			return "Online"
		elseif lastseen == 1 then
			return "< an hour"
		else
			return date("%d/%m/%y", (time() -lastseen))
		end
	end
end

local convertlist = { Donations = {Donated = false, Looted = false, Repaired = false},
							Name = function(name) return name end,
							Rank = function(name) return GuildControlGetRankName(GMRoster[name].rank+1) end,
							Class = function(name) return GMRoster[name].classname end,
							Location = function(name) return GMRoster[name].zone end,
							Level = function(name) return GMRoster[name].level end,
							Note = function(name) return GMRoster[name].Note end,
							Chat = function(name) if RosterCache[name] then return RosterCache[name][3] or "0" else return 0 end end,
							LastSeen = ConvertLastSeen,
							Joined = function(name) return date("%x", GMRoster[name].firstseen) end,
							}

convertlist["Officer Note"] = function(name) return GMRoster[name].ONote end
convertlist["Weekly XP"] = function(name) return GMRoster[name]["Weekly XP"] end
convertlist["Weekly Rank"] = function(name) return GMRoster[name]["Weekly Rank"] end
convertlist["Total XP"] = function(name) return GMRoster[name]["Total XP"] end
convertlist["Total Rank"] = function(name) return GMRoster[name]["Total Rank"] end
convertlist["Achv Rank"] = function(name) return GMRoster[name]["Achv Rank"] end
convertlist["Achv Points"] = function(name) return GMRoster[name]["Achv Total"] end




function GMaster.UpdateRoster()
		--hide all buttons and child fontstrings
		for i = 1, #RosterButtons do
			local button = RosterButtons[i]
			for name, fontstring in pairs(button.strings) do
				fontstring:Hide()
			end
			button:Hide()
			button.icon:Hide()
		end

	for i = 1, #RosterButtons do
		local button = RosterButtons[i]
		local player = GMRoster[TempRoster[i+offset]]
		if player then
		button:Show()
		for name, fontstring in pairs(button.strings) do
			if RosterChild.TabNames[name] then
				fontstring:SetPoint("LEFT", RosterChild.TabNames[name],"LEFT", 3, 0)
				fontstring:SetPoint("RIGHT", RosterChild.TabNames[name],"RIGHT", -3, 0)
			
				if name == "Name" or name == "Class" then
					local color = RAID_CLASS_COLORS[strupper(player.class)]
					if player.online then
						fontstring:SetTextColor(color.r, color.g, color.b, 1)
					else
						fontstring:SetTextColor(color.r/1.5, color.g/1.5, color.b/1.5, 1)
					end
				else
					fontstring:SetTextColor(1, 1, 1, 1)
				end
				
				fontstring:SetParent(RosterChild.TabNames[name])
				fontstring:SetText(convertlist[name](TempRoster[i+offset]))
				
				fontstring:Show()
			end
		end
		if button.strings.Class:IsVisible() then
			if button.strings.Class:GetRight() - button.strings.Class:GetLeft() < 40 then
				button.strings.Class:Hide()
				button.icon:Show()
				button.icon:SetPoint("LEFT", RosterChild.TabNames.Class, "LEFT")
				local a,b,c,d = unpack(CLASS_ICON_TCOORDS[player.class])
				button.icon:SetTexCoord(a+0.01, b-0.01, c+0.01, d-0.01)
			else
				button.icon:Hide()
				button.strings.Class:Show()
			end
			
		end
		if not RosterChild.TabNames.Class then
			button.icon:Hide()
		end
		button:Show()
		end
	end
end

local function Sorter(a, b)
	
	--special conditions
	if SortBy == "Joined" then
		return GMRoster[a].firstseen > GMRoster[b].firstseen
	elseif SortBy == "-Joined" then
		return GMRoster[a].firstseen < GMRoster[b].firstseen
	elseif SortBy == "Rank" then
		return GMRoster[a].rank < GMRoster[b].rank
	elseif SortBy == "-Rank" then
		return GMRoster[a].rank > GMRoster[b].rank
	elseif SortBy == "Chat" then
		if RosterCache[a] and RosterCache[b] then
			return RosterCache[a][3] < RosterCache[b][3]
		else
			return false
		end
	elseif SortBy == "-Chat" then
		if RosterCache[a] and RosterCache[b] then
			return RosterCache[a][3] > RosterCache[b][3]
		else
			return false
		end
	end
	
	--general conditions
	local rev, test = SortBy:match("^(%-)(.+)")
	test = test or SortBy
	if convertlist[test] then
		if rev then
			return convertlist[test](a) > convertlist[test](b)
		else
			return convertlist[test](a) < convertlist[test](b)
		end
		return
	end
end

local function FilterResults(name, info, msg)
	for label, tab in pairs(RosterChild.TabNames) do
		local str = convertlist[label](name)
		if str then
			str = tostring(str)
			str = strlower(str)
			if str:match(msg) then
				tinsert(TempRoster,name)
				return
			end
		end
	end
	
end
	
local function RefreshSelection(reset)
	if not RosterFrame:IsVisible() then 
		return 
	end
	if reset then
		offset = 0
	end
	local msg = SearchBox:GetText()
	msg = strlower(msg)
	--need to select members who match the text in the box
	--potentially make it only apply to the tabs that are shown
	TempRoster = {}
	for name, info in pairs(GMRoster) do
		if (not msg) or (msg == " ") or (msg == "") then --if the searchbox is empty
			if info.online or GetGuildRosterShowOffline() then
				tinsert(TempRoster, name)
			end
		else --filter resutls based on text
			if info.online or GetGuildRosterShowOffline() then
				FilterResults(name, info, msg)
			end
		end
	end
	--sort the list

	if SortBy then
		table.sort(TempRoster, Sorter)
	end
	-- after sorting, need to add in alts
	
	--update the roster
	
	
	GMaster.UpdateRoster()
end
GMaster.RefreshRoster = RefreshSelection
SearchBox:SetScript("OnTextChanged", function() RefreshSelection(true) end)



local function Update_Tabs()
	local totalwidth = 0 
	for i, tab in pairs(RosterChild.Tabs) do
		tab:ClearAllPoints()
		if i ==1 then
			tab:SetPoint("TOPLEFT", RosterChild, "TOPLEFT")
		else
			tab:SetPoint("LEFT", RosterChild.Tabs[i-1], "RIGHT", 0, 0)
		end
		totalwidth = totalwidth + tab:GetWidth()
		tab.position = i
	end
	RosterChild:SetWidth(totalwidth)
end

local function Tab_Dragging(self, elapsed)
self.downtime = self.downtime + elapsed
	if self.downtime > 1  then
		if not self.dragging then
			self.dragging = true
			tremove(RosterChild.Tabs, self.position)
			tremove(Settings.TabLayout, self.position)
			self.width = self:GetWidth()
			self:SetWidth(50)
			WhoFrameColumn_SetWidth(self, 50)
			Update_Tabs()
		else
			self:ClearAllPoints()
			local r, l = RosterFrame:GetRight(),  RosterFrame:GetLeft() 
			local x, y = GetCursorPosition() 
			
			x = x/UIParent:GetEffectiveScale() 
				
			if x > l and x < r then
				self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, self.center)
			end
		end
	end	
end

local function Tab_Sizing(self)
	local r, l = self:GetRight(),  self:GetLeft() 
	local x, y = GetCursorPosition() 
	
	x = x/UIParent:GetEffectiveScale() 
		
		if x > (l+20) and x < (l+250) then
			self:SetWidth(x-l)
			WhoFrameColumn_SetWidth(self, (x-l))
			Settings.TabLayout[self.position].width = floor((x-l))
		end
end

local function Tab_MouseDown(self, button)
	if (button == "LeftButton") then
		self.downtime = 0
		self.dragging = nil
		local r, l = self:GetRight(),  self:GetLeft() 
		local x, y = GetCursorPosition() 
		_, self.center = self:GetCenter()
		x = x/UIParent:GetEffectiveScale()
		
		if x < (r) and x > (r-10) then
			self:SetScript("OnUpdate", Tab_Sizing)
			self.sizing = true
		else
			
			self:SetScript("OnUpdate", Tab_Dragging)
		end
	elseif button == "RightButton" then
		--show dropdown
		ToggleDropDownMenu(1, nil, RosterChild.Category, self, 30, 20)
	end
end

local function Tab_MouseUp(self, button)
	self:SetScript("OnUpdate", nil)
	if button == "LeftButton" then
		if self.sizing then
	
			self.sizing = nil
			self:SetScript("OnUpdate", nil)
		elseif self.dragging then
			self:SetScript("OnUpdate", nil)
			self:SetWidth(self.width)
			WhoFrameColumn_SetWidth(self, self.width)
			
			local center = self:GetCenter()
			local found 
			for i, tab in pairs(RosterChild.Tabs) do
				if tab == self then
					return
				end
				
				local tl, tr = tab:GetLeft(), tab:GetRight()
				local tc = tab:GetCenter()
				if center > tl and center < tc then
					tinsert(RosterChild.Tabs, tab.position, self)
					tinsert(Settings.TabLayout, tab.position, {label = self:GetText(), width = floor(self:GetWidth())})
					Update_Tabs()
					found = true
				elseif center > tc and center < tr then
					tinsert(RosterChild.Tabs, tab.position+1, self)
					tinsert(Settings.TabLayout, tab.position+1, {label = self:GetText(), width = floor(self:GetWidth())})
					Update_Tabs()
					found = true
				end
			end
			if not found then
				tinsert(RosterChild.Tabs, self)
				tinsert(Settings.TabLayout, {label = self:GetText(), width = floor(self:GetWidth())})
			end
		else
			if SortBy == self:GetText() then
				SortBy = "-"..self:GetText()
			else
				SortBy = self:GetText()
			end
			RefreshSelection(true)
		end
		Update_Tabs()	
	else
		self:StopMovingOrSizing()
	end
end



local TAB_HEIGHT = 20

local function NewTab(label)
	local tab = CreateFrame("Button", "GMRosterTab"..label, RosterChild, "GuildRosterColumnButtonTemplate")

	tab:SetScript("OnClick",nil) --remove the preset
	tab:SetMovable(true)
	tab:SetResizable(true)
	tab:SetScript("OnMouseDown", Tab_MouseDown) --need to add sorting by tab
	tab:SetScript("OnMouseUp", Tab_MouseUp)
	
	tab:SetSize(60, TAB_HEIGHT)
	_G[tab:GetName().."Left"]:SetHeight(TAB_HEIGHT)
	_G[tab:GetName().."Middle"]:SetHeight(TAB_HEIGHT)
	_G[tab:GetName().."Right"]:SetHeight(TAB_HEIGHT)
	WhoFrameColumn_SetWidth(tab, 60)
	local fs = tab:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	
	fs:SetPoint("TOPLEFT", tab, "TOPLEFT", 3, 0)
	fs:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -3, 0)
	fs:SetJustifyH("LEFT")
	fs:SetJustifyV("MIDDLE")
	tab:SetFontString(fs)
	return tab
end 




local function Roster_Shown(self)
	
end

RosterFrame:SetScript("OnShow", Roster_Shown)


local function DropDown_Clicked(self, label, value)
	local tab = RosterChild.TabNames[label]
	if value then --the tab is shown
		if tab and tab:IsShown() then
			tab:Hide()
			tremove(RosterChild.Tabs, tab.position)	
			tremove(Settings.TabLayout, tab.position)
			
		end			
	else --tab isnt shown, needs to be shown or created.
		if not tab then
			tab = NewTab(label)
			RosterChild.TabNames[label] = tab
			tab:SetText(label)
			tab:Show()
			tab.position = #RosterChild.Tabs + 1
			tinsert(RosterChild.Tabs, tab)
			if not Settings.TabLayout[tab.position] then
				tinsert(Settings.TabLayout, tab.position, {label = label, width = 60})
			end
			RefreshSelection()
		end	
		if not tab:IsShown() then
			tab:Show()
			tab.position = #RosterChild.Tabs + 1
			tinsert(RosterChild.Tabs, tab)
			if not Settings.TabLayout[tab.position] then
				tinsert(Settings.TabLayout, tab.position, {label = label, width = 60})
			end
		end
		
	end		
	Update_Tabs()
end


RosterChild.Category = CreateFrame("Frame", "GMRosterDD", AskFrame, "UIDropDownMenuTemplate")

	UIDropDownMenu_SetWidth(RosterChild.Category, 60)
	UIDropDownMenu_SetButtonWidth(RosterChild.Category, 50)

	function RosterChild.Category_Initialize(self, level)
		level = level or 1
		local info = UIDropDownMenu_CreateInfo()
		local value = UIDROPDOWNMENU_MENU_VALUE
		
		info.isNotRadio = true
		for label, v in pairs(list) do
			if not (label == "Officer Note" and not CanViewOfficerNote()) then
			
			if type(v) == "table" then
				if level == 1 then
					info = UIDropDownMenu_CreateInfo()
					info.isNotRadio = true
					info.notCheckable = true
					info.hasArrow = true
					info.text = label
					info.value = label
					info.func =  function(self) end

					UIDropDownMenu_AddButton(info, level)
				elseif level == 2 and value == label then	
									
					for label2, v2 in pairs(v) do
						info = UIDropDownMenu_CreateInfo()
						info.isNotRadio = true
						info.text = label2
						info.value = label2
						info.checked = v2
						info.func =  function(self) list[label][label2] = not v2 DropDown_Clicked(self, label2, v2) end
						UIDropDownMenu_AddButton(info, level)				
					
					end
				end
			else
				if level == 1 then
				info = UIDropDownMenu_CreateInfo()
				info.isNotRadio = true
				info.text = label
				info.value = label
				info.checked = v
				info.func =  function(self) list[label] = not v DropDown_Clicked(self, label, v) end
				UIDropDownMenu_AddButton(info, level)
				end
			end
			end
		end
	end
UIDropDownMenu_Initialize(RosterChild.Category, RosterChild.Category_Initialize, "MENU")
	--UIDropDownMenu_SetText(RosterChild.Category, 0, true)



--this needs to be made dynamic
DropDown_Clicked(nil, "Name", false)

list.Name = true


for i, info in pairs(Settings.TabLayout) do
	
	if not list[info.label] == true then
		DropDown_Clicked(nil, info.label, false)
	end
	for name, value in pairs(list) do
		if type(value) == "table" then
			if value[info.label] == false then
				list[name][info.label] = true
			end
		else
			if name == info.label then
				list[info.label] = true
			end
		end
	end
	
	RosterChild.TabNames[info.label]:SetWidth(info.width)
		WhoFrameColumn_SetWidth(RosterChild.TabNames[info.label], info.width)
end
Update_Tabs()
--===========================================================================================


		local function EditRosterDD(self)
			if self == FriendsDropDown then
					local info = UIDropDownMenu_CreateInfo();
				if CanGuildPromote() then
					info.text = "Promote"
					info.func = function() GuildPromote(self.name) end
					info.notCheckable = true
					UIDropDownMenu_AddButton(info);
					
					info.text = "Demote"
					info.func = function() GuildDemote(self.name) end
					info.notCheckable = true
					UIDropDownMenu_AddButton(info);
				end
				if CanGuildRemove() then
					info.text = "Remove"
					info.func = function() GuildUninvite(self.name) end
					info.notCheckable = true
					UIDropDownMenu_AddButton(info);
				end
			end
		end
			
	hooksecurefunc("UIDropDownMenu_Initialize", EditRosterDD)

--===========================================================================================
	
	local function GuildTabButtonClicked(self)
		local tabIndex = self:GetID();
		if tabIndex == 2 then
			if Settings.active then
				GuildRosterFrame:Hide()
				GuildFrameInset:SetPoint("TOPLEFT", 3, -78);
				GuildFrameInset:SetPoint("BOTTOMRIGHT", -5, 4);
				
				RefreshSelection(true)
				RosterFrame:Show()
				GuildRosterShowOfflineButton:SetParent(GuildFrame)
			end
		else
			GuildRosterShowOfflineButton:SetParent(GuildRosterFrame)
			RosterFrame:Hide()
		end
	end
	
	hooksecurefunc("GuildFrame_TabClicked", GuildTabButtonClicked)
	GuildRosterShowOfflineButton:HookScript("OnClick", RefreshSelection)
	
--end -- end of GFL
	
	
--if GMaster.LastLogin < (time() - 3600) then
	local msg = ""
	msg = msg.."RES"..GetCombatRating(COMBAT_RATING_RESILIENCE_PLAYER_DAMAGE_TAKEN).."|"
	msg = msg.."HP"..UnitHealthMax("player").."|"
	msg = msg.."SP"..GetSpellBonusHealing().."|"
	msg = msg.."STR"..UnitStat("player", 1).."|"
	msg = msg.."AGI"..UnitStat("player", 2).."|"
	msg = msg.."STA"..UnitStat("player", 3).."|"
	msg = msg.."INT"..UnitStat("player", 4).."|"
	msg = msg.."SPI"..UnitStat("player", 5).."|"
	msg = msg.."ILVL"..floor(GetAverageItemLevel()).."|"
	GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMRosStat", msg}
--end
	
		
--[[
	stats needed
	health - UnitHealthMax("player")
	mana - powerType, powerTypeString = UnitPowerType(UnitId);
	item level - floor(GetAverageItemLevel())
	

	
	hit chance - GetCombatRatingBonus
	
	
--]]


local function SendSpec()
	local test = ""
	for t=1, GetNumTalentTabs() do
		test = test.."||"
		 for i=1, GetNumTalents(t) do
				nameTalent, icon, row, column, currRank, maxRank= GetTalentInfo(t,i);
				test = test..row..column..currRank
		 end
	end
	GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMRosTal", test}
end

function GMaster.CMA.GMRoster(prefix, msg, channel, player)
	if prefix == "GMRosTal" then
		if GMRoster[player] then
			GMRoster[player].Spec = msg			
		end
	elseif prefix == "GMRosStat" then
		GMRoster[player].Stats = msg
	end
end

GMTimer:NewTimer(10, SendSpec)

end
end



--===========================================================================================
--===========================================================================================
--===========================================================================================
--===========================================================================================
--===========================================================================================
--===========================================================================================
--===========================================================================================




local function UpdateCache()
GMaster.Debug("Updating cache")
RosterCache = {}

	for dated,players in pairs(GMLogs) do
		for name, info in pairs(players) do
			if name ~= "LastRecord" then
				if RosterCache[name] then --if the name is already in the cache
					for i = 1, #info do
						if i > 9 and i < 16 then --if its a top score
							if RosterCache[name][i] then
								if info[i] > RosterCache[name][i] then --if its higher 
									RosterCache[name][i] = 0 + info[i] --replace it
								end
							else
								RosterCache[name][i] = 0 + info[i]
							end
						else -- add it to the previous numbers
							if RosterCache[name][i] then
								RosterCache[name][i] = RosterCache[name][i] + info[i]
							else
								RosterCache[name][i] = 0 +info[i]
							end
						end
					end
				else
					RosterCache[name]  = {unpack(info)}
				end	
			end
		end
	end
end

--===========================================================================================



	local firstrun = true
	
	local cachecount = 0
	
function GMaster.RosterUpdate() --need to merge the two parts of this function to reduce the number of calls to GetGuildRosterInfo(i)
	 --[[
		It seems that the roster event is called multiple times upon first log in, 
		sometimes when the guild roster is not yet readable
		
		new method:
		set up some temp tables to track changes
		report them once the correct number of guildies is seen
	 --]]
	 
	
	 if not GMSettings.modules.GMRoster.active then
		return
	 end
	 
	 if cachecount > 9 then
		cachecount = 1
		UpdateCache()
	 end
	 cachecount = cachecount + 1
	 
	 for i = 1, GetNumGuildMembers(true) do
			local name, rank, rankIndex, level, class, zone, note, onote, online, _, classFileName, achiPoint, achiRank=  GetGuildRosterInfo(i)
			local year, month, day, hour = GetGuildRosterLastOnline(i)
			local weeklyXP, totalXP, weeklyRank, totalRank = GetGuildRosterContribution(i);
				--ViewGuildRecipes(skillID)
				
			if name then
				tracker.names[name] = true
				local player = GMRoster[name]
				if player then -- they have already been seen 
					if rankIndex > player.rank then
						tinsert(tracker.promoted, {name = name, oldrank = player.rank, newrank = rankIndex})
					elseif rankIndex < player.rank then
						tinsert(tracker.demoted, name)
					end
					if level > player.level then
						tinsert(tracker.levelled, {name = name, oldlevel = player.level, newlevel = level})
					end
				else
					tinsert(tracker.joined, name)
					GMRoster[name] = {class = classFileName, level = level, rank = rankIndex, online = online, Alts = {}}
					player = GMRoster[name]
				end	
				
				player.online = online

				if not online then --needs removing/moving to locator b
					player.zx = nil
					player.zy = nil
					player.cx = nil
					player.cy = nil
					player.zcont = nil
					player.zzone = nil
					player.ccont = nil
					player.czone = nil
				end
				player.index = i
				player.Note = note or ""
				player.ONote = onote or ""
				player.rank = rankIndex
				player.level = level
				player.zone = zone or ""
				
				player["Achv Rank"] = achiPoint 
				player["Achv Total"] = achiRank
				
				player["Weekly XP"] = weeklyXP
				player["Total XP"] = totalXP
				player["Weekly Rank"] = weeklyRank
				player["Total Rank"] = totalRank
				
				if hour then
					local val = ((((year*12)+month)*30.5+day)*24+hour)*3600
					if val > 0 then
						player.LastSeen = val
					else
						player.LastSeen = 1
					end
				else
					player.LastSeen = 0
				end
				
				
				if not player.firstseen then
					player.firstseen = time()
				end
				
				player.class = classFileName
				player.classname = class
			end
	 end

	local function PrintChanges()
		if firstrun then
			if tracker.names ~= {} then
				for name, info in pairs(GMRoster) do --check who has left the guild
					if not tracker.names[name] then
						tinsert(tracker.quit, name)
						GMRoster[name] = nil
					end
				end
				
				local msg 
				local count = 0
				for i = 1, #tracker.joined do
					if i == 1 then
						msg = tracker.joined[i]
						count = count + 1
					elseif i == #tracker.joined then
						msg = msg.." and "..tracker.joined[i]
						count = count + 1
					else
						msg = msg..", "..tracker.joined[i]
						count = count + 1
					end
				end
					
				if	count == 1 then
					print(msg.." has joined the guild")
				elseif count > 1 then
					print(msg.." have joined the guild")
				end
					
				msg = ""
				count = 0
				
				for i = 1, #tracker.quit do
					if i == 1 then
						msg = tracker.quit[i]
						count = count + 1
					elseif i == #tracker.quit then
						msg = msg.." and "..tracker.quit[i]
						count = count+1
					else
						msg = msg..", "..tracker.quit[i]
						count = count + 1
					end
				end
					
				if count == 1 then
					print(msg.." has left the guild")
				elseif count > 1 then
					print(msg.." have left the guild")
				end
					
				firstrun = nil
			end
		end
	end
	GMTimer:NewTimer(30, PrintChanges)
	if GMaster.RefreshRoster then
			GMaster.RefreshRoster(nil)
	end
end




function GMaster.ModuleSettings.GMRoster()
	if not module.settings then

		local parent = CreateFrame("Frame")
				parent.titleText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				parent.titleText:SetPoint("TOPLEFT", parent, "TOPLEFT", 30, -40)
				parent.titleText:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -30, 40)
				parent.titleText:SetJustifyH("LEFT")
				parent.titleText:SetJustifyV("TOP")
				parent.titleText:SetText("GM-Roster adds a search bar to the guild roster and adds extra stats to the guild member detail frame"..
																	", including talents and gear")
		module.settings = parent
	end
return module.settings

end

function GMaster.ModuleLoad.GMRoster()
	
	GMaster.AL.GMRoster()
	
	if GMaster.GUILD_FRAME_LOADED then
		GMaster.GFL.GMRoster()
	else
		LoadAddOn("Blizzard_GuildUI")
	end
	--create settings page
	
	
end

function GMaster.ModuleRemove.GMRoster()
	
	return true
end



