LinkLuaModifier("modifier_item_base_damage", "items/baseitems/item_base_damage", LUA_MODIFIER_MOTION_NONE)

item_base_damage = class({})

function item_base_damage:GetIntrinsicModifierName()
	return "modifier_item_base_damage"
end

item_base_damage_1 = class(item_base_damage)
item_base_damage_2 = class(item_base_damage)
item_base_damage_3 = class(item_base_damage)
item_base_damage_4 = class(item_base_damage)

modifier_item_base_damage = class({
	IsHidden 		= function(self) return true end,
	GetAttributes 	= function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,
	DeclareFunctions  = function(self) return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}end,
})

function modifier_item_base_damage:OnCreated()
	self.bonusValue = self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_base_damage:GetModifierPreAttack_BonusDamage()
	return self.bonusValue
end
