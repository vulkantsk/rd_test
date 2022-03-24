creature_nether_blast = class({
    GetAOERadius = function(self)
        return self:GetSpecialValueFor("radius")
    end
})

function creature_nether_blast:Precache(context)
	PrecacheResource("particle", "particles/units/heroes/hero_pugna/pugna_netherblast_pre.vpcf", context)
    PrecacheResource("particle", "particles/units/heroes/hero_pugna/pugna_netherblast.vpcf", context)
    PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_pugna.vsndevts", context)
end

function creature_nether_blast:OnSpellStart()
    if(not IsServer()) then
        return
    end
    local caster = self:GetCaster()
	local target_point = self:GetCursorPosition()
    local casterTeam = caster:GetTeamNumber()
	local blast_delay = self:GetSpecialValueFor("delay")
	local damage = self:GetSpecialValueFor("blast_damage")
	local damage_buildings = damage * (self:GetSpecialValueFor("structure_damage_pct") / 100)
    local radius = self:GetSpecialValueFor("radius")
    local particle_pre_blast_fx = ParticleManager:CreateParticleForTeam("particles/units/heroes/hero_pugna/pugna_netherblast_pre.vpcf", PATTACH_CUSTOMORIGIN, caster, casterTeam)
	ParticleManager:SetParticleControl(particle_pre_blast_fx, 0, target_point)
	ParticleManager:SetParticleControl(particle_pre_blast_fx, 1, Vector(radius, blast_delay, 1))
	ParticleManager:ReleaseParticleIndex(particle_pre_blast_fx)
    EmitSoundOnLocationForAllies(caster:GetAbsOrigin(), "Hero_Pugna.NetherBlastPreCast", caster)
    local damageTable = {
        victim = nil,
        damage = 0,
        damage_type = self:GetAbilityDamageType(),
        attacker = caster,
        ability = self
    }
    Timers:CreateTimer(blast_delay, function()
		if(self and self:IsNull() == false and caster and caster:IsNull() == false) then
			local enemies = FindUnitsInRadius(
				casterTeam,
				target_point,
				nil,
				radius,
				self:GetAbilityTargetTeam(),
				self:GetAbilityTargetType(),
				self:GetAbilityTargetFlags(),
				FIND_ANY_ORDER,
				false
			)
			for _, enemy in pairs(enemies) do
				if(enemy:IsBuilding() == true) then
					damageTable.damage = damage_buildings
				else
					damageTable.damage = damage
				end
				damageTable.victim = enemy
				ApplyDamage(damageTable)
			end
			local particle_blast_fx = ParticleManager:CreateParticle("particles/units/heroes/hero_pugna/pugna_netherblast.vpcf", PATTACH_ABSORIGIN, caster)
			ParticleManager:SetParticleControl(particle_blast_fx, 0, target_point)
			ParticleManager:SetParticleControl(particle_blast_fx, 1, Vector(radius, 0, 0))
			ParticleManager:ReleaseParticleIndex(particle_blast_fx)
			EmitSoundOn("Hero_Pugna.NetherBlast", caster)
		end
    end, self)
end

killer_nether_blast = class(creature_nether_blast)
necrolyte_skeleton_mage_summon_nether_blast = class(creature_nether_blast)