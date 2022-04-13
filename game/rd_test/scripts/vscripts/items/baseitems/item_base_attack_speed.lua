LinkLuaModifier("modifier_item_base_attack_speed", "items/baseitems/item_base_attack_speed", LUA_MODIFIER_MOTION_NONE)

item_base_attack_speed = class({})

function item_base_attack_speed:GetIntrinsicModifierName()
	return "modifier_item_base_attack_speed"
end

item_base_attack_speed_1 = class(item_base_attack_speed)
item_base_attack_speed_2 = class(item_base_attack_speed)
item_base_attack_speed_3 = class(item_base_attack_speed)
item_base_attack_speed_4 = class(item_base_attack_speed)

modifier_item_base_attack_speed = class({
	IsHidden 		= function(self) return true end,
	GetAttributes 	= function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,
	DeclareFunctions  = function(self) return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
	}end,
})

function modifier_item_base_attack_speed:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end