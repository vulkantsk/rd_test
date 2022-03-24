LinkLuaModifier("modifier_luna_eclipse_custom", "abilities/heroes/hero_luna/eclipse_custom", LUA_MODIFIER_MOTION_NONE)

luna_eclipse_custom = class({})

function luna_eclipse_custom:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_luna_eclipse_custom", {duration = self:GetSpecialValueFor("duration")})
end

modifier_luna_eclipse_custom = class({
	IsHidden = function() return false end,
	IsPurgable = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
	} end,
	GetModifierAttackSpeedBonus_Constant = function(self) return self.as_bonus end
})

function modifier_luna_eclipse_custom:OnCreated()
	self.ability = self:GetAbility()
	self.as_bonus = self.ability:GetSpecialValueFor("as_bonus")
end

function modifier_luna_eclipse_custom:OnRefresh()
	self:OnCreated()
end