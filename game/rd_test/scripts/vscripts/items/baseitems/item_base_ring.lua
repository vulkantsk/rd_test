LinkLuaModifier("modifier_item_base_ring", "items/baseitems/item_base_ring", LUA_MODIFIER_MOTION_NONE)

item_base_ring = class({})

function item_base_ring:GetIntrinsicModifierName()
	return "modifier_item_base_ring"
end

item_base_hp_regen_1 = class(item_base_ring)
item_base_hp_regen_2 = class(item_base_ring)
item_base_hp_regen_3 = class(item_base_ring)
item_base_hp_regen_4 = class(item_base_ring)

modifier_item_base_ring = class({
	IsHidden 		= function(self) return true end,
	DeclareFunctions  = function(self) return {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
	}end,
})

function modifier_item_base_ring:GetModifierConstantHealthRegen()
	return self:GetAbility():GetSpecialValueFor("bonus_hp_regen")
end