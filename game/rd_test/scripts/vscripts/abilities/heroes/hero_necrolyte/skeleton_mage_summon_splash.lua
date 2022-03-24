LinkLuaModifier("modifier_necrolyte_skeleton_mage_summon_splash", "abilities/heroes/hero_necrolyte/skeleton_mage_summon_splash", LUA_MODIFIER_MOTION_NONE)

necrolyte_skeleton_mage_summon_splash = class({
	GetIntrinsicModifierName = function() return "modifier_necrolyte_skeleton_mage_summon_splash" end
})

modifier_necrolyte_skeleton_mage_summon_splash = class({
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_EVENT_ON_ATTACK_LANDED
	} end
})

function modifier_necrolyte_skeleton_mage_summon_splash:OnCreated()
	if not IsServer() then return end
	self.ability = self:GetAbility()
	self.radius = self.ability:GetSpecialValueFor("radius")
	self.damage_pct = self.ability:GetSpecialValueFor("damage_pct")
	self.target_team = self.ability:GetAbilityTargetTeam()
	self.target_type = self.ability:GetAbilityTargetType()
	self.target_flags = self.ability:GetAbilityTargetFlags() or 0
	self.damage_type = self.ability:GetAbilityDamageType()
end

function modifier_necrolyte_skeleton_mage_summon_splash:OnAttackLanded(data)
	if not IsServer() then return end
	local attacker = data.attacker
	local target = data.target
	local damage = data.damage * (self.damage_pct / 100)
	if attacker == self:GetParent() and target and not (target:IsMagicImmune()) then
		local enemies_in_radius = FindUnitsInRadius(attacker:GetTeamNumber(), target:GetAbsOrigin(), nil, self.radius, self.target_team, self.target_type, self.target_flags, 0, false)
		for _, enemy in pairs(enemies_in_radius) do
			if not enemy == target then
				ApplyDamage({
					victim = enemy,
					attacker = attacker,
					ability = self.ability,
					damage = damage,
					damage_type = self.damage_type
				})
			end
		end
	end
end