LinkLuaModifier("modifier_kunkka_seasickness_immunity", "abilities/heroes/hero_kunkka/seasickness_immunity", LUA_MODIFIER_MOTION_NONE)


kunkka_seasickness_immunity = class({})

function kunkka_seasickness_immunity:GetIntrinsicModifierName()
    return "modifier_kunkka_seasickness_immunity"
end


modifier_kunkka_seasickness_immunity = class({
    IsHidden = function(self) return false end,
    IsPurgable = function() return true end,
    DeclareFunctions = function() return {
        MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_STATUS_RESISTANCE,
--        MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING ,        
    } end,
})

function modifier_kunkka_seasickness_immunity:OnCreated()
    local ability = self:GetAbility()
    self.bonus_base_damage = ability:GetSpecialValueFor("bonus_base_damage")
    self.bonus_armor = ability:GetSpecialValueFor("bonus_armor")
    self.bonus_status_resist = ability:GetSpecialValueFor("bonus_status_resist")
end

function modifier_kunkka_seasickness_immunity:OnRefresh()
    self:OnCreated()
end

function modifier_kunkka_seasickness_immunity:GetModifierBaseAttack_BonusDamage()
    return self.bonus_base_damage
end
function modifier_kunkka_seasickness_immunity:GetModifierPhysicalArmorBonus()
    return self.bonus_armor
end
--GetModifierStatusResistanceStacking
function modifier_kunkka_seasickness_immunity:GetModifierStatusResistance()
    return self.bonus_status_resist
end
