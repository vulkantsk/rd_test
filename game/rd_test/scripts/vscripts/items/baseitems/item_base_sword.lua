LinkLuaModifier("modifier_item_base_sword", "items/baseitems/item_base_sword", LUA_MODIFIER_MOTION_NONE)

item_base_sword = class({})

function item_base_sword:GetIntrinsicModifierName()
	return "modifier_item_base_sword"
end

item_base_damage_1 = class(item_base_sword)
item_base_damage_2 = class(item_base_sword)
item_base_damage_3 = class(item_base_sword)
item_base_damage_4 = class(item_base_sword)

modifier_item_base_sword = class({
	IsHidden 		= function(self) return true end,
	DeclareFunctions  = function(self) return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}end,
})

function modifier_item_base_sword:OnCreated()
	self.bonusValue = self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_item_base_sword:GetModifierPreAttack_BonusDamage()
	return self.bonusValue
end
