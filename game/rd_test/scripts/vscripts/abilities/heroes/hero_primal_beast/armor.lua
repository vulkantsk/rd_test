LinkLuaModifier("modifier_primal_beast_armor", "abilities/heroes/hero_primal_beast/armor", LUA_MODIFIER_MOTION_NONE)

primal_beast_armor = class({
	GetIntrinsicModifierName = function() return "modifier_primal_beast_armor" end
})

modifier_primal_beast_armor = class({
	IsHidden = function() return true end,
	IsPurgable = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK
	} end,
})

function modifier_primal_beast_armor:GetModifierPhysical_ConstantBlock()
	return self.damage_block
end

function modifier_primal_beast_armor:OnCreated()
	self.ability = self:GetAbility()
	self.damage_block = self.ability:GetSpecialValueFor("damage_block")
end

function modifier_primal_beast_armor:OnRefresh()
	self:OnCreated()
end