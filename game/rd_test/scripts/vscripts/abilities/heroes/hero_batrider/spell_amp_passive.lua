LinkLuaModifier("modifier_batrider_spell_amp_passive", "abilities/heroes/hero_batrider/spell_amp_passive", LUA_MODIFIER_MOTION_NONE)

batrider_spell_amp_passive = class({
	GetIntrinsicModifierName = function() return "modifier_batrider_spell_amp_passive" end
})

modifier_batrider_spell_amp_passive = class({
	IsHidden = function(self) return self:GetStackCount() < 1 end,
	IsPurgable = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE
	} end,
	GetModifierSpellAmplify_Percentage = function(self) return self:GetStackCount() * self.spell_amp_per_stack end
})

function modifier_batrider_spell_amp_passive:OnCreated()
	self.ability = self:GetAbility()
	self.max_stacks = self.ability:GetSpecialValueFor("max_stacks")
	self.stack_duration = self.ability:GetSpecialValueFor("stack_duration")
	self.spell_amp_per_stack = self.ability:GetSpecialValueFor("spell_amp_per_stack")
end

function modifier_batrider_spell_amp_passive:OnRefresh()
	self:OnCreated()
end

function modifier_batrider_spell_amp_passive:OnTakeDamage(keys)
	if not IsServer() then return end
	local caster = self:GetCaster()
	local attacker = keys.attacker
	local target = keys.unit
	local inflictor = keys.inflictor
	local mod = caster:FindModifierByName("modifier_batrider_spell_amp_passive")
	if inflictor and attacker == caster and target and isAllowed(inflictor) and not (target:IsMagicImmune() or caster:PassivesDisabled() or target:IsBuilding()) then
		if caster:GetModifierStackCount("modifier_batrider_spell_amp_passive", caster) < self.max_stacks then
			mod:IncrementStackCount()
			Timers:CreateTimer(self.stack_duration, function()
				if (mod and not mod:IsNull()) then
					mod:DecrementStackCount()
				end
			end)
		end
	end
end

function isAllowed(ability)
	local ability_name = ability:GetAbilityName()
	local allowed_abilities = {
		"batrider_fireball",
		"batrider_bomb",
		"batrider_bombs"
	}
	for _, abil in pairs(allowed_abilities) do
		if ability_name == abil then
			return true
		end
	end
	return false
end