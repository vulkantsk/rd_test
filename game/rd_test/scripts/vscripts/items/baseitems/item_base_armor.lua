LinkLuaModifier("modifier_item_base_armor", "items/baseitems/item_base_armor", LUA_MODIFIER_MOTION_NONE)

item_base_armor = class({})

function item_base_armor:GetIntrinsicModifierName()
	return "modifier_item_base_armor"
end

item_base_armor_1 = class(item_base_armor)
item_base_armor_2 = class(item_base_armor)
item_base_armor_3 = class(item_base_armor)
item_base_armor_4 = class(item_base_armor)
item_base_armor_5 = class(item_base_armor)

modifier_item_base_armor = class({
	IsHidden 		= function(self) return true end,
	GetAttributes 	= function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,
	DeclareFunctions  = function(self) return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}end,
})

function modifier_item_base_armor:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

