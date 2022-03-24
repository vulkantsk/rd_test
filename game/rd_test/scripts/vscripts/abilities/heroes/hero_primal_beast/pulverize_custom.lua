LinkLuaModifier("modifier_primal_beast_pulverize_custom", "abilities/heroes/hero_primal_beast/pulverize_custom", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_primal_beast_pulverize_custom_debuff", "abilities/heroes/hero_primal_beast/pulverize_custom", LUA_MODIFIER_MOTION_NONE)

primal_beast_pulverize_custom = class({
	GetChannelTime = function(self) return self:GetSpecialValueFor("duration") end,
	GetChannelAnimation = function() return ACT_DOTA_CHANNEL_ABILITY_5 end,
	GetPlaybackRateOverride = function(self) return self:GetSpecialValueFor("attack_interval") * 0.75 end
})

function primal_beast_pulverize_custom:OnSpellStart()
	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_primal_beast_pulverize_custom", {duration = self:GetSpecialValueFor("duration")})
	EmitSoundOn("Hero_PrimalBeast.Pulverize.Cast", caster)
end

function primal_beast_pulverize_custom:OnChannelFinish(bInterrupted)
	if bInterrupted then
		self:GetCaster():RemoveModifierByName("modifier_primal_beast_pulverize_custom")
	end
end

modifier_primal_beast_pulverize_custom = class({
	IsHidden = function() return true end,
	IsPurgable = function() return false end
})

function modifier_primal_beast_pulverize_custom:OnCreated()
	if not IsServer() then return end
	self.ability = self:GetAbility()
	self.radius = self.ability:GetSpecialValueFor("radius")
	self.damage = self.ability:GetSpecialValueFor("damage")
	self.stack_duration = self.ability:GetSpecialValueFor("stack_duration")
	self.attack_interval = self.ability:GetSpecialValueFor("attack_interval")
	self.max_stacks = self.ability:GetSpecialValueFor("max_stacks")
	self.target_team = self.ability:GetAbilityTargetTeam()
	self.target_type = self.ability:GetAbilityTargetType()
	self.target_flags = self.ability:GetAbilityTargetFlags() or 0
	self.damage_type = self.ability:GetAbilityDamageType()
	self:StartIntervalThink(self.attack_interval)
end

function modifier_primal_beast_pulverize_custom:OnIntervalThink()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local nearby_enemies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, self.radius, self.target_team, self.target_type, self.target_flags, 0, false)
	for _, enemy in pairs(nearby_enemies) do
		ApplyDamage({
			victim = enemy,
			attacker = caster,
			ability = self.ability,
			damage = self.damage,
			damage_type = self.damage_type
		})
		if not enemy:HasModifier("modifier_primal_beast_pulverize_custom_debuff") then
			enemy:AddNewModifier(caster, self.ability, "modifier_primal_beast_pulverize_custom_debuff", {duration = self.stack_duration}):SetStackCount(1)
		else
			local mod = enemy:FindModifierByName("modifier_primal_beast_pulverize_custom_debuff")
			if mod:GetStackCount() < self.max_stacks then
				mod:IncrementStackCount()
				mod:SetDuration(self.stack_duration, true)
				--if mod and not mod:IsNull() then
				--	Timers:CreateTimer(self.stack_duration, function()
				--		mod:DecrementStackCount()
				--	end)
				--end
			end
		end
	end
	EmitSoundOnLocationWithCaster(caster:GetAbsOrigin(), "Hero_PrimalBeast.Pulverize.Impact", caster)
	local pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_primal_beast/primal_beast_pulverize_hit.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(pfx, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(pfx, 1, Vector(self.radius, 0, 0))
	ParticleManager:SetParticleControl(pfx, 3, caster:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(pfx)
end

modifier_primal_beast_pulverize_custom_debuff = class({
	IsHidden = function() return false end,
	IsPurgable = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE
	} end,
	GetModifierDamageOutgoing_Percentage = function(self) return self.dmg_red_pct_per_stack * self:GetStackCount() end
})

function modifier_primal_beast_pulverize_custom_debuff:OnCreated()
	if not IsServer() then return end
	self.ability = self:GetAbility()
	self.dmg_red_pct_per_stack = self.ability:GetSpecialValueFor("dmg_red_pct_per_stack") * -1
	self:SetHasCustomTransmitterData(true)
end

function modifier_primal_beast_pulverize_custom_debuff:AddCustomTransmitterData()
	return {
		dmg_per_pct_per_stack = self.dmg_per_pct_per_stack
	}
end

function modifier_primal_beast_pulverize_custom_debuff:HandleCustomTransmitterData(data)
	self.dmg_per_pct_per_stack = data.dmg_per_pct_per_stack
end