--[[
1. Summary
2. Details
3. Structure
4. Changes
5. To Do

--========================== 1. Summary ===============================
	Refreshes the guild message of the day at set intervals
--========================== 2. Details ===============================
	Aimed to encourage players to actually read the message of the day, 
	This module will refresh the current message of the day at set intervals, 
	Making it appear in guild chat.
	The duration between update can be set in the interface options for the module.
--========================== 3. Structure =============================
	
--========================== 4. Changes ===============================
1.6
	-should sync updates with other players
1.52:
	Hopefully fixed the update bug.
1.5
Should now work!
--========================== 5. To do =================================
	Sync duration with other players
	Add the duration slider to the edit box of the MOTD
]]


local module = {}

GMaster.LoadOrder.GMOTD = true --add it into the addon list

function GMaster.AL.GMOTD()
	GMSettings.MOTDinterval = GMSettings.MOTDinterval or 3600

	function GMaster.GFL.GMOTD()
		if CanEditMOTD() then
			GMSettings.lastMOTD = GMSettings.lastMOTD or time()
			
			
			function module.RefreshMOTD()
				
				if (time() - GMSettings.lastMOTD) > GMSettings.MOTDinterval then
					local motd = GetGuildRosterMOTD()
					if motd and type(motd) =="string" and not motd == "" then
						GuildSetMOTD(motd)
					end
					GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMOTD", time()}				
				end
			end
			
			function GMaster.CMA.CheckMOTD(prefix, msg, channel, player)
				if prefix == "GMOTD" then
					local lastsent = tonumber(msg)
					if lastsent then
						GMSettings.lastMOTD = lastsent
					end
				end
			end
			tinsert(GMaster.Timers, {runonce = false, interval = 60, elapsed = 0, func = module.RefreshMOTD}) --checks every 60 seconds to see if it needs updating
		end
	end
end

function GMaster.ModuleSettings.GMOTD()
	local parent = CreateFrame("Frame")
			parent.titleText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			parent.titleText:SetPoint("TOPLEFT", parent, "TOPLEFT", 30, -40)
			parent.titleText:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -30, 40)
			parent.titleText:SetJustifyH("LEFT")
			parent.titleText:SetJustifyV("TOP")
			parent.titleText:SetText("GM-MOTD resheses the MTOD, so you don't have to."
																.."\n Just drag the slider to set the update duration")
			
			
			parent.delaySlide =  CreateFrame("Slider", "GMOTDSlide", parent, "OptionsSliderTemplate")
	parent.delaySlide:SetWidth(300)
	parent.delaySlide:SetHeight(20)
	parent.delaySlide:SetMinMaxValues(10, 60)
	parent.delaySlide:SetValueStep(1)

	parent.delaySlide:SetPoint("TOP", 0 , -100)
	parent.delaySlide:SetScript("OnValueChanged", function(self, value) GMSettings.MOTDinterval = value*60 end)
	parent.delaySlide:SetValue(GMSettings.MOTDinterval/60)

	GMOTDSlideLow:SetText("10 minutes")
	GMOTDSlideHigh:SetText("1 hour")
		return parent
end

function GMaster.ModuleLoad.GMOTD()
	GMaster.AL.GMOTD()
	if GMaster.GUILD_FRAME_LOADED then
		GMaster.GFL.GMOTD()
	else
		LoadAddOn("Blizzard_GuildUI")
	end
end

function GMaster.ModuleRemove.GMAlts()
	module.RefreshMOTD = function() end
	return true
end