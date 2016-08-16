--[[
1. Summary
2. Details
3. Structure
4. Changes
5. To Do

--========================== 1. Summary ===============================
	Auto rank guild members based on certain criteria.
--========================== 2. Details ===============================
	Adds an extra item to the dropdown in "Guild Control" which allows you to 
	apply certain filters to each rank. Guild members can then be sorted between ranks
	based on wether they match the specified filters.
--========================== 3. Structure =============================
	
--========================== 4. Changes ===============================
1.52:
	merged antirankspam into this module
1.50
	Scrapped the manual vs auto features.
	Integrated the module into the guild control UI ("Rank Requirements" in the guild rank control dropdown)
	fixed a bug where it would still spam per rank change.
--========================== 5. To do =================================
	Add extra methods to rank people by.
	Broadcast the requirements so that the guild members can see what they need to do
	to achieve the next rank.
	Priority: High
	Need to send a message to anitrankspam to make it block all rank changes
	need to convert it to modular
]]



--[[
Other ideas:
General ranking tools:
Remove all members offline for more then X months 
																-(ignore specific rank)
																-account for alts.
Delete Rank: Auto move everyone from that rank either up or down																

when promoting someone manually, allow optional reason
delay the manual promote until the player is next online, this way they will notcie their new rank change.
snend some kind of congratulations.

This may be better suited to being integrated into the guild control UI


--]]

--[[
Need to merge the old test methods into the new ui

SendAddonMessage("GMRanker", "Start", "GUILD")
	tinsert(GMaster.Timers, {runonce = true, interval = 10, elapsed = 0, func = function() SendAddonMessage("GMRanker", "End", "GUILD") end})

--]]
--change this to add a tooltip.


GMaster.LoadOrder.GMRanker = true

local module = {}

local reqs = {Level = "Minimum Level for this rank",
							Age = "Minimum length of time in guild (days)",
							Chattyness = "Minimum number of times spoken in guild chat",
							Donations = "Minimum donated, in gold, through looting or direct donations",
							}
							
							--[[  need to add these in as they are written
							reqs["Events Created"] = "Minimum number of events that the player has started in the guild"
							reqs["Events Attended"] = "Minimum number of events the player has attended"
							reqs["Guild Rep"] = "Minimum guild reputation earned"
							reqs["Battlegrounds Attended"] = "Time spent in battlegrounds (hours)"
							reqs["Instanced Attended"] = "Time spent in instances"
							--]]
							
GMSettings.RankList = {}


local RankFrame= CreateFrame("Frame", nil, UIParent)
RankFrame:Hide()


local SettingsFrame = CreateFrame("Frame", nil, RankFrame)
SettingsFrame:SetAllPoints(RankFrame)
SettingsFrame:Hide()


--ton.icon:SetTexCoord(0.5625, 1, 0, 0.4375);
--create all of the settings:
--[[
	need an add button, a remove button, a label and edit box for each setting.
	
	need a dynamic system to load and show the settings for each requirement
	
	scroll frame to scroll each item (copy from the guild tab)
	
	remove button to remove each item
--]]
local function CheckEligible(name, info, rank, checks)
	if checks.Level then
		if info.level < checks.Level then
			return
		end
	end
	local tempstats = {}
	
	
	for dated, players in pairs(GMLogs) do
		if players[name] then
			for i = 1, #players[name] do
				if tempstats[i] then
					tempstats[i] = tempstats[i] + players[name][i]
				else
					tempstats[i] = players[name][i]
				end
			end
		end
	end
	
	if checks.Donations then
		local donated = (tempstats[22] or 0) - (tempstats[23] or 0) - (tempstats[24] or 0) + (tempstats[25] or 0)
		
		if (donated < checks.Donations) then
			return
		end
	end
	
	if checks.Chattyness then
		if not tempstats[3] then
			return
		end
		if (tempstats[3] < checks.Chattyness) then
			return
		end
	end
	
	if checks.Age then
		if GMRoster[name].firstseen then
			local age = time() - GMRoster[name].firstseen
			age = age/86400
			
			if age < checks.Age then
				return
			end
		end
	end
	

	if (info.rank + 1) <= RankFrame.selectedrank then
		return
	end	
	GMaster.Debug("promoting "..name)
	--if it has got to this point, they need to be promoted:
	
	for i = 1, (info.rank+1 - RankFrame.selectedrank) do 
		tinsert(GMaster.Timers, {runonce = true, interval = 1*i, elapsed = 0, func = GuildPromote, vars = {name}})
	end
		
end

local function Autorank()
if RankFrame.selectedrank then
	local check = GMSettings.RankList[RankFrame.selectedrank]
	if check then
		SendAddonMessage("GMRanker", "Start", "GUILD")	
		for name, info in pairs(GMRoster) do
			CheckEligible(name, info, RankFrame.selectedrank, check)
		end
		tinsert(GMaster.Timers, {runonce = true, interval = 10, elapsed = 0, func = function() SendAddonMessage("GMRanker", "End", "GUILD") end})
	end
end
end

local function CreateRequirement(k)
	local frame = CreateFrame("Frame", nil, SettingsFrame)
	frame:SetHeight(25)
	frame:SetPoint("LEFT")
	frame:SetPoint("RIGHT")
	frame.label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.label:SetSize(100, 25)
	frame.label:SetPoint("TOPLEFT",40, 0)
	frame.label:SetJustifyH("LEFT")
	frame.editbox = CreateFrame("EditBox", "GMRankReqEB"..k, frame, "InputBoxTemplate")
	frame.editbox:SetPoint("TOPLEFT", 200, 0)
	frame.editbox:SetPoint("BOTTOMRIGHT", -15, 0)
	frame.editbox:SetScript("OnEscapePressed", function(self) GuildControlUI:Hide() end)
	frame.editbox:SetNumeric(true)
	frame.editbox:SetScript("OnTextChanged", function(self) GMSettings.RankList[RankFrame.selectedrank][frame.label:GetText()] = self:GetNumber() end)
	frame.editbox:SetScript("OnShow", function(self) if tonumber(GMSettings.RankList[RankFrame.selectedrank][frame.label:GetText()]) then
				self:SetNumber(GMSettings.RankList[RankFrame.selectedrank][frame.label:GetText()])
			else self:SetNumber(0) end end)
	
	frame.remove = CreateFrame("Button", nil, frame)
	frame.remove:SetSize(15,15)
	frame.remove:SetPoint("TOPLEFT", 15, -5)
	
	frame.remove:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
	frame.remove:SetPushedTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Down")
	frame.remove:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Highlight")
	frame.remove:SetScript("OnClick", function() GMSettings.RankList[RankFrame.selectedrank][frame.label:GetText()] = nil GMaster.ReqRefresh() end)
	
	frame:Hide()
	return frame
end

local items = {}

function GMaster.ReqRefresh()
	for k, item in pairs(items) do
		item:Hide()
	end
	local found = 0
	local i = 1
	for name, tooltip in pairs(reqs) do
		if GMSettings.RankList[RankFrame.selectedrank][name] then
			
			local button = items[i] or CreateRequirement(i)
			button:Show()
			button:SetPoint("TOP", 0, -40-(found*30))
			button.label:SetText(name)
			if tonumber(GMSettings.RankList[RankFrame.selectedrank][name]) then
				button.editbox:SetNumber(GMSettings.RankList[RankFrame.selectedrank][name])
			end
			items[i] = button
			found = found + 1
			i = i + 1
		end
	end
end

local ReqSelect = CreateFrame("Frame", "GMRankerReqSelect", RankFrame, "UIDropDownMenuTemplate") --ReqSelect showing each rank
			
			UIDropDownMenu_SetWidth(ReqSelect, 120)
			--UIDropDownMenu_SetButtonWidth(GMRankerRankSelect, 120)
	
local function DropDown_Initialize(self, level) -- the menu items, needs a cleanup
	
	local info = UIDropDownMenu_CreateInfo()
	
	for name, tooltip in pairs(reqs) do
		info.text = name
		info.value = name
		info.tooltipTitle = name
		info.tooltipText = tooltip
		info.checked = function() if RankFrame.selectedrank and GMSettings.RankList[RankFrame.selectedrank][name] then return true end end
		info.func = function() GMSettings.RankList[RankFrame.selectedrank][name] = (not GMSettings.RankList[RankFrame.selectedrank][name]) GMaster.ReqRefresh() end
		UIDropDownMenu_AddButton(info, level)
	end
end
	UIDropDownMenu_Initialize(ReqSelect, DropDown_Initialize, "MENU")	
	UIDropDownMenu_SetText(ReqSelect, "Select Rank")




local AddButton = CreateFrame("Button", nil, SettingsFrame, "UIPanelButtonTemplate")
AddButton:SetText("Add Req.")
AddButton:SetSize(100, 25)
AddButton:SetPoint("TOPLEFT", 6, 0)
AddButton:SetScript("OnClick", function(self) ToggleDropDownMenu(1, 1, ReqSelect, self, 5, 0) end)
AddButton.tooltip = "Add a new requirement for this rank"
AddButton:SetScript("OnEnter", function(self) 
																	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
																		GameTooltip:SetText(self.tooltip);
																	end)
AddButton:SetScript("OnLeave", function(self)
																GameTooltip:Hide()
																end)

local ReqButton = CreateFrame("Button", nil, SettingsFrame, "UIPanelButtonTemplate")
ReqButton:SetText("Auto Rank!")
ReqButton:SetSize(100, 25)
ReqButton:SetPoint("BOTTOMRIGHT", -7, 10)
ReqButton:SetScript("OnClick", function(self) Autorank() end)
ReqButton.tooltip = "Automatically rank guild members based on the requirements set."
ReqButton:SetScript("OnEnter", function(self) 
																	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
																		GameTooltip:SetText(self.tooltip);
																	end)
ReqButton:SetScript("OnLeave", function(self)
																GameTooltip:Hide()
																end)

local function RankBackup()
	for i = 1, GetNumGuildMembers(true) do --build a list of all members in the selected ranks
		local name, rank, rankIndex, level  =  GetGuildRosterInfo(i)
		if GMRoster[name] then
			GMRoster[name].oldrank = rankIndex
		end
	end
end

local function RestoreRanks()
	SendAddonMessage("GMRanker", "Start", "GUILD")
	for i = 1, GetNumGuildMembers(true) do --build a list of all members in the selected ranks
		local name, rank, rankIndex, level  =  GetGuildRosterInfo(i)
		if GMRoster[name] and GMRoster[name].oldrank and not (GMRoster[name].oldrank == rankIndex) then
			if GMRoster[name].oldrank < rankIndex then
				for k = 1, (rankIndex - GMRoster[name].oldrank) do
					tinsert(GMaster.Timers, {runonce = true, interval = 1*k, elapsed = 0, func = GuildPromote, vars = {name}})
				end
			elseif GMRoster[name].oldrank > rankIndex then
				for k = 1, (GMRoster[name].oldrank - rankIndex) do
					tinsert(GMaster.Timers, {runonce = true, interval = 1*k, elapsed = 0, func = GuildDemote, vars = {name}})
				end
			end
		end
	end
		tinsert(GMaster.Timers, {runonce = true, interval = 12, elapsed = 0, func = function() SendAddonMessage("GMRanker", "End", "GUILD") end})
end

local function RestoreAddonRanks()
	SendAddonMessage("GMRanker", "Start", "GUILD")
	for i = 1, GetNumGuildMembers(true) do --build a list of all members in the selected ranks
		local name, rank, rankIndex, level  =  GetGuildRosterInfo(i)
		local found = nil
		if GMRoster[name] and GMRoster[name].oldrank and not (GMRoster[name].oldrank == rankIndex) then
			for dated, players in pairs(GMLogs) do --clears empty and small tables
				if players[name] and players[name][2] and players[name][2] > 0 then
					found = true
				end
			end
			
			if found and (GMRoster[name].oldrank < rankIndex) then
				for k = 1, (rankIndex - GMRoster[name].oldrank) do
					tinsert(GMaster.Timers, {runonce = true, interval = 1*k, elapsed = 0, func = GuildPromote, vars = {name}})
				end
			elseif found and (GMRoster[name].oldrank > rankIndex) then
				for k = 1, (GMRoster[name].oldrank - rankIndex) do
					tinsert(GMaster.Timers, {runonce = true, interval = 1*k, elapsed = 0, func = GuildDemote, vars = {name}})
				end
			end
			
			
		end
	end
		tinsert(GMaster.Timers, {runonce = true, interval = 12, elapsed = 0, func = function() SendAddonMessage("GMRanker", "End", "GUILD") end})
end

local function Demote_All()
	SendAddonMessage("GMRanker", "Start", "GUILD")
	for i = 1, GetNumGuildMembers(true) do --build a list of all members in the selected ranks
		local name, rank, rankIndex, level  =  GetGuildRosterInfo(i)
		local found = nil
			if rankIndex > 3 then
				for k = 1, (10 - rankIndex) do
					tinsert(GMaster.Timers, {runonce = true, interval = 2*k, elapsed = 0, func = GuildDemote, vars = {name}})
				end
			end
	end
		tinsert(GMaster.Timers, {runonce = true, interval = 25, elapsed = 0, func = function() SendAddonMessage("GMRanker", "End", "GUILD") end})
end

local BackupButton = CreateFrame("Button", nil, RankFrame, "UIPanelButtonTemplate")
BackupButton:SetText("Backup")
BackupButton:SetSize(100, 25)
BackupButton:SetPoint("BOTTOMLEFT", 7, 10)
BackupButton:SetScript("OnClick", function(self) RankBackup()	 end)
BackupButton.tooltip = "Backup the current rank of each guild member"
BackupButton:SetScript("OnEnter", function(self) 
																	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
																		GameTooltip:SetText(self.tooltip);
																	end)
BackupButton:SetScript("OnLeave", function(self)
																GameTooltip:Hide()
																end)
																
local RestoreButton = CreateFrame("Button", nil, RankFrame, "UIPanelButtonTemplate")
RestoreButton:SetText("Restore")
RestoreButton:SetSize(100, 25)
RestoreButton:SetPoint("LEFT",BackupButton, "RIGHT", 7, 0)
RestoreButton:SetScript("OnClick", function(self) RestoreRanks()	 end)
RestoreButton.tooltip = "Restore the backed up ranks"
RestoreButton:SetScript("OnEnter", function(self) 
																	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
																		GameTooltip:SetText(self.tooltip);
																	end)
RestoreButton:SetScript("OnLeave", function(self)
																GameTooltip:Hide()
																end)
																
local RestoreWithAddonButton = CreateFrame("Button", nil, RankFrame, "UIPanelButtonTemplate")
RestoreWithAddonButton:SetText("Restore /w addon")
RestoreWithAddonButton:SetSize(150, 25)
RestoreWithAddonButton:SetPoint("LEFT",BackupButton, "RIGHT", 7, -25)
RestoreWithAddonButton:SetScript("OnClick", function(self) RestoreAddonRanks()	 end)
RestoreWithAddonButton.tooltip = "Restore the backed up ranks"
RestoreWithAddonButton:SetScript("OnEnter", function(self) 
																	GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
																		GameTooltip:SetText(self.tooltip);
																	end)
RestoreWithAddonButton:SetScript("OnLeave", function(self)
																GameTooltip:Hide()
																end)

local DemoteAll = CreateFrame("Button", nil, RankFrame, "UIPanelButtonTemplate")
DemoteAll:SetText("Demote All")
DemoteAll:SetSize(100, 25)
DemoteAll:SetPoint("LEFT",BackupButton, "LEFT", 0, -25)
DemoteAll:SetScript("OnClick", function(self) Demote_All()	 end)


local DropDown = CreateFrame("Frame", "GMRankerRankSelect", RankFrame, "UIDropDownMenuTemplate") --dropdown showing each rank
			DropDown:SetPoint("TOPRIGHT", 10, 0)
			UIDropDownMenu_SetWidth(DropDown, 120)
			--UIDropDownMenu_SetButtonWidth(GMRankerRankSelect, 120)
	
	local function DropDown_Initialize(self, level) -- the menu items, needs a cleanup
			level = level or 1
		local info = UIDropDownMenu_CreateInfo()
		for i = 2, GuildControlGetNumRanks() do
			local name = GuildControlGetRankName(i)
			info.text = name
			info.value = name
			info.notCheckable = true
			info.arg1 = i
			info.func = function(self, arg1)  
										RankFrame.selectedrank = arg1 
											if not GMSettings.RankList[RankFrame.selectedrank] then 
												GMSettings.RankList[RankFrame.selectedrank] = {} 
											end
											SettingsFrame:Show() 
											GMaster.ReqRefresh()  
											UIDropDownMenu_SetText(DropDown, name) 
										end
			UIDropDownMenu_AddButton(info, level)
		end
	end
	UIDropDownMenu_Initialize(DropDown, DropDown_Initialize)	
	UIDropDownMenu_SetText(DropDown, "Select Rank")


	
local function ShowControls(self, arg1, arg2)
	if arg1 == 4 then
		RankFrame:Show()
	else 
		RankFrame:Hide()
	end
end

function GMaster.AL.GMRanker()
	if not module.addDD then
		function module.addDD(frame)
			if frame == GuildControlUINavigationDropDown and GMSettings.modules.GMRanker.active then
					local info = UIDropDownMenu_CreateInfo();
				info.text = "Rank Requirements"
				info.arg1 = 4;
				info.arg2 = "Rank Requirements"
				info.func = GuildControlUINavigationDropDown_OnSelect;
				info.checked = GuildControlUI.selectedTab == 4;
				UIDropDownMenu_AddButton(info);
			end
		end
	end
	
	function GMaster.GFL.GMRanker()
	hooksecurefunc("UIDropDownMenu_Initialize", module.addDD)
	hooksecurefunc("GuildControlUINavigationDropDown_OnSelect", ShowControls)
	UIDropDownMenu_SetWidth( GuildControlUINavigationDropDown, 140)
	RankFrame:SetParent(GuildControlUI)
	RankFrame:SetPoint("TOPLEFT", 5, -55)
	RankFrame:SetPoint("BOTTOMRIGHT", -5, 5)	
end	
end





	local RankWaitTime
	local ChangeRank = {}
	local SysType
	local blockAll

	local Timer = CreateFrame("Frame")

	local function RankAnnounce(self, elapsed)
		if RankWaitTime and (RankWaitTime < time() -5) then
			local ranks = {}
			for member, info in pairs(ChangeRank) do
				if not ranks[info.rank] then
					ranks[info.rank] = {}
				end
				if not ranks[info.rank][info.ptype] then
					ranks[info.rank][info.ptype] = {}
				end
				tinsert(ranks[info.rank][info.ptype], member)
			end	
			for rank, types in pairs(ranks) do
				local msg = ""	
				local k = 0
				for rtype, names in pairs(types) do
					for i = 1, #names do
						if k == 0 and i == 1 then
							msg = msg..names[i]
						else
							msg = msg..", "..names[i]
						end
					end
						msg = msg.." "..rtype..": "
					k = k + 1
				end
				msg = msg.." to rank '"..rank.."'"
				DEFAULT_CHAT_FRAME:AddMessage(msg, 1, 1, 0)
			end
			Timer:SetScript("OnUpdate", nil)
			ChangeRank = {}
		end
	end

	function GMaster.CMA.ToggleRankSpam(prefix, msg, channel, player)
		if prefix == "GMRanker" then
			if msg == "Start" then
				blockAll = true
			elseif msg == "End" and blockAll then
				blockAll = false
				DEFAULT_CHAT_FRAME:AddMessage("Guild ranks have been updated. Check out the roster for more information", 1, 1, 0)
			end
		end
	end

	local ptypes = {"promoted", "demoted", "kicked"}

	local function filter(self, event, msg, ...)
		if blockAll then return true end
		for k, ptype in pairs(ptypes) do
			local officer, member, rank = msg:match("(.-) has "..ptype.." (.-) to (.+)")
			if officer then
					ChangeRank[member] = {rank = rank, ptype = ptype, officer = officer}
					RankWaitTime = time()
					Timer:SetScript("OnUpdate", RankAnnounce)
				return true
			end
		end
	end

	ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", filter);






function GMaster.ModuleSettings.GMRanker()
	local parent = CreateFrame("Frame")
			parent.titleText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			parent.titleText:SetPoint("TOPLEFT", parent, "TOPLEFT", 30, -40)
			parent.titleText:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -30, 40)
			parent.titleText:SetJustifyH("LEFT")
			parent.titleText:SetJustifyV("TOP")
			parent.titleText:SetText("GM-Alts tracks alts of guild members and shares them with other members, allowing you to see who's who easily in the roster."..
																"\n There are currently no settings that can be changed for this module")
		return parent
end

function GMaster.ModuleLoad.GMRanker()
	GMaster.AL.GMRanker()
	if GMaster.GUILD_FRAME_LOADED then
		GMaster.GFL.GMRanker()
	else
		LoadAddOn("Blizzard_GuildUI")
	end
end

function GMaster.ModuleRemove.GMRanker()
	module.addDD = function() end
	return true
end