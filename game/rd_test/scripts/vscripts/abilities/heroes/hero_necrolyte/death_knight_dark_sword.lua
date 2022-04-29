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

function modifier_necrolyte_death_knight_dark_sword:OnCreated()
	self.ability = self:GetAbility()
	self.skeleton_duration = self.ability:GetSpecialValueFor("skeleton_duration")
	self.skeleton_hp = self.ability:GetSpecialValueFor("skeleton_hp")
	self.skeleton_damage = self.ability:GetSpecialValueFor("skeleton_damage")
	self.skeleton_armor = self.ability:GetSpecialValueFor("skeleton_armor")
	self.skeleton_BAT = self.ability:GetSpecialValueFor("skeleton_BAT")
end

function modifier_necrolyte_death_knight_dark_sword:OnDeath(data)
	if not IsServer() then return end
	local attacker = data.attacker
	local unit = data.unit
	local caster = self:GetCaster()
	
	if caster == attacker and attacker:GetTeam() ~= unit:GetTeam() then
		local position = unit:GetAbsOrigin()
		local unit_fw = unit:GetForwardVector()
		local position = unit:GetAbsOrigin()
		local unit = CreateUnitByName("npc_necrolyte_death_knight_minion", position, true, caster, caster, caster:GetTeamNumber())
		local pfx = ParticleManager:CreateParticle("particles/neutral_fx/skeleton_spawn.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(pfx, 0, position)
		ParticleManager:ReleaseParticleIndex(pfx)
		unit:AddNewModifier(caster, self, "modifier_kill", {duration = self.skeleton_duration})
		unit:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)
		unit:SetForwardVector(unit_fw)
		
		unit:SetMaxHealth(self.skeleton_hp)
		unit:SetHealth(unit:GetMaxHealth())
		unit:SetBaseDamageMin(self.skeleton_damage)
		unit:SetBaseDamageMax(self.skeleton_damage)
		unit:SetPhysicalArmorBaseValue(self.skeleton_armor)
		unit:SetBaseAttackTime(self.skeleton_BAT)
		FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
	end
end
