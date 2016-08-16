--[[
1. Summary
2. Details
3. Structure
4. Changes
5. To Do

--========================== 1. Summary ===============================
	Auto create guild events with filters for level, role, and gear.
--========================== 2. Details ===============================
	Adds a button to the guild frame which allows any guild member to create a custom event.
	Options for the name of the event, the roles required, a minimum level, resilience, or item level.
	Sends the invite to any player who matches the criteria, and isnt busy (raiding/arena/etc)
	
--========================== 3. Structure =============================
	
--========================== 4. Changes ===============================


1.47
	-Added option to select minimum resilience, level, and item level.
	-Added a status window showing which players have been invited, etc.
	-Declining an event will automatically decline all events for the next 15 minutes
--========================== 5. To do =================================
	Priority: Low
	Add broadcast event to record who started the event, and who joined it 
	check recording of event start and attendance.
	option to choose from previous event
	make the list of replies scrollable.
--]]


GMaster.LoadOrder.GMEvent = true

local module = {}

function GMaster.AL.GMEvent()
	local IsLeader = nil
	local tempdisable = false
	
	local Queue = {}

	local AskFrame = CreateFrame("Frame", nil, UIParent)
	AskFrame.page = 1



	local function PartyCheck() --check this bit
		if GetNumRaidMembers() < 1 and GetNumPartyMembers() < 1 then
			IsLeader = nil 
			AskFrame.event = nil
			AskFrame.numheal = nil
			AskFrame.numdps = nil
			AskFrame.numtank = nil
			AskFrame.healcount = 0
			AskFrame.dpscount = 0
			AskFrame.tankcount = 0
			AskFrame.minres = nil
			--reset and event stuff
		end
	end


	local test = CreateFrame("Frame")
	test:RegisterEvent("PARTY_MEMBERS_CHANGED")

	AskFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
												edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
												tile = true, tileSize = 16, edgeSize = 16, 
												insets = { left = 4, right = 4, top = 4, bottom = 4 }})
	AskFrame:SetBackdropColor(0,0,0,1);
	AskFrame:Hide()
	AskFrame.TitleText = AskFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	AskFrame.TitleText:CanWordWrap(true)
	AskFrame.TitleText:SetJustifyV("TOP")
	AskFrame.TitleText:SetPoint("LEFT", AskFrame, "LEFT", 40, 0)
	AskFrame.TitleText:SetPoint("RIGHT", AskFrame, "RIGHT", -40, 0)
	AskFrame.TitleText:SetHeight(50)
	AskFrame.TitleText:SetPoint("TOP", AskFrame, "TOP", 0, -20)
	AskFrame.TitleText:SetText("Would you like to queue for premades?")

	AskFrame.EditBox = CreateFrame("EditBox", "GMEventEB", AskFrame, "InputBoxTemplate")
	AskFrame.EditBox:SetWidth(350)
	AskFrame.EditBox:SetHeight(25)
	AskFrame.EditBox:SetScript("OnEscapePressed", function(self) AskFrame:Hide() SendAddonMessage("GMEventBusy", "Reason: Closed", "GUILD") end)


	AskFrame.LevelBox = CreateFrame("EditBox", "GMEventLevelB", AskFrame, "InputBoxTemplate")
	AskFrame.LevelBox:SetWidth(100)
	AskFrame.LevelBox:SetHeight(25)
	AskFrame.LevelBox:SetScript("OnEscapePressed", function(self) AskFrame:Hide() end)
	
	
	AskFrame.iLevelBox = CreateFrame("EditBox", "GMEventiLevelB", AskFrame, "InputBoxTemplate")
	AskFrame.iLevelBox:SetWidth(100)
	AskFrame.iLevelBox:SetHeight(25)
	AskFrame.iLevelBox:SetScript("OnEscapePressed", function(self) AskFrame:Hide() end)
	
	
	AskFrame.RessiBox = CreateFrame("EditBox", "GMEventRessiB", AskFrame, "InputBoxTemplate")
	AskFrame.RessiBox:SetWidth(100)
	AskFrame.RessiBox:SetHeight(25)
	AskFrame.RessiBox:SetScript("OnEscapePressed", function(self) AskFrame:Hide() end)
	

	AskFrame.Heal = CreateFrame("Button", nil, AskFrame)
	AskFrame.Heal:SetWidth(100)
	AskFrame.Heal:SetHeight(100)
	AskFrame.HealBg = AskFrame.Heal:CreateTexture()
	AskFrame.HealBg:SetTexture("Interface\\LFGFrame\\UI-LFG-ICONS-RoleBACKGROUNDS")
	AskFrame.HealBg:SetTexCoord(GetBackgroundTexCoordsForRole("HEALER"))
	AskFrame.HealBg:SetAllPoints(AskFrame.Heal)
	AskFrame.HealBg:SetDrawLayer("BACKGROUND")
	AskFrame.HealIcon = AskFrame.Heal:CreateTexture()
	AskFrame.HealIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-RoleS")
	AskFrame.HealIcon:SetTexCoord(GetTexCoordsForRole("HEALER"))
	AskFrame.HealIcon:SetPoint("TOPLEFT", AskFrame.Heal, "TOPLEFT", 15, -15)
	AskFrame.HealIcon:SetPoint("BOTTOMRIGHT", AskFrame.Heal, "BOTTOMRIGHT", -15,15)
	AskFrame.Heal:Hide()

	AskFrame.Dps = CreateFrame("Button", nil, AskFrame)
	AskFrame.Dps:SetWidth(100)
	AskFrame.Dps:SetHeight(100)
	AskFrame.DpsBg = AskFrame.Dps:CreateTexture()
	AskFrame.DpsBg:SetTexture("Interface\\LFGFrame\\UI-LFG-ICONS-RoleBACKGROUNDS")
	AskFrame.DpsBg:SetTexCoord(GetBackgroundTexCoordsForRole("DAMAGER"))
	AskFrame.DpsBg:SetAllPoints(AskFrame.Dps)
	AskFrame.DpsBg:SetDrawLayer("BACKGROUND")
	AskFrame.DpsIcon = AskFrame.Dps:CreateTexture()
	AskFrame.DpsIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-RoleS")
	AskFrame.DpsIcon:SetTexCoord(GetTexCoordsForRole("DAMAGER"))
	AskFrame.DpsIcon:SetPoint("TOPLEFT", AskFrame.Dps, "TOPLEFT", 15, -15)
	AskFrame.DpsIcon:SetPoint("BOTTOMRIGHT", AskFrame.Dps, "BOTTOMRIGHT", -15,15)
	AskFrame.Dps:Hide()

	AskFrame.Tank = CreateFrame("Button", nil, AskFrame)
	AskFrame.Tank:SetWidth(100)
	AskFrame.Tank:SetHeight(100)
	AskFrame.TankBg = AskFrame.Tank:CreateTexture()
	AskFrame.TankBg:SetTexture("Interface\\LFGFrame\\UI-LFG-ICONS-RoleBACKGROUNDS")
	AskFrame.TankBg:SetTexCoord(GetBackgroundTexCoordsForRole("TANK"))
	AskFrame.TankBg:SetAllPoints(AskFrame.Tank)
	AskFrame.TankBg:SetDrawLayer("BACKGROUND")
	AskFrame.TankIcon = AskFrame.Tank:CreateTexture()
	AskFrame.TankIcon:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-RoleS")
	AskFrame.TankIcon:SetTexCoord(GetTexCoordsForRole("TANK"))
	AskFrame.TankIcon:SetPoint("TOPLEFT", AskFrame.Tank, "TOPLEFT", 15, -15)
	AskFrame.TankIcon:SetPoint("BOTTOMRIGHT", AskFrame.Tank, "BOTTOMRIGHT", -15,15)
	AskFrame.Tank:Hide()

	AskFrame.YesButton = CreateFrame("Button", nil, AskFrame, "UIPanelButtonTemplate")
	AskFrame.YesButton:SetWidth(50)
	AskFrame.YesButton:SetHeight(30)
	AskFrame.YesButton:SetText("Yes")
	AskFrame.YesButton:SetPoint("BOTTOMLEFT", AskFrame, "BOTTOMLEFT", 60, 20)

	AskFrame.NoButton = CreateFrame("Button", nil, AskFrame, "UIPanelButtonTemplate")
	AskFrame.NoButton:SetWidth(50)
	AskFrame.NoButton:SetHeight(30)
	AskFrame.NoButton:SetText("No")

	AskFrame.DDHeal = CreateFrame("Frame", "GMEventHealDD", AskFrame, "UIDropDownMenuTemplate")
	AskFrame.DDHeal:SetPoint("BOTTOMLEFT", AskFrame, "BOTTOMLEFT", 60, 60)
	UIDropDownMenu_SetWidth(AskFrame.DDHeal, 60)
	UIDropDownMenu_SetButtonWidth(AskFrame.DDHeal, 50)

	AskFrame.CheckBox = CreateFrame("CheckButton", "GMEventCheckButton", AskFrame, "ChatConfigCheckButtonTemplate");
	AskFrame.CheckBox:SetSize(25, 25)

	AskFrame.ListFrame = CreateFrame("Frame", nil, AskFrame)
	AskFrame.ListFrame:SetAllPoints(AskFrame)
	AskFrame.List = {}
	
	local parent

	for i = 1, 10 do
		local button = CreateFrame("Button", "GMEventListbutton"..i, AskFrame.ListFrame, "WorldStateScoreTemplate")
		tinsert(AskFrame.List, button)
		button:SetPoint("LEFT", AskFrame.ListFrame, "LEFT", 15, 0)
		button:SetPoint("RIGHT", AskFrame.ListFrame, "RIGHT", -15, 0)
	
		if parent then
			parent = _G["GMEventListbutton"..(i-1)]
			button:SetPoint("TOP", parent, "BOTTOM", 0, -1)
		else
			button:SetPoint("TOP", AskFrame.ListFrame, "TOP", 0, -40)
			parent = button
		end
		local textureLeft = _G["GMEventListbutton"..i.."FactionLeft"]
		local textureRight = _G["GMEventListbutton"..i.."FactionRight"]
		textureLeft:SetAlpha(0.3)
		textureRight:SetAlpha(0.3)
		
		button.texts = {}
		button.texts[#button.texts+1] = button.name.text
		button.texts[#button.texts+1] = _G[button:GetName().."Column2Text"] 
		button.texts[#button.texts+1] = button.killlingBlows
		button.texts[#button.texts+1] = button.damage
		button.texts[#button.texts+1] = button.healing
		button.texts[#button.texts+1] = button.honorableKills
		button.texts[#button.texts+1] = _G[button:GetName().."Column1Text"]
		button.texts[#button.texts+1] = button.deaths
	
		button.texts[1]:SetText("Name "..i)
		--button:SetScript("OnMouseWheel", function(self, delta) delta = delta*16 Scroller:SetVerticalScroll(Scroller:GetVerticalScroll() + delta) GMInfoFrame_Update()  end)
			
		--button:SetScript("OnClick", function(self) if self:IsShown() then if GraphFrame:IsShown() then else GraphFrame:Show() GraphFrame.name = button.texts[1]:GetText() Graph_Update(GraphFrame.name) end end end)
				--button:Hide()
	end
	
	local offset = 0
	
	local function UpdateList()
		for i = 1, 10 do
			AskFrame.List[i]:Hide()
		end
		local j = 0
		for name, status in pairs(Queue) do
			j = j + 1
			local button = AskFrame.List[j]
			if button then
				button.texts[1]:SetText(name)
				button.texts[2]:SetText(status)
			
				button:Show()
			end

			if GMRoster[name] then
				local class = GMRoster[name].class
				local classColor = RAID_CLASS_COLORS[class];
				if classColor then
					button.texts[1]:SetTextColor(classColor.r, classColor.g, classColor.b);
				end
			end
			
			if status == "Pending" then
				button.texts[2]:SetTextColor(0, 0.7, 0)
			elseif status == "Invited" then
				button.texts[2]:SetTextColor(0, 1, 0)
			elseif status:find("^Decline") then
				button.texts[2]:SetTextColor(0.8, 0, 0)
			end
		end
	end
	
	
	
	local ListFrame = CreateFrame("Frame", nil, UIParent) --container for the list

	for i = 1, 6 do --create buttons for the ist frame


	end


	function AskFrame.DDHeal_Initialize(self, level)
		level = level or 1
		local info = UIDropDownMenu_CreateInfo()
		for i = 0, 10 do
			info = UIDropDownMenu_CreateInfo()
			info.notCheckable = true
			info.text = i
			info.value = i
			info.checked = nil
			info.func =  function(self) UIDropDownMenu_SetText(AskFrame.DDHeal, i)  end
			UIDropDownMenu_AddButton(info, level)
		end
	end

	UIDropDownMenu_Initialize(AskFrame.DDHeal, AskFrame.DDHeal_Initialize)
	UIDropDownMenu_SetText(AskFrame.DDHeal, 0, true)

	AskFrame.DDDps = CreateFrame("Frame", "GMEventDpsDD", AskFrame, "UIDropDownMenuTemplate")
	AskFrame.DDDps:SetPoint("TOPLEFT", AskFrame.DDHeal, "TOPRIGHT", 30, 0)
	UIDropDownMenu_SetWidth(AskFrame.DDDps, 60)
	UIDropDownMenu_SetButtonWidth(AskFrame.DDDps, 50)

	function AskFrame.DDDps_Initialize(self, level)
		level = 1
		local info = UIDropDownMenu_CreateInfo()
		for i = 0, 30 do
			info = UIDropDownMenu_CreateInfo()
			info.notCheckable = true
			info.text = i
			info.value = i
			info.checked = nil
			info.func =  function(self) UIDropDownMenu_SetText(AskFrame.DDDps, self.value, true)  end
			UIDropDownMenu_AddButton(info, level)
		end
	end
	UIDropDownMenu_Initialize(AskFrame.DDDps, AskFrame.DDDps_Initialize)
	UIDropDownMenu_SetText(AskFrame.DDDps, 0, true)

	AskFrame.DDTank = CreateFrame("Frame", "GMEventTankDD", AskFrame, "UIDropDownMenuTemplate")
	AskFrame.DDTank:SetPoint("TOPLEFT", AskFrame.DDDps, "TOPRIGHT", 30, 0)
	UIDropDownMenu_SetWidth(AskFrame.DDTank, 60)
	UIDropDownMenu_SetButtonWidth(AskFrame.DDTank, 50)

	function AskFrame.DDTank_Initialize()
		level = 1
		local info = UIDropDownMenu_CreateInfo()
		for i = 0, 5 do
			info = UIDropDownMenu_CreateInfo()
			info.notCheckable = true
			info.text = i
			info.value = i
			info.checked = nil
			info.func =  function(self) UIDropDownMenu_SetText(AskFrame.DDTank, self.value, true)  end
			UIDropDownMenu_AddButton(info, level)
		end
	end
	UIDropDownMenu_Initialize(AskFrame.DDTank, AskFrame.DDTank_Initialize)
	UIDropDownMenu_SetText(AskFrame.DDTank, 0, true)




	local function RoleButtonClick(self)
		if AskFrame.page == 1 then
			local value = UIDropDownMenu_GetText(AskFrame["DD"..self.name])
			UIDropDownMenu_SetText(AskFrame["DD"..self.name], value+1, true)
		elseif AskFrame.page == 2 then
			GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMEventAccept", "|ROLE|"..self.name}
			tinsert(GMaster.Timers, {runonce = true, interval = 5, elapsed = 0, func = AcceptGroup})
			tinsert(GMaster.Timers, {runonce = true, interval = 5.5, elapsed = 0, func = function() StaticPopup1:Hide() end})
			AskFrame:Hide()
		end
	end

	AskFrame.Heal.name = "Heal"
	AskFrame.Dps.name = "Dps"
	AskFrame.Tank.name = "Tank"



	local function SetAskFrame(page)
		if page == 1 then -- this is the page to create new events
			AskFrame.ListFrame:Hide()
		
			AskFrame:SetWidth(450)
			AskFrame:SetHeight(225)
			AskFrame:ClearAllPoints()
			AskFrame:SetPoint("CENTER")
			AskFrame.DDHeal:Show()
			AskFrame.DDDps:Show()
			AskFrame.DDTank:Show()
			-- if isingroup() then
			--	AskFrane.TitleText:SetText("You are currently grouped. To add more members, select the extra roles you need and click invite")
			--end
			AskFrame.TitleText:SetText("To create a new event, give it a meaningful name, choose the number of players required for each role, and press 'Invite.'")
			AskFrame.YesButton:SetText("Invite")
			AskFrame.YesButton:SetWidth(80)
			AskFrame.YesButton:SetPoint("BOTTOMLEFT", 140, 10)
			AskFrame.YesButton:Show()
			
			AskFrame.NoButton:Show()
			AskFrame.NoButton:SetText("Cancel")
			AskFrame.NoButton:ClearAllPoints()
			AskFrame.NoButton:SetPoint("TOPLEFT", AskFrame.YesButton, "TOPRIGHT", 5, 0)
			AskFrame.NoButton:SetWidth(80)
			
			AskFrame.EditBox:SetPoint("TOPLEFT", 55, -60)
			AskFrame.EditBox:Show()
			AskFrame.EditBox:SetText("[Type Event Name Here]")

			AskFrame.LevelBox:SetPoint("TOPLEFT", 30, -90)
			AskFrame.LevelBox:SetText("[Min Level]")
			AskFrame.LevelBox:Show()
			
			AskFrame.iLevelBox:SetPoint("TOPLEFT", 180, -90)
			AskFrame.iLevelBox:SetText("[Min item Lvl]")
			AskFrame.iLevelBox:Show()
			
			AskFrame.RessiBox:SetPoint("TOPLEFT", 320, -90)
			AskFrame.RessiBox:SetText("[Min Resi]")
			AskFrame.RessiBox:Show()
			
			AskFrame.Dps:SetSize(64, 64)
			AskFrame.Dps:ClearAllPoints()
			AskFrame.Dps:SetPoint("TOPRIGHT", AskFrame.DDDps, "TOPLEFT", 20, 20)
			AskFrame.DpsIcon:SetPoint("TOPLEFT", AskFrame.Dps, "TOPLEFT", 12, -12)
			AskFrame.DpsIcon:SetPoint("BOTTOMRIGHT", AskFrame.Dps, "BOTTOMRIGHT", -8,8)
			AskFrame.Dps:Show()
			
			AskFrame.Heal:SetSize(64, 64)
			AskFrame.Heal:ClearAllPoints()
			AskFrame.Heal:SetPoint("TOPRIGHT", AskFrame.DDHeal, "TOPLEFT", 20, 20)
			AskFrame.HealIcon:SetPoint("TOPLEFT", AskFrame.Heal, "TOPLEFT", 12, -12)
			AskFrame.HealIcon:SetPoint("BOTTOMRIGHT", AskFrame.Heal, "BOTTOMRIGHT", -8,8)
			AskFrame.Heal:Show()
			
			AskFrame.Tank:SetSize(64, 64)
			AskFrame.Tank:ClearAllPoints()
			AskFrame.Tank:SetPoint("TOPRIGHT", AskFrame.DDTank, "TOPLEFT", 20, 20)
			AskFrame.TankIcon:SetPoint("TOPLEFT", AskFrame.Tank, "TOPLEFT", 12, -12)
			AskFrame.TankIcon:SetPoint("BOTTOMRIGHT", AskFrame.Tank, "BOTTOMRIGHT", -8,8)
			AskFrame.Tank:Show()
		
			AskFrame.Heal:SetScript("OnClick", RoleButtonClick)
			AskFrame.Dps:SetScript("OnClick", RoleButtonClick)
			AskFrame.Tank:SetScript("OnClick", RoleButtonClick)
		
		elseif page == 2 then --this is the page to join new events
			AskFrame.ListFrame:Hide()
			AskFrame:SetSize(450, 200)
			AskFrame:ClearAllPoints()
			AskFrame:SetPoint("CENTER")
			AskFrame.TitleText:SetText((AskFrame.leader or "").." is starting an event: "..(AskFrame.event or "")..". \n Click your role or 'Decline' ")
			AskFrame.DDHeal:Hide()
			AskFrame.DDDps:Hide()
			AskFrame.DDTank:Hide()
			
			AskFrame.LevelBox:Hide()
			
			AskFrame.iLevelBox:Hide()
			
			AskFrame.RessiBox:Hide()
			
			
			AskFrame.Heal:SetScript("OnClick", RoleButtonClick)
			AskFrame.Dps:SetScript("OnClick", RoleButtonClick)
			AskFrame.Tank:SetScript("OnClick", RoleButtonClick)
			
			AskFrame.Heal:SetSize(64,64)
			AskFrame.Heal:ClearAllPoints()
			AskFrame.Heal:SetPoint("BOTTOMLEFT", AskFrame, "BOTTOMLEFT", 100, 80)
			AskFrame.Heal:Show()
			
			AskFrame.Dps:SetSize(64, 64)
			AskFrame.Dps:ClearAllPoints()
			AskFrame.Dps:SetPoint("TOPLEFT", AskFrame.Heal, "TOPRIGHT", 20, 0)
			AskFrame.Dps:Show()
			
			AskFrame.Tank:SetSize(64, 64)
			AskFrame.Tank:ClearAllPoints()
			AskFrame.Tank:SetPoint("TOPLEFT", AskFrame.Dps, "TOPRIGHT", 20, 0)
			AskFrame.Tank:Show()
			
			if AskFrame.numheal == 0 then
				AskFrame.Heal:Hide()
			end
			
			if AskFrame.numtank == 0 then
				AskFrame.Tank:Hide()
			end
			
			if AskFrame.numdps == 0 then
				AskFrame.Dps:Hide()
			end
			
			AskFrame.EditBox:ClearAllPoints()
			AskFrame.EditBox:SetPoint("CENTER", 0, -40)
			AskFrame.EditBox:Show()
			AskFrame.EditBox:SetText("[Insert optional decline reason here]")
			AskFrame.YesButton:Hide()
			AskFrame.NoButton:ClearAllPoints()
			AskFrame.NoButton:SetWidth(80)
			AskFrame.NoButton:SetPoint("BOTTOM", AskFrame, "BOTTOM", 0, 10)
			AskFrame.NoButton:SetText("Decline")
			AskFrame.NoButton:Show()
		elseif page == 3 then -- this page need to show the number of accepts/declines as they come in.
			AskFrame.ListFrame:Show()
		
			AskFrame:SetSize(450, 300)
			
			AskFrame.TitleText:SetText("Waiting for players")
			AskFrame.DDHeal:Hide()
			AskFrame.DDDps:Hide()
			AskFrame.DDTank:Hide()
			
			AskFrame.Heal:Hide()
			AskFrame.Dps:Hide()
			AskFrame.Tank:Hide()
			
			AskFrame.YesButton:Hide()
			AskFrame.EditBox:Hide()
			
			AskFrame.LevelBox:Hide()
			AskFrame.iLevelBox:Hide()
			AskFrame.RessiBox:Hide()
			
			AskFrame.NoButton:Show()
			AskFrame.NoButton:SetText("Close")
			AskFrame.NoButton:ClearAllPoints()
			AskFrame.NoButton:SetPoint("BOTTOMLEFT", 150, 10)
			AskFrame.NoButton:SetWidth(80)
			
		
			
			--idealy this needs to contain a scrollable dropdown, but thats a bit fancy
		end
	end

	
		local function ButtonHandler(self) --handles the commands for the yas and no buttons
		if AskFrame.page == 1 then --if they want to join the event		
			if self:GetText() == "Invite" then
				AskFrame.numdps = tonumber(UIDropDownMenu_GetText(AskFrame.DDDps))
				AskFrame.numheal = tonumber(UIDropDownMenu_GetText(AskFrame.DDHeal))
				AskFrame.numtank = tonumber(UIDropDownMenu_GetText(AskFrame.DDTank))
				
				AskFrame.healcount = 0
				AskFrame.dpscount = 0
				AskFrame.tankcount = 0
				
				AskFrame.event = AskFrame.EditBox:GetText()
				AskFrame.minres = tonumber(AskFrame.RessiBox:GetText()) 
				AskFrame.minilvl = tonumber(AskFrame.iLevelBox:GetText()) 
				AskFrame.minlvl = tonumber(AskFrame.LevelBox:GetText()) 
				
				local msg = "EVENT|"..AskFrame.event.."|DPS|"..AskFrame.numdps.."|HEAL|"..AskFrame.numheal.."|TANK|"..AskFrame.numtank
				
				if AskFrame.minres then
					msg = msg.."|RES|"..AskFrame.minres
				end
				if AskFrame.minilvl then
					msg = msg.."|iLVL|"..AskFrame.minilvl
				end
				if AskFrame.minlvl then
					msg = msg.."|LVL|"..AskFrame.minlvl
				end
				
				
				if AskFrame.event ~= "" and AskFrame.event ~= "[Type Event Name Here]" and string.len(AskFrame.event) > 5 then
					GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMEventNew", msg}
					AskFrame.TitleText:SetText("Waiting for players")
					SetAskFrame(3)
					AskFrame.page = 3
					IsLeader = true
				end
				
			elseif self:GetText() == "Cancel" then
				AskFrame:Hide()
			end
		elseif AskFrame.page == 2 then --second page, asking if dps or heal
			if self:GetText("Decline") then
				local reason = AskFrame.EditBox:GetText()
				if reason == "" or reason == "" or string.len(reason) < 5 then
					GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMEventBusy", ""}
				else
					GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMEventBusy", "REASON|"..reason}
				end
				
				tinsert(GMaster.Timers, {runonce = true, interval = 900, elapsed = 0, func = function() tempdisable = false end})
				AskFrame:Hide()
			end
		elseif AskFrame.page == 3 then
			if self:GetText() == "Close" then
				AskFrame:Hide()
			end
		end
	end

	AskFrame.YesButton:SetScript("OnClick", ButtonHandler)
	AskFrame.NoButton:SetScript("OnClick", ButtonHandler)

	local function AskCheck(event) --ask if they want to join the group
		AskFrame.event = event or ""
		AskFrame.page = 2
		SetAskFrame(2)
	end

	local function NewEvent()
		if AskFrame:IsShown() and AskFrame.page == 1 then
		
		else
			Queue = {}
			SetAskFrame(1)
			AskFrame.page = 1
			AskFrame:Show()
		end
	end

	function GMaster.CMA.EventCheck(prefix, msg, channel, player)
	
		if prefix == "GMEventNew" then
			if  player == GMaster.PlayerName then return end
		
			
			local ininst, instype = IsInInstance()
			if tempdisable then
				SendAddonMessage("GMEventBusy", "REASON| None", "GUILD")
			elseif ininst then 
				SendAddonMessage("GMEventBusy", instype, "GUILD")
			elseif GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0 then
				SendAddonMessage("GMEventBusy", "Reason: Group", "GUILD")
			else
				
				local event, numdps, numheal, numtank = msg:match("EVENT|(.-)|DPS|(%d+)|HEAL|(%d+)|TANK|(%d+)")
				local ressi = tonumber(msg:match("|RES|(%d+)"))
				local ilvl = tonumber(msg:match("|iLVL|(%d+)"))
				local lvl = tonumber(msg:match("|LVL|(%d+)"))
				if event then
					if ressi or ilvl or lvl  then
						
						local pRes =  GetCombatRating(COMBAT_RATING_RESILIENCE_PLAYER_DAMAGE_TAKEN) --the players ressi
						local plevel = UnitLevel("player")
						local pilevel = floor(GetAverageItemLevel()+0.5)
						
						if ressi then
							if pRes >= ressi then
								--they can join
							else
								--they cant join!
								SendAddonMessage("GMEventBusy", "REASON| Crap Resi", "GUILD")
								return
							end
						end
						
						if ilvl then
							if pilevel >= ilvl then
								--they can join
							else
								--they cant join!
								SendAddonMessage("GMEventBusy", "REASON| Crap gear", "GUILD")
								return
							end
						end
						
						if lvl then
							if plevel >= lvl then
								--they can join
							else
								--they cant join!
								SendAddonMessage("GMEventBusy", "REASON| Too low", "GUILD")
								return
							end
						end
						
					end
					SendAddonMessage( "GMEventPending", "Pending", "GUILD") --insert resi
					
					AskFrame.event = event
					AskFrame.leader = player
					AskFrame.numheal = tonumber(numheal) or 0
					AskFrame.numdps = tonumber(numdps) or 0
					AskFrame.numtank = tonumber(numtank) or 0
					SetAskFrame(2)
					AskFrame.page = 2
					AskFrame:Show()
				end
			end
		elseif prefix == "GMEventBusy" then
			if IsLeader then
				if msg == "pvp" then
					Queue[player] = "Decline: In Battlground"
					UpdateList()
				elseif msg == "arena" then
					--they are in arena
					Queue[player] = "Decline: In Arena"
					UpdateList()
				elseif msg == "party" then
					--they are in an instance
					Queue[player] = "Decline: In Instance"
					UpdateList()
				elseif msg == "raid" then
					--they are raiding
				elseif msg:find("REASON|") then
					local reason = msg:match("REASON|(.+)")
					Queue[player] = "Decline: "..reason
					UpdateList()
				end
			end
		elseif prefix == "GMEventPending" then
			if not (player == GMaster.PlayerName)then
				--pull the ressi if needed
				--print("Recieved pending")
				Queue[player] = "Pending"
				UpdateList()
			end
		elseif prefix == "GMEventAccept" then
			local role = msg:match("|ROLE|(.+)")
			if IsLeader then
				if role then
					if role:find("Heal") then
						if AskFrame.healcount < AskFrame.numheal then
							if (AskFrame.healcount + AskFrame.dpscount + AskFrame.tankcount) == 5 then
								ConvertToRaid()
							end
							tinsert(GMaster.Timers, {runonce = true, interval = 3, elapsed = 0, func = InviteUnit, vars = {player}})
							
							Queue[player] = "Invited"
							UpdateList()
							AskFrame.healcount = AskFrame.healcount + 1
						else
							--send reply saying sorry, full up now
						end
					elseif role:find("Dps") then
						if AskFrame.dpscount < AskFrame.numdps then
							if (AskFrame.healcount + AskFrame.dpscount + AskFrame.tankcount) == 5 then
								ConvertToRaid()
							end
							tinsert(GMaster.Timers, {runonce = true, interval = 3, elapsed = 0, func = InviteUnit, vars = {player}})
							Queue[player] = "Invited"
							UpdateList()
							AskFrame.dpscount = AskFrame.dpscount + 1
						else
							--send reply saying sorry, full up now
						end
					elseif role:find("Tank") then
						if AskFrame.tankcount < AskFrame.numtank then
							if (AskFrame.healcount + AskFrame.dpscount + AskFrame.tankcount) == 5 then
								ConvertToRaid()
							end
							tinsert(GMaster.Timers, {runonce = true, interval = 3, elapsed = 0, func = InviteUnit, vars = {player}})
							Queue[player] = "Invited"
							UpdateList()
							AskFrame.tankcount = AskFrame.tankcount + 1
						else
							--send reply saying sorry, full up now
						end
					end
				end
			end
		end
	end
	function GMaster.GFL.GMEvent() --loads the event button
		if not GMSettings.modules.GMEvent then
			return
		end
		local Eventler = CreateFrame("Frame")

			Eventler:RegisterEvent("CHAT_MSG_ADDON")
			Eventler:SetScript("OnEvent", EventCheck)

		local button = CreateFrame("Button", nil, GuildFrame, "UIPanelButtonTemplate")
		module.button = button
				button:SetWidth(80)
				button:SetHeight(18)
				button:SetText("New Event")
				button:SetPoint("TOPRIGHT", GuildFrame, "TOPRIGHT", -25, -2)
				button:SetScript("OnClick", NewEvent)
				button:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
															GameTooltip:SetText("Find guild members for any event you would like")
											end)
				button:SetScript("OnLeave", function() GameTooltip:Hide() end)
				button:Show()
	end
end

function GMaster.ModuleSettings.GMEvent()

	
	--create settings page
	local parent = CreateFrame("Frame")
		parent.titleText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		parent.titleText:SetPoint("TOPLEFT", parent, "TOPLEFT", 30, -40)
		parent.titleText:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -30, 40)
		parent.titleText:SetJustifyH("LEFT")
		parent.titleText:SetJustifyV("TOP")
		parent.titleText:SetText("GM-Event allows you to quickly create an event and invite other guild members based on certain criteria.\n"..
														"Currently you can invite based on level, item level, and resilience. Players that do not meet the criteria"..
														" or are busy (in an instance/bg/arena/etc) will not receive the invite.\n"..
														"There are no options as of yet, just click 'New Event' on the guild frame to get started")
	return parent
	
end

function GMaster.ModuleLoad.GMEvent()
	--enable the module
		GMaster.AL.GMEvent()
	if GMaster.GUILD_FRAME_LOADED then
		GMaster.GFL.GMEvent()
	else
		LoadAddOn("Blizzard_GuildUI")
	end

	
end

function GMaster.ModuleRemove.GMEvent()
	if module.button then
		module.button:Hide()
	end
	
	GMaster.CMA.EventCheck = function() end
	return true
end









