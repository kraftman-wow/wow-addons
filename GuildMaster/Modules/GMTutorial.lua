--[[
1. Summary
2. Details
3. Structure
4. Changes
5. To Do

--========================== 1. Summary ===============================
A breif wizard to explain the functionality of the addon and each module.
--========================== 2. Details ===============================
	runs through each module with extra info on how the module works, 
	and the settings
--========================== 3. Structure =============================
	
--========================== 4. Changes ===============================
1.52
	Created the module.
--========================== 5. To do =================================
Everything
]]


--[[
For guild masters:
Welcome to guild master: it appears that you are in fact a guild master! Which is good because this
 addon is designed for you! This tutorial will run you through come of the functionality of the addon, 
 showing you each module and what it does. It's a bit of a read but its worth it, if you want to re read it
 any time, you can do so from the interface options.
 
 General:
 Guild master is designed to make every aspect of managing a guild easier for you. It does this by allowing
 you to automate laborious tasks such as ranking members based on their contributions, organising events,
 recruiting new members, etc.
 The addon is made up of a number of modules, which can be enabled or disabled depending on which you require them.
 
 
 The following is a breif summary of each module, and settings which will be reflected throughout the guild.
 
 GMAlts:
 This module records the alts of each player, and shares this information between guild members. 
 It is then used to group the player with their alts in the roster, to show a players total contribution 
 to the guild from all alts, and to rank the alts if you wish.
 
 Settings: Enable/disable
 
 
 GMEvent:
 This module allows you to quickly invite guild members to events based on certain requirements. It will not 
 invite anyone who is busy (in a party/battleground/instance/arena) and you can choose a minimum level, item
 level, or resilience. Any member who does not meet the requirement will not receive the invitation.
 Players that are invited choose which role they will fulfill, and players are no longer invited once each 
 role becomes full.
 Settings: Enable/disable
 
 GMForum:
 This module adds a forum to the guild frame which allows you to communicate with offline guild members.
 Each topic can be expanded/collapsed to show the replies. guild masters can delete any posts
 
 GMGuildFrame:
 This module is purely cosmetic; it rearranges the guild frame to make it more usable: the "Add Member" and "Guild Control buttons are on the first page, 
 for easier access. The perks and reputation rewards are both on the rewards page, and the MOTD, events, and news are on the main page.
 The 
 
 GMLocator:
 This module transmits location data from 


--]]
--================ GUI Stuff  =========================

local GMPages = {{x = 300, y = 150, title = "GMaster", body = "Welcome to the new improved Guild Master Suite!\nThis module provides a breif overview of what all of the other modules do."},
								 {x = 300, y = 150, title = "GM-Alts", body = "Shares data between players about whose alts are whose, so you know who your talking to. There is no graphical component."},
								 {x = 300, y = 150, title = "GM-Banker", body = "Adds filters to the guild bank so that you can auto sort all items by price/type/quality. Also allows you to view the guild bank without being near it."},
								 {x = 300, y = 150, title = "GM-Event", body = "Allows you to quickly start a guild event, only inviting players that meet your requirements (item level/resilience)/nClick 'New Event' In the guild frame to get started."},
									{x = 300, y = 150, title = "GM-GuildFrame", body = "Modifies the guild frame, relocating features to make the more useful aspects easier to access."},
									{x = 300, y = 150, title = "GM-Locator", body = "Shows guild members on the world map."},
									{x = 300, y = 150, title = "GM-MOTD", body = "Auto refreshes the guild message of the day a set intervals."},
									{x = 300, y = 150, title = "GM-Ranker", body = "Allows you to auto rank guild members based on certain criteria."},
									{x = 300, y = 150, title = "GM-Forum", body = "Adds an in-game forum to the guild frame, allowing you to communicate with offline players."},


									}
									
local Pages = {
}


GMaster.LoadOrder.GMTutorial = true

local TutFrame = CreateFrame("Frame", nil, UIParent)
TutFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
                                            edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
                                            tile = true, tileSize = 16, edgeSize = 16, 
                                            insets = { left = 4, right = 4, top = 4, bottom = 4 }});
TutFrame:SetBackdropColor(0,0,0,1);


--=====================================================
TutFrame.Page = 1


TutFrame.close = CreateFrame("Button", nil, TutFrame, "UIPanelButtonTemplate")
TutFrame.close:SetText("x")
TutFrame.close:SetSize(15, 20)
TutFrame.close:SetPoint("TOPRIGHT", -5, -5)
TutFrame.close:SetScript("OnClick", function() TutFrame:Hide() end)

TutFrame.forward = CreateFrame("Button", nil, TutFrame, "UIPanelButtonTemplate")
TutFrame.forward:SetText(">")
TutFrame.forward:SetSize(15, 15)
TutFrame.forward:SetPoint("BOTTOMRIGHT", -5, 5)
TutFrame.forward:SetScript("OnClick", function() TutFrame:ShowPage(TutFrame.page+1) end)

TutFrame.back = CreateFrame("Button", nil, TutFrame, "UIPanelButtonTemplate")
TutFrame.back:SetText("<")
TutFrame.back:SetSize(15, 15)
TutFrame.back:SetPoint("BOTTOMRIGHT", -25, 5)
TutFrame.back:SetScript("OnClick", function() TutFrame:ShowPage(TutFrame.page-1) end)

TutFrame.title = TutFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
TutFrame.title:SetJustifyH("LEFT")
TutFrame.title:SetJustifyV("TOP")
TutFrame.title:SetPoint("TOPLEFT", 10, -10)
TutFrame.title:SetPoint("TOPRIGHT", 10, -30)

TutFrame.body = TutFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
TutFrame.body:SetJustifyH("LEFT")
TutFrame.body:SetJustifyV("TOP")
TutFrame.body:SetPoint("TOPLEFT", 10, -30)
TutFrame.body:SetPoint("BOTTOMRIGHT", -10, 10)



function TutFrame:ShowPage(page)



	if IsGuildLeader() then
		if GMPages[page] then
			TutFrame.back:Show()
			TutFrame.forward:Show()
			if page == 1 then
				TutFrame.back:Hide()
			elseif page == #GMPages then
				TutFrame.forward:Hide()
			end
			TutFrame:SetSize(GMPages[page].x, GMPages[page].y)
			TutFrame:SetPoint("Center")
			
			TutFrame.title:SetText(GMPages[page].title)
			TutFrame.body:SetText(GMPages[page].body)
		end
	else

	end
TutFrame.page = page
TutFrame:Show()
end

function GMaster.AL.GMTutorial()
	function GMaster.PEW.GMTutorial()
		if not GMSettings.modules.GMTutorial.hasrun then
			--TutFrame:ShowPage(1)
			--print("cheeeees")
		end
	end
end





















