--[[
1. Summary
2. Details
3. Structure
4. Changes
5. To Do

--========================== 1. Summary ===============================
	Adds an in-game forum allowing players to communicate with one another without
	needing to be online at the same time.
--========================== 2. Details ===============================
	The forum is a reddit-style message board in that each reply is shown
	underneath the post it is a reply to.
	New topics on the front page must have titles, however replies can have replies without titles,
	whichever is inputted is shown as the title.
	Because of the style of the forum, deleting posts would mean that
	children of those posts would have to be deleted too. As a result, 
	deleting posts changes their content to "deleted" and greys them out, 
	leaving any undeleted child posts intact.
	There is currently no method of permanently deleting posts, 
	This would need to be stored server side somehow otherwise it will cause major headaches.
	

--========================== 3. Structure =============================
	
--========================== 4. Changes ===============================
1.52
fixed bug that hid the  rep bar.

1.4
	Topics can now be completely deleted.
	Guild Masters can delete all posts.
--========================== 5. To do =================================
	Priority: High
		Make replies properly delete.
		sticky posts.
		age limit of posts.
		
		Add Colors!
		convert gmfrequest to whisper
]]


--[[
Possible future plans:
	Polls
Sticky posts, etc:

need to properly check the way that the posts are sorted, in order to properly 
make the stickies higher up the list.

|cff66119d Test|r

--]]

GMaster.LoadOrder.GMForum = true

local module = {} 

function GMaster.AL.GMForum()
	if GMSettings.GMForum.Timing then
		tinsert(GMaster.Timers, {runonce = true, interval = 60, elapsed = 0, func = function()  GMSettings.GMForum.Timing = false end})
	end
			
	local ReplyTo -- the timestamp of the post
	local PlayerName = GMaster.PlayerName

	local FFrame = CreateFrame("Frame", "GuildForumFrame", UIParent)
			FFrame:Hide()
	local EditBoxInset = CreateFrame("Frame", nil, FFrame, "InsetFrameTemplate")
		EditBoxInset:SetPoint("TOP", FFrame, "BOTTOM")
		EditBoxInset:SetPoint("LEFT", FFrame, "LEFT")
		EditBoxInset:SetPoint("RIGHT", FFrame, "RIGHT", 18, 0)
		EditBoxInset:SetPoint("BOTTOM", FFrame, "BOTTOM", 0, -75)
		EditBoxInset:SetFrameStrata("HIGH")
			
	local TitleBoxInset = CreateFrame("Frame", nil, FFrame, "InsetFrameTemplate")
		TitleBoxInset:SetPoint("TOPLEFT", EditBoxInset, "BOTTOMLEFT", 60, 0)
		TitleBoxInset:SetPoint("BOTTOMRIGHT", EditBoxInset, "BOTTOMRIGHT", -110, -20)
		TitleBoxInset:SetFrameStrata("HIGH")
		TitleBoxInset:Hide()
			
		TitleBoxInset.TitleText = TitleBoxInset:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		TitleBoxInset.TitleText:SetWidth(60)
		TitleBoxInset.TitleText:SetHeight(20)
		TitleBoxInset.TitleText:SetPoint("TOPRIGHT", TitleBoxInset, "TOPLEFT")
		TitleBoxInset.TitleText:SetText("Title:")
			
	local PostButton = CreateFrame("Button", nil, EditBoxInset, "UIPanelButtonTemplate")
		PostButton:SetText("Post")
		PostButton:SetWidth(100)
		PostButton:SetHeight(20)
		PostButton:SetPoint("BOTTOMRIGHT", EditBoxInset, "BOTTOMRIGHT", -5, -21)
			--]]
			
	local TitleContainer = CreateFrame("ScrollFrame", "ForumTitleFrame", FFrame, "HybridScrollFrameTemplate")
		TitleContainer:SetPoint("TOPLEFT", FFrame, "TOPLEFT", 0, -5)
		TitleContainer:SetHeight(300)
		--TitleContainer:SetPoint("BOTTOMRIGHT", FFrame, "BOTTOMRIGHT", -2, 5)

	local TitleContainerScroll = CreateFrame("Slider", "ForumTitleFrameScrollBar", TitleContainer, "HybridScrollBarTemplate")
		TitleContainerScroll:SetPoint("TOPLEFT", TitleContainer, "TOPRIGHT", 0, -12)
		TitleContainerScroll:SetPoint("BOTTOMLEFT", TitleContainer, "BOTTOMRIGHT", 0, 12)
		--TitleContainer:SetScrollChild(TitleContainerScroll)
			
	EditBoxInset:Hide()
	ForumEditBoxScroll = CreateFrame("ScrollFrame", "ForumEditBoxScroll", EditBoxInset, "UIPanelScrollFrameTemplate")

	ForumEditBoxScroll:SetPoint("TOPLEFT", EditBoxInset, "TOPLEFT", 10, -5)
	ForumEditBoxScroll:SetPoint("BOTTOMRIGHT", EditBoxInset, "BOTTOMRIGHT", -27, 3)


	ForumEditBox = CreateFrame("EditBox", "ForumEditBox", ForumEditBoxScroll)
	ForumEditBox:SetScript("OnEscapePressed", function(self) ToggleGuildFrame() end)
	ForumEditBox:SetWidth(450)
	ForumEditBox:SetHeight(85)
	ForumEditBox:SetMultiLine(true)
	ForumEditBox:SetFontObject(GameFontHighlight)
	ForumEditBoxScroll:SetScrollChild(ForumEditBox)
	
	TitleEditBox = CreateFrame("EditBox", "ForumTitleEditBox", ForumEditBoxScroll)
	TitleEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
	TitleEditBox:SetPoint("TOPLEFT", TitleBoxInset, "TOPLEFT", 3, 0)
	TitleEditBox:SetPoint("BOTTOMRIGHT", TitleBoxInset, "BOTTOMRIGHT", -3, 0)
	TitleEditBox:SetMultiLine(false)
	TitleEditBox:SetFontObject(GameFontHighlight)
	
	local NewTopic = CreateFrame("Button", nil, FFrame, "UIPanelButtonTemplate")
		NewTopic:SetText("New Topic")
		NewTopic:SetWidth(100)
		NewTopic:SetHeight(25)
		NewTopic:SetPoint("BOTTOMRIGHT", FFrame, "TOPRIGHT", -10, 5)
			
			
	local MsgFrame = CreateFrame("Frame", nil, FFrame)
		MsgFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
										edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
										tile = true, tileSize = 16, edgeSize = 16, 
										insets = { left = 4, right = 4, top = 4, bottom = 4 }})
		MsgFrame:SetBackdropColor(0,0,0,1);
		
		MsgFrame:SetPoint("TOPLEFT", FFrame, "TOPRIGHT", 25, -5)
		MsgFrame:SetPoint("BOTTOMLEFT", FFrame, "BOTTOMRIGHT", 25, 5)
		MsgFrame:SetWidth(300)
		MsgFrame:Hide()
		
		MsgFrame.Text = MsgFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		MsgFrame.Text:SetPoint("TOPLEFT", MsgFrame, "TOPLEFT", 10, -10)
		MsgFrame.Text:SetPoint("BOTTOMRIGHT", MsgFrame, "BOTTOMRIGHT", -10, 30)
		MsgFrame.Text:SetJustifyH("LEFT")
		MsgFrame.Text:SetJustifyV("TOP")
	
	local ReplyButton = CreateFrame("Button", nil, MsgFrame, "UIPanelButtonTemplate")
		ReplyButton:SetText("Reply")
		ReplyButton:SetWidth(100)
		ReplyButton:SetHeight(20)
		ReplyButton:SetPoint("BOTTOMRIGHT", MsgFrame, "BOTTOMRIGHT", -5, -21)

												
	local EditButton = CreateFrame("Button", nil, MsgFrame, "UIPanelButtonTemplate")
		EditButton:SetText("Edit")
		EditButton:SetWidth(100)
		EditButton:SetHeight(20)
		EditButton:SetPoint("RIGHT", ReplyButton, "LEFT", -5, 0)
		EditButton:Hide()
			
	local parent
	
	local TopicPage = CreateFrame("Frame", nil, FFrame)
		TopicPage:SetAllPoints(FFrame)
		TopicPage.buttons = {}
	
	local Scroller = CreateFrame("ScrollFrame", "GMForumScrollFrame", FFrame, "FauxScrollFrameTemplate")
		Scroller:SetWidth(30)
		Scroller:SetHeight(300)
		Scroller:SetPoint("TOPRIGHT", FFrame, "TOPRIGHT", -5, 0)
		Scroller:Show()
	
	TopicPage:SetScript("OnShow", Forum_Update)
	

		local button
			
			local TopicTable = {}
			--add hem if its open
			
			local function AddChild(dated, level)
				local self = GMForum[dated]
				self.level = level
				if self.children and self.open and not (self.msg == "DELETE") then
					TopicTable[#TopicTable +1 ] = self
					for child, v in pairs(self.children) do
						AddChild(child, (level+1))
					end
				elseif not (self.msg == "DELETE") then
					self.dated = dated
					TopicTable[#TopicTable +1 ] = self
				end
			end
			
			local function Forum_Update() --called whenever a message is recieved, its opened, scrollbar is moved
			
				TopicTable = {}

					--find all children
					table.sort(GMForum, function(a, b) return a > b end)
					
					for dated, info in pairs(GMForum) do
						if info.replyto > 1 then --its a reply
							if not GMForum[info.replyto] then
									return
									--this means it doesnt have the parent for some reason
									--need to do something about it!
							end
						
							if not GMForum[info.replyto].children then
								GMForum[info.replyto].children = {}
							end
							if not GMForum[info.replyto].children[dated] then
								GMForum[info.replyto].children[dated] = true
							end
							
							--info.level = GMForum[info.replyto].level + 1
						else
							--info.level = 1
						end
					end
					
					for dated, info in pairs(GMForum) do
						if info.replyto < 1 and not (info.msg == "DELETED" )then
							info.level = 1
							AddChild(dated, 1)
						end
					end
					local offset = 0
					
				FauxScrollFrame_Update(Scroller, #TopicTable, 16, 16)
					
				offset = FauxScrollFrame_GetOffset(Scroller)
				
				
				for index = 1, #TopicPage.buttons do
				local i = index + offset
						button = TopicPage.buttons[index]
				if not button then 
					return
				end
					if TopicTable[i] then
					local info = TopicTable[i]
							
							
							
							if TopicTable[i].title == "" then
								button.string1:SetText(TopicTable[i].msg)	
							else
								button.string1:SetText(TopicTable[i].title)	
							end
											
							
						if info.level == 1 then
							button.icon:SetPoint("LEFT", button, "LEFT", 10, 0)
						
							button.string1:SetWidth(200)
							button.string1:SetTextColor(1,1,0.3)
							--button.string1:SetWidth(300)
							button.left:SetTexture()
							button.left:Show()
							button.right:Show()
							button.middle:Show()
							button.left:SetTexture("Interface\\Buttons\\CollapsibleHeader")
							--button.texture:SetTexture("Interface\\TokenFrame\\UI-TokenFrame-CategoryButton")
							
							button.texture:Show()
						else
							button.left:Hide()
							button.right:Hide()
							button.middle:Hide()
							button.string1:SetTextColor(1,1,1)
							button.string1:SetWidth(150)
							button.icon:SetPoint("LEFT", button, "LEFT", 15 + (info.level * 10), 0)
							--button.string1:SetWidth(300 -(info.level * 10))
							button.texture:SetTexture("Interface\\GuildFrame\\GuildFrame")
							--button.texture:Hide()
						end
						
							if TopicTable[i].msg == "DELETED" then
								button.string1:SetText("[Deleted]")
								button.string1:SetTextColor(0.6, 0.6, 0.6)
							end	
							
							if info.children then
								button.icon:Show()
							else
								button.icon:Hide()
							end
							
								
							button.string2:SetText(TopicTable[i].name)
							if TopicTable[i].name == GMaster.PlayerName or IsGuildLeader() then
								button.delete:Show()
							else
								button.delete:Hide()
							end
							
							button.tooltip = TopicTable[i].msg
							--change to suit new purpose
							local dated = date("%H:%M %d-%m", TopicTable[i].dated)
							
							button.string3:SetText(dated)
							button.id = TopicTable[i].dated
							button.replyto = TopicTable[i].replyto
							
							if GMRoster[TopicTable[i].name] then --if the person is still in the guild
								local class = GMRoster[TopicTable[i].name].class
								local classColor = RAID_CLASS_COLORS[class];
								if class then
									button.string2:SetTextColor(classColor.r, classColor.g, classColor.b);
								end
							else 
								--tremove(GMForum, i)
								--Forum_Update()
							end
							
						if TopicTable[i].msg == "DELETED" and not info.children then
							--button:Hide()
							--offset = offset -1
						else
							button:Show()
						end
					else
							button.string1:SetText("")		
							button.string2:SetText("")
							button.string3:SetText("")
							button.texture:Hide()
							button:Hide()
					end
				end
			end

			Scroller:SetScript("OnVerticalScroll", function(self, value) FauxScrollFrame_OnVerticalScroll(self, value, 16, Forum_Update)  end)
			
			
			
				PostButton:SetScript("OnClick", function() 
														if GMSettings.GMForum.Timing and (ReplyTo == 0) then
															ForumTitleEditBox:SetText("You cannot make a new topic for 10 minutes!")
														else
															if ForumTitleEditBox:GetText() == "" and (ReplyTo ==0) then
																ForumTitleEditBox:SetText("Please Set a Title!")
															else
																if ForumEditBox:GetText() == "" then
																	ForumEditBox:SetText("Please write a message here")
																else
																	local dated
																	if EditButton.clicked then
																		dated = EditButton.id
																		ReplyTo = GMForum[dated].replyto
																		
																	else
																		dated = time()
																	end
																	
																	local msg = ""
																	msg = dated.."-"..ReplyTo.."|title"..ForumTitleEditBox:GetText()
																	GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMFnew", msg}
																	
																	local str = ForumEditBox:GetText()
																	while str:sub(1, 200) ~= "" do
																		msg = dated.."-"..ReplyTo.."|msg"..str:sub(1,200)
																	   str = str:sub(201)
																	   GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMFnew", msg}
																	end
																	
																	GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMFnew", (dated.."-"..ReplyTo.."|&&&&")}
																	
																	Forum_Update()
																	if ReplyTo == 0 then
																		tinsert(GMaster.Timers, {runonce = true, interval = 600, elapsed = 0, func = function()  GMSettings.GMForum.Timing = false end})
																		GMSettings.GMForum.Timing = true
																	end
																	
																	ForumEditBox:SetText("") --clear everything
																	ForumTitleEditBox:SetText("")
																	GuildFrameInset:SetPoint("BOTTOMRIGHT", -25, 5);
																	EditBoxInset:Hide() 
																	TitleBoxInset:Hide()
																	MsgFrame:Hide()
																end
															end
														end
											end)
											
	function GMaster.GFL.GMForum()
		
			
			if ( GetGuildLevelEnabled() ) then
				GuildFrameTab1:SetPoint("TOPLEFT", GuildFrame, "BOTTOMLEFT", -10, 0)
			end
			FFrame:SetParent(GuildFrame)
			FFrame:SetPoint("TOPLEFT", GuildFrameInset, "TOPLEFT")
			FFrame:SetPoint("BOTTOMRIGHT", GuildFrameInset, "BOTTOMRIGHT")
			GuildFrame_RegisterPanel(FFrame) --adds the panel into teh list of panels
			
			NewTopic:SetScript("OnMouseUp", function(self) if self.active then
																GuildFrameInset:SetPoint("BOTTOMRIGHT", -25, 5);
																EditBoxInset:Hide() 
																TitleBoxInset:Hide()
																self.active = nil 
															else
																 GuildFrameInset:SetPoint("BOTTOMRIGHT", -25, 100);
																EditBoxInset:Show()
																TitleBoxInset:Show()
																ReplyTo = 0
																self.active = true
															end
														end)
			
			local ChatButton = CreateFrame("BUTTON", "GuildFrameTab6", GuildFrame, "CharacterFrameTabButtonTemplate")
			module.ChatButton = ChatButton
			ChatButton:SetText("Forum")
			ChatButton:SetPoint("LEFT", GuildFrameTab5, "RIGHT", -15, 0)
			ChatButton:SetID(6)
			
			PanelTemplates_SetNumTabs(GuildFrame, 6); --chaneg the number of tabs the guild pane has

			HybridScrollFrame_CreateButtons(TitleContainer, "GuildRosterButtonTemplate", 8, 0, "TOPLEFT", "TOPLEFT", 0, 0, "TOP", "BOTTOM");
			
			for i = 1, 16 do
			
				local button = CreateFrame("Button", "ForumFrameButton"..i, TopicPage, "GuildRosterButtonTemplate")
				
				local border = _G[button:GetName().."BarTexture"]
				border:Hide()
				
				button.texture = _G[button:GetName().."Stripe"]
				
				local Icon = _G[button:GetName().."Icon"]
				Icon:SetTexture("Interface\\Buttons\\UI-PlusMinus-Buttons")
				Icon:ClearAllPoints()
				Icon:SetHeight(10)
				Icon:SetWidth(10)
				Icon:SetPoint("LEFT", button, "LEFT")
				Icon:SetDrawLayer("OVERLAY")
				--Icon:Hide()
				button.icon = Icon
				
				button.left = button:CreateTexture()
				button.left:SetTexture("Interface\\Buttons\\CollapsibleHeader")
				button.left:SetTexCoord(0.17578125, 0.47265625, 0.29687500, 0.54687500)
				button.left:SetWidth(76)
				button.left:SetHeight(button:GetHeight())
				button.left:SetPoint("LEFT", button, "LEFT", 5, 0)
				
				button.right = button:CreateTexture()
				button.right:SetTexture("Interface\\Buttons\\CollapsibleHeader")
				button.right:SetTexCoord(0.17578125, 0.47265625, 0.01562500, 0.26562500)
				button.right:SetWidth(76)
				button.right:SetHeight(button:GetHeight())
				button.right:SetPoint("RIGHT", button, "RIGHT", -5, 0)
				
				button.middle = button:CreateTexture()
				button.middle:SetTexture("Interface\\Buttons\\CollapsibleHeader")
				button.middle:SetTexCoord( 0.48046875, 0.98046875, 0.01562500, 0.26562500)
				button.middle:SetWidth(76)
				button.middle:SetHeight(button:GetHeight())
				button.middle:SetPoint("LEFT", button.left, "RIGHT", -20, 0)
				button.middle:SetPoint("RIGHT", button.right, "LEFT", 20, 0)
				
				button.string1:SetPoint("LEFT", button.icon, "RIGHT", 5, 0)
				button.string1:SetWidth(150)
				button.string1:SetJustifyH("LEFT")
				button.string1:Show()
				
				button.string2:SetPoint("LEFT", button.string1, "RIGHT", 5, 0)
				button.string2:SetWidth(70)
				button.string2:SetJustifyH("LEFT")
				button.string2:Show()
				
				button.string3:SetPoint("LEFT", button.string2, "RIGHT")
				button.string3:SetWidth(100)
				button.string3:SetJustifyH("LEFT")
				button.string3:Show()
				button.icon:SetTexCoord(0, 0.4375, 0, 0.4375);
				
				button:SetHeight(20)
				button:SetPoint("LEFT", TopicPage, "LEFT")
				button:SetPoint("RIGHT", TopicPage, "RIGHT")
				
				button.delete = CreateFrame("Button", nil, button)
				button.delete:SetHeight(15)
				button.delete:SetWidth(15)
				button.delete:SetPoint("RIGHT", button, "RIGHT", -7, 0)
				button.delete:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
				button.delete:SetPushedTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Down")
				button.delete:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Highlight")
				button.delete:SetScript("OnMouseUp", function(self)
																					local button = self:GetParent()
																					local msg = button.id.."-"..button.replyto.."|msgDELETED|&&&&"
																					GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMFnew", msg}
																		end)
																		
				if parent then
					parent = _G["ForumFrameButton"..(i-1)]
					button:SetPoint("TOP", parent, "BOTTOM", 0, -2)
				else
					button:SetPoint("TOP", FFrame, "TOP")
					parent = button
				end
					
				button:SetScript("OnClick", function(self) 
												if GMForum[self.id].open then 
													GMForum[self.id].open = false 
													MsgFrame:Hide()
													EditButton:Hide()
													button.icon:SetTexCoord(0, 0.4375, 0, 0.4375);
					
												else 
													GMForum[self.id].open = true 
													MsgFrame.Text:SetText(self.tooltip)
													MsgFrame:Show()
													ReplyTo = self.id
													button.icon:SetTexCoord(0.5625, 1, 0, 0.4375);
													if GMForum[self.id].name == GMaster.PlayerName then
														ReplyButton.id = self.id
														EditButton.id = self.id
														EditButton.clicked = false
														EditButton:Show()
													else
														EditButton:Hide()
													end
												end 
												Forum_Update() 
											end)
											
						button:SetScript("OnShow", function(self) 
												Forum_Update()
												if GMForum[self.id] then
													if GMForum[self.id].open then 
														button.icon:SetTexCoord(0.5625, 1, 0, 0.4375);
													else 
														button.icon:SetTexCoord(0, 0.4375, 0, 0.4375);	
													end 
												end
											end)
											
				button:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
															GameTooltip:SetText(self.tooltip)
											end)
				button:SetScript("OnLeave", function() GameTooltip:Hide() end)
				
				
				button:Show()
				tinsert(TopicPage.buttons, button)
				
			end
			EditButton:SetScript("OnClick", function(self) 	
															if self.id then
																if GMForum[self.id] then
																self.clicked = true
																	ForumTitleEditBox:SetText(GMForum[self.id].title)
																	ForumEditBox:SetText(GMForum[self.id].msg)
																		 GuildFrameInset:SetPoint("BOTTOMRIGHT", -25, 100);
																EditBoxInset:Show()
																TitleBoxInset:Show()
																end
															end
														end)
														
			ChatButton:SetScript("OnClick", function(self) PanelTemplates_Tab_OnClick(self, GuildFrame)
															GuildFrame_TabClicked(self) end)
			ChatButton:Show()
			
					ReplyButton:SetScript("OnMouseUp", function(self) if self.active then
																GuildFrameInset:SetPoint("BOTTOMRIGHT", -25, 5);
																EditBoxInset:Hide() 
																TitleBoxInset:Hide()
																self.active = false
															else
																 GuildFrameInset:SetPoint("BOTTOMRIGHT", -25, 100);
																EditBoxInset:Show()
																TitleBoxInset:Show()
																
															end
														end)
			local function GuildTabButtonClicked(self)
				local tabIndex = self:GetID();
				if self:GetID() == 6 then
					
				
					GuildViewLogButton:Hide()
					GuildControlButton:Hide()
					GuildAddMemberButton:Hide()
					--GuildFactionBar:Hide()
					GuildFrameInset:Show()
					
					ButtonFrameTemplate_ShowButtonBar(GuildFrame);
					  GuildFrame_ShowPanel("GuildForumFrame");
					  GuildFrameInset:ClearAllPoints()
					  GuildFrameInset:SetPoint("TOPLEFT", 4, -60);
					  if NewTopic.active then
						 GuildFrameInset:SetPoint("BOTTOMRIGHT", -25, 100);
					  else
						GuildFrameInset:SetPoint("BOTTOMRIGHT", -25, 5);
					  end
				end
			end
			hooksecurefunc("GuildFrame_TabClicked", GuildTabButtonClicked)
		end
	

	--=============================== Sycing Stuff ==============================================
	--=======================================================================================

	local temptable = {}

	function GMaster.CMA.ForumMsg(prefix, msg, channel, player)
		if prefix == "GMFnew" then --its a new message from someone online
		
		local dated, replyto = msg:match("^(%d+)-(%d+)|")
		
			dated = tonumber(dated)
			replyto = tonumber(replyto)
			if not temptable[dated] then
				temptable[dated] = {title = "", message = ""}
			end
			
			if msg:find("|title") then
				temptable[dated].title = temptable[dated].title..msg:match("|title(.*)")
			end
			if msg:find("|msg") then
				temptable[dated].message = temptable[dated].message..msg:match("|msg(.+)")
			end
			if msg:find("&&&&$") then
				if msg:find("msgDELETED") then
					GMForum[dated] = nil
					GMForum[dated] = {replyto = replyto, title = "", msg = "DELETED", name = player}
				else
					if GMForum[dated] then
						GMForum[dated].msg = temptable[dated].message
						GMForum[dated].title = temptable[dated].title
						GMForum[dated].edited = time()
					else
						GMForum[dated] = {replyto = replyto, title = temptable[dated].title, msg = temptable[dated].message, name = player}
					end
				end
				Forum_Update()
				temptable[dated] = nil
			end
		elseif prefix == "GMFBroadcast" then
			if not (player == PlayerName) then
				local dated, replyto = msg:match("^(%d+)-(%d+)|")
				local deleted = msg:match("|DELETED")
				local edited = msg:match("|e(%d+)")
				edited = tonumber(edited)
				dated = tonumber(dated)
				replyto = tonumber(replyto)
				if deleted then
					GMForum[dated] = {replyto = replyto, title = "", msg = "DELETED", name = ""}
				else
					if GMForum[dated] then
						if GMForum[dated].edited and edited then
							if tonumber(GMForum[dated].edited) > edited then
								GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMFBroadcast", dated.."-"..GMForum[dated].replyto.."|e"..GMForum[dated].edited}
							elseif tonumber(GMForum[dated].edited) < edited then
								GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMFRequest"..player, dated}
							end
						else
							GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMFRequest"..player, dated}
						end
					else
						GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMFRequest"..player, dated}
					end
				end
			end
		elseif prefix:find("^GMFSend"..PlayerName) then

			local dated, replyto = msg:match("^(%d+)-(%d+)|")
					dated = tonumber(dated)
					replyto = tonumber(replyto)
					if not temptable[dated] then
						temptable[dated] = {title = "", message = ""}
					end
					
					if msg:find("|title") then
						temptable[dated].title = temptable[dated].title..msg:match("|title(.-)|")
					end
					
					if msg:find("|name") then
						temptable[dated].name = msg:match("|name(.-)|")
					end
					if msg:find("|msg") then
						temptable[dated].message = temptable[dated].message..msg:match("|msg(.+)")
					end
					if msg:find("|e%d+") then
						temptable[dated].edited = msg:match("|e(%d+)")
					end
					if msg:find("&&&&$") then
						if GMForum[dated] then
							GMForum[dated].message = temptable[dated].msg
							GMForum[dated].title = temptable[dated].title
							GMForum[dated].edited = tonumber(temptable[dated].edited)
						else
							GMForum[dated] = {replyto = replyto, title = temptable[dated].title, msg = temptable[dated].message, name = temptable[dated].name}
						end
						temptable[dated] = nil
					end
			
			
			
		elseif prefix:find("^GMFRequest"..PlayerName) then
			--send the table
			msg = tonumber(msg)
			local send
			
			if GMForum[msg] then
				if GMForum[msg].edited then
					send = msg.."-"..GMForum[msg].replyto.."|title"..GMForum[msg].title.."|name"..GMForum[msg].name.."|e"..GMForum[msg].edited
				else
						send = msg.."-"..GMForum[msg].replyto.."|title"..GMForum[msg].title.."|name"..GMForum[msg].name.."|"
				end
				GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMFSend"..player, send}
			
				local str = GMForum[msg].msg
				
				while str:sub(1, 200) ~= "" do
					send = msg.."-"..GMForum[msg].replyto.."|msg"..str:sub(1,200)
				   str = str:sub(201)
				   
				   GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMFSend"..player, send}
				end
				
				GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMFSend"..player, (msg.."-"..GMForum[msg].replyto.."|&&&&")}

			end
			
		end
	end

	function GMaster.PEW.ForumBroadcast() --should move this to AL really
		if GMaster.LastLogin < (time() - 3600) then
			if GMForum then
				for dated, info in pairs(GMForum) do --broadcast all know forum message dates
					if info.msg == "DELETED" then
						GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMFBroadcast", dated.."-"..info.replyto.."|DELETED"}
					elseif info.edited then
						GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMFBroadcast", dated.."-"..info.replyto.."|e"..info.edited}
					else
						GMaster.QueueTable[#GMaster.QueueTable + 1] = {"GMFBroadcast", dated.."-"..info.replyto.."|"}
					end
				end
			end	
		end
	end
end

function GMaster.ModuleSettings.GMForum()
--create settings page
	local parent = CreateFrame("Frame")
		parent.titleText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		parent.titleText:SetPoint("TOPLEFT", parent, "TOPLEFT", 30, -40)
		parent.titleText:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -30, 40)
		parent.titleText:SetJustifyH("LEFT")
		parent.titleText:SetJustifyV("TOP")
		parent.titleText:SetText("GM-Forum adds a small forum to the guild frame, allowing you to communicate with players that aren't online.\n ")
	return parent


end

function GMaster.ModuleLoad.GMForum()
	--enable the module
	GMaster.AL.GMForum()
	if GMaster.GUILD_FRAME_LOADED then
		GMaster.GFL.GMForum()
	else
		LoadAddOn("Blizzard_GuildUI")
	end
	
	
	
end

function GMaster.ModuleRemove.GMForum()
	if module.ChatButton then
		module.ChatButton:Hide()
	end
	if GuildFrame_TabClicked then
	GuildFrame_TabClicked(GuildFrameTab1);
	end
	
	return true
end


