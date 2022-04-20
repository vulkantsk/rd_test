LinkLuaModifier("modifier_item_base_mp_regen", "items/baseitems/item_base_mp_regen", LUA_MODIFIER_MOTION_NONE)

item_base_mp_regen = class({})

function item_base_mp_regen:GetIntrinsicModifierName()
	return "modifier_item_base_mp_regen"
end

item_base_mp_regen_1 = class(item_base_mp_regen)
item_base_mp_regen_2 = class(item_base_mp_regen)
item_base_mp_regen_3 = class(item_base_mp_regen)
item_base_mp_regen_4 = class(item_base_mp_regen)
item_base_mp_regen_5 = class(item_base_mp_regen)

modifier_item_base_mp_regen = class({
	IsHidden 		= function(self) return true end,
	GetAttributes 	= function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,
	DeclareFunctions  = function(self) return {
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
	}end,
})

function modifier_item_base_mp_regen:GetModifierConstantManaRegen()
	return self:GetAbility():GetSpecialValueFor("bonus_mp_regen")
end