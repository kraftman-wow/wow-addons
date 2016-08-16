--[[
====================================================================================
=========================== GUILD MASTER ============================================
====================================================================================

1. About
2. Changes
3. To do.

--========================== 1. About ===============================
	This module does some database management and handles loading all of the other modules.
	
	Aim of the addon:
	The key aims of this addon are to make guilds more streamlined: 
	Running a guild requires a fair emount of administration, so any way this can be made easier for the guild master is 
	obviously a bonus.
	
	
--========================== 2. Changes ==============================
1.7
	Started moving GM Stats into GMRoster
1.5
	More changes to the way modules are loaded, and the way that the guild frame is loaded.
	Moved some roster functionality over to GMRoster.
1.4+
	Modified some of the function calls to make each module properly modular
--========================== 3. To do ================================



--------------------------------

Each time the player logs in, broadcast some stats, eg:
resi
rating
itemlevel

Take a look at moving some of the savedvariables away from per character, 
eg the database and forum


Make all modules use the stored playername instead of UnitName("player")


current layout: 

GMLogs = {	} -- stores all of the stats per member

GMSettings = {
	Ranklist = {} stores the rank settings
	Debug = boolean -- wether to print debugging stuff or not
	Active -- wether to directly to record to the current table or not.
	LastLogout = number -- last date of the logout
	MOTD -- the guild message of the day, just in case it gets deleted.
	modules = {} --list of  addons, not quite sure what it does.
	Log = {} --list of all guild members with some stats for them.
	Version = number -- the version number of the guild
	EnableEvent = boolean -- wether to enable event insites or not.
	GMRecruit = {
							lastsent = number -- time of last message
							list == table -- list of all messages.
							}
	StartTime ==number when they first come online.
	lockout = boolean --locks the player out if the version number isnt newest
	
	
	
GMForum = {} -- list of all forum posts.

GMBanker = {} - Filters for bank tabs and 

addon 
String - Addon name to look up metadata for
field 
value = GetAddOnMetadata("addon", "field")
String - Field name. May be Title, Notes, Author, Version, or anything starting with X-
}
]]

--[[
	Standard checks to be carried out before release:
	
		-Check no guild info is wiped.
		-Check on multiple guilds
		-Check on character not in a guild.
		-Test upgrade from old svaedvars
		-Test upgrade from no savedvars.
		
	Module checks:
		-Load/Unload each module on demand.

--]]


local ADDON_VERSION

local runcount = 3 --records if the guild roster has updated for the first time.
local firstrun = true

GMaster = {} --stores info on which modules are loaded
GMaster.PlayerName = UnitName("player")
GMaster.QueueTable = {} -- set up the table
GMaster.TempTable = {}
GMaster.loaded = {}

GMaster.LoadOrder = {} --each module puts its name in here to indicate that it needs to be loaded
-- common events 
GMaster.PEW = {} --list of functions to run on PEW
GMaster.AL = {} --list of functions to run on Addon Loaded
GMaster.CMA = {} --list of functions to run on CHAT_MESSAGE_ADDON
GMaster.GFL = {} --guild frame loaded


GMaster.ModuleLoad = {} --stores all methods that load the module
GMaster.ModuleRemove = {} --stores all methods that remove the module
GMaster.ModuleSettings = {} --stores the settings page for each module

GMaster.GUILD_FRAME_LOADED = nil -- has the guild frame loaded yet.
GMaster.IS_GUILD_MASTER = nil

GMSettings = {} --saved vars, stores settings for all modules
GMRoster = {} -- saved vars, stores info for each player.

local SETTINGS_LOADED = nil

GMaster.Debug = function(self, ...) --global print used by all modules to debug
	if GMSettings.Debug then
		print(...)
	end
end

 

function GMaster.EventHandler(self, event, ...)
	if event == "ADDON_LOADED" then
		local addon = ...
		if addon == "GuildMaster" then --if this addon has loaded
			GMaster.OnLoad() --check settings etc
			for name, v in pairs(GMaster.LoadOrder) do
				if GMSettings.modules[name] and GMSettings.modules[name].active and GMaster.AL[name] then --if the module needs to be loaded, load it
					GMaster.AL[name]() --load the module
					GMaster.loaded[name]  = true --store that the module has loaded successfully
				end
			end
		elseif addon == "Blizzard_GuildUI" then
			GMaster.GUILD_FRAME_LOADED = true
			LoadAddOn("Blizzard_GuildControlUI")
			for name, func in pairs(GMaster.GFL) do
				if type(func) == "function" and GMSettings.modules[name] then
					func()
					GMaster.Debug("GFL, ",name, func)
				end
			end
		end
	elseif event == "PLAYER_ENTERING_WORLD" then 
			GMaster.IS_GUILD_MASTER = IsGuildLeader("player")
			for name, func in pairs(GMaster.PEW) do
				if type(func) == "function" then
					func()
				end
				GMaster.Debug("PEW, ",name, func)
			end
			if not SETTINGS_LOADED then
				if GMaster.GMSettings then --this needs to load after all the other modules
					GMaster.GMSettings()
					SETTINGS_LOADED = true
				end
			end		
	elseif event == "CHAT_MSG_ADDON" then
		if IsInGuild() then
			for name, func in pairs(GMaster.CMA) do --loop through all the functions that need th event
				if type(func) == "function" then
					func(...)
				end
			end				
		end
	elseif event == "GUILD_ROSTER_UPDATE" then
		if GMaster.RosterUpdate then
			GMaster.RosterUpdate(...)
		end	
	end
end

function GMaster.OnLoad() 
		ADDON_VERSION = tonumber(GetAddOnMetadata("GuildMaster", "Version"))
		GMaster.LastLogin = time()
		if not GMSettings.Version then
		
				GMSettings = {Version = ADDON_VERSION, StartTime = 0, LastLogout = 0, GMForum = {}, EnableEvent = true}
				GMSettings.modules = {}
				for name, k in pairs(GMaster.LoadOrder) do
					GMSettings.modules[name] = {}
					GMSettings.modules[name].active = true
				end
				GMSettings.RankList = {}
				GMaster.TempTable = {}
				GMSettings.Active = nil
				GMLogs = {}
				GMForum = {}
				
				if not GMRoster then
					GMRoster = {}
				end
		
		end
		
	
	if  GMSettings.Version <  ADDON_VERSION then --if they are using an old version of the addon, 
	
			GMSettings = {Version = ADDON_VERSION, StartTime = 0, LastLogout = 0, GMForum = {}, EnableEvent = true}
			GMSettings.modules = {}
			if not GMSettings.modules then
				GMSettings.modules = {}
			
			end
			for name, k in pairs(GMaster.LoadOrder) do
				GMSettings.modules[name] = {}
				GMSettings.modules[name].active = true
			end
			
			GMSettings.RankList = {}
			GMaster.TempTable = {}
			GMSettings.Active = nil
			GMLogs = {}
			GMForum = {}
			
			if not GMRoster then
				GMRoster = {}
			end
			
			if not GMSettings.RankList then
				GMSettings.RankList = {}
			end
			GMSettings.Version = ADDON_VERSION
	else
		GMSettings.lockout = false --innocent until proven guilty
	end
end



--[[	This big 'ol function needs to clean up our tables, which means
-remove any tables that are teeny tiny
-remove any tables that are empty
-merge tables that are old

--]]
function GMaster.CleanTables()
	
	local temptable = {}
				
	for dated, players in pairs(GMLogs) do --clears empty and small tables
		if not players.LastRecord then --if it hasnt recorded any values
			GMLogs[dated] = nil --remove it
		else
			local wipe = false
			if players.LastRecord - dated < 600 then --remove entries smaller than 10 minutes
				wipe = true
			end
			if wipe then
				GMLogs[dated] = nil --remove it
			else
				tinsert(temptable, {dated, players.LastRecord}) --add it into the temp table
			end
		end
	end
	
	table.sort(temptable, function(a, b) return a[1] > b[1] end)
			
	for i = 2, #temptable, 1 do -- this function should merge tabls that are close to each other
		local first = temptable[i]
		local second = temptable[i +1]
		if first and second then
		
			 --dont add the second to last table to the potentially current table
				if first[1] - second[2] < 600 and (first[1] - second[2] > 0) then
				
				GMLogs[second[1]].LastRecord = first[2]
				--check they are on the same day
					if date("%d", first[1]) == date("%d", second[2]) then 
						for name, info in pairs(GMLogs[first[1]]) do
							if name ~= "LastRecord" then
								if not GMLogs[second[1]][name] then
									GMLogs[second[1]][name] = {}
								end
								for k, v in pairs(info) do
									if not GMLogs[second[1]][name][k] then
										GMLogs[second[1]][name][k] = v
									else
										if k > 9 and k < 16 then
											if  GMLogs[second[1]][name][k] < v then
												GMLogs[second[1]][name][k] = v
											end
										else
											GMLogs[second[1]][name][k] = GMLogs[second[1]][name][k] + v
										end
									end
								end
							end
						end
					end
						GMLogs[first[1]] = nil
				end		
			end
		end
				
	for i = 2, #temptable do
		local first = temptable[i]
		for j = 2, #temptable do
			if i ~= j then
				local second = temptable[j]
				if first[1] > second[1] and first[2] > second[2] then --first was somehow recorded inside second
					GMLogs[first[1]] = nil -- remove it from the savedvars
				end
			
			end
		end
	end
	GMaster.CleanTables = nil
	--need to loop through all tables and merge some based on their dates
	--pull out the merge function from the above loop so it can be reused
end

	--[[
	Need to make this function delete any location data stored when they go offline.
	
	--]]


local Eventler = CreateFrame("Frame")
Eventler:RegisterEvent("PLAYER_ENTERING_WORLD")
Eventler:RegisterEvent("ADDON_LOADED")
Eventler:RegisterEvent("CHAT_MSG_ADDON")
Eventler:RegisterEvent("GUILD_ROSTER_UPDATE")
Eventler:SetScript("OnEvent", GMaster.EventHandler)