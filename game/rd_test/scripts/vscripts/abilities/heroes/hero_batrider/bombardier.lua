LinkLuaModifier("modifier_batrider_bombardier", "abilities/heroes/hero_batrider/bombardier", LUA_MODIFIER_MOTION_NONE)

batrider_bombardier = class({
	GetChannelTime = function(self) return self:GetSpecialValueFor("duration") end
})

function batrider_bombardier:CastFilterResult()
	if not IsServer() then return end
	local caster = self:GetCaster()
	if caster:HasAbility("batrider_bomb") then
		if caster:FindAbilityByName("batrider_bomb"):GetLevel() > 0 then
			return UF_SUCCESS
		end
	end
	return UF_FAIL_CUSTOM
end

function batrider_bombardier:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_batrider_bombardier", {duration = self:GetSpecialValueFor("duration")})
end

function batrider_bombardier:OnChannelFinish(bInterrupted)
	if bInterrupted then
		self:GetCaster():RemoveModifierByName("modifier_batrider_bombardier")
	end
end

modifier_batrider_bombardier = class({
	IsHidden = function() return true end,
	IsPurgable = function() return false end
})

function modifier_batrider_bombardier:OnCreated()
	if not IsServer() then return end
	self.ability = self:GetAbility()
	self.radius = self.ability:GetSpecialValueFor("radius")
	self.bombardier_count = self.ability:GetSpecialValueFor("bombs_count")
	self.interval = self.ability:GetSpecialValueFor("interval")
	self.target_team = self.ability:GetAbilityTargetTeam()
	self.target_type = self.ability:GetAbilityTargetType()
	self.target_flags = self.ability:GetAbilityTargetFlags() or 0
	self:StartIntervalThink(self.interval)
end

function modifier_batrider_bombardier:OnIntervalThink()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local nearby_enemies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, self.radius, self.target_team, self.target_type, self.target_flags, 0, false)
	if #nearby_enemies > 0 then
		local point = nearby_enemies[math.random(1, #nearby_enemies)]:GetAbsOrigin()
		for i = 1, self.bombardier_count do
			caster:FindAbilityByName("batrider_bomb"):OnSpellStart(point)
		end
	end
end