LinkLuaModifier("modifier_luna_lumina_bless", "abilities/heroes/hero_luna/lumina_bless", LUA_MODIFIER_MOTION_NONE)

luna_lumina_bless = class({})

function luna_lumina_bless:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_luna_lumina_bless", {duration = self:GetSpecialValueFor("duration")})
end

modifier_luna_lumina_bless = class({
	IsHidden = function() return false end,
	IsPurgable = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
	} end,
	GetModifierAttackSpeedBonus_Constant = function(self) return self.as_bonus end
})

function modifier_luna_lumina_bless:OnCreated()
	self.ability = self:GetAbility()
	self.as_bonus = self.ability:GetSpecialValueFor("as_bonus")
end

function modifier_luna_lumina_bless:OnRefresh()
	self:OnCreated()
end