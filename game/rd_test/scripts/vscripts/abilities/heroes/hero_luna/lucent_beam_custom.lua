LinkLuaModifier("modifier_luna_lucent_beam_custom_buff", "abilities/heroes/hero_luna/lucent_beam_custom", LUA_MODIFIER_MOTION_NONE)

luna_lucent_beam_custom = class({})

function luna_lucent_beam_custom:OnAbilityPhaseStart()
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_luna/luna_lucent_beam_precast.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
	ParticleManager:SetParticleControl(particle, 1, Vector(0.4,0,0))
	ParticleManager:SetParticleControlEnt(particle, 0, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_attack1", Vector(), true)
	ParticleManager:ReleaseParticleIndex( particle )

	return true
end

function luna_lucent_beam_custom:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_luna/luna_lucent_beam.vpcf", PATTACH_CUSTOMORIGIN, target)
	ParticleManager:SetParticleControl(particle, 0, target:GetOrigin())
	ParticleManager:SetParticleControlEnt(particle, 1, target, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", Vector(), true)
	ParticleManager:SetParticleControlEnt(particle, 5, target, PATTACH_POINT_FOLLOW, "attach_hitloc", Vector(), true)
	ParticleManager:SetParticleControlEnt(particle, 6, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_attack1", Vector(), true)
	ParticleManager:ReleaseParticleIndex(particle)
	target:AddNewModifier(caster, self, "modifier_stunned", {duration = self:GetSpecialValueFor("stun_duration")})
	ApplyDamage({
		victim = target,
		attacker = caster,
		damage = self:GetSpecialValueFor("damage"),
		damage_type = self:GetAbilityDamageType(),
		ability = self
	})
	caster:AddNewModifier(caster, self, "modifier_luna_lucent_beam_custom_buff", {duration = self:GetSpecialValueFor("buff_duration")})
	EmitSoundOn("Hero_Luna.LucentBeam.Cast", self:GetCaster())
	EmitSoundOn("Hero_Luna.LucentBeam.Target", target)
end

modifier_luna_lucent_beam_custom_buff = class({
	IsHidden = function() return false end,
	IsPurgable = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS_PERCENTAGE
	} end,
	GetModifierBonusStats_Agility = function(self) return self.agility_bonus end,
	GetModifierBonusStats_Agility_Percentage = function(self) return self.agility_bonus_pct end,
	GetAttributes = function() return MODIFIER_ATTRIBUTE_MULTIPLE end
})

function modifier_luna_lucent_beam_custom_buff:OnCreated()
	self.ability = self:GetAbility()
	self.agility_bonus = self.ability:GetSpecialValueFor("agility_bonus")
	self.agility_bonus_pct = self.ability:GetSpecialValueFor("agility_bonus_pct")
end

function modifier_luna_lucent_beam_custom_buff:OnRefresh()
	self:OnCreated()
end