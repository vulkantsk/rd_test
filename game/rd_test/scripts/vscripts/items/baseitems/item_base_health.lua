LinkLuaModifier("modifier_item_base_health", "items/baseitems/item_base_health", LUA_MODIFIER_MOTION_NONE)

item_base_health = class({})

function item_base_health:GetIntrinsicModifierName()
	return "modifier_item_base_health"
end

item_base_health_1 = class(item_base_health)
item_base_health_2 = class(item_base_health)
item_base_health_3 = class(item_base_health)
item_base_health_4 = class(item_base_health)

modifier_item_base_health = class({
	IsHidden 		= function(self) return true end,
	GetAttributes 	= function(self) return MODIFIER_ATTRIBUTE_MULTIPLE end,
	DeclareFunctions  = function(self) return {
		MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
		MODIFIER_PROPERTY_HEALTH_BONUS,
	}end,
})

function modifier_item_base_health:OnCreated()
	self.parent = self:GetParent()
end

function modifier_item_base_health:GetModifierHealthBonus()
	if(self.parent:IsRealHero() == true) then
		return self:GetAbility():GetSpecialValueFor("bonus_health")
	end
	return 0
end

function modifier_item_base_health:GetModifierExtraHealthBonus()
	if(self.parent:IsRealHero() == true) then
		return 0
	end
	return self:GetAbility():GetSpecialValueFor("bonus_health")
end