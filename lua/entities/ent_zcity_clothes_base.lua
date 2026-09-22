-- meow

AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "ent_zcity_equipment_base"
ENT.PrintName = "Equipment base"
ENT.Category = "ZCity Equipment"
ENT.Spawnable = false
ENT.Model = "models/props_junk/cardboard_box003a.mdl"
ENT.IconOverride = ""

ENT.SlotOccupation = {
    --[ZC_CLOTHES_SLOT_TORSO] = true,
    --[ZC_CLOTHES_SLOT_PANTS] = true,
    --[ZC_CLOTHES_SLOT_BOOTS] = true,
}

ENT.Male = {}
ENT.Male.Model = ""
ENT.Male.HideSubMaterails = {}
ENT.Male.Skin = 0
ENT.Male.Bodygroups = "0000000000000"

ENT.FeMale = {}
ENT.FeMale.Model = ""
ENT.FeMale.HideSubMaterails = {}
ENT.FeMale.Skin = 0
ENT.FeMale.Bodygroups = "0000000000000"

ENT.PhysicsSounds = true

ENT.NamePos = Vector(12,1.5,4.6)
ENT.NameAng = Angle(0,-90,0)

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
            model:AddEffects(EF_BONEMERGE)

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

        model:DrawModel()
    end
--//

--\\ Temperature system
    hook.Add("ZC_BodyTemperature", "EquipmentSaveTemp", function(ply, org, timeValue, changeRate, MaxWarmMul, warmLoseMul)
        local Equipment = ply:GetNetVar("zc_equipment", {})
        if #Equipment < 1 then return end

        for i = 1, #Equipment do
            local Equip = Entity(Equipment[i])
            if !IsValid(Equip) then continue end
            if !Equip.WarmSave then continue end
            MaxWarmMul = MaxWarmMul + (Equip.WarmSave / 1.5)
            changeRate = changeRate * math.max(1 - Equip.WarmSave, 0.1)
            --warmLoseMul = warmLoseMul * math.max(1 - Equip.WarmSave / 2.5, 0.1)
        end

        return changeRate, MaxWarmMul, warmLoseMul
    end)
--//