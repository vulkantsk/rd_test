LinkLuaModifier("modifier_kunkka_hard_blow", "abilities/heroes/hero_kunkka/hard_blow", LUA_MODIFIER_MOTION_NONE)


kunkka_hard_blow = class({})

function kunkka_hard_blow:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local buff_duration = self:GetSpecialValueFor("buff_duration")

    caster:EmitSound('Hero_Abaddon.DeathCoil.Cast')
    
    caster:AddNewModifier(caster, self, "modifier_kunkka_hard_blow", {duration = buff_duration})
end


modifier_kunkka_hard_blow = class({
    IsHidden = function(self) return false end,
    IsPurgable = function() return true end,
    DeclareFunctions = function() return {
        MODIFIER_EVENT_ON_ATTACK,
        MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
    } end,
})

function modifier_kunkka_hard_blow:OnCreated()
    self.ability = self:GetAbility()
    self.bonus_damage_pct = self.ability:GetSpecialValueFor("bonus_damage_pct")
end

function modifier_kunkka_hard_blow:OnRefresh()
    self:OnCreated()
end

function modifier_kunkka_hard_blow:OnAttack(data)
    local caster = self:GetCaster()
    local attacker = data.attacker

    if caster == attacker then
        self:Destroy()
    end
end

function modifier_kunkka_hard_blow:GetModifierBaseDamageOutgoing_Percentage()
    return self.bonus_damage_pct
end