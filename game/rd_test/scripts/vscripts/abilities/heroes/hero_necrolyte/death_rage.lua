LinkLuaModifier("modifier_necrolyte_death_rage", "abilities/heroes/hero_necrolyte/death_rage", LUA_MODIFIER_MOTION_NONE)

necrolyte_death_rage = class({})

function necrolyte_death_rage:OnSpellStart()
	local buff_duration = self:GetSpecialValueFor("buff_duration")

	local caster = self:GetCaster()
	local target = self:GetCursorTarget()

	target:AddNewModifier(caster, self, "modifier_necrolyte_death_rage", {duration = buff_duration})
end


modifier_necrolyte_death_rage = class({
	IsHidden = function() return false end,
	IsPurgable = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
	} end
})

function modifier_necrolyte_death_rage:GetEffectName()
	return "particles/items2_fx/mask_of_madness.vpcf"
end

function modifier_necrolyte_death_rage:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("bonus_as")
end
