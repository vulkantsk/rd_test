LinkLuaModifier( "modifier_batrider_combusition", "abilities/heroes/hero_batrider/combusition", LUA_MODIFIER_MOTION_NONE )

batrider_combusition = {}

function batrider_combusition:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	local projectile_name = "particles/units/heroes/hero_ogre_magi/ogre_magi_ignite.vpcf"
	local projectile_speed = self:GetSpecialValueFor( "projectile_speed" )

	local info = {
		Target = target,
		Source = caster,
		Ability = self,	
		EffectName = projectile_name,
		iMoveSpeed = projectile_speed,
		bDodgeable = true,
	}
	ProjectileManager:CreateTrackingProjectile(info)

	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		caster:GetOrigin(),
		nil,
		self:GetCastRange( target:GetOrigin(), target ),
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
		0,
		false
	)

	local target_2 = nil
	for _,enemy in pairs(enemies) do
		if enemy~=target and ( not enemy:HasModifier("modifier_batrider_combusition") ) then
			target_2 = enemy
			break
		end
	end

	if target_2 then
		info.Target = target_2
		ProjectileManager:CreateTrackingProjectile(info)
	end

	EmitSoundOn( "Hero_OgreMagi.Ignite.Cast", caster )
end

function batrider_combusition:OnProjectileHit( target, location )
	if not target then return end
	if target:TriggerSpellAbsorb( self ) then return end

	target:AddNewModifier(
		self:GetCaster(),
		self,
		"modifier_batrider_combusition",
		{ duration = self:GetSpecialValueFor( "duration" ) }
	)

	EmitSoundOn( "Hero_OgreMagi.Ignite.Target", self:GetCaster() )
end

modifier_batrider_combusition = {}

function modifier_batrider_combusition:IsHidden()
	return false
end

function modifier_batrider_combusition:IsDebuff()
	return true
end

function modifier_batrider_combusition:IsStunDebuff()
	return false
end

function modifier_batrider_combusition:IsPurgable()
	return true
end

function modifier_batrider_combusition:OnCreated( kv )
	self.slow = self:GetAbility():GetSpecialValueFor( "slow_movement_speed_pct" )
	local damage = self:GetAbility():GetSpecialValueFor( "burn_damage" )

	if not IsServer() then return end

	local interval = 1

	self.damageTable = {
		victim = self:GetParent(),
		attacker = self:GetCaster(),
		damage = damage,
		damage_type = self:GetAbility():GetAbilityDamageType(),
		ability = self, --Optional.
	}

	self:StartIntervalThink( interval )
end

function modifier_batrider_combusition:OnRefresh( kv )
	self.decrease_regen = self:GetAbility():GetSpecialValueFor( "decrease_regen" )
	local damage = self:GetAbility():GetSpecialValueFor( "burn_damage" )
	
	if not IsServer() then return end

	self.damageTable.damage = damage
end

function modifier_batrider_combusition:OnRemoved()
end

function modifier_batrider_combusition:OnDestroy()
end

function modifier_batrider_combusition:DeclareFunctions()
	return { 
		MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
	 }
end

function modifier_batrider_combusition:GetModifierHPRegenAmplify_Percentage()
	return self.decrease_regen*(-1)
end

function modifier_batrider_combusition:OnIntervalThink()
	ApplyDamage( self.damageTable )
	EmitSoundOn( "Hero_OgreMagi.Ignite.Damage", self:GetParent() )
end

function modifier_batrider_combusition:GetEffectName()
	return "particles/units/heroes/hero_ogre_magi/ogre_magi_ignite_debuff.vpcf"
end

function modifier_batrider_combusition:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end