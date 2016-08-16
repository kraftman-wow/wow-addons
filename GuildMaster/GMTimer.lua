--[[

1. About
2. Changes
3. To do.
 
--========================== 1. About ===============================
This module containers a timer which all of the modules use to schedule thier functions.
Since none of the modules need to check settings on every frame, this module reduces the number 
of function calls, and the number of frames needed to be created.

--========================== 2. Changes ==============================
2.0 
	-fixed an error preventing the timer repeating.
1.53
	New method for adding timers, makes things slightly neater
	some minor increases in efficiency
1.42
Moved the message queueing function from GMSync to here, which means other addons can still use it when 
GMSync is deactivated.

--========================== 3. To do ================================
Need to make the function that adds the queued stuff work faster.

Efficiency:
Need to have seperate tables for different jobs, 
eg some functions only need checking once a second, once a minute, once an hours

Make the timer more efficient:
only perform updates as fast as the fastest required update

]]

local SendAddonMessage = SendAddonMessage
local unpack = unpack
local tremove = tremove

local StopWatch = CreateFrame("Frame")
StopWatch.interval = 0.1
StopWatch.elapsed = 0
GMaster.Timers = {}

GMTimer = {}


local function StopWatcher(self, elapsed)
	StopWatch.elapsed = StopWatch.elapsed + elapsed
	if StopWatch.elapsed >= StopWatch.interval then
		for i = #GMaster.Timers , 1, -1 do
			local timer = GMaster.Timers[i]
			if timer then
				timer.elapsed = timer.elapsed + StopWatch.elapsed
				if timer.elapsed >= timer.interval then
					if timer.vars then
							timer.func(unpack(timer.vars))
					else
							timer.func()
					end
				
					if timer.dorepeat then
						timer.elapsed = 0
					else
						tremove(GMaster.Timers, i)
					end
				end
			end
		end
		StopWatch.elapsed = 0
	end
end

function GMTimer:NewTimer(interval, func, args, dorepeat)
	--print(interval, func, args, dorepeat)
	tinsert(GMaster.Timers, {dorepeat = dorepeat, interval = interval, elapsed = 0, func = func, vars = args})
end

StopWatch:SetScript("OnUpdate", StopWatcher)

local queue = GMaster.QueueTable

local function QueueIt()
	
	if #queue > 0 then
		local prefix, msg = unpack(tremove(queue, 1))
		if prefix and msg then
			if IsInGuild() then
				SendAddonMessage(prefix, msg, "GUILD")
			end
		end
	end
	if GMSettings.Active == true and not (GMSettings.StartTime == 0) then
		if #GMaster.TempTable > 0 then --if there are temporary values
			local a, b, i, v, l = unpack(tremove(GMaster.TempTable,1))
			GMaster:Debug("Adding queued info "..a..i..v)
			GMaster.AddInfo(a, b, i, v, l)
			--[[
			for i = 1, #GMaster.TempTable do
				local a, b, i, v, l = unpack(GMaster.TempTable[i])
				GMaster:Debug("Adding queued info "..a..i..v)
				GMaster.AddInfo(a, b, i, v, l)
			end
			GMaster.TempTable = {}
			--]]
			
		end
	end
end

GMTimer:NewTimer(0.3, QueueIt, nil, true)
--tinsert(GMaster.Timers, {runonce = false, interval = 0.3, elapsed = 0, func = QueueIt})

--Example:
-- old
--run a function without vars:
--	tinsert(GMaster.Timers, {runonce = true, interval = 3, elapsed = 0, func = AcceptGroup})
--run a function with vars:
--tinsert(GMaster.Timers, {runonce = true, interval = 5, elapsed = 0, func =  StaticPopup_Hide, vars = {"PARTY_INVITE"}})