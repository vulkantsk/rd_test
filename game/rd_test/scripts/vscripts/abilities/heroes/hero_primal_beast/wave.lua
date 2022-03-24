primal_beast_wave = class({
	GetCastAnimation = function() return ACT_DOTA_CAST_ABILITY_4 end,
	GetPlaybackRateOverride = function() return 2 end
})

function primal_beast_wave:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	ProjectileManager:CreateLinearProjectile({
		EffectName = "particles/units/heroes/hero_magnataur/magnataur_shockwave.vpcf",
		Ability = self,
		vSpawnOrigin = caster:GetAbsOrigin(),
		fStartRadius = self:GetSpecialValueFor("wave_start_width"),
		fEndRadius = self:GetSpecialValueFor("wave_end_width"),
		vVelocity = (point - caster:GetAbsOrigin()):Normalized() * self:GetSpecialValueFor("wave_speed"),
		fDistance = self:GetSpecialValueFor("wave_distance"),
		Source = caster,
		iUnitTargetTeam = self:GetAbilityTargetTeam(),
		iUnitTargetType = self:GetAbilityTargetType(),
		iUnitTargetFlags = self:GetAbilityTargetFlags(),
		bProvidesVision = true,
		iVisionTeamNumber = caster:GetTeamNumber(),
		iVisionRadius = self:GetSpecialValueFor("vision_radius")
	})
	EmitSoundOn("Hero_Magnataur.ShockWave.Cast", caster)
end

function primal_beast_wave:OnProjectileHit(target, location)
	if not IsServer() then return end
	if target then
		target:AddNewModifier(self:GetCaster(), self, "modifier_stunned", {duration = self:GetSpecialValueFor("stun_duration")})
		ApplyDamage({
			victim = target,
			attacker = self:GetCaster(),
			ability = self,
			damage = self:GetSpecialValueFor("damage"),
			damage_type = self:GetAbilityDamageType()
		})
	end
end