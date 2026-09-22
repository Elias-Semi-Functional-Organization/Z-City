
--\\ Armor Slots
    -- ZC_ARMOR_SLOT_HEAD = 4
    -- ZC_ARMOR_SLOT_FACE = 5
    --     ZC_ARMOR_SLOT_EYES = 6
    -- ZC_ARMOR_SLOT_EARS = 7

    -- ZC_ARMOR_SLOT_TORSO = 8
    --     ZC_ARMOR_SLOT_UPPERARM_L = 9
    --         ZC_ARMOR_SLOT_FOREARM_L = 10
    --     ZC_ARMOR_SLOT_UPPERARM_R = 11
    --         ZC_ARMOR_SLOT_FOREARM_R = 12  

    -- ZC_ARMOR_SLOT_BELLY = 13

    -- ZC_ARMOR_SLOT_PELVIS = 14
    --     ZC_ARMOR_SLOT_THIGH_L = 15
    --         ZC_ARMOR_SLOT_SHIN_L = 16
    --     ZC_ARMOR_SLOT_THIGH_R = 17
    --         ZC_ARMOR_SLOT_SHIN_R = 18
--//

if not load_from_armor_file then return end -- i'm sorry for that, but that way light than create Entity registration module
local ENT = {}
ENT.Type = "anim"
ENT.Base = "ent_zcity_armor_base"
ENT.PrintName = "Plate Body Armor IV"
ENT.Category = "ZCity TestArmor"
ENT.Spawnable = true
ENT.Model = "models/combataegis/body/ballisticvest_d.mdl"
ENT.ModelMaterial = nil
ENT.IconOverride = "scrappers/armor1.png"

ENT.SlotOccupation = {                              -- Slots what armor occupate
    [ZC_ARMOR_SLOT_TORSO] = true,
}
--\\ Balistic settings                              -- soon can be enchanced, per plate material, durability and other stuff

--\\ HitBoxSets Hitbox Creation
    ENT.HitBoxSet = "new_vest1"                     -- you can use same hitbox sets on other armor
    --\\ Plates HitBoxSets
        local color_yellow = Color(255,255,0)
        -- Fornt Plate
            local HitBox = hg.organism:HitBox("ValveBiped.Bip01_Spine2", "new_vest1", 1, Vector(5.8, 7, 0), Angle(0, -4, 0), Vector(3, 1, 3.5), color_yellow, true)
            hg.organism:CreateHitBox("Front",HitBox)

            local HitBox = hg.organism:HitBox("ValveBiped.Bip01_Spine2", "new_vest1", 1, Vector(0, 7.5, 0), Angle(0, -4, 0), Vector(4.1, 1, 5.2), color_yellow, true)
            hg.organism:CreateHitBox("FrontDown",HitBox)

            local HitBox = hg.organism:HitBox("ValveBiped.Bip01_Spine2", "new_vest1", 1, Vector(5.8, 7, -2.9), Angle(-18, -4, 0), Vector(2.5, 1, 1.5), color_yellow, true)
            hg.organism:CreateHitBox("FrontRight",HitBox)

            local HitBox = hg.organism:HitBox("ValveBiped.Bip01_Spine2", "new_vest1", 1, Vector(5.8, 7, 2.9), Angle(18, -4, 0), Vector(2.5, 1, 1.5), color_yellow, true)
            hg.organism:CreateHitBox("FrontLeft",HitBox)
        --//

        -- Back Plate
            local HitBox = hg.organism:HitBox("ValveBiped.Bip01_Spine2", "new_vest1", 1, Vector(5.8, -3, 0), Angle(0, -4, 0), Vector(3, 1, 3.5), color_yellow, true)
            hg.organism:CreateHitBox("Back",HitBox)

            local HitBox = hg.organism:HitBox("ValveBiped.Bip01_Spine2", "new_vest1", 1, Vector(0, -2.5, 0), Angle(0, -4, 0), Vector(4.1, 1, 5.2), color_yellow, true)
            hg.organism:CreateHitBox("BackDown",HitBox)

            local HitBox = hg.organism:HitBox("ValveBiped.Bip01_Spine2", "new_vest1", 1, Vector(5.8, -3, -2.9), Angle(-18, -4, 0), Vector(2.5, 1, 1.5), color_yellow, true)
            hg.organism:CreateHitBox("BackRight",HitBox)

            local HitBox = hg.organism:HitBox("ValveBiped.Bip01_Spine2", "new_vest1", 1, Vector(5.8, -3, 2.9), Angle(18, -4, 0), Vector(2.5, 1, 1.5), color_yellow, true)
            hg.organism:CreateHitBox("BackLeft",HitBox)
        --//

        -- Side Plates (kevlar... but soon)
            local HitBox = hg.organism:HitBox("ValveBiped.Bip01_Spine2", "new_vest1", 1, Vector(-1.7, 2.5, 6), Angle(0, 0, 90), Vector(2.5, 0.5, 4.5), color_yellow, true)
            hg.organism:CreateHitBox("LeftSide",HitBox)

            local HitBox = hg.organism:HitBox("ValveBiped.Bip01_Spine2", "new_vest1", 1, Vector(-1.7, 2.5, -6), Angle(0, 0, 90), Vector(2.5, 0.5, 4.5), color_yellow, true)
            hg.organism:CreateHitBox("RightSide",HitBox)
        --//
    --//
    hg.organism:AddArmorInputList("new_vest1", ZC_ARMOR_SLOT_TORSO)
--//

    --\\ Plates
    local FP = "FrontPlate"
    local BP = "BackPlate"
    local LP = "LeftPlate"
    local RP = "RightPlate"

    ENT.PlatesLinks = { -- this is links to armor, table down here, key is name of UID HitBox, value is string link ["FrontPlate"] etc.
        Front =         FP,
        FrontDown =     FP,
        FrontRight =    FP,
        FrontLeft =     FP,

        Back =          BP,
        BackDown =      BP,
        BackRight =     BP,
        BackLeft =      BP,

        LeftSide =      LP,
        RightSide =     RP
    }
    --\\ FrontPlate
        ENT.FrontPlate = {}
        ENT.FrontPlate.Protection = ZC_ARMOR_PROTCLASS_IV
            --\\ Protection classes
                -- ZC_ARMOR_PROTCLASS_II = 4
                -- ZC_ARMOR_PROTCLASS_IIIA = 8
                -- ZC_ARMOR_PROTCLASS_III = 12
                -- ZC_ARMOR_PROTCLASS_III_PLUS = 16
                -- ZC_ARMOR_PROTCLASS_IV = 22
        ENT.FrontPlate.ProtectionDamageMul = 0.4                   -- protected damage mul
        ENT.FrontPlate.PenetratedDamageMul = 0.7                   -- penetrated damage mul

        ENT.FrontPlate.BalisticMaterial = ZC_ARMOR_MATERIAL_CERAMIC -- actually this is just a mul of degradation armor
            --\\ BalisticMaterials
                -- ZC_ARMOR_MATERIAL_CERAMIC = 3
                -- ZC_ARMOR_MATERIAL_TITAN = 1.8
                -- ZC_ARMOR_MATERIAL_ARSTEEL = 1.4

                -- ZC_ARMOR_MATERIAL_KEVLAR = 0.9
                -- ZC_ARMOR_MATERIAL_KEVLAR_CERAMIC = 0.75
                -- ZC_ARMOR_MATERIAL_KEVLAR_ARSTEEL = 0.6
                -- ZC_ARMOR_MATERIAL_KEVLAR_TITAN = 0.45
        ENT.FrontPlate.Durability = 100                            -- durability
        ENT.FrontPlate.DurabilityMax = 100                         -- max durability, for the future repair armor (yeah i'm doing immersive shit)
        ENT.FrontPlate.DurabilityWarranty = 70                     -- guarantee that the protection level will not decrease (no debuff) upon the degradation

        ENT.FrontPlate.NeedPunch = false                           -- viewpunch after impact
    --//       
    
    --\\ BackPlate
        ENT.BackPlate = {}
        ENT.BackPlate.Protection = ZC_ARMOR_PROTCLASS_IV
        ENT.BackPlate.ProtectionDamageMul = 0.4                   -- protected damage mul
        ENT.BackPlate.PenetratedDamageMul = 0.7                   -- penetrated damage mul

        ENT.BackPlate.BalisticMaterial = ZC_ARMOR_MATERIAL_CERAMIC -- actually this is just a mul of degradation armor
        ENT.BackPlate.Durability = 170                            -- durability
        ENT.BackPlate.DurabilityMax = 170                         -- max durability, for the future repair armor (yeah i'm doing immersive shit)
        ENT.BackPlate.DurabilityWarranty = 70                    -- guarantee that the protection level will not decrease (no debuff) upon the degradation

        ENT.BackPlate.NeedPunch = false                           -- viewpunch after impact
    --//  

    --\\ LeftPlate
        ENT.LeftPlate = {}
        ENT.LeftPlate.Protection = ZC_ARMOR_PROTCLASS_II
        ENT.LeftPlate.ProtectionDamageMul = 0.6                   -- protected damage mul
        ENT.LeftPlate.PenetratedDamageMul = 0.8                   -- penetrated damage mul

        ENT.LeftPlate.BalisticMaterial = ZC_ARMOR_MATERIAL_KEVLAR -- actually this is just a mul of degradation armor
        ENT.LeftPlate.Durability = 25                            -- durability
        ENT.LeftPlate.DurabilityMax = 25                         -- max durability, for the future repair armor (yeah i'm doing immersive shit)
        ENT.LeftPlate.DurabilityWarranty = 20                     -- guarantee that the protection level will not decrease (no debuff) upon the degradation

        ENT.LeftPlate.NeedPunch = false                           -- viewpunch after impact
    --//  

    --\\ LeftPlate
        ENT.RightPlate = {}
        ENT.RightPlate.Protection = ZC_ARMOR_PROTCLASS_II
        ENT.RightPlate.ProtectionDamageMul = 0.6                   -- protected damage mul
        ENT.RightPlate.PenetratedDamageMul = 0.8                   -- penetrated damage mul

        ENT.RightPlate.BalisticMaterial = ZC_ARMOR_MATERIAL_KEVLAR -- actually this is just a mul of degradation armor
        ENT.RightPlate.Durability = 25                            -- durability
        ENT.RightPlate.DurabilityMax = 25                         -- max durability, for the future repair armor (yeah i'm doing immersive shit)
        ENT.RightPlate.DurabilityWarranty = 20                     -- guarantee that the protection level will not decrease (no debuff) upon the degradation

        ENT.RightPlate.NeedPunch = false                           -- viewpunch after impact
    --//  
--//

--\\ Render male model
ENT.Male = {}
ENT.Male.Model = "models/combataegis/body/ballisticvest.mdl"
ENT.Male.ModelSubMaterials = {}                     -- submaterials on rendered model
ENT.Male.HideSubMaterails = {}                      -- playermodel hide submaterials
ENT.Male.Skin = 0                                   -- skin on rendered model
ENT.Male.Bodygroups = "0000000000000"               -- bodygroups on rendered model
--
ENT.Male.BoneMerge = false
ENT.Male.ParentBone = "ValveBiped.Bip01_Spine2"     -- parent bone
ENT.Male.OffsetPos = Vector(17.8,2.8,0)
ENT.Male.OffsetAng = Angle(0,88,90)
ENT.Male.ModelSize = 1
--//

--\\ Render female model
ENT.FeMale = {}
ENT.FeMale.Model = "models/combataegis/body/ballisticvest.mdl"
ENT.FeMale.ModelSubMaterials = {}                   -- submaterials on rendered model
ENT.FeMale.HideSubMaterails = {}                    -- playermodel hide submaterials
ENT.FeMale.Skin = 0                                 -- skin on rendered model
ENT.FeMale.Bodygroups = "0000000000000"             -- bodygroups on rendered model
--
ENT.FeMale.BoneMerge = false
ENT.FeMale.ParentBone = "ValveBiped.Bip01_Spine2"   -- parent bone
ENT.FeMale.OffsetPos = Vector(15,2.5,0)
ENT.FeMale.OffsetAng = Angle(0,90,90)
ENT.FeMale.ModelSize = 0.9
--//
local filename = string.StripExtension(string.GetFileFromFilename( GetCurrentLuaFile() ))
scripted_ents.Register(ENT, filename)