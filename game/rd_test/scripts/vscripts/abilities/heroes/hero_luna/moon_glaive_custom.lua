LinkLuaModifier("modifier_luna_moon_glaive_custom", "abilities/heroes/hero_luna/moon_glaive_custom", LUA_MODIFIER_MOTION_NONE)

luna_moon_glaive_custom = class({
	GetIntrinsicModifierName = function() return "modifier_luna_moon_glaive_custom" end
})

function luna_moon_glaive_custom:OnProjectileHit_ExtraData(target, location, data)
	if not IsServer() then return end
	local caster = self:GetCaster()
	if target then
		local reduction = (100 - self:GetSpecialValueFor("damage_reduction_pct")) / 100
		print(data.isUlt)
		local final_damage
		if data.isUlt == 1 then
			final_damage = data.damage
		else
			final_damage = data.damage * reduction
		end
		ApplyDamage({
			victim = target,
			attacker = caster,
			ability = self,
			damage = final_damage,
			damage_type = DAMAGE_TYPE_PHYSICAL
		})
		if data.bounces > 0 then
			local nearby_enemies = FindUnitsInRadius(
				caster:GetTeamNumber(),
				target:GetAbsOrigin(),
				nil,
				self:GetSpecialValueFor("range"),
				self:GetAbilityTargetTeam(),
				self:GetAbilityTargetType(),
				self:GetAbilityTargetFlags(),
				FIND_CLOSEST,
				false
			)
			table.remove(nearby_enemies, 1)
			--[[	for i = 1, #nearby_enemies, 1 in pairs(nearby_enemies) do
					if nearby_enemies[i] == target then
						table.remove(nearby_enemies, i)
						break
					end
				end]]
			for _, unit in pairs(nearby_enemies) do
				ProjectileManager:CreateTrackingProjectile({
					Target = unit,
					Source = target,
					Ability = self,
					EffectName = caster:GetRangedProjectileName(),
					bDodgeable = false,
					iMoveSpeed = caster:GetProjectileSpeed(),
					ExtraData = {
						bounces = data.bounces - 1,
						damage = final_damage,
						isUlt = data.isUlt
					}
				})
				break
			end
		end
	end
end

modifier_luna_moon_glaive_custom = class({
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_EVENT_ON_ATTACK_LANDED
	} end
})

function modifier_luna_moon_glaive_custom:OnCreated()
	if not IsServer() then return end
	self.ability = self:GetAbility()
	self.bounces = self.ability:GetSpecialValueFor("bounces")
	self.radius = self.ability:GetSpecialValueFor("range")
	self.target_team = self.ability:GetAbilityTargetTeam()
	self.target_type = self.ability:GetAbilityTargetType()
	self.target_flags = self.ability:GetAbilityTargetFlags()
end

function modifier_luna_moon_glaive_custom:OnRefresh()
	self:OnCreated()
end

function modifier_luna_moon_glaive_custom:OnAttackLanded(keys)
	if not IsServer() then return end
	local caster = self:GetCaster()
	local target = keys.target
	local UltActive = caster:HasModifier("modifier_luna_eclipse_custom")
	local nearby_enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		target:GetAbsOrigin(),
		nil,
		self.radius,
		self.target_team,
		self.target_type,
		self.target_flags,
		FIND_CLOSEST,
		false
	)
	table.remove(nearby_enemies, 1)
--[[	for i = 1, #nearby_enemies, 1 in pairs(nearby_enemies) do
		if nearby_enemies[i] == target then
			table.remove(nearby_enemies, i)
			break
		end
	end]]
	for _, unit in pairs(nearby_enemies) do
		caster_damage = caster:GetAverageTrueAttackDamageDisplay()
		ProjectileManager:CreateTrackingProjectile({
			Target = unit,
			Source = target,
			Ability = self.ability,
			EffectName = caster:GetRangedProjectileName(),
			bDodgeable = false,
			iMoveSpeed = caster:GetProjectileSpeed(),
			ExtraData = {
				bounces = self.bounces,
				damage = caster_damage,
				isUlt = UltActive
			}
		})
		break
	end
end