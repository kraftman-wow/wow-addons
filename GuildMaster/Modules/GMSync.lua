--[[
1. Summary
2. Details
3. Structure
4. Changes
5. To Do

--========================== 1. Summary ===============================
	Syncronises extra player data between guild members, such as donations,
	
--========================== 2. Details ===============================
	Upon  the player entering the game, the addon sends a ping out to check for other players with the addon. At this point any data received will be stored in a temporary table.
	If no other addons send a pong, the addon will assume that it is the only one online, and start a new session, adding any temporary data into the new session.
	If other addons are found, the oldest addon that is not currently involved with syncing to another player will also pause its own data gathering, and begin transmitting the current table to the new addon.
	Once the current session has been updated to the new addon, both the newest and oldest addons will resuming recording directly to their sessions, and add any temporary information recorded.
	The newest and oldest addons will broadcast their session ID's to all other addons, and all addons transmit any sessions that other addons are missing.
	if sessions are somehow recorded during another session, they will eventually be detected and deleted.
--========================== 3. Structure =============================
	
--========================== 4. Changes ===============================
1.42
	-	Moved the queue function over to GMTimer.
		Added a method of blocking users whose addons are out of date.
--========================== 5. To do =================================
	Efficiency:
	Change the order of the if/elese statements to better suit how oftn ethey are called.
	
	New Method:
	10 minute blocks of data, sync every half an hour.
	
	log in, record login time, start recording.
	after 10 mins, split chunk.
	after half hour, transmit the start time, size of last chunk
	Wait 10 seconds, then decide which module is the "master"  
	Master transmits all known chunk times
		Slaves request missing chunks, transmit missing chunk labels.
		Wait 30 seconds, count requests for each chunk.
		If a chunk has multiple requests, broadcast it
		If a chunk has a single request, WHISPER it.
	
	hash value for tables:
		need to create some method of finding the total size of a table
		
	Problems:
		Players changing zones/reloading
		-may miss some data
		
	Merging continuous chunks:
		Find tables whose start and end times match
		merge the table data
		
	Merging non-comtinuous chunks:
		Non continuous chunks can be merged provided: 
		the start and end times of each chunk are recorded into the new chunk
		for example:
			- chunk 1 measures a to c
			- chunk 2 measures g to h
			chunk 1a is a merge of ac gh
			chunk 3 measures d to f
			chunk 1b is a merge of 1a and 3 consisting a through h
			
		Timescales:
			10 minute chunks
			merge after 30 mins and transmit
			merge after 1 hour
			merge 24 hour after 1 day
			merge 7 days after 1 week
			merge 4 weeks after a month
			
			Eventually merge data into the roster.
	
	Security:
	 With the limitations on obfuscation, can only be basic.
	 Masking the saved vars by conversion to ASCII?

Use GMRoster savedvar to store which members are online, and the last time they were seen, 
(any addonmessage received should be used as the last time they were seen.)
	 
]]


--[[


["PLAYER"] = {	[1] = 0, -- hash
				[2] = 0, -- online
				[3] = 0, -- chat
				[4] = 0, -- inbg
				[5] = 0, -- in arena
				[6] = 0, -- in instance
				[7] = 0, -- in raid
				[8] = 0, --started event
				[9] = 0, --joined event
				[10] = 0, -- Killing Blows
				[11] = 0, -- Deaths
				[12] = 0, -- Honorable Kills
				[13] = 0, -- Damage Done
				[14] = 0, -- Healing Done
				[15] = 0, --Honor Gained
				[16] = 0, Killing Blows total
				[17] = 0, -- Deaths total
				[18] = 0, -- HK total
				[19] = 0, - damage total
				[20] = 0, -- heal total
				[21] = 0, -- honor gained
				[22] = 0, -- money donated.
				[23] = 0 --money withdrawn
				[24] = 0, --repairs used
				[25] = 0,  --looted
				[26] = 0, -- guild rep
			 
--]]

function GMaster.AL.GMSync()

	local testframe = CreateFrame("FRAME", nil,UIParent,  WorldStateScore)
	testframe:SetWidth(300)
	testframe:SetHeight(300)
	testframe:SetPoint("CENTER", UIParent, "CENTER")
	testframe:Show()

	local LoginTime = 0
	local AddonList = {}

	local SendTo = "" --stores who it is sending stuff to
 --stores temporary info while the addon is sending or recieving
	local PlayerName = GMaster.PlayerName
	local RequestTable = {}
	local EnteredBG = false
	--stores all mesages to be sent

	local PingSent = nil
	local isBusy = 0 -- 0 isnt busy, 1 is
	local waitingToPing = 0 --if the addon is queued to ping a vacant addon (check locFrame)
	
	local ignorelist = {}
	
	--=======================================================================

	GMaster.PEW.LoadSync = function()
			LoginTime = tonumber(time())
			GMSettings.Active = nil --stop it recording anything to its current table, as the current table doesnt exist yet
			
			if (GMSettings.LastLogout > 0) and (LoginTime - GMSettings.LastLogout) < 60 then --if the addon has been run before
				GMaster:Debug("continuing with current table") --stick with the stored
				GMSettings.Active = true
			else --send a ping to see whats going on
				tinsert(GMaster.Timers, {runonce = true, interval = 20, elapsed = 0, func = function() SendAddonMessage("GMPing", LoginTime.."|"..GMSettings.Version, "GUILD") end})
				PingSent = true
			end
		GMaster.PEW.LoadSync = nil
	end

	--=================================================================

	function GMaster.AddInfo(name, dated, index, value, LastRecord) --adds the info received into the database
	if not IsInGuild() then return end
		if (GMSettings.Active == true) and not (GMSettings.StartTime == 0) then --if it hasnt receieved a start time yet, or its busy, record to temp table
		local flagged = false --flag to set the value rather than add it
		
		if dated == "current" and GMLogs[GMSettings.StartTime] and GMLogs[GMSettings.StartTime].LastRecord then 
			if date("%d", GMLogs[GMSettings.StartTime].LastRecord) ~= date("%d", GMSettings.StartTime) then --this should force creation of a new table each day
				GMSettings.StartTime = time()
			end
		end

		if (not dated) or (dated == "current") then 
				dated = GMSettings.StartTime
			end
			
			if not GMLogs[dated] then
				GMLogs[dated] = {}
			end
			
			if LastRecord then
				GMLogs[dated].LastRecord = LastRecord
			else
				GMLogs[dated].LastRecord = time()
			end
			
			GMSettings.LastLogout = time()

			if not GMLogs[dated][name] then
				GMLogs[dated][name] = {}
			end
			
			for i = 1, math.min((index + 6), 26) do
				if not GMLogs[dated][name][i] then
					GMLogs[dated][name][i] = 0
				end
			end
			
				if index > 9 and index < 16 then --top scores in bg
					if value > GMLogs[dated][name][index] then --if its a new top score
						GMLogs[dated][name][index]  = value --replace thenew top score
					end
					GMLogs[dated][name][index+6] = GMLogs[dated][name][index+6] + value -- increase the totals
				else
					GMLogs[dated][name][index] = GMLogs[dated][name][index] + value
				end
			
			local hash = 0
			for i = 2, #GMLogs[dated][name] do 
				hash = hash + GMLogs[dated][name][i]
			end
			GMLogs[dated][name][1] = hash
		else --add it to a queue to be added later
			GMaster:Debug("queing "..name..dated..index)
			
			GMaster.TempTable[#GMaster.TempTable+1] = {name,dated,index,value, LastRecord}
		end
	end





	--=========================== Checks that are sent out: =======================================================
	--=====================================================================================================
	--=====================================================================================================
	--[[

	1. Any chatting in /g
	2. Withdrawals from guild bank
	3. donations to guild bank
	4. Guild Repairs
	5. Guild loot donations
	6. Guild Rep
	7. What the player is doing
	8. Battleground scores.


	--]]

	--=================  1. Chatting in /g =================

	local function ChatCheck(self, event, msg, name) -- flags every time a player talks in /g
		GMaster.AddInfo(name, "current", 3, 1)
	end

	local Chatter = CreateFrame("FRAME")
	Chatter:RegisterEvent("CHAT_MSG_GUILD")
	Chatter:SetScript("OnEvent", ChatCheck)


	--===================== 2. Withdrawal from Guild Bank ===================

	StaticPopupDialogs["GUILDBANK_WITHDRAW"] = {
		text = GUILDBANK_WITHDRAW,
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = function(self)
			local moneys = MoneyInputFrame_GetCopper(self.moneyInputFrame)
			WithdrawGuildBankMoney(moneys);
				GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMWithdraw", moneys}
			end,
		OnHide = function(self)
			MoneyInputFrame_ResetMoney(self.moneyInputFrame);
		end,
		EditBoxOnEnterPressed = function(self)
			local parent = self:GetParent():GetParent();
			local moneys = MoneyInputFrame_GetCopper(parent.moneyInputFrame)
			WithdrawGuildBankMoney(moneys);
			GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMWithdraw", moneys}
			parent:Hide();
		end,
		hasMoneyInputFrame = 1,
		timeout = 0,
		hideOnEscape = 1
	};

	--===================== 3. Donations to guild bank =============

	StaticPopupDialogs["GUILDBANK_DEPOSIT"] = {
		text = GUILDBANK_DEPOSIT,
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = function(self)
			local moneys = MoneyInputFrame_GetCopper(self.moneyInputFrame)
			DepositGuildBankMoney(moneys)
			GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMDonate", moneys}
		end,
		OnHide = function(self)
			MoneyInputFrame_ResetMoney(self.moneyInputFrame);
		end,
		EditBoxOnEnterPressed = function(self)
			local parent = self:GetParent():GetParent();
			local moneys = MoneyInputFrame_GetCopper(parent.moneyInputFrame)
			DepositGuildBankMoney(moneys);
			GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMDonate", moneys}
			parent:Hide();
		end,
		hasMoneyInputFrame = 1,
		timeout = 0,
		hideOnEscape = 1
	};

	--====================== 4. Repair ================

		
								
								MerchantGuildBankRepairButton:SetScript("OnClick", function(self) 
										local amount = GetGuildBankWithdrawMoney();
										local guildBankMoney = GetGuildBankMoney();
										local cost = GetRepairAllCost()
										if ( amount == -1 ) then
											-- Guild leader shows full guild bank amount
											amount = min(guildBankMoney, cost)
										else
											amount = min(amount, guildBankMoney, cost);
										end
										if(CanGuildBankRepair()) then
											
											GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMRepair", amount}
											RepairAllItems(1);
											PlaySound("ITEM_REPAIR");
										end
										GameTooltip:Hide();
								end)
								
	--======================= 5. Donations from looting ==================================
	do 
	local f = CreateFrame("Frame")
	f:RegisterEvent("CHAT_MSG_MONEY")
	f:SetScript("OnEvent", function(self, event, msg)
			local Gold = msg:match("%(.-(%d+) Gold.-deposited to guild bank") or 0
			local Silver = msg:match("%(.-(%d+) Silver.-deposited to guild bank") or 0
			local Copper = msg:match("%(.-(%d+) Copper.-deposited to guild bank") or 0 


				if not GMaster.tempmoney then 
					GMaster.tempmoney = 0
				end
				GMaster.tempmoney = GMaster.tempmoney + Copper + Silver*100 + Gold *10000
			end)
	end

	--======================= 6. Guild Rep ===============================
	do
	local f = CreateFrame("Frame")
	f:RegisterEvent("COMBAT_TEXT_UPDATE")
	f:SetScript("OnEvent", function(self, event, ctype, faction, gain, ...) 
											if ctype == "FACTION" then
												if faction == "Guild Reputation" then 
													GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMUpdate", "|Rep|"..gain}
												end
											end 
								end)
	end


	--======================= 7. What is the player doing? (instance/bg/arena/raid)  =====================


	local function LocCheck()
		local inInstance, instanceType = IsInInstance()
		if IsInGuild() then
			SendAddonMessage("GMUpdate", "|Loc"..instanceType.."|int60", "GUILD")
		end
		if GMaster.tempmoney and GMaster.tempmoney > 0 then
			GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMUpdate", "|Loot|"..GMaster.tempmoney}
			GMaster.tempmoney = 0
		end
		
	end

	tinsert(GMaster.Timers, {runonce = false, interval = 60, elapsed = 0, func = LocCheck})

	--========================== 8. Battleground scores  =============================================

	local name, killingBlows, honorableKills, deaths, honorGained, faction, race, class, classToken, damageDone, healingDone, bgRating, ratingChange 

	local BGScore = CreateFrame("FRAME")
	BGScore:RegisterEvent("PLAYER_ENTERING_WORLD")
	BGScore:RegisterEvent("UPDATE_WORLD_STATES")
	BGScore:RegisterEvent("UPDATE_BATTLEFIELD_SCORE")


		
	BGScore:SetScript("OnEvent", function(self, event, msg)
														
															local inst, instype = IsInInstance()
															if inst and instype == "pvp" then
																	for i = 1, GetNumBattlefieldScores() do
																		name, killingBlows, honorableKills, deaths, honorGained, faction, race, class, classToken, damageDone, healingDone, bgRating, ratingChange = GetBattlefieldScore(i);
																		if name and name == PlayerName then
																			return
																		end
																	end
															else
																if name and killingBlows then
																	local msg = "BG|10:"..killingBlows.."|11:"..deaths.."|12:"..honorableKills.."|13:"..damageDone
																			msg = msg.."|14:"..healingDone.."|15:"..honorGained.."|"
																		GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMUpdate", msg}
																	name, killingBlows = nil, nil
																end
															end
														
													end)

	--===================================================================
	--==========================================================================

	local function PingWait()
			SendAddonMessage("GMPing", LoginTime.."|"..GMSettings.Version, "GUILD")
			PingSent = true
	end


	local function Timer()
		if GMSettings.lockout then
			return
		end
			GMaster:Debug("timer finished, sorting")
			table.sort(AddonList, function(a, b) return a.login < b.login end)
			if #AddonList == 1 then
				--its the only one online
				--if its the only one online, check the damn start time
				GMSettings.StartTime = LoginTime
				GMaster:Debug("this addon is the only one online")
				PingSent = nil
				GMSettings.Active = true			
			else
				local i = 1
				--search for the first addon that isnt busy
				while ( AddonList[i] and AddonList[i].busy == 1) do
					i = i + 1
				end
					
					GMaster:Debug(#AddonList)--if theres more than one, it wont be the oldest, so it wont send crap to itself
					GMaster:Debug(i)
					for j = 1, #AddonList do
						GMaster:Debug(j..": "..AddonList[j].player..AddonList[j].login)
					end
					
				if AddonList[i] then
					if AddonList[i].player == PlayerName then --if this addon is the one that needs to send the tables
						if PingSent then --check it isnt the one that asked for the tables
							if not i == 1 then
								GMaster:Debug("There are no free addons, queueing ping") 
								tinsert(GMaster.Timers, {runonce = true, interval = 60, elapsed = 0, func = PingWait})
							end
						else
							if isBusy < 1 and not PingSent then --its not busy
								GMaster:Debug("this addon is the oldest and will send the tables")
								GMSettings.Active = nil --stop this addon recording directly to the table
								isBusy = 1 --mark it as busy
								
								GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMCurrentStart"..SendTo, GMSettings.StartTime}
							
								--send the current table
								if GMLogs and GMLogs[GMSettings.StartTime] then
									for name, info in pairs(GMLogs[GMSettings.StartTime]) do
										if (name == "LastRecord") then
											GMaster:Debug("this value is LastRecord")
										else
											GMaster:Debug("Sending message for name: "..name)
											local msg = name.."|"
											for i = 1, #info do
												if  info[i] ~= 0 then
													msg = msg..i..":"..(info[i]).."|"
												end
											end
											GMaster:Debug(msg.." this is being sent out")
											GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMCurrent"..SendTo, msg}
										end
									end
								end
								
								isBusy = 0 --mark it as available
								GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMCurrentEnd"..SendTo, GMSettings.StartTime}
							else
								GMaster:Debug("This addon is busy")
							end
						end
					else
						if PingSent then -- there should be an addon about to send data, so wait for it.
							GMaster:Debug("this addon is waiting to receive ")
						else
							GMaster:Debug("this addon isnt the oldest, and will continue recording normally")
							GMSettings.Active = true
						end
					end
				else --the players addon is busy, as are all the  others
					GMaster:Debug("There are no free addons, queueing ping")
					tinsert(GMaster.Timers, {runonce = true, interval = 60, elapsed = 0, func = PingWait})
				end
			end
	end

	--[[
	GMWipe - Forces all online addons to wipe their data
	GMDonate - the player has donated
	GMWithdraw - the player has withdrawn money
	GMRepair - the player has used guild repair
	GMPing - only sent by new addons when they come online
	GMPong - sent by all addosn to work out who is the "leader" (oldest)
	GMUpdate --sent by all addons to tell all other addons any new info
	GMBroadcast - send out all known table Start and ned times, not their data
	GMRequest -- asks for any tables that are needed
	GMCurrentStart - sends the current table to a new addon
	GMCurrent -- the data of the current table
	GMCurrentEnd --the current table has finished sending

	--what happens if a new addon comes online while the leader is sending out the current table?
		-- it gets directed to a different addon, or queued
	--]]


	--this function needs reshuffling so the most likely events occur first


	function GMaster.CMA.SyncMsg( prefix, msg, channel, player) --only deals with checking which tables different addons have
		if GMSettings.lockout then --don't do anything
			return
		end
		if ignorelist[player] then
			return
		end
		if prefix == "GMWIPE" then
			--this should reset all addons online
			GMSettings = {}
			GMaster.QueueTable = {}
			GMSettings.Active = nil
			GMSettings.StartTime = tonumber(msg)
			GMRoster = {}
			GMLogs = {}
		elseif prefix == "GMEventNew" then
			GMaster.AddInfo(player, "current", 8, 1)
		elseif prefix == "GMEventAccept" then
			GMaster.AddInfo(player, "current", 9, 1)
		elseif prefix == "GMDonate" then
			msg = tonumber(msg)
			GMaster.AddInfo(player, "current", 22, msg)
			GMaster:Debug(player.." donated "..msg)
		elseif prefix == "GMWithdraw" then
				msg = tonumber(msg)
				GMaster:Debug(player.." withdrew "..msg.." from GB")
			GMaster.AddInfo(player, "current", 23, msg)
		elseif prefix == "GMRepair" then
			msg = tonumber(msg)
			GMaster.AddInfo(player, "current", 24, msg)
			GMaster:Debug(player.."used GB for repair, costing:"..msg)
		elseif  prefix == "GMPing" then -- listened to by all addons
			local version = tonumber(msg:match("|(%d+%p%d+)"))
				if (not version) or (version < GMSettings.Version) then
					ignorelist[player] = true
					return
				end
				if version and version > GMSettings.Version then
					GMSettings.lockout = true
					print("Guild Master is out of date. Most functionality will not work until you update")
				end
				
				GMaster:Debug("Receiving Ping from "..player)
				AddonList = {} --clear the table of stores addon start times
				SendTo = player --store who pinged, in case this addon need to send its data to the pinger
				
				GMSettings.Active = false --stop it recording to its own table
				
				tinsert(GMaster.Timers, {runonce = true, interval = 4, elapsed = 0, func = Timer})
				SendAddonMessage("GMPong", LoginTime.."|"..isBusy.."|"..GMSettings.Version, "GUILD")
				
				GMaster:Debug("sent pong, waiting to decide")
		elseif prefix == "GMPong" then --records all pongs, including itself
			GMaster:Debug(msg.." got pong")
			local dated, busy = msg:match("(%d+)|(%d+).+")
			local version = tonumber(msg:match(".+|(%d+%p+%d+)"))
				if (not version) or (version < GMSettings.Version) then
					ignorelist[player] = true
					return
				end
			busy = tonumber(busy)
			dated = tonumber(dated)
			GMaster:Debug(dated, busy)
			if dated then
				AddonList[#AddonList+1] = {login = dated, player = player, busy = busy}
			end
		elseif prefix == "GMDelete" then
			msg = tonumber(msg)
			if GMLogs[msg] then
				GMLogs[msg] = nil
			end
		elseif prefix == "GMUpdate" then
			--GMaster:Debug("received update")
			if msg:find("^|Loot") then
				local money = msg:match("|Loot|(%d+)")
				if money then
					money = tonumber(money)
					GMaster.AddInfo(player, "current", 25, money)
				end
			elseif msg:find("^|Rep") then
				local rep = msg:match("|Rep|(%d+)")
				if tonumber(rep) then
					rep = tonumber(rep)
					GMaster.AddInfo(player, "current", 26, rep)
				end
			elseif msg:find("^|Loc") then  -- if the thing to update is the zone info
				local zoneType, interval = msg:match("|Loc(%w+)|int(%d+)")
				interval = tonumber(interval)
				GMaster.AddInfo(player, "current", 2, interval) --updated the general online time

				if not GMRoster[player] then
					GMRoster[player] = {}
				end
				
				if zoneType == "pvp" then
					GMaster.AddInfo(player, "current", 4, interval)
				elseif zoneType == "arena" then
					GMaster.AddInfo(player, "current", 5, interval)
				elseif zoneType == "party" then
					GMaster.AddInfo(player, "current", 6, interval)
				elseif zoneType == "raid" then
					GMaster.AddInfo(player, "current", 7, interval)
				end
				
			elseif msg:find("^BG|") then
				GMaster:Debug("update bg")
				for i, v in msg:gmatch("|(%d+):(%d+)") do
					i = tonumber(i)
					v = tonumber(v)
					GMaster:Debug(i, v)
					GMaster.AddInfo(player, "current", i, v)
				end
				
			end
			
		elseif prefix == "GMBroadcast" then
			if not (player == PlayerName) then --make sure it doesnt listen to its own broadcasts
			GMaster:Debug(player, PlayerName)
			
				--need to check that no tables overlap
				
				
				local startTime, endTime = msg:match("|(%d+)-(%d+)|") 
				GMaster:Debug("Recieving old table start times: "..startTime.." from "..player)
				startTime = tonumber(startTime) --make sure its using numbers
				endTime = tonumber(endTime)
				-- this needs to delete any tables that started inside the duration of other tables
				for dated, info in pairs(GMLogs) do
					if  info.LastRecord then
						if startTime > dated and endTime < info.LastRecord then
								GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMDelete", startTime}
						end
					end
					return
				end
				
					if GMLogs[startTime] then --if it already has a table that started the same time
						if endTime == GMLogs[startTime].LastRecord then --its the same table (hopefully)
							GMaster:Debug("I already have this table: "..startTime)
						elseif endTime > GMLogs[startTime].LastRecord then
							if not RequestTable[startTime] then
								GMaster:Debug("requesting send of table: "..startTime)
								GMLogs[startTime] = {} -- nil mine out to prevent tainting
								GMLogs[startTime].LastRecord = endTime
								GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMRequest"..player, startTime}
								RequestTable[startTime] = true
							end
						elseif  GMLogs[startTime].LastRecord > endTime then
							--my table is bigger, broadcast its size
							GMaster:Debug("larger version of the same table found, broadcasting")
							GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMBroadcast", "|"..startTime.."-"..GMLogs[startTime].LastRecord.."|"}
						end
					else
						--i dont have that table, please send it
						if not RequestTable[startTime] then
							GMaster:Debug("Table not found, requesting: "..startTime)
							GMLogs[startTime] = {} 
							GMLogs[startTime].LastRecord = endTime
							GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMRequest"..player, startTime}
						end
					end
					--need to check for missing tables somehow
			end
			-- record the tables and see which are needed
		elseif prefix:find("^GMSend"..PlayerName)  then
			GMaster:Debug("this should be recievingg the player name: "..prefix)
			---[[
			local dated, name = msg:match("^|(%d+)|(.-)|")
			dated = tonumber(dated)
			
			GMaster:Debug("receiving table "..dated)
			for index, value in msg:gmatch("|(%d+):(%d+)") do
				value = tonumber(value)
				index = tonumber(index)
				if GMLogs[dated] then
					local lastrecord = GMLogs[dated].LastRecord -- this should hopefuly retain the original lastrecord value of the table
																						-- rather than updating it with a new lastrecord
					
					GMaster:Debug(dated, (lastrecord or "lastrecord not found"))
						GMaster.AddInfo(name, dated, index, value, lastrecord)
						GMaster:Debug("This is recievingplayer name: "..name..", positon:"..index..", and value: "..value..". Dated = "..dated)
				end
			end
			--]]
		elseif prefix:find("^GMRequest"..PlayerName) then
			GMaster:Debug("Detected Request: "..player..""..PlayerName)
			if PlayerName ~= player then
				
				msg = tonumber(msg)
				if GMLogs[msg] then --if its got the table that the other addons want
					for name, info in pairs(GMLogs[msg]) do
						if not (name == "LastRecord") then -- we dont want it to send the LastRecord value.
							GMaster:Debug("request for table "..msg.." found, Sending it ")
							local message = "|"..msg.."|"..name.."|"
							for i = 1, #info do
								if info[i] ~= 0 then
									message = message..i..":"..(info[i]).."|"
								end
									if (string.len(message) > 200) or i == #info then --if its too big or its the last data
										GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMSend"..player, message}
										message = "|"..msg.."|"..name.."|"
									end
								--end
							end
							GMaster:Debug(message.."this is being sent out in reply to a request")
						end
					end
				end
			end
		elseif prefix:find("^GMCurrentStart"..PlayerName) then
				GMaster:Debug("Recieved start from"..player)
				GMaster:Debug("setting start of table to "..msg)
				GMSettings.StartTime = tonumber(msg)
				if not GMLogs then
					GMLogs = {}
				end
				GMLogs[GMSettings.StartTime] = {}
				GMSettings.Active = nil --stop the other addon recording directly to the table
				--recieve the current table name
		elseif prefix:find("GMCurrent"..PlayerName) then
			--sort the msg and apply it directly to the table
			GMaster:Debug("Recieving current table from "..player.."msg = "..msg)
			local name = msg:match("^(.-)|")
			if not name then return end --temporary fix until i can work out why name wouldnt get sent out, or would get recorded as nothing
			GMaster:Debug("name = "..name)
			
			for index, value in msg:gmatch("|(%d+):(%d+)") do
				index = tonumber(index)
				value = tonumber(value)
				GMaster.AddInfo(name, "current", index, value)
			end
		
		
		elseif prefix:find(("^GMCurrentEnd"..PlayerName)) or (prefix:find("^GMCurrentEnd") and (player == PlayerName)) then
			--if its the oldest addon or the newest, start them recording again
			GMaster:Debug("Recieved End from"..player)
			local msg = "|"
			
			PingSent = nil
			GMSettings.Active = true
			--[[
				At this point, the master addon should have sent all of the info for 
				the current table to the new addon.
				The new addon and old addon now need to share with each other which tables they have, so that they
				can find out which tables they are missing
			--]]
			if GMLogs then
				for dated, info in pairs(GMLogs) do
					if not (dated == GMSettings.StartTime) then --dont send the current table
						if info.LastRecord then
						GMaster:Debug("info.LastRecord = "..info.LastRecord)
						msg = msg..dated.."-"..info.LastRecord.."|"
						GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMBroadcast", msg}
						msg = "|"
						GMaster:Debug("Sending old tables: "..msg)
						end
					end
				end
			end
		end
	end

	local test = CreateFrame("Frame")
	test:RegisterEvent("PLAYER_LEAVING_WORLD")
	test:SetScript("OnEvent", function() GMSettings.LastLogout = tonumber(time()) end)

end

GMaster.LoadOrder.GMSync = true