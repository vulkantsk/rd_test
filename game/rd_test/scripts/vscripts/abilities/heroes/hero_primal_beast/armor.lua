LinkLuaModifier("modifier_primal_beast_armor", "abilities/heroes/hero_primal_beast/armor", LUA_MODIFIER_MOTION_NONE)

primal_beast_armor = class({
	GetIntrinsicModifierName = function() return "modifier_primal_beast_armor" end
})

modifier_primal_beast_armor = class({
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
	} end,
	GetModifierIncomingDamage_Percentage = function(self) return self.damage_reduction_pct end
})

function modifier_primal_beast_armor:OnCreated()
	self.ability = self:GetAbility()
	self.damage_reduction_pct = self.ability:GetSpecialValueFor("damage_reduction_pct")
end

function modifier_primal_beast_armor:OnRefresh()
	self:OnCreated()
end