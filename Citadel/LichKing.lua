--------------------------------------------------------------------------------
-- Module Declaration
--

local mod = BigWigs:NewBoss("The Lich King", "Icecrown Citadel")
if not mod then return end
mod:RegisterEnableMob(36597)
mod.toggleOptions = {70541, 69409, {72743, "SAY", "ICON", "WHISPER", "FLASHSHAKE"}, {73912, "ICON", "WHISPER", "FLASHSHAKE"}, 69037, 68980, {74270, "FLASHSHAKE"}, {72262, "FLASHSHAKE"}, "proximity", "bosskill"}

--------------------------------------------------------------------------------
-- Locals
--

local phase = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:NewLocale("enUS", true)
if L then
	L.warmup_trigger = "So the Light's vaunted justice has finally arrived"
	L.engage_trigger = "So be it. Champions. attack!"
	L.engage_bar = "Incoming!"

	L.necroticplague_message = "Necrotic Plague"
	L.necroticplague_bar = "Necrotic Plague"

	L.valkyr_bar = "Next Val'kyr"
	L.valkyr_message = "Val'kyr"
	L.vilespirits_bar = "Vile Spirits"

	L.harvestsoul_message = "Harvest Soul"

	L.remorselesswinter_message = "Remorseless Winter Casting"
	L.quake_message = "Quake Casting"

	L.defile_say = "Defile on ME!"
	L.defile_message = "Defile on YOU!"
	L.defile_bar = "Next Defile"

	L.infest_bar = "~Next Infest"

	L.reaper_message = "Soul Reaper"
	L.reaper_bar = "~Next Reaper"
end
L = mod:GetLocale()

--------------------------------------------------------------------------------
-- Initialization
--


function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Infest", 70541, 73779, 73780, 73781)
	self:Log("SPELL_CAST_START", "DefileCast", 72762)
	self:Log("SPELL_CAST_SUCCESS", "NecroticPlague", 70337, 73912)
	self:Log("SPELL_CAST_SUCCESS", "Reaper", 69409, 73797, 73798, 73799)
	self:Log("SPELL_SUMMON", "Valkyr", 69037)
	self:Log("SPELL_CAST_SUCCESS", "HarvestSoul", 68980)
	self:Log("SPELL_CAST_START", "RemorselessWinter", 68981, 74270)
	self:Log("SPELL_CAST_START", "Quake", 72262)
	self:Log("SPELL_DAMAGE", "DefileRun", 72754, 73708, 73709, 73710)
	self:Log("SPELL_DISPEL", "NPRemove", 70337, 73912)

	self:Death("Win", 36597)

	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:Yell("Warmup", L["warmup_trigger"])
	self:Yell("Engage", L["engage_trigger"])
end

function mod:Warmup()
	self:Bar(69037, self.displayName, 47, "achievement_boss_lichking")
end

function mod:OnEngage()
	print("Note that none of the timers in this bossfight have been verified by the Big Wigs team, so things might be a little off at this point. Nevertheless enjoy the fight!")
	self:OpenProximity(10)
	self:Bar(72743, L["necroticplague_bar"], 36, 73912)
	self:Bar(69037, L["engage_bar"], 4, 69037)
	phase = 1
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Infest(_, spellId, _, _, spellName)
	self:Message(70541, spellName, "Urgent", spellId)
	self:Bar(70541, L["infest_bar"], 22, spellId)
end

function mod:Reaper(player, spellId)
	self:TargetMessage(69409, L["reaper_message"], player, "Personal", spellId, "Alert")
	self:Bar(69409, L["reaper_bar"], 30, spellId)
end

function mod:NecroticPlague(player, spellId)
	self:TargetMessage(73912, L["necroticplague_message"], player, "Personal", spellId, "Alert")
	if UnitIsUnit(player, "player") then self:FlashShake(73912) end
	self:Whisper(73912, player, L["necroticplague_message"])
	self:Bar(73912, L["necroticplague_bar"], 30, spellId)
	self:SecondaryIcon(73912, player)
end

function mod:NPRemove(player, spellId)
	self:SecondaryIcon(73912, false)
end

local last = 0
function mod:DefileRun(player, spellId)
	local time = GetTime()
	if (time - last) > 2 then
		last = time
		if UnitIsUnit(player, "player") then
			self:LocalMessage(72743, L["defile_message"], "Personal", spellId, "Info")
			self:FlashShake(72743)
		end
	end
end

function mod:Valkyr(_, spellId)
	self:Message(69037, L["valkyr_message"], "Attention", 71844)
	self:Bar(69037, L["valkyr_bar"], 48, 71844)
end

function mod:HarvestSoul(player, spellId)
	self:Bar(68980, L["harvestsoul_message"], 75, spellId)
	self:TargetMessage(68980, L["harvestsoul_message"], player, "Attention", spellId)
end

function mod:RemorselessWinter(_, spellId)
	phase = phase + 1
	self:SendMessage("BigWigs_StopBar", self, L["necroticplague_bar"])
	self:SendMessage("BigWigs_StopBar", self, L["infest_bar"])
	self:LocalMessage(74270, L["remorselesswinter_message"], "Urgent", spellId, "Alert")
	self:Bar(72262, L["quake_message"], 60, 72262)
end

function mod:Quake(_, spellId)
	phase = phase + 1
	self:LocalMessage(72262, L["quake_message"], "Urgent", spellId, "Alert")
	self:Bar(72743, L["defile_bar"], 30, 72743)
	self:Bar(70541, L["infest_bar"], 13, 70541)
	if phase == 2 then
		self:Bar(69037, L["valkyr_bar"], 20, 69037)
	elseif phase == 4 then
		self:Bar(70498, L["vilespirits_bar"], 20, 70498)
	end
end

do
	local id, name, handle = nil, nil, nil
	local function scanTarget()
		local bossId = mod:GetUnitIdByGUID(36597)
		if not bossId then return end
		local target = UnitName(bossId .. "target")
		if target then
			if UnitIsUnit(target, "player") then
				mod:FlashShake(72743)
				if bit.band(mod.db.profile[(GetSpellInfo(72743))], BigWigs.C.SAY) == BigWigs.C.SAY then
					SendChatMessage(L["defile_say"], "SAY")
				end
			end
			mod:TargetMessage(72743, name, target, "Attention", id, "Alert")
			mod:Whisper(72743, target, name)
			mod:PrimaryIcon(72743, target)
		end
		handle = nil
	end

	function mod:DefileCast(player, spellId, _, _, spellName)
		id, name = spellId, spellName
		self:CancelTimer(handle, true)
		self:Bar(72743, L["defile_bar"], 30, 72743)
		handle = self:ScheduleTimer(scanTarget, 0.1)
	end
end

