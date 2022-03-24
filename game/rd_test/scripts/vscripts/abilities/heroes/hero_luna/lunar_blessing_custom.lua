LinkLuaModifier("modifier_luna_lunar_blessing_custom_aura", "abilities/heroes/hero_luna/lunar_blessing_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_luna_lunar_blessing_custom_aura_buff", "abilities/heroes/hero_luna/lunar_blessing_custom", LUA_MODIFIER_MOTION_NONE)

luna_lunar_blessing_custom = class({
	GetIntrinsicModifierName = function() return "modifier_luna_lunar_blessing_custom_aura" end
})

modifier_luna_lunar_blessing_custom_aura = class({
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
	IsAura = function() return true end,
	GetAuraSearchTeam = function(self) return self.target_team end,
	GetAuraSearchType = function(self) return self.target_type end,
	GetAuraSearchFlags = function(self) return self.target_flags end,
	GetAuraRadius = function(self) return self.aura_radius end,
	GetModifierAura = function() return "modifier_luna_lunar_blessing_custom_aura_buff" end
})

function modifier_luna_lunar_blessing_custom_aura:OnCreated()
	if not IsServer() then return end
	self.ability = self:GetAbility()
	self.target_team = self.ability:GetAbilityTargetTeam()
	self.target_type = self.ability:GetAbilityTargetType()
	self.target_flags = self.ability:GetAbilityTargetFlags()
	self.aura_radius = self.ability:GetSpecialValueFor("radius")
end

function modifier_luna_lunar_blessing_custom_aura:GetAuraEntityReject(target)
	if not IsServer() then return end
	if target:IsRangedAttacker() then
		return false
	end
	return true
end

modifier_luna_lunar_blessing_custom_aura_buff = class({
	IsHidden = function() return false end,
	IsPurgable = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE
	} end,
	GetModifierDamageOutgoing_Percentage = function(self) return self.bonus_damage_pct end
})

function modifier_luna_lunar_blessing_custom_aura_buff:OnCreated()
	self.ability = self:GetAbility()
	self.bonus_damage_pct = self.ability:GetSpecialValueFor("bonus_damage_pct")
end

function modifier_luna_lunar_blessing_custom_aura_buff:OnRefresh()
	self:OnCreated()
end