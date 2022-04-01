LinkLuaModifier("modifier_item_base_stone_str", "items/baseitems/item_base_stone_str", LUA_MODIFIER_MOTION_NONE)

item_base_stone_str = class({})

function item_base_stone_str:GetIntrinsicModifierName()
	return "modifier_item_base_stone_str"
end

item_base_str_1 = class(item_base_stone_str)
item_base_str_2 = class(item_base_stone_str)
item_base_str_3 = class(item_base_stone_str)
item_base_str_4 = class(item_base_stone_str)

modifier_item_base_stone_str = class({
	IsHidden 		= function(self) return true end,
	DeclareFunctions  = function(self) return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS
	}end,
})

function modifier_item_base_stone_str:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor("bonus_str")
end