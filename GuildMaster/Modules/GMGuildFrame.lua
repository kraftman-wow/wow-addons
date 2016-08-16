--[[
1. Summary
2. Details
3. Structure
4. Changes
5. To Do

--========================== 1. Summary ===============================
	Adjusts the layout of the guild frame for more direct access to certain 
	features and information.
--========================== 2. Details ===============================
	Guild message of the day and events are moved to the first page, as well as
	the Add Member, View Log, and guild control buttons for guild masters.
	Guild rewards and guild perks are now both shown under the "Rewards" tab.
	Some extra info is shown under the "Info" tab.
	
	A "kill chat" button has been added to the guild control page. This will temporarily block all 
	guild chat, in case of arguements etc.
--========================== 3. Structure =============================
	
--========================== 4. Changes ===============================
2.0
	Lots of small fixes to do with the new patch

1.6
	Fixed issue with rewards frame cuasing an error on mouseover for level 1 guilds.

1.5
	Fixed a bug due to the recent interface changes,
	Brought back the info window. This will be used to show/edit the guild information,
	and also show some other stats about the guild.
- 1.47
	Added a button in guild control to temporarily suspend all guild chat.
	Rewards now show properly
	guild masters can delete all posts
	some posts can be properly deleted
--========================== 5. To do =================================
	 fix the reward showing when the forum shows.
	Move the guild control button to the roster frame.
	Bring the info frame back in and add some guild stats:
	average level
	number of 85's
	number of each class.
	
	Get the Invite Request working.
	
	BUG:
	rep bar doesnt show back up again after moving to forum
	
]]

--[[ 
Future plans:
More info on the info page, summary of stats collected by the addon.
--]]


GMaster.LoadOrder.GMGuildFrame = true

function GMaster.AL.GMGuildFrame()
	function GMaster.GFL.GMGuildFrame()
		
		--move the first tab allong a bit		
		GuildFrameTab1:SetPoint("TOPLEFT", GuildFrame, "BOTTOMLEFT", -5, 0) 
		
		local Settings = GMSettings.modules.GMGuildFrame
		if not Settings.PageWidths then
				Settings.PageWidths = {}
		end
		--=================== Adds a button to temporarily block guild chat. =======================
		--===================================================================================================
		
		local function KillGuildChat(self)
			if self.active then
				self.active = nil
				self:SetText("Kill Chat")
				SendChatMessage("[GMS:] Guild Chat Active.", "GUILD")
				for i = 2, GuildControlGetNumRanks() do
					GuildControlSetRank(i)
					GuildControlSetRankFlag(2, true)
					GuildControlSaveRank()
				end
			else
				self.active = true
				self:SetText("Activate Chat")
				SendChatMessage("[GMS:] Guild Chat Locked.", "GUILD")
				for i = 2, GuildControlGetNumRanks() do
					GuildControlSetRank(i)
					GuildControlSetRankFlag(2, false)
					GuildControlSaveRank()
				end
			end
		end
		
		local killguild = CreateFrame("Button", nil, GuildFrame, "UIPanelButtonTemplate")
		killguild:SetSize(100, 25)
		killguild:SetText("Kill Chat")
		
		killguild:SetScript("OnClick", KillGuildChat)
		
		killguild:SetParent(GuildControlUI)
		killguild:SetPoint("TOPLEFT", 20, -20)
		
		--================================================================================================
			
			--static settings
			
		if GuildFrameTab6 then -- since this runs after the forum, it should move the forum tab.
			GuildFrameTab6:SetPoint("LEFT", GuildFrameTab5, "RIGHT", -15, 0)
		end
		
		function GuildFrame_Toggle() --make sure we hide the tabs we dont want.
			if ( GuildFrame:IsShown() ) then
				HideUIPanel(GuildFrame);
			else
				ShowUIPanel(GuildFrame);
				GuildFrameTab3:Hide()
				GuildFrameTab4:SetPoint("LEFT", GuildFrameTab2, "RIGHT", -15, 0)
			end
		end
		
		function GuildFrame_UpdateFaction() --replace the blizz function to change the text formatting
			local factionBar = GuildFactionFrame;
			local gender = UnitSex("player");
			local name, description, standingID, barMin, barMax, barValue, _, _, _, _, _, _, _, repToCap, weeklyCap = GetGuildFactionInfo();
			local factionStandingtext = GetText("FACTION_STANDING_LABEL"..standingID, gender);
			--Normalize Values
			barMax = barMax - barMin;
			barValue = barValue - barMin;
			GuildFactionBarLabel:SetText(barValue.." / "..barMax.."  "..factionStandingtext);
			GuildFactionFrameStanding:SetText(factionStandingtext);
			GuildBar_SetProgress(GuildFactionBar, barValue, barMax, repToCap or 0);
		end
			
				
				
			
		--move the faction bar
		GuildFactionFrame:ClearAllPoints() 
		GuildFactionFrame:SetPoint("TOPLEFT", GuildFrame, "TOPLEFT", 58, -3)
		GuildFactionFrame:SetWidth(182)
		GuildFactionFrameStanding:Hide() --hide the faction text
		
		
		
		GuildFrameTitleText:Hide() -- hide the title text (people generally know the name of their own guild)
		GuildFactionFrameHeader:Hide()
		GuildXPFrameLevelText:Hide() --hide the level text(its already written on the tabard)
		GuildXPBar:SetPoint("TOPLEFT", GuildFrame, "TOPLEFT", 70, -30)
		GuildFrameTab3:Hide()
		
		GuildViewLogButton:SetParent(GuildFrame)
	--[[
		GuildViewLogButton:ClearAllPoints()
		GuildViewLogButton:SetSize(25, 80)
		GuildViewLogButton:SetPoint("LEFT", GuildAddMemberButton, "RIGHT")
	--]]
		GuildAddMemberButton:SetParent(GuildFrame)
		
		GuildControlButton:SetParent(GuildFrame)
		
		GuildFactionFrame:Show();
		GuildFactionFrame:ClearAllPoints() 
		GuildFactionFrame:SetPoint("TOPLEFT", GuildFrame, "TOPLEFT", 58, -3)
		GuildFactionFrame:SetWidth(182)
			
			--===============================================================================
			--===============================================================================
			
			GuildRoster()
			
			--===============================================================================

			
			
			local header1 = CreateFrame("Frame", nil, GuildFrame)
						header1:SetAllPoints(GuildFrameInset)
			header1.text = header1:CreateFontString(nil, "ARTWORK", "GameFontNormal")
			
			header1.text:SetPoint("TOPLEFT", 10, -3)
			header1.text:SetPoint("BOTTOMRIGHT", header1, "TOPRIGHT", 0, -20)
			header1.text:SetJustifyH("LEFT")
			
			header1.background = header1:CreateTexture()
			header1.background:SetTexture("Interface\\GuildFrame\\GuildFrame")
			header1.background:SetTexCoord(0.00097656, 0.31445313, 0.00195313, 0.59765625)
			header1.background:SetPoint("TOPLEFT", 3, -3)
			header1.background:SetDrawLayer("BACKGROUND")
			header1.background:SetPoint("BOTTOMRIGHT", header1, "BOTTOMRIGHT", -3, 3)
			
			header1.bar = header1:CreateTexture()
			header1.bar:SetTexture("Interface\\GuildFrame\\GuildFrame")
			header1.bar:SetTexCoord(0.00097656, 0.31445313, 0.93164063, 0.97460938)
			header1.bar:SetPoint("TOPLEFT", 3, -2)
			header1.bar:SetDrawLayer("ARTWORK")
			header1.bar:SetPoint("BOTTOMRIGHT", header1, "TOPRIGHT", -3, -22)
			
			local header2 = CreateFrame("Frame", nil, GuildFrame)
			header2.text = header2:CreateFontString(nil, "ARTWORK", "GameFontNormal")
			
			header2.text:SetPoint("TOPLEFT", 10, -5)
			header2.text:SetPoint("BOTTOMRIGHT", header2, "TOPRIGHT", 0, -20)
			header2.text:SetJustifyH("LEFT")
			
			header2.background = header2:CreateTexture()
			header2.background:SetTexture("Interface\\GuildFrame\\GuildFrame")
			header2.background:SetTexCoord(0.00097656, 0.31445313, 0.00195313, 0.59765625)
			header2.background:SetPoint("TOPLEFT", 3, -3)
			header2.background:SetDrawLayer("BACKGROUND")
			header2.background:SetPoint("BOTTOMRIGHT", header2, "BOTTOMRIGHT", -3, 3)
			
			header2.bar = header2:CreateTexture()
			header2.bar:SetTexture("Interface\\GuildFrame\\GuildFrame")
			header2.bar:SetTexCoord(0.00097656, 0.31445313, 0.93164063, 0.97460938)
			header2.bar:SetPoint("TOPLEFT", 3, -3)
			header2.bar:SetDrawLayer("ARTWORK")
			header2.bar:SetPoint("BOTTOMRIGHT", header2, "TOPRIGHT", -3, -25)
		
			CreateFrame("Frame", "GMForumInset", GuildFrame, "InsetFrameTemplate")
			header2:SetAllPoints(GMForumInset)
		
		
			local StatsPage = CreateFrame("Frame", nil, GuildFrame)
			StatsPage:SetAllPoints(GuildFrame)
		
			local MainPage = CreateFrame("Frame", nil, GuildFrame)
						MainPage:SetAllPoints(GuildFrame)
						
						GuildNewsContainer:SetParent(MainPage)
						
	MainPage:SetScript("OnShow", function(self) --when the page is shown
		
		GuildInfoEvents_Update()
				
		if CanEditGuildEvent() then
			GuildInfoEditEventButton:ClearAllPoints()
			GuildInfoEditEventButton:SetParent(MainPage)
			GuildInfoEditEventButton:SetPoint("TOPRIGHT", header2, "TOPRIGHT",  -10, -5)
			GuildInfoEditEventButton:SetHeight(15)
			GuildInfoEditEventButton:SetWidth(100)
			GuildInfoEditEventButton:Show()
		else
			GuildInfoEditEventButton:Hide()
		end
					
				--show:
				GuildViewLogButton:Show()
				
				GMForumInset:Show()
				header1:Show()
				header2:Show()
				GuildInfoMOTD:Show()
				GuildNewsFrame:Show()
				GuildFrameInset:Show()
								
				--hide
				GuildPerksToggleButton:Hide()
				GuildNextPerkButton:Hide()
				GuildLatestPerkButton:Hide()
				GuildAllPerksFrame:Hide()
				GuildInfoDetailsFrame:Hide()
				GuildMainFrame:Hide()
				GuildInfoEditDetailsButton:Hide()
				
				--modify:
				
				header2.text:SetText("Events")
				header1.text:SetText("Message of the Day:")
				
				GuildInfoEventsContainer:Show()
				
					local numEvents = CalendarGetNumGuildEvents();
					local scrollFrame = GuildInfoEventsContainer;
					local totalHeight = numEvents * scrollFrame.buttonHeight;
					
					
					if totalHeight > 100 then
						GuildInfoEventsContainer:SetHeight(110)
						GMForumInset:SetHeight(140)
						GuildNewsContainer:SetHeight(90)
					elseif totalHeight < 20 then
						GuildNewsContainer:SetHeight(180)
						GuildInfoEventsContainer:SetHeight(30)
						GMForumInset:SetHeight(50)
					else
						GuildNewsContainer:SetHeight(200 - totalHeight)
						GuildInfoEventsContainer:SetHeight( totalHeight)
						GMForumInset:SetHeight( totalHeight + 30)
					end
					
					GuildNewsContainer:ClearAllPoints()
					GuildNewsContainer:SetPoint("TOPLEFT", GuildFrameBottomInset, "TOPLEFT", 7,-22)
					GuildNewsContainer:SetPoint("BOTTOMRIGHT", GuildFrameBottomInset, "BOTTOMRIGHT", -25,5)
					
					GuildNewsFrame:ClearAllPoints()
					GuildNewsFrame:SetPoint("TOPLEFT", GuildFrameBottomInset, "TOPLEFT", 0, 0)
					GuildNewsFrame:SetPoint("RIGHT", GuildFrameBottomInset, "RIGHT", 0, 0)
					
					GuildNewsFrameHeader:ClearAllPoints()
					GuildNewsFrameHeader:SetPoint("TOPLEFT", GuildFrameBottomInset, "TOPLEFT", 3, -3)
					GuildNewsFrameHeader:SetPoint("RIGHT", GuildFrameBottomInset, "RIGHT", -5, 0)
					GuildNewsFrameHeader:SetHeight(22)
					
					GuildFrameInset:ClearAllPoints()
					GuildFrameInset:SetPoint("TOPLEFT", GuildFrame, "TOPLEFT", 4, -55)
					GuildFrameInset:SetPoint("RIGHT", GuildFrame, "RIGHT", -7, 0)
					GuildFrameInset:SetHeight(82)
					
					
					
					GuildInfoEditMOTDButton:SetParent(MainPage)
					GuildInfoEditMOTDButton:ClearAllPoints()
					GuildInfoEditMOTDButton:SetPoint("TOPRIGHT", header1, "TOPRIGHT", -10, -3)
					GuildInfoEditMOTDButton:SetHeight(15)
					GuildInfoEditMOTDButton:SetWidth(80)
					GuildInfoMOTD:SetParent(header1)
					GuildInfoMOTD:ClearAllPoints()
					GuildInfoMOTD:SetPoint("TOPLEFT", 10, -25)
					GuildInfoMOTD:SetPoint("BOTTOMRIGHT", header1, "BOTTOMRIGHT", -5, 0)
					
			
					GuildInfoEventsContainer:SetParent(GMForumInset)
					GuildInfoEventsContainer:SetPoint("TOPLEFT", 7, -25)
					GuildInfoEventsContainer:SetWidth(305)
					
					GuildFrameBottomInset:ClearAllPoints()
					GuildFrameBottomInset:SetPoint("TOPLEFT", GuildFrameInset, "BOTTOMLEFT", 0, 0)
					GuildFrameBottomInset:SetPoint("BOTTOMRIGHT", GMForumInset, "TOPRIGHT", 0, 0)
					
					header2:SetAllPoints(GMForumInset)
					
					GMForumInset:SetPoint("BOTTOMLEFT", GuildFrame, "BOTTOMLEFT", 5, 25)
					GMForumInset:SetPoint("RIGHT", GuildFrame, "RIGHT", -7, 0)
			
			end)
			MainPage:SetScript("OnHide", function(self)
				header1:Hide()
				header2:Hide()
				GuildInfoEditMOTDButton:Hide()
				GuildInfoEditEventButton:Hide()
				GMForumInset:Hide()
			end)
			--[[
			local InfoPage = CreateFrame("Frame", nil, GuildFrame)
						InfoPage:SetAllPoints(GuildFrame)
						
			InfoPage:SetScript("OnShow",
			function(self)
					
			
			
				--hide:
					MainPage:Hide()
					GuildInfoEventsContainer:Hide()
					GuildInfoEditMOTDButton:Hide()
					GuildAddMemberButton:Hide()
					GuildViewLogButton:Hide()
					GuildControlButton:Hide()
					GuildInfoMOTD:Hide()
					GuildInfoFrame:Hide()
					GuildInfoEditEventButton:Hide()
				--show:
					header1:Show()
					header2:Show()
					GuildInfoDetailsFrame:Show()
					GMForumInset:Show()
					
					if CanEditGuildInfo() then
						GuildInfoEditDetailsButton:Show()
						GuildInfoEditDetailsButton:SetParent(self)
					else
						GuildInfoEditDetailsButton:Hide()
					end
				--modify:
				
					header2.text:SetText("Guild Information")
					header1.text:SetText("Guild Statistics")
												
					GuildFrameInset:SetPoint("TOPLEFT", GuildFrame, "TOPLEFT", 4, -53)
					GuildFrameInset:SetPoint("BOTTOMRIGHT", GuildFrame, "BOTTOMRIGHT", -7, 5)
									
					
					
					GuildInfoEditDetailsButton:ClearAllPoints()
					GuildInfoEditDetailsButton:SetParent(self)
					GuildInfoEditDetailsButton:SetPoint("TOPRIGHT", header2, "TOPRIGHT",  -10, -5)
					GuildInfoEditDetailsButton:SetHeight(15)
					GuildInfoEditDetailsButton:SetWidth(100)
					
				
					GuildInfoDetailsFrame:SetParent(header2)
					GuildInfoDetailsFrame:SetPoint("TOPLEFT", 7, -25)
					GuildInfoDetailsFrame:SetWidth(305)
					GuildInfoDetailsFrame:SetHeight(90)
					GMForumInset:SetHeight(125)
					GMForumInset:SetPoint("BOTTOMLEFT", GuildFrame, "BOTTOMLEFT", 5, 5)
				
				
			end)
			
			InfoPage:SetScript("OnHide",
			function(self)
				header1:Hide()
				header2:Hide()
				GMForumInset:Hide()
			end)
			--]]
			
						
		
		RequestGuildRewards()
		QueryGuildXP();
		QueryGuildNews();
		OpenCalendar();		-- to get event data
		GuildFrame_UpdateTabard();
		GuildFrame_UpdateLevel();
		GuildFrame_UpdateXP();
		GuildFrame_UpdateFaction();
		GuildFrame_CheckPermissions();
		
		local function GuildInfo_CheckTabs()
			if ( IsGuildLeader() ) then
				GuildInfoFrameTab3:SetPoint("LEFT", GuildInfoFrameTab2, "RIGHT");
			else
				GuildInfoFrameTab3:SetPoint("LEFT", GuildInfoFrameTab4, "RIGHT");
			end
			
			if CanEditGuildEvent() then
				GuildInfoEditEventButton:Show()
			else
				GuildInfoEditEventButton:Hide()
			end
		end
			
		local function GuildInfo_CheckPage()
			local selected = PanelTemplates_GetSelectedTab(GuildInfoFrame);
			
			if selected == 1 then
				StatsPage:Hide()
				if CanGuildInvite() then
					GuildAddMemberButton:Show()
				end	
							
				if CanEditMOTD() then
					GuildInfoEditMOTDButton:Show()
				end
						
				if ( IsGuildLeader() ) then
					GuildControlButton:Show();
				end
			elseif selected == 2 or selected == 3 then
				StatsPage:Hide()
				GuildViewLogButton:Hide()
				GuildAddMemberButton:Hide()
				GuildControlButton:Hide()
			elseif selected == 4 then
				GuildInfoFrameApplicants:Hide()
				StatsPage:Show()

				
			end
		end
			
						
	local function GuildTabButtonClicked(self)
		
		local tabIndex = self:GetID();
		local width = Settings.PageWidths[tabIndex]
		if width then
			GuildFrame:SetWidth(width)
			SetUIPanelAttribute(GuildFrame, "width", width	)
		end		
		if ( tabIndex == 1 ) then -- Guild
			QueryGuildXP();
			QueryGuildNews();
			OpenCalendar();		-- to get event data
			GuildFrame_UpdateTabard();
			GuildFrame_UpdateLevel();
			GuildFrame_UpdateXP();
			GuildFrame_UpdateFaction();
			GuildFrame_CheckPermissions();
							
			if CanGuildInvite() then
				GuildAddMemberButton:Show()
			end	
						
			if CanEditMOTD() then
				GuildInfoEditMOTDButton:Show()
			end
					
			if ( IsGuildLeader() ) then
				GuildControlButton:Show();
			end
				
			--InfoPage:Hide()
			MainPage:Show() --does all the hard work, so you dont have to!
					
		elseif ( tabIndex == 2 ) then -- Roster 
				
		--Hide
			MainPage:Hide()
		--	InfoPage:Hide()
			GuildPerksToggleButton:Hide()
			GuildAllPerksFrame:Hide()
			GuildInfoEditMOTDButton:Hide()
			GMForumInset:Hide()
			header2:Hide()
			header2:Hide();
			GuildXPFrame:Hide();
			GuildAddMemberButton:Hide();
			GuildControlButton:Hide();
			GuildViewLogButton:Hide();
			GuildNextPerkButton:Hide()
			GuildLatestPerkButton:Hide()
			GuildAllPerksFrame:Hide()
		
		--Modify
			
			ButtonFrameTemplate_HideButtonBar(GuildFrame);
				
			GuildFactionFrame:Show();
				
			updateRosterCount = true;
			
		
		elseif ( tabIndex == 3 ) then -- News
			--this tab is hidden completely
			GuildLatestPerkButton:Hide()
			GuildLatestPerkButton:Hide()
			MainPage:Hide()
		--	InfoPage:Hide()
				
		elseif ( tabIndex == 4 ) then -- Rewards
			
			RequestGuildRewards()
			GuildRewards_Update()				
		
		--hide
			MainPage:Hide()
		--	InfoPage:Hide()
			
			GuildInfoEditMOTDButton:Hide()
			GMForumInset:Hide()
			GuildAllPerksFrame:Hide()
			GuildXPFrame:Hide();
			GuildAddMemberButton:Hide();
			GuildControlButton:Hide();
			GuildViewLogButton:Hide();
		
		--show
				GuildFrame_ShowPanel("GuildRewardsFrame");
				GuildRewardsContainer:Show()
				GuildFrameInset:Show()
				
				local level = GetGuildLevel()
				if level == 25 then
					GuildNextPerkButton:Hide()
					GuildLatestPerkButton:Show()
				elseif level == 1 then
					GuildLatestPerkButton:Hide()
					GuildNextPerkButton:Show()
				else
					GuildLatestPerkButton:Show()
					GuildNextPerkButton:Show()
				end
				GuildFrameBottomInset:Show()
				GuildFactionFrame:Show();
				
			GuildRewardsContainer:SetHeight(200)
			GuildRewardsContainer:SetWidth(315)
			GuildAllPerksFrame:SetParent(GuildFrameBottomInset)
			GuildAllPerksFrame:SetAllPoints(GuildFrameBottomInset)
			
			GuildPerksContainer:SetWidth(307)
			GuildPerksContainer:SetHeight(300)
			
			GuildRewardsFrameBg:SetHeight(200)
			GuildRewardsFrameBg:SetWidth(315)
			GuildRewardsFrameBg:SetParent(GuildRewardsFrame)
			GuildPerksToggleButton:Show()
			GuildPerksToggleButton.ac = nil
			
			GuildRewardsFrameBg:SetHeight(200)
			

			GuildFrameBottomInset:SetPoint("TOPLEFT", GuildFrame, "TOPLEFT", 5, -275)
			GuildPerksToggleButtonRightText:SetText(GUILD_VIEW_ALL_PERKS_LINK);
			GuildPerksToggleButtonArrow:SetTexCoord(0.45312500, 0.64062500, 0.01562500, 0.20312500);
				 
			
			GuildPerksToggleButton:SetParent(GuildFrameBottomInset)
			GuildPerksToggleButton:SetPoint("TOPLEFT", 5, -5)
			
			GuildPerksToggleButton:SetScript("OnClick", function(self) 
																					if self.ac then 
																						self.ac = nil 
																						GuildRewardsFrameBg:SetHeight(200)
																						GuildRewardsContainer:Show()
																						GuildAllPerksFrame:Hide()
																						GuildFrameInset:Show()
																						GuildRewardsFrameBg:SetParent(GuildRewardsFrame)
																						GuildFrameBottomInset:SetPoint("TOPLEFT", GuildFrame, "TOPLEFT", 5, -275)
																						GuildPerksToggleButtonRightText:SetText(GUILD_VIEW_ALL_PERKS_LINK);
																						GuildPerksToggleButtonArrow:SetTexCoord(0.45312500, 0.64062500, 0.01562500, 0.20312500);
																						local level = GetGuildLevel()
																						if level == 25 then
																							GuildNextPerkButton:Hide()
																							GuildLatestPerkButton:Show()
																						elseif level == 1 then
																							GuildLatestPerkButton:Hide()
																							GuildNextPerkButton:Show()
																						else
																							GuildLatestPerkButton:Show()
																							GuildNextPerkButton:Show()
																						end
																					else 
																							 GuildNextPerkButton:Hide()
																							GuildLatestPerkButton:Hide()
																						self.ac = true 
																						GuildRewardsFrameBg:SetHeight(320)
																						GuildRewardsContainer:Hide()
																						GuildAllPerksFrame:Show()
																						GuildRewardsFrameBg:SetParent(GuildAllPerksFrame)
																						GuildFrameInset:Hide()
																						GuildFrameBottomInset:SetPoint("TOPLEFT", GuildFrame, "TOPLEFT", 5, -65)
																						GuildPerksToggleButtonRightText:SetText(GUILD_VIEW_NEW_PERKS_LINK);
																						GuildPerksToggleButtonArrow:SetTexCoord(0.45312500, 0.64062500, 0.20312500, 0.01562500);	
																					end
																				end)
			
			GuildFrameBottomInset:ClearAllPoints()
			GuildFrameBottomInset:SetPoint("TOPLEFT", GuildFrame, "TOPLEFT", 5, -275)
			GuildFrameBottomInset:SetPoint("BOTTOMRIGHT", GuildFrame, "BOTTOMRIGHT", -7, 30)
			
			
			 
			 GuildLatestPerkButton:ClearAllPoints()
			 GuildLatestPerkButton:SetParent(GuildFrameBottomInset)
			 GuildLatestPerkButton:SetPoint("BOTTOMLEFT", 15, 20)
			 
			 
			 GuildNextPerkButton:SetParent(GuildFrameBottomInset)
			 
				
				ButtonFrameTemplate_HideButtonBar(GuildFrame);
				GuildFrameInset:ClearAllPoints()
				GuildFrameInset:SetPoint("TOPLEFT", 4, -65);
				GuildFrameInset:SetPoint("BOTTOMRIGHT", -7, 150);

				updateRosterCount = true;
				
		elseif ( tabIndex == 5 ) then -- Info
				--[[ want: 
						List of stats
						Guild info
						rank info.
						player info.
					
					--]]
					
				
					GuildViewLogButton:Show()
				
					
			if not GuildInfoFrameTab4 then
				local StatsTab = CreateFrame("Button", "GuildInfoFrameTab4", GuildInfoFrame, "TabButtonTemplate")
				StatsTab:SetText("Stats")
				StatsTab:SetPoint("LEFT", GuildInfoFrameTab1, "RIGHT", 0, 0)
				StatsTab:SetID(4)
				StatsTab:SetScript("OnClick", function(self) PanelTemplates_Tab_OnClick(self, GuildInfoFrame) GuildInfoFrame_Update(); end)
				_G[StatsTab:GetName().."HighlightTexture"]:SetWidth(StatsTab:GetTextWidth() + 31);
				
				PanelTemplates_SetNumTabs(GuildInfoFrame, 4) --add the extra tab

					--narrow the other tabs down a bit to fit the new tab
				PanelTemplates_TabResize(GuildInfoFrameTab1, -8)
				PanelTemplates_TabResize(GuildInfoFrameTab2, -8)
				PanelTemplates_TabResize(GuildInfoFrameTab3, -8)
				PanelTemplates_TabResize(GuildInfoFrameTab4, -8)
				
				GuildInfoFrameTab2:SetPoint("LEFT", GuildInfoFrameTab4, "RIGHT")
				
				hooksecurefunc("GuildInfoFrame_UpdatePermissions", GuildInfo_CheckTabs)
				hooksecurefunc("GuildInfoFrame_Update", GuildInfo_CheckPage)
			end
					
			if CanGuildInvite() then
				GuildAddMemberButton:Show()
			end	
				
				
			if ( IsGuildLeader() ) then
				GuildControlButton:Show();
			end
			
			MainPage:Hide()
		
		elseif self:GetID() == 6 then
				GuildFrameInset:Show()
				
				MainPage:Hide()
				--InfoPage:Hide()
			
				
				GuildAllPerksFrame:Hide()
				GuildNextPerkButton:Hide()
				GuildLatestPerkButton:Hide()
				GuildInfoEditMOTDButton:Hide()
				GMForumInset:Hide()
				
				GuildXPFrame:Hide();
				GuildFactionFrame:Hide();
				GuildAddMemberButton:Hide();
				GuildControlButton:Hide();
				GuildViewLogButton:Hide();
					  
					
			
		end
				GuildFrameMembersCountLabel:Hide();
				GuildFactionFrame:Show();
	end

			hooksecurefunc("GuildFrame_TabClicked", GuildTabButtonClicked)
			MainPage:Hide()
			GuildTabButtonClicked(GuildFrameTab1)
			GuildTabButtonClicked(GuildFrameTab2)
			
	--==============================================================================================
	
	local Sizer = CreateFrame("Button", nil, GuildFrame)
			Sizer:SetSize(15, 100)
			Sizer:SetPoint("CENTER", GuildFrame, "RIGHT", 7, 0)
			Sizer.Tex = Sizer:CreateTexture()
			Sizer.Tex:SetAllPoints(Sizer)
			Sizer.Tex:SetTexture("Interface\\RAIDFRAME\\RaidPanel-Toggle")
			Sizer.Tex:SetTexCoord(1, 0.5, 1, 0)
			Sizer:SetScript("OnMouseDown", function(self) end)
			Sizer:SetScript("OnMouseUp", function(self) end)

			
			
			Sizer:SetMovable(true)
			Sizer:SetScript("OnMouseDown", function(self) 
																			_, self.center = self:GetCenter() 
																			--self.center = self.center* UIParent:GetEffectiveScale() 
																			self:ClearAllPoints()
																			GuildFrame:SetPoint("RIGHT", self, "CENTER", -7, 0)
																			self:SetScript("OnUpdate", function(self) 
																																		local r, l = GuildFrame:GetRight(),  GuildFrame:GetLeft() 
																																		local x, y = GetCursorPosition() 
																																			x = x/UIParent:GetEffectiveScale() 
																																		if (r -l) < 345 then
																																			if x > r then
																																				self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, self.center)
																																			end
																																		elseif (r - l) > 800 then
																																			if x < r  then
																																				self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, self.center)
																																			end
																																		else
																																			self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, self.center)
																																		end
																																	end) 
																			end)
   
			Sizer:SetScript("OnMouseUp", function(self)
																			
																		self:SetScript("OnUpdate", nil)
																		local r, l = GuildFrame:GetRight(),  GuildFrame:GetLeft() 
																		local t = GuildFrame:GetTop()
																		GuildFrame:ClearAllPoints()
																		GuildFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l, t)
																		GuildFrame:SetWidth(r-l)
																		Sizer:SetPoint("CENTER", GuildFrame, "RIGHT", 7, 0)
																		SetUIPanelAttribute(GuildFrame, "width", r-l)
																		Settings.PageWidths[PanelTemplates_GetSelectedTab(GuildFrame)] = r-l
																end)
	

	
end
end	




--======================= Settings stuff  =============================
--======================================================================

function GMaster.ModuleSettings.GMGuildFrame()
--create settings page
	local parent = CreateFrame("Frame")
		parent.titleText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		parent.titleText:SetPoint("TOPLEFT", parent, "TOPLEFT", 30, -40)
		parent.titleText:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -30, 40)
		parent.titleText:SetJustifyH("LEFT")
		parent.titleText:SetJustifyV("TOP")
		parent.titleText:SetText("GM-GuildFrame makes the layout of the guild frame a little more sensible.\n "
															.."The Message of the day, news, and events are now on the main page, the reward page shows both"
															.." rep rewards and guild perks, and the guild info shows some extra guild stats.")
	return parent

end

function GMaster.ModuleLoad.GMGuildFrame()
	--enable the module
		GMaster.AL.GMGuildFrame()
		
	if GMaster.GUILD_FRAME_LOADED then
		GMaster.GFL.GMGuildFrame()
	else
		LoadAddOn("Blizzard_GuildUI")
	end
	
	
	
end

function GMaster.ModuleRemove.GMGuildFrame()
	--this is a pretty big job, best to just reload the UI
	return false
end


