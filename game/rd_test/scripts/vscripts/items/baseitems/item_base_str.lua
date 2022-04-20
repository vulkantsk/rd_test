LinkLuaModifier("modifier_item_base_str", "items/baseitems/item_base_str", LUA_MODIFIER_MOTION_NONE)

item_base_str = class({})

function item_base_str:GetIntrinsicModifierName()
	return "modifier_item_base_str"
end

item_base_str_1 = class(item_base_str)
item_base_str_2 = class(item_base_str)
item_base_str_3 = class(item_base_str)
item_base_str_4 = class(item_base_str)
item_base_str_5 = class(item_base_str)

modifier_item_base_str = class({
	IsHidden 		= function(self) return true end,
	GetAttributes 	= function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,
	DeclareFunctions  = function(self) return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS
	}end,
})

function modifier_item_base_str:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor("bonus_str")
end