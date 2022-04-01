
item_flask_hp = class({})

function item_flask_hp:OnSpellStart()
	local item = self
	local caster = self:GetCaster()
	local hp_recover = item:GetSpecialValueFor("hp_recover")
	local hp_recover_pct = item:GetSpecialValueFor("hp_recover_pct")
	local total_hp_recover = hp_recover + caster:GetMaxHealth()*hp_recover_pct/100
	caster:Heal(total_hp_recover, item)
	caster:EmitSound("DOTA_Item.HealingSalve.Activate")
	
	item:SpendCharge()
	if item:GetCurrentCharges() <1 then
		self:Destroy()
	end
end

item_flask_mp = class({})

function item_flask_mp:OnSpellStart()
	local item = self
	local caster = self:GetCaster()
	local mp_recover = item:GetSpecialValueFor("mp_recover")
	local mp_recover_pct = item:GetSpecialValueFor("mp_recover_pct")
	local total_mp_recover = mp_recover + caster:GetMaxMana()*mp_recover_pct/100
	caster:GiveMana(total_mp_recover)
	caster:EmitSound("DOTA_Item.HealingSalve.Activate")
	
	item:SpendCharge()
	if item:GetCurrentCharges() <1 then
		self:Destroy()
	end
end

item_flask_hp_1 = class(item_flask_hp)
item_flask_hp_2 = class(item_flask_hp)

item_flask_mp_1 = class(item_flask_mp)
item_flask_mp_2 = class(item_flask_mp)
