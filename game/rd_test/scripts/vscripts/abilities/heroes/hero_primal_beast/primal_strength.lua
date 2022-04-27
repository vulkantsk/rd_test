LinkLuaModifier("modifier_primal_beast_primal_strength", "abilities/heroes/hero_primal_beast/primal_strength", LUA_MODIFIER_MOTION_NONE)


primal_beast_primal_strength = class({})

function primal_beast_primal_strength:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    local buff_duration = self:GetSpecialValueFor("buff_duration")

    caster:AddNewModifier(caster, self, "modifier_primal_beast_primal_strength", {duration = buff_duration})
end


modifier_primal_beast_primal_strength = class({
    IsHidden = function(self) return false end,
    IsPurgable = function() return true end,
    DeclareFunctions = function() return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    } end,
})

function modifier_primal_beast_primal_strength:OnCreated()
    self.ability = self:GetAbility()
    self.bonus_str = self.ability:GetSpecialValueFor("bonus_str")
    self.bonus_hp_regen = self.ability:GetSpecialValueFor("bonus_hp_regen")
end

function modifier_primal_beast_primal_strength:OnRefresh()
    self:OnCreated()
end

function modifier_primal_beast_primal_strength:GetModifierBonusStats_Strength()
    return self.bonus_str
end

function modifier_primal_beast_primal_strength:GetModifierConstantHealthRegen()
    return self.bonus_hp_regen
end
