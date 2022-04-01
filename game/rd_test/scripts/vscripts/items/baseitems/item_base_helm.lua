LinkLuaModifier("modifier_item_base_helm", "items/baseitems/item_base_helm", LUA_MODIFIER_MOTION_NONE)

item_base_helm = class({})

function item_base_helm:GetIntrinsicModifierName()
	return "modifier_item_base_helm"
end

item_base_helm_1 = class(item_base_helm)
item_base_helm_2 = class(item_base_helm)
item_base_helm_3 = class(item_base_helm)

modifier_item_base_helm = class({
	IsHidden 		= function(self) return true end,
	DeclareFunctions  = function(self) return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}end,
})

function modifier_item_base_helm:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor("bonus_value")
end

function modifier_item_base_helm:GetModifierBonusStats_Agility()
	return self:GetAbility():GetSpecialValueFor("bonus_value")
end

function modifier_item_base_helm:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("bonus_value")
end
