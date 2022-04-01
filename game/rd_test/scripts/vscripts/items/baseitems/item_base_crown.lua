LinkLuaModifier("modifier_item_base_crown", "items/baseitems/item_base_crown", LUA_MODIFIER_MOTION_NONE)

item_base_crown = class({})

function item_base_crown:GetIntrinsicModifierName()
	return "modifier_item_base_crown"
end

item_base_allstats_1 = class(item_base_crown)
item_base_allstats_2 = class(item_base_crown)
item_base_allstats_3 = class(item_base_crown)
item_base_allstats_4 = class(item_base_crown)

modifier_item_base_crown = class({
	IsHidden 		= function(self) return true end,
	DeclareFunctions  = function(self) return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}end,
})

function modifier_item_base_crown:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor("bonus_allstats")
end

function modifier_item_base_crown:GetModifierBonusStats_Agility()
	return self:GetAbility():GetSpecialValueFor("bonus_allstats")
end

function modifier_item_base_crown:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("bonus_allstats")
end
