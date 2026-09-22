--\\ SLOTS... i think too many for armor, but this is cool!
ZC_CLOTHES_SLOT_TORSO = 0
ZC_CLOTHES_SLOT_PANTS = 1
ZC_CLOTHES_SLOT_BOOTS = 2
ZC_CLOTHES_SLOT_BACKPACK = 3

ZC_ARMOR_SLOT_HEAD = 4
    ZC_ARMOR_SLOT_FACE = 5
        ZC_ARMOR_SLOT_EYES = 6
    ZC_ARMOR_SLOT_EARS = 7

ZC_ARMOR_SLOT_TORSO = 8
    ZC_ARMOR_SLOT_UPPERARM_L = 9
        ZC_ARMOR_SLOT_FOREARM_L = 10
    ZC_ARMOR_SLOT_UPPERARM_R = 11
        ZC_ARMOR_SLOT_FOREARM_R = 12  

ZC_ARMOR_SLOT_BELLY = 13

ZC_ARMOR_SLOT_PELVIS = 14
    ZC_ARMOR_SLOT_THIGH_L = 15
        ZC_ARMOR_SLOT_SHIN_L = 16
    ZC_ARMOR_SLOT_THIGH_R = 17
        ZC_ARMOR_SLOT_SHIN_R = 18
--//

--\\ Balistic materials
    ZC_ARMOR_MATERIAL_CERAMIC = 3
    ZC_ARMOR_MATERIAL_TITAN = 1.8
    ZC_ARMOR_MATERIAL_ARSTEEL = 1.4

    ZC_ARMOR_MATERIAL_KEVLAR = 0.9
    ZC_ARMOR_MATERIAL_KEVLAR_CERAMIC = 0.75
    ZC_ARMOR_MATERIAL_KEVLAR_ARSTEEL = 0.6
    ZC_ARMOR_MATERIAL_KEVLAR_TITAN = 0.45
--//
--\\ Protection classes
--II - 4 protection, IIIA - 8 protection, III - 12 protection, III+ - 16 protection, IV - 22 protection
    ZC_ARMOR_PROTCLASS_II = 4
    ZC_ARMOR_PROTCLASS_IIIA = 8
    ZC_ARMOR_PROTCLASS_III = 12
    ZC_ARMOR_PROTCLASS_III_PLUS = 16
    ZC_ARMOR_PROTCLASS_IV = 22
--//
hg = hg or {}
hg.organism = hg.organism or {}

local function ArmorEffect(placement, armor, dmgInfo, org, hit, prot)
	if prot < 0 then return end
	local eff = "Impact"
	local dir = -dmgInfo:GetDamageForce()
	dir:Normalize()
	local effdata = EffectData()
	
	effdata:SetOrigin((hit and isvector(hit) and hit or dmgInfo:GetDamagePosition()) - dir)
	effdata:SetNormal(dir)
	effdata:SetMagnitude(0.25)
	effdata:SetRadius(2)
	effdata:SetScale(0.1)
	effdata:SetNormal(dir)
	effdata:SetStart((hit and isvector(hit) and hit or dmgInfo:GetDamagePosition()) + dir)
	effdata:SetEntity(hg.GetCurrentCharacter(org.owner))
	effdata:SetSurfaceProp(77)
	effdata:SetDamageType(dmgInfo:GetDamageType())

	EmitSound("physics/metal/metal_solid_impact_bullet"..math.random(4)..".wav",dmgInfo:GetDamagePosition(),0,CHAN_AUTO,1,55,nil,100)
	util.Effect(eff,effdata)
end

--\\ Armor balistic settings
    --[[
        ENT.HitBoxSet = "TestVest"
        ENT.Protection = 10
        ENT.ProtectionDamageMul = 0.6
        ENT.PenetratedDamageMul = 0.8

        ENT.BalisticMaterial = ZC_ARMOR_MATERIAL_KEVLAR -- actually this is just a mul of degradation armor
        ENT.Durability = 100
        ENT.DurabilityMax = 100
        ENT.DurabilityWarranty = 15

        ENT.NeedPunch = false
    --]]
--//
local developer = GetConVar("developer")
local function protec(org, bone, dmg, dmgInfo, placement, boneindex, dir, hit, ricochet)
    local armor = org.owner:GetEquipmentBySlot(placement)
	if !IsValid(armor) then return end

    local durablityMul = math.min(armor.Durability / (armor.DurabilityMax - armor.DurabilityWarranty), 1)
    local protectionDamageMul = math.min(armor.ProtectionDamageMul * (1 + (1 - durablityMul)), 1)
    local penetratedDamageMul = math.min(armor.PenetratedDamageMul * (1 + (1 - durablityMul)), 1)

    local penetration = (dmgInfo:GetInflictor().bullet and dmgInfo:GetInflictor().bullet.Penetration or 1)
    local prot = armor.Protection * durablityMul
    --print(penetration, prot, durablityMul)
	prot = prot - penetration

	if armor.NeedPunch then
		if org.owner:IsPlayer() and org.alive and dmgInfo:IsDamageType(DMG_BUCKSHOT + DMG_BULLET) then
			org.owner:ViewPunch(AngleRand(-30, 30))
			
			org.owner:EmitSound("homigrad/physics/shield/bullet_hit_shield_0"..math.random(7)..".wav", 80, math.random(95, 105))

			org.owner:AddTinnitus(3, true)
			net.Start("AddFlash")
				net.WriteVector(hg.eye(org.owner) + org.owner:GetForward() * 3)
				net.WriteFloat(3)
				net.WriteInt(100, 20)
			net.Send(org.owner)

			hg.ExplosionDisorientation(org.owner, 6, 6)

			hg.organism.input_list.spine3(org, bone, (dmg/100) * math.Rand(0,0.1), dmgInfo)
			--org.spine3 = org.spine3 + math.Rand(0.05,1) * dmg / 5
		end
	end
	
	//scale = scale * (dmgInfo:IsDamageType(DMG_SLASH) and 0.1 or 1)
	
	ArmorEffect(placement, armor, dmgInfo, org, hit, prot)
    //print(dmgInfo:IsDamageType(DMG_BULLET + DMG_SLASH))
    local oldDurability = armor.Durability
    if dmgInfo:IsDamageType(DMG_BULLET + DMG_SLASH) and (!org.oldBalisticDamageInfo or org.oldBalisticDamageInfo != dmgInfo) then
        org.oldBalisticDamageInfo = dmgInfo
        armor.Durability = math.max(armor.Durability - (penetration * armor.BalisticMaterial), 0)
        --print(armor.Durability)
    end
    --print(armor.Durability, prot, dmg)

    if developer:GetBool() and SERVER then
        local attacker = dmgInfo:GetAttacker()
        if IsValid(attacker) and attacker:IsPlayer() and attacker:IsAdmin() then
            --print(org.owner)
            attacker:PrintMessage(HUD_PRINTCONSOLE, "\n--// Damage to armor on " .. org.owner:Nick())
            attacker:PrintMessage(HUD_PRINTCONSOLE, "--|| Armor: " .. armor.PrintName)
            attacker:PrintMessage(HUD_PRINTCONSOLE, "--|| OldDur ".. oldDurability ..", Dur ".. armor.Durability ..", Prot ".. prot ..", Dmg ".. dmg ..", Pentr ".. penetration)
            attacker:PrintMessage(HUD_PRINTCONSOLE, "--\\\\ Penetrated? " .. (prot < 1 and "Yes." or "No.") .. "\n\n" )
        end
    end

	if prot < 0 then
		dmgInfo:ScaleDamage(penetratedDamageMul)
		dmgInfo:SetDamageForce(dmgInfo:GetDamageForce() * penetratedDamageMul )
		return 
	end

	dmgInfo:SetDamageType(DMG_CLUB)
	dmgInfo:SetDamageForce(dmgInfo:GetDamageForce() * protectionDamageMul / 2)
	dmgInfo:ScaleDamage(protectionDamageMul)
    
	return 0.9
end
hg.organism = hg.organism or {}
hg.organism.input_list = hg.organism.input_list or {}
function hg.organism:AddArmorInputList(strName, nPlacement)
    hg.organism.input_list[strName] = function(org, bone, dmg, dmgInfo, ...)
        local protect = protec(org, bone, dmg, dmgInfo, nPlacement, ...)
        return protect
    end
end
load_from_armor_file = false
local function loadArmor() 
    local path = "homigrad/equipment_system/entities/"
    local files = file.Find(path.."*.lua", "LUA")
    for k,v in ipairs(files) do
        load_from_armor_file = true
        include(path .. v)
    end
end

hook.Add("HG_BaseHitBoxSetLoaded","LoadArmor",loadArmor)

hook.Add("Think","RemoveMeLoadArmor",function()
    hook.Remove("Think","RemoveMeLoadArmor")
    if !HG_BaseHitBoxSetLoaded then return end 
    loadArmor()
end)