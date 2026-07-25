local hg_unconscioustimer = CreateClientConVar("hg_unconscioustimer", "1", true, false, "Displays a timer till you're conscious while unconscious! (if you really dislike it that much because of realism you can disable it)")

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
        --render.PushFilterMag( TEXFILTER.ANISOTROPIC )
		--render.PushFilterMin( TEXFILTER.ANISOTROPIC )

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
		(brain >= 0.385 and "Unfortunately for you this is where it ends.") or
		(brain >= 0.34 and "...") or
		(brain >= 0.3 and "...I'll survive this right?") or
		(brain >= 0.25 and "...") or
		(brain >= 0.15 and "...Is anyone there?") or
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

		--surface.SetTextColor(255,255,255,255)
		--surface.SetFont("HomigradFontMedium")
		--local txtSizeX, txtSizeY = surface.GetTextSize(textOtrub)
		--surface.SetTextPos(ScrW()/2 - (txtSizeX/2),ScrH()/1.1 - (txtSizeY/2))
		--surface.DrawText(textOtrub)

		parsed:Draw( ScrW()/2, ScrH()/2.2, TEXT_ALIGN_CENTER, nil, nil, TEXT_ALIGN_CENTER )

		--render.PopFilterMag()
		--render.PopFilterMin()
    end
end)