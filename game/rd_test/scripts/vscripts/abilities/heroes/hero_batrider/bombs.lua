LinkLuaModifier("modifier_batrider_bombs", "abilities/heroes/hero_batrider/bombs", LUA_MODIFIER_MOTION_NONE)

batrider_bombs = class({
	GetChannelTime = function(self) return self:GetSpecialValueFor("duration") end
})

function batrider_bombs:CastFilterResult()
	if not IsServer() then return end
	local caster = self:GetCaster()
	if caster:HasAbility("batrider_bomb") then
		if caster:FindAbilityByName("batrider_bomb"):GetLevel() > 0 then
			return UF_SUCCESS
		end
	end
	return UF_FAIL_CUSTOM
end

function batrider_bombs:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_batrider_bombs", {duration = self:GetSpecialValueFor("duration")})
end

function batrider_bombs:OnChannelFinish(bInterrupted)
	if bInterrupted then
		self:GetCaster():RemoveModifierByName("modifier_batrider_bombs")
	end
end

modifier_batrider_bombs = class({
	IsHidden = function() return true end,
	IsPurgable = function() return false end
})

function modifier_batrider_bombs:OnCreated()
	if not IsServer() then return end
	self.ability = self:GetAbility()
	self.radius = self.ability:GetSpecialValueFor("radius")
	self.bombs_count = self.ability:GetSpecialValueFor("bombs_count")
	self.interval = self.ability:GetSpecialValueFor("interval")
	self.target_team = self.ability:GetAbilityTargetTeam()
	self.target_type = self.ability:GetAbilityTargetType()
	self.target_flags = self.ability:GetAbilityTargetFlags() or 0
	self:StartIntervalThink(self.interval)
end

function modifier_batrider_bombs:OnIntervalThink()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local nearby_enemies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, self.radius, self.target_team, self.target_type, self.target_flags, 0, false)
	if #nearby_enemies > 0 then
		local point = nearby_enemies[math.random(1, #nearby_enemies)]:GetAbsOrigin()
		for i = 1, self.bombs_count do
			caster:FindAbilityByName("batrider_bomb"):OnSpellStart(point)
		end
	end
end