/obj/item/summon_chalk
	name = "qareen enchanted chalk"
	desc = "A weird chalk covered in ectoplasm."
	icon = 'modular_bluemoon/Gardelin0/icons/items/qareen_chalk.dmi'
	icon_state = "chalk_pink"
	throw_speed = 3
	throw_range = 5
	w_class = WEIGHT_CLASS_TINY

/obj/item/summon_chalk/afterattack(atom/target, mob/user as mob, proximity)
	if(!proximity)
		return
	if(istype(target, /turf/open/floor))
		if(do_after(user, 5))
			new /obj/effect/summon_rune(target)


/obj/effect/summon_rune
	name = "Lewd summon rune"
	desc = "It is believed this rune is capable of summoning horny creatures!"
	icon = 'modular_bluemoon/Gardelin0/icons/items/qareen_chalk.dmi'
	icon_state = "rune_pink"
	light_color = LIGHT_COLOR_PINK
	var/return_pos

/obj/effect/summon_rune/Initialize(mapload)
	. = ..()
	set_light(2)

/obj/effect/summon_rune/attack_hand(mob/living/carbon/M)
	var/list/applicants = list()
	var/static/list/applicants_result = list()
	for(var/mob/living/carbon/human/H in GLOB.carbon_list)
		if(HAS_TRAIT(H, TRAIT_LEWD_SUMMON))
			applicants += H
	for(var/mob/living/carbon/human/V in applicants)
		var/mob/living/carbon/human/A = V
		//var/atom/A = V
		var/player_info = "[A.dna.species.name], [A.gender]"
		applicants_result[initial(player_info)] = A

	var/choice = tgui_alert(usr, "Do you want to attempt to summon?", "Attempt to summon?", list("Yes", "No"))
	switch(choice)
		if("No")
			return
		if("Yes")
			var/target_info = input("Please, select a person to summon!", "Select", null, null) as null|anything in applicants_result
			var/target_id= applicants.Find(target_info)+1
			var/mob/living/carbon/human/target = applicants[target_id]
			if(isnull(target))
				to_chat(M, span_userdanger("Nobody to summon!"))
				return
			else

				var/applicant_choice = tgui_alert(target, "You have been summoned! Do you want to answer?", "Do you want to answer?", list("Yes", "No"))
				switch(applicant_choice)
					if("No")
						to_chat(M, span_userdanger("It refuses to answer!"))
					if("Yes")

						to_chat(M, span_lewd("Something is happening!"))
						var/old_pos = target.loc
						do_teleport(target, src.loc, channel = TELEPORT_CHANNEL_MAGIC)
						//target.forceMove(src.loc)
						to_chat(target, span_hypnophrase("You are turning on!"))
						ADD_TRAIT(target, TRAIT_LEWD_SUMMONED, src)
						playsound(loc, "modular_bluemoon/Gardelin0/sound/effect/spook.ogg", 50, 1)
						var/obj/effect/summon_rune/return_rune/R = new(src.loc)
						R.return_pos = old_pos
						qdel(src)
/*
/obj/effect/summon_rune/proc/generate_display_names()
	var/list/applicants = list()
	var/static/list/applicants_result = list()
	for(var/mob/living/carbon/human/H in GLOB.carbon_list)
		if(HAS_TRAIT(H, TRAIT_LEWD_SUMMON))
			applicants += H
	for(var/mob/living/carbon/human/V in applicants)
		var/mob/living/carbon/human/A = V
		//var/atom/A = V
		var/player_info = "[A.dna.species.name], [A.gender]"
		applicants_result[initial(player_info)] = A
	return applicants_result
*/

/obj/effect/summon_rune/return_rune/attack_hand(mob/living/carbon/M)

	if(HAS_TRAIT(M, TRAIT_LEWD_SUMMONED))
		REMOVE_TRAIT(M, TRAIT_LEWD_SUMMONED, src)
		do_teleport(M, return_pos, channel = TELEPORT_CHANNEL_MAGIC)
		qdel(src)
