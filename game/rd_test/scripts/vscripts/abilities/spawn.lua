
power_mult = 1
power_mult1 = 1

function Respoint (keys )
	Timers:CreateTimer(0.01,function()
		local caster = keys.caster 	--пробиваем IP усопшего
	
		caster.respoint = caster:GetAbsOrigin() -- определяем точку спавна
		caster.fw = caster:GetForwardVector()
		caster:SetIsNeutralCreep(true)
	end)
end

function Upgrader(keys)
	local caster= keys.caster
	-- 7.31 cause crash if something is null
	if(not caster or caster:IsNull() == true) then
		return
	end
	-- wisp case, ability cause problems if removed from wisp (default dota ui completely broken). Thanks Valve
	if(caster:GetTeamNumber() == DOTA_TEAM_GOODGUYS) then
		return
	end
	local position = caster.respoint
	local name = caster:GetUnitName()
	local team = caster:GetTeam()
	local unit
	local respawn_time = GameRules.neutral_respawn
	local gold

	Timers:CreateTimer(respawn_time,function()
		unit = CreateUnitByName(name, position + RandomVector( RandomFloat( 0, 50)), true, nil, nil, team)
		gold = unit:GetMinimumGoldBounty()*power_mult
		if gold >= 25000 then
			gold = 25000
		end
		unit:SetMaximumGoldBounty(gold)
		unit:SetMinimumGoldBounty(gold)

		unit:SetForwardVector(caster.fw)
		unit:SetBaseDamageMin(unit:GetBaseDamageMin()*power_mult)
		unit:SetBaseDamageMax(unit:GetBaseDamageMax()*power_mult)
		unit:SetPhysicalArmorBaseValue(unit:GetPhysicalArmorBaseValue()*power_mult1)
		local maxhp = unit:GetMaxHealth()*power_mult
		unit:SetBaseMaxHealth(maxhp)
		unit:SetMaxHealth(maxhp)
		unit:SetHealth(maxhp)
		unit:SetIsNeutralCreep(true)
	end)

	power_mult = power_mult * 2
	power_mult1 = power_mult1 + 1
end


function respawn_strong(keys)
	local caster= keys.caster
	-- 7.31 cause crash if something is null
	if(not caster or caster:IsNull() == true) then
		return
	end
	-- wisp case, ability cause problems if removed from wisp (default dota ui completely broken). Thanks Valve
	if(caster:GetTeamNumber() == DOTA_TEAM_GOODGUYS) then
		return
	end
	local position = caster.respoint
	local name = caster:GetUnitName()
	local team = caster:GetTeam()
	local respawn_time = GameRules.neutral_respawn

	Timers:CreateTimer(respawn_time,function()
		local unit = CreateUnitByName(name, position + RandomVector( RandomFloat( 0, 50)), true, nil, nil, team)
		
		unit:SetForwardVector(caster.fw)
		
		unit:SetIsNeutralCreep(true)
	end)
end

function Respawn (keys )
	local caster= keys.caster
	-- 7.31 cause crash if something is null
	if(not caster or caster:IsNull() == true) then
		return
	end
	-- wisp case, ability cause problems if removed from wisp (default dota ui completely broken). Thanks Valve
	if(caster:GetTeamNumber() == DOTA_TEAM_GOODGUYS) then
		return
	end
	local caster_position = caster:GetAbsOrigin()
	local name = caster:GetUnitName()
	local team = caster:GetTeam()
	local respawn_time = keys.ability:GetSpecialValueFor("respawn_time")

	Timers:CreateTimer(respawn_time,function()
		local unit = CreateUnitByName(name, caster_position + RandomVector( RandomFloat( 0, 50)), true, nil, nil, team)
		unit:SetIsNeutralCreep(true)
	end)
end

local DATA = {}

DATA["npc_boss_forest_1"] = "npc_boss_forest_2"
DATA["npc_boss_forest_2"] = "npc_boss_forest_3"

DATA["npc_boss_spider_1"] = "npc_boss_spider_2"
DATA["npc_boss_spider_2"] = "npc_boss_spider_3"

DATA["npc_boss_ice_1"] = "npc_boss_ice_2"
DATA["npc_boss_ice_2"] = "npc_boss_ice_3"

DATA["npc_boss_water_1"] = "npc_boss_water_2"
DATA["npc_boss_water_2"] = "npc_boss_water_3"

DATA["npc_boss_alliance_1"] = "npc_boss_alliance_2"
DATA["npc_boss_alliance_2"] = "npc_boss_alliance_3"

DATA["npc_boss_fire_1"] = "npc_boss_fire_2"
DATA["npc_boss_fire_2"] = "npc_boss_fire_3"

DATA["npc_dota_boss_astral_1"] = "npc_dota_boss_astral_2"


function Boss_Respawn (keys )
	local caster = keys.caster
	-- 7.31 cause crash if something is null
	if(not caster or caster:IsNull() == true) then
		return
	end
	-- wisp case, ability cause problems if removed from wisp (default dota ui completely broken). Thanks Valve
	if(caster:GetTeamNumber() == DOTA_TEAM_GOODGUYS) then
		return
	end
	local position = caster.respoint or caster:GetAbsOrigin()
	local name = caster:GetUnitName()
	local team = caster:GetTeam()
	local respawn_time = GameRules.boss_respawn or 300
	local vector = caster:GetForwardVector()

	local unit_desired_name = DATA[name] or name


	Timers:CreateTimer(respawn_time, function()
		local unit = CreateUnitByName(unit_desired_name, position + RandomVector( RandomFloat( 0, 50)), true, nil, nil, team)
		unit:SetForwardVector(vector)
		unit:SetIsNeutralCreep(true)
	end)
end