--[[ Inventory
    Everything what can be looted (players, their death ragdolls, npc ragdolls, loot boxes)
    got ent.inventory and the same table in netvar "Inventory":

    ent.inventory = {
        Weapons = {
            ["weapon_ak74"] = Weapon,           -- players/death ragdolls: weapon entity (on ragdoll it's hidden and parented to it)
            ["weapon_glock17"] = {17, {...}},   -- npc ragdolls/loot boxes: SWEP:GetInfo() or true, weapon is created when taken
            ["hg_sling"] = true,                -- virtual items, see VirtualItems
        },
        Ammo = {
            [ammoID] = count,                   -- players: ply:GetAmmo()
        },
        --Armor = {},                           -- not used anywhere right now, armor lives in ent.armors (netvar "Armor") and netvar "zc_equipment"
        Attachments = {
            [1] = "supressor2",
        },
    }

    --\\ How to change inventory
        Change the table and call SetNetVar. It's not sending whole table anymore,
        only what changed (see Delta netvars in libraries/core/sh_networking.lua):

        local inv = ply:GetNetVar("Inventory", {})
        inv.Weapons = inv.Weapons or {}
        inv.Weapons["hg_sling"] = true
        ply:SetNetVar("Inventory", inv)

        On client ply:GetNetVar("Inventory") is patched in place by deltas, read it but don't change it!
    --//

    --\\ Hooks
        ItemsTransfered(ply, ragdoll)                       -- player died, items moved to his death ragdoll
        ItemsRemoved(ply)                                   -- player died without ragdoll
        ItemTransfer(ply, ent, placement, armor)            -- armor taken from ent
        ZB_CanLootInventory(ply, ent) -> ply, ent, canloot  -- return canloot = false to block looting
        ZB_InventoryChecked(ply, ent)                       -- before opening, loot boxes generate loot here
        ZB_InventoryOpened(ply, ent)
    --//

    --\\ Net
        should_open_inv     server -> client    Entity
        ply_take_item       client -> server    String tab, String key, Entity
    --//

    --\\ Prop inventory example
        local ent = ents.Create("prop_physics")
        ent:SetModel("models/props_interiors/Furniture_Desk01a.mdl")
        ent:SetPos(Entity(1):GetEyeTrace().HitPos)
        ent:Spawn()
        ent.inventory = {Weapons = {["weapon_ar15"] = {30, hg.ClearAttachments("weapon_ar15")}}}
        hg.SetAttachment(ent.inventory.Weapons["weapon_ar15"][2], "supressor2", "weapon_ar15")
        ent:SetNetVar("Inventory", ent.inventory)
    --//
--]]


local BlackList = {
    ["weapon_hands_sh"] = true,
    ["weapon_zombclaws"] = true,
    ["weapon_physgun"] = true,
    ["gmod_tool"] = true,
}

-- not SWEPs, just true in Weapons. They stay in inventory when weapons are renewed
local VirtualItems = {
    ["hg_sling"] = true,
    ["hg_brassknuckles"] = true,
    ["hg_flashlight"] = true,
}

--\\ Create / Renew
    -- rebuilds Weapons and Ammo from what player really has, isDead - hide weapons on death ragdoll
    function hg.RenewInv(ply, isDead)
        ply.inventory = ply.inventory or {}

        local inv = ply.inventory
        local OldWeapons = inv.Weapons or {}
        local rag = ply:GetNWEntity("RagdollDeath")

        inv.Weapons = {}
        for _, wep in ipairs(ply:GetWeapons()) do
            local class = wep:GetClass()
            if BlackList[class] then continue end

            if isDead then
                ply:DropWeapon(wep)

                wep:SetNoDraw(true)
                wep:DrawShadow(false)
                wep:AddSolidFlags(FSOLID_NOT_SOLID)

                if IsValid(rag) then
                    wep:SetPos(rag:GetPos() + vector_up * -10000)
                    wep:SetParent(rag, 0)
                else
                    wep:SetPos(ply:GetPos())
                    wep:SetParent(ply, 0)
                end
            end

            inv.Weapons[class] = wep
        end

        for class in pairs(VirtualItems) do
            inv.Weapons[class] = OldWeapons[class]
        end

        inv.Ammo = ply:GetAmmo()
        --inv.Armor = inv.Armor or {} -- not used anywhere right now, armor is in netvars "Armor" and "zc_equipment"
        inv.Attachments = inv.Attachments or {}

        ply:SetNetVar("Inventory", inv)
    end

    function hg.CreateInv(ply)
        ply.inventory = {}
        hg.RenewInv(ply)
    end
--//

--\\ Player hooks
    hook.Add("Player Spawn", "homigrad-inventory", function(ply)
        hg.CreateInv(ply)
        ply.armors = {}
        ply.armors_health = {}
        ply:SyncArmor()
    end)

    hook.Add("PlayerLoadout", "giveHands", function(ply)
        ply:Give("weapon_hands_sh")
        return true
    end)

    hook.Add("WeaponEquip", "homigrad-inventory", function(wep, ply)
        if BlackList[wep:GetClass()] then return end

        local inv = ply.inventory or {}
        inv.Weapons = inv.Weapons or {}
        inv.Weapons[wep:GetClass()] = wep

        wep:SetNoDraw(false)

        if wep.sling then
            wep.sling = nil

            if !inv.Weapons["hg_sling"] then
                inv.Weapons["hg_sling"] = true
                ply:ChatPrint("You took the sling the weapon was attached to.")
            else
                local sling = ents.Create("hg_sling")
                sling:SetPos(ply:EyePos())
                sling:SetVelocity(ply:GetAimVector() * 5)
                sling:Spawn()
                ply:ChatPrint("You deattached the sling the weapon was connected to.")
            end
        end

        ply:SetNetVar("Inventory", inv)
    end)

    hook.Add("PlayerDroppedWeapon", "homigrad-inventory", function(ply, wep)
        if ply:IsNPC() then return end

        local inv = ply.inventory
        if !inv or !inv.Weapons or !inv.Weapons[wep:GetClass()] then return end

        inv.Weapons[wep:GetClass()] = nil
        ply:SetNetVar("Inventory", inv)
    end)

    hook.Add("PlayerAmmoChanged", "homigrad-inventory", function(ply, ammoID, oldCount, newCount)
        if !ply.inventory then return end

        ply.inventory.Ammo = ply:GetAmmo()
        ply:SetNetVar("Inventory", ply.inventory)

        -- hl2 grenade ammo turns into grenade weapon
        if game.GetAmmoName(ammoID) != "Grenade" then return end

        local wep = ply:Give("weapon_hg_hl2nade_tpik")
        if !IsValid(wep) then return end

        wep.DontEquipInstantly = true
        wep.count = newCount - oldCount
        ply:SetAmmo(0, ammoID)

        timer.Simple(0.1, function()
            if !IsValid(wep) then return end
            wep.DontEquipInstantly = nil
        end)
    end)
--//

--\\ Drop active weapon, on death it stays in ragdoll hand
    local vecZero = Vector(0, 0, 0)
    local vecHandOffset = Vector(3.5, 0, 0)

    hook.Add("PlayerDropWeapon", "homigrad-inventory", function(ply)
        local wep = ply:GetActiveWeapon()
        if !IsValid(wep) or wep.NoDrop then return end

        if wep.RemoveFake then wep:RemoveFake() end
        wep:SetCollisionGroup(COLLISION_GROUP_WORLD)
        ply:DropWeapon(wep, ply:EyePos(), vecZero)
        wep:SetPos(ply:EyePos())
        ply:SetActiveWeapon(NULL)

        timer.Simple(0.1, function()
            if !IsValid(wep) or !IsValid(ply) then return end

            local ent = IsValid(ply:GetNWEntity("RagdollDeath")) and ply:GetNWEntity("RagdollDeath") or ply.FakeRagdoll
            if !IsValid(ent) then return end

            local bon = ent:LookupBone("ValveBiped.Bip01_R_Hand")
            local handpos, handang = ent:GetPos(), ent:GetAngles()
            if bon then
                local phys = ent:GetPhysicsObjectNum(ent:TranslateBoneToPhysBone(bon))
                if IsValid(phys) then
                    handpos = phys:GetPos()
                    handang = phys:GetAngles()
                end
            end

            local pos, ang = LocalToWorld(wep.WorldPos and wep.WorldPos + vecHandOffset or vector_origin, wep.WorldAng or angle_zero, handpos, handang)
            ang:RotateAroundAxis(ang:Forward(), 180)
            wep:SetPos(pos)
            wep:SetAngles(ang)
            wep:SetVelocity(vector_origin)
            wep:SetCollisionGroup(COLLISION_GROUP_WEAPON)

            local physbone = ent:TranslateBoneToPhysBone(bon)
            local physbonetorso = ent:TranslateBoneToPhysBone(ent:LookupBone("ValveBiped.Bip01_Spine2"))

            local cons = constraint.Weld(wep, ent, 0, physbone, 600, true, false)

            if math.random(1, 10) <= 2 then
                timer.Simple(4, function()
                    timer.Simple(0, function()
                        constraint.NoCollide(wep, ent, 0, 0)
                    end)

                    if IsValid(cons) then cons:Remove() end
                end)
            end

            --\\ Sling, rifle hangs on the body
                local owner = ply:Alive() and (ply.organism and !ply.organism.otrub) and ply or ent
                local inv = owner:GetNetVar("Inventory", {})
                if !inv.Weapons or !inv.Weapons["hg_sling"] then return end
                if !ishgweapon(wep) or wep:IsPistolHoldType() then return end

                constraint.Rope(wep, ent, 0, physbonetorso, vector_origin, vector_origin, 10, 5, 0, 0, "null", true, color_white)
                wep.sling = true
                ent.rope_attach = wep

                inv.Weapons["hg_sling"] = nil
                owner:SetNetVar("Inventory", inv)
            --//
        end)
    end)
--//

--\\ Death, items go to death ragdoll
    function hg.TransferItems(ply, ragdoll)
        if !IsValid(ragdoll) then
            hook.Run("ItemsRemoved", ply)
            return
        end

        ragdoll.inventory = ply:GetNetVar("Inventory", {})
        ragdoll:SetNetVar("Inventory", ragdoll.inventory)

        ply.inventory = {}
        ply:SetNetVar("Inventory", ply.inventory)

        hook.Run("ItemsTransfered", ply, ragdoll)

        ragdoll:SetNetVar("Armor", ply.armors)
        ragdoll.armors = ragdoll:GetNetVar("Armor", {})
        ragdoll:SetNetVar("HideArmorRender", ply:GetNetVar("HideArmorRender", false))

        ply:SetNetVar("Armor", {})
        ply.armors = ply:GetNetVar("Armor", {})
    end

    hook.Add("DoPlayerDeath", "homigrad-inventory", function(ply)
        hook.Run("PlayerDropWeapon", ply)
    end)

    hook.Add("PostPlayerDeath", "homigrad-inventory", function(ply)
        hg.RenewInv(ply, true)
        hg.TransferItems(ply, ply:GetNWEntity("RagdollDeath"))

        -- without ragdoll items are just gone
        ply.inventory = {}
        ply:SetNetVar("Inventory", ply.inventory)
        ply:SetNetVar("Armor", {})
        ply:RemoveAllAmmo()
    end)
--//

--\\ Take item
    -- (ply, ent, key), key is always a string from client
    local TakeItem = {}

    TakeItem["Weapons"] = function(ply, ent, class)
        local Weapons = ent.inventory and ent.inventory.Weapons
        local item = Weapons and Weapons[class]
        if !item then return end

        local activeWep = ent:IsPlayer() and ent:GetActiveWeapon()
        if IsValid(activeWep) and activeWep:GetClass() == class then return end

        local isEnt = isentity(item) and IsValid(item) and item:IsWeapon()
        local weapon = isEnt and item or ents.Create(class)
        if !IsValid(weapon) then return end

        weapon.DontEquipInstantly = !weapon.NoHolster and weapon.weaponInvCategory != 1

        if isEnt then
            weapon:SetParent(NULL)
            weapon:SetPos(hg.eyeTrace(ply, 60).HitPos)
            weapon:SetAngles(ent:GetAngles())
            weapon:SetNoDraw(false)
            weapon:DrawShadow(true)
            weapon:RemoveSolidFlags(FSOLID_NOT_SOLID)
        else
            weapon.IsSpawned = true
            weapon.init = true
            weapon:Spawn()
            weapon:SetPos(ent:GetPos())
            weapon:SetAngles(ent:GetAngles())

            if weapon.SetInfo then weapon:SetInfo(item) end
        end

        Weapons[class] = nil

        if ent:IsPlayer() then
            if isEnt then
                ent:DropWeapon(weapon)
                weapon:SetPos(hg.eyeTrace(ply, 60).HitPos)
            else
                ent:StripWeapon(class)
            end
        end

        ply:DropObject()

        -- virtual items (hg_sling etc.) are entities, they give themselves on use
        if !weapon:IsWeapon() then weapon:Use(ply) return end

        weapon.IsSpawned = false
        weapon.init = false

        if !hook.Run("PlayerCanPickupWeapon", ply, weapon) then
            weapon.IsSpawned = true
            weapon.init = true
            weapon:SetPos(ply:EyePos())
            return
        end

        ply:PickupWeapon(weapon)

        if weapon.DontEquipInstantly then return end

        timer.Simple(0, function()
            if !IsValid(ply) or !IsValid(weapon) then return end
            ply:SelectWeapon(weapon:GetClass())
        end)
    end

    TakeItem["Ammo"] = function(ply, ent, ammoID)
        ammoID = tonumber(ammoID)

        local Ammo = ent.inventory and ent.inventory.Ammo
        local count = ammoID and Ammo and Ammo[ammoID]
        if !count then return end

        local name = game.GetAmmoName(ammoID)
        ply:GiveAmmo(count, name, true)

        if ent:IsPlayer() then
            ent:SetAmmo(0, name)
        else
            Ammo[ammoID] = nil
        end
    end

    TakeItem["Armor"] = function(ply, ent, placement)
        local armor = ent.armors and ent.armors[placement]
        local armorData = armor and hg.armor[placement] and hg.armor[placement][armor]
        if !armorData or armorData.nodrop then return end
        if ply.armors and ply.armors[placement] then return end
        if !hg.AddArmor(ply, armor) then return end

        ent.armors[placement] = nil

        if placement == "face" and ent:GetNetVar("zableval_masku", false) and armor != "nightvision1" then
            ply:SetNetVar("zableval_masku", true)
            ent:SetNetVar("zableval_masku", false)
        end

        hook.Run("ItemTransfer", ply, ent, placement, armor)
    end

    TakeItem["Attachments"] = function(ply, ent, index)
        index = tonumber(index)

        local Attachments = ent.inventory and ent.inventory.Attachments
        local att = index and Attachments and Attachments[index]
        if !att then return end

        ply.inventory.Attachments = ply.inventory.Attachments or {}
        ply.inventory.Attachments[#ply.inventory.Attachments + 1] = att
        Attachments[index] = nil
    end

    TakeItem["Equipment"] = function(ply, ent, index)
        local equipIndex = ent:GetEquipments()[tonumber(index) or 0]
        local Equip = equipIndex and Entity(equipIndex)
        if !IsValid(Equip) then return end

        Equip:Unwear(ent)
        Equip:Use(ply)
    end

    util.AddNetworkString("ply_take_item")
    net.Receive("ply_take_item", function(len, ply)
        if (ply.cooldown_takeitem or 0) > CurTime() then return end
        ply.cooldown_takeitem = CurTime() + 0.5

        local tab = net.ReadString()
        local key = net.ReadString()
        local ent = net.ReadEntity()

        local Take = TakeItem[tab]
        if !Take or !IsValid(ent) then return end
        if !ply:Alive() or (ply.organism and ply.organism.otrub) then return end
        if ent:IsPlayer() and !IsValid(ent.FakeRagdoll) then return end
        if ent:GetPos():Distance(ply:GetPos()) > 125 then return end

        Take(ply, ent, key)

        ply:SetNetVar("Inventory", ply.inventory)
        ent:SetNetVar("Inventory", ent.inventory)
        ply:SyncArmor()
        ent:SyncArmor()
    end)
--//

--\\ Open inventory
    util.AddNetworkString("should_open_inv")

    local playerMeta = FindMetaTable("Player")

    function playerMeta:OpenInventory(ent)
        hook.Run("ZB_InventoryOpened", self, ent)
        if !IsValid(ent) then return end
        if ent:IsPlayer() and !IsValid(ent.FakeRagdoll) then return end

        if ent:IsPlayer() then hg.RenewInv(ent) end
        hg.RenewInv(self)
        self.cooldown_takeitem = CurTime() + 0.5

        net.Start("should_open_inv")
            net.WriteEntity(ent)
        net.Send(self)
    end

    function playerMeta:GetLookTrace()
        if !IsValid(self) or !self:Alive() then return end

        local ent = IsValid(self.FakeRagdoll) and self.FakeRagdoll or self
        local att = ent:GetAttachment(ent:LookupAttachment("eyes"))
        if !att then return false end

        return util.TraceLine({
            start = att.Pos,
            endpos = att.Pos + self:EyeAngles():Forward() * 80,
            filter = ent
        })
    end

    -- standing: RMB + E, in fake: ALT + SHIFT
    hook.Add("Player Think", "loot-fellows", function(ply)
        if !ply:Alive() then return end

        local use
        if IsValid(ply.FakeRagdoll) then
            use = ply:KeyDown(IN_WALK) and ply:KeyDown(IN_SPEED) and !ply:KeyDown(IN_ATTACK) and !ply:KeyDown(IN_ATTACK2)
        else
            use = ply:KeyDown(IN_ATTACK2) and ply:KeyDown(IN_USE)
        end

        if !use then ply.keypressed = false return end
        if ply.keypressed then return end

        local trace = hg.eyeTrace(ply, 60)
        if !trace then return end

        local ent = trace.Entity
        ent = IsValid(hg.RagdollOwner(ent)) and hg.RagdollOwner(ent) or ent

        local _, _, canloot = hook.Run("ZB_CanLootInventory", ply, ent)
        if canloot == false then
            ply.keypressed = true
            return
        end

        hook.Run("ZB_InventoryChecked", ply, ent)

        if !IsValid(ent) or !ent:GetNetVar("Inventory") then return end

        ply:OpenInventory(ent)
        ply.keypressed = true
    end)
--//

--[[ scug :p ZTEAM FOREVER! support us pls
░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░
░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░▒▒░░░░░░░░▒▒▒▒▒▒▒▒░░░░░
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░░░░░░░▒░░░░░░
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░░░░▒░░░░░░░░░░▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░▓▓████▓▓▒░▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░▒▓██░░░░░░░░░░▒██▓▒░▓▓███▓▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▒▓▒▓█▓░░░░░░░░░░██▓▓▓████████▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▓████▓░░░░░░░░░░▒█████████████▓▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░▓████▓░░░░░░░░░░░▒█████████████▓▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒░░▓███▓▒░░▒▓▓█▓░░░░░░▒████████████▓▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒░░▒▒░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▓███████▓▓▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
--]]
