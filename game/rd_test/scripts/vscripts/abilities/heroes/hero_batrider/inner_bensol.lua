LinkLuaModifier("modifier_batrider_inner_bensol", "abilities/heroes/hero_batrider/inner_bensol", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_batrider_inner_bensol_debuff", "abilities/heroes/hero_batrider/inner_bensol", LUA_MODIFIER_MOTION_NONE)

batrider_inner_bensol = class({
	GetIntrinsicModifierName = function() return "modifier_batrider_inner_bensol" end
})

modifier_batrider_inner_bensol = class({
	IsHidden = function(self) return self:GetStackCount() < 1 end,
	IsPurgable = function() return false end,
	DeclareFunctions = function() return {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE
	} end,
})

function modifier_batrider_inner_bensol:OnCreated()
	self.ability = self:GetAbility()
	self.ability_damage = self.ability:GetAbilityDamageType()
	self.max_stacks = self.ability:GetSpecialValueFor("max_stacks")
	self.debuff_duration = self.ability:GetSpecialValueFor("debuff_duration")
	self.damage_per_stack = self.ability:GetSpecialValueFor("damage_per_stack")
end

function modifier_batrider_inner_bensol:OnRefresh()
	self:OnCreated()
end

function modifier_batrider_inner_bensol:OnTakeDamage(keys)
	if not IsServer() then return end
	local caster = self:GetCaster()
	local attacker = keys.attacker
	local target = keys.unit
	local inflictor = keys.inflictor
	
	if inflictor and inflictor ~= self.ability and attacker == caster and target and not (target:IsMagicImmune() or caster:PassivesDisabled() or target:IsBuilding()) then
		local modifier = target:AddNewModifier(caster, self.ability, "modifier_batrider_inner_bensol_debuff", {duration = self.debuff_duration})
		local stack_count = modifier:GetStackCount()
		
		if stack_count > 0 then
			local damage = self.damage_per_stack * stack_count
			local damageTable = {
		        attacker = caster,
		        victim = target,
		        damage = damage,
		        damage_type = self.ability_damage,
		        ability = self.ability,
		    }	
			ApplyDamage(damageTable)
		end	

		if stack_count < self.max_stacks then
			modifier:IncrementStackCount()
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

modifier_batrider_inner_bensol_debuff = class({
	IsHidden = function(self) return false end,
	IsPurgable = function() return true end,
	IsDebuff = function() return true end,
})

function modifier_batrider_inner_bensol:GetTexture()
	return self:GetAbility():GetAbilityTextureName()
end

