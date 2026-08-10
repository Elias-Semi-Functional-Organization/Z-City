local hg_unconscioustimer = CreateClientConVar("hg_unconscioustimer", "1", true, false, "Displays a timer till you're conscious while unconscious! (if you really dislike it that much because of realism you can disable it)")

// wall of flavor text
local flavortextwallofdoom1 = {
	"\"Is my fate really sealed..?\"",
	"Hm... How dissapointing.",
	"\"I had to be at the wrong place at the wrong time...\"",
	"\"Please let this be a bad dream...\"",
	"\"I will wake up... I know I will...\"",
	"You're only an human after all.",
}

local flavortextwallofdoom2 = {
	"Do you think your choices would've changed this outcome?",
	"Do you see it? Your life flashing before your eyes?",
	"It's terrifying I know but...",
	"Is it really that time again?",
	"Was all of it for nothing?",
	"Was there something you could've done..?",
	"You were only preventing the inevitable."
}

local flavortextwallofdoom3 = {
	"Just don't forget...",
	"Just know that you'll be a closed casket at the funeral if you have one.",
	"Just remember that...",
	"Whoever you were, just realize this..."
}

local function randomtextplease()
	local flavor1 = flavortextwallofdoom1[math.random(#flavortextwallofdoom1)]
	local flavor2 = flavortextwallofdoom2[math.random(#flavortextwallofdoom2)]
	local flavor3 = flavortextwallofdoom3[math.random(#flavortextwallofdoom3)]
	return flavor1, flavor2, flavor3
end

local random1, random2, random3 = randomtextplease()

hook.Add("HUDPaint", "UnconsciousTimer", function() // why didn't i make it a different file in the first place i'm dumb
local plyguy = LocalPlayer()
if not IsValid(plyguy) or not plyguy:Alive() then return end
local org = plyguy.organism
if not hg_unconscioustimer:GetBool() then return end

if not org then return end

	local o2 = org.o2 and org.o2[1] or 30
	local brain = org.brain or 0
	local adrenaline = org.adrenaline or 0
	local pulse = org.pulse or 70
	local pain = org.pain or 0
	local hurt = org.hurt or 0
	local blood = org.blood or 5000
	local bleed = org.bleed or 0
    local disorientation = org.disorientation or 0
	local immobilization = org.immobilization or 0
	local incapacitated = org.incapacitated or false
	local critical = org.critical or false
	local shock = org.shock or 0

local unconsciousblud = org.otrub

    if unconsciousblud then

		local textOtrub = "You are unconscious."
		local textOtrub2 =
			( critical and "You can't be saved." ) or
			( incapacitated and "You will not get up without someone's help." ) or
			( pain > 80 and "You're experiencing too much pain. You can't wake up yet.") or
			( shock <= 0.8 and "Something is preventing you from waking up.") or
			(
				"You will wake up in "
				..(
					math.floor(((shock - 5) / 4) + 1) .. " second(s)."
				)
			)
		local textOtrub3 =
		(brain >= 0.57 and "We'll meet again.") or
		(brain >= 0.52 and "Farewell, "..plyguy:GetPlayerName()..".") or
		(brain >= 0.52 and random3 and plyguy:GetPlayerName() == "Unrecognizable") or
		(brain >= 0.39 and "Well... This is where it ends.") or
		(brain >= 0.36 and "...") or
		(brain >= 0.3 and random2) or
		(brain >= 0.25 and "...") or
		(brain >= 0.15 and random1) or
		(brain >= 0.1 and "...") or
		(brain < 0.1 and critical and "You might as well kill bind.") or
		(brain < 0.1 and incapacitated and "Well I'm not sure about you surviving now.") or
		(brain < 0.1 and "You can still survive, at least for now.")

		local parsed = markup.Parse(
			"<font=HomigradFontMedium>"..
			( critical and "You're critically injured." or textOtrub )..
			"\n<colour=255,"..( critical and 25 or 255 )..","..( critical and 25 or 255 ) ..",255>"..
			( textOtrub2 ).."\n\n"..( textOtrub3 ).."</colour></font>"
		)

		parsed:Draw( ScrW()*0.009, ScrH()*0.9, TEXT_ALIGN_LEFT, nil, nil, TEXT_ALIGN_LEFT )
    end
end)

hook.Add("Player_Death", "randomizethestupidtextplease", function(ply)
	if ply == LocalPlayer() then
		timer.Simple(0.1, function()
			random1, random2, random3 = randomtextplease()
		end)
	end
end)