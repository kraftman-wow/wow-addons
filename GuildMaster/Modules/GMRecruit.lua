--[[
1. Summary
2. Details
3. Structure
4. Changes
5. To Do

--========================== 1. Summary ===============================
	Auto announces different guild recruitment messages from different players
	in the guild.
--========================== 2. Details ===============================
	This module aims to promote your guild more and from a diverse range of players by alternating who places recruitment adds in the trade channel. 
	Upon entering a city, the module will place your advert, and then broadcast to all other addons that it has done so. Until leave the city and re-enter, it will not place any more adverts.
	Depending on the interval set by the GM or officer, any other players entering a city within the next X minutes will not place any adverts.
	After X minutes, any player entering a city will once again place an advert.
	As many adverts as you like can be added, and will be synced to other players with the addon. 
	If more than one advert is found, the advert posted will be randomly chosen form all found.
--========================== 3. Structure =============================
	
--========================== 4. Changes ===============================
1.4
	Broadcasting alts now works.
	Recieving and recording alts now works.
--========================== 5. To do =================================
	Get the settings for the module working again.
	broadcast needs to handle longer messages
	
]]



GMaster.LoadOrder.GMRecruit = true --can change this to force disable the addon

local module = {}

function GMaster.AL.GMRecruit()

	function GMaster.GFL.GMRecruit()
		
		local save = GMSettings.modules.GMRecruit
		
		if not save.Requests then
			save.Requests = {}
		end
		
		if not save.Messages then
			save.Messages = {}
		end
			
		local function FriendList_Update()
			for i = 1, GetNumWhoResults() do
				local name = GetWhoInfo(i)
				if name == applicant then
				
				end
			end
		end
		
		local old_FreindsEvent = FriendsFrame_OnEvent(self, event, ...)
			
		FriendsFrame_OnEvent = function(self, event, ...)
			if (event == "WHO_LIST_UPDATE") and RECRUIT_WAITING then
				FriendList_Update()
			else	
				old_FreindsEvent(self, event, ...)
			end
		end
	
	
		--[[
			need to hook the buttons and provide a method of delaying the
			functions until the player comes online
			
			GuildRecruitmentInviteButton
			GuildRecruitmentMessageButton
			GuildRecruitmentDeclineButton
				local name, level, class, bQuest, bDungeon, bRaid,
				bPvP, bRP, bWeekdays, bWeekends, bTank, bHealer,
				bDamage, comment, timeSince, timeLeft = GetGuildApplicantInfo(self.index)
		
		--]]
		
		local function QueueInvite(self)
			local name = GetGuildApplicationInfo(GetGuildApplicantSelection())
			
			
			--[[
				check if the player is online
				if they are, invite them
				if they arent, queue the invite
			
			--]]
		
		end
		
		local function QueueMessage()
			local name = GetGuildApplicationInfo(GetGuildApplicantSelection())
			--[[
				--check if the player is online
				--if they are online, ChatFrame_SendTell("playername")
				--if they arent online, record the message and queue it
				
				--if mail box i open, mail the message
				--next time they are online, whisper them
				need to find a way to see if the message was delivered or not
			--]]
		end
		
		GuildRecruitmentInviteButton:HookScript("OnClick", QueueInvite)
		GuildRecruitmentMessageButton:SetScript("OnClick", QueueMessage)
	
	local function Checker(name)
		SetWhoToUI(1)
		SendWho(name)
		RECRUIT_WAITING = true
		
		GMTimer:NewTimer(3, function() RECRUIT_WAITING = nil end, 
	
	end
	--[[
		Checker:
		SetWhoToUI(1)
		set request bool
		SendWho (remember to add name prefix)
		SetWhoToUI(0)
		check who list
	--]]
	
	--character limit 255
	end

	if not module.Eventler then
		module.Eventler = CreateFrame("Frame")
	end
	
	if not GMSettings.GMRecruit then
		GMSettings.GMRecruit = {Active = true, lastsent = 0, delay = 10}
		GMSettings.GMRecruit.list = {}
	end
	
	local Eventler = module.Eventler
	
	
	Eventler.elapsed = 0
	Eventler.interval = 10 --this waits for a few seconds after entering a zone,



	local function Timer(self, elapsed)
		
		Eventler.elapsed = Eventler.elapsed + elapsed
			if Eventler.elapsed > Eventler.interval then
				Eventler.elapsed = 0
				Eventler:SetScript("OnUpdate", nil)
				local i = GetChannelName("Trade") 
				if i > 0 then
					
					SendAddonMessage("GMRecruitPing", time(), "GUILD") -- let other addons know
					if #GMSettings.GMRecruit.list > 0 then
						SendChatMessage(GMSettings.GMRecruit.list[math.random(#GMSettings.GMRecruit.list)].msg, "CHANNEL", nil, i)
					end
				end
			end
	end


	local function EventHandler(self, event, prefix, msg, channel, player)
		if event == "ZONE_CHANGED_NEW_AREA" then
			if time() - GMSettings.GMRecruit.lastsent> (GMSettings.GMRecruit.delay*60) then
				Eventler:SetScript("OnUpdate", Timer)
			end
		elseif event == "CHAT_MSG_ADDON" then
			if prefix == "GMRecruitPing" then
				GMSettings.GMRecruit.lastsent = tonumber(msg)
				
			elseif prefix == "GMRecruitNew" then
				local pos, dated, msg = msg:match("(%d+)|(%d+)|(.+)")
					if pos then
						pos = tonumber(pos)
						dated = tonumber(dated)
						if not GMSettings.GMRecruit.list[pos] then
							GMSettings.GMRecruit.list[pos] = {dated = dated, msg = msg}
						else
							local loc = GMSettings.GMRecruit.list[pos]
							if loc.dated == dated then
								--both the same, do nothing	
							elseif loc.dated < dated then
								--new values, update
								loc.dated = dated
								loc.msg = msg
							elseif loc.dated > dated then
								--it has old values, broadcast new values
								GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMRecruitNew", pos.."|"..loc.dated.."|"..loc.msg}
							end
						end
					end
			end
		
			
				
			
		elseif event == "PLAYER_ENTERING_WORLD" then
			if not GMSettings.GMRecruit then
					GMSettings.GMRecruit = {Active = true, lastsent = 0, delay = 10, list = {}}
			end
			if GMaster.LastLogin < (time() - 3600) then
				for i = 1, #GMSettings.GMRecruit.list do
				local loc = GMSettings.GMRecruit.list[i]
					GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMRecruitNew", i.."|"..loc.dated.."|"..loc.msg}
				end
			end
			GMSettings.GMRecruit.lastsent = time() --stops the first spam when logging in.
			Eventler:UnregisterEvent("PLAYER_ENTERING_WORLD")
		end
	end



	Eventler:RegisterEvent("CHAT_MSG_ADDON")
	Eventler:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	Eventler:RegisterEvent("ADDON_LOADED")
	Eventler:RegisterEvent("PLAYER_ENTERING_WORLD")
	Eventler:SetScript("OnEvent", EventHandler)
end



function GMaster.ModuleSettings.GMRecruit()
	local parent = CreateFrame("Frame")
			parent.titleText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			parent.titleText:SetPoint("TOPLEFT", parent, "TOPLEFT", 30, -40)
			parent.titleText:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -30, 40)
			parent.titleText:SetJustifyH("LEFT")
			parent.titleText:SetJustifyV("TOP")
			parent.titleText:SetText()
			
			--[[
				need option to choose the channel, and the update frequency.
			
			--]]
		return parent
end

function GMaster.ModuleLoad.GMRecruit()
	--enable the module
		GMaster.AL.GMRecruit()
	
end

function GMaster.ModuleRemove.GMRecruit()
	module.eventler:SetScript("OnEvent", nil)
	return true
end