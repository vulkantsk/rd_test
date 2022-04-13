LinkLuaModifier("modifier_item_base_mana", "items/baseitems/item_base_mana", LUA_MODIFIER_MOTION_NONE)

item_base_mana = class({})

function item_base_mana:GetIntrinsicModifierName()
	return "modifier_item_base_mana"
end

item_base_mana_1 = class(item_base_mana)
item_base_mana_2 = class(item_base_mana)
item_base_mana_3 = class(item_base_mana)
item_base_mana_4 = class(item_base_mana)

modifier_item_base_mana = class({
	IsHidden 		= function(self) return true end,
	GetAttributes 	= function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,
	DeclareFunctions  = function(self) return {
		MODIFIER_PROPERTY_MANA_BONUS,
		MODIFIER_PROPERTY_EXTRA_MANA_BONUS,
	}end,
})

function modifier_item_base_mana:OnCreated()
	self.parent = self:GetParent()
end

function modifier_item_base_mana:GetModifierManaBonus()
	if(self.parent:IsRealHero() == true) then
		return self:GetAbility():GetSpecialValueFor("bonus_mana")
	end
	return 0
end

function modifier_item_base_mana:GetModifierExtraManaBonus()
	if(self.parent:IsRealHero() == true) then
		return 0
	end
	return self:GetAbility():GetSpecialValueFor("bonus_mana")
end