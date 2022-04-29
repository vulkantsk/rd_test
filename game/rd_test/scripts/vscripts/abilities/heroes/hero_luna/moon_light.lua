LinkLuaModifier("modifier_luna_moon_light", "abilities/heroes/hero_luna/moon_light", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_luna_moon_light_buff", "abilities/heroes/hero_luna/moon_light", LUA_MODIFIER_MOTION_NONE)

luna_moon_light = class({
	GetIntrinsicModifierName = function() return "modifier_luna_moon_light" end
})

modifier_luna_moon_light = class({
	IsHidden = function() return true  end,
	IsPurgable = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_EVASION_CONSTANT,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	} end
})

function modifier_luna_moon_light:OnCreated()
	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	self:StartIntervalThink(1)
end

function modifier_luna_moon_light:OnIntervalThink()

	if not GameRules:IsDaytime() and not self.caster:HasModifier("modifier_luna_moon_light_buff") then
		self.caster:AddNewModifier(self.caster, self.ability, "modifier_luna_moon_light_buff", nil)
	end

	if GameRules:IsDaytime() and self.caster:HasModifier("modifier_luna_moon_light_buff") then
		self.caster:RemoveModifierByName("modifier_luna_moon_light_buff")
	end
end

modifier_luna_moon_light_buff = class({
	IsHidden = function() return false  end,
	IsPurgable = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_EVASION_CONSTANT,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	} end
})

function modifier_luna_moon_light_buff:OnCreated()
	self.ability = self:GetAbility()
	self.bonus_ms_pct = self.ability:GetSpecialValueFor("bonus_ms_pct")
	self.bonus_evasion = self.ability:GetSpecialValueFor("bonus_evasion")
	self.bonus_magic_resist = self.ability:GetSpecialValueFor("bonus_magic_resist")
end

function modifier_luna_moon_light_buff:OnRefresh()
	self:OnCreated()
end

function modifier_luna_moon_light_buff:GetModifierMoveSpeedBonus_Percentage()
	return self.bonus_ms_pct
end

function modifier_luna_moon_light_buff:GetModifierEvasion_Constant()
	return self.bonus_evasion
end

function modifier_luna_moon_light:GetModifierMagicalResistanceBonus()
	return self.bonus_magic_resist
end

