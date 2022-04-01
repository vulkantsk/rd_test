LinkLuaModifier("modifier_item_base_ring", "items/baseitems/item_base_ring", LUA_MODIFIER_MOTION_NONE)

item_base_ring = class({})

function item_base_ring:GetIntrinsicModifierName()
	return "modifier_item_base_ring"
end

item_base_health_regeneration_1 = class(item_base_ring)
item_base_health_regeneration_2 = class(item_base_ring)
item_base_health_regeneration_3 = class(item_base_ring)
item_base_health_regeneration_4 = class(item_base_ring)

modifier_item_base_ring = class({
	IsHidden 		= function(self) return true end,
	DeclareFunctions  = function(self) return {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
	}end,
})

function modifier_item_base_ring:GetModifierConstantHealthRegen()
	return self:GetAbility():GetSpecialValueFor("bonus_health_regeneration")
end