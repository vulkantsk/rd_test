LinkLuaModifier("modifier_necrolyte_death_knight_dark_sword", "abilities/heroes/hero_necrolyte/death_knight_dark_sword", LUA_MODIFIER_MOTION_NONE)

necrolyte_death_knight_dark_sword = class({})

function necrolyte_death_knight_dark_sword:GetIntrinsicModifierName()
	return "modifier_necrolyte_death_knight_dark_sword"
end

modifier_necrolyte_death_knight_dark_sword = class({
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_EVENT_ON_DEATH
	} end
})

function modifier_necrolyte_death_knight_dark_sword:OnDeath(data)
	if not IsServer() then return end
	local attacker = data.attacker
	local unit = data.unit
	local caster = self:GetCaster()
	local reduction = (100 - self.stats_reduction_pct) / 100
	
	if caster == attacker and attacker:GetTeam() ~= unit:GetTeam() then
		local unit_fw = unit:GetForwardVector()
		local position = unit:GetAbsOrigin()
		local unit = CreateUnitByName("npc_necrolyte_death_knight_minion", position, true, caster, caster, caster:GetTeamNumber())
		local pfx = ParticleManager:CreateParticle("particles/neutral_fx/skeleton_spawn.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(pfx, 0, position)
		ParticleManager:ReleaseParticleIndex(pfx)
		unit:AddNewModifier(caster, self, "modifier_kill", {duration = duration})
		unit:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)
		unit:SetForwardVector(unit_fw)
		
		unit:SetMaxHealth(hp)
		unit:SetHealth(unit:GetMaxHealth())
		unit:SetBaseDamageMin(damage)
		unit:SetBaseDamageMax(damage)
		unit:SetPhysicalArmorBaseValue(armor)
		unit:SetBaseAttackTime(BAT)
		FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
	end
end
