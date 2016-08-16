--[[
1. Summary 
2. Details
3. Structure
4. Changes
5. To Do

--========================== 1. Summary ===============================
	Adds filters to each bank tab allowing you to automatically sort items 
	depending on type, subtype, Quality, or auction value. (Requires auctioneer for auction value 
	to be determined
--========================== 2. Details ===============================
	The guild master can use the dropdown menu to add certain filters to a tab, for example
	only Blue items that are weapons, or green gems.
	The module then scans all of the items and find any which match all of the tabs filters,
	matching items are then moved to the desired tab.
	Any items which do not match any filter are auto sorted by subtype, and placed in any tabs that 
	have no filters.
	Tabs that have "Ignore" selected in the dropdown menu are treated like they do no exist.
	No items will be moved from them or placed into them.
	
	Each tab can also have a minimum value set. This pulls the item auction price from the Auctioneer database,
	and multiplies it by the number of items in the stack. If the value is above a tabs minimum value, the item
	will be moved to that tab. This is useful for creating Officer tabs which contain expensive items that
	general guild members cannot access.
	
	Due to the latency between the client and server, some items may not get properly moved between tabs.
	the module attempts to compensate for this by splitting movement of items that may conflict across multiple passes.
	If after sorting the bank it looks like it hasnt quite sorted all of the items, run the sort again and it should sort
	it out.
--========================== 3. Structure =============================
	Button - Auto sort. Requests tab data from the server and runs 
	AllocateItems - records the item in every tab
	SortItems - Works out where each item needs to go based on the filters, queues each item
	AllocateItems - sends the movement to the server
	
--========================== 4. Changes ===============================
2.1
	The guild bank frame should no longer overlap other frames when shown
	away from the guild bank.
	Added a last scanned time.

2.0
	Added button to the guildframe to enable toggling the guild bank
1.6
	Converted to new timer method
	fixed error on checking for auctioneer
	guild bank frame shows away from the guild bank.
1.52
	Created the module - Filters and sorting now work.
--========================== 5. To do =================================
	Show the last checked time.
	Auto bag greys.
	Change the pass system to recheck the location each time.
	
	Integrate settings and load/unload
	need to add an icon to the guild frame
]]

GMaster.LoadOrder.GMBanker = true --can change this to force disable the addon

local module = {}

function GMaster.AL.GMBanker()


end

GMBanker = {}
GMBanker.SaveList = {}




local SaveList = GMBanker.SaveList


local Filters = {}
local module = {}

local modes = {}
			modes["Quality"] = {r = 0.5, g = 0, b = 0}
			modes["Item Level"] = {r = 0, g = 0.5, b = 0}

local mode = "test"

local itemClasses = { GetAuctionItemClasses() };

local flatlist = {} --list of all items in the bank
local treelist = {}

local BagSpace = 0

local BANK_LOADED

local virtual


local AutoSort = CreateFrame("Button", nil, UIParent, "UIPanelButtonTemplate")
			AutoSort:SetSize(80, 25)
			AutoSort:SetText("Auto Sort")
			
			
local MoneyBox = CreateFrame("EditBox", "GMBankEB", UIParent, "InputBoxTemplate")
			MoneyBox:SetNumeric(true)
			MoneyBox:SetAutoFocus(false)
	MoneyBox:Hide()
	
	local moneytext = MoneyBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		moneytext:SetSize(100, 20)
		moneytext:SetPoint("RIGHT", MoneyBox, "LEFT", -5, 0)
		moneytext:SetText("Min Value (g):")

local ModeDD = CreateFrame("Frame", "GMBankModeDD", UIParent, "UIDropDownMenuTemplate")


local loadBar = CreateFrame("StatusBar", "GMBankerTestBar", UIParent)

local BankTip = CreateFrame("GameTooltip","GMBankerTT", UIParent, "GameTooltipTemplate")

local function SetLabels(title, text)
	GuildBankMoneyLimitLabel:SetText(title)
	GuildBankMoneyUnlimitedLabel:SetText(text)
end

local function LoadBank()
	if not BANK_LOADED then
		LoadAddOn("Blizzard_GuildBankUI")
		BANK_LOADED = true
	else

	end

	if GuildBankFrame:IsShown() then
		GuildBankFrame:Hide()
	else
		virtual = true
		--GuildBankFrame:Show()
		ShowUIPanel(GuildBankFrame)
	end

end

local BankButton = CreateFrame("Button", nil, UIParent)

function GMaster.GFL.GMBanker()
	BankButton:SetParent(GuildFrame)
	BankButton:SetScript("OnClick", LoadBank) 
	BankButton.bg = BankButton:CreateTexture()
	BankButton.bg:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder.blp")
	BankButton.bg:SetAllPoints(BankButton)
	BankButton.bg:SetTexCoord(0, 0.5, 0, 0.5)
	BankButton.icon = BankButton:CreateTexture()
	BankButton.icon:SetTexture("Interface\\Minimap\\OBJECTICONS")
	BankButton.icon:SetPoint("TOPLEFT", 5, -5)
	BankButton.icon:SetPoint("BOTTOMRIGHT", -5, 5)
	BankButton.icon:SetTexCoord(0.125, 0.25, 0.5, 0.75)
	BankButton:SetSize(30,30)
	BankButton:SetPoint("CENTER", GuildFrame, "TOPLEFT")
	
end

local function GuildBank_OnHide()
	virtual = false
end

local function GuildBank_OnShow(force)
	if virtual then
		AutoSort:Hide()
		ModeDD:Hide()
		GuildBankFrameTab1:Hide()
		GuildBankFrameTab2:Hide()
		GuildBankFrameTab3:Hide()
		GuildBankFrameTab4:Hide()
	
		if GMBanker.lastcheck then
			SetLabels("Last Scanned:", date("%H:%M:%S %d/%m/%y", GMBanker.lastcheck)) 
		end
		
	else
		GuildBankFrameTab1:Show()
		GuildBankFrameTab2:Show()
		GuildBankFrameTab3:Show()
		GuildBankFrameTab4:Show()
		
		AutoSort:Show()
		ModeDD:Show()
		flatlist = {} --clear out the old lists
		treelist = {}
		wipe(SaveList)
		local dur = 0
		local tabmax = GetNumGuildBankTabs()
		GMBanker.LimitLabel = GuildBankMoneyLimitLabel:GetText() --store the old labels
		GMBanker.LimitText = GuildBankMoneyUnlimitedLabel:GetText() 
		GMBanker.lastcheck = time()
		for i = 1, tabmax do 
			dur = dur + 0.1
			if Filters[i].Ignore then
																			
			else
				GMTimer:NewTimer(dur, QueryGuildBankTab, {i})
				GMTimer:NewTimer(dur, SetLabels, {"Requesting: ", "Tab "..i})
				GMTimer:NewTimer(dur, function(arg1) loadBar:SetValue(arg1) end, {(100/tabmax)*i})
				GMTimer:NewTimer(dur+1, module.CheckTabs, {i})
				GMTimer:NewTimer(dur+1, SetLabels, {"Scanning: ", "Tab "..i})		
			end
		end
		GMTimer:NewTimer(dur+2, function() loadBar:Hide() SetLabels(GMBanker.LimitLabel, GMBanker.LimitText) end )

		return dur
	end
end


function testest1()
	if not GuildBankFrame then
		LoadAddOn("Blizzard_GuildBankUI")
	end
	virtual = true
	--GuildBankFrame:Show()
	ShowUIPanel(GuildBankFrame)
end

--========================= Frames ==============================

local function dropdown_OnClick(self, itype, isubtype)
	local tab = GetCurrentGuildBankTab() 
	
	if not Filters[tab] then
		Filters[tab] = {}
	end
	if not Filters[tab][itype] then
		Filters[tab][itype] = {}
	end
	
	if Filters[tab][itype][isubtype] then
		Filters[tab][itype][isubtype] = nil
		if not next(Filters[tab][itype]) then
			Filters[tab][itype] = nil
		end
	else
		Filters[tab][itype][isubtype] = true
	end
end

local function CheckFilter(itype,name)
	if not Filters[GetCurrentGuildBankTab()] then
		return nil
	elseif not Filters[GetCurrentGuildBankTab()][itype] then
		return nil
	elseif not Filters[GetCurrentGuildBankTab()][itype][name] then
		return nil
	end

	if Filters[GetCurrentGuildBankTab()][itype][name] then
		return true
	end
end



UIDropDownMenu_SetWidth(ModeDD, 110)
UIDropDownMenu_SetButtonWidth(ModeDD, 85)

local function ModeDD_Initialize(self, level) -- the menu items, needs a cleanup
		level = level or 1
	local info = UIDropDownMenu_CreateInfo()
	local value = UIDROPDOWNMENU_MENU_VALUE
	
	info.isNotRadio = true
	
	if level == 1 then
	
		info.notCheckable = true
		info.text = "Type"
		info.value = "weptype"
		info.hasArrow = true
		info.func = function()  end
		UIDropDownMenu_AddButton(info, level)
		
		info.text = "Quality"
		info.value = "Quality"
		info.hasArrow = true
		info.func = function(self)  end
		UIDropDownMenu_AddButton(info, level)
		
		info.text = "Ignore"
		info.value = "Ignore"
		info.hasArrow = false
		info.notCheckable = false
		info.checked = function() if not Filters[GetCurrentGuildBankTab()] then return nil elseif not Filters[GetCurrentGuildBankTab()].Ignore then return nil else return true end end
		info.func = function(self) if Filters[GetCurrentGuildBankTab()].Ignore then Filters[GetCurrentGuildBankTab()].Ignore = nil else Filters[GetCurrentGuildBankTab()].Ignore = true  end end
		UIDropDownMenu_AddButton(info, level)
	
	elseif level == 2 then 
		if value == "weptype" then
			for i, name in pairs(itemClasses) do
				info.text = name
				info.value = i
				info.arg1 = "itemType"
				info.arg2 = name
				info.checked = CheckFilter("itemType", name)
				info.func = dropdown_OnClick
				info.hasArrow = true
				info.keepShownOnClick = true
				UIDropDownMenu_AddButton(info, level)
			end
		elseif value == "Quality" then
			for i=0, getn(ITEM_QUALITY_COLORS)-2  do
				local name = _G["ITEM_QUALITY"..i.."_DESC"];
				info.text = name
				info.value = name
				info.arg1 = "itemRarity"
				info.arg2 = name
				info.func = dropdown_OnClick
				info.keepShownOnClick = true
				info.checked = CheckFilter("itemRarity", name)
				
				info.colorCode = select(4, GetItemQualityColor(i))
				UIDropDownMenu_AddButton(info, level);
			end
		end
	elseif level == 3 then
		local test = {GetAuctionItemSubClasses(value)}
		
		for i = 1, #test do
			info.text = test[i]
			info.value = i
			info.checked = CheckFilter("itemSubType", test[i])
			info.arg1 = "itemSubType"
			info.arg2 = test[i]
			info.func = dropdown_OnClick
			info.keepShownOnClick = true
			UIDropDownMenu_AddButton(info, level)
		end
	end
end

UIDropDownMenu_Initialize(ModeDD, ModeDD_Initialize)
UIDropDownMenu_SetText(ModeDD, "Select Filters")

		

	
	
	
local function moneyEnterPressed(self)
local tab = GetCurrentGuildBankTab()
local value = tonumber(self:GetText())
	if value == 0 then
		self:SetText("")
		Filters[tab].MinVal = nil
	elseif value and (value > 0) then
		Filters[tab].MinVal = value*10000
	end
end


	MoneyBox:SetScript("OnEnterPressed", moneyEnterPressed)


--=====================================================================

local function OnTabClick()
local tab = GetCurrentGuildBankTab()
	if Filters[tab].MinVal then
		MoneyBox:SetText(Filters[tab].MinVal/10000)
	else
		MoneyBox:SetText("")
	end

	if virtual then
		
			local button, index, column;
			local texture, itemCount, locked;
			for i=1, MAX_GUILDBANK_SLOTS_PER_TAB do
				index = mod(i, NUM_SLOTS_PER_GUILDBANK_GROUP);
				if ( index == 0 ) then
					index = NUM_SLOTS_PER_GUILDBANK_GROUP;
				end
				column = ceil((i-0.5)/NUM_SLOTS_PER_GUILDBANK_GROUP);
				button = _G["GuildBankColumn"..column.."Button"..index];
				button:SetScript("OnLeave", function(self) BankTip:Hide() end)
				button:SetID(i);
				if SaveList[tab] then
				--print(tab, "test", i, SaveList[tab][i], SaveList[tab][i].texture)
				local item = SaveList[tab][i]
					if item and item.texture then
						
						SetItemButtonTexture(button, item.texture);
						SetItemButtonCount(button, item.count);
						button.link = item.link
						button:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
						
					else
						button.link = nil
					end
				end
			end
	end
	
end
													
													
local function GMBanker_OnLoad()
	
	if not GMBanker.Filters then
		GMBanker.Filters = {}
	end
	
	function GuildBankItemButton_OnEnter(self)
		if self.link then 
			BankTip:SetOwner(self, "ANCHOR_RIGHT")
			BankTip:SetHyperlink(self.link)
		else
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:SetGuildBankItem(GetCurrentGuildBankTab(), self:GetID())
		end
	end
	
	Filters = GMBanker.Filters
	
	SaveList = GMBanker.SaveList
	 
	for i = 1, GetNumGuildBankTabs() do
		if not Filters[i] then
			Filters[i] = {}
		end
	end
	

	hooksecurefunc(GuildBankFrame, "Show", GuildBank_OnShow)
	hooksecurefunc(GuildBankFrame, "Hide", GuildBank_OnHide)
	--if auctioneer is running, allow the price box
	--need to check and remove any previous price filters.
	if AucAdvanced and AucAdvanced.API and AucAdvanced.API.GetMarketValue then
		MoneyBox:SetParent(GuildBankFrame)
		MoneyBox:SetPoint("TOP", GuildBankFrame, "TOP", -130, -40)
		MoneyBox:SetSize(60, 20)
		MoneyBox:Show()
		MoneyBox:SetScript("OnEscapePressed", function(self) self:ClearFocus()  end)
		
		moneytext:Show()
		
		hooksecurefunc("GuildBankTab_OnClick", OnTabClick)
	end
	
	
	loadBar:SetParent(GuildBankFrame)
	loadBar:SetSize(410, 10)
	loadBar:SetPoint("BOTTOMLEFT", 210, 17)
	loadBar:SetMinMaxValues(0, 100)
	loadBar:SetValue(100)
	loadBar:SetStatusBarTexture("Interface\\Tooltips\\UI-Tooltip-Background")
	loadBar:SetStatusBarColor(0, 1, 0)
	
	AutoSort:SetParent(GuildBankFrame)
	AutoSort:SetPoint("TOPRIGHT", -14, -38)
	
	ModeDD:SetParent(GuildBankFrame)
	ModeDD:SetPoint("TOPRIGHT", -80, -37)
	
	if IsGuildLeader() then
		AutoSort:Show()
		ModeDD:Show()
		MoneyBox:Show()
		moneytext:Show()
		
	else
		AutoSort:Hide()
		ModeDD:Hide()
		MoneyBox:Hide()
		moneytext:Hide()
		
	end
end


local Eventler = CreateFrame("Frame")

Eventler:RegisterEvent("ADDON_LOADED")
Eventler:SetScript("OnEvent", function(self, event, addon)
																if addon == "Blizzard_GuildBankUI" then
																	GMBanker_OnLoad()
																	
																end
															end)


--========================= functional stuff =========================





local function GetAucValue(itemlink)
	--need to check auctioneer is loaded
	if AucAdvanced then
		local value, seen = AucAdvanced.API.GetMarketValue(AucAdvanced.SanitizeLink(select(2, GetItemInfo(itemlink))))
		return value, seen
	 end
end

--check the number of free bag slots
local function CheckBagSpace()
	bagspace = 0
	for bag = 0,4 do
		bagspace = bagspace + GetContainerNumFreeSlots(bag)
	end
	return bagspace
end



									 
local function AllocateItems(start, finish, pass)
	local igcount = 0
	local movcount = 0
	for i = start, finish do
		if not flatlist[i] then
			return
		end
		local item = flatlist[i]
		
		local link = GetGuildBankItemLink(item.totab, item.toslot)
		local count = select(2, GetGuildBankItemInfo(item.totab, item.toslot))
		if item.pass and (item.pass > pass) then
			return
		end
		if item.moved or link == item.link then
			
			igcount = igcount + 1
			item.moved = true
		else
			movcount = movcount + 1
			
			if treelist[item.totab][item.toslot] == "Empty" then
				--its moving to an empty slot
					PickupGuildBankItem(item.tab, item.slot) --pick it up
					PickupGuildBankItem(item.totab, item.toslot) --drop it in the empty slot
					treelist[item.tab][item.slot] = "Empty" --mark the old slot as empty
					treelist[item.totab][item.toslot] = item --mark the new slot as full 
					item.tab = item.totab
					item.slot = item.toslot
			else
				PickupGuildBankItem(item.tab, item.slot) --pick it up
				PickupGuildBankItem(item.totab, item.toslot) -- swap it with the other one
				
				for i = 1, #flatlist do --find the one thats been replaced
					if flatlist[i].tab == item.totab and flatlist[i].slot == item.toslot then
							flatlist[i].tab = item.tab
							flatlist[i].slot = item.slot
							flatlist[i].pass = pass+ 1
						if flatlist[i] == item then
							item.tab = item.totab
							item.slot = item.toslot
						end
					end					
				end
			end
			QueryGuildBankTab(item.tab)
		end
	end
	print("Moved: "..movcount..", ignored: "..igcount)
end
									 
local function SortItems()
	
	table.sort(flatlist, function(a, b) return a.SortBy < b.SortBy end) --sort by the necessary requirement


	local tabmax = GetNumGuildBankTabs()
	
	local bagsize = CheckBagSpace()
	local bagcount = 0
	
	local tabcount = {}
		for i = 1, tabmax do
			tabcount[i] = 1
		end
	
	for i, item in pairs(flatlist) do
		
		local found = nil
	
	
		for j = 1, tabmax do
			if Filters[j].Ignore then
			
			elseif Filters[j].MinVal and ((item.itemAuc*item.itemStackCount) > Filters[j].MinVal) then
				found = j
			else
				local loc = nil
				for filter, subfilter in pairs(Filters[j]) do
					if (filter ~= "MinVal") and (filter ~= "SortBy") then
						if item[filter] and subfilter[item[filter]] then
							loc = j
						else
							loc = nil
						end				
					end
				end	
				if loc then --it matches all filters
					found = loc
				end
			end
		end
		
		if found then
			if tabcount[found] < (7*14) then
				item.totab = found
				item.toslot = tabcount[found]
				tabcount[found] = tabcount[found] + 1
			else
				found = nil
			end
		end
		
		-- at this point anything that matches a filter has been allocated a slot, anything else 
		-- will be either put into a tab with no filters, or placed in the bag
		for i = 1, #flatlist do
			if baggreys and not found then
				if item.itemRarityIndex == 0 then
					if bagspace > 0 then
						AutoStoreGuildBankItem(item.tab, item.slot)
						item.moved = true --prevent the next function from messing around with it
						TreeList[item.tab][item.slot] = "Empty" --mark its slot as empty
					end
				end			
			end
		end
		
		if not found then
			local t = 1
			while (Filters[t] ~= {}) and (tabcount[t] >= 7*14) --[[or Filters[t].Ignore]]  do --needs testing
				t = t + 1
				if t > tabmax then
					break
				end
			end
			if t > tabmax then
				
				--it doesnt fit anywhere
				--bag it
				--return
			else
				item.totab = t
				item.toslot = tabcount[t]
				tabcount[t] = tabcount[t] + 1
			end
		end
	end

	
	local split = 20
	local interval = 0.5
	local passes = 2
	local passtime = interval * #flatlist + 10
	
	local tabmax = tabmax
	local itemcount = #flatlist
	
	for j = 0, passes-1 do
		for i = 0, floor((itemcount/split)+0.5) do
			GMTimer:NewTimer(i*interval + j*passtime, AllocateItems, {i*split + 1, i*split + split, j})
			
			for k = 1, tabmax do
				GMTimer:NewTimer((passtime*j)-2, QueryGuildBankTab, {k})
			end
				GMTimer:NewTimer(i*interval + j*passtime, SetLabels, {"Pass: "..(j+1),"Sorting items: "..(i*split + 1).." to "..(i*split + split)} )
				GMTimer:NewTimer(i*interval + j*passtime, function(arg1) loadBar:SetValue(arg1) end, {(j*itemcount + i*split)/(passes*itemcount)*100})
		end
	end
	GMTimer:NewTimer(((passes+1)*passtime)-5, SetLabels, {"Done!",""} )
	GMTimer:NewTimer((passes+1)*passtime, function() loadBar:Hide() SetLabels(GMBanker.LimitLabel, GMBanker.LimitText) end )

end

function module.CheckTabs(tab)
	 --GuildBankTab_OnClick(nil, nil, tab) --check if this is still needed or not
		--check docks, mmight need to manually switch tabs here
		if not treelist[tab] then
			treelist[tab] = {}
		end
		if not SaveList[tab] then
			SaveList[tab] = {}
		end
		
		for slot = 1, (14*7) do
			local link = GetGuildBankItemLink(tab, slot)
			local count = select(2, GetGuildBankItemInfo(tab, slot))
			
			loadBar:Show()
			
			if link then --if an item exists
				local usable = IsUsableItem(link)
				local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount,
							itemEquipLoc, itemTexture, itemSellPrice = GetItemInfo(link)
							
					tinsert(flatlist, {
															link = link,
															tab = tab,
															slot = slot,
															itemName = itemName,
															itemLink = itemLink,
															itemRarity = _G["ITEM_QUALITY"..itemRarity.."_DESC"],
															itemRarityIndex = itemRarity,
															itemLevel = itemLevel,
															itemMinLevel = itemMinLevel, 
															itemType = itemType,
															itemSubType = itemSubType,
															itemStackCount = count,
															itemEquipLoc = itemEquipLoc,
															itemTexture = itemTexture,
															itemSellPrice = itemSellPrice,
															itemAuc = GetAucValue(itemLink) or 0,
															SortBy = itemSubType..itemName
															
														})
						treelist[tab][slot] = flatlist[#flatlist]
						SaveList[tab][slot] = {count = count, texture = itemTexture, link = itemLink}
						--print("tab: "..tab, "slot: "..slot, treelist[tab][slot].itemType)
			else
				treelist[tab][slot] = "Empty" --store location of empty places
				SaveList[tab][slot] = {}
			end
	end
end



AutoSort:SetScript("OnClick", function() 
																CheckBagSpace()
																local dur = GuildBank_OnShow() -- get most recent item data, and duration to wait (dependant on tab number)
																GMTimer:NewTimer(dur, SetLabels, {"Sorting..", ""})
																GMTimer:NewTimer(dur+3, SortItems)																		
															end)



															
															
															
															
--=================================================================================
--=================================================================================

function GMaster.ModuleSettings.GMBanker()
	local parent = CreateFrame("Frame")
			parent.titleText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			parent.titleText:SetPoint("TOPLEFT", parent, "TOPLEFT", 30, -40)
			parent.titleText:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -30, 40)
			parent.titleText:SetJustifyH("LEFT")
			parent.titleText:SetJustifyV("TOP")
			parent.titleText:SetText("GM-Banker"..
																"\n ")
		return parent
end

function GMaster.ModuleLoad.GMBanker()
	GMaster.AL.GMBanker()
	GMBanker_OnLoad()
end

function GMaster.ModuleRemove.GMBanker()
	AutoSort:Hide()
	ModeDD:Hide()
	MoneyBox:Hide()
	BankButton:Hide()
	return false
end
