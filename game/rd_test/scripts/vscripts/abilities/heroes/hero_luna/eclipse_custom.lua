LinkLuaModifier( "modifier_luna_eclipse_custom", "abilities/heroes/hero_luna/eclipse_custom", LUA_MODIFIER_MOTION_NONE )

luna_eclipse_custom = {}

function luna_eclipse_custom:GetAOERadius()
	if self:GetCaster():HasScepter() then
		return self:GetSpecialValueFor( "radius" )
	end
	return 0
end

function luna_eclipse_custom:GetBehavior()
	if self:GetCaster():HasScepter() then
		return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_OPTIONAL_POINT + DOTA_ABILITY_BEHAVIOR_AOE
	end

	return DOTA_ABILITY_BEHAVIOR_NO_TARGET
end

function luna_eclipse_custom:GetCastRange( vLocation, hTarget )
	if self:GetCaster():HasScepter() then
		return self:GetSpecialValueFor( "cast_range_tooltip_scepter" )
	end
	return self:GetSpecialValueFor( "radius" )
end

function luna_eclipse_custom:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local point = self:GetCursorPosition()
	local duration = self:GetSpecialValueFor("duration")
	local beam_interval = self:GetSpecialValueFor("beam_interval")
	local radius = self:GetSpecialValueFor("radius")

	local damage = 0
	if self.damage then
		damage = self.damage
	else
		local ability = caster:FindAbilityByName( "luna_lucent_beam_custom" )
		if ability and ability:GetLevel()>0 then
			damage = ability:GetLevelSpecialValueFor( "damage", ability:GetLevel()-1 )
		end
	end

	caster:AddNewModifier(
		caster,
		self,
		"modifier_luna_eclipse_custom",
		{ 
			duration = duration,
			damage = damage }
	)

	GameRules:BeginTemporaryNight( 10 )
end

function luna_eclipse_custom:OnStolen( hSourceAbility )
	self.damage = 0
	local ability = hSourceAbility:GetCaster():FindAbilityByName( "ability_lucent_beam" )
	if ability and ability:GetLevel()>0 then
		self.damage = ability:GetLevelSpecialValueFor( "beam_damage", ability:GetLevel()-1 )
	end
end

modifier_luna_eclipse_custom = {}

function modifier_luna_eclipse_custom:IsHidden()
	return false
end

function modifier_luna_eclipse_custom:IsDebuff()
	return false
end

function modifier_luna_eclipse_custom:IsPurgable()
	return false
end

function modifier_luna_eclipse_custom:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_luna_eclipse_custom:OnCreated( kv )
	print("222")
	self.duration = self:GetAbility():GetSpecialValueFor( "duration" )
	self.beam_interval = self:GetAbility():GetSpecialValueFor( "beam_interval" )
	self.radius = self:GetAbility():GetSpecialValueFor( "radius" )
	
	self.beam_ability = self:GetCaster():FindAbilityByName("luna_lucent_beam_custom")


	self.parent = self:GetParent()
	self.caster = self:GetCaster()

	if IsServer() then
		if kv.point==1 then
			self.point = Vector( kv.pointx, kv.pointy, kv.pointz )

			AddFOWViewer( self:GetCaster():GetTeamNumber(), self.point, self.radius + 75, self.duration, true)
		end
		self.counter = 0
		self.hits = {}


		self.damageTable = {
			attacker = self.caster,
			damage = kv.damage,
			damage_type = self:GetAbility():GetAbilityDamageType(),
			ability = self:GetAbility()
		}

		self:StartIntervalThink( self.beam_interval )
		self:OnIntervalThink()

		local effect_cast = nil
		if self.point then
			effect_cast = ParticleManager:CreateParticle(
				"particles/units/heroes/hero_luna/luna_eclipse.vpcf",
				PATTACH_WORLDORIGIN,
				nil
			)
			ParticleManager:SetParticleControl( effect_cast, 0, self.point )

			EmitSoundOnLocationWithCaster( self.point, "Hero_Luna.Eclipse.Cast", self:GetParent() )
		else
			effect_cast = ParticleManager:CreateParticle(
				"particles/units/heroes/hero_luna/luna_eclipse.vpcf",
				PATTACH_ABSORIGIN_FOLLOW,
				self:GetParent()
			)

			EmitSoundOn( "Hero_Luna.Eclipse.Cast", self:GetParent() )
		end

		ParticleManager:SetParticleControl( effect_cast, 1, Vector( self.radius, 0, 0 ) )

		self:AddParticle(
			effect_cast,
			false,
			false,
			-1,
			false,
			false
		)
	end
end

function modifier_luna_eclipse_custom:OnIntervalThink()
	local point = self.point or self.parent:GetOrigin()
	local units = FindUnitsInRadius(
		self.caster:GetTeamNumber(),
		point,
		nil,
		self.radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS,
		0,
		false
	)

	local unit = nil
	if #units>0 then
		unit = units[RandomInt(1, #units)]
		self.damageTable.victim = unit
		ApplyDamage(self.damageTable)
		self.beam_ability:BeamStackProc()
	end

	if not unit then
		local vector = point + RandomVector( RandomInt( 0, self.radius ) )
		local effect_cast = ParticleManager:CreateParticle(
			"particles/units/heroes/hero_luna/luna_lucent_beam.vpcf",
			PATTACH_WORLDORIGIN,
			nil
		)
		ParticleManager:SetParticleControl( effect_cast, 0, vector )
		ParticleManager:SetParticleControl( effect_cast, 1, vector )
		ParticleManager:SetParticleControl( effect_cast, 5, vector )
		ParticleManager:SetParticleControl( effect_cast, 6, vector )
		ParticleManager:ReleaseParticleIndex( effect_cast )

		EmitSoundOnLocationWithCaster( vector, "Hero_Luna.Eclipse.NoTarget", self.caster )

		return
	end

	local effect_cast = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_luna/luna_lucent_beam.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		unit
	)
	ParticleManager:SetParticleControl( effect_cast, 0, unit:GetOrigin() )
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		1,
		unit,
		PATTACH_ABSORIGIN_FOLLOW,
		"attach_hitloc",
		Vector(),
		true
	)
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		5,
		unit,
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector(),
		true
	)
	ParticleManager:SetParticleControlEnt(
		effect_cast,
		6,
		unit,
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		Vector(),
		true
	)
	ParticleManager:ReleaseParticleIndex( effect_cast )

	EmitSoundOn( "Hero_Luna.Eclipse.Target", unit )
end