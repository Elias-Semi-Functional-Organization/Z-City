teams = {
	[0] = {
		color = Color(255, 0, 0),
		name = "Terrorists",
	},
	[1] = {
		color = Color(0, 0, 255),
		name = "Counter Terrorists",
	}
}

local team_GetPlayers = team.GetPlayers
function zb:BalancedChoice(first, second)
	local team0, team1 = team_GetPlayers(first), team_GetPlayers(second)
	return (#team0 > #team1 and second) or (#team1 > #team0 and first) or first
end

local player_GetAll = player.GetAll
function zb:AutoBalance()
	local mode = CurrentRound()

	if mode.OverrideBalance and mode:OverrideBalance() then return end

	for i, ply in player.Iterator() do
		if ply:Team() == TEAM_SPECTATOR then continue end
		ply:SetTeam(TEAM_UNASSIGNED)
	end

	for i, ply in RandomPairs(player_GetAll()) do
		if ply:Team() == TEAM_SPECTATOR then continue end
		ply:SetTeam(zb:BalancedChoice(0, 1))
	end

	if mode.name == "hns" then
		print("Gamemode is Hide and Seek!")
		local users = {}
			for i, ply in ipairs(player_GetAll()) do
			if ply:Team() == TEAM_SPECTATOR then continue end
			if ply:IsBot() == true then ply:SetTeam(1) continue end
			table.insert(users, ply:SteamID())
			print(ply:SteamID())
		end
		local seeker = math.random(1, #users)
		player.GetBySteamID(users[seeker]):SetTeam(0)
		table.remove(users, seeker)
		for i, ply in ipairs(users) do
			player.GetBySteamID(ply):SetTeam(1)
		end
	end
end