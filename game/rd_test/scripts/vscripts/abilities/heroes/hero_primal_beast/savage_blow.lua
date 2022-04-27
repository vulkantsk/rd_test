LinkLuaModifier("modifier_primal_beast_savage_blow", "abilities/heroes/hero_primal_beast/savage_blow", LUA_MODIFIER_MOTION_NONE)


primal_beast_savage_blow = class({})

function primal_beast_savage_blow:GetIntrinsicModifierName()
    return "modifier_primal_beast_savage_blow"
end


modifier_primal_beast_savage_blow = class({
    IsHidden = function(self) return true end,
    IsPurgable = function() return true end,
    DeclareFunctions = function() return {
        MODIFIER_EVENT_ON_ATTACK_LANDED,
    } end,
})

function modifier_primal_beast_savage_blow:OnCreated()
    self.ability = self:GetAbility()
    self.radius = self.ability:GetSpecialValueFor("radius")
    self.damage = self.ability:GetSpecialValueFor("damage")
    self.damage_str =  self.ability:GetSpecialValueFor("damage_str")
end

function modifier_primal_beast_savage_blow:OnRefresh()
    self:OnCreated()
end

function modifier_primal_beast_savage_blow:OnAttackLanded(data)
    local caster = self:GetCaster()
    local attacker = data.attacker
    local target = data.target
    if not self.ability:IsCooldownReady() then
        return
    end

    if caster == attacker and not target:IsBuilding()  then
        local nearby_enemies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, self.ability:GetSpecialValueFor("radius"), self.ability:GetAbilityTargetTeam(), self.ability:GetAbilityTargetType(), self.ability:GetAbilityTargetFlags(), 0, false)
       local total_damage = self.damage + self.damage_str*caster:GetStrength()/100

        for _, enemy in pairs(nearby_enemies) do
            ApplyDamage({
                victim = enemy,
                attacker = caster,
                ability = self.ability,
                damage = total_damage,
                damage_type = self.ability:GetAbilityDamageType()
            })
        end
        local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_primal_beast/primal_beast_pulverize_hit.vpcf", PATTACH_WORLDORIGIN, nil)
        ParticleManager:SetParticleControl(pfx, 0, caster:GetAbsOrigin())
        ParticleManager:SetParticleControl(pfx, 1, Vector(self.radius, 0, 0))
        ParticleManager:SetParticleControl(pfx, 3, caster:GetAbsOrigin())
        ParticleManager:ReleaseParticleIndex(pfx)
        EmitSoundOnLocationWithCaster(caster:GetAbsOrigin(), "Hero_PrimalBeast.Pulverize.Impact", caster)
        self.ability:UseResources(true, true, true)
    end
end
