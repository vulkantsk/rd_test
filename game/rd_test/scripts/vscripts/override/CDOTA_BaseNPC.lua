function CDOTA_BaseNPC:IsBoss()
	if(self.spawnIsBoss) then
		return true
	end
	return false
end

function CDOTA_BaseNPC:SetIsBoss(state)
    if(state ~= true and state ~= false) then
		Debug_PrintError("CDOTA_BaseNPC.SetIsBoss expected state to be true or false. Got "..tostring(state).."("..type(state)..")")
        return
    end
    self.spawnIsBoss = state
end

function CDOTA_BaseNPC:IsNeutralCreep()
	if(self.spawnIsNeutralCreep) then
		return true
	end
	return false
end

function CDOTA_BaseNPC:SetIsNeutralCreep(state)
    if(state ~= true and state ~= false) then
		Debug_PrintError("CDOTA_BaseNPC.SetIsNeutralCreep expected state to be true or false. Got "..tostring(state).."("..type(state)..")")
        return
    end
    self.spawnIsNeutralCreep = state
end

function CDOTA_BaseNPC:SetIsBuilding(value)
	if(not self or self:IsNull() == true) then
		return
	end
	self._isCustomBuilding = value
end

function CDOTA_BaseNPC:GetReductionFromPhysicalArmor()
	local armor = self:GetPhysicalArmorValue(false)
	return (0.06 * armor) / (1 + 0.06 * math.abs(armor))
end

-- Return white + green dmg, ignoring crits and rest aa dmg modifiers
function CDOTA_BaseNPC:GetAverageTrueAttackDamageDisplay()
	local attackDamage = 0
	if(not self or self:IsNull() == true) then
		return attackDamage
	end
	attackDamage = self:GetAttackDamage()
	local greenBonus = 0
	local modifiers = self:FindAllModifiers()
	local finalMultiplier = 1
	local eventData = {
		attacker = self,
		damage = 0,
		damage_type = DAMAGE_TYPE_PHYSICAL,
		damage_category = DOTA_DAMAGE_CATEGORY_ATTACK,
		damage_flags = DOTA_DAMAGE_FLAG_NONE,
		inflictor = nil,
		original_damage = 0,
		ranged_attack = false,
		target = nil,
		no_attack_cooldown = false,
		record = -1,
		fail_type = DOTA_ATTACK_RECORD_FAIL_NO
	}
	for _, modifier in pairs(modifiers) do
		if(modifier.GetModifierPreAttack_BonusDamage) then
			greenBonus = (tonumber(modifier:GetModifierPreAttack_BonusDamage(eventData) or 0) or 0)
		end
		if(modifier.GetModifierBaseDamageOutgoing_Percentage) then
			greenBonus = attackDamage * ((tonumber(modifier:GetModifierBaseDamageOutgoing_Percentage(eventData) or 0) or 0) / 100)
		end
		if(modifier.GetModifierBaseDamageOutgoing_PercentageUnique) then
			greenBonus = attackDamage * ((tonumber(modifier:GetModifierBaseDamageOutgoing_PercentageUnique(eventData) or 0) or 0) / 100)
		end
		if(modifier.GetModifierDamageOutgoing_Percentage) then
			finalMultiplier = finalMultiplier + ((tonumber(modifier:GetModifierDamageOutgoing_Percentage(eventData) or 0) or 0) / 100)
		end
	end
	return (attackDamage + greenBonus) * finalMultiplier
end

function CDOTA_BaseNPC:GetBaseAttackTimeNoOverride()
	if(not self or self:IsNull() == true) then
		return 1.7
	end
	local batInKV = tonumber(GetUnitKV(self:GetUnitName(), "AttackRate"))
	if(not batInKV) then
		Debug_PrintError(self:GetUnitName().." are missing AttackRate in KV or valve break something.")
		return 1.7
	end
	return batInKV
end

function CDOTA_BaseNPC:IsCanBeDominated()
	if(not self or self:IsNull() == true) then
		return true
	end
	local result = tonumber(GetUnitKV(self:GetUnitName(), "CanBeDominated")) or 1
	return result == 1
end

-- Custom motion controllers stuff
function CDOTA_BaseNPC:IsMotionControlled()
	if(not self or self:IsNull()) then
		return false
	end
	if(self._customMotionControllerModifier) then
		return true
	end
	return false
end

function CDOTA_BaseNPC:InterruptMotionControllers(findClearSpace)
	if(not self or self:IsNull()) then
		Debug_PrintError("CDOTA_BaseNPC:InterruptMotionControllers attempt to interrupt motion controller for nil or null npc.")
		return
	end
	self:_DestroyMotionController(true)
	if(findClearSpace == true) then
		FindClearSpaceForUnit(self, self:GetAbsOrigin(), true)
	else
		self:SetAbsOrigin(GetGroundPosition(self:GetAbsOrigin(), self))
	end
end

-- Don't use that, use modifier:StartMotionController() instead
function CDOTA_BaseNPC:_ApplyMotionController(modifier)
	if(not self or self:IsNull()) then
		Debug_PrintError("CDOTA_BaseNPC:_ApplyMotionController attempt to apply motion controller for nil or null npc.")
		return false
	end
	if(self:IsMotionControlled() == true) then
		if(modifier:GetMotionPriority() >= self._customMotionControllerModifier:GetMotionPriority()) then
			self:_DestroyMotionController(true)
		else
			return false
		end
	end
	self._customMotionControllerModifier = modifier
	self._customMotionControllerTimer = Timers:CreateTimer(0, function()
		if(not self or self:IsNull() or not self._customMotionControllerModifier or self._customMotionControllerModifier:IsNull() == true) then 
			return 
		end
		local frameTime = FrameTime()
		self._customMotionControllerModifier:OnControlledMotion(self, frameTime) 
		return frameTime
	end)
	return true
end

-- And this too, use modifier:StopMotionController() instead
function CDOTA_BaseNPC:_DestroyMotionController(isInterrupt)
	if(not self or self:IsNull()) then
		Debug_PrintError("CDOTA_BaseNPC:_DestroyMotionController() attempt to destroy motion controller for nil or null npc.")
		return
	end
	if(self._customMotionControllerTimer) then
		Timers:RemoveTimer(self._customMotionControllerTimer)
	end
	FindClearSpaceForUnit(self, self:GetAbsOrigin(), true)
	if(isInterrupt == true) then
		if(self._customMotionControllerModifier and self._customMotionControllerModifier:IsNull() == false) then 
			self._customMotionControllerModifier:OnControlledMotionInterrupted()
		end
	end
	self._customMotionControllerModifier = nil
end

function CDOTA_BaseNPC:SetIsCustomStatsModifierJustAdded(value)
	if(not self or self:IsNull() == true) then
		return
	end
	if(value == true) then
		self._isCustomStatsModifierWasJustAdded = true
		return
	end
	self._isCustomStatsModifierWasJustAdded = nil
end

function CDOTA_BaseNPC:IsCustomStatsModifierJustAdded()
	if(not self or self:IsNull() == true) then
		return
	end
	return self._isCustomStatsModifierWasJustAdded or false
end

function CDOTA_BaseNPC:AddCustomStatsModifier()
	if(not self or self:IsNull() == true) then
		return
	end
	if(self:IsCustomStatsModifierJustAdded() == true) then
		return
	end
	self:SetIsCustomStatsModifierJustAdded(true)
	self._customStatsModifier = self:AddNewModifier(self, nil, "modifier_roshdef_custom_stats_tracker", {duration = -1})
	self:SetIsCustomStatsModifierJustAdded(false)
	return self._customStatsModifier
end

function CDOTA_BaseNPC:GetCustomStatsModifier()
	if(not self or self:IsNull() == true) then
		return nil
	end
	return self._customStatsModifier
end

-- Chicken game chickens, dps test dummy
function CDOTA_BaseNPC:IsInvalidTargetForInfiniteStackingEffects()
	if(not self or self:IsNull() == true) then
		return false
	end
	if(self.m_bChecken) then
		return true
	end
	return false
end

local ATTACK_PRIORITY_ENUM = {
	ROSHDEF_NPC_LOW_ATTACK_PRIORITY = 1,
	ROSHDEF_NPC_NORMAL_ATTACK_PRIORITY = 2,
	ROSHDEF_NPC_HIGH_ATTACK_PRIORITY = 3
}

for k,v in pairs(ATTACK_PRIORITY_ENUM) do
	_G[k] = v
end

function CDOTA_BaseNPC:GetAttackPriority()
	if(not self or self:IsNull() == true) then
		return ROSHDEF_NPC_NORMAL_ATTACK_PRIORITY
	end
	if(self:IsHighAttackPriority() == true) then
		return ROSHDEF_NPC_HIGH_ATTACK_PRIORITY
	end
	if(self:IsLowAttackPriority() == true) then
		return ROSHDEF_NPC_LOW_ATTACK_PRIORITY
	end
	return ROSHDEF_NPC_NORMAL_ATTACK_PRIORITY
end

function CDOTA_BaseNPC:IsHighAttackPriority()
	if(not self or self:IsNull() == true) then
		return false
	end
	return self._isHighAttackPriority or false
end

function CDOTA_BaseNPC:SetIsHighAttackPriority(state)
	if(not self or self:IsNull() == true) then
		return
	end
	if(state ~= true and state ~= false) then
		Debug_PrintError("CDOTA_BaseNPC:SetIsHighAttackPriority expected state to be true or false. Got "..tostring(state))
		return
	end
	self._isHighAttackPriority = state
end

-- This shit will keep deal damage until hero dead or begin reincarnation...
-- Valve npc:ForceKill is actully deal pure damage = max hp. They fucking hardcoded for every insta death skill removing of modifiers that can block death...
function CDOTA_BaseNPC:TrueKill(state)
	if(not self or self:IsNull() == true) then
		return
	end
	Timers:CreateTimer(0, function()
		if(not self or self:IsNull() == true) then
			return nil
		else
			self:ForceKill(state)
			-- Reincarnation shit
			if(state == true) then
				if(self:IsReincarnating() == true) then
					return nil
				else
					if(self:IsAlive() == false) then
						return nil
					end
				end
				return 0.25
			else
				if(self:IsAlive() == true) then
					return 0.25
				end
			end
		end
	end, self)
end

local function LoadUnitsAttackCapabilitesFromKV()
	local result = {}
	local heroes = LoadKeyValues("scripts/npc/npc_heroes.txt")
	for heroName, data in pairs(heroes) do
		if(data and type(data) == "table" and data["AttackCapabilities"]) then
			result[heroName] = _G[data["AttackCapabilities"]] or DOTA_UNIT_CAP_NO_ATTACK
		end
	end
	local heroesCustom = LoadKeyValues("scripts/npc/npc_heroes_custom.txt")
	for heroName, data in pairs(heroesCustom) do
		if(data and type(data) == "table" and data["AttackCapabilities"]) then
			result[heroName] = _G[data["AttackCapabilities"]] or DOTA_UNIT_CAP_NO_ATTACK
		end
	end
	local units = LoadKeyValues("scripts/npc/npc_units.txt")
	for unitName, data in pairs(units) do
		if(data and type(data) == "table" and data["AttackCapabilities"]) then
			result[unitName] = _G[data["AttackCapabilities"]] or DOTA_UNIT_CAP_NO_ATTACK
		end
	end
	local unitsCustom = LoadKeyValues("scripts/npc/npc_units_custom.txt")
	for unitName, data in pairs(units) do
		if(data and type(data) == "table" and data["AttackCapabilities"]) then
			result[unitName] = _G[data["AttackCapabilities"]] or DOTA_UNIT_CAP_NO_ATTACK 
		end
	end
	return result
end

local UnitsAttackCapabilitiesKV = LoadUnitsAttackCapabilitesFromKV()

function CDOTA_BaseNPC:GetAttackCapabilityNoOverride()
	if(not self or self:IsNull()) then
		return DOTA_UNIT_CAP_NO_ATTACK
	end
	local attackCapability = UnitsAttackCapabilitiesKV[self:GetUnitName()]
	if(not attackCapability) then
		return DOTA_UNIT_CAP_NO_ATTACK
	end
	return attackCapability
end

-- 7.31 cause crash if something is null
if(_G._gaben731crashFixesBaseNPCInit) then
	return
end

-- Lua has 200 local variables limit...
function _OverrideBaseNPCFunctionsThird(entity)

	local vanillaPickupDroppedItem = entity.PickupDroppedItem
	entity.PickupDroppedItem = function(self, hItem, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.PickupDroppedItem called for null entity.")
			return
		end
		if (type(hItem) ~= "table" or hItem.IsNull == nil or hItem:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.PickupDroppedItem expected hItem as valid not null entity.")
			return
		end
		if (vanillaPickupDroppedItem) then
			vanillaPickupDroppedItem(self, hItem, ...)
		end

	end

	local vanillaPickupRune = entity.PickupRune
	entity.PickupRune = function(self, hItem, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.PickupRune called for null entity.")
			return
		end
		if (type(hItem) ~= "table" or hItem.IsNull == nil or hItem:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.PickupRune expected hItem as valid not null entity.")
			return
		end
		if (vanillaPickupRune) then
			vanillaPickupRune(self, hItem, ...)
		end

	end

	local vanillaPlayVCD = entity.PlayVCD
	entity.PlayVCD = function(self, pVCD, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.PlayVCD called for null entity.")
			return
		end
		if (type(pVCD) ~= "string") then
			Debug_PrintError("CDOTA_BaseNPC.PlayVCD expected pVCD as string.")
			return
		end
		if (vanillaPlayVCD) then
			vanillaPlayVCD(self, pVCD, ...)
		end

	end

	local vanillaProvidesVision = entity.ProvidesVision
	entity.ProvidesVision = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.ProvidesVision called for null entity.")
			return false
		end
		if (vanillaProvidesVision) then
			return vanillaProvidesVision(self, ...)
		end
		return false
	end

	local vanillaPurge = entity.Purge
	entity.Purge = function(self, bRemovePositiveBuffs, bRemoveDebuffs, bFrameOnly, bRemoveStuns, bRemoveExceptions, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.Purge called for null entity.")
			return
		end
		if (bRemovePositiveBuffs ~= true and bRemovePositiveBuffs ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.Purge expected bRemovePositiveBuffs as boolean.")
			return
		end
		if (bRemoveDebuffs ~= true and bRemoveDebuffs ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.Purge expected bRemoveDebuffs as boolean.")
			return
		end
		if (bFrameOnly ~= true and bFrameOnly ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.Purge expected bFrameOnly as boolean.")
			return
		end
		if (bRemoveStuns ~= true and bRemoveStuns ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.Purge expected bRemoveStuns as boolean.")
			return
		end
		if (bRemoveExceptions ~= true and bRemoveExceptions ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.Purge expected bRemoveExceptions as boolean.")
			return
		end
		if (vanillaPurge) then
			vanillaPurge(self, bRemovePositiveBuffs, bRemoveDebuffs, bFrameOnly, bRemoveStuns, bRemoveExceptions, ...)
		end

	end

	local vanillaQueueConcept = entity.QueueConcept
	entity.QueueConcept = function(self, flDelay, hCriteriaTable, hCompletionCallbackFn, hContext, hCallbackInfo, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.QueueConcept called for null entity.")
			return
		end
		flDelay = tonumber(flDelay)
		if (not flDelay) then
			Debug_PrintError("CDOTA_BaseNPC.QueueConcept expected flDelay as number.")
			return
		end
		if (type(hCriteriaTable) ~= "table" or hCriteriaTable.IsNull == nil or hCriteriaTable:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.QueueConcept expected hCriteriaTable as valid not null entity.")
			return
		end
		if (type(hCompletionCallbackFn) ~= "table" or hCompletionCallbackFn.IsNull == nil or hCompletionCallbackFn:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.QueueConcept expected hCompletionCallbackFn as valid not null entity.")
			return
		end
		if (type(hContext) ~= "table" or hContext.IsNull == nil or hContext:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.QueueConcept expected hContext as valid not null entity.")
			return
		end
		if (type(hCallbackInfo) ~= "table" or hCallbackInfo.IsNull == nil or hCallbackInfo:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.QueueConcept expected hCallbackInfo as valid not null entity.")
			return
		end
		if (vanillaQueueConcept) then
			vanillaQueueConcept(self, flDelay, hCriteriaTable, hCompletionCallbackFn, hContext, hCallbackInfo, ...)
		end

	end

	local vanillaQueueTeamConcept = entity.QueueTeamConcept
	entity.QueueTeamConcept = function(self, flDelay, hCriteriaTable, hCompletionCallbackFn, hContext, hCallbackInfo, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.QueueTeamConcept called for null entity.")
			return
		end
		flDelay = tonumber(flDelay)
		if (not flDelay) then
			Debug_PrintError("CDOTA_BaseNPC.QueueTeamConcept expected flDelay as number.")
			return
		end
		if (type(hCriteriaTable) ~= "table" or hCriteriaTable.IsNull == nil or hCriteriaTable:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.QueueTeamConcept expected hCriteriaTable as valid not null entity.")
			return
		end
		if (type(hCompletionCallbackFn) ~= "table" or hCompletionCallbackFn.IsNull == nil or hCompletionCallbackFn:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.QueueTeamConcept expected hCompletionCallbackFn as valid not null entity.")
			return
		end
		if (type(hContext) ~= "table" or hContext.IsNull == nil or hContext:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.QueueTeamConcept expected hContext as valid not null entity.")
			return
		end
		if (type(hCallbackInfo) ~= "table" or hCallbackInfo.IsNull == nil or hCallbackInfo:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.QueueTeamConcept expected hCallbackInfo as valid not null entity.")
			return
		end
		if (vanillaQueueTeamConcept) then
			vanillaQueueTeamConcept(self, flDelay, hCriteriaTable, hCompletionCallbackFn, hContext, hCallbackInfo, ...)
		end

	end

	local vanillaQueueTeamConceptNoSpectators = entity.QueueTeamConceptNoSpectators
	entity.QueueTeamConceptNoSpectators = function(self, flDelay, hCriteriaTable, hCompletionCallbackFn, hContext, hCallbackInfo, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.QueueTeamConceptNoSpectators called for null entity.")
			return
		end
		flDelay = tonumber(flDelay)
		if (not flDelay) then
			Debug_PrintError("CDOTA_BaseNPC.QueueTeamConceptNoSpectators expected flDelay as number.")
			return
		end
		if (type(hCriteriaTable) ~= "table" or hCriteriaTable.IsNull == nil or hCriteriaTable:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.QueueTeamConceptNoSpectators expected hCriteriaTable as valid not null entity.")
			return
		end
		if (type(hCompletionCallbackFn) ~= "table" or hCompletionCallbackFn.IsNull == nil or hCompletionCallbackFn:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.QueueTeamConceptNoSpectators expected hCompletionCallbackFn as valid not null entity.")
			return
		end
		if (type(hContext) ~= "table" or hContext.IsNull == nil or hContext:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.QueueTeamConceptNoSpectators expected hContext as valid not null entity.")
			return
		end
		if (type(hCallbackInfo) ~= "table" or hCallbackInfo.IsNull == nil or hCallbackInfo:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.QueueTeamConceptNoSpectators expected hCallbackInfo as valid not null entity.")
			return
		end
		if (vanillaQueueTeamConceptNoSpectators) then
			vanillaQueueTeamConceptNoSpectators(self, flDelay, hCriteriaTable, hCompletionCallbackFn, hContext, hCallbackInfo, ...)
		end

	end

	local vanillaReduceMana = entity.ReduceMana
	entity.ReduceMana = function(self, flAmount, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.ReduceMana called for null entity.")
			return
		end
		flAmount = tonumber(flAmount)
		if (not flAmount) then
			Debug_PrintError("CDOTA_BaseNPC.ReduceMana expected flAmount as number.")
			return
		end
		if (vanillaReduceMana) then
			vanillaReduceMana(self, flAmount, ...)
		end

	end

	local vanillaRemoveAbility = entity.RemoveAbility
	entity.RemoveAbility = function(self, pszAbilityName, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.RemoveAbility called for null entity.")
			return
		end
		if (type(pszAbilityName) ~= "string") then
			Debug_PrintError("CDOTA_BaseNPC.RemoveAbility expected pszAbilityName as string.")
			return
		end
		if (vanillaRemoveAbility) then
			vanillaRemoveAbility(self, pszAbilityName, ...)
		end

	end

	local vanillaRemoveAbilityByHandle = entity.RemoveAbilityByHandle
	entity.RemoveAbilityByHandle = function(self, hAbility, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.RemoveAbilityByHandle called for null entity.")
			return
		end
		if (type(hAbility) ~= "table" or hAbility.IsNull == nil or hAbility:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.RemoveAbilityByHandle expected hAbility as valid not null entity.")
			return
		end
		if (vanillaRemoveAbilityByHandle) then
			vanillaRemoveAbilityByHandle(self, hAbility, ...)
		end

	end

	local vanillaRemoveAbilityFromIndexByName = entity.RemoveAbilityFromIndexByName
	entity.RemoveAbilityFromIndexByName = function(self, pszAbilityName, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.RemoveAbilityFromIndexByName called for null entity.")
			return
		end
		if (type(pszAbilityName) ~= "string") then
			Debug_PrintError("CDOTA_BaseNPC.RemoveAbilityFromIndexByName expected pszAbilityName as string.")
			return
		end
		if (vanillaRemoveAbilityFromIndexByName) then
			vanillaRemoveAbilityFromIndexByName(self, pszAbilityName, ...)
		end

	end

	local vanillaRemoveAllModifiers = entity.RemoveAllModifiers
	entity.RemoveAllModifiers = function(self, targets, bNow, bPermanent, bDeath, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.RemoveAllModifiers called for null entity.")
			return
		end
		targets = tonumber(targets)
		if (not targets) then
			Debug_PrintError("CDOTA_BaseNPC.RemoveAllModifiers expected targets as number.")
			return
		end
		if (bNow ~= true and bNow ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.RemoveAllModifiers expected bNow as boolean.")
			return
		end
		if (bPermanent ~= true and bPermanent ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.RemoveAllModifiers expected bPermanent as boolean.")
			return
		end
		if (bDeath ~= true and bDeath ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.RemoveAllModifiers expected bDeath as boolean.")
			return
		end
		if (vanillaRemoveAllModifiers) then
			vanillaRemoveAllModifiers(self, targets, bNow, bPermanent, bDeath, ...)
		end

	end

	local vanillaRemoveAllModifiersOfName = entity.RemoveAllModifiersOfName
	entity.RemoveAllModifiersOfName = function(self, pszScriptName, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.RemoveAllModifiersOfName called for null entity.")
			return
		end
		if (type(pszScriptName) ~= "string") then
			Debug_PrintError("CDOTA_BaseNPC.RemoveAllModifiersOfName expected pszScriptName as string.")
			return
		end
		if (vanillaRemoveAllModifiersOfName) then
			vanillaRemoveAllModifiersOfName(self, pszScriptName, ...)
		end

	end

	local vanillaRemoveGesture = entity.RemoveGesture
	entity.RemoveGesture = function(self, nActivity, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.RemoveGesture called for null entity.")
			return
		end
		nActivity = tonumber(nActivity)
		if (not nActivity) then
			Debug_PrintError("CDOTA_BaseNPC.RemoveGesture expected nActivity as number.")
			return
		end
		if (vanillaRemoveGesture) then
			vanillaRemoveGesture(self, nActivity, ...)
		end

	end

	local vanillaRemoveHorizontalMotionController = entity.RemoveHorizontalMotionController
	entity.RemoveHorizontalMotionController = function(self, hBuff, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.RemoveHorizontalMotionController called for null entity.")
			return
		end
		if (type(hBuff) ~= "table" or hBuff.IsNull == nil or hBuff:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.RemoveHorizontalMotionController expected hBuff as valid not null entity.")
			return
		end
		if (vanillaRemoveHorizontalMotionController) then
			vanillaRemoveHorizontalMotionController(self, hBuff, ...)
		end

	end

	local vanillaRemoveItem = entity.RemoveItem
	entity.RemoveItem = function(self, hItem, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.RemoveItem called for null entity.")
			return
		end
		if (type(hItem) ~= "table" or hItem.IsNull == nil or hItem:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.RemoveItem expected hItem as valid not null entity.")
			return
		end
		if (vanillaRemoveItem) then
			vanillaRemoveItem(self, hItem, ...)
		end

	end

	local vanillaRemoveModifierByName = entity.RemoveModifierByName
	entity.RemoveModifierByName = function(self, pszScriptName, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.RemoveModifierByName called for null entity.")
			return
		end
		if (type(pszScriptName) ~= "string") then
			Debug_PrintError("CDOTA_BaseNPC.RemoveModifierByName expected pszScriptName as string.")
			return
		end
		if (vanillaRemoveModifierByName) then
			vanillaRemoveModifierByName(self, pszScriptName, ...)
		end

	end

	local vanillaRemoveModifierByNameAndCaster = entity.RemoveModifierByNameAndCaster
	entity.RemoveModifierByNameAndCaster = function(self, pszScriptName, hCaster, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.RemoveModifierByNameAndCaster called for null entity.")
			return
		end
		if (type(pszScriptName) ~= "string") then
			Debug_PrintError("CDOTA_BaseNPC.RemoveModifierByNameAndCaster expected pszScriptName as string.")
			return
		end
		if (type(hCaster) ~= "table" or hCaster.IsNull == nil or hCaster:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.RemoveModifierByNameAndCaster expected hCaster as valid not null entity.")
			return
		end
		if (vanillaRemoveModifierByNameAndCaster) then
			vanillaRemoveModifierByNameAndCaster(self, pszScriptName, hCaster, ...)
		end

	end

	local vanillaRemoveNoDraw = entity.RemoveNoDraw
	entity.RemoveNoDraw = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.RemoveNoDraw called for null entity.")
			return
		end
		if (vanillaRemoveNoDraw) then
			vanillaRemoveNoDraw(self, ...)
		end

	end

	local vanillaRemoveVerticalMotionController = entity.RemoveVerticalMotionController
	entity.RemoveVerticalMotionController = function(self, hBuff, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.RemoveVerticalMotionController called for null entity.")
			return
		end
		if (type(hBuff) ~= "table" or hBuff.IsNull == nil or hBuff:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.RemoveVerticalMotionController expected hBuff as valid not null entity.")
			return
		end
		if (vanillaRemoveVerticalMotionController) then
			vanillaRemoveVerticalMotionController(self, hBuff, ...)
		end

	end

	local vanillaRespawnUnit = entity.RespawnUnit
	entity.RespawnUnit = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.RespawnUnit called for null entity.")
			return
		end
		if (vanillaRespawnUnit) then
			vanillaRespawnUnit(self, ...)
		end

	end

	local vanillaScript_GetAttackRange = entity.Script_GetAttackRange
	entity.Script_GetAttackRange = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.Script_GetAttackRange called for null entity.")
			return 0
		end
		if (vanillaScript_GetAttackRange) then
			return vanillaScript_GetAttackRange(self, ...)
		end
		return 0
	end

	local vanillaScript_IsDeniable = entity.Script_IsDeniable
	entity.Script_IsDeniable = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.Script_IsDeniable called for null entity.")
			return false
		end
		if (vanillaScript_IsDeniable) then
			return vanillaScript_IsDeniable(self, ...)
		end
		return false
	end

	local vanillaSellItem = entity.SellItem
	entity.SellItem = function(self, hItem, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SellItem called for null entity.")
			return
		end
		if (type(hItem) ~= "table" or hItem.IsNull == nil or hItem:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SellItem expected hItem as valid not null entity.")
			return
		end
		if (vanillaSellItem) then
			vanillaSellItem(self, hItem, ...)
		end

	end

	local vanillaSetAbilityByIndex = entity.SetAbilityByIndex
	entity.SetAbilityByIndex = function(self, hAbility, iIndex, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetAbilityByIndex called for null entity.")
			return
		end
		if (type(hAbility) ~= "table" or hAbility.IsNull == nil or hAbility:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetAbilityByIndex expected hAbility as valid not null entity.")
			return
		end
		iIndex = tonumber(iIndex)
		if (not iIndex) then
			Debug_PrintError("CDOTA_BaseNPC.SetAbilityByIndex expected iIndex as number.")
			return
		end
		if (vanillaSetAbilityByIndex) then
			vanillaSetAbilityByIndex(self, hAbility, iIndex, ...)
		end

	end

	local vanillaSetAcquisitionRange = entity.SetAcquisitionRange
	entity.SetAcquisitionRange = function(self, nRange, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetAcquisitionRange called for null entity.")
			return
		end
		nRange = tonumber(nRange)
		if (not nRange) then
			Debug_PrintError("CDOTA_BaseNPC.SetAcquisitionRange expected nRange as number.")
			return
		end
		if (vanillaSetAcquisitionRange) then
			vanillaSetAcquisitionRange(self, nRange, ...)
		end

	end

	local vanillaSetAdditionalBattleMusicWeight = entity.SetAdditionalBattleMusicWeight
	entity.SetAdditionalBattleMusicWeight = function(self, flWeight, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetAdditionalBattleMusicWeight called for null entity.")
			return
		end
		flWeight = tonumber(flWeight)
		if (not flWeight) then
			Debug_PrintError("CDOTA_BaseNPC.SetAdditionalBattleMusicWeight expected flWeight as number.")
			return
		end
		if (vanillaSetAdditionalBattleMusicWeight) then
			vanillaSetAdditionalBattleMusicWeight(self, flWeight, ...)
		end

	end

	local vanillaSetAggroTarget = entity.SetAggroTarget
	entity.SetAggroTarget = function(self, hAggroTarget, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetAggroTarget called for null entity.")
			return
		end
		if (type(hAggroTarget) ~= "table" or hAggroTarget.IsNull == nil or hAggroTarget:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetAggroTarget expected hAggroTarget as valid not null entity.")
			return
		end
		if (vanillaSetAggroTarget) then
			vanillaSetAggroTarget(self, hAggroTarget, ...)
		end

	end

	local vanillaSetAttackCapability = entity.SetAttackCapability
	entity.SetAttackCapability = function(self, iAttackCapabilities, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetAttackCapability called for null entity.")
			return
		end
		iAttackCapabilities = tonumber(iAttackCapabilities)
		if (not iAttackCapabilities) then
			Debug_PrintError("CDOTA_BaseNPC.SetAttackCapability expected iAttackCapabilities as number.")
			return
		end
		if (vanillaSetAttackCapability) then
			vanillaSetAttackCapability(self, iAttackCapabilities, ...)
		end

	end

	local vanillaSetAttacking = entity.SetAttacking
	entity.SetAttacking = function(self, hAttackTarget, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetAttacking called for null entity.")
			return
		end
		if (type(hAttackTarget) ~= "table" or hAttackTarget.IsNull == nil or hAttackTarget:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetAttacking expected hAttackTarget as valid not null entity.")
			return
		end
		if (vanillaSetAttacking) then
			vanillaSetAttacking(self, hAttackTarget, ...)
		end

	end

	local vanillaSetBaseAttackTime = entity.SetBaseAttackTime
	entity.SetBaseAttackTime = function(self, flBaseAttackTime, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetBaseAttackTime called for null entity.")
			return
		end
		flBaseAttackTime = tonumber(flBaseAttackTime)
		if (not flBaseAttackTime) then
			Debug_PrintError("CDOTA_BaseNPC.SetBaseAttackTime expected flBaseAttackTime as number.")
			return
		end
		if (vanillaSetBaseAttackTime) then
			vanillaSetBaseAttackTime(self, flBaseAttackTime, ...)
		end

	end

	local vanillaSetBaseDamageMax = entity.SetBaseDamageMax
	entity.SetBaseDamageMax = function(self, nMax, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetBaseDamageMax called for null entity.")
			return
		end
		nMax = tonumber(nMax)
		if (not nMax) then
			Debug_PrintError("CDOTA_BaseNPC.SetBaseDamageMax expected nMax as number.")
			return
		end
		if (vanillaSetBaseDamageMax) then
			vanillaSetBaseDamageMax(self, nMax, ...)
		end

	end

	local vanillaSetBaseDamageMin = entity.SetBaseDamageMin
	entity.SetBaseDamageMin = function(self, nMin, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetBaseDamageMin called for null entity.")
			return
		end
		nMin = tonumber(nMin)
		if (not nMin) then
			Debug_PrintError("CDOTA_BaseNPC.SetBaseDamageMin expected nMin as number.")
			return
		end
		if (vanillaSetBaseDamageMin) then
			vanillaSetBaseDamageMin(self, nMin, ...)
		end

	end

	local vanillaSetBaseHealthRegen = entity.SetBaseHealthRegen
	entity.SetBaseHealthRegen = function(self, flHealthRegen, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetBaseHealthRegen called for null entity.")
			return
		end
		flHealthRegen = tonumber(flHealthRegen)
		if (not flHealthRegen) then
			Debug_PrintError("CDOTA_BaseNPC.SetBaseHealthRegen expected flHealthRegen as number.")
			return
		end
		if (vanillaSetBaseHealthRegen) then
			vanillaSetBaseHealthRegen(self, flHealthRegen, ...)
		end

	end

	local vanillaSetBaseMagicalResistanceValue = entity.SetBaseMagicalResistanceValue
	entity.SetBaseMagicalResistanceValue = function(self, flMagicalResistanceValue, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetBaseMagicalResistanceValue called for null entity.")
			return
		end
		flMagicalResistanceValue = tonumber(flMagicalResistanceValue)
		if (not flMagicalResistanceValue) then
			Debug_PrintError("CDOTA_BaseNPC.SetBaseMagicalResistanceValue expected flMagicalResistanceValue as number.")
			return
		end
		if (vanillaSetBaseMagicalResistanceValue) then
			vanillaSetBaseMagicalResistanceValue(self, flMagicalResistanceValue, ...)
		end

	end

	local vanillaSetBaseManaRegen = entity.SetBaseManaRegen
	entity.SetBaseManaRegen = function(self, flManaRegen, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetBaseManaRegen called for null entity.")
			return
		end
		flManaRegen = tonumber(flManaRegen)
		if (not flManaRegen) then
			Debug_PrintError("CDOTA_BaseNPC.SetBaseManaRegen expected flManaRegen as number.")
			return
		end
		if (vanillaSetBaseManaRegen) then
			vanillaSetBaseManaRegen(self, flManaRegen, ...)
		end

	end

	local vanillaSetBaseMaxHealth = entity.SetBaseMaxHealth
	entity.SetBaseMaxHealth = function(self, flBaseMaxHealth, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetBaseMaxHealth called for null entity.")
			return
		end
		flBaseMaxHealth = tonumber(flBaseMaxHealth)
		if (not flBaseMaxHealth) then
			Debug_PrintError("CDOTA_BaseNPC.SetBaseMaxHealth expected flBaseMaxHealth as number.")
			return
		end
		if (vanillaSetBaseMaxHealth) then
			vanillaSetBaseMaxHealth(self, flBaseMaxHealth, ...)
		end

	end

	local vanillaSetBaseMoveSpeed = entity.SetBaseMoveSpeed
	entity.SetBaseMoveSpeed = function(self, iMoveSpeed, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetBaseMoveSpeed called for null entity.")
			return
		end
		iMoveSpeed = tonumber(iMoveSpeed)
		if (not iMoveSpeed) then
			Debug_PrintError("CDOTA_BaseNPC.SetBaseMoveSpeed expected iMoveSpeed as number.")
			return
		end
		if (vanillaSetBaseMoveSpeed) then
			vanillaSetBaseMoveSpeed(self, iMoveSpeed, ...)
		end

	end

	local vanillaSetCanSellItems = entity.SetCanSellItems
	entity.SetCanSellItems = function(self, bCanSell, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetCanSellItems called for null entity.")
			return
		end
		if (bCanSell ~= true and bCanSell ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.SetCanSellItems expected bCanSell as boolean.")
			return
		end
		if (vanillaSetCanSellItems) then
			vanillaSetCanSellItems(self, bCanSell, ...)
		end

	end

	local vanillaSetControllableByPlayer = entity.SetControllableByPlayer
	entity.SetControllableByPlayer = function(self, nPlayerID, bSkipAdjustingPosition, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetControllableByPlayer called for null entity.")
			return
		end
		nPlayerID = tonumber(nPlayerID)
		if (not nPlayerID) then
			Debug_PrintError("CDOTA_BaseNPC.SetControllableByPlayer expected nPlayerID as number.")
			return
		end
		if (bSkipAdjustingPosition ~= true and bSkipAdjustingPosition ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.SetControllableByPlayer expected bSkipAdjustingPosition as boolean.")
			return
		end
		if (vanillaSetControllableByPlayer) then
			vanillaSetControllableByPlayer(self, nPlayerID, bSkipAdjustingPosition, ...)
		end

	end

	local vanillaSetCursorCastTarget = entity.SetCursorCastTarget
	entity.SetCursorCastTarget = function(self, hEntity, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetCursorCastTarget called for null entity.")
			return
		end
		if (type(hEntity) ~= "table" or hEntity.IsNull == nil or hEntity:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetCursorCastTarget expected hEntity as valid not null entity.")
			return
		end
		if (vanillaSetCursorCastTarget) then
			vanillaSetCursorCastTarget(self, hEntity, ...)
		end

	end

	local vanillaSetCursorPosition = entity.SetCursorPosition
	entity.SetCursorPosition = function(self, vLocation, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetCursorPosition called for null entity.")
			return
		end
		if (type(vLocation) ~= "userdata") then
			Debug_PrintError("CDOTA_BaseNPC.SetCursorPosition expected vLocation as Vector.")
			return
		end
		if (vanillaSetCursorPosition) then
			vanillaSetCursorPosition(self, vLocation, ...)
		end

	end

	local vanillaSetCursorTargetingNothing = entity.SetCursorTargetingNothing
	entity.SetCursorTargetingNothing = function(self, bTargetingNothing, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetCursorTargetingNothing called for null entity.")
			return
		end
		if (bTargetingNothing ~= true and bTargetingNothing ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.SetCursorTargetingNothing expected bTargetingNothing as boolean.")
			return
		end
		if (vanillaSetCursorTargetingNothing) then
			vanillaSetCursorTargetingNothing(self, bTargetingNothing, ...)
		end

	end

	local vanillaSetCustomHealthLabel = entity.SetCustomHealthLabel
	entity.SetCustomHealthLabel = function(self, pLabel, r, g, b, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetCustomHealthLabel called for null entity.")
			return
		end
		if (type(pLabel) ~= "string") then
			Debug_PrintError("CDOTA_BaseNPC.SetCustomHealthLabel expected pLabel as string.")
			return
		end
		r = tonumber(r)
		if (not r) then
			Debug_PrintError("CDOTA_BaseNPC.SetCustomHealthLabel expected r as number.")
			return
		end
		g = tonumber(g)
		if (not g) then
			Debug_PrintError("CDOTA_BaseNPC.SetCustomHealthLabel expected g as number.")
			return
		end
		b = tonumber(b)
		if (not b) then
			Debug_PrintError("CDOTA_BaseNPC.SetCustomHealthLabel expected b as number.")
			return
		end
		if (vanillaSetCustomHealthLabel) then
			vanillaSetCustomHealthLabel(self, pLabel, r, g, b, ...)
		end

	end

	local vanillaSetDayTimeVisionRange = entity.SetDayTimeVisionRange
	entity.SetDayTimeVisionRange = function(self, iRange, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetDayTimeVisionRange called for null entity.")
			return
		end
		iRange = tonumber(iRange)
		if (not iRange) then
			Debug_PrintError("CDOTA_BaseNPC.SetDayTimeVisionRange expected iRange as number.")
			return
		end
		if (vanillaSetDayTimeVisionRange) then
			vanillaSetDayTimeVisionRange(self, iRange, ...)
		end

	end

	local vanillaSetDeathXP = entity.SetDeathXP
	entity.SetDeathXP = function(self, iXPBounty, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetDeathXP called for null entity.")
			return
		end
		iXPBounty = tonumber(iXPBounty)
		if (not iXPBounty) then
			Debug_PrintError("CDOTA_BaseNPC.SetDeathXP expected iXPBounty as number.")
			return
		end
		if (vanillaSetDeathXP) then
			vanillaSetDeathXP(self, iXPBounty, ...)
		end

	end

	local vanillaSetFollowRange = entity.SetFollowRange
	entity.SetFollowRange = function(self, flFollowRange, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetFollowRange called for null entity.")
			return
		end
		flFollowRange = tonumber(flFollowRange)
		if (not flFollowRange) then
			Debug_PrintError("CDOTA_BaseNPC.SetFollowRange expected flFollowRange as number.")
			return
		end
		if (vanillaSetFollowRange) then
			vanillaSetFollowRange(self, flFollowRange, ...)
		end

	end

	local vanillaSetForceAttackTarget = entity.SetForceAttackTarget
	entity.SetForceAttackTarget = function(self, hNPC, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetForceAttackTarget called for null entity.")
			return
		end
		if (type(hNPC) ~= "table" or hNPC.IsNull == nil or hNPC:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetForceAttackTarget expected hNPC as valid not null entity.")
			return
		end
		if (vanillaSetForceAttackTarget) then
			vanillaSetForceAttackTarget(self, hNPC, ...)
		end

	end

	local vanillaSetForceAttackTargetAlly = entity.SetForceAttackTargetAlly
	entity.SetForceAttackTargetAlly = function(self, hNPC, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetForceAttackTargetAlly called for null entity.")
			return
		end
		if (type(hNPC) ~= "table" or hNPC.IsNull == nil or hNPC:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetForceAttackTargetAlly expected hNPC as valid not null entity.")
			return
		end
		if (vanillaSetForceAttackTargetAlly) then
			vanillaSetForceAttackTargetAlly(self, hNPC, ...)
		end

	end

	local vanillaSetHasInventory = entity.SetHasInventory
	entity.SetHasInventory = function(self, bHasInventory, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetHasInventory called for null entity.")
			return
		end
		if (bHasInventory ~= true and bHasInventory ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.SetHasInventory expected bHasInventory as boolean.")
			return
		end
		if (vanillaSetHasInventory) then
			vanillaSetHasInventory(self, bHasInventory, ...)
		end

	end

	local vanillaSetHealthBarOffsetOverride = entity.SetHealthBarOffsetOverride
	entity.SetHealthBarOffsetOverride = function(self, nOffset, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetHealthBarOffsetOverride called for null entity.")
			return
		end
		nOffset = tonumber(nOffset)
		if (not nOffset) then
			Debug_PrintError("CDOTA_BaseNPC.SetHealthBarOffsetOverride expected nOffset as number.")
			return
		end
		if (vanillaSetHealthBarOffsetOverride) then
			vanillaSetHealthBarOffsetOverride(self, nOffset, ...)
		end

	end

	local vanillaSetHullRadius = entity.SetHullRadius
	entity.SetHullRadius = function(self, flHullRadius, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetHullRadius called for null entity.")
			return
		end
		flHullRadius = tonumber(flHullRadius)
		if (not flHullRadius) then
			Debug_PrintError("CDOTA_BaseNPC.SetHullRadius expected flHullRadius as number.")
			return
		end
		if (vanillaSetHullRadius) then
			vanillaSetHullRadius(self, flHullRadius, ...)
		end

	end

	local vanillaSetIdleAcquire = entity.SetIdleAcquire
	entity.SetIdleAcquire = function(self, bIdleAcquire, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetIdleAcquire called for null entity.")
			return
		end
		if (bIdleAcquire ~= true and bIdleAcquire ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.SetIdleAcquire expected bIdleAcquire as boolean.")
			return
		end
		if (vanillaSetIdleAcquire) then
			vanillaSetIdleAcquire(self, bIdleAcquire, ...)
		end

	end

	local vanillaSetInitialGoalEntity = entity.SetInitialGoalEntity
	entity.SetInitialGoalEntity = function(self, hGoal, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetInitialGoalEntity called for null entity.")
			return
		end
		if (type(hGoal) ~= "table" or hGoal.IsNull == nil or hGoal:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetInitialGoalEntity expected hGoal as valid not null entity.")
			return
		end
		if (vanillaSetInitialGoalEntity) then
			vanillaSetInitialGoalEntity(self, hGoal, ...)
		end

	end

	local vanillaSetInitialGoalPosition = entity.SetInitialGoalPosition
	entity.SetInitialGoalPosition = function(self, vPosition, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetInitialGoalPosition called for null entity.")
			return
		end
		if (type(vPosition) ~= "userdata") then
			Debug_PrintError("CDOTA_BaseNPC.SetInitialGoalPosition expected vPosition as Vector.")
			return
		end
		if (vanillaSetInitialGoalPosition) then
			vanillaSetInitialGoalPosition(self, vPosition, ...)
		end

	end

	local vanillaSetMana = entity.SetMana
	entity.SetMana = function(self, flMana, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetMana called for null entity.")
			return
		end
		flMana = tonumber(flMana)
		if (not flMana) then
			Debug_PrintError("CDOTA_BaseNPC.SetMana expected flMana as number.")
			return
		end
		if (vanillaSetMana) then
			vanillaSetMana(self, flMana, ...)
		end

	end

	local vanillaSetMaxMana = entity.SetMaxMana
	entity.SetMaxMana = function(self, flMaxMana, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetMaxMana called for null entity.")
			return
		end
		flMaxMana = tonumber(flMaxMana)
		if (not flMaxMana) then
			Debug_PrintError("CDOTA_BaseNPC.SetMaxMana expected flMaxMana as number.")
			return
		end
		if (vanillaSetMaxMana) then
			vanillaSetMaxMana(self, flMaxMana, ...)
		end

	end

	local vanillaSetMaximumGoldBounty = entity.SetMaximumGoldBounty
	entity.SetMaximumGoldBounty = function(self, iGoldBountyMax, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetMaximumGoldBounty called for null entity.")
			return
		end
		iGoldBountyMax = tonumber(iGoldBountyMax)
		if (not iGoldBountyMax) then
			Debug_PrintError("CDOTA_BaseNPC.SetMaximumGoldBounty expected iGoldBountyMax as number.")
			return
		end
		if (vanillaSetMaximumGoldBounty) then
			vanillaSetMaximumGoldBounty(self, iGoldBountyMax, ...)
		end

	end

	local vanillaSetMinimumGoldBounty = entity.SetMinimumGoldBounty
	entity.SetMinimumGoldBounty = function(self, iGoldBountyMin, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetMinimumGoldBounty called for null entity.")
			return
		end
		iGoldBountyMin = tonumber(iGoldBountyMin)
		if (not iGoldBountyMin) then
			Debug_PrintError("CDOTA_BaseNPC.SetMinimumGoldBounty expected iGoldBountyMin as number.")
			return
		end
		if (vanillaSetMinimumGoldBounty) then
			vanillaSetMinimumGoldBounty(self, iGoldBountyMin, ...)
		end

	end

	local vanillaSetModifierStackCount = entity.SetModifierStackCount
	entity.SetModifierStackCount = function(self, pszScriptName, hCaster, nStackCount, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetModifierStackCount called for null entity.")
			return
		end
		if (type(pszScriptName) ~= "string") then
			Debug_PrintError("CDOTA_BaseNPC.SetModifierStackCount expected pszScriptName as string.")
			return
		end
		if (type(hCaster) ~= "table" or hCaster.IsNull == nil or hCaster:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetModifierStackCount expected hCaster as valid not null entity.")
			return
		end
		nStackCount = tonumber(nStackCount)
		if (not nStackCount) then
			Debug_PrintError("CDOTA_BaseNPC.SetModifierStackCount expected nStackCount as number.")
			return
		end
		if (vanillaSetModifierStackCount) then
			vanillaSetModifierStackCount(self, pszScriptName, hCaster, nStackCount, ...)
		end

	end

	local vanillaSetMoveCapability = entity.SetMoveCapability
	entity.SetMoveCapability = function(self, iMoveCapabilities, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetMoveCapability called for null entity.")
			return
		end
		iMoveCapabilities = tonumber(iMoveCapabilities)
		if (not iMoveCapabilities) then
			Debug_PrintError("CDOTA_BaseNPC.SetMoveCapability expected iMoveCapabilities as number.")
			return
		end
		if (vanillaSetMoveCapability) then
			vanillaSetMoveCapability(self, iMoveCapabilities, ...)
		end

	end

	local vanillaSetMustReachEachGoalEntity = entity.SetMustReachEachGoalEntity
	entity.SetMustReachEachGoalEntity = function(self, must, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetMustReachEachGoalEntity called for null entity.")
			return
		end
		if (must ~= true and must ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.SetMustReachEachGoalEntity expected must as boolean.")
			return
		end
		if (vanillaSetMustReachEachGoalEntity) then
			vanillaSetMustReachEachGoalEntity(self, must, ...)
		end

	end

	local vanillaSetNeverMoveToClearSpace = entity.SetNeverMoveToClearSpace
	entity.SetNeverMoveToClearSpace = function(self, neverMoveToClearSpace, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetNeverMoveToClearSpace called for null entity.")
			return
		end
		if (neverMoveToClearSpace ~= true and neverMoveToClearSpace ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.SetNeverMoveToClearSpace expected neverMoveToClearSpace as boolean.")
			return
		end
		if (vanillaSetNeverMoveToClearSpace) then
			vanillaSetNeverMoveToClearSpace(self, neverMoveToClearSpace, ...)
		end

	end

	local vanillaSetNightTimeVisionRange = entity.SetNightTimeVisionRange
	entity.SetNightTimeVisionRange = function(self, iRange, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetNightTimeVisionRange called for null entity.")
			return
		end
		iRange = tonumber(iRange)
		if (not iRange) then
			Debug_PrintError("CDOTA_BaseNPC.SetNightTimeVisionRange expected iRange as number.")
			return
		end
		if (vanillaSetNightTimeVisionRange) then
			vanillaSetNightTimeVisionRange(self, iRange, ...)
		end

	end

	local vanillaSetOrigin = entity.SetOrigin
	entity.SetOrigin = function(self, vLocation, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetOrigin called for null entity.")
			return
		end
		if (type(vLocation) ~= "userdata") then
			Debug_PrintError("CDOTA_BaseNPC.SetOrigin expected vLocation as Vector.")
			return
		end
		if (vanillaSetOrigin) then
			vanillaSetOrigin(self, vLocation, ...)
		end

	end

	local vanillaSetOriginalModel = entity.SetOriginalModel
	entity.SetOriginalModel = function(self, pszModelName, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetOriginalModel called for null entity.")
			return
		end
		if (type(pszModelName) ~= "string") then
			Debug_PrintError("CDOTA_BaseNPC.SetOriginalModel expected pszModelName as string.")
			return
		end
		if (vanillaSetOriginalModel) then
			vanillaSetOriginalModel(self, pszModelName, ...)
		end

	end

	local vanillaSetPhysicalArmorBaseValue = entity.SetPhysicalArmorBaseValue
	entity.SetPhysicalArmorBaseValue = function(self, flPhysicalArmorValue, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetPhysicalArmorBaseValue called for null entity.")
			return
		end
		flPhysicalArmorValue = tonumber(flPhysicalArmorValue)
		if (not flPhysicalArmorValue) then
			Debug_PrintError("CDOTA_BaseNPC.SetPhysicalArmorBaseValue expected flPhysicalArmorValue as number.")
			return
		end
		if (vanillaSetPhysicalArmorBaseValue) then
			vanillaSetPhysicalArmorBaseValue(self, flPhysicalArmorValue, ...)
		end

	end

	local vanillaSetRangedProjectileName = entity.SetRangedProjectileName
	entity.SetRangedProjectileName = function(self, pProjectileName, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetRangedProjectileName called for null entity.")
			return
		end
		if (type(pProjectileName) ~= "string") then
			Debug_PrintError("CDOTA_BaseNPC.SetRangedProjectileName expected pProjectileName as string.")
			return
		end
		if (vanillaSetRangedProjectileName) then
			vanillaSetRangedProjectileName(self, pProjectileName, ...)
		end

	end

	local vanillaSetRevealRadius = entity.SetRevealRadius
	entity.SetRevealRadius = function(self, revealRadius, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetRevealRadius called for null entity.")
			return
		end
		revealRadius = tonumber(revealRadius)
		if (not revealRadius) then
			Debug_PrintError("CDOTA_BaseNPC.SetRevealRadius expected revealRadius as number.")
			return
		end
		if (vanillaSetRevealRadius) then
			vanillaSetRevealRadius(self, revealRadius, ...)
		end

	end

	local vanillaSetShouldDoFlyHeightVisual = entity.SetShouldDoFlyHeightVisual
	entity.SetShouldDoFlyHeightVisual = function(self, bShouldVisuallyFly, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetShouldDoFlyHeightVisual called for null entity.")
			return
		end
		if (bShouldVisuallyFly ~= true and bShouldVisuallyFly ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.SetShouldDoFlyHeightVisual expected bShouldVisuallyFly as boolean.")
			return
		end
		if (vanillaSetShouldDoFlyHeightVisual) then
			vanillaSetShouldDoFlyHeightVisual(self, bShouldVisuallyFly, ...)
		end

	end

	local vanillaSetStolenScepter = entity.SetStolenScepter
	entity.SetStolenScepter = function(self, bStolenScepter, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetStolenScepter called for null entity.")
			return
		end
		if (bStolenScepter ~= true and bStolenScepter ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.SetStolenScepter expected bStolenScepter as boolean.")
			return
		end
		if (vanillaSetStolenScepter) then
			vanillaSetStolenScepter(self, bStolenScepter, ...)
		end

	end

	local vanillaSetUnitCanRespawn = entity.SetUnitCanRespawn
	entity.SetUnitCanRespawn = function(self, bCanRespawn, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetUnitCanRespawn called for null entity.")
			return
		end
		if (bCanRespawn ~= true and bCanRespawn ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.SetUnitCanRespawn expected bCanRespawn as boolean.")
			return
		end
		if (vanillaSetUnitCanRespawn) then
			vanillaSetUnitCanRespawn(self, bCanRespawn, ...)
		end

	end

	local vanillaSetUnitName = entity.SetUnitName
	entity.SetUnitName = function(self, pName, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SetUnitName called for null entity.")
			return
		end
		if (type(pName) ~= "string") then
			Debug_PrintError("CDOTA_BaseNPC.SetUnitName expected pName as string.")
			return
		end
		if (vanillaSetUnitName) then
			vanillaSetUnitName(self, pName, ...)
		end

	end

	local vanillaShouldIdleAcquire = entity.ShouldIdleAcquire
	entity.ShouldIdleAcquire = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.ShouldIdleAcquire called for null entity.")
			return false
		end
		if (vanillaShouldIdleAcquire) then
			return vanillaShouldIdleAcquire(self, ...)
		end
		return false
	end

	local vanillaSpeakConcept = entity.SpeakConcept
	entity.SpeakConcept = function(self, hCriteriaTable, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SpeakConcept called for null entity.")
			return
		end
		if (type(hCriteriaTable) ~= "table" or hCriteriaTable.IsNull == nil or hCriteriaTable:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SpeakConcept expected hCriteriaTable as valid not null entity.")
			return
		end
		if (vanillaSpeakConcept) then
			vanillaSpeakConcept(self, hCriteriaTable, ...)
		end

	end

	local vanillaSpendMana = entity.SpendMana
	entity.SpendMana = function(self, flManaSpent, hAbility, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SpendMana called for null entity.")
			return
		end
		flManaSpent = tonumber(flManaSpent)
		if (not flManaSpent) then
			Debug_PrintError("CDOTA_BaseNPC.SpendMana expected flManaSpent as number.")
			return
		end
		if (type(hAbility) ~= "table" or hAbility.IsNull == nil or hAbility:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SpendMana expected hAbility as valid not null entity.")
			return
		end
		if (vanillaSpendMana) then
			vanillaSpendMana(self, flManaSpent, hAbility, ...)
		end

	end

	local vanillaStartGesture = entity.StartGesture
	entity.StartGesture = function(self, nActivity, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.StartGesture called for null entity.")
			return
		end
		nActivity = tonumber(nActivity)
		if (not nActivity) then
			Debug_PrintError("CDOTA_BaseNPC.StartGesture expected nActivity as number.")
			return
		end
		if (vanillaStartGesture) then
			vanillaStartGesture(self, nActivity, ...)
		end

	end

	local vanillaStartGestureFadeWithSequenceSettings = entity.StartGestureFadeWithSequenceSettings
	entity.StartGestureFadeWithSequenceSettings = function(self, nActivity, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.StartGestureFadeWithSequenceSettings called for null entity.")
			return
		end
		nActivity = tonumber(nActivity)
		if (not nActivity) then
			Debug_PrintError("CDOTA_BaseNPC.StartGestureFadeWithSequenceSettings expected nActivity as number.")
			return
		end
		if (vanillaStartGestureFadeWithSequenceSettings) then
			vanillaStartGestureFadeWithSequenceSettings(self, nActivity, ...)
		end

	end

	local vanillaStartGestureWithFade = entity.StartGestureWithFade
	entity.StartGestureWithFade = function(self, nActivity, fFadeIn, fFadeOut, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.StartGestureWithFade called for null entity.")
			return
		end
		nActivity = tonumber(nActivity)
		if (not nActivity) then
			Debug_PrintError("CDOTA_BaseNPC.StartGestureWithFade expected nActivity as number.")
			return
		end
		fFadeIn = tonumber(fFadeIn)
		if (not fFadeIn) then
			Debug_PrintError("CDOTA_BaseNPC.StartGestureWithFade expected fFadeIn as number.")
			return
		end
		fFadeOut = tonumber(fFadeOut)
		if (not fFadeOut) then
			Debug_PrintError("CDOTA_BaseNPC.StartGestureWithFade expected fFadeOut as number.")
			return
		end
		if (vanillaStartGestureWithFade) then
			vanillaStartGestureWithFade(self, nActivity, fFadeIn, fFadeOut, ...)
		end

	end

	local vanillaStartGestureWithPlaybackRate = entity.StartGestureWithPlaybackRate
	entity.StartGestureWithPlaybackRate = function(self, nActivity, flRate, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.StartGestureWithPlaybackRate called for null entity.")
			return
		end
		nActivity = tonumber(nActivity)
		if (not nActivity) then
			Debug_PrintError("CDOTA_BaseNPC.StartGestureWithPlaybackRate expected nActivity as number.")
			return
		end
		flRate = tonumber(flRate)
		if (not flRate) then
			Debug_PrintError("CDOTA_BaseNPC.StartGestureWithPlaybackRate expected flRate as number.")
			return
		end
		if (vanillaStartGestureWithPlaybackRate) then
			vanillaStartGestureWithPlaybackRate(self, nActivity, flRate, ...)
		end

	end

	local vanillaStop = entity.Stop
	entity.Stop = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.Stop called for null entity.")
			return
		end
		if (vanillaStop) then
			vanillaStop(self, ...)
		end

	end

	local vanillaStopFacing = entity.StopFacing
	entity.StopFacing = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.StopFacing called for null entity.")
			return
		end
		if (vanillaStopFacing) then
			vanillaStopFacing(self, ...)
		end

	end

	local vanillaSwapAbilities = entity.SwapAbilities
	entity.SwapAbilities = function(self, pAbilityName1, pAbilityName2, bEnable1, bEnable2, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SwapAbilities called for null entity.")
			return
		end
		if (type(pAbilityName1) ~= "string") then
			Debug_PrintError("CDOTA_BaseNPC.SwapAbilities expected pAbilityName1 as string.")
			return
		end
		if (type(pAbilityName2) ~= "string") then
			Debug_PrintError("CDOTA_BaseNPC.SwapAbilities expected pAbilityName2 as string.")
			return
		end
		if (bEnable1 ~= true and bEnable1 ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.SwapAbilities expected bEnable1 as boolean.")
			return
		end
		if (bEnable2 ~= true and bEnable2 ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.SwapAbilities expected bEnable2 as boolean.")
			return
		end
		if (vanillaSwapAbilities) then
			vanillaSwapAbilities(self, pAbilityName1, pAbilityName2, bEnable1, bEnable2, ...)
		end

	end

	local vanillaSwapItems = entity.SwapItems
	entity.SwapItems = function(self, nSlot1, nSlot2, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.SwapItems called for null entity.")
			return
		end
		nSlot1 = tonumber(nSlot1)
		if (not nSlot1) then
			Debug_PrintError("CDOTA_BaseNPC.SwapItems expected nSlot1 as number.")
			return
		end
		nSlot2 = tonumber(nSlot2)
		if (not nSlot2) then
			Debug_PrintError("CDOTA_BaseNPC.SwapItems expected nSlot2 as number.")
			return
		end
		if (vanillaSwapItems) then
			vanillaSwapItems(self, nSlot1, nSlot2, ...)
		end

	end

	local vanillaTakeItem = entity.TakeItem
	entity.TakeItem = function(self, hItem, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.TakeItem called for null entity.")
			return nil
		end
		if (type(hItem) ~= "table" or hItem.IsNull == nil or hItem:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.TakeItem expected hItem as valid not null entity.")
			return nil
		end
		if (vanillaTakeItem) then
			return vanillaTakeItem(self, hItem, ...)
		end
		return nil
	end

	local vanillaTimeUntilNextAttack = entity.TimeUntilNextAttack
	entity.TimeUntilNextAttack = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.TimeUntilNextAttack called for null entity.")
			return 999999
		end
		if (vanillaTimeUntilNextAttack) then
			return vanillaTimeUntilNextAttack(self, ...)
		end
		return 999999
	end

	local vanillaTriggerModifierDodge = entity.TriggerModifierDodge
	entity.TriggerModifierDodge = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.TriggerModifierDodge called for null entity.")
			return false
		end
		if (vanillaTriggerModifierDodge) then
			return vanillaTriggerModifierDodge(self, ...)
		end
		return false
	end

	local vanillaTriggerSpellAbsorb = entity.TriggerSpellAbsorb
	entity.TriggerSpellAbsorb = function(self, hAbility, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.TriggerSpellAbsorb called for null entity.")
			return false
		end
		if (type(hAbility) ~= "table" or hAbility.IsNull == nil or hAbility:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.TriggerSpellAbsorb expected hAbility as valid not null entity.")
			return false
		end
		if (vanillaTriggerSpellAbsorb) then
			return vanillaTriggerSpellAbsorb(self, hAbility, ...)
		end
		return false
	end

	local vanillaTriggerSpellReflect = entity.TriggerSpellReflect
	entity.TriggerSpellReflect = function(self, hAbility, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.TriggerSpellReflect called for null entity.")
			return
		end
		if (type(hAbility) ~= "table" or hAbility.IsNull == nil or hAbility:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.TriggerSpellReflect expected hAbility as valid not null entity.")
			return
		end
		if (vanillaTriggerSpellReflect) then
			vanillaTriggerSpellReflect(self, hAbility, ...)
		end

	end

	local vanillaUnHideAbilityToSlot = entity.UnHideAbilityToSlot
	entity.UnHideAbilityToSlot = function(self, pszAbilityName, pszReplacedAbilityName, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.UnHideAbilityToSlot called for null entity.")
			return
		end
		if (type(pszAbilityName) ~= "string") then
			Debug_PrintError("CDOTA_BaseNPC.UnHideAbilityToSlot expected pszAbilityName as string.")
			return
		end
		if (type(pszReplacedAbilityName) ~= "string") then
			Debug_PrintError("CDOTA_BaseNPC.UnHideAbilityToSlot expected pszReplacedAbilityName as string.")
			return
		end
		if (vanillaUnHideAbilityToSlot) then
			vanillaUnHideAbilityToSlot(self, pszAbilityName, pszReplacedAbilityName, ...)
		end

	end

	local vanillaUnitCanRespawn = entity.UnitCanRespawn
	entity.UnitCanRespawn = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.UnitCanRespawn called for null entity.")
			return false
		end
		if (vanillaUnitCanRespawn) then
			return vanillaUnitCanRespawn(self, ...)
		end
		return false
	end

	local vanillaWasKilledPassively = entity.WasKilledPassively
	entity.WasKilledPassively = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.WasKilledPassively called for null entity.")
			return false
		end
		if (vanillaWasKilledPassively) then
			return vanillaWasKilledPassively(self, ...)
		end
		return false
	end
end

function _OverrideBaseNPCFunctionsSecond(entity)

	local vanillaGetRangeToUnit = entity.GetRangeToUnit
	entity.GetRangeToUnit = function(self, hNPC, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetRangeToUnit called for null entity.")
			return 0
		end
		if (type(hNPC) ~= "table" or hNPC.IsNull == nil or hNPC:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetRangeToUnit expected hNPC as valid not null entity.")
			return 0
		end
		if (vanillaGetRangeToUnit) then
			return vanillaGetRangeToUnit(self, hNPC, ...)
		end
		return 0
	end

	local vanillaGetRangedProjectileName = entity.GetRangedProjectileName
	entity.GetRangedProjectileName = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetRangedProjectileName called for null entity.")
			return ""
		end
		if (vanillaGetRangedProjectileName) then
			return vanillaGetRangedProjectileName(self, ...)
		end
		return ""
	end

	local vanillaGetSecondsPerAttack = entity.GetSecondsPerAttack
	entity.GetSecondsPerAttack = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetSecondsPerAttack called for null entity.")
			return 0
		end
		if (vanillaGetSecondsPerAttack) then
			return vanillaGetSecondsPerAttack(self, ...)
		end
		return 0
	end

	local vanillaGetSpellAmplification = entity.GetSpellAmplification
	entity.GetSpellAmplification = function(self, bBaseOnly, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetSpellAmplification called for null entity.")
			return 0
		end
		if (bBaseOnly ~= true and bBaseOnly ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.GetSpellAmplification expected bBaseOnly as boolean.")
			return 0
		end
		if (vanillaGetSpellAmplification) then
			return vanillaGetSpellAmplification(self, bBaseOnly, ...)
		end
		return 0
	end

	-- Valve break this functions, always return 0. Nice
	entity.GetStatusResistance = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetStatusResistance called for null entity.")
			return 0
		end
		local eventData = {
			unit = self
		}
		local statusResistance = 1
		local thereAreNoStatusResistanceSources = true
		local modifiers = self:FindAllModifiers()
		for _, modifier in pairs(modifiers) do
			if(modifier.GetModifierStatusResistanceStacking) then
				statusResistance = statusResistance * (1 - ((tonumber(modifier:GetModifierStatusResistanceStacking(eventData) or 0) or 0) / 100))
				thereAreNoStatusResistanceSources = false
			end
			if(modifier.GetModifierStatusResistance) then
				statusResistance = statusResistance * (1 - ((tonumber(modifier:GetModifierStatusResistance(eventData) or 0) or 0) / 100))
				thereAreNoStatusResistanceSources = false
			end
		end
		if(thereAreNoStatusResistanceSources == true) then
			return 0
		else
			return (1 - statusResistance)
		end
	end

	local vanillaGetTotalPurchasedUpgradeGoldCost = entity.GetTotalPurchasedUpgradeGoldCost
	entity.GetTotalPurchasedUpgradeGoldCost = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetTotalPurchasedUpgradeGoldCost called for null entity.")
			return 0
		end
		if (vanillaGetTotalPurchasedUpgradeGoldCost) then
			return vanillaGetTotalPurchasedUpgradeGoldCost(self, ...)
		end
		return 0
	end

	local vanillaGetUnitLabel = entity.GetUnitLabel
	entity.GetUnitLabel = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetUnitLabel called for null entity.")
			return ""
		end
		if (vanillaGetUnitLabel) then
			return vanillaGetUnitLabel(self, ...)
		end
		return ""
	end

	local vanillaGetUnitName = entity.GetUnitName
	entity.GetUnitName = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetUnitName called for null entity.")
			return ""
		end
		if (vanillaGetUnitName) then
			return vanillaGetUnitName(self, ...)
		end
		return ""
	end

	local vanillaGiveMana = entity.GiveMana
	entity.GiveMana = function(self, flMana, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GiveMana called for null entity.")
			return
		end
		flMana = tonumber(flMana)
		if (not flMana) then
			Debug_PrintError("CDOTA_BaseNPC.GiveMana expected flMana as number.")
			return
		end
		if (vanillaGiveMana) then
			vanillaGiveMana(self, flMana, ...)
		end

	end

	local vanillaHasAbility = entity.HasAbility
	entity.HasAbility = function(self, pszAbilityName, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.HasAbility called for null entity.")
			return false
		end
		if (type(pszAbilityName) ~= "string") then
			Debug_PrintError("CDOTA_BaseNPC.HasAbility expected pszAbilityName as string.")
			return false
		end
		if (vanillaHasAbility) then
			return vanillaHasAbility(self, pszAbilityName, ...)
		end
		return false
	end

	local vanillaHasAnyActiveAbilities = entity.HasAnyActiveAbilities
	entity.HasAnyActiveAbilities = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.HasAnyActiveAbilities called for null entity.")
			return false
		end
		if (vanillaHasAnyActiveAbilities) then
			return vanillaHasAnyActiveAbilities(self, ...)
		end
		return false
	end

	local vanillaHasAttackCapability = entity.HasAttackCapability
	entity.HasAttackCapability = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.HasAttackCapability called for null entity.")
			return false
		end
		if (vanillaHasAttackCapability) then
			return vanillaHasAttackCapability(self, ...)
		end
		return false
	end

	local vanillaHasFlyMovementCapability = entity.HasFlyMovementCapability
	entity.HasFlyMovementCapability = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.HasFlyMovementCapability called for null entity.")
			return false
		end
		if (vanillaHasFlyMovementCapability) then
			return vanillaHasFlyMovementCapability(self, ...)
		end
		return false
	end

	local vanillaHasFlyingVision = entity.HasFlyingVision
	entity.HasFlyingVision = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.HasFlyingVision called for null entity.")
			return false
		end
		if (vanillaHasFlyingVision) then
			return vanillaHasFlyingVision(self, ...)
		end
		return false
	end

	local vanillaHasGroundMovementCapability = entity.HasGroundMovementCapability
	entity.HasGroundMovementCapability = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.HasGroundMovementCapability called for null entity.")
			return false
		end
		if (vanillaHasGroundMovementCapability) then
			return vanillaHasGroundMovementCapability(self, ...)
		end
		return false
	end

	local vanillaHasInventory = entity.HasInventory
	entity.HasInventory = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.HasInventory called for null entity.")
			return false
		end
		if (vanillaHasInventory) then
			return vanillaHasInventory(self, ...)
		end
		return false
	end

	local vanillaHasItemInInventory = entity.HasItemInInventory
	entity.HasItemInInventory = function(self, pItemName, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.HasItemInInventory called for null entity.")
			return false
		end
		if (type(pItemName) ~= "string") then
			Debug_PrintError("CDOTA_BaseNPC.HasItemInInventory expected pItemName as string.")
			return false
		end
		if (vanillaHasItemInInventory) then
			return vanillaHasItemInInventory(self, pItemName, ...)
		end
		return false
	end

	local vanillaHasModifier = entity.HasModifier
	entity.HasModifier = function(self, pszScriptName, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.HasModifier called for null entity.")
			return false
		end
		if (type(pszScriptName) ~= "string") then
			Debug_PrintError("CDOTA_BaseNPC.HasModifier expected pszScriptName as string.")
			return false
		end
		if (vanillaHasModifier) then
			return vanillaHasModifier(self, pszScriptName, ...)
		end
		return false
	end

	local vanillaHasMovementCapability = entity.HasMovementCapability
	entity.HasMovementCapability = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.HasMovementCapability called for null entity.")
			return false
		end
		if (vanillaHasMovementCapability) then
			return vanillaHasMovementCapability(self, ...)
		end
		return false
	end

	local vanillaHasScepter = entity.HasScepter
	entity.HasScepter = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.HasScepter called for null entity.")
			return false
		end
		if (vanillaHasScepter) then
			return vanillaHasScepter(self, ...)
		end
		return false
	end

	_G.DOTA_HEAL_TYPE_HEALING = 0
	_G.DOTA_HEAL_TYPE_LIFESTEAL = 1

	local vanillaHeal = entity.Heal

	entity.Heal = function(self, flAmount, hInflictor, type, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.Heal called for null entity.")
			return 0
		end
		flAmount = tonumber(flAmount)
		if (not flAmount) then
			Debug_PrintError("CDOTA_BaseNPC.Heal expected flAmount as number.")
			return 0
		end
		if (hInflictor ~= nil and (type(hInflictor) ~= "table" or hInflictor.IsNull == nil or hInflictor:IsNull() == true)) then
			Debug_PrintError("CDOTA_BaseNPC.Heal expected hInflictor as valid not null entity.")
			return 0
		end
		type = tonumber(type)
		if(not type) then
			Debug_PrintError("CDOTA_BaseNPC.Heal expected type as number.")
			return 0
		end
		if(type ~= DOTA_HEAL_TYPE_HEALING and type ~= DOTA_HEAL_TYPE_LIFESTEAL) then
			Debug_PrintError("CDOTA_BaseNPC.Heal expected type as valid enum value(DOTA_HEAL_TYPE_HEALING or DOTA_HEAL_TYPE_LIFESTEAL).")
			return 0
		end
		if (vanillaHeal) then
			vanillaHeal(self, flAmount, hInflictor, ...)
		end
		local eventData = {
			target = self,
			source = nil,
			original_amount = amount
		}
		-- Try get source unit if source is modifier or ability
		local sourceNpc = hInflictor and (hInflictor.GetCaster and hInflictor:GetCaster() or nil) or nil
		local totalHealingAmp = 1
		if(type ~= DOTA_HEAL_TYPE_LIFESTEAL) then
			-- Try get source unit if source is unit
			if(not sourceNpc) then
				if(hInflictor.GetUnitName) then
					sourceNpc = hInflictor
				end
			end
			-- Welp, we did our best...
			if(sourceNpc) then
				eventData["source"] = sourceNpc
				for _, modifier in pairs(sourceNpc:FindAllModifiers()) do
					if(modifier.GetModifierHealCaused_Percentage) then
						totalHealingAmp = totalHealingAmp + ((tonumber(modifier:GetModifierHealCaused_Percentage(eventData) or 0) or 0) / 100)
					end
				end
			end
			for _, modifier in pairs(self:FindAllModifiers()) do
				if(modifier.GetModifierHealReceived_Percentage) then
					totalHealingAmp = totalHealingAmp + ((tonumber(modifier:GetModifierHealReceived_Percentage(eventData) or 0) or 0) / 100)
				end
			end
		end
		amount = amount * totalHealingAmp
		if (vanillaHeal) then
			vanillaHeal(self, flAmount, hInflictor, ...)
			return amount
		else
			Debug_PrintError("CDOTA_BaseNPC.Heal valve removed this function. Fix this please.")
			return 0
		end
	end

	local vanillaHealWithParams = entity.HealWithParams
	entity.HealWithParams = function(self, flAmount, hInflictor, bLifesteal, bAmplify, hSource, bSpellLifesteal, ...)
		print("For healing from lifesteal source use CDOTA_BaseNPC.Heal with DOTA_HEAL_TYPE_LIFESTEAL.")
		print("For healing from non-lifesteal source use CDOTA_BaseNPC.Heal with DOTA_HEAL_TYPE_HEALING.")
		Debug_PrintError("CDOTA_BaseNPC.HealWithParams use CDOTA_BaseNPC.Heal instead.")
		return 0
	end

	local vanillaHold = entity.Hold
	entity.Hold = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.Hold called for null entity.")
			return
		end
		if (vanillaHold) then
			vanillaHold(self, ...)
		end

	end

	local vanillaInterrupt = entity.Interrupt
	entity.Interrupt = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.Interrupt called for null entity.")
			return
		end
		if (vanillaInterrupt) then
			vanillaInterrupt(self, ...)
		end

	end

	local vanillaInterruptChannel = entity.InterruptChannel
	entity.InterruptChannel = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.InterruptChannel called for null entity.")
			return
		end
		if (vanillaInterruptChannel) then
			vanillaInterruptChannel(self, ...)
		end

	end

	local vanillaInterruptMotionControllers = entity.InterruptMotionControllers
	entity.InterruptMotionControllers = function(self, bFindClearSpace, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.InterruptMotionControllers called for null entity.")
			return
		end
		if (bFindClearSpace ~= true and bFindClearSpace ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.InterruptMotionControllers expected bFindClearSpace as boolean.")
			return
		end
		if (vanillaInterruptMotionControllers) then
			vanillaInterruptMotionControllers(self, bFindClearSpace, ...)
		end

	end

	local vanillaIsAlive = entity.IsAlive
	entity.IsAlive = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsAlive called for null entity.")
			return false
		end
		if (vanillaIsAlive) then
			 return vanillaIsAlive(self, ...)
		end
		return false
	end

	local vanillaIsAncient = entity.IsAncient
	entity.IsAncient = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsAncient called for null entity.")
			return false
		end
		if (vanillaIsAncient) then
			return vanillaIsAncient(self, ...)
		end
		return false
	end

	local vanillaIsAttackImmune = entity.IsAttackImmune
	entity.IsAttackImmune = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsAttackImmune called for null entity.")
			return false
		end
		if (vanillaIsAttackImmune) then
			return vanillaIsAttackImmune(self, ...)
		end
		return false
	end

	local vanillaIsAttacking = entity.IsAttacking
	entity.IsAttacking = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsAttacking called for null entity.")
			return false
		end
		if (vanillaIsAttacking) then
			return vanillaIsAttacking(self, ...)
		end
		return false
	end

	local vanillaIsAttackingEntity = entity.IsAttackingEntity
	entity.IsAttackingEntity = function(self, hEntity, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsAttackingEntity called for null entity.")
			return false
		end
		if (type(hEntity) ~= "table" or hEntity.IsNull == nil or hEntity:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsAttackingEntity expected hEntity as valid not null entity.")
			return false
		end
		if (vanillaIsAttackingEntity) then
			return vanillaIsAttackingEntity(self, hEntity, ...)
		end
		return false
	end

	local vanillaIsBarracks = entity.IsBarracks
	entity.IsBarracks = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsBarracks called for null entity.")
			return false
		end
		if (vanillaIsBarracks) then
			return vanillaIsBarracks(self, ...)
		end
		return false
	end

	local vanillaIsBlind = entity.IsBlind
	entity.IsBlind = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsBlind called for null entity.")
			return false
		end
		if (vanillaIsBlind) then
			return vanillaIsBlind(self, ...)
		end
		return false
	end

	local vanillaIsBlockDisabled = entity.IsBlockDisabled
	entity.IsBlockDisabled = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsBlockDisabled called for null entity.")
			return false
		end
		if (vanillaIsBlockDisabled) then
			return vanillaIsBlockDisabled(self, ...)
		end
		return false
	end
	local vanillaIsBossCreature = entity.IsBossCreature
	entity.IsBossCreature = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsBossCreature called for null entity.")
			return false
		end
		if (vanillaIsBossCreature) then
			return vanillaIsBossCreature(self, ...)
		end
		return false
	end

	local vanillaIsBuilding = entity.IsBuilding
	entity.IsBuilding = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsBuilding called for null entity.")
			return false
		end
		local isBuildingFromVanillaFunction = vanillaIsBuilding and vanillaIsBuilding(self, ...) or false
		if(isBuildingFromVanillaFunction == false) then
			if((self._isCustomBuilding and self._isCustomBuilding or false) == true) then
				return true
			end
			-- Check greevil lord buildings?
			local isBuildingInKV = (tonumber(GetUnitKV(self:GetUnitName(), "ConstructionSize")) or -1) > -1
			if(isBuildingInKV == true) then
				return isBuildingInKV
			end
		end
		return isBuildingFromVanillaFunction
	end

	local vanillaIsChanneling = entity.IsChanneling
	entity.IsChanneling = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsChanneling called for null entity.")
			return false
		end
		if (vanillaIsChanneling) then
			return vanillaIsChanneling(self, ...)
		end
		return false
	end

	local vanillaIsClone = entity.IsClone
	entity.IsClone = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsClone called for null entity.")
			return false
		end
		if (vanillaIsClone) then
			return vanillaIsClone(self, ...)
		end
		return false
	end

	local vanillaIsCommandRestricted = entity.IsCommandRestricted
	entity.IsCommandRestricted = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsCommandRestricted called for null entity.")
			return false
		end
		if (vanillaIsCommandRestricted) then
			return vanillaIsCommandRestricted(self, ...)
		end
		return false
	end

	local vanillaIsConsideredHero = entity.IsConsideredHero
	entity.IsConsideredHero = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsConsideredHero called for null entity.")
			return false
		end
		if (vanillaIsConsideredHero) then
			return vanillaIsConsideredHero(self, ...)
		end
		return false
	end

	local vanillaIsControllableByAnyPlayer = entity.IsControllableByAnyPlayer
	entity.IsControllableByAnyPlayer = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsControllableByAnyPlayer called for null entity.")
			return false
		end
		if (vanillaIsControllableByAnyPlayer) then
			return vanillaIsControllableByAnyPlayer(self, ...)
		end
		return false
	end

	local vanillaIsCourier = entity.IsCourier
	entity.IsCourier = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsCourier called for null entity.")
			return false
		end
		if (vanillaIsCourier) then
			return vanillaIsCourier(self, ...)
		end
		return false
	end

	local vanillaIsCreature = entity.IsCreature
	entity.IsCreature = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsCreature called for null entity.")
			return false
		end
		if (vanillaIsCreature) then
			return vanillaIsCreature(self, ...)
		end
		return false
	end

	local vanillaIsCreep = entity.IsCreep
	entity.IsCreep = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsCreep called for null entity.")
			return false
		end
		if (vanillaIsCreep) then
			return vanillaIsCreep(self, ...)
		end
		return false
	end

	local vanillaIsCreepHero = entity.IsCreepHero
	entity.IsCreepHero = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsCreepHero called for null entity.")
			return false
		end
		if (vanillaIsCreepHero) then
			return vanillaIsCreepHero(self, ...)
		end
		return false
	end

	local vanillaIsCurrentlyHorizontalMotionControlled = entity.IsCurrentlyHorizontalMotionControlled
	entity.IsCurrentlyHorizontalMotionControlled = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsCurrentlyHorizontalMotionControlled called for null entity.")
			return false
		end
		if (vanillaIsCurrentlyHorizontalMotionControlled) then
			return vanillaIsCurrentlyHorizontalMotionControlled(self, ...)
		end
		return false
	end

	local vanillaIsCurrentlyVerticalMotionControlled = entity.IsCurrentlyVerticalMotionControlled
	entity.IsCurrentlyVerticalMotionControlled = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsCurrentlyVerticalMotionControlled called for null entity.")
			return false
		end
		if (vanillaIsCurrentlyVerticalMotionControlled) then
			return vanillaIsCurrentlyVerticalMotionControlled(self, ...)
		end
		return false
	end

	local vanillaIsDisarmed = entity.IsDisarmed
	entity.IsDisarmed = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsDisarmed called for null entity.")
			return false
		end
		if (vanillaIsDisarmed) then
			return vanillaIsDisarmed(self, ...)
		end
		return false
	end

	local vanillaIsDominated = entity.IsDominated
	entity.IsDominated = function(self, ...)
		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsDominated called for null entity.")
			return false
		end
		if (vanillaIsDominated) then
			return vanillaIsDominated(self, ...)
		end
		return false
	end

	local vanillaIsEvadeDisabled = entity.IsEvadeDisabled
	entity.IsEvadeDisabled = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsEvadeDisabled called for null entity.")
			return false
		end
		if (vanillaIsEvadeDisabled) then
			return vanillaIsEvadeDisabled(self, ...)
		end
		return false
	end

	local vanillaIsFort = entity.IsFort
	entity.IsFort = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsFort called for null entity.")
			return false
		end
		if (vanillaIsFort) then
			return vanillaIsFort(self, ...)
		end
		return false
	end

	local vanillaIsFrozen = entity.IsFrozen
	entity.IsFrozen = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsFrozen called for null entity.")
			return false
		end
		if (vanillaIsFrozen) then
			return vanillaIsFrozen(self, ...)
		end
		return false
	end

	local vanillaIsHero = entity.IsHero
	entity.IsHero = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsHero called for null entity.")
			return false
		end
		if (vanillaIsHero) then
			return vanillaIsHero(self, ...)
		end
		return false
	end

	local vanillaIsHexed = entity.IsHexed
	entity.IsHexed = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsHexed called for null entity.")
			return false
		end
		if (vanillaIsHexed) then
			return vanillaIsHexed(self, ...)
		end
		return false
	end

	local vanillaIsIdle = entity.IsIdle
	entity.IsIdle = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsIdle called for null entity.")
			return false
		end
		if (vanillaIsIdle) then
			return vanillaIsIdle(self, ...)
		end
		return false
	end

	local vanillaIsIllusion = entity.IsIllusion
	entity.IsIllusion = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsIllusion called for null entity.")
			return false
		end
		if (vanillaIsIllusion) then
			return vanillaIsIllusion(self, ...)
		end
		return false
	end

	local vanillaIsInRangeOfShop = entity.IsInRangeOfShop
	entity.IsInRangeOfShop = function(self, nShopType, bPhysical, ...)
		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsInRangeOfShop called for null entity.")
			return false
		end
		nShopType = tonumber(nShopType)
		if (not nShopType) then
			Debug_PrintError("CDOTA_BaseNPC.IsInRangeOfShop expected nShopType as number.")
			return false
		end
		if (bPhysical ~= true and bPhysical ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.IsInRangeOfShop expected bPhysical as boolean.")
			return false
		end
		if (vanillaIsInRangeOfShop) then
			return vanillaIsInRangeOfShop(self, nShopType, bPhysical, ...)
		end
		return false
	end

	local vanillaIsInvisible = entity.IsInvisible
	entity.IsInvisible = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsInvisible called for null entity.")
			return false
		end
		if (vanillaIsInvisible) then
			return vanillaIsInvisible(self, ...)
		end
		return false
	end

	local vanillaIsInvulnerable = entity.IsInvulnerable
	entity.IsInvulnerable = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsInvulnerable called for null entity.")
			return false
		end
		if (vanillaIsInvulnerable) then
			return vanillaIsInvulnerable(self, ...)
		end
		return false
	end

	local vanillaIsLowAttackPriority = entity.IsLowAttackPriority
	entity.IsLowAttackPriority = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsLowAttackPriority called for null entity.")
			return false
		end
		if (vanillaIsLowAttackPriority) then
			return vanillaIsLowAttackPriority(self, ...)
		end
		return false
	end

	local vanillaIsMagicImmune = entity.IsMagicImmune
	entity.IsMagicImmune = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsMagicImmune called for null entity.")
			return false
		end
		if (vanillaIsMagicImmune) then
			return vanillaIsMagicImmune(self, ...)
		end
		return false
	end

	local vanillaIsMovementImpaired = entity.IsMovementImpaired
	entity.IsMovementImpaired = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsMovementImpaired called for null entity.")
			return false
		end
		if (vanillaIsMovementImpaired) then
			return vanillaIsMovementImpaired(self, ...)
		end
		return false
	end

	local vanillaIsMoving = entity.IsMoving
	entity.IsMoving = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsMoving called for null entity.")
			return false
		end
		if (vanillaIsMoving) then
			return vanillaIsMoving(self, ...)
		end
		return false
	end

	local vanillaIsMuted = entity.IsMuted
	entity.IsMuted = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsMuted called for null entity.")
			return false
		end
		if (vanillaIsMuted) then
			return vanillaIsMuted(self, ...)
		end
		return false
	end

	local vanillaIsNeutralUnitType = entity.IsNeutralUnitType
	entity.IsNeutralUnitType = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsNeutralUnitType called for null entity.")
			return false
		end
		if (vanillaIsNeutralUnitType) then
			return vanillaIsNeutralUnitType(self, ...)
		end
		return false
	end

	local vanillaIsNightmared = entity.IsNightmared
	entity.IsNightmared = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsNightmared called for null entity.")
			return false
		end
		if (vanillaIsNightmared) then
			return vanillaIsNightmared(self, ...)
		end
		return false
	end

	local vanillaIsOpposingTeam = entity.IsOpposingTeam
	entity.IsOpposingTeam = function(self, nTeam, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsOpposingTeam called for null entity.")
			return false
		end
		nTeam = tonumber(nTeam)
		if (not nTeam) then
			Debug_PrintError("CDOTA_BaseNPC.IsOpposingTeam expected nTeam as number.")
			return false
		end
		if (vanillaIsOpposingTeam) then
			return vanillaIsOpposingTeam(self, nTeam, ...)
		end
		return false
	end

	local vanillaIsOther = entity.IsOther
	entity.IsOther = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsOther called for null entity.")
			return false
		end
		if (vanillaIsOther) then
			return vanillaIsOther(self, ...)
		end
		return false
	end

	local vanillaIsOutOfGame = entity.IsOutOfGame
	entity.IsOutOfGame = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsOutOfGame called for null entity.")
			return false
		end
		if (vanillaIsOutOfGame) then
			return vanillaIsOutOfGame(self, ...)
		end
		return false
	end

	local vanillaIsOwnedByAnyPlayer = entity.IsOwnedByAnyPlayer
	entity.IsOwnedByAnyPlayer = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsOwnedByAnyPlayer called for null entity.")
			return false
		end
		if (vanillaIsOwnedByAnyPlayer) then
			return vanillaIsOwnedByAnyPlayer(self, ...)
		end
		return false
	end

	local vanillaIsPhantom = entity.IsPhantom
	entity.IsPhantom = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsPhantom called for null entity.")
			return false
		end
		if (vanillaIsPhantom) then
			return vanillaIsPhantom(self, ...)
		end
		return false
	end

	local vanillaIsPhantomBlocker = entity.IsPhantomBlocker
	entity.IsPhantomBlocker = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsPhantomBlocker called for null entity.")
			return false
		end
		if (vanillaIsPhantomBlocker) then
			return vanillaIsPhantomBlocker(self, ...)
		end
		return false
	end

	local vanillaIsPhased = entity.IsPhased
	entity.IsPhased = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsPhased called for null entity.")
			return false
		end
		if (vanillaIsPhased) then
			return vanillaIsPhased(self, ...)
		end
		return false
	end

	local vanillaIsPositionInRange = entity.IsPositionInRange
	entity.IsPositionInRange = function(self, vPosition, flRange, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsPositionInRange called for null entity.")
			return false
		end
		if (type(vPosition) ~= "userdata") then
			Debug_PrintError("CDOTA_BaseNPC.IsPositionInRange expected vPosition as Vector.")
			return false
		end
		flRange = tonumber(flRange)
		if (not flRange) then
			Debug_PrintError("CDOTA_BaseNPC.IsPositionInRange expected flRange as number.")
			return false
		end
		if (vanillaIsPositionInRange) then
			return vanillaIsPositionInRange(self, vPosition, flRange, ...)
		end
		return false
	end

	local vanillaIsRangedAttacker = entity.IsRangedAttacker
	entity.IsRangedAttacker = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsRangedAttacker called for null entity.")
			return false
		end
		if (vanillaIsRangedAttacker) then
			return vanillaIsRangedAttacker(self, ...)
		end
		return false
	end

	local vanillaIsRealHero = entity.IsRealHero
	entity.IsRealHero = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsRealHero called for null entity.")
			return false
		end
		if (vanillaIsRealHero) then
			return vanillaIsRealHero(self, ...)
		end
		return false
	end

	local vanillaIsReincarnating = entity.IsReincarnating
	entity.IsReincarnating = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsReincarnating called for null entity.")
			return false
		end
		if (vanillaIsReincarnating) then
			return vanillaIsReincarnating(self, ...)
		end
		return false
	end

	local vanillaIsRooted = entity.IsRooted
	entity.IsRooted = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsRooted called for null entity.")
			return false
		end
		if (vanillaIsRooted) then
			return vanillaIsRooted(self, ...)
		end
		return false
	end

	local vanillaIsShrine = entity.IsShrine
	entity.IsShrine = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsShrine called for null entity.")
			return false
		end
		if (vanillaIsShrine) then
			return vanillaIsShrine(self, ...)
		end
		return false
	end

	local vanillaIsSilenced = entity.IsSilenced
	entity.IsSilenced = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsSilenced called for null entity.")
			return false
		end
		if (vanillaIsSilenced) then
			return vanillaIsSilenced(self, ...)
		end
		return false
	end

	local vanillaIsSpeciallyDeniable = entity.IsSpeciallyDeniable
	entity.IsSpeciallyDeniable = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsSpeciallyDeniable called for null entity.")
			return false
		end
		if (vanillaIsSpeciallyDeniable) then
			return vanillaIsSpeciallyDeniable(self, ...)
		end
		return false
	end

	local vanillaIsSpeciallyUndeniable = entity.IsSpeciallyUndeniable
	entity.IsSpeciallyUndeniable = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsSpeciallyUndeniable called for null entity.")
			return false
		end
		if (vanillaIsSpeciallyUndeniable) then
			return vanillaIsSpeciallyUndeniable(self, ...)
		end
		return false
	end

	local vanillaIsStunned = entity.IsStunned
	entity.IsStunned = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsStunned called for null entity.")
			return false
		end
		if (vanillaIsStunned) then
			return vanillaIsStunned(self, ...)
		end
		return false
	end

	local vanillaIsSummoned = entity.IsSummoned
	entity.IsSummoned = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsSummoned called for null entity.")
			return false
		end
		if (vanillaIsSummoned) then
			return vanillaIsSummoned(self, ...)
		end
		return false
	end

	local vanillaIsTempestDouble = entity.IsTempestDouble
	entity.IsTempestDouble = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsTempestDouble called for null entity.")
			return false
		end
		if (vanillaIsTempestDouble) then
			return vanillaIsTempestDouble(self, ...)
		end
		return false
	end

	local vanillaIsTower = entity.IsTower
	entity.IsTower = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsTower called for null entity.")
			return false
		end
		if (vanillaIsTower) then
			return vanillaIsTower(self, ...)
		end
		return false
	end

	local vanillaIsUnableToMiss = entity.IsUnableToMiss
	entity.IsUnableToMiss = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsUnableToMiss called for null entity.")
			return false
		end
		if (vanillaIsUnableToMiss) then
			return vanillaIsUnableToMiss(self, ...)
		end
		return false
	end

	local vanillaIsUnselectable = entity.IsUnselectable
	entity.IsUnselectable = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsUnselectable called for null entity.")
			return false
		end
		if (vanillaIsUnselectable) then
			return vanillaIsUnselectable(self, ...)
		end
		return false
	end

	local vanillaIsUntargetable = entity.IsUntargetable
	entity.IsUntargetable = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsUntargetable called for null entity.")
			return false
		end
		if (vanillaIsUntargetable) then
			return vanillaIsUntargetable(self, ...)
		end
		return false
	end

	local vanillaIsZombie = entity.IsZombie
	entity.IsZombie = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.IsZombie called for null entity.")
			return false
		end
		if (vanillaIsZombie) then
			return vanillaIsZombie(self, ...)
		end
		return false
	end

	local vanillaKill = entity.Kill
	entity.Kill = function(self, hAbility, hAttacker, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.Kill called for null entity.")
			return
		end
		if (type(hAbility) ~= "table" or hAbility.IsNull == nil or hAbility:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.Kill expected hAbility as valid not null entity.")
			return
		end
		if (type(hAttacker) ~= "table" or hAttacker.IsNull == nil or hAttacker:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.Kill expected hAttacker as valid not null entity.")
			return
		end
		if (vanillaKill) then
			vanillaKill(self, hAbility, hAttacker, ...)
		end

	end

	local vanillaMakeIllusion = entity.MakeIllusion
	entity.MakeIllusion = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.MakeIllusion called for null entity.")
			return
		end
		if (vanillaMakeIllusion) then
			vanillaMakeIllusion(self, ...)
		end

	end

	local vanillaMakePhantomBlocker = entity.MakePhantomBlocker
	entity.MakePhantomBlocker = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.MakePhantomBlocker called for null entity.")
			return
		end
		if (vanillaMakePhantomBlocker) then
			vanillaMakePhantomBlocker(self, ...)
		end

	end

	local vanillaMakeVisibleDueToAttack = entity.MakeVisibleDueToAttack
	entity.MakeVisibleDueToAttack = function(self, iTeam, flRadius, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.MakeVisibleDueToAttack called for null entity.")
			return
		end
		iTeam = tonumber(iTeam)
		if (not iTeam) then
			Debug_PrintError("CDOTA_BaseNPC.MakeVisibleDueToAttack expected iTeam as number.")
			return
		end
		flRadius = tonumber(flRadius)
		if (not flRadius) then
			Debug_PrintError("CDOTA_BaseNPC.MakeVisibleDueToAttack expected flRadius as number.")
			return
		end
		if (vanillaMakeVisibleDueToAttack) then
			vanillaMakeVisibleDueToAttack(self, iTeam, flRadius, ...)
		end

	end

	local vanillaMakeVisibleToTeam = entity.MakeVisibleToTeam
	entity.MakeVisibleToTeam = function(self, iTeam, flDuration, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.MakeVisibleToTeam called for null entity.")
			return
		end
		iTeam = tonumber(iTeam)
		if (not iTeam) then
			Debug_PrintError("CDOTA_BaseNPC.MakeVisibleToTeam expected iTeam as number.")
			return
		end
		flDuration = tonumber(flDuration)
		if (not flDuration) then
			Debug_PrintError("CDOTA_BaseNPC.MakeVisibleToTeam expected flDuration as number.")
			return
		end
		if (vanillaMakeVisibleToTeam) then
			vanillaMakeVisibleToTeam(self, iTeam, flDuration, ...)
		end

	end

	local vanillaManageModelChanges = entity.ManageModelChanges
	entity.ManageModelChanges = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.ManageModelChanges called for null entity.")
			return
		end
		if (vanillaManageModelChanges) then
			vanillaManageModelChanges(self, ...)
		end

	end

	local vanillaModifyHealth = entity.ModifyHealth
	entity.ModifyHealth = function(self, iDesiredHealthValue, hAbility, bLethal, iAdditionalFlags, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.ModifyHealth called for null entity.")
			return
		end
		iDesiredHealthValue = tonumber(iDesiredHealthValue)
		if (not iDesiredHealthValue) then
			Debug_PrintError("CDOTA_BaseNPC.ModifyHealth expected iDesiredHealthValue as number.")
			return
		end
		if (type(hAbility) ~= "table" or hAbility.IsNull == nil or hAbility:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.ModifyHealth expected hAbility as valid not null entity.")
			return
		end
		if (bLethal ~= true and bLethal ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.ModifyHealth expected bLethal as boolean.")
			return
		end
		iAdditionalFlags = tonumber(iAdditionalFlags)
		if (not iAdditionalFlags) then
			Debug_PrintError("CDOTA_BaseNPC.ModifyHealth expected iAdditionalFlags as number.")
			return
		end
		if (vanillaModifyHealth) then
			vanillaModifyHealth(self, iDesiredHealthValue, hAbility, bLethal, iAdditionalFlags, ...)
		end

	end

	local vanillaMoveToNPC = entity.MoveToNPC
	entity.MoveToNPC = function(self, hNPC, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.MoveToNPC called for null entity.")
			return
		end
		if (type(hNPC) ~= "table" or hNPC.IsNull == nil or hNPC:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.MoveToNPC expected hNPC as valid not null entity.")
			return
		end
		if (vanillaMoveToNPC) then
			vanillaMoveToNPC(self, hNPC, ...)
		end

	end

	local vanillaMoveToNPCToGiveItem = entity.MoveToNPCToGiveItem
	entity.MoveToNPCToGiveItem = function(self, hNPC, hItem, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.MoveToNPCToGiveItem called for null entity.")
			return
		end
		if (type(hNPC) ~= "table" or hNPC.IsNull == nil or hNPC:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.MoveToNPCToGiveItem expected hNPC as valid not null entity.")
			return
		end
		if (type(hItem) ~= "table" or hItem.IsNull == nil or hItem:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.MoveToNPCToGiveItem expected hItem as valid not null entity.")
			return
		end
		if (vanillaMoveToNPCToGiveItem) then
			vanillaMoveToNPCToGiveItem(self, hNPC, hItem, ...)
		end

	end

	local vanillaMoveToPosition = entity.MoveToPosition
	entity.MoveToPosition = function(self, vDest, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.MoveToPosition called for null entity.")
			return
		end
		if (type(vDest) ~= "userdata") then
			Debug_PrintError("CDOTA_BaseNPC.MoveToPosition expected vDest as Vector.")
			return
		end
		if (vanillaMoveToPosition) then
			vanillaMoveToPosition(self, vDest, ...)
		end

	end

	local vanillaMoveToPositionAggressive = entity.MoveToPositionAggressive
	entity.MoveToPositionAggressive = function(self, vDest, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.MoveToPositionAggressive called for null entity.")
			return
		end
		if (type(vDest) ~= "userdata") then
			Debug_PrintError("CDOTA_BaseNPC.MoveToPositionAggressive expected vDest as Vector.")
			return
		end
		if (vanillaMoveToPositionAggressive) then
			vanillaMoveToPositionAggressive(self, vDest, ...)
		end

	end

	local vanillaMoveToTargetToAttack = entity.MoveToTargetToAttack
	entity.MoveToTargetToAttack = function(self, hTarget, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.MoveToTargetToAttack called for null entity.")
			return
		end
		if (type(hTarget) ~= "table" or hTarget.IsNull == nil or hTarget:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.MoveToTargetToAttack expected hTarget as valid not null entity.")
			return
		end
		if (vanillaMoveToTargetToAttack) then
			vanillaMoveToTargetToAttack(self, hTarget, ...)
		end

	end

	local vanillaNoHealthBar = entity.NoHealthBar
	entity.NoHealthBar = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.NoHealthBar called for null entity.")
			return false
		end
		if (vanillaNoHealthBar) then
			return vanillaNoHealthBar(self, ...)
		end
		return false
	end

	local vanillaNoTeamMoveTo = entity.NoTeamMoveTo
	entity.NoTeamMoveTo = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.NoTeamMoveTo called for null entity.")
			return false
		end
		if (vanillaNoTeamMoveTo) then
			return vanillaNoTeamMoveTo(self, ...)
		end
		return false
	end

	local vanillaNoTeamSelect = entity.NoTeamSelect
	entity.NoTeamSelect = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.NoTeamSelect called for null entity.")
			return false
		end
		if (vanillaNoTeamSelect) then
			return vanillaNoTeamSelect(self, ...)
		end
		return false
	end

	local vanillaNoUnitCollision = entity.NoUnitCollision
	entity.NoUnitCollision = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.NoUnitCollision called for null entity.")
			return false
		end
		if (vanillaNoUnitCollision) then
			return vanillaNoUnitCollision(self, ...)
		end
		return false
	end

	local vanillaNotOnMinimap = entity.NotOnMinimap
	entity.NotOnMinimap = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.NotOnMinimap called for null entity.")
			return false
		end
		if (vanillaNotOnMinimap) then
			return vanillaNotOnMinimap(self, ...)
		end
		return false
	end

	local vanillaNotOnMinimapForEnemies = entity.NotOnMinimapForEnemies
	entity.NotOnMinimapForEnemies = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.NotOnMinimapForEnemies called for null entity.")
			return false
		end
		if (vanillaNotOnMinimapForEnemies) then
			return vanillaNotOnMinimapForEnemies(self, ...)
		end
		return false
	end

	local vanillaNotifyWearablesOfModelChange = entity.NotifyWearablesOfModelChange
	entity.NotifyWearablesOfModelChange = function(self, bOriginalModel, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.NotifyWearablesOfModelChange called for null entity.")
			return
		end
		if (bOriginalModel ~= true and bOriginalModel ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.NotifyWearablesOfModelChange expected bOriginalModel as boolean.")
			return
		end
		if (vanillaNotifyWearablesOfModelChange) then
			vanillaNotifyWearablesOfModelChange(self, bOriginalModel, ...)
		end

	end

	local vanillaPassivesDisabled = entity.PassivesDisabled
	entity.PassivesDisabled = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.PassivesDisabled called for null entity.")
			return false
		end
		if (vanillaPassivesDisabled) then
			return vanillaPassivesDisabled(self, ...)
		end
		return false
	end

	local vanillaPatrolToPosition = entity.PatrolToPosition
	entity.PatrolToPosition = function(self, vDest, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.PatrolToPosition called for null entity.")
			return
		end
		if (type(vDest) ~= "userdata") then
			Debug_PrintError("CDOTA_BaseNPC.PatrolToPosition expected vDest as Vector.")
			return
		end
		if (vanillaPatrolToPosition) then
			vanillaPatrolToPosition(self, vDest, ...)
		end

	end

	local vanillaPerformAttack = entity.PerformAttack
	entity.PerformAttack = function(self, hTarget, bUseCastAttackOrb, bProcessProcs, bSkipCooldown, bIgnoreInvis, bUseProjectile, bFakeAttack, bNeverMiss, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.PerformAttack called for null entity.")
			return
		end
		if (type(hTarget) ~= "table" or hTarget.IsNull == nil or hTarget:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.PerformAttack expected hTarget as valid not null entity.")
			return
		end
		if (bUseCastAttackOrb ~= true and bUseCastAttackOrb ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.PerformAttack expected bUseCastAttackOrb as boolean.")
			return
		end
		if (bProcessProcs ~= true and bProcessProcs ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.PerformAttack expected bProcessProcs as boolean.")
			return
		end
		if (bSkipCooldown ~= true and bSkipCooldown ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.PerformAttack expected bSkipCooldown as boolean.")
			return
		end
		if (bIgnoreInvis ~= true and bIgnoreInvis ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.PerformAttack expected bIgnoreInvis as boolean.")
			return
		end
		if (bUseProjectile ~= true and bUseProjectile ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.PerformAttack expected bUseProjectile as boolean.")
			return
		end
		if (bFakeAttack ~= true and bFakeAttack ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.PerformAttack expected bFakeAttack as boolean.")
			return
		end
		if (bNeverMiss ~= true and bNeverMiss ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.PerformAttack expected bNeverMiss as boolean.")
			return
		end
		if (vanillaPerformAttack) then
			vanillaPerformAttack(self, hTarget, bUseCastAttackOrb, bProcessProcs, bSkipCooldown, bIgnoreInvis, bUseProjectile, bFakeAttack, bNeverMiss, ...)
		end

	end
	_OverrideBaseNPCFunctionsThird(entity)
end

-- This function return try catch into valve code to prevent 7.31 crash due to null (at least supposed to)...
function _OverrideBaseNPCFunctions(entity)
	_OverrideBaseFlexFunctions(entity)
	if(entity._OverrideBaseNPCFunctionsUsed) then
		return
	end
	-- CDOTA_BaseNPC

	local vanillaAddAbility = entity.AddAbility
	entity.AddAbility = function(self, pszAbilityName, ...)
		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.AddAbility called for null entity.")
			return nil
		end
		if (type(pszAbilityName) ~= "string") then
			Debug_PrintError("CDOTA_BaseNPC.AddAbility expected pszAbilityName as string.")
			return nil
		end
		if (vanillaAddAbility) then
			local ability = vanillaAddAbility(self, pszAbilityName, ...)
			if(ability) then
				_OverrideAbilityFunctions(ability)
				return ability
			end
			return nil
		end
		return nil
	end

	local vanillaAddActivityModifier = entity.AddActivityModifier
	entity.AddActivityModifier = function(self, szName, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.AddActivityModifier called for null entity.")
			return
		end
		if (type(szName) ~= "string") then
			Debug_PrintError("CDOTA_BaseNPC.AddActivityModifier expected szName as string.")
			return
		end
		if (vanillaAddActivityModifier) then
			vanillaAddActivityModifier(self, szName, ...)
		end

	end

	local vanillaAddItem = entity.AddItem
	entity.AddItem = function(self, hItem, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.AddItem called for null entity.")
			return nil
		end
		if (type(hItem) ~= "table" or hItem.IsNull == nil or hItem:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.AddItem expected hItem as valid not null entity.")
			return nil
		end
		if (vanillaAddItem) then
			local item = vanillaAddItem(self, hItem, ...)
			if(item) then
				_OverrideItemFunctions(item)
				return item
			end
			return nil
		end
		return nil
	end

	local vanillaAddItemByName = entity.AddItemByName
	entity.AddItemByName = function(self, pszItemName, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.AddItemByName called for null entity.")
			return nil
		end
		if (type(pszItemName) ~= "string") then
			Debug_PrintError("CDOTA_BaseNPC.AddItemByName expected pszItemName as string.")
			return nil
		end
		if (vanillaAddItemByName) then
			local item = vanillaAddItemByName(self, pszItemName, ...)
			if(item) then
				_OverrideItemFunctions(item)
				return item
			end
			return nil
		end
		return nil
	end

	local ModifierCCStates = {
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_HEXED] = true,
		[MODIFIER_STATE_SILENCED] = true,
		[MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_FROZEN] = true,
		[MODIFIER_STATE_NIGHTMARED] = true,
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_PASSIVES_DISABLED] = true,
		[MODIFIER_STATE_BLIND] = true,
		[MODIFIER_STATE_TAUNTED] = true,
		[MODIFIER_STATE_TETHERED] = true
	}

	local vanillaAddNewModifier = entity.AddNewModifier
	entity.AddNewModifier = function(self, hCaster, hAbility, pszScriptName, hModifierTable, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.AddNewModifier called for null entity.")
		return nil
		end
		if (type(hCaster) ~= "table" or hCaster.IsNull == nil or hCaster:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.AddNewModifier expected hCaster as valid not null entity.")
			return nil
		end
		if (hAbility ~= nil and (type(hAbility) ~= "table" or hAbility.IsNull == nil or hAbility:IsNull() == true)) then
			Debug_PrintError("CDOTA_BaseNPC.AddNewModifier expected hAbility as valid not null entity.")
			return nil
		end
		if (type(pszScriptName) ~= "string") then
			Debug_PrintError("CDOTA_BaseNPC.AddNewModifier expected pszScriptName as string.")
			return nil
		end
		if (hModifierTable ~= nil and (type(hModifierTable) ~= "table")) then
			Debug_PrintError("CDOTA_BaseNPC.AddNewModifier expected hModifierTable as valid table.")
			return nil
		end
		local modifier = vanillaAddNewModifier(self, hCaster, hAbility, pszScriptName, hModifierTable, ...)
		if(not modifier or not hModifierTable or not hModifierTable.duration or (hModifierTable.duration and hModifierTable.duration < 0.01)) then
			return modifier
		end
		local buffsAmplificationPct = 1
		local isDebuff = (modifier.IsDebuff and modifier:IsDebuff() == true) or false
		if(isDebuff == false) then
			local allModifiers = hCaster:FindAllModifiers()
			for _, modifier in pairs(hCaster:FindAllModifiers()) do
				if(modifier.GetModifierBuffsDurationAmplificationPercent) then
					buffsAmplificationPct = buffsAmplificationPct + ((tonumber(modifier:GetModifierBuffsDurationAmplificationPercent() or 0) or 0) / 100)
				end
			end
			hModifierTable.duration = hModifierTable.duration * buffsAmplificationPct
			modifier:SetDuration(hModifierTable.duration, true)
		end
		-- modifier_invoker_tornado is npc_boss_fire_3 tornado modifier for combo (someone rewrite that skill and modifiers to lua please...)
		if((modifier.IsIgnoreStatusResistance and modifier:IsIgnoreStatusResistance() == true) or modifier:GetName() == "modifier_invoker_tornado") then
			return modifier
		end
		if(hCaster ~= self) then
			local modifierState = {} 
			modifier:CheckStateToTable(modifierState)
			local isAffectedByStatusResistance = false
			for state, value in pairs(modifierState) do
				if(ModifierCCStates[tonumber(state) or -1] and value == true) then
					isAffectedByStatusResistance = true
					break
				end
			end
			if(isAffectedByStatusResistance == true) then
				OpenEvents:RunEventByName(OPEN_EVENT_ON_MODIFIER_PRE_STATUS_RESISTANCE, {
					caster = hCaster,
					target = self,
					modifier = modifier
				})
				local newDuration = hModifierTable.duration * (1 - self:GetStatusResistance())
				modifier:SetDuration(newDuration, true)
			end
		end
		return modifier
	end

	local vanillaAddNoDraw = entity.AddNoDraw
	entity.AddNoDraw = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.AddNoDraw called for null entity.")
			return
		end
		if (vanillaAddNoDraw) then
			vanillaAddNoDraw(self, ...)
		end

	end

	local vanillaAddSpeechBubble = entity.AddSpeechBubble
	entity.AddSpeechBubble = function(self, iBubble, pszSpeech, flDuration, unOffsetX, unOffsetY, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.AddSpeechBubble called for null entity.")
			return
		end
		iBubble = tonumber(iBubble)
		if (not iBubble) then
			Debug_PrintError("CDOTA_BaseNPC.AddSpeechBubble expected iBubble as number.")
			return
		end
		if (type(pszSpeech) ~= "string") then
			Debug_PrintError("CDOTA_BaseNPC.AddSpeechBubble expected pszSpeech as string.")
			return
		end
		flDuration = tonumber(flDuration)
		if (not flDuration) then
			Debug_PrintError("CDOTA_BaseNPC.AddSpeechBubble expected flDuration as number.")
			return
		end
		unOffsetX = tonumber(unOffsetX)
		if (not unOffsetX) then
			Debug_PrintError("CDOTA_BaseNPC.AddSpeechBubble expected unOffsetX as number.")
			return
		end
		unOffsetY = tonumber(unOffsetY)
		if (not unOffsetY) then
			Debug_PrintError("CDOTA_BaseNPC.AddSpeechBubble expected unOffsetY as number.")
			return
		end
		if (vanillaAddSpeechBubble) then
			vanillaAddSpeechBubble(self, iBubble, pszSpeech, flDuration, unOffsetX, unOffsetY, ...)
		end

	end

	local vanillaAlertNearbyUnits = entity.AlertNearbyUnits
	entity.AlertNearbyUnits = function(self, hAttacker, hAbility, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.AlertNearbyUnits called for null entity.")
			return
		end
		if (type(hAttacker) ~= "table" or hAttacker.IsNull == nil or hAttacker:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.AlertNearbyUnits expected hAttacker as valid not null entity.")
			return
		end
		if (type(hAbility) ~= "table" or hAbility.IsNull == nil or hAbility:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.AlertNearbyUnits expected hAbility as valid not null entity.")
			return
		end
		if (vanillaAlertNearbyUnits) then
			vanillaAlertNearbyUnits(self, hAttacker, hAbility, ...)
		end

	end

	local vanillaAngerNearbyUnits = entity.AngerNearbyUnits
	entity.AngerNearbyUnits = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.AngerNearbyUnits called for null entity.")
			return
		end
		if (vanillaAngerNearbyUnits) then
			vanillaAngerNearbyUnits(self, ...)
		end

	end

	local vanillaAttackNoEarlierThan = entity.AttackNoEarlierThan
	entity.AttackNoEarlierThan = function(self, flTime, flTimeDisparityTolerance, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.AttackNoEarlierThan called for null entity.")
			return
		end
		flTime = tonumber(flTime)
		if (not flTime) then
			Debug_PrintError("CDOTA_BaseNPC.AttackNoEarlierThan expected flTime as number.")
			return
		end
		flTimeDisparityTolerance = tonumber(flTimeDisparityTolerance)
		if (not flTimeDisparityTolerance) then
			Debug_PrintError("CDOTA_BaseNPC.AttackNoEarlierThan expected flTimeDisparityTolerance as number.")
			return
		end
		if (vanillaAttackNoEarlierThan) then
			vanillaAttackNoEarlierThan(self, flTime, flTimeDisparityTolerance, ...)
		end

	end

	local vanillaAttackReady = entity.AttackReady
	entity.AttackReady = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.AttackReady called for null entity.")
			return false
		end
		if (vanillaAttackReady) then
			return vanillaAttackReady(self, ...)
		end
		return false
	end

	local vanillaBoundingRadius2D = entity.BoundingRadius2D
	entity.BoundingRadius2D = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.BoundingRadius2D called for null entity.")
			return 0
		end
		if (vanillaBoundingRadius2D) then
			return vanillaBoundingRadius2D(self, ...)
		end
		return 0
	end

	local vanillaCalculateGenericBonuses = entity.CalculateGenericBonuses
	entity.CalculateGenericBonuses = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.CalculateGenericBonuses called for null entity.")
			return
		end
		if (vanillaCalculateGenericBonuses) then
			vanillaCalculateGenericBonuses(self, ...)
		end

	end

	local vanillaCanBeSeenByAnyOpposingTeam = entity.CanBeSeenByAnyOpposingTeam
	entity.CanBeSeenByAnyOpposingTeam = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.CanBeSeenByAnyOpposingTeam called for null entity.")
			return false
		end
		if (vanillaCanBeSeenByAnyOpposingTeam) then
			return vanillaCanBeSeenByAnyOpposingTeam(self, ...)
		end
		return false
	end

	local vanillaCanEntityBeSeenByMyTeam = entity.CanEntityBeSeenByMyTeam
	entity.CanEntityBeSeenByMyTeam = function(self, hEntity, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.CanEntityBeSeenByMyTeam called for null entity.")
			return false
		end
		if (type(hEntity) ~= "table" or hEntity.IsNull == nil or hEntity:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.CanEntityBeSeenByMyTeam expected hEntity as valid not null entity.")
			return false
		end
		if (vanillaCanEntityBeSeenByMyTeam) then
			return vanillaCanEntityBeSeenByMyTeam(self, hEntity, ...)
		end
		return false
	end

	local vanillaCanSellItems = entity.CanSellItems
	entity.CanSellItems = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.CanSellItems called for null entity.")
			return false
		end
		if (vanillaCanSellItems) then
			return vanillaCanSellItems(self, ...)
		end
		return false
	end

	local vanillaCastAbilityImmediately = entity.CastAbilityImmediately
	entity.CastAbilityImmediately = function(self, hAbility, iPlayerIndex, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.CastAbilityImmediately called for null entity.")
			return
		end
		if (type(hAbility) ~= "table" or hAbility.IsNull == nil or hAbility:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.CastAbilityImmediately expected hAbility as valid not null entity.")
			return
		end
		iPlayerIndex = tonumber(iPlayerIndex)
		if (not iPlayerIndex) then
			Debug_PrintError("CDOTA_BaseNPC.CastAbilityImmediately expected iPlayerIndex as number.")
			return
		end
		if (vanillaCastAbilityImmediately) then
			vanillaCastAbilityImmediately(self, hAbility, iPlayerIndex, ...)
		end

	end

	local vanillaCastAbilityNoTarget = entity.CastAbilityNoTarget
	entity.CastAbilityNoTarget = function(self, hAbility, iPlayerIndex, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.CastAbilityNoTarget called for null entity.")
			return
		end
		if (type(hAbility) ~= "table" or hAbility.IsNull == nil or hAbility:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.CastAbilityNoTarget expected hAbility as valid not null entity.")
			return
		end
		iPlayerIndex = tonumber(iPlayerIndex)
		if (not iPlayerIndex) then
			Debug_PrintError("CDOTA_BaseNPC.CastAbilityNoTarget expected iPlayerIndex as number.")
			return
		end
		if (vanillaCastAbilityNoTarget) then
			vanillaCastAbilityNoTarget(self, hAbility, iPlayerIndex, ...)
		end

	end

	local vanillaCastAbilityOnPosition = entity.CastAbilityOnPosition
	entity.CastAbilityOnPosition = function(self, vPosition, hAbility, iPlayerIndex, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.CastAbilityOnPosition called for null entity.")
			return
		end
		if (type(vPosition) ~= "userdata") then
			Debug_PrintError("CDOTA_BaseNPC.CastAbilityOnPosition expected vPosition as Vector.")
			return
		end
		if (type(hAbility) ~= "table" or hAbility.IsNull == nil or hAbility:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.CastAbilityOnPosition expected hAbility as valid not null entity.")
			return
		end
		iPlayerIndex = tonumber(iPlayerIndex)
		if (not iPlayerIndex) then
			Debug_PrintError("CDOTA_BaseNPC.CastAbilityOnPosition expected iPlayerIndex as number.")
			return
		end
		if (vanillaCastAbilityOnPosition) then
			vanillaCastAbilityOnPosition(self, vPosition, hAbility, iPlayerIndex, ...)
		end

	end

	local vanillaCastAbilityOnTarget = entity.CastAbilityOnTarget
	entity.CastAbilityOnTarget = function(self, hTarget, hAbility, iPlayerIndex, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.CastAbilityOnTarget called for null entity.")
			return
		end
		if (type(hTarget) ~= "table" or hTarget.IsNull == nil or hTarget:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.CastAbilityOnTarget expected hTarget as valid not null entity.")
			return
		end
		if (type(hAbility) ~= "table" or hAbility.IsNull == nil or hAbility:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.CastAbilityOnTarget expected hAbility as valid not null entity.")
			return
		end
		iPlayerIndex = tonumber(iPlayerIndex)
		if (not iPlayerIndex) then
			Debug_PrintError("CDOTA_BaseNPC.CastAbilityOnTarget expected iPlayerIndex as number.")
			return
		end
		if (vanillaCastAbilityOnTarget) then
			vanillaCastAbilityOnTarget(self, hTarget, hAbility, iPlayerIndex, ...)
		end

	end

	local vanillaCastAbilityToggle = entity.CastAbilityToggle
	entity.CastAbilityToggle = function(self, hAbility, iPlayerIndex, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.CastAbilityToggle called for null entity.")
			return
		end
		if (type(hAbility) ~= "table" or hAbility.IsNull == nil or hAbility:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.CastAbilityToggle expected hAbility as valid not null entity.")
			return
		end
		iPlayerIndex = tonumber(iPlayerIndex)
		if (not iPlayerIndex) then
			Debug_PrintError("CDOTA_BaseNPC.CastAbilityToggle expected iPlayerIndex as number.")
			return
		end
		if (vanillaCastAbilityToggle) then
			vanillaCastAbilityToggle(self, hAbility, iPlayerIndex, ...)
		end

	end

	local vanillaChangeTeam = entity.ChangeTeam
	entity.ChangeTeam = function(self, iTeamNum, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.ChangeTeam called for null entity.")
			return
		end
		iTeamNum = tonumber(iTeamNum)
		if (not iTeamNum) then
			Debug_PrintError("CDOTA_BaseNPC.ChangeTeam expected iTeamNum as number.")
			return
		end
		if (vanillaChangeTeam) then
			vanillaChangeTeam(self, iTeamNum, ...)
		end

	end

	local vanillaClearActivityModifiers = entity.ClearActivityModifiers
	entity.ClearActivityModifiers = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.ClearActivityModifiers called for null entity.")
			return
		end
		if (vanillaClearActivityModifiers) then
			vanillaClearActivityModifiers(self, ...)
		end

	end

	local vanillaDestroyAllSpeechBubbles = entity.DestroyAllSpeechBubbles
	entity.DestroyAllSpeechBubbles = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.DestroyAllSpeechBubbles called for null entity.")
			return
		end
		if (vanillaDestroyAllSpeechBubbles) then
			vanillaDestroyAllSpeechBubbles(self, ...)
		end

	end

	local vanillaDisassembleItem = entity.DisassembleItem
	entity.DisassembleItem = function(self, hItem, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.DisassembleItem called for null entity.")
			return
		end
		if (type(hItem) ~= "table" or hItem.IsNull == nil or hItem:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.DisassembleItem expected hItem as valid not null entity.")
			return
		end
		if (vanillaDisassembleItem) then
			vanillaDisassembleItem(self, hItem, ...)
		end

	end

	local vanillaDropItemAtPosition = entity.DropItemAtPosition
	entity.DropItemAtPosition = function(self, vDest, hItem, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.DropItemAtPosition called for null entity.")
			return
		end
		if (type(vDest) ~= "userdata") then
			Debug_PrintError("CDOTA_BaseNPC.DropItemAtPosition expected vDest as Vector.")
			return
		end
		if (type(hItem) ~= "table" or hItem.IsNull == nil or hItem:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.DropItemAtPosition expected hItem as valid not null entity.")
			return
		end
		if (vanillaDropItemAtPosition) then
			vanillaDropItemAtPosition(self, vDest, hItem, ...)
		end

	end

	local vanillaDropItemAtPositionImmediate = entity.DropItemAtPositionImmediate
	entity.DropItemAtPositionImmediate = function(self, hItem, vPosition, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.DropItemAtPositionImmediate called for null entity.")
			return
		end
		if (type(hItem) ~= "table" or hItem.IsNull == nil or hItem:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.DropItemAtPositionImmediate expected hItem as valid not null entity.")
			return
		end
		if (type(vPosition) ~= "userdata") then
			Debug_PrintError("CDOTA_BaseNPC.DropItemAtPositionImmediate expected vPosition as Vector.")
			return
		end
		if (vanillaDropItemAtPositionImmediate) then
			vanillaDropItemAtPositionImmediate(self, hItem, vPosition, ...)
		end

	end

	local vanillaEjectItemFromStash = entity.EjectItemFromStash
	entity.EjectItemFromStash = function(self, hItem, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.EjectItemFromStash called for null entity.")
			return
		end
		if (type(hItem) ~= "table" or hItem.IsNull == nil or hItem:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.EjectItemFromStash expected hItem as valid not null entity.")
			return
		end
		if (vanillaEjectItemFromStash) then
			vanillaEjectItemFromStash(self, hItem, ...)
		end

	end

	local vanillaFaceTowards = entity.FaceTowards
	entity.FaceTowards = function(self, vTarget, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.FaceTowards called for null entity.")
			return
		end
		if (type(vTarget) ~= "userdata") then
			Debug_PrintError("CDOTA_BaseNPC.FaceTowards expected vTarget as Vector.")
			return
		end
		if (vanillaFaceTowards) then
			vanillaFaceTowards(self, vTarget, ...)
		end

	end

	local vanillaFadeGesture = entity.FadeGesture
	entity.FadeGesture = function(self, nActivity, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.FadeGesture called for null entity.")
			return
		end
		nActivity = tonumber(nActivity)
		if (not nActivity) then
			Debug_PrintError("CDOTA_BaseNPC.FadeGesture expected nActivity as number.")
			return
		end
		if (vanillaFadeGesture) then
			vanillaFadeGesture(self, nActivity, ...)
		end

	end

	local vanillaFindAbilityByName = entity.FindAbilityByName
	entity.FindAbilityByName = function(self, pAbilityName, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.FindAbilityByName called for null entity.")
			return nil
		end
		if (type(pAbilityName) ~= "string") then
			Debug_PrintError("CDOTA_BaseNPC.FindAbilityByName expected pAbilityName as string.")
			return nil
		end
		if (vanillaFindAbilityByName) then
			return vanillaFindAbilityByName(self, pAbilityName, ...)
		end
		return nil
	end

	local vanillaFindAllModifiers = entity.FindAllModifiers
	entity.FindAllModifiers = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.FindAllModifiers called for null entity.")
			return {}
		end
		if (vanillaFindAllModifiers) then
			return vanillaFindAllModifiers(self, ...)
		end
		return {}
	end

	local vanillaFindAllModifiersByName = entity.FindAllModifiersByName
	entity.FindAllModifiersByName = function(self, pszScriptName, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.FindAllModifiersByName called for null entity.")
			return {}
		end
		if (type(pszScriptName) ~= "string") then
			Debug_PrintError("CDOTA_BaseNPC.FindAllModifiersByName expected pszScriptName as string.")
			return {}
		end
		if (vanillaFindAllModifiersByName) then
			return vanillaFindAllModifiersByName(self, pszScriptName, ...)
		end
		return {}
	end

	local vanillaFindItemInInventory = entity.FindItemInInventory
	entity.FindItemInInventory = function(self, pszItemName, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.FindItemInInventory called for null entity.")
			return nil
		end
		if (type(pszItemName) ~= "string") then
			Debug_PrintError("CDOTA_BaseNPC.FindItemInInventory expected pszItemName as string.")
			return nil
		end
		if (vanillaFindItemInInventory) then
			return vanillaFindItemInInventory(self, pszItemName, ...)
		end
		return nil
	end

	local vanillaFindModifierByName = entity.FindModifierByName
	entity.FindModifierByName = function(self, pszScriptName, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.FindModifierByName called for null entity.")
			return nil
		end
		if (type(pszScriptName) ~= "string") then
			Debug_PrintError("CDOTA_BaseNPC.FindModifierByName expected pszScriptName as string.")
			return nil
		end
		if (vanillaFindModifierByName) then
			return vanillaFindModifierByName(self, pszScriptName, ...)
		end
		return nil
	end

	local vanillaFindModifierByNameAndCaster = entity.FindModifierByNameAndCaster
	entity.FindModifierByNameAndCaster = function(self, pszScriptName, hCaster, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.FindModifierByNameAndCaster called for null entity.")
			return nil
		end
		if (type(pszScriptName) ~= "string") then
			Debug_PrintError("CDOTA_BaseNPC.FindModifierByNameAndCaster expected pszScriptName as string.")
			return nil
		end
		if (type(hCaster) ~= "table" or hCaster.IsNull == nil or hCaster:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.FindModifierByNameAndCaster expected hCaster as valid not null entity.")
			return nil
		end
		if (vanillaFindModifierByNameAndCaster) then
			return vanillaFindModifierByNameAndCaster(self, pszScriptName, hCaster, ...)
		end
		return nil
	end

	local vanillaForceKill = entity.ForceKill
	entity.ForceKill = function(self, bReincarnate, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.ForceKill called for null entity.")
			return
		end
		if (bReincarnate ~= true and bReincarnate ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.ForceKill expected bReincarnate as boolean.")
			return
		end
		if (vanillaForceKill) then
			vanillaForceKill(self, bReincarnate, ...)
		end

	end

	local vanillaForcePlayActivityOnce = entity.ForcePlayActivityOnce
	entity.ForcePlayActivityOnce = function(self, nActivity, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.ForcePlayActivityOnce called for null entity.")
			return
		end
		nActivity = tonumber(nActivity)
		if (not nActivity) then
			Debug_PrintError("CDOTA_BaseNPC.ForcePlayActivityOnce expected nActivity as number.")
			return
		end
		if (vanillaForcePlayActivityOnce) then
			vanillaForcePlayActivityOnce(self, nActivity, ...)
		end

	end

	local vanillaGetAbilityByIndex = entity.GetAbilityByIndex
	entity.GetAbilityByIndex = function(self, iIndex, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetAbilityByIndex called for null entity.")
			return nil
		end
		iIndex = tonumber(iIndex)
		if (not iIndex) then
			Debug_PrintError("CDOTA_BaseNPC.GetAbilityByIndex expected iIndex as number.")
			return nil
		end
		if (vanillaGetAbilityByIndex) then
			return vanillaGetAbilityByIndex(self, iIndex, ...)
		end
		return nil
	end

	local vanillaGetAbilityCount = entity.GetAbilityCount
	entity.GetAbilityCount = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetAbilityCount called for null entity.")
			return 0
		end
		if (vanillaGetAbilityCount) then
			return vanillaGetAbilityCount(self, ...)
		end
		return 0
	end

	local vanillaGetAcquisitionRange = entity.GetAcquisitionRange
	entity.GetAcquisitionRange = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetAcquisitionRange called for null entity.")
			return 0
		end
		if (vanillaGetAcquisitionRange) then
			return vanillaGetAcquisitionRange(self, ...)
		end
		return 0
	end

	local vanillaGetAdditionalBattleMusicWeight = entity.GetAdditionalBattleMusicWeight
	entity.GetAdditionalBattleMusicWeight = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetAdditionalBattleMusicWeight called for null entity.")
			return 0
		end
		if (vanillaGetAdditionalBattleMusicWeight) then
			return vanillaGetAdditionalBattleMusicWeight(self, ...)
		end
		return 0
	end

	local vanillaGetAggroTarget = entity.GetAggroTarget
	entity.GetAggroTarget = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetAggroTarget called for null entity.")
			return nil
		end
		if (vanillaGetAggroTarget) then
			return vanillaGetAggroTarget(self, ...)
		end
		return nil
	end

	local vanillaGetAttackAnimationPoint = entity.GetAttackAnimationPoint
	entity.GetAttackAnimationPoint = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetAttackAnimationPoint called for null entity.")
			return 1
		end
		if (vanillaGetAttackAnimationPoint) then
			return vanillaGetAttackAnimationPoint(self, ...)
		end
		return 1
	end

	local vanillaGetAttackCapability = entity.GetAttackCapability
	entity.GetAttackCapability = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetAttackCapability called for null entity.")
			return DOTA_UNIT_CAP_NO_ATTACK
		end
		if (vanillaGetAttackCapability) then
			return vanillaGetAttackCapability(self, ...)
		end
		return DOTA_UNIT_CAP_NO_ATTACK
	end

	local vanillaGetAttackDamage = entity.GetAttackDamage
	entity.GetAttackDamage = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetAttackDamage called for null entity.")
			return 0
		end
		if (vanillaGetAttackDamage) then
			return vanillaGetAttackDamage(self, ...)
		end
		return 0
	end

	local vanillaGetAttackRangeBuffer = entity.GetAttackRangeBuffer
	entity.GetAttackRangeBuffer = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetAttackRangeBuffer called for null entity.")
			return 0
		end
		if (vanillaGetAttackRangeBuffer) then
			return vanillaGetAttackRangeBuffer(self, ...)
		end
		return 0
	end

	local vanillaGetAttackSpeed = entity.GetAttackSpeed
	entity.GetAttackSpeed = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetAttackSpeed called for null entity.")
			return 0
		end
		if (vanillaGetAttackSpeed) then
			return vanillaGetAttackSpeed(self, ...)
		end
		return 0
	end

	local vanillaGetAttackTarget = entity.GetAttackTarget
	entity.GetAttackTarget = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetAttackTarget called for null entity.")
			return nil
		end
		if (vanillaGetAttackTarget) then
			return vanillaGetAttackTarget(self, ...)
		end
		return nil
	end

	local vanillaGetAttacksPerSecond = entity.GetAttacksPerSecond
	entity.GetAttacksPerSecond = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetAttacksPerSecond called for null entity.")
			return 0
		end
		if (vanillaGetAttacksPerSecond) then
			return vanillaGetAttacksPerSecond(self, ...)
		end
		return 0
	end

	local vanillaGetAverageTrueAttackDamage = entity.GetAverageTrueAttackDamage
	entity.GetAverageTrueAttackDamage = function(self, hTarget, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetAverageTrueAttackDamage called for null entity.")
			return 0
		end
		if (type(hTarget) ~= "table" or hTarget.IsNull == nil or hTarget:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetAverageTrueAttackDamage expected hTarget as valid not null entity.")
			return 0
		end
		if (vanillaGetAverageTrueAttackDamage) then
			return vanillaGetAverageTrueAttackDamage(self, hTarget, ...)
		end
		return 0
	end

	local vanillaGetBaseAttackRange = entity.GetBaseAttackRange
	entity.GetBaseAttackRange = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetBaseAttackRange called for null entity.")
			return 0
		end
		if (vanillaGetBaseAttackRange) then
			return vanillaGetBaseAttackRange(self, ...)
		end
		return 0
	end

	local vanillaGetBaseAttackTime = entity.GetBaseAttackTime
	entity.GetBaseAttackTime = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetBaseAttackTime called for null entity.")
			return 1.7
		end
		if (vanillaGetBaseAttackTime) then
			return vanillaGetBaseAttackTime(self, ...)
		end
		return 1.7
	end

	local vanillaGetBaseDamageMax = entity.GetBaseDamageMax
	entity.GetBaseDamageMax = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetBaseDamageMax called for null entity.")
			return 0
		end
		if (vanillaGetBaseDamageMax) then
			return vanillaGetBaseDamageMax(self, ...)
		end
		return 0
	end

	local vanillaGetBaseDamageMin = entity.GetBaseDamageMin
	entity.GetBaseDamageMin = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetBaseDamageMin called for null entity.")
			return 0
		end
		if (vanillaGetBaseDamageMin) then
			return vanillaGetBaseDamageMin(self, ...)
		end
		return 0
	end

	local vanillaGetBaseDayTimeVisionRange = entity.GetBaseDayTimeVisionRange
	entity.GetBaseDayTimeVisionRange = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetBaseDayTimeVisionRange called for null entity.")
			return 0
		end
		if (vanillaGetBaseDayTimeVisionRange) then
			return vanillaGetBaseDayTimeVisionRange(self, ...)
		end
		return 0
	end

	local vanillaGetBaseHealthBarOffset = entity.GetBaseHealthBarOffset
	entity.GetBaseHealthBarOffset = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetBaseHealthBarOffset called for null entity.")
			return 0
		end
		if (vanillaGetBaseHealthBarOffset) then
			return vanillaGetBaseHealthBarOffset(self, ...)
		end
		return 0
	end

	local vanillaGetBaseHealthRegen = entity.GetBaseHealthRegen
	entity.GetBaseHealthRegen = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetBaseHealthRegen called for null entity.")
			return 0
		end
		if (vanillaGetBaseHealthRegen) then
			return vanillaGetBaseHealthRegen(self, ...)
		end
		return 0
	end

	local vanillaGetBaseMagicalResistanceValue = entity.GetBaseMagicalResistanceValue
	entity.GetBaseMagicalResistanceValue = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetBaseMagicalResistanceValue called for null entity.")
			return 0
		end
		if (vanillaGetBaseMagicalResistanceValue) then
			return vanillaGetBaseMagicalResistanceValue(self, ...)
		end
		return 0
	end

	local vanillaGetBaseMaxHealth = entity.GetBaseMaxHealth
	entity.GetBaseMaxHealth = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetBaseMaxHealth called for null entity.")
			return 0
		end
		if (vanillaGetBaseMaxHealth) then
			return vanillaGetBaseMaxHealth(self, ...)
		end
		return 0
	end

	local vanillaGetBaseMoveSpeed = entity.GetBaseMoveSpeed
	entity.GetBaseMoveSpeed = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetBaseMoveSpeed called for null entity.")
			return 0
		end
		if (vanillaGetBaseMoveSpeed) then
			return vanillaGetBaseMoveSpeed(self, ...)
		end
		return 0
	end

	local vanillaGetBaseNightTimeVisionRange = entity.GetBaseNightTimeVisionRange
	entity.GetBaseNightTimeVisionRange = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetBaseNightTimeVisionRange called for null entity.")
			return 0
		end
		if (vanillaGetBaseNightTimeVisionRange) then
			return vanillaGetBaseNightTimeVisionRange(self, ...)
		end
		return 0
	end

	local vanillaGetBonusManaRegen = entity.GetBonusManaRegen
	entity.GetBonusManaRegen = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetBonusManaRegen called for null entity.")
			return 0
		end
		if (vanillaGetBonusManaRegen) then
			return vanillaGetBonusManaRegen(self, ...)
		end
		return 0
	end

	local vanillaGetCastPoint = entity.GetCastPoint
	entity.GetCastPoint = function(self, bAttack, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetCastPoint called for null entity.")
			return 0
		end
		if (bAttack ~= true and bAttack ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.GetCastPoint expected bAttack as boolean.")
			return 0
		end
		if (vanillaGetCastPoint) then
			return vanillaGetCastPoint(self, bAttack, ...)
		end
		return 0
	end

	local vanillaGetCastRangeBonus = entity.GetCastRangeBonus
	entity.GetCastRangeBonus = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetCastRangeBonus called for null entity.")
			return 0
		end
		if (vanillaGetCastRangeBonus) then
			return vanillaGetCastRangeBonus(self, ...)
		end
		return 0
	end

	local vanillaGetCloneSource = entity.GetCloneSource
	entity.GetCloneSource = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetCloneSource called for null entity.")
			return nil
		end
		if (vanillaGetCloneSource) then
			return vanillaGetCloneSource(self, ...)
		end
		return nil
	end

	local vanillaGetCollisionPadding = entity.GetCollisionPadding
	entity.GetCollisionPadding = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetCollisionPadding called for null entity.")
			return 0
		end
		if (vanillaGetCollisionPadding) then
			return vanillaGetCollisionPadding(self, ...)
		end
		return 0
	end

	local vanillaGetCooldownReduction = entity.GetCooldownReduction
	entity.GetCooldownReduction = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetCooldownReduction called for null entity.")
			return 1
		end
		if (vanillaGetCooldownReduction) then
			return vanillaGetCooldownReduction(self, ...)
		end
		return 1
	end

	local vanillaGetCreationTime = entity.GetCreationTime
	entity.GetCreationTime = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetCreationTime called for null entity.")
			return 0
		end
		if (vanillaGetCreationTime) then
			return vanillaGetCreationTime(self, ...)
		end
		return 0
	end

	local vanillaGetCurrentActiveAbility = entity.GetCurrentActiveAbility
	entity.GetCurrentActiveAbility = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetCurrentActiveAbility called for null entity.")
			return nil
		end
		if (vanillaGetCurrentActiveAbility) then
			return vanillaGetCurrentActiveAbility(self, ...)
		end
		return nil
	end

	local vanillaGetCurrentVisionRange = entity.GetCurrentVisionRange
	entity.GetCurrentVisionRange = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetCurrentVisionRange called for null entity.")
			return 0
		end
		if (vanillaGetCurrentVisionRange) then
			return vanillaGetCurrentVisionRange(self, ...)
		end
		return 0
	end

	local vanillaGetCursorCastTarget = entity.GetCursorCastTarget
	entity.GetCursorCastTarget = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetCursorCastTarget called for null entity.")
			return nil
		end
		if (vanillaGetCursorCastTarget) then
			return vanillaGetCursorCastTarget(self, ...)
		end
		return nil
	end

	local vanillaGetCursorPosition = entity.GetCursorPosition
	entity.GetCursorPosition = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetCursorPosition called for null entity.")
			return Vector(0, 0, 0)
		end
		if (vanillaGetCursorPosition) then
			return vanillaGetCursorPosition(self, ...)
		end
		return Vector(0, 0, 0)
	end

	local vanillaGetCursorTargetingNothing = entity.GetCursorTargetingNothing
	entity.GetCursorTargetingNothing = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetCursorTargetingNothing called for null entity.")
			return false
		end
		if (vanillaGetCursorTargetingNothing) then
			return vanillaGetCursorTargetingNothing(self, ...)
		end
		return false
	end

	local vanillaGetDamageMax = entity.GetDamageMax
	entity.GetDamageMax = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetDamageMax called for null entity.")
			return 0
		end
		if (vanillaGetDamageMax) then
			return vanillaGetDamageMax(self, ...)
		end
		return 0
	end

	local vanillaGetDamageMin = entity.GetDamageMin
	entity.GetDamageMin = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetDamageMin called for null entity.")
			return 0
		end
		if (vanillaGetDamageMin) then
			return vanillaGetDamageMin(self, ...)
		end
		return 0
	end

	local vanillaGetDayTimeVisionRange = entity.GetDayTimeVisionRange
	entity.GetDayTimeVisionRange = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetDayTimeVisionRange called for null entity.")
			return 0
		end
		if (vanillaGetDayTimeVisionRange) then
			return vanillaGetDayTimeVisionRange(self, ...)
		end
		return 0
	end

	local vanillaGetDeathXP = entity.GetDeathXP
	entity.GetDeathXP = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetDeathXP called for null entity.")
			return 0
		end
		if (vanillaGetDeathXP) then
			return vanillaGetDeathXP(self, ...)
		end
		return 0
	end

	local vanillaGetDisplayAttackSpeed = entity.GetDisplayAttackSpeed
	entity.GetDisplayAttackSpeed = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetDisplayAttackSpeed called for null entity.")
			return 0
		end
		if (vanillaGetDisplayAttackSpeed) then
			return vanillaGetDisplayAttackSpeed(self, ...)
		end
		return 0
	end

	local vanillaGetEvasion = entity.GetEvasion
	entity.GetEvasion = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetEvasion called for null entity.")
			return 0
		end
		if (vanillaGetEvasion) then
			return vanillaGetEvasion(self, ...)
		end
		return 0
	end

	local vanillaGetForceAttackTarget = entity.GetForceAttackTarget
	entity.GetForceAttackTarget = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetForceAttackTarget called for null entity.")
			return nil
		end
		if (vanillaGetForceAttackTarget) then
			return vanillaGetForceAttackTarget(self, ...)
		end
		return nil
	end

	local vanillaGetGoldBounty = entity.GetGoldBounty
	entity.GetGoldBounty = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetGoldBounty called for null entity.")
			return 0
		end
		if (vanillaGetGoldBounty) then
			return vanillaGetGoldBounty(self, ...)
		end
		return 0
	end

	local vanillaGetHasteFactor = entity.GetHasteFactor
	entity.GetHasteFactor = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetHasteFactor called for null entity.")
			return 1
		end
		if (vanillaGetHasteFactor) then
			return vanillaGetHasteFactor(self, ...)
		end
		return 1
	end

	local vanillaGetHealthDeficit = entity.GetHealthDeficit
	entity.GetHealthDeficit = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetHealthDeficit called for null entity.")
			return 0
		end
		if (vanillaGetHealthDeficit) then
			return vanillaGetHealthDeficit(self, ...)
		end
		return 0
	end

	local vanillaGetHealthPercent = entity.GetHealthPercent
	entity.GetHealthPercent = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetHealthPercent called for null entity.")
			return 0
		end
		if (vanillaGetHealthPercent) then
			return vanillaGetHealthPercent(self, ...)
		end
		return 0
	end

	local vanillaGetHealthRegen = entity.GetHealthRegen
	entity.GetHealthRegen = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetHealthRegen called for null entity.")
			return 0
		end
		if (vanillaGetHealthRegen) then
			return vanillaGetHealthRegen(self, ...)
		end
		return 0
	end

	local vanillaGetHullRadius = entity.GetHullRadius
	entity.GetHullRadius = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetHullRadius called for null entity.")
			return 0
		end
		if (vanillaGetHullRadius) then
			return vanillaGetHullRadius(self, ...)
		end
		return 0
	end

	local vanillaGetIdealSpeed = entity.GetIdealSpeed
	entity.GetIdealSpeed = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetIdealSpeed called for null entity.")
			return 0
		end
		if (vanillaGetIdealSpeed) then
			return vanillaGetIdealSpeed(self, ...)
		end
		return 0
	end

	local vanillaGetIdealSpeedNoSlows = entity.GetIdealSpeedNoSlows
	entity.GetIdealSpeedNoSlows = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetIdealSpeedNoSlows called for null entity.")
			return 0
		end
		if (vanillaGetIdealSpeedNoSlows) then
			return vanillaGetIdealSpeedNoSlows(self, ...)
		end
		return 0
	end

	local vanillaGetIncreasedAttackSpeed = entity.GetIncreasedAttackSpeed
	entity.GetIncreasedAttackSpeed = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetIncreasedAttackSpeed called for null entity.")
			return 0
		end
		if (vanillaGetIncreasedAttackSpeed) then
			return vanillaGetIncreasedAttackSpeed(self, ...)
		end
		return 0
	end

	local vanillaGetInitialGoalEntity = entity.GetInitialGoalEntity
	entity.GetInitialGoalEntity = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetInitialGoalEntity called for null entity.")
			return nil
		end
		if (vanillaGetInitialGoalEntity) then
			return vanillaGetInitialGoalEntity(self, ...)
		end
		return nil
	end

	local vanillaGetInitialGoalPosition = entity.GetInitialGoalPosition
	entity.GetInitialGoalPosition = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetInitialGoalPosition called for null entity.")
			return Vector(0, 0, 0)
		end
		if (vanillaGetInitialGoalPosition) then
			return vanillaGetInitialGoalPosition(self, ...)
		end
		return Vector(0, 0, 0)
	end

	local vanillaGetItemInSlot = entity.GetItemInSlot
	entity.GetItemInSlot = function(self, i, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetItemInSlot called for null entity.")
			return nil
		end
		i = tonumber(i)
		if (not i) then
			Debug_PrintError("CDOTA_BaseNPC.GetItemInSlot expected i as number.")
			return nil
		end
		if (vanillaGetItemInSlot) then
			return vanillaGetItemInSlot(self, i, ...)
		end
		return nil
	end

	local vanillaGetLastAttackTime = entity.GetLastAttackTime
	entity.GetLastAttackTime = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetLastAttackTime called for null entity.")
			return 0
		end
		if (vanillaGetLastAttackTime) then
			return vanillaGetLastAttackTime(self, ...)
		end
		return 0
	end

	local vanillaGetLastDamageTime = entity.GetLastDamageTime
	entity.GetLastDamageTime = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetLastDamageTime called for null entity.")
			return 0
		end
		if (vanillaGetLastDamageTime) then
			return vanillaGetLastDamageTime(self, ...)
		end
		return 0
	end

	local vanillaGetLastIdleChangeTime = entity.GetLastIdleChangeTime
	entity.GetLastIdleChangeTime = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetLastIdleChangeTime called for null entity.")
			return 0
		end
		if (vanillaGetLastIdleChangeTime) then
			return vanillaGetLastIdleChangeTime(self, ...)
		end
		return 0
	end

	local vanillaGetLevel = entity.GetLevel
	entity.GetLevel = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetLevel called for null entity.")
			return 0
		end
		if (vanillaGetLevel) then
			return vanillaGetLevel(self, ...)
		end
		return 0
	end

	local vanillaGetMagicalArmorValue = entity.GetMagicalArmorValue
	entity.GetMagicalArmorValue = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetMagicalArmorValue called for null entity.")
			return 0
		end
		if (vanillaGetMagicalArmorValue) then
			return vanillaGetMagicalArmorValue(self, ...)
		end
		return 0
	end

	local vanillaGetMainControllingPlayer = entity.GetMainControllingPlayer
	entity.GetMainControllingPlayer = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetMainControllingPlayer called for null entity.")
			return -1
		end
		if (vanillaGetMainControllingPlayer) then
			return vanillaGetMainControllingPlayer(self, ...)
		end
		return -1
	end

	local vanillaGetMana = entity.GetMana
	entity.GetMana = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetMana called for null entity.")
			return 0
		end
		if (vanillaGetMana) then
			return vanillaGetMana(self, ...)
		end
		return 0
	end

	local vanillaGetManaPercent = entity.GetManaPercent
	entity.GetManaPercent = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetManaPercent called for null entity.")
			return 0
		end
		if (vanillaGetManaPercent) then
			return vanillaGetManaPercent(self, ...)
		end
		return 0
	end

	local vanillaGetManaRegen = entity.GetManaRegen
	entity.GetManaRegen = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetManaRegen called for null entity.")
			return 0
		end
		if (vanillaGetManaRegen) then
			return vanillaGetManaRegen(self, ...)
		end
		return 0
	end

	local vanillaGetMaxMana = entity.GetMaxMana
	entity.GetMaxMana = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetMaxMana called for null entity.")
			return 0
		end
		if (vanillaGetMaxMana) then
			return vanillaGetMaxMana(self, ...)
		end
		return 0
	end

	local vanillaGetMaximumGoldBounty = entity.GetMaximumGoldBounty
	entity.GetMaximumGoldBounty = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetMaximumGoldBounty called for null entity.")
			return 0
		end
		if (vanillaGetMaximumGoldBounty) then
			return vanillaGetMaximumGoldBounty(self, ...)
		end
		return 0
	end

	local vanillaGetMinimumGoldBounty = entity.GetMinimumGoldBounty
	entity.GetMinimumGoldBounty = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetMinimumGoldBounty called for null entity.")
			return 0
		end
		if (vanillaGetMinimumGoldBounty) then
			return vanillaGetMinimumGoldBounty(self, ...)
		end
		return 0
	end

	local vanillaGetModelRadius = entity.GetModelRadius
	entity.GetModelRadius = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetModelRadius called for null entity.")
			return 1
		end
		if (vanillaGetModelRadius) then
			return vanillaGetModelRadius(self, ...)
		end
		return 1
	end

	local vanillaGetModifierCount = entity.GetModifierCount
	entity.GetModifierCount = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetModifierCount called for null entity.")
			return 0
		end
		if (vanillaGetModifierCount) then
			return vanillaGetModifierCount(self, ...)
		end
		return 0
	end

	local vanillaGetModifierNameByIndex = entity.GetModifierNameByIndex
	entity.GetModifierNameByIndex = function(self, nIndex, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetModifierNameByIndex called for null entity.")
			return ""
		end
		nIndex = tonumber(nIndex)
		if (not nIndex) then
			Debug_PrintError("CDOTA_BaseNPC.GetModifierNameByIndex expected nIndex as number.")
			return ""
		end
		if (vanillaGetModifierNameByIndex) then
			return vanillaGetModifierNameByIndex(self, nIndex, ...)
		end
		return ""
	end

	local vanillaGetModifierStackCount = entity.GetModifierStackCount
	entity.GetModifierStackCount = function(self, pszScriptName, hCaster, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetModifierStackCount called for null entity.")
			return 0
		end
		if (type(pszScriptName) ~= "string") then
			Debug_PrintError("CDOTA_BaseNPC.GetModifierStackCount expected pszScriptName as string.")
			return 0
		end
		if (type(hCaster) ~= "table" or hCaster.IsNull == nil or hCaster:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetModifierStackCount expected hCaster as valid not null entity.")
			return 0
		end
		if (vanillaGetModifierStackCount) then
			return vanillaGetModifierStackCount(self, pszScriptName, hCaster, ...)
		end
		return 0
	end

	local vanillaGetMoveSpeedModifier = entity.GetMoveSpeedModifier
	entity.GetMoveSpeedModifier = function(self, flBaseSpeed, bReturnUnslowed, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetMoveSpeedModifier called for null entity.")
			return 0
		end
		flBaseSpeed = tonumber(flBaseSpeed)
		if (not flBaseSpeed) then
			Debug_PrintError("CDOTA_BaseNPC.GetMoveSpeedModifier expected flBaseSpeed as number.")
			return 0
		end
		if (bReturnUnslowed ~= true and bReturnUnslowed ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.GetMoveSpeedModifier expected bReturnUnslowed as boolean.")
			return 0
		end
		if (vanillaGetMoveSpeedModifier) then
			return vanillaGetMoveSpeedModifier(self, flBaseSpeed, bReturnUnslowed, ...)
		end
		return 0
	end

	local vanillaGetMustReachEachGoalEntity = entity.GetMustReachEachGoalEntity
	entity.GetMustReachEachGoalEntity = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetMustReachEachGoalEntity called for null entity.")
			return false
		end
		if (vanillaGetMustReachEachGoalEntity) then
			return vanillaGetMustReachEachGoalEntity(self, ...)
		end
		return false
	end

	local vanillaGetNeutralSpawnerName = entity.GetNeutralSpawnerName
	entity.GetNeutralSpawnerName = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetNeutralSpawnerName called for null entity.")
			return ""
		end
		if (vanillaGetNeutralSpawnerName) then
			return vanillaGetNeutralSpawnerName(self, ...)
		end
		return ""
	end

	local vanillaGetNeverMoveToClearSpace = entity.GetNeverMoveToClearSpace
	entity.GetNeverMoveToClearSpace = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetNeverMoveToClearSpace called for null entity.")
			return false
		end
		if (vanillaGetNeverMoveToClearSpace) then
			return vanillaGetNeverMoveToClearSpace(self, ...)
		end
		return false
	end

	local vanillaGetNightTimeVisionRange = entity.GetNightTimeVisionRange
	entity.GetNightTimeVisionRange = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetNightTimeVisionRange called for null entity.")
			return 0
		end
		if (vanillaGetNightTimeVisionRange) then
			return vanillaGetNightTimeVisionRange(self, ...)
		end
		return 0
	end

	local vanillaGetOpposingTeamNumber = entity.GetOpposingTeamNumber
	entity.GetOpposingTeamNumber = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetOpposingTeamNumber called for null entity.")
			return DOTA_TEAM_NOTEAM
		end
		if (vanillaGetOpposingTeamNumber) then
			return vanillaGetOpposingTeamNumber(self, ...)
		end
		return DOTA_TEAM_NOTEAM
	end

	local vanillaGetPaddedCollisionRadius = entity.GetPaddedCollisionRadius
	entity.GetPaddedCollisionRadius = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetPaddedCollisionRadius called for null entity.")
			return 0
		end
		if (vanillaGetPaddedCollisionRadius) then
			return vanillaGetPaddedCollisionRadius(self, ...)
		end
		return 0
	end

	local vanillaGetPhysicalArmorBaseValue = entity.GetPhysicalArmorBaseValue
	entity.GetPhysicalArmorBaseValue = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetPhysicalArmorBaseValue called for null entity.")
			return 0
		end
		if (vanillaGetPhysicalArmorBaseValue) then
			return vanillaGetPhysicalArmorBaseValue(self, ...)
		end
		return 0
	end

	local vanillaGetPhysicalArmorValue = entity.GetPhysicalArmorValue
	entity.GetPhysicalArmorValue = function(self, bIgnoreBase, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetPhysicalArmorValue called for null entity.")
			return 0
		end
		if (bIgnoreBase ~= true and bIgnoreBase ~= false) then
			Debug_PrintError("CDOTA_BaseNPC.GetPhysicalArmorValue expected bIgnoreBase as boolean.")
			return 0
		end
		if (vanillaGetPhysicalArmorValue) then
			return vanillaGetPhysicalArmorValue(self, bIgnoreBase, ...)
		end
		return 0
	end

	local vanillaGetPlayerOwner = entity.GetPlayerOwner
	entity.GetPlayerOwner = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetPlayerOwner called for null entity.")
			return nil
		end
		if (vanillaGetPlayerOwner) then
			return vanillaGetPlayerOwner(self, ...)
		end
		return nil
	end

	local vanillaGetPlayerOwnerID = entity.GetPlayerOwnerID
	entity.GetPlayerOwnerID = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetPlayerOwnerID called for null entity.")
			return -1
		end
		if (vanillaGetPlayerOwnerID) then
			return vanillaGetPlayerOwnerID(self, ...)
		end
		return -1
	end

	local vanillaGetProjectileSpeed = entity.GetProjectileSpeed
	entity.GetProjectileSpeed = function(self, ...)

		if (not self or self.IsNull == nil or self:IsNull() == true) then
			Debug_PrintError("CDOTA_BaseNPC.GetProjectileSpeed called for null entity.")
			return 0
		end
		if (vanillaGetProjectileSpeed) then
			return vanillaGetProjectileSpeed(self, ...)
		end
		return 0
	end
	_OverrideBaseNPCFunctionsSecond(entity)
	entity._OverrideBaseNPCFunctionsUsed = true
end

_OverrideBaseNPCFunctions(_G.CDOTA_BaseNPC)

function _OverrideBaseNPCAbilities(kv)
	kv.entindex = tonumber(kv.entindex)
	if(not kv.entindex) then
		return
	end
	local npc = EntIndexToHScript(kv.entindex)
	if(npc._isMarkedByBaseNPC731crashFix) then
		return
	end
	for i=0,npc:GetAbilityCount()-1 do
		local ability = npc:GetAbilityByIndex(i)
		if(ability) then
			_OverrideAbilityFunctions(ability)
		end
	end
	npc._isMarkedByBaseNPC731crashFix = true
end

ListenToGameEvent('npc_spawned', _OverrideBaseNPCAbilities, self)


_G._gaben731crashFixesBaseNPCInit = true