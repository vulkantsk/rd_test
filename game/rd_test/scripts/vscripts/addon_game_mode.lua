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
	ListenToGameEvent('entity_killed', Dynamic_Wrap(GameMode, 'OnEntityKilled'), GameMode)
	ListenToGameEvent('npc_spawned', Dynamic_Wrap(GameMode, 'OnNPCSpawned'), GameMode)

	GameRules:GetGameModeEntity():SetUseCustomHeroLevels(true)
	GameRules:GetGameModeEntity():SetCustomXPRequiredToReachNextLevel(XP_PER_LEVEL_TABLE)
end

function GameMode:OnEntityKilled( keys )
--	print( '[BAREBONES] OnEntityKilled Called' )
--	DeepPrintTable( keys )

	-- The Unit that was Killed
	local killedUnit = EntIndexToHScript( keys.entindex_killed )
	-- The Killing entity
	local killerEntity = nil
	local team= killedUnit:GetTeam()
	
	if killedUnit:IsRealHero() and killedUnit:IsReincarnating() == false then
		killedUnit:SetTimeUntilRespawn( 1 )
--		PlayerResource:SetCustomBuybackCost(killedUnit:GetPlayerID(), CUSTOM_BUYBACK_COST)
	end
	
	if keys.entindex_attacker ~= nil then
		killerEntity = EntIndexToHScript( keys.entindex_attacker )
	end

	-- Put code here to handle when an entity gets killed
end

function GameMode:OnNPCSpawned(keys)
--	print("[BAREBONES] NPC Spawned")
--	DeepPrintTable(keys)
	local npc = EntIndexToHScript(keys.entindex)
	local name = npc:GetUnitName()
	
	if npc:IsRealHero() and npc.bFirstSpawned == nil then
--		GameSettings:OnHeroInGame(npc)			
		npc.bFirstSpawned = true
		local playerID = npc:GetPlayerID()
		local steamID = PlayerResource:GetSteamAccountID(playerID)

		if FirstSpawned == nil then
			FirstSpawned = {}
		end
		
		npc:AddItemByName(item_flask_hp_1)
		npc:AddItemByName(item_flask_mp_1)
	end	
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