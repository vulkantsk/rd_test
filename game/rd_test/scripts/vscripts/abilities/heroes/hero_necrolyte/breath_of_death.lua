LinkLuaModifier("modifier_necrolyte_breath_of_death", "abilities/heroes/hero_necrolyte/breath_of_death", LUA_MODIFIER_MOTION_NONE)

necrolyte_breath_of_death = class({
	GetAOERadius = function(self) return self:GetSpecialValueFor("radius") end
})

function necrolyte_breath_of_death:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	local enemies_in_radius = FindUnitsInRadius(caster:GetTeamNumber(), point, nil, self:GetSpecialValueFor("radius"), self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags(), 0, false)

	for _, enemy in pairs(enemies_in_radius) do
		enemy:AddNewModifier(caster, self, "modifier_necrolyte_breath_of_death", {duration = self:GetSpecialValueFor("duration")})
		local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_dark_willow/dark_willow_bramble_wraith_endcap.vpcf", PATTACH_ABSORIGIN_FOLLOW, enemy)
		ParticleManager:SetParticleControl(pfx, 0, enemy:GetAbsOrigin())
		ParticleManager:SetParticleControl(pfx, 3, enemy:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(pfx)
	end
end

modifier_necrolyte_breath_of_death = class({
	IsHidden = function() return false end,
	IsPurgable = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_EVENT_ON_DEATH
	} end
})

function modifier_necrolyte_breath_of_death:OnCreated()
	if not IsServer() then return end
	self.ability = self:GetAbility()
	self.damage_per_sec = self.ability:GetSpecialValueFor("damage_per_sec")
	self.damage_interval = self.ability:GetSpecialValueFor("damage_interval")
	self.live_duration = self.ability:GetSpecialValueFor("live_duration")
	self.stats_reduction_pct = self.ability:GetSpecialValueFor("stats_reduction_pct")
	self.damage_type = self.ability:GetAbilityDamageType()
	self:StartIntervalThink(self.damage_interval)
end

function modifier_necrolyte_breath_of_death:OnIntervalThink()
	if not IsServer() then return end
	ApplyDamage({
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		ability = self.ability,
		damage = self.damage_per_sec * self.damage_interval,
		damage_type = self.damage_type
	})
end

function modifier_necrolyte_breath_of_death:OnDeath(data)
	if not IsServer() then return end
	local unit = data.unit
	local caster = self:GetCaster()
	local reduction = (100 - self.stats_reduction_pct) / 100
	if unit == self:GetParent() then
		local unit = CreateUnitByName(unit:GetUnitName(), unit:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber())
		unit:AddNewModifier(caster, self.ability, "modifier_kill", {duration = self.live_duration})
		unit:SetControllableByPlayer(caster:GetPlayerID(), true)
		unit:SetMaxHealth(unit:GetMaxHealth() * reduction)
		unit:SetHealth(unit:GetMaxHealth())
		unit:SetBaseDamageMin(unit:GetBaseDamageMin() * reduction)
		unit:SetBaseDamageMax(unit:GetBaseDamageMax() * reduction)
		unit:SetPhysicalArmorBaseValue(unit:GetPhysicalArmorBaseValue() * reduction)
		unit:SetBaseAttackTime(unit:GetBaseAttackTime() * reduction)
		unit:SetRenderColor(10, 10, 10)
		FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
		local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_dark_willow/dark_willow_bramble_wraith_endcap.vpcf", PATTACH_ABSORIGIN_FOLLOW, unit)
		ParticleManager:SetParticleControl(pfx, 0, unit:GetAbsOrigin())
		ParticleManager:SetParticleControl(pfx, 3, unit:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(pfx)
	end
end