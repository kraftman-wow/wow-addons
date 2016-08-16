
--[[
TODO:
check compatibilty with other nameplate addons
block non healing classes

--]]


local heallist = {}

local exclass = {}


local testing = nil

exclass.WARRIOR = true
exclass.DEATHKNIGHT = true
exclass.MAGE = true
exclass.WARLOCK = true
exclass.ROGUE = true

local function UpdatePlate(self)
	if heallist[self.HPname:GetText()] or testing then
		self.HPHeal:Show()
	else
		self.HPHeal:Hide()
	end
end

local function IsValidFrame(frame)
	if frame:GetName() then
		return
	end
	if frame.aloftData then 
		return true
	end
	
	if frame.done then
		return true
	end
	
	local overlayRegion = select(2, frame:GetRegions())
	return overlayRegion and overlayRegion:GetObjectType() == "Texture" and overlayRegion:GetTexture() == "Interface\\Tooltips\\Nameplate-Border"
end


local function CreatePlate(frame)
	if frame.HPdone then
		return
	end

	frame.nameplate = true

	frame.healthBar, frame.castBar = frame:GetChildren()
	local healthBar, castBar = frame.healthBar, frame.castBar
		local glowRegion, overlayRegion, castbarOverlay, shieldedRegion, spellIconRegion, highlightRegion, nameTextRegion, levelTextRegion, bossIconRegion, raidIconRegion, stateIconRegion = frame:GetRegions()

	frame.HPname = nameTextRegion
	
	frame.HPHeal = frame:CreateTexture()
	frame.HPHeal:SetHeight(50)
	frame.HPHeal:SetWidth(50)
	frame.HPHeal:SetPoint("BOTTOM", frame, "TOP", 0, 10)
	frame.HPHeal:SetTexture()
	
	
	frame.HPHeal:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-RoleS")
	frame.HPHeal:SetTexCoord(GetTexCoordsForRole("HEALER"))
	
	frame.HPdone = true

	UpdatePlate(frame)
	frame:HookScript("OnShow", UpdatePlate)
	--hooksecurefunc(frame, "Show", UpdatePlate)
	--frame:SetScript("OnShow", UpdatePlate)

end

local numKids = 0
local lastUpdate = 0

local f = CreateFrame("Frame")
f:SetScript("OnUpdate", function(self, elapsed)
	lastUpdate = lastUpdate + elapsed

	if lastUpdate > 5 then
		lastUpdate = 0
		local newNumKids = WorldFrame:GetNumChildren()
		if newNumKids ~= numKids then
			for i = numKids + 1, newNumKids do
				local frame = select(i, WorldFrame:GetChildren())
				if IsValidFrame(frame) then
					CreatePlate(frame)
				end
			end
			numKids = newNumKids
		end
	end
end)

local lastcheck = 0
local t = CreateFrame("Frame")

local function CheckHealers(self, elapsed)	
	lastcheck = lastcheck + elapsed
	if lastcheck > 30 then
		lastcheck = 0
		heallist = {}
		for i = 1, GetNumBattlefieldScores() do
					local name, killingBlows, honorableKills, deaths, honorGained, faction, race, class, classToken, damageDone, healingDone, bgRating, ratingChange = GetBattlefieldScore(i);
				if (healingDone > damageDone*1.2) and faction == 1 then
					name = name:match("(.+)%-.+") or name
					if not exclass[classToken] then
						heallist[name] = true
					end
				end
		end
	end
end

local function checkloc(self, event)
	local isin, instype = IsInInstance()
	if isin and instype == "pvp" then
		t:SetScript("OnUpdate", CheckHealers)
	else
		heallist = {}
		t:SetScript("OnUpdate", nil)
	end			
end

t:RegisterEvent("PLAYER_ENTERING_WORLD")
t:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND")
t:SetScript("OnEvent", checkloc)



local function TestIt()
testing = not testing

end

SLASH_KHeal1 = "/KHT";
SlashCmdList["KHeal"] = TestIt;


















