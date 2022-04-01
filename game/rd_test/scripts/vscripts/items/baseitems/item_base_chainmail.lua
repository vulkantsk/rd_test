LinkLuaModifier("modifier_item_base_chainmail", "items/baseitems/item_base_chainmail", LUA_MODIFIER_MOTION_NONE)

item_base_chainmail = class({})

function item_base_chainmail:GetIntrinsicModifierName()
	return "modifier_item_base_chainmail"
end

modifier_item_base_chainmail = class({
	IsHidden 		= function(self) return true end,
	DeclareFunctions  = function(self) return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}end,
})

function modifier_item_base_chainmail:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

item_base_armor_1 = class(item_base_chainmail)
item_base_armor_2 = class(item_base_chainmail)
item_base_armor_3 = class(item_base_chainmail)
item_base_armor_4 = class(item_base_chainmail)
