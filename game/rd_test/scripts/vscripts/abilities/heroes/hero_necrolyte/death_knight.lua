necrolyte_summon_death_knight = class({})

function necrolyte_summon_death_knight:OnSpellStart()
	if not IsServer() then return end
	local count = self:GetSpecialValueFor("skeleton_count")
	local duration = self:GetSpecialValueFor("skeleton_duration")
	local hp = self:GetSpecialValueFor("skeleton_hp")
	local damage = self:GetSpecialValueFor("skeleton_damage")
	local armor = self:GetSpecialValueFor("skeleton_armor")
	local BAT = self:GetSpecialValueFor("skeleton_BAT")

	local caster = self:GetCaster()
	local caster_fw = caster:GetForwardVector()
	local point = caster:GetAbsOrigin() + caster_fw*100 + RandomVector(RandomInt(-50, 50))

	local unit = CreateUnitByName("necrolyte_skeleton_mage_summon", point, true, caster, caster, caster:GetTeamNumber())
	local pfx = ParticleManager:CreateParticle("particles/neutral_fx/skeleton_spawn.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(pfx, 0, point)
	ParticleManager:ReleaseParticleIndex(pfx)
	unit:AddNewModifier(caster, self, "modifier_kill", {duration = duration})
	unit:SetControllableByPlayer(caster:GetPlayerID(), true)
	unit:SetForwardVector(caster_fw)

	unit:SetMaxHealth(hp)
	unit:SetHealth(unit:GetMaxHealth())
	unit:SetBaseDamageMin(damage)
	unit:SetBaseDamageMax(damage)
	unit:SetPhysicalArmorBaseValue(armor)
	unit:SetBaseAttackTime(BAT)
	local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_dark_willow/dark_willow_bramble_precast.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
	ParticleManager:SetParticleControl(pfx, 0, unit:GetAbsOrigin())
	ParticleManager:SetParticleControl(pfx, 3, unit:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(pfx)
end