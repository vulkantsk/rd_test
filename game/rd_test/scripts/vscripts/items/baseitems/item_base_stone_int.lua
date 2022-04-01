LinkLuaModifier("modifier_item_base_stone_int", "items/baseitems/item_base_stone_int", LUA_MODIFIER_MOTION_NONE)

item_base_stone_int = class({})

function item_base_stone_int:GetIntrinsicModifierName()
	return "modifier_item_base_stone_int"
end

item_base_int_1 = class(item_base_stone_int)
item_base_int_2 = class(item_base_stone_int)
item_base_int_3 = class(item_base_stone_int)
item_base_int_4 = class(item_base_stone_int)

modifier_item_base_stone_int = class({
	IsHidden 		= function(self) return true end,
	DeclareFunctions  = function(self) return {
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}end,
})

function modifier_item_base_stone_int:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("bonus_int")
end