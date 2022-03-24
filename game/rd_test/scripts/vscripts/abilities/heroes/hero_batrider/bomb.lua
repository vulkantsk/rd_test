batrider_bomb = class({})

function batrider_bomb:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function batrider_bomb:OnSpellStart(target)
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	if not target then
		point = self:GetCursorPosition()
	else
		point = target
	end

	ProjectileManager:CreateLinearProjectile({
		EffectName = "particles/custom/units/heroes/batrider/batrider_flamebreak_linear.vpcf",
		Ability = self,
		vSpawnOrigin = caster:GetAbsOrigin(),
		vVelocity = (point - caster:GetAbsOrigin()):Normalized() * self:GetSpecialValueFor("proj_speed"),
		fDistance = (caster:GetAbsOrigin() - point):Length2D(),
		Source = caster,
		bProvidesVision = false,
		iVisionTeamNumber = caster:GetTeamNumber(),
		iVisionRadius = self:GetSpecialValueFor("vision_radius")
	})
	EmitSoundOn("Hero_Batrider.Flamebreak", caster)
end

function batrider_bomb:OnProjectileHit(hTarget, vLocation)
	if not IsServer() then return end
	if not hTarget then
		local caster = self:GetCaster()
		local radius = self:GetSpecialValueFor("radius")
		local enemies_in_radius = FindUnitsInRadius(caster:GetTeamNumber(), vLocation, nil, radius, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags(), 0, false)
		for _, enemy in pairs(enemies_in_radius) do
			enemy:AddNewModifier(caster, self, "modifier_stunned", {duration = self:GetSpecialValueFor("stun_duration")})
			ApplyDamage({
				victim = enemy,
				attacker = caster,
				ability = self,
				damage = self:GetSpecialValueFor("damage"),
				damage_type = self:GetAbilityDamageType()
			})
		end
		EmitSoundOnLocationWithCaster(vLocation, "Hero_Batrider.Flamebreak.Impact", caster)
		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_batrider/batrider_flamebreak_explosion.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(particle, 0, vLocation);
        ParticleManager:SetParticleControl(particle, 3, vLocation);
        ParticleManager:SetParticleControl(particle, 5, vLocation);
		ParticleManager:ReleaseParticleIndex(particle)
	end
end