--[[
1. Summary
2. Details
3. Structure
4. Changes
5. To Do

--========================== 1. Summary ===============================
	Records which alts are in the same guild, 
	and shares this info with other players.
--========================== 2. Details ===============================
	Upon logging in, the module checks to see if the player is in a guild:
	if they are, it creates a record and stores their name under their guild name.
	all alts in the current guild are then broadcast out for other players to receive.
	upon receiving a name from a player, the name is added to the addons roster under the players name.
--========================== 3. Structure =============================
	
--========================== 4. Changes ===============================
2.1
	--removes alts no longer in the guild.

1.4
	Broadcasting alts now works.
	Recieving and recording alts now works.
--========================== 5. To do =================================
	Add method of removing alts if they changed guilds
	integrate the alts feature into all of the other modules that need it.
]]

GMaster.LoadOrder.GMAlts = true

function GMaster.AL.GMAlts() --load on ADDON_LOADED

	local name = GMaster.PlayerName
	local guild = GetGuildInfo("player")
	
	if not GMAlts then
		GMAlts = {}
	end
	
	if guild then
		if not GMAlts[guild] then
			GMAlts[guild] = {}
		end
		if not GMAlts[guild][name] then
			GMAlts[guild][name] = {}
		end
	end
	
	

	
	function GMaster.PEW.SendAlts()
				--check alts:
		for name, info in pairs(GMRoster) do
			if info.Alts then
				for alt in pairs(info.Alts) do
					if not GMRoster[alt] then
						GMRoster[name].Alts[alt] = nil
					end
				end
			end
		end	
	
	
		if GMaster.LastLogin < (time() - 3600) then
			if GMAlts[guild] then
				local msg = "|"
				for alt, v in pairs(GMAlts[guild]) do
					msg = msg..alt.."|"
				end
				
				GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMAlts", msg}
			end
			
		end
		GMaster.PEW.SendAlts = nil --remove itself once it has run
	end
	
	function GMaster.CMA.ReceiveAlts(prefix, msg, channel, player)
		if prefix == "GMAlts" then
			for alt in string.gmatch(msg, "(.-)|") do
				if not (alt == "") then
					if GMRoster[player] then
						if not GMRoster[player].Alts then
							GMRoster[player].Alts = {}
						end
						GMRoster[player].Alts[alt] = true
					end
				end
			end
		end
	end
end

function GMaster.ModuleSettings.GMAlts()
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

function GMaster.ModuleLoad.GMAlts()
	--enable the module
		GMaster.AL.GMAlts()
	
	--create settings page
	
	
end

function GMaster.ModuleRemove.GMAlts()
	GMaster.CMA.ReceiveAlts = nil --prevent it from receiving alts, for what its worth
	return true
end


