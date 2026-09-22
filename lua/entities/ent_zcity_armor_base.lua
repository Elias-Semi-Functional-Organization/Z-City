--[[             z...
    /\___/\    z
    | _ _ |  Z
   /|__-__|\
   \-------/
--]]
DEFINE_BASECLASS( "ent_zcity_equipment_base" )	
AddCSLuaFile()
--[[
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
--]]
ENT.Type = "anim"
ENT.Base = "ent_zcity_equipment_base"
ENT.PrintName = "Armor base"
ENT.Category = "ZCity TestArmor"
ENT.Spawnable = false
ENT.Model = "models/jworld_equipment/kevlar.mdl"
ENT.ModelMaterial = "sal/acc/armor01_2"
ENT.IconOverride = ""

ENT.SlotOccupation = {
    [ZC_ARMOR_SLOT_TORSO] = true,
    --[zc_equipment_SLOT_PANTS] = true,
    --[zc_equipment_SLOT_BOOTS] = true,
}
--\\ balistic settings
ENT.HitBoxSet = "vest3"
ENT.Protection = 10
ENT.ProtectionDamageMul = 0.6
ENT.PenetratedDamageMul = 0.8

ENT.BalisticMaterial = nil
ENT.Durability = 100
ENT.DurabilityMax = 100
ENT.DurabilityWarranty = 15

--//
--\\
ENT.Male = {}
ENT.Male.Model = "models/lightvest/lightvest.mdl"
ENT.Male.ModelSubMaterials = {}
ENT.Male.HideSubMaterails = {}
ENT.Male.Skin = 0
ENT.Male.Bodygroups = "0000000000000"
--
ENT.Male.BoneMerge = false
ENT.Male.ParentBone = "ValveBiped.Bip01_Spine2"
ENT.Male.OffsetPos = Vector(-9.8,3.5,0)
ENT.Male.OffsetAng = Angle(0,88,90)
ENT.Male.ModelSize = 0.92
--//

--\\
ENT.FeMale = {}
ENT.FeMale.Model = "models/lightvest/lightvest.mdl"
ENT.FeMale.ModelSubMaterials = {}
ENT.FeMale.HideSubMaterails = {}
ENT.FeMale.Skin = 0
ENT.FeMale.Bodygroups = "0000000000000"
--
ENT.FeMale.BoneMerge = false
ENT.FeMale.ParentBone = "ValveBiped.Bip01_Spine2"
ENT.FeMale.OffsetPos = Vector(-9.1,2.5,0)
ENT.FeMale.OffsetAng = Angle(0,90,90)
ENT.FeMale.ModelSize = 0.8
--//

ENT.PhysicsSounds = true

function ENT:Initialize()
    BaseClass.Initialize( self )

    self:SetMaterial(self.ModelMaterial)
end


function ENT:Draw()
    if self:GetMoveType() == MOVETYPE_NONE or self.GetEquiped and self:GetEquiped() then self:DrawShadow(false) return end
    if IsValid(self.renderModel) then self.renderModel:Remove() end
    self:DrawModel()
end
local developer = GetConVar("developer")
--\\ Render Equipment
    local vec = Vector(1,1,1)
    function ENT:RenderOnBody(entDrawOn)
        local fem = ThatPlyIsFemale(entDrawOn)

        if !IsValid(self.renderModel) then
            local data = fem and self.FeMale or self.Male
            self.renderModel = ClientsideModel(data.Model, RENDERGROUP_BOTH)

            local model = self.renderModel
            model:SetNoDraw(true)
            model:SetSkin(data.Skin)
            model:SetBodyGroups(data.Bodygroups)
            model:SetParent(entDrawOn)
            --print(data.BoneMerge)
            if data.BoneMerge then
                model:AddEffects(EF_BONEMERGE)
            else
                model.ParentBone = entDrawOn:LookupBone( data.ParentBone ) 
                model.OffsetPos = data.OffsetPos
                model.OffsetAng = data.OffsetAng
                model:SetModelScale(data.ModelSize)
            end
            

            if data.ModelSubMaterials then
                for k,v in pairs(data.ModelSubMaterials) do
                    local id = isnumber(k) and k or model:GetSubMaterialIdByName(k)
                    if !id then continue end
                    model:SetSubMaterial(id, v)
                end
            end

            self:CallOnRemove("RemoveEquip",function()
                if IsValid(self.renderModel) then
                    model:Remove()
                    model = nil
                end
            end)
        end

        local model = self.renderModel

        local mdl = string.Split(string.sub(entDrawOn:GetModel(),1,-5),"/")[#string.Split(string.sub(entDrawOn:GetModel(),1,-5),"/")]
        if mdl and model:GetFlexIDByName(mdl) then
            model:SetFlexWeight(model:GetFlexIDByName(mdl),1)
        end

        if model:GetParent() != entDrawOn then model:SetParent(entDrawOn) end

        if model.ParentBone then
            if developer:GetBool() then
                local data = fem and self.FeMale or self.Male
                model.ParentBone = entDrawOn:LookupBone( data.ParentBone ) 
                model.OffsetPos = data.OffsetPos
                model.OffsetAng = data.OffsetAng

                model:SetModelScale(data.ModelSize)
            end
            local matBone = entDrawOn:GetBoneMatrix(model.ParentBone)
            local pos = matBone:GetTranslation()
            local ang = matBone:GetAngles()

            pos,ang = LocalToWorld(model.OffsetPos, model.OffsetAng, pos, ang)
            model:SetPos(pos)
            model:SetAngles(ang)

            model:SetRenderOrigin(pos)
            model:SetRenderAngles(ang)
        end        
        
        model:DrawModel()
    end
--//

--\\ Utilites
hg = hg or {}
hg.organism = hg.organism or {}
hg.organism.input_list = hg.organism.input_list or {}

local function protec(org, bone, dmg, dmgInfo, placement, boneindex, dir, hit, ricochet)
    --print(123)
    local armor = org.owner:GetEquipmentBySlot(placement)
	if not force and !IsValid(armor) then return 0 end
	force = nil
    --[[
        ENT.Protection = 10
        ENT.ProtectionDamageMul = 0.6
        ENT.PenetratedDamageMul = 0.8

        ENT.BalisticMaterial = nil
        ENT.Durability = 100
        ENT.DurabilityMax = 100
        ENT.DurabilityWarranty = 15

    ]]
    local durablityMul = math.min(armor.Durability / (armor.DurabilityMax - armor.DurabilityWarranty), 1)
    local protectionDamageMul = math.min(armor.ProtectionDamageMul * (1 + (1 - durablityMul)), 1)
    local penetratedDamageMul = math.min(armor.PenetratedDamageMul * (1 + (1 - durablityMul)), 1)

    local penetration = (dmgInfo:GetInflictor().bullet and dmgInfo:GetInflictor().bullet.Penetration or 1)
    local prot = armor.Protection * durablityMul
    --print(penetration, prot, durablityMul)
	prot = prot - penetration

	if punch then
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
	
	//ArmorEffect(placement, armor, dmgInfo, org, hit, prot)
    if dmgInfo:IsDamageType(DMG_BULLET + DMG_SLASH) then
        armor.Durability = math.max(armor.Durability - (dmg * 5), 0)
    end
    --print(armor.Durability, prot, dmg)
	if prot < 0 then
		dmgInfo:ScaleDamage(penetratedDamageMul)
		return 0
	end

	dmgInfo:SetDamageType(DMG_CLUB)
	dmgInfo:SetDamageForce(dmgInfo:GetDamageForce() * 0.4)
	dmgInfo:ScaleDamage(protectionDamageMul)
    
	return 0.9
end

function hg.organism:AddArmorInputList(strName, nPlacement)
    hg.organism.input_list[strName] = function(org, bone, dmg, dmgInfo, ...)
        local protect = protec(org, bone, dmg, dmgInfo, nPlacement, ...)
        return protect
    end
end

--hg.organism:AddInputList("vest3", ZC_ARMOR_SLOT_TORSO)

hook.Add("HG_OrganAvalible", "ArmorHitboxAvaliveCheck", function(ent, organ_name) 
    local equipment = ent:GetNetVar("zc_equipment", {})
    local armor
    for i = 1, #equipment do
        local Equip = Entity(equipment[i])
        if not IsValid(Equip) then continue end
        --print(Equip.HitBoxSet)
        if Equip.HitBoxSet != organ_name then continue end
        
        return true
    end
end)

--[[
    hg.organism.input_list.vest1 = function(org, bone, dmg, dmgInfo, ...)
        local protect = protec(org, bone, dmg, dmgInfo, "torso", "vest1", 0.6, 0.6, false, ...)
        return protect
    end
--]]

--[[

local ArmorEffect
local force
local function protec(org, bone, dmg, dmgInfo, placement, armor, scale, scaleprot, punch, boneindex, dir, hit, ricochet)
	if not force and org.owner.armors[placement] ~= armor then return 0 end
	force = nil
	
	local prot = placement and hg.armor[placement] and armor and hg.armor[placement][armor] and (hg.armor[placement][armor].protection - (dmgInfo:GetInflictor().bullet and dmgInfo:GetInflictor().bullet.Penetration or 1)) or (10 - ( dmgInfo:GetInflictor().bullet and dmgInfo:GetInflictor().bullet.Penetration or 1))
	
	org.owner.armors_health = org.owner.armors_health or {}

	prot = prot * (org.owner.armors_health[armor] or 1)
	
	if punch then
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
	
	scale = scale * (dmgInfo:IsDamageType(DMG_SLASH) and 0.1 or 1)
	
	ArmorEffect(placement, armor, dmgInfo, org, hit, prot)

	if prot < 0 then
		//dmgInfo:ScaleDamage(scale)
		return 0
	end

	dmgInfo:SetDamageType(DMG_CLUB)
	dmgInfo:SetDamageForce(dmgInfo:GetDamageForce() * 0.4)
	dmgInfo:ScaleDamage(0.2)

	return 0.9
end

ArmorEffect = function(placement, armor, dmgInfo, org, hit, prot)
	local armdata = placement and hg.armor[placement] and hg.armor[placement][armor] or {}
	local eff = prot < 0 and "Impact" or armdata.effect or "Impact"
	local dir = -dmgInfo:GetDamageForce()
	dir:Normalize()
	local effdata = EffectData()
	
	effdata:SetOrigin((hit and isvector(hit) and hit or dmgInfo:GetDamagePosition()) - dir)
	effdata:SetNormal(dir)
	effdata:SetMagnitude(0.25)
	effdata:SetRadius(4)
	effdata:SetNormal(dir)
	effdata:SetStart((hit and isvector(hit) and hit or dmgInfo:GetDamagePosition()) + dir)
	effdata:SetEntity(org.owner)
	effdata:SetSurfaceProp(prot < 0 and 67 or armdata.surfaceprop or 67)
	effdata:SetDamageType(dmgInfo:GetDamageType())

	EmitSound("physics/metal/metal_solid_impact_bullet"..math.random(4)..".wav",dmgInfo:GetDamagePosition(),0,CHAN_AUTO,1,55,nil,100)
	util.Effect(eff,effdata)
end

local ArmorEffectEx = function(ent,dmgInfo,eff,surfaceprop)
	local dir = -dmgInfo:GetDamageForce()
	dir:Normalize()
	local effdata = EffectData()
	
	effdata:SetOrigin( dmgInfo:GetDamagePosition() - dir )
	effdata:SetNormal( dir )
	effdata:SetMagnitude(0.25)
	effdata:SetRadius(4)
	effdata:SetNormal(dir)
	effdata:SetStart(dmgInfo:GetDamagePosition() + dir)
	effdata:SetEntity(ent)
	effdata:SetSurfaceProp(surfaceprop or 67)
	effdata:SetDamageType(dmgInfo:GetDamageType())

	EmitSound("physics/metal/metal_solid_impact_bullet"..math.random(4)..".wav",dmgInfo:GetDamagePosition(),0,CHAN_AUTO,1,55,nil,100)
	util.Effect(eff,effdata)
end

--]]
--local vest3 = hg.organism:HitBox("ValveBiped.Bip01_Spine2", "vest3", 1, Vector(3, 8.5, 0), Angle(0, 0, 0), Vector(7, 2, 6), Color(0, 17, 255), true)
--hg.organism:CreateHitBox(vest3) 
--//