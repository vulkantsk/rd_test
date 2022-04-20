LinkLuaModifier("modifier_item_base_allstats", "items/baseitems/item_base_allstats", LUA_MODIFIER_MOTION_NONE)

item_base_allstats = class({})

function item_base_allstats:GetIntrinsicModifierName()
	return "modifier_item_base_allstats"
end

item_base_allstats_1 = class(item_base_allstats)
item_base_allstats_2 = class(item_base_allstats)
item_base_allstats_3 = class(item_base_allstats)
item_base_allstats_4 = class(item_base_allstats)
item_base_allstats_5 = class(item_base_allstats)

modifier_item_base_allstats = class({
	IsHidden 		= function(self) return true end,
	GetAttributes 	= function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,
	DeclareFunctions  = function(self) return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}end,
})

function modifier_item_base_allstats:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor("bonus_allstats")
end

function modifier_item_base_allstats:GetModifierBonusStats_Agility()
	return self:GetAbility():GetSpecialValueFor("bonus_allstats")
end

function modifier_item_base_allstats:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("bonus_allstats")
end
