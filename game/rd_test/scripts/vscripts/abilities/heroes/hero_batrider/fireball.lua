LinkLuaModifier("modifier_batrider_fireball_thinker", "abilities/heroes/hero_batrider/fireball", LUA_MODIFIER_MOTION_NONE)

batrider_fireball = class({})

function batrider_fireball:OnSpellStart()
	local caster = self:GetCaster()

	self.start_pos = caster:GetAbsOrigin()
	self.end_pos = caster:GetAbsOrigin()
	self.final_end_pos = self:GetCursorPosition()
	local point = self:GetCursorPosition()
	print((self.start_pos - point):Length2D())
	ProjectileManager:CreateLinearProjectile({
		EffectName = "",
		Ability = self,
		vSpawnOrigin = caster:GetAbsOrigin(),
		fStartRadius = self:GetSpecialValueFor("proj_width"),
		fEndRadius = self:GetSpecialValueFor("proj_width"),
		vVelocity = (self.final_end_pos - caster:GetAbsOrigin()):Normalized() * self:GetSpecialValueFor("proj_speed"),
		fDistance = (self.start_pos - point):Length2D(),--self:GetSpecialValueFor("proj_length"),
		Source = caster,
		bProvidesVision = true,
		iVisionTeamNumber = caster:GetTeamNumber(),
		iVisionRadius = self:GetSpecialValueFor("vision_radius")
	})
	CreateModifierThinker(caster, self, "modifier_batrider_fireball_thinker", {duration = self:GetSpecialValueFor("fire_duration")}, self.start_pos, caster:GetTeamNumber(), false)
	self.particles = {}
	self.pfx = ParticleManager:CreateParticle("particles/custom/units/heroes/batrider/batrider_fireball_trail.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(self.pfx, 0, self.start_pos)
	ParticleManager:SetParticleControl(self.pfx, 1, self.start_pos)
	ParticleManager:SetParticleControl(self.pfx, 2, Vector(self:GetSpecialValueFor("fire_width"), 0, 0))
	table.insert(self.particles, self.pfx)
end

function batrider_fireball:OnProjectileThink(vLocation)
	if not IsServer() then return end
	local distance = (self.end_pos - vLocation):Length2D()
	if distance  > self:GetSpecialValueFor("fire_width") * self:GetSpecialValueFor("particle_distance_multiplier") then
		self.end_pos = vLocation
		self.pfx_2 = ParticleManager:CreateParticle("particles/custom/units/heroes/batrider/batrider_fireball_trail.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(self.pfx_2, 0, vLocation)
		ParticleManager:SetParticleControl(self.pfx_2, 1, vLocation)
		ParticleManager:SetParticleControl(self.pfx_2, 2, Vector(self:GetSpecialValueFor("fire_width"), 0, 0))
		table.insert(self.particles, self.pfx_2)
	end
end

function batrider_fireball:OnProjectileHit_ExtraData(target, location)
	if not IsServer() then return end
	local caster = self:GetCaster()
	if target then
		ApplyDamage({
			victim = target,
			attacker = caster,
			ability = self,
			damage = self:GetSpecialValueFor("proj_damage"),
			damage_type = self:GetAbilityDamageType()
		})
	else
		self.end_pos = self.final_end_pos
		--CreateModifierThinker(caster, self, "modifier_batrider_fireball_thinker", {duration = self:GetSpecialValueFor("fire_duration")}, location, caster:GetTeamNumber(), false)
	end
end

modifier_batrider_fireball_thinker = class({
	IsHidden = function() return true end,
	IsPurgable = function() return false end
})

function modifier_batrider_fireball_thinker:OnCreated()
	if not IsServer() then return end
	self.ability = self:GetAbility()
	self.fire_width = self.ability:GetSpecialValueFor("fire_width")
	self.damage_interval = self.ability:GetSpecialValueFor("damage_interval")
	self.damage_per_sec = self.ability:GetSpecialValueFor("damage_per_sec")
	self.start_pos = self.ability.start_pos
	--self.end_pos = self.ability.end_pos
	self.target_team = self.ability:GetAbilityTargetTeam()
	self.target_type = self.ability:GetAbilityTargetType()
	self.target_flags = self.ability:GetAbilityTargetFlags() or 0
	self.damage_type = self.ability:GetAbilityDamageType()
	self:StartIntervalThink(self.damage_interval)
end

function modifier_batrider_fireball_thinker:OnDestroy()
	if not IsServer() then return end
	print("fire stop")
	for _, particle in pairs (self.ability.particles) do
		ParticleManager:DestroyParticle(particle, false)
	end
end

function modifier_batrider_fireball_thinker:OnIntervalThink()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local enemies_in_path = FindUnitsInLine(caster:GetTeamNumber(), self.start_pos, self.ability.end_pos, nil, self.fire_width, self.target_team, self.target_type, self.target_flags)
	for _, enemy in pairs(enemies_in_path) do
		ApplyDamage({
			victim = enemy,
			attacker = caster,
			ability = self.ability,
			damage = self.damage_per_sec * self.damage_interval,
			damage_type = self.damage_type
		})
	end
end