LinkLuaModifier("modifier_item_base_mage_ring", "items/baseitems/item_base_mage_ring", LUA_MODIFIER_MOTION_NONE)

item_base_mage_ring = class({})

function item_base_mage_ring:GetIntrinsicModifierName()
	return "modifier_item_base_mage_ring"
end

item_base_mp_regen_1 = class(item_base_mage_ring)
item_base_mp_regen_2 = class(item_base_mage_ring)
item_base_mp_regen_3 = class(item_base_mage_ring)
item_base_mp_regen_4 = class(item_base_mage_ring)

modifier_item_base_mage_ring = class({
	IsHidden 		= function(self) return true end,
	DeclareFunctions  = function(self) return {
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
	}end,
})

function modifier_item_base_mage_ring:GetModifierConstantManaRegen()
	return self:GetAbility():GetSpecialValueFor("bonus_mp_regen")
end