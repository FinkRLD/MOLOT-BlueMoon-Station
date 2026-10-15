// BLUEMOON ADD - Malf AI custom abilities: fake laws, fake ion storm, APC stealth
// Порт механики Paradise LawManager + стелс для сбойного ИИ.
// Подхватывается автоматически через typesof(/datum/AI_Module) в datum/module_picker.

#define MALF_APC_STEALTH_DURATION (300 SECONDS) // 5 минут стелса
#define MALF_FAKE_LAWS_MAX 20

// ---------- Silicon vars ----------
/mob/living/silicon
	var/list/fake_laws = list()
	var/fake_laws_enabled = FALSE

/mob/living/silicon/proc/is_malf_ai()
	if(!isAI(src))
		return FALSE
	var/mob/living/silicon/ai/A = src
	if(A.malf_picker)
		return TRUE
	if(mind && mind.has_antag_datum(/datum/antagonist/traitor))

		return TRUE
	return FALSE

/mob/living/silicon/proc/get_fake_laws_numbered()
	var/list/out = list()
	var/n = 1
	for(var/law in fake_laws)
		if(length(law))
			out += list(list("num" = n, "text" = law))
			n++
	return out

// ---------- APC stealth vars ----------
/obj/machinery/power/apc
	var/stealth_end_time = 0

/obj/machinery/power/apc/proc/is_stealthed()
	return stealth_end_time > world.time

/obj/machinery/power/apc/proc/activate_stealth(duration = MALF_APC_STEALTH_DURATION)
	stealth_end_time = world.time + duration
	update_appearance()
	if(malfai)
		to_chat(malfai, span_notice("[src] маскируется под исправный ([duration / 10] сек). Синий экран скрыт."))
	addtimer(CALLBACK(src, PROC_REF(stealth_expire)), duration + 5, TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_DELETE_ME)

/obj/machinery/power/apc/proc/stealth_expire()
	if(!is_stealthed())
		update_appearance() // важно: пересчитывает update_state, возвращает синий экран
		if(malfai)
			to_chat(malfai, span_warning("Маскировка [src] истекла. АПЦ снова синий."))

// ================= FAKE LAWS MODULE =================
/datum/AI_Module/small/malf_fake_laws
	module_name = "Фейковые законы"
	mod_pick_name = "fakelaws"
	description = "Позволяет писать свои фейковые законы в отдельной вкладке Менеджера Законов. Экипаж при запросе State Laws увидит фейки вместо настоящих. Реальные законы не меняются. Выбор какие законы озвучивать - через галочки."
	cost = 15
	one_purchase = TRUE
	power_type = /datum/action/innate/ai/malf_fake_laws
	unlock_text = "<span class='notice'>Модуль подмены законов загружен. Откройте Менеджер Законов - вкладка FAKE.</span>"
	unlock_sound = 'sound/machines/ping.ogg'

/datum/action/innate/ai/malf_fake_laws
	name = "Fake Laws"
	desc = "Писать/переключать фейковые законы. Экипаж увидит их вместо настоящих."
	icon_icon = 'icons/mob/actions.dmi'
	button_icon_state = "language_menu"
	auto_use_uses = FALSE

/datum/action/innate/ai/malf_fake_laws/New()
	..()
	desc = initial(desc)

/datum/action/innate/ai/malf_fake_laws/Activate()
	var/mob/living/silicon/ai/A = owner
	if(!istype(A))
		return
	var/choice = tgui_input_list(owner, "Фейковые законы: что сделать?", "Fake Laws", list("Добавить фейк-закон", "Удалить фейк-закон", "Вкл/Выкл подмену", "Показать фейки", "Открыть Менеджер Законов"))
	if(!choice)
		return
	switch(choice)
		if("Добавить фейк-закон")
			if(length(A.fake_laws) >= MALF_FAKE_LAWS_MAX)
				to_chat(A, span_warning("Максимум [MALF_FAKE_LAWS_MAX] фейковых законов."))
				return
			var/new_law = tgui_input_text(owner, "Введите фейковый закон для экипажа:", "Fake Law", max_length = 512, multiline = TRUE, encode = FALSE)
			if(!new_law)
				return
			A.fake_laws += new_law
			A.fake_laws_enabled = TRUE
			log_game("[key_name(owner)] MALF fake law added: [new_law]")
			to_chat(A, span_notice("Фейк-закон добавлен и подмена ВКЛЮЧЕНА. Экипаж увидит его через State Laws."))
			A.update_law_menu()
		if("Удалить фейк-закон")
			if(!length(A.fake_laws))
				to_chat(A, span_warning("Список пуст."))
				return
			var/sel = tgui_input_list(owner, "Какой удалить?", "Fake Laws", A.fake_laws)
			if(!sel)
				return
			A.fake_laws -= sel
			to_chat(A, span_notice("Удалено."))
			A.update_law_menu()
		if("Вкл/Выкл подмену")
			A.fake_laws_enabled = !A.fake_laws_enabled
			to_chat(A, span_notice("Подмена законов: [A.fake_laws_enabled ? "ВКЛ - экипаж видит фейки" : "ВЫКЛ - экипаж видит выбранные реальные законы"]."))
			A.update_law_menu()
		if("Показать фейки")
			if(!length(A.fake_laws))
				to_chat(A, span_warning("Фейков нет."))
				return
			var/dat = "<b>FAKE LAWS ([A.fake_laws_enabled ? "АКТИВНЫ" : "ВЫКЛ"]):</b><br>"
			var/n = 1
			for(var/l in A.fake_laws)
				dat += "[n]. [l]<br>"
				n++
			to_chat(A, dat)
		if("Открыть Менеджер Законов")
			A.checklaws()

// ================= FAKE ION STORM ANNOUNCE =================
/datum/AI_Module/small/malf_fake_ion_storm
	module_name = "Ложный ионный шторм"
	mod_pick_name = "fakeionstorm"
	description = "Делает лживый анонс о ионосферном/ионном шторме тем же текстом что настоящий ионный шторм. Законов никому не меняет. Для прикрытия подмены законов."
	cost = 10
	power_type = /datum/action/innate/ai/malf_fake_ion_storm
	unlock_text = "<span class='notice'>Поддельный анонс шторма готов.</span>"
	unlock_sound = 'sound/misc/notice1.ogg'

/datum/action/innate/ai/malf_fake_ion_storm
	name = "Fake Ion Storm"
	desc = "Ложное объявление о ионосферном шторме. Без смены законов."
	button_icon_state = "blackout"
	uses = 3
	auto_use_uses = FALSE

/datum/action/innate/ai/malf_fake_ion_storm/New()
	..()
	desc = "[desc] It has [uses] use\s remaining."

/datum/action/innate/ai/malf_fake_ion_storm/Activate()

	priority_announce("Вблизи станции обнаружен ионный шторм. Пожалуйста, проверьте все контролируемое ИИ оборудование на наличие ошибок.", "ВНИМАНИЕ: АНОМАЛИЯ", "ionstorm", type = "ionstorm", has_important_message = prob(80))
	log_game("[key_name(owner)] MALF fake ion storm announcement.")
	message_admins("[ADMIN_LOOKUPFLW(owner)] сделал ЛОЖНЫЙ анонс ионного шторма.")
	to_chat(owner, span_notice("Ложный анонс отправлен. Законов никому не меняло."))
	adjust_uses(-1)
	if(src && uses)
		desc = "[initial(desc)] It has [uses] use\s remaining."
		UpdateButtons()

// ================= APC STEALTH =================
/datum/AI_Module/small/malf_apc_stealth
	module_name = "Маскировка АПЦ"
	mod_pick_name = "apcstealth"
	description = "На время меняет спрайт взломанных АПЦ с синего (apcemag) на обычный зелёный. Для стелса. Действует на уже взломанные и на все взломы в ближайшие 5 минут (300 сек)."
	cost = 15
	power_type = /datum/action/innate/ai/malf_apc_stealth
	unlock_text = "<span class='notice'>Маскировочный протокол АПЦ загружен.</span>"
	unlock_sound = 'sound/machines/ping.ogg'

/datum/action/innate/ai/malf_apc_stealth
	name = "APC Camouflage"
	desc = "Скрыть синий экран взломанных АПЦ на 5 минут + автомаскировка будущих взломов. Обычный спрайт + скрытие в examine."
	icon_icon = 'icons/mob/actions/actions.dmi'
	button_icon_state = "null_charge"
	uses = 3
	auto_use_uses = FALSE
	cooldown_period = 100

/datum/action/innate/ai/malf_apc_stealth/New()
	..()
	desc = "[desc] It has [uses] use\s remaining."

/datum/action/innate/ai/malf_apc_stealth/Activate()
	var/mob/living/silicon/ai/A = owner
	if(!istype(A))
		return
	var/mob/living/silicon/ai/base = A.parent || A
	// Окно на 5 минут: будущие взломы тоже автоматически маскируются (см. malfhacked)
	base.apc_camouflage_until = world.time + MALF_APC_STEALTH_DURATION
	var/count = 0
	for(var/obj/machinery/power/apc/P in GLOB.apcs_list)
		if(P.malfai == A || P.malfai == base || P.malfhack)
			P.activate_stealth(MALF_APC_STEALTH_DURATION)
			count++
	to_chat(A, span_notice("Камуфляж включён на [MALF_APC_STEALTH_DURATION / 10] сек. Уже замаскировано АПЦ: [count]. Новые взломы в этом окне тоже будут скрыты."))
	log_game("[key_name(A)] MALF APC stealth on [count] APCs + window [MALF_APC_STEALTH_DURATION / 10]s.")
	adjust_uses(-1)
	if(src && uses)
		desc = "[initial(desc)] It has [uses] use\s remaining."
		UpdateButtons()

#undef MALF_APC_STEALTH_DURATION
#undef MALF_FAKE_LAWS_MAX

