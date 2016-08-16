--[[
1. Summary
2. Details
3. Structure
4. Changes
5. To Do

--========================== 1. Summary ===============================
	Shows guild members on the map
--========================== 2. Details ===============================
	Location data is recorded by the addon and then transmitted out ot other guild members.
	If more than one player is in the same zone, the update frequency increases.
--========================== 3. Structure =============================
	
--========================== 4. Changes ===============================
1.52
	Tooltips now show when the map is fullscreen

1.42
	Fixed a problem where guildies that had entered an instance where shown at the last location before entering
	Fixed an error caused by recieving the location of a player in an instance
	
--========================== 5. To do =================================
	Efficiency:
	Decrease the update interval for players in seperate zones,
	Increase the interval for players in the same zones, using the 
	whisper channel.
]]

GMaster.LoadOrder.GMLocator = true

local module = {}

	local MAX_ICONS = 25
	local ClassCoord = { 
									WARRIOR = {0, 0.125, 0, 0.25},
									PALADIN = {0.125, 0.25, 0, 0.25},
									HUNTER = {0.25, 0.375, 0, 0.25},
									ROGUE = {0.375, 0.5, 0, 0.25},
									PRIEST = {0.5, 0.625, 0, 0.25},
									DEATHKNIGHT = {0.625, 0.75, 0, 0.25},
									SHAMAN= {0.75, 0.875, 0, 0.25},
									MAGE = {0.875, 1, 0, 0.25},
									WARLOCK = {0, 0.125, 0.25, 0.5},
									DRUID = {0.25, 0.375, 0.25, 0.5}
								}

function GMaster.AL.GMLocator() --load when the addon loads

	local Player = {} --set up a table with the players details
	Player.zx = 0
	Player.zy = 0
	Player.zcont = 0
	Player.zzone = 0
	Player.standing = 0 
	local partyNames = {}

	if not module.statusFrame then
		module.statusFrame = CreateFrame("Frame")
	end
	local statusFrame = module.statusFrame
	 

	local function SendLocation()
			
		if not IsInGuild() then
			return
		end
		
		if IsInInstance() then
			GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMLocator", "ININSTANCE"}
			return
		end
			
			
			
		statusFrame:UnregisterEvent("WORLD_MAP_UPDATE")
			local lastCont, lastZone = GetCurrentMapContinent(), GetCurrentMapZone();
			SetMapToCurrentZone();
			
			local zx, zy = GetPlayerMapPosition("player")
			local zcont, zzone = GetCurrentMapContinent(), GetCurrentMapZone()
				
			SetMapZoom(GetCurrentMapContinent())
			local cx, cy = GetPlayerMapPosition("player")
			local ccont, czone = GetCurrentMapContinent(), GetCurrentMapZone()
			
				if (zx + zy + cx + cy) > 0 then -- the playe rmight have the map open which will screw things up a bit
					zx = floor(zx * 10000 + 0.5)
					zy = floor(zy *10000 + 0.5)
					cx = floor(cx *10000 + 0.5)
					cy = floor(cy *10000 + 0.5)
					if zx ~= Player.zx and zy ~= Player.zy then
						Player.zx = zx
						Player.zy = zy 
						Player.zcont = zcont
						Player.zzone = zzone
						
						GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMLocator", "zx"..zx.."zy"..zy.."cx"..cx.."cy"..cy.."zcont"..zcont.."zzone"..zzone.."ccont"..ccont.."czone"..czone}
					end
				end
			SetMapZoom(lastCont, lastZone); -- set map zoom back to what it was before;
		statusFrame:RegisterEvent("WORLD_MAP_UPDATE")
	end


	if not module.iconsloaded then
		for i = 1, MAX_ICONS do
			local icon = CreateFrame("Button", "GMLocWorldButton"..i,WorldMapButton)
			icon.tex = icon:CreateTexture()
			icon.tex:SetAllPoints(icon)
			icon.tex:SetTexture("Interface\\Minimap\\PartyRaidBlips")
			icon.tex:SetTexCoord(0, 0.125,  0, 0.25)		
			icon:SetWidth(16)
			icon:SetHeight(16)
			icon.tooltip = ""
			icon:SetScript("OnEnter", function(self) 
															WorldMapTooltip:SetOwner(self, "ANCHOR_RIGHT")
															WorldMapTooltip:SetText(self.tooltip)
														end)
			icon:SetScript("OnLeave", function(self) WorldMapTooltip:Hide() end)
		end
		module.iconsloaded = true
	end

	statusFrame.elapsed = 0
	statusFrame.interval = 5

	local function MainMapRefresh(self)
		local curCont = GetCurrentMapContinent() -- get the current continent
		local curZo = GetCurrentMapZone() --current zone
		local i = 1

		if curCont < 0 or curCont > 4 or IsInInstance() then --hide them all if its a bg etc
			for i = 1, MAX_ICONS do
				local  button = getglobal("GMLocWorldButton" .. i)
				button:Hide()
			end
			return
		end
		
		for i = 1, MAX_ICONS do
			local  button = getglobal("GMLocWorldButton" .. i)
			button:Hide()
		end
		
		local found
	
		for player, info in pairs(GMRoster) do
			if info.online  and player ~= GMaster.PlayerName and info.zx then
				if partyNames[player] then
					return
				end
				local button = _G["GMLocWorldButton"..i]
				local x, y	
				
				if  (info.zzone == curZo)  and (info.zcont == curCont) then
					x, y = info.zx, info.zy
				elseif (info.czone == curZo) and (info.ccont == curCont ) then
					x, y = info.cx, info.cy
				end
					if i <= MAX_ICONS then
						if button and x and y then
							found = true
							local width, height = WorldMapButton:GetWidth(), WorldMapButton:GetHeight()
							local x, y = (width/10000)*x, (height/10000)*y
							if info.class then
								button.tex:SetTexCoord(unpack(ClassCoord[info.class]))
							end
							button:SetPoint("CENTER", WorldMapButton, "TOPLEFT", x, -y)
							button:SetFrameStrata("TOOLTIP")
							button:SetFrameLevel(WorldMapButton:GetFrameLevel() + 50)
							button.tooltip = player
							button:Show()
							i = i + 1
						else
							button:Hide()
						end
					end
			end
		end
			tinsert(GMaster.Timers, {runonce = true, interval = (self.interval-1), elapsed = 0, func = SendLocation})
			return found
	end

	local function UpdateMainMap(self, elapsed)
	statusFrame.elapsed = statusFrame.elapsed + elapsed
		if statusFrame.elapsed > statusFrame.interval then
				statusFrame.elapsed = 0
				local found = MainMapRefresh(self)
				if found then
					self.interval = 5
				else
					self.interval = 20
				end
		end
	end

	local function UpdatePartyNames()
	partyNames = {}
		if( GetNumRaidMembers() > 0 ) then
			for i=1, MAX_RAID_MEMBERS do
				local playerName = UnitName( "raid" .. i );
				if playerName then
					partyNames[playerName] = true
				end
			end
		else
			for i=1, MAX_PARTY_MEMBERS do
				local playerName = UnitName( "party" .. i );
				if playerName then
					partyNames[playerName] = true
				end
			end
		end
	end

	function GMaster.CMA.GMLocator(prefix, msg, channel, player)
		if prefix == "GMLocator" then
			if msg == "ININSTANCE" then
				if GMRoster[player] then
					GMRoster[player].zx = nil --this should stop the map from checking it, needs testing
					return
				else
					return
				end
			end
			if player ~= GMaster.PlayerName then
			local zx, zy, cx, cy, zcont, zzone, ccont, czone = msg:match("zx(%d+)zy(%d+)cx(%d+)cy(%d+)zcont(%d+)zzone(%d+)ccont(%d+)czone(%d+)")
				if zx then
					if GMRoster[player]  then
					GMRoster[player].zx = tonumber(zx)
					GMRoster[player].zy = tonumber(zy)
					GMRoster[player].cx = tonumber(cx)
					GMRoster[player].cy = tonumber(cy)
					GMRoster[player].zcont = tonumber(zcont)
					GMRoster[player].zzone = tonumber(zzone)
					GMRoster[player].ccont = tonumber(ccont)
					GMRoster[player].czone = tonumber(czone)
					GMRoster[player].online = true
					end
				end		
			end
		end	
	end

	local function StatusCheck(self, event, ...)	
		if event == "CHAT_MSG_SYSTEM" then
			local msg = ...
			local player = msg:match("(.-) has gone offline")
			if GMRoster[player] then
				GMRoster[player].online = nil
			end
		elseif event == "PARTY_MEMBERS_CHANGED" then -- change this for thje actual function
			UpdatePartyNames()
		elseif event == "ZONE_CHANGED_NEW_AREA" then
			tinsert(GMaster.Timers, {runonce = true, interval = 3, elapsed = 0, func = SendLocation})
		elseif event == "WORLD_MAP_UPDATE" then
			MainMapRefresh(self)
		end
	end


	statusFrame:RegisterEvent("CHAT_MSG_SYSTEM")
	statusFrame:RegisterEvent("PARTY_MEMBERS_CHANGED") -- raid members changing
	statusFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA") -- current map zone changing

	statusFrame:RegisterEvent("WORLD_MAP_UPDATE")
	statusFrame:SetScript("OnEvent", StatusCheck)
	statusFrame:SetScript("OnUpdate", UpdateMainMap)
	
	if not module.togglebutton then
		module.togglebutton = CreateFrame("CheckButton", "GMLocatorCheckButton", WorldMapFrame, "ChatConfigCheckButtonTemplate")
		_G[module.togglebutton:GetName().."Text"]:SetText ("Show Guild Members")
		_G[module.togglebutton:GetName().."Text"]:SetTextColor(1, 0.8, 0)
			module.togglebutton:SetSize(25, 25)
			module.togglebutton:SetPoint("RIGHT", WorldMapQuestShowObjectives, "LEFT", -300, 0)
			module.togglebutton:SetScript("OnClick", function(self) 
																									if self:GetChecked() then
																										GMaster.AL.GMLocator()
																									else
																										GMaster.CMA.GMLocator = function() end --prevent it from recieving locations
																										statusFrame:SetScript("OnUpdate", nil) --stop it from ending locations
																										statusFrame:SetScript("OnEvent", nil)
																										
																										for i = 1, MAX_ICONS do --hide all the icons
																											local  button = getglobal("GMLocWorldButton" .. i)
																											button:Hide()
																										end
																									end
																								end )
																								
	end
		module.togglebutton:SetChecked(true)
		
		
end



function GMaster.ModuleSettings.GMLocator()
	local parent = CreateFrame("Frame")
			parent.titleText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			parent.titleText:SetPoint("TOPLEFT", parent, "TOPLEFT", 30, -40)
			parent.titleText:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -30, 40)
			parent.titleText:SetJustifyH("LEFT")
			parent.titleText:SetJustifyV("TOP")
			parent.titleText:SetText("GM-Locator shares your location with other guild members on the map, allowing you see where all your bestest"
																.." buddies are!")
		return parent
end

function GMaster.ModuleLoad.GMLocator()
	
	GMaster.AL.GMLocator()
	
	module.togglebutton:Show()
end

function GMaster.ModuleRemove.GMLocator()
	GMaster.CMA.GMLocator = function() end --prevent it from recieving locations
	module.statusFrame:SetScript("OnUpdate", nil) --stop it from ending locations
	module.statusFrame:SetScript("OnEvent", nil)
	module.togglebutton:Hide()

	for i = 1, MAX_ICONS do --hide all the icons
			local  button = getglobal("GMLocWorldButton" .. i)
			button:Hide()
	end
		
	return true
end


