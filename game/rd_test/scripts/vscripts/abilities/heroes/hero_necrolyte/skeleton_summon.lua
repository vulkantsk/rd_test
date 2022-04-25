necrolyte_skeleton_summon = class({})

function necrolyte_skeleton_summon:OnSpellStart()
	if not IsServer() then return end
	local count = self:GetSpecialValueFor("skeleton_count")
	local duration = self:GetSpecialValueFor("skeleton_duration")
	local hp = self:GetSpecialValueFor("skeleton_hp")
	local damage = self:GetSpecialValueFor("skeleton_damage")
	local armor = self:GetSpecialValueFor("skeleton_armor")
	local BAT = self:GetSpecialValueFor("skeleton_BAT")

	local caster = self:GetCaster()
	local caster_fw = caster:GetForwardVector()
	local point = caster:GetAbsOrigin()

	for i = 1, count do
		local position = point + caster_fw*100 + RandomVector(RandomInt(-50, 50))
		local unit = CreateUnitByName("necrolyte_skeleton_summon", position, true, caster, caster, caster:GetTeamNumber())
		local pfx = ParticleManager:CreateParticle("particles/neutral_fx/skeleton_spawn.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(pfx, 0, position)
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
		FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
	end
end