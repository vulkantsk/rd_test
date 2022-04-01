LinkLuaModifier("modifier_item_base_stone_agi", "items/baseitems/item_base_stone_agi", LUA_MODIFIER_MOTION_NONE)

item_base_stone_agi = class({})

function item_base_stone_agi:GetIntrinsicModifierName()
	return "modifier_item_base_stone_agi"
end

item_base_agi_1 = class(item_base_stone_agi)
item_base_agi_2 = class(item_base_stone_agi)
item_base_agi_3 = class(item_base_stone_agi)
item_base_agi_4 = class(item_base_stone_agi)

modifier_item_base_stone_agi = class({
	IsHidden 		= function(self) return true end,
	DeclareFunctions  = function(self) return {
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS
	}end,
})

function modifier_item_base_stone_agi:GetModifierBonusStats_Agility()
	return self:GetAbility():GetSpecialValueFor("bonus_agi")
end