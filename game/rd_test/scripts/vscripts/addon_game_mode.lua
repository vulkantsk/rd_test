require('timers')

XP_PER_LEVEL_TABLE = {}
XP_PER_LEVEL_TABLE[0] = 0
XP_PER_LEVEL_TABLE[1] = 150

for i = 2, 25 do
    XP_PER_LEVEL_TABLE[i] = XP_PER_LEVEL_TABLE[i - 1] + i * 250
end

for i = 26, 50 do
    XP_PER_LEVEL_TABLE[i] = XP_PER_LEVEL_TABLE[i - 1] + i * 350
end

for i = 51, 74 do
    XP_PER_LEVEL_TABLE[i] = XP_PER_LEVEL_TABLE[i - 1] + i * 500
end

for i = 75, 99 do
    XP_PER_LEVEL_TABLE[i] = XP_PER_LEVEL_TABLE[i - 1] + i * 1000
end

if GameMode == nil then
	GameMode = class({})
end

function Precache( context )
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_magnataur.vsndevts", context )
end

function Activate()
	GameRules.GameMode = GameMode()
	GameRules.GameMode:InitGameMode()
end

function GameMode:InitGameMode()
	GameRules:GetGameModeEntity():SetUseCustomHeroLevels(true)
	GameRules:GetGameModeEntity():SetCustomXPRequiredToReachNextLevel(XP_PER_LEVEL_TABLE)
end

function CDOTA_BaseNPC:GetAverageTrueAttackDamageDisplay()
	local attackDamage = 0
	if(not self or self:IsNull() == true) then
		return attackDamage
	end
	attackDamage = self:GetAttackDamage()
	local greenBonus = 0
	local modifiers = self:FindAllModifiers()
	local finalMultiplier = 1
	local eventData = {
		attacker = self,
		damage = 0,
		damage_type = DAMAGE_TYPE_PHYSICAL,
		damage_category = DOTA_DAMAGE_CATEGORY_ATTACK,
		damage_flags = DOTA_DAMAGE_FLAG_NONE,
		inflictor = nil,
		original_damage = 0,
		ranged_attack = false,
		target = nil,
		no_attack_cooldown = false,
		record = -1,
		fail_type = DOTA_ATTACK_RECORD_FAIL_NO
	}
	for _, modifier in pairs(modifiers) do
		if(modifier.GetModifierPreAttack_BonusDamage) then
			greenBonus = (tonumber(modifier:GetModifierPreAttack_BonusDamage(eventData) or 0) or 0)
		end
		if(modifier.GetModifierBaseDamageOutgoing_Percentage) then
			greenBonus = attackDamage * ((tonumber(modifier:GetModifierBaseDamageOutgoing_Percentage(eventData) or 0) or 0) / 100)
		end
		if(modifier.GetModifierBaseDamageOutgoing_PercentageUnique) then
			greenBonus = attackDamage * ((tonumber(modifier:GetModifierBaseDamageOutgoing_PercentageUnique(eventData) or 0) or 0) / 100)
		end
		if(modifier.GetModifierDamageOutgoing_Percentage) then
			finalMultiplier = finalMultiplier + ((tonumber(modifier:GetModifierDamageOutgoing_Percentage(eventData) or 0) or 0) / 100)
		end
	end
	return (attackDamage + greenBonus) * finalMultiplier
end