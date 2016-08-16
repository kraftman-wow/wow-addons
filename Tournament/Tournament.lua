
TournamentDB = {}
TournamentSessions = {}
local Top20 = {}
TournamentDB.Enabled = true
local function TournamentFind(player)
player = strlower(player)
local found
	for i = 1, #TournamentDB do
		if (strlower(TournamentDB[i].names) == player ) then
			found = 1
			return i
		end
	end
	if not found then
		return nil
	end
end

local function TournamentEvent(self, event, msg, name) --handles system events and whispers

	if ( event == "CHAT_MSG_SYSTEM" ) then -- read the duel message and enter it in the table
		local month, day, year, hour, minute, second = date("%m"), date("%d"), date("%y"), date("%H"), date("%M"), date("%S") 
		
		if msg:find("([^%s]+) has defeated ([^%s]+) in a duel") then -- find the two player names
			local player1, player2 = msg:match("([^%s]+) has defeated ([^%s]+) in a duel")
			local found1 = TournamentFind(player1)                  --find if the players already exist in the table
			local found2 = TournamentFind(player2)
												
				if found1 then --if the winner is found, change the date/time, increment the wins by 1
				TournamentDB[found1].lastupdate = {month = month, day = day, year = year, hour = hour, minute = minute, second = second}
				TournamentDB[found1].win = TournamentDB[found1].win + 1
					if found2 then -- if the loser is found as well, edit the rating based on the rating from the table
						local difference = TournamentDB[found1].XP - TournamentDB[found2].XP
						if (abs(difference) < 240) then
							if ( difference > 0 ) then
							--print(player1.." before: "..TournamentDB[found1].XP)
								TournamentDB[found1].XP = (TournamentDB[found1].XP + floor(10 - (10*difference)/300)+0.5)
							--print(player1.." after: "..TournamentDB[found1].XP)
							elseif ( difference < 0 ) then
							--print(player1.." before: "..TournamentDB[found1].XP)
								TournamentDB[found1].XP = (TournamentDB[found1].XP + floor(10 + (10*difference)/300)+0.5)
							--print(player1.." after: "..TournamentDB[found1].XP)
							end
						end
						if (abs(difference) >= 240) then
							if ( difference > 0 ) then
								TournamentDB[found1].XP = floor(TournamentDB[found1].XP + 2.5) --0.5 for rounding
							elseif ( difference < 0 ) then
								TournamentDB[found1].XP = floor(TournamentDB[found1].XP + 18.5)
							end
						end
					else -- the loser doesnt exist in the table, just give the winner 5 points
						TournamentDB[found1].XP = TournamentDB[found1].XP + 5
					end
				else -- the winner doesnt exist in the table, create a new entry based on the losers xp if it exists
					local newxp = 0
					if found2 then
						local difference = 1500 - TournamentDB[found2].XP
						if (abs(difference) < 300) then
							if ( difference > 0 ) then
								newxp = floor((1500 + 10 - (10*difference)/300) +0.5)
							elseif ( difference < 0 ) then
								newxp = floor((1500 + 10 + (10*difference)/300) +0.5) 
							end
						end
						
						tinsert(TournamentDB, {names = player1, win = 1, lose = 0, XP = newxp}) -- create the new table entry
					else
						tinsert(TournamentDB, {names = player1, win = 1, lose = 0, XP = 1505})
					end
				end
				found1 = nil --reset these
				found2 = nil 
				local found1 = TournamentFind(player1)                  --find if the players already exist in the table
				local found2 = TournamentFind(player2)
				
				if found2 then -- as above excetp from the loser
					TournamentDB[found1].lastupdate = {month = month, day = day, year = year, hour = hour, minute = minute, second = second}
					TournamentDB[found2].lose = TournamentDB[found2].lose + 1
					if found1 then
						local difference = TournamentDB[found1].XP - TournamentDB[found2].XP
						if (abs(difference) < 240) then
							if ( difference > 0 ) then
							--print(player2.." before: "..TournamentDB[found2].XP)
								TournamentDB[found2].XP = floor(TournamentDB[found2].XP - (10 - (10*difference)/300) - 0.5)
							--print(player2.." after: "..TournamentDB[found2].XP)
							elseif ( difference < 0 ) then
								TournamentDB[found2].XP = floor(TournamentDB[found2].XP - (10 + (10*difference)/300) - 0.5)
							end
						end
						if (abs(difference) < 240) then
							if ( difference > 0 ) then
								TournamentDB[found2].XP = floor(TournamentDB[found2].XP - 2.5)
							elseif ( difference > 0 ) then
								TournamentDB[found2].XP = floor(TournamentDB[found2].XP - 18.5)
							end
						end
					else
						TournamentDB[found2].XP = TournamentDB[found2].XP + 5
					end
				else
					local newxp = 0
					if found1 then
						local difference = 1500 - TournamentDB[found1].XP
						if (abs(difference) < 300) then
							if ( difference > 0 ) then
								newxp = floor(1500 - (10 - (10*difference)/300))
							elseif ( difference < 0 ) then
								newxp = floor(1500 - (10 + (10*difference)/300))
							end
						end
						tinsert(TournamentDB, {names = player2, win = 0, lose = 1, XP = newxp, lastupdate = {month = month, day = day, year = year, hour = hour, minute = minute, second = second}})
					else
						tinsert(TournamentDB, {names = player2, win = 0, lose = 1, XP = 1495, lastupdate = {month = month, day = day, year = year, hour = hour, minute = minute, second = second}})
					end
				end
				table.sort(TournamentDB, function (a,b) return a.XP > b.XP end)
		end
	end
	if ( event == "CHAT_MSG_WHISPER" ) then -- handle all whispers from players
		msg = strlower(msg)	
		if msg:find("^commands") then
			SendChatMessage("Current commands are: 'rank' to get your own rank, 'rank#' to find the player of the #th rank, 'top#' to return the top # players, 'who [player]' to find the info for a player, and 'rating' to get your current 1v1 rating", "WHISPER", nil, name)
		end	
		if msg:find("^rank") then -- this needs editing to do ^rank$ vs ^rank %d$
			if msg:find("^rank%d+") or msg:find("^rank %d+") then
				local search = msg:match("^rank(%d+)") or msg:find("^rank (%d+)")
				if tonumber(search) then
				search = tonumber(search)
					if TournamentDB[search] then
						SendChatMessage(TournamentDB[search].names.." is ranked at "..search..", with "..TournamentDB[search].win.." wins, "..TournamentDB[search].lose.." losses", "WHISPER", nil, name)
					else
						SendChatMessage("There is currently no one ranked"..search, "WHISPER", nil, name)
					end
				else
					SendChatMessage("Try 'rank' followed by a number", "WHISPER", nil, name)
				end
				return
			end
			local found = TournamentFind(name) 
			if found then
				SendChatMessage("You are ranked: "..found.."/"..#TournamentDB..". Won: "..TournamentDB[found].win.." Lost: "..TournamentDB[found].lose, "WHISPER", nil, name)
			else
				SendChatMessage("You are currently unranked, duel someone!", "WHISPER", nil, name)
			end
		end	
		if msg:find("^rating") then -- find their ratign and tell them it
		local found = TournamentFind(name)
			if found then
					SendChatMessage("Your current 1v1 rating is: "..floor(TournamentDB[found].XP), "WHISPER", nil, name)
			else
					SendChatMessage("You are currently unrated, duel someone!", "WHISPER", nil, name)
			end
		end
		if msg:find("^who ([^%s]+)") then -- find the player they are looking for and return the players info
			local player = msg:match("^who ([^%s]+)")
			local found = TournamentFind(player)
			if found then	
			if msg:find("^who ([^%s]+) say") then
				SendChatMessage(player.." is ranked: "..found.."/"..#TournamentDB..", "..TournamentDB[found].win.." wins, "..TournamentDB[found].lose.." losses, 1v1 rating: "..TournamentDB[found].XP, "SAY")
				
			else
				SendChatMessage(player.." is ranked: "..found.."/"..#TournamentDB..", "..TournamentDB[found].win.." wins, "..TournamentDB[found].lose.." losses, 1v1 rating: "..TournamentDB[found].XP, "WHISPER", nil, name)
			end
			else
				SendChatMessage(player.." is unranked", "WHISPER", nil, name)
			end
		end
		if msg:find("^top%d+") then -- if they ask to see the top players, whisper it it, if they say 'say', say it
			local count = msg:match("^top(%d+)") -- but limit the say
				if msg:find("^top%d+ say") then
					SendChatMessage("Current top "..count.." duelists are:", "SAY")
						for i = 1, count do
							SendChatMessage(i..": "..TournamentDB[i].names.." - won: "..TournamentDB[i].win.." lost: "..TournamentDB[i].lose, "SAY")
						end
					SendChatMessage("Whisper me saying 'commands' to find out your duel rank and info :)", "SAY")	
				
					return
				end
			
				if tonumber(count) then
				count = tonumber(count) 
					if (count > 20) then
						count = 20
					end
				else
					SendChatMessage("try a number less than 20, eg 'top10' ", "WHISPER", nil, name)
						
					return
				end
			SendChatMessage("Current top "..count.." duelists are:", "WHISPER", nil, name)
				for i = 1, count do
					SendChatMessage(i..": "..TournamentDB[i].names.." - won: "..TournamentDB[i].win.." lost: "..TournamentDB[i].lose, "WHISPER", nil, name)
					--print(i..": "..TournamentDB[i].names.." - won: "..TournamentDB[i].win.." lost: "..TournamentDB[i].lose)
				end
			SendChatMessage("Whisper me saying 'commands' to get more info on your rank/duel statistics", "WHISPER", nil, name)	
		end		
	end	
end


local f = CreateFrame("Frame", "TournamentToggleFrame")
f:RegisterEvent("CHAT_MSG_SYSTEM")
f:RegisterEvent("CHAT_MSG_WHISPER")
f:SetScript("OnEvent", TournamentEvent)

local function TournamentToggle()
local f = _G["TournamentToggleFrame"]
	if TournamentDB.Enabled then
		TournamentDB.Enabled = nil
		f:UnregisterEvent("CHAT_MSG_SYSTEM")
		print("Tournament disabled")
	else
		TournamentDB.Enabled =  true
		f:RegisterEvent("CHAT_MSG_SYSTEM")
		print("Tournament enabled")
	end
end
local function AddonSync()
--[[
on login, send the date of the last most recent update
other addons then reply with just thier updated info.

]]
end

local function TournSlashHandler(msg)
	if msg:find("^clear$") then
		wipe(TournamentDB)
		print("Tournament has been reset")
	end

	if msg:find("^toggle$") then
		TournamentToggle()
	end
	if msg:find("^reset ([^%s]+)") then
	local player = msg:match("^reset ([^%s]+)")
		for i = 1, #TournamentDB do
			if ( TournamentDB[i].names == player ) then
				TournamentDB[i].XP = 1500
				TournamentDB[i].win = 0
				TournamentDB[i].lose = 0
			end
		end
		table.sort(TournamentDB, function (a,b) return a.XP > b.XP end)
	end

	if msg:find("^test") then -- used to clean up things
		for i = 1, #TournamentDB do
			
		end
	end

	if msg:find("^hardpurge") then
	--[[local found = 0
		for i = 1, #TournamentDB do
			local day = date("%d")
			if TournamentDB[i] then
			if TournamentDB[i].lastupdate then
				if (#TournamentDB[i].lastupdate.day < (day - 5)) then
					found = found + 1
					table.wipe(TournamentDB[i])
				end
			end
			end
		end
		print(found.." entries removed")
		table.sort(TournamentDB, function (a,b) return a.XP > b.XP end)]]
	end

	if msg:find("^say top%d*") then -- pretty much the same as the whisper stuff.
	local count = tonumber(msg:match("^say top(%d*)"))
		SendChatMessage("Current top "..count.." duelists are:", "SAY")
		for i = 1, count do
			SendChatMessage(i..": "..TournamentDB[i].names.." - won: "..TournamentDB[i].win.." lost: "..TournamentDB[i].lose, "SAY")
						--print(i..": "..TournamentDB[i].names.." - won: "..TournamentDB[i].win.." lost: "..TournamentDB[i].lose)
		end
		SendChatMessage("Whisper me saying 'commands' to get more info on your rank/duel statistics", "SAY")

	end

	if msg:find("^who ([^%s]+)") then
		local player = msg:match("^who ([^%s]+)")
		local found = TournamentFind(player)
		if found then	
			print(player.." is ranked: "..found.."/"..#TournamentDB..", "..TournamentDB[found].win.." wins, "..TournamentDB[found].lose.." losses, 1v1 rating: "..TournamentDB[found].XP)
		else
			print(player.." is unranked")
		end
	end
end

SLASH_Tourn1 = "/tourn";
SlashCmdList["Tourn"] = TournSlashHandler;

local function TournamentTooltip()
	local found = TournamentFind(GameTooltip:GetUnit())
	
	if found then
		GameTooltip:AddLine("Rank: "..found.."/"..#TournamentDB..", 1v1 Rating: "..floor(TournamentDB[found].XP + 0.5))
		GameTooltip:AddLine("Won: "..TournamentDB[found].win..", Lost: "..TournamentDB[found].lose)
		GameTooltip:Show()
	end
 
end
GameTooltip:HookScript("OnTooltipSetUnit", TournamentTooltip)
