LinkLuaModifier("modifier_luna_moon_light", "abilities/heroes/hero_luna/moon_light", LUA_MODIFIER_MOTION_NONE)

luna_moon_light = class({
	GetIntrinsicModifierName = function() return "modifier_luna_moon_light" end
})

modifier_luna_moon_light = class({
	IsHidden = function() return not GameRules:IsDaytime()  end,
	IsPurgable = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_EVASION_CONSTANT,
	} end
})

function modifier_luna_moon_light:OnCreated()
	if not IsServer() then return end
	self.ability = self:GetAbility()
	self.bonus_ms_pct = self.ability:GetSpecialValueFor("bonus_ms_pct")
	self.bonus_evasion = self.ability:GetSpecialValueFor("bonus_evasion")
	self.bonus_magic_resist = self.ability:GetSpecialValueFor("bonus_magic_resist")
end

function modifier_luna_moon_light:OnRefresh()
	self:OnCreated()
end

function modifier_luna_moon_light:GetModifierMoveSpeedBonus_Percentage()
	if not GameRules:IsDaytime() then
		return self.bonus_ms_pct
	end
end

function modifier_luna_moon_light:GetModifierEvasion_Constant()
	if not GameRules:IsDaytime() then
		return self.bonus_evasion
	end
end

function modifier_luna_moon_light:GetModifierMagicalResistanceBonus()
	if not GameRules:IsDaytime() then
		return self.bonus_magic_resist
	end
end

