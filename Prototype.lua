﻿--------------------------------
--      Module Prototype      --
--------------------------------

local L = AceLibrary("AceLocale-2.2"):new("BigWigs")
local BB = AceLibrary("Babble-Boss-2.2")

-- Provide some common translations here, so we don't have to replicate it in
-- every freaking module.
local commonWords = AceLibrary("AceLocale-2.2"):new("BigWigsCommonWords")
commonWords:RegisterTranslations("enUS", function() return {
	you = "You",
	are = "are",

	enrage_start = "%s Engaged - Enrage in %dmin",
	enrage_end = "%s Enraged",
	enrage_min = "Enrage in %d min",
	enrage_sec = "Enrage in %d sec",
	enrage = "Enrage",
} end)

commonWords:RegisterTranslations("deDE", function() return {
	you = "Ihr",
	are = "seid",
} end )

commonWords:RegisterTranslations("koKR", function() return {
	you = "당신은",
	are = " ",

	enrage_start = "%s 전투 개시 - %d분 후 격노",
	enrage_end = "%s 격노",
	enrage_min = "%d분 후 격노",
	enrage_sec = "%d초 후 격노",
	enrage = "격노",
} end )

commonWords:RegisterTranslations("zhCN", function() return {
	you = "你",
	are = "到",
} end )

commonWords:RegisterTranslations("zhTW", function() return {
	you = "你",
	are = "了",
} end )

commonWords:RegisterTranslations("frFR", function() return {
	you = "Vous",
	are = "subissez",

	enrage_start = "%s engagé - Enragé dans %d min.",
	enrage_end = "%s enragé",
	enrage_min = "Enragé dans %d min.",
	enrage_sec = "Enragé dans %d sec.",
	enrage = "Enrager",
} end )


function BigWigs.modulePrototype:OnInitialize()
	-- Unconditionally register, this shouldn't happen from any other place
	-- anyway.
	BigWigs:RegisterModule(self.name, self)
end

function BigWigs.modulePrototype:IsBossModule()
	return self.zonename and self.enabletrigger and true
end

function BigWigs.modulePrototype:GenericBossDeath(msg)
	if msg == UNITDIESOTHER:format(self:ToString()) then
		self:Sync("BossDeath " .. self:ToString())
	end
end

local function populateScanTable(mod)
	if type(mod.scanTable) == "table" then return end
	mod.scanTable = {}

	local x = mod.enabletrigger
	if type(x) == "string" then
		mod.scanTable[x] = true
	elseif type(x) == "table" then
		for i, v in ipairs(x) do
			mod.scanTable[v] = true
		end
	end

	local a = mod.wipemobs
	if type(a) == "string" then
		mod.scanTable[a] = true
	elseif type(a) == "table" then
		for i, v in ipairs(a) do
			mod.scanTable[v] = true
		end
	end
end

function BigWigs.modulePrototype:Scan()
	if not self.scanTable then populateScanTable(self) end

	if UnitExists("target") and UnitAffectingCombat("target") and self.scanTable[UnitName("target")] then
		return true
	end

	if UnitExists("focus") and UnitAffectingCombat("focus") and self.scanTable[UnitName("focus")] then
		return true
	end

	local num = GetNumRaidMembers()
	if num == 0 then
		num = GetNumPartyMembers()
		for i = 1, num do
			local partyUnit = string.format("party%starget", i)
			if UnitExists(partyUnit) and UnitAffectingCombat(partyUnit) and self.scanTable[UnitName(partyUnit)] then
				return true
			end			
		end
	else
		for i = 1, num do
			local raidUnit = string.format("raid%starget", i)
			if UnitExists(raidUnit) and UnitAffectingCombat(raidUnit) and self.scanTable[UnitName(raidUnit)] then
				return true
			end
		end
	end
	return false	
end

function BigWigs.modulePrototype:GetEngageSync()
	return "BossEngaged"
end

-- Really not much of a validation, but at least it validates that the sync is
-- remotely related to the module :P
function BigWigs.modulePrototype:ValidateEngageSync(sync, rest)
	if type(sync) ~= "string" or type(rest) ~= "string" then return false end
	if sync ~= self:GetEngageSync() then return false end
	local boss = BB:HasReverseTranslation(rest) and BB:GetReverseTranslation(rest) or rest
	if not self.scanTable then populateScanTable(self) end
	for mob in pairs(self.scanTable) do
		local translated = BB:HasReverseTranslation(mob) and BB:GetReverseTranslation(mob) or mob
		if translated == rest or mob == rest then return true end
	end
	return boss == self:ToString() or rest == self:ToString()
end

function BigWigs.modulePrototype:CheckForEngage()
	local go = self:Scan()
	if go then
		if BigWigs:IsDebugging() then
			BigWigs:Debug(self, "Scan returned true, engaging.")
		end
		local mod = self:ToString()
		local moduleName = BB:HasReverseTranslation(mod) and BB:GetReverseTranslation(mod) or mod
		self:Sync(self:GetEngageSync().." "..moduleName)
	elseif UnitAffectingCombat("player") then
		self:ScheduleEvent(self.CheckForEngage, .5, self)
	end
end

-- 2.1.0 compat
local fdFunc = nil
if type(UnitIsFeignDeath) == "function" then
	fdFunc = function() return UnitIsFeignDeath("player") end
else
	fdFunc = function() return IsFeignDeath() end
end

function BigWigs.modulePrototype:CheckForWipe()
	if not fdFunc() then
		local go = self:Scan()
		if not go then
			if BigWigs:IsDebugging() then
				BigWigs:Debug(self, "Rebooting module.")
			end
			self:TriggerEvent("BigWigs_RemoveRaidIcon")
			self:TriggerEvent("BigWigs_RebootModule", self)
			return
		end
	end

	if not UnitAffectingCombat("player") then
		self:ScheduleEvent(self.CheckForWipe, 2, self)
	end
end

-- Shortcuts for common actions.

function BigWigs.modulePrototype:Message(text, priority, ...)
	self:TriggerEvent("BigWigs_Message", text, priority, ...)
end

function BigWigs.modulePrototype:DelayedMessage(delay, text, priority, ...)
	return self:ScheduleEvent("BigWigs_Message", delay, text, priority, ...)
end

local icons = setmetatable({}, {__index =
	function(self, key)
		if not key then return end
		self[key] = "Interface\\Icons\\" .. key
		return self[key]
	end
})
function BigWigs.modulePrototype:Bar(text, length, icon, ...)
	self:TriggerEvent("BigWigs_StartBar", self, text, length, icons[icon], ...)
end

function BigWigs.modulePrototype:Sync(sync)
	self:TriggerEvent("BigWigs_SendSync", sync)
end

function BigWigs.modulePrototype:Whisper(player, text)
	self:TriggerEvent("BigWigs_SendTell", player, text)
end

function BigWigs.modulePrototype:Icon( player )
	self:TriggerEvent("BigWigs_SetRaidIcon", player )
end
