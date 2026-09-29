zb = zb or {}

--\\ Delta netvars
    --[[
        Some netvars (inventory) are big tables what change often, sending them fully every time is stupid.
        So table is sent fully only once, after that SetNetVar sends only what changed (delta).

        Delta works 2 levels deep: var[category][key] = value
            Inventory.Weapons["weapon_ak74"] = ent  -> category "Weapons", key "weapon_ak74"
            Inventory.Ammo[5] = 30                  -> category "Ammo", key 5
        If value is a table (weapon info) it's compared deeply, but sent whole.

        Server keeps a copy of what clients already have (zb.net.sent[ent][key]),
        diffs new value with it and broadcasts only changed/removed keys.
        New clients get this copy fully through SyncVars, so everyone has the same table.

        On client table is patched in place and OnNetVarSet is called like before,
        so all old code with SetNetVar/GetNetVar works without changes :D
    --]]

    -- key == nil - whole category, value == nil - remove it
    local function ApplyDelta(tbl, category, key, value)
        if key == nil then tbl[category] = value return end
        if !istable(tbl[category]) then tbl[category] = {} end

        tbl[category][key] = value
    end
--//

if (CLIENT) then
    local entityMeta = FindMetaTable("Entity")
    local playerMeta = FindMetaTable("Player")

    zb.net = zb.net or {}
    zb.net.globals = zb.net.globals or {}

    net.Receive("zbGlobalVarSet", function()
        local key, var = net.ReadString(), net.ReadType()

    	zb.net.globals[key] = var

        hook.Run("OnGlobalVarSet", key, var)
    end)

    net.Receive("zbNetVarSet", function()
        local index = net.ReadUInt(16)

		local key = net.ReadString()
    	local var = net.ReadType()
		
        zb.net[index] = zb.net[index] or {}
        zb.net[index][key] = var

		-- print(index, key)
		
		if IsValid(Entity(index)) then
			hook.Run("OnNetVarSet", index, key, var)
		else
			zb.net[index].waiting = true
		end
    end)

    net.Receive("zbNetVarDelta", function()
        local index = net.ReadUInt(16)
        local key = net.ReadString()

        zb.net[index] = zb.net[index] or {}
        if !istable(zb.net[index][key]) then zb.net[index][key] = {} end

        local var = zb.net[index][key]
        for i = 1, net.ReadUInt(16) do
            local category, k, value = net.ReadType(), net.ReadType(), net.ReadType()
            ApplyDelta(var, category, k, value)
        end

        if IsValid(Entity(index)) then
            hook.Run("OnNetVarSet", index, key, var)
        else
            zb.net[index].waiting = true
        end
    end)

    net.Receive("zbNetVarDelete", function()
    	zb.net[net.ReadUInt(16)] = nil
    end)

    net.Receive("zbLocalVarSet", function()
    	local key = net.ReadString()
    	local var = net.ReadType()

    	zb.net[LocalPlayer():EntIndex()] = zb.net[LocalPlayer():EntIndex()] or {}
    	zb.net[LocalPlayer():EntIndex()][key] = var

    	hook.Run("OnLocalVarSet", key, var)
    end)

    function GetNetVar(key, default) -- luacheck: globals GetNetVar
    	local value = zb.net.globals[key]

    	return value != nil and value or default
    end

    function entityMeta:GetNetVar(key, default)
    	local index = self:EntIndex()

    	if (zb.net[index] and zb.net[index][key] != nil) then
    		return zb.net[index][key]
    	end

    	return default
    end

    playerMeta.GetLocalVar = entityMeta.GetNetVar

	hook.Add("InitPostEntity", "OnRequestFullUpdate_zb", function()
		LocalPlayer():SyncVars()
	end)

	function playerMeta:SyncVars()
		net.Start("ZB_request_fullupdate")
		net.SendToServer()
	end
else
	util.AddNetworkString("ZB_request_fullupdate")

	net.Receive("ZB_request_fullupdate",function(len,ply)
		ply.cooldown_sendnet = ply.cooldown_sendnet or 0
		if ply.cooldown_sendnet < CurTime() then
			ply.cooldown_sendnet = CurTime() + 1

			ply:SyncVars()
		end
	end)

	gameevent.Listen( "OnRequestFullUpdate" )
	hook.Add("OnRequestFullUpdate", "OnRequestFullUpdate_zb", function(data)
		local id = data.userid
		local ply = Player(id)
		
		ply:SyncVars()
	end)
	
	
    local entityMeta = FindMetaTable("Entity")
    local playerMeta = FindMetaTable("Player")

    zb.net = zb.net or {}
    zb.net.list = zb.net.list or {}
    zb.net.locals = zb.net.locals or {}
    zb.net.globals = zb.net.globals or {}

    util.AddNetworkString("zbGlobalVarSet")
    util.AddNetworkString("zbLocalVarSet")
    util.AddNetworkString("zbNetVarSet")
    util.AddNetworkString("zbNetVarDelete")
    util.AddNetworkString("zbNetVarDelta")

    --\\ Delta netvars
        -- add your key here if netvar is a big table of tables and it changes often
        local DeltaVars = {
            ["Inventory"] = true,
        }

        zb.net.sent = zb.net.sent or {}

        local function IsEqual(a, b)
            if a == b then return true end
            if !istable(a) or !istable(b) then return false end

            for k, v in pairs(a) do
                if !IsEqual(v, b[k]) then return false end
            end

            for k in pairs(b) do
                if a[k] == nil then return false end
            end

            return true
        end

        local function Copy(value)
            return istable(value) and table.Copy(value) or value
        end

        -- {category, key, value}, see ApplyDelta
        local function GetDelta(old, new)
            local delta = {}

            for category, items in pairs(new) do
                local oldItems = old[category]

                if istable(items) and istable(oldItems) then
                    for k, v in pairs(items) do
                        if !IsEqual(oldItems[k], v) then delta[#delta + 1] = {category, k, v} end
                    end

                    for k in pairs(oldItems) do
                        if items[k] == nil then delta[#delta + 1] = {category, k} end
                    end
                elseif !IsEqual(oldItems, items) then
                    delta[#delta + 1] = {category, nil, items}
                end
            end

            for category in pairs(old) do
                if new[category] == nil then delta[#delta + 1] = {category} end
            end

            return delta
        end

        function entityMeta:SendNetVarDelta(key)
            local sent = zb.net.sent[self]
            local old, new = sent and sent[key], zb.net.list[self][key]

            -- first send (or not a table), send it fully
            if !istable(old) or !istable(new) then
                if IsEqual(old, new) then return end

                zb.net.sent[self] = sent or {}
                zb.net.sent[self][key] = Copy(new)

                self:SendNetVar(key)
                return
            end

            local delta = GetDelta(old, new)
            if #delta < 1 then return end

            net.Start("zbNetVarDelta")
                net.WriteUInt(self:EntIndex(), 16)
                net.WriteString(key)
                net.WriteUInt(#delta, 16)
                for i = 1, #delta do
                    local category, k, value = delta[i][1], delta[i][2], delta[i][3]
                    net.WriteType(category)
                    net.WriteType(k)
                    net.WriteType(value)

                    ApplyDelta(old, category, k, Copy(value))
                end
            net.Broadcast()
        end
    --//

    local function CheckBadType(name, object)
		return false
    	--[[if (isfunction(object)) then
    		ErrorNoHalt("Net var '" .. name .. "' contains a bad object type!")

    		return true
    	elseif (istable(object)) then
    		for k, v in pairs(object) do
    			if (CheckBadType(name, k) or CheckBadType(name, v)) then
    				return true
    			end
    		end
    	end--]]
    end

    function GetNetVar(key, default)
    	local value = zb.net.globals[key]

    	return value != nil and value or default
    end

    function SetNetVar(key, value, receiver, unreliable)
    	if (CheckBadType(key, value)) then return end
    	--if (GetNetVar(key) == value) then return end
		
    	zb.net.globals[key] = value

    	net.Start("zbGlobalVarSet", unreliable)
    	net.WriteString(key)
    	net.WriteType(value)

    	if (receiver == nil) then
    		net.Broadcast()
    	else
    		net.Send(receiver)
    	end
    end
	
    function playerMeta:SyncVars()
    	for k, v in pairs(zb.net.globals) do
    		net.Start("zbGlobalVarSet")
    			net.WriteString(k)
    			net.WriteType(v)
    		net.Send(self)
    	end

    	for k, v in pairs(zb.net.locals[self] or {}) do
    		net.Start("zbLocalVarSet")
    			net.WriteString(k)
    			net.WriteType(v)
    		net.Send(self)
    	end

    	for entity, data in pairs(zb.net.list) do
    		if (IsValid(entity)) then
    			local index = entity:EntIndex()
    			local sent = zb.net.sent[entity]

    			for k, v in pairs(data) do
    				-- delta vars: send what other clients have, next deltas are made from it
    				if DeltaVars[k] and sent and sent[k] != nil then v = sent[k] end

    				net.Start("zbNetVarSet")
    					net.WriteUInt(index, 16)
    					net.WriteString(k)
    					net.WriteType(v)
    				net.Send(self)
    			end
			else
				zb.net.list[entity] = nil
				zb.net.sent[entity] = nil
    		end
    	end
    end
	
    function playerMeta:GetLocalVar(key, default)
    	if (zb.net.locals[self] and zb.net.locals[self][key] != nil) then
    		return zb.net.locals[self][key]
    	end

    	return default
    end

    function playerMeta:SetLocalVar(key, value)
    	if (CheckBadType(key, value)) then return end

    	zb.net.locals[self] = zb.net.locals[self] or {}
    	zb.net.locals[self][key] = value

    	net.Start("zbLocalVarSet")
    		net.WriteString(key)
    		net.WriteType(value)
    	net.Send(self)
    end

    function entityMeta:GetNetVar(key, default)
    	if (zb.net.list[self] and zb.net.list[self][key] != nil) then
    		return zb.net.list[self][key]
    	end

    	return default
    end

    function entityMeta:SetNetVar(key, value, receiver)
    	if (CheckBadType(key, value)) then return end

		zb.net.list[self] = zb.net.list[self] or {}

		--if not hg.IsChanged(value, key, zb.net.list[self]) then return end

    	if (zb.net.list[self][key] != value) then
    		zb.net.list[self][key] = value
    	end

		if DeltaVars[key] and receiver == nil then
			self:SendNetVarDelta(key)
			return
		end

		self:SendNetVar(key, receiver)
	end

    function entityMeta:SendNetVar(key, receiver)
    	net.Start("zbNetVarSet")
    	net.WriteUInt(self:EntIndex(), 16)
    	net.WriteString(key)
    	net.WriteType(zb.net.list[self] and zb.net.list[self][key])

    	if (receiver == nil) then
    		net.Broadcast()
    	else
    		net.Send(receiver)
    	end
    end

    function entityMeta:ClearNetVars(receiver)
    	if !zb.net.list[self] and !zb.net.locals[self] then return end

    	zb.net.list[self] = nil
    	zb.net.sent[self] = nil
    	zb.net.locals[self] = nil

    	net.Start("zbNetVarDelete")
    	net.WriteUInt(self:EntIndex(), 16)

    	if (receiver == nil) then
    		net.Broadcast()
    	else
    		net.Send(receiver)
    	end
    end
	
	hook.Add("EntityRemoved","ZB_clear_net",function(ent,fullUpdate)
		ent:ClearNetVars()
	end)

	hook.Add("PlayerDisconnected","ZB_clear_net",function(ply)
		ply:ClearNetVars()
	end)
end