LinkLuaModifier("modifier_batrider_sticky_masut", "abilities/heroes/hero_batrider/sticky_masut", LUA_MODIFIER_MOTION_NONE)


batrider_sticky_masut = class({})

function batrider_sticky_masut:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function batrider_sticky_masut:OnSpellStart(target)
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	if not target then
		point = self:GetCursorPosition()
	else
		point = target
	end

	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local enemies_in_radius = FindUnitsInRadius(caster:GetTeamNumber(), point, nil, radius, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags(), 0, false)
	for _, enemy in pairs(enemies_in_radius) do
		enemy:AddNewModifier(caster, self, "modifier_batrider_sticky_masut", {duration = self:GetSpecialValueFor("debuff_duration")})
	end
	
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_batrider/batrider_stickynapalm_impact.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, vLocation);
    ParticleManager:SetParticleControl(particle, 1, Vector(radius,radius,radius));
 	ParticleManager:ReleaseParticleIndex(particle)

	AddFOWViewer(caster:GetTeam(), point, radius, reveal_duration, true)
	EmitSoundOn("Hero_Batrider.Flamebreak", caster)
end

modifier_batrider_sticky_masut = class({
	IsHidden = function(self) return self:GetStackCount() < 1 end,
	IsPurgable = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	} end,
})

function modifier_batrider_sticky_masut:OnCreated()
	self.ability = self:GetAbility()
	self.decrease_resist = self.ability:GetSpecialValueFor("decrease_resist")
	self.decrease_ms = self.ability:GetSpecialValueFor("decrease_ms")
end

function modifier_batrider_sticky_masut:OnRefresh()
	self:OnCreated()
end

function modifier_batrider_sticky_masut:GetEffectName()
	return "particles/units/heroes/hero_batrider/batrider_stickynapalm_debuff.vpcf"
end

function modifier_batrider_sticky_masut:GetModifierMagicalResistanceBonus()
	return self.decrease_resist*(-1)
end

function modifier_batrider_sticky_masut:GetModifierMoveSpeedBonus_Percentage()
	return self.decrease_ms*(-1)
end

