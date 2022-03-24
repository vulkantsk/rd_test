LinkLuaModifier("modifier_necrolyte_plague_cloud_thinker", "abilities/heroes/hero_necrolyte/plague_cloud", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_necrolyte_plague_cloud_debuff", "abilities/heroes/hero_necrolyte/plague_cloud", LUA_MODIFIER_MOTION_NONE)

necrolyte_plague_cloud = class({
	GetAOERadius = function(self) return self:GetSpecialValueFor("radius") end
})

function necrolyte_plague_cloud:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	CreateModifierThinker(caster, self, "modifier_necrolyte_plague_cloud_thinker", {duration = self:GetSpecialValueFor("duration")}, point, caster:GetTeamNumber(), false)
end

modifier_necrolyte_plague_cloud_thinker = class({
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
	IsAura = function() return true end,
	GetAuraSearchTeam = function(self) return self.target_team end,
	GetAuraSearchType = function(self) return self.target_type end,
	GetAuraSearchFlags = function(self) return self.target_flags end,
	GetAuraRadius = function(self) return self.radius end,
	GetModifierAura = function() return "modifier_necrolyte_plague_cloud_debuff" end
})

function modifier_necrolyte_plague_cloud_thinker:OnCreated()
	if not IsServer() then return end
	self.ability = self:GetAbility()
	self.target_team = self.ability:GetAbilityTargetTeam()
	self.target_type = self.ability:GetAbilityTargetType()
	self.target_flags = self.ability:GetAbilityTargetFlags() or 0
	self.radius = self.ability:GetSpecialValueFor("radius")
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_pudge/pudge_rot.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControl(particle, 1, Vector(self.radius, 0, 0))
    self:AddParticle(particle, false, false, 1, false, false)
end

modifier_necrolyte_plague_cloud_debuff = class({
	IsHidden = function() return false end,
	IsPurgable = function() return true end
})

function modifier_necrolyte_plague_cloud_debuff:OnCreated()
	if not IsServer() then return end
	self.ability = self:GetAbility()
	self.damage_per_sec = self.ability:GetSpecialValueFor("damage_per_sec")
	self.damage_interval = self.ability:GetSpecialValueFor("damage_interval")
	self.damage_type = self.ability:GetAbilityDamageType()
	self:StartIntervalThink(self.damage_interval)
end

function modifier_necrolyte_plague_cloud_debuff:OnIntervalThink()
	if not IsServer() then return end
	ApplyDamage({
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		ability = self.ability,
		damage = self.damage_interval * self.damage_per_sec,
		damage_type = self.damage_type
	})
end