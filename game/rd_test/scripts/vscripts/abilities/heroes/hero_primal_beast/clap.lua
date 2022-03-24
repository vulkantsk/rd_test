LinkLuaModifier("modifier_primal_beast_clap", "abilities/heroes/hero_primal_beast/clap", LUA_MODIFIER_MOTION_NONE)

primal_beast_clap = class({
	GetCastAnimation = function() return ACT_DOTA_CAST1_STATUE end,
	GetPlaybackRateOverride = function() return 3 end
})


function primal_beast_clap:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local nearby_enemies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, self:GetSpecialValueFor("radius"), self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), self:GetAbilityTargetFlags(), 0, false)
	for _, enemy in pairs(nearby_enemies) do
		enemy:AddNewModifier(caster, self, "modifier_primal_beast_clap", {duration = self:GetSpecialValueFor("reduction_duration")})
		ApplyDamage({
			victim = enemy,
			attacker = caster,
			ability = self,
			damage = self:GetSpecialValueFor("damage"),
			damage_type = self:GetAbilityDamageType()
		})
	end
	local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_primal_beast/primal_beast_pulverize_hit.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(pfx, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(pfx, 1, Vector(self:GetSpecialValueFor("radius"), 0, 0))
	ParticleManager:SetParticleControl(pfx, 3, caster:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(pfx)
	EmitSoundOnLocationWithCaster(caster:GetAbsOrigin(), "Hero_PrimalBeast.Pulverize.Impact", caster)
end

modifier_primal_beast_clap = class({
	IsHidden = function() return false end,
	IsPurgable = function() return true end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
	} end,
	GetModifierAttackSpeedBonus_Constant = function(self) return self.as_reduction end
})

function modifier_primal_beast_clap:OnCreated()
	self.ability = self:GetAbility()
	self.as_reduction = self.ability:GetSpecialValueFor("as_reduction") * -1
	self:SetHasCustomTransmitterData(true)
end

function modifier_primal_beast_clap:AddCustomTransmitterData()
	return {
		as_reduction = self.as_reduction
	}
end

function modifier_primal_beast_clap:HandleCustomTransmitterData(data)
	self.as_reduction = data.as_reduction
end

function modifier_primal_beast_clap:OnRefresh()
	self:OnCreated()
end