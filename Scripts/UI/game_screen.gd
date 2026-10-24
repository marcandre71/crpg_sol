extends Control
## Écran de jeu de la démo « L'Impasse de l'Habitat Thulé-7 » : journal façon terminal,
## choix numérotés (touches 1 à 9), fiche du personnage et compte à rebours du support vital.
## Trois modes : dialogue, réparation (test prolongé) et combat ; une fin arrête tout.

const DIALOGUE_ID := "thule7_sas"
const PLAYER_ID := "ezra_tal"
const NPC_IDS: Array[String] = ["lina", "kael", "voronov"]
const HELP := "Touches 1 à 9 : choisir · Les pourcentages sont les chances de réussite (score modifié)."
const REPAIR_SUIT_PENALTY := -10
const REPAIR_TASKS := [
	{"skill": "systemes_de_survie", "difficulty": "delicate", "label": "Purger les filtres saturés"},
	{"skill": "mecanique", "difficulty": "difficile", "label": "Relancer la pompe du recycleur"},
	{"skill": "electronique", "difficulty": "difficile", "label": "Recalibrer la régulation"},
]

enum Mode { DIALOGUE, REPAIR, COMBAT, ENDING }

var mode := Mode.DIALOGUE
var player: CharacterData
var runner: DialogueRunner
var clock: LifeSupportClock
var dialogue: Dictionary

var repair: RulesEngine.ExtendedTest
var repair_then: Dictionary = {}
var combat: CombatEngine
var combat_then: Dictionary = {}
var _ai_running := false
## Pause entre deux tours de PNJ, pour suivre le combat (0 dans les tests).
var ai_delay := 0.7

var _log: RichTextLabel
var _choices: VBoxContainer
var _sheet: RichTextLabel
var _clock_label: Label
var _status_label: Label


func _ready() -> void:
	theme = TerminalTheme.build()
	_build_ui()
	_new_game()


# --- Construction de l'interface -------------------------------------------------

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = TerminalTheme.BACKGROUND
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	var title := Label.new()
	title.text = "SOL, NOUVELLE ÈRE · THULÉ-7 · SAS PRINCIPAL"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_clock_label = Label.new()
	header.add_child(_clock_label)
	root.add_child(HSeparator.new())

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	root.add_child(body)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 2.2
	body.add_child(left)
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.selection_enabled = true
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(_log)
	left.add_child(HSeparator.new())
	var choice_scroll := ScrollContainer.new()
	choice_scroll.custom_minimum_size = Vector2(0, 230)
	choice_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(choice_scroll)
	_choices = VBoxContainer.new()
	_choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_scroll.add_child(_choices)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(panel)
	_sheet = RichTextLabel.new()
	_sheet.bbcode_enabled = true
	_sheet.add_theme_font_size_override("normal_font_size", 14)
	_sheet.add_theme_font_size_override("bold_font_size", 14)
	panel.add_child(_sheet)

	_status_label = Label.new()
	_status_label.add_theme_color_override("font_color", TerminalTheme.AMBER_DIM)
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.text = HELP
	root.add_child(_status_label)


# --- Partie ------------------------------------------------------------------------

func _new_game() -> void:
	GameState.reset()
	_log.clear()
	combat = null
	repair = null
	_status_label.text = HELP
	player = DataDB.get_character(PLAYER_ID)
	GameState.add_character(player)
	for id in NPC_IDS:
		GameState.add_character(DataDB.get_character(id))
	dialogue = DataDB.get_dialogue(DIALOGUE_ID)
	clock = LifeSupportClock.new(int(dialogue.get("lifeSupportSeconds", 900)))
	clock.ticked.connect(_on_clock_ticked)
	clock.warning.connect(_on_clock_warning)
	clock.expired.connect(_on_clock_expired)
	runner = DialogueRunner.new(dialogue, GameState.flags, _dialogue_test)
	runner.node_entered.connect(_on_node_entered)
	runner.effect_requested.connect(_on_effect)
	mode = Mode.DIALOGUE
	_on_clock_ticked(clock.seconds_left)
	runner.start()
	_refresh()


func _speaker_name(id: String) -> String:
	return dialogue.get("speakers", {}).get(id, id.capitalize())


static func esc(text: String) -> String:
	return text.replace("[", "[lb]")


func _say(text: String, color: Color = TerminalTheme.AMBER) -> void:
	_log.append_text("[color=%s]%s[/color]\n" % [TerminalTheme.hex(color), esc(text)])


func _say_result(label: String, result: Dictionary) -> void:
	var ok: bool = result["success"]
	var verdict := "RÉUSSITE" if ok else "ÉCHEC"
	if result["critical"]:
		verdict += " CRITIQUE"
	var degrees := "%d %s" % [result["degrees"], "DR" if ok else "DE"]
	var text := "  ┌ %s : %d %% · dé %02d → %s, %s" % [label, result["target"], result["roll"] % 100, verdict, degrees]
	if result.get("complication", false) and not ok:
		text += " · complication"
	_say(text, TerminalTheme.SUCCESS if ok else TerminalTheme.FAILURE)


func _on_node_entered(_id: String) -> void:
	var n := runner.node()
	_log.append_text("\n")
	var speaker: String = _speaker_name(n.get("speaker", ""))
	if speaker != "":
		_log.append_text("[color=%s][b]%s[/b][/color]\n" % [TerminalTheme.hex(TerminalTheme.AMBER_BRIGHT), esc(speaker.to_upper())])
	_say(n.get("text", ""))
	if n.has("ending"):
		_show_ending(n["ending"])


# --- Tests de compétence du dialogue ------------------------------------------------

func _skill_label(key: String) -> String:
	return DataDB.get_skill(key).get("name", key)


func _skill_mods(ch: CharacterData, key: String, extra: Array) -> Array[int]:
	var mods: Array[int] = []
	for m in extra:
		mods.append(int(m))
	mods.append_array(ch.condition_modifiers(DataDB.get_skill(key).get("domain", "")))
	return mods


## Chance affichée : score modifié, borné à 0-100 ; -1 si la compétence est impossible.
func _chance(ch: CharacterData, key: String, difficulty: String, extra: Array = []) -> int:
	var score := ch.skill_score(DataDB.get_skill(key))
	if score == RulesEngine.IMPOSSIBLE:
		return -1
	return clampi(RulesEngine.modified_target(score, difficulty, _skill_mods(ch, key, extra)), 0, 100)


func _check_tag(check: Dictionary) -> String:
	var key: String = check["skill"]
	var chance := _chance(player, key, check.get("difficulty", "normale"), check.get("modifiers", []))
	var tag := "%s %d %%" % [_skill_label(key), chance] if chance >= 0 else "%s impossible" % _skill_label(key)
	var opp: Dictionary = check.get("opposedBy", {})
	if not opp.is_empty():
		var npc := GameState.get_character(opp["npc"])
		tag += " contre %s %d %%" % [npc.name, _chance(npc, opp["skill"], "normale")]
	return "[%s] " % tag


## Testeur du DialogueRunner : test simple ou opposé ; success = le joueur l'emporte.
func _dialogue_test(check: Dictionary) -> Dictionary:
	var key: String = check["skill"]
	var difficulty: String = check.get("difficulty", "normale")
	var score := player.skill_score(DataDB.get_skill(key))
	if score == RulesEngine.IMPOSSIBLE:
		_say("  ┌ %s : impossible sans formation." % _skill_label(key), TerminalTheme.FAILURE)
		return {}
	var result := Rules.test(score, difficulty, _skill_mods(player, key, check.get("modifiers", [])))
	_say_result(_skill_label(key), result)
	var opp: Dictionary = check.get("opposedBy", {})
	if not opp.is_empty():
		var npc := GameState.get_character(opp["npc"])
		var npc_score := npc.skill_score(DataDB.get_skill(opp["skill"]))
		var npc_result := Rules.test(npc_score, "normale", _skill_mods(npc, opp["skill"], []))
		_say_result("%s (%s)" % [_skill_label(opp["skill"]), npc.name], npc_result)
		var opposed := RulesEngine.opposed(result, npc_result)
		var won: bool = opposed["winner"] == "a"
		_say("  └ Test opposé : %s." % ("vous l'emportez" if won else "%s l'emporte" % npc.name),
			TerminalTheme.SUCCESS if won else TerminalTheme.FAILURE)
		var critical: bool = result["critical"] and result["success"] == won
		result = result.duplicate()
		result["success"] = won
		result["degrees"] = opposed["margin"]
		result["critical"] = critical
	EventBus.skill_check_resolved.emit(player.id, key, result)
	return result


func _on_effect(effect: Dictionary) -> void:
	if effect.has("timeCost"):
		clock.advance(int(effect["timeCost"]))
	elif effect.has("loseSangFroid"):
		player.lose_sang_froid(int(effect["loseSangFroid"]))
		_say("  (−%d Sang-froid)" % effect["loseSangFroid"], TerminalTheme.FAILURE)
	elif effect.has("repairLifeSupport"):
		clock.stop()
		_on_clock_ticked(clock.seconds_left)
	elif effect.has("startRepair"):
		_start_repair(effect["startRepair"])
	elif effect.has("startCombat"):
		_start_combat(effect["startCombat"])


# --- Horloge du support vital ------------------------------------------------------

func _on_clock_ticked(seconds: int) -> void:
	if clock.stopped:
		_clock_label.text = "SUPPORT VITAL : NOMINAL"
		_clock_label.add_theme_color_override("font_color", TerminalTheme.SUCCESS)
		return
	_clock_label.text = "SUPPORT VITAL %s" % LifeSupportClock.format(seconds)
	_clock_label.add_theme_color_override("font_color", TerminalTheme.FAILURE if seconds <= 120 else TerminalTheme.AMBER)


func _on_clock_warning(seconds: int) -> void:
	_say("  ⚠ Greffier : autonomie du recycleur %s." % LifeSupportClock.format(seconds), TerminalTheme.FAILURE)


func _on_clock_expired() -> void:
	if mode == Mode.ENDING:
		return
	mode = Mode.DIALOGUE
	combat = null
	runner.goto("fin_silence")
	_refresh()


# --- Choix et rafraîchissement --------------------------------------------------------

func _refresh() -> void:
	for child in _choices.get_children():
		_choices.remove_child(child)
		child.queue_free()
	match mode:
		Mode.DIALOGUE:
			_dialogue_buttons()
		Mode.REPAIR:
			_repair_buttons()
		Mode.COMBAT:
			_combat_buttons()
		Mode.ENDING:
			_add_button("Recommencer", _new_game)
			_add_button("Retour à l'écran titre", func() -> void: get_tree().change_scene_to_file("res://Scenes/Main.tscn"))
	_render_sheet()


func _add_button(text: String, callback: Callable, enabled: bool = true) -> void:
	var b := Button.new()
	var n := _choices.get_child_count() + 1
	b.text = ("%d. %s" % [n, text]) if n <= 9 else text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.disabled = not enabled
	b.pressed.connect(callback)
	_choices.add_child(b)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key: int = event.physical_keycode
		var i := key - KEY_1 if key >= KEY_1 and key <= KEY_9 else key - KEY_KP_1
		var buttons := _choices.get_children()
		if i >= 0 and i < mini(9, buttons.size()) and not buttons[i].disabled:
			buttons[i].pressed.emit()
			get_viewport().set_input_as_handled()


func _dialogue_buttons() -> void:
	if runner.is_ending():
		return
	var options := runner.choices()
	if options.is_empty():
		if runner.node().has("next"):
			_add_button("[Continuer]", func() -> void:
				runner.advance()
				_after_dialogue_step())
		return
	for o in options:
		var choice: Dictionary = o["choice"]
		var label: String = choice["text"]
		if choice.has("skillCheck"):
			label = _check_tag(choice["skillCheck"]) + label
		var index: int = o["index"]
		_add_button(label, func() -> void: _choose(index, label))


func _choose(index: int, label: String) -> void:
	_log.append_text("\n")
	_say("> " + label, TerminalTheme.AMBER_DIM)
	runner.choose(index)
	_after_dialogue_step()


func _after_dialogue_step() -> void:
	if mode == Mode.DIALOGUE and runner.is_ending():
		mode = Mode.ENDING
	_refresh()


func _show_ending(ending: Dictionary) -> void:
	mode = Mode.ENDING
	clock.stop()
	_log.append_text("\n[color=%s][b]═══ FIN : %s ═══[/b][/color]\n" % [TerminalTheme.hex(TerminalTheme.AMBER_BRIGHT), esc(str(ending.get("title", "")).to_upper())])


# --- Réparation : test prolongé --------------------------------------------------------

func _repair_mods() -> Array[int]:
	var mods: Array[int] = [REPAIR_SUIT_PENALTY]
	if player.gear_count("kit_outils") > 0:
		mods.append(DataDB.get_item("kit_outils").get("toolBonus", 10))
	if GameState.has_flag("lina_soignee"):
		mods.append(10)
	return mods


func _start_repair(def: Dictionary) -> void:
	mode = Mode.REPAIR
	repair_then = def["then"]
	repair = RulesEngine.ExtendedTest.new(int(def["goal"]), int(def["interval"]))
	var helpers := "kit d'outils +10, gants de combinaison −10"
	if GameState.has_flag("lina_soignee"):
		helpers += ", aide de Lina +10"
	_say("  Test prolongé : %d DR à réunir, %d s par tentative (%s)." % [repair.goal, repair.interval_seconds, helpers], TerminalTheme.AMBER_DIM)
	_refresh()


func _repair_buttons() -> void:
	var filled := mini(repair.progress, repair.goal)
	for task: Dictionary in REPAIR_TASKS:
		var chance := _chance(player, task["skill"], task["difficulty"], _repair_mods())
		var label := "[%s %d %%] %s (%d s)" % [_skill_label(task["skill"]), chance, task["label"], repair.interval_seconds]
		_add_button(label, func() -> void: _repair_attempt(task))
	_add_button("Laisser le panneau et revenir au centre du sas", func() -> void:
		mode = Mode.DIALOGUE
		_status_label.text = HELP
		runner.goto(repair_then["abort"])
		_refresh())
	_status_label.text = "Recycleur : [%s%s] %d / %d DR" % ["█".repeat(filled), "░".repeat(repair.goal - filled), repair.progress, repair.goal]


func _repair_attempt(task: Dictionary) -> void:
	_log.append_text("\n")
	_say("> %s" % task["label"], TerminalTheme.AMBER_DIM)
	var key: String = task["skill"]
	var result := Rules.test(player.skill_score(DataDB.get_skill(key)), task["difficulty"], _skill_mods(player, key, _repair_mods()))
	_say_result(_skill_label(key), result)
	repair.add(result)
	if result["success"]:
		_say("  Progression : %d / %d DR." % [repair.progress, repair.goal])
	elif result["complication"]:
		_say("  Une gerbe d'étincelles, une odeur de brûlé dans la radio. Le cœur vous cogne dans les tempes. (−1 Sang-froid, +30 s)", TerminalTheme.FAILURE)
		player.lose_sang_froid(1)
		clock.advance(30)
	else:
		_say("  Rien ne bouge. La mousse grise colle à tout.")
	clock.advance(repair.interval_seconds)
	if mode != Mode.REPAIR:
		return
	if repair.is_complete():
		mode = Mode.DIALOGUE
		_status_label.text = HELP
		runner.goto(repair_then["done"])
	_refresh()


# --- Combat ------------------------------------------------------------------------------

func _start_combat(def: Dictionary) -> void:
	mode = Mode.COMBAT
	combat_then = def["then"]
	combat = CombatEngine.new(DataDB.skills, Rules.rng)
	combat.logged.connect(func(text: String) -> void: _say("  " + text, TerminalTheme.AMBER_BRIGHT if text.begins_with("—") else TerminalTheme.AMBER))
	combat.round_started.connect(func(n: int) -> void:
		if n > 1:
			clock.advance(CombatEngine.ROUND_SECONDS))
	_add_combatant(player, "player")
	for id: String in def.get("allies", []):
		_add_combatant(GameState.get_character(id), "ally")
	for id: String in def.get("enemies", []):
		_add_combatant(GameState.get_character(id), "enemy")
	_say("  Combat : chaque tour dure 5 s. Une action, un mouvement ; l'esquive est automatique (réaction).", TerminalTheme.AMBER_DIM)
	combat.start()
	_continue_combat()


func _add_combatant(ch: CharacterData, side: String) -> void:
	var weapon := DataDB.get_item(ch.weapons[0]) if not ch.weapons.is_empty() else {}
	combat.add(ch, side, weapon, DataDB.get_item(ch.armor))


## Fait jouer les PNJ jusqu'au tour du joueur ou jusqu'à la fin du combat.
func _continue_combat() -> void:
	if _ai_running:
		return
	_ai_running = true
	while combat != null and combat.outcome == "" and combat.current().side != "player":
		_refresh()
		await get_tree().create_timer(ai_delay).timeout
		if combat == null or mode != Mode.COMBAT:
			_ai_running = false
			return
		combat.run_ai_turn(combat.current())
	_ai_running = false
	if combat == null or mode != Mode.COMBAT:
		return
	if combat.outcome != "":
		_end_combat()
		return
	combat.begin_turn_constraints(combat.current())
	_refresh()


func _end_combat() -> void:
	var outcome := combat.outcome
	var labels := {"victory": "Victoire", "defeat": "Défaite", "ceasefire": "Cessez-le-feu"}
	_say("  ═ Fin du combat : %s ═" % labels.get(outcome, outcome), TerminalTheme.AMBER_BRIGHT)
	combat = null
	mode = Mode.DIALOGUE
	runner.goto(combat_then[outcome])
	_after_dialogue_step()


func _player_acted() -> void:
	if combat.outcome != "":
		_end_combat()
		return
	var c := combat.current()
	if c.action_used and (c.move_used or not combat.can_move(c)):
		combat.end_turn()
		_continue_combat()
		return
	_refresh()


func _combat_buttons() -> void:
	if combat == null or combat.current() == null or combat.current().side != "player":
		_add_button("…", func() -> void: pass, false)
		return
	var me := combat.current()
	for target in combat.opponents_of(me):
		if combat.can_attack(me):
			var t := target
			_add_button("Tirer sur %s · %d %%" % [t.display_name(), combat.attack_chance(me, t)], func() -> void:
				combat.attack(me, t)
				_player_acted())
			_add_button("Tir visé au torse de %s · %d %%" % [t.display_name(), combat.attack_chance(me, t, "torso")], func() -> void:
				combat.attack(me, t, "torso")
				_player_acted())
			_add_button("Tir visé à la visière de %s · %d %%" % [t.display_name(), combat.attack_chance(me, t, "visor")], func() -> void:
				combat.attack(me, t, "visor")
				_player_acted())
	if me.spinning and not me.action_used:
		_add_button("Se stabiliser (action)", func() -> void:
			combat.stabilize(me)
			_player_acted())
	if combat.can_aim(me):
		_add_button("Viser (+10, jusqu'à +30 ; actuel +%d)" % me.aim, func() -> void:
			combat.aim(me)
			_player_acted())
	if combat.can_reload(me):
		_add_button("Recharger (%d / %d)" % [me.ammo, me.weapon.get("ammo", 0)], func() -> void:
			combat.reload(me)
			_player_acted())
	if combat.can_move(me) and me.character.position != Conditions.ANCHORED:
		_add_button("S'ancrer à une poignée (mouvement)", func() -> void:
			combat.anchor(me)
			_player_acted())
	if combat.can_move(me) and me.cover == 0:
		_add_button("Se mettre à couvert (mouvement, −20 pour vous toucher)", func() -> void:
			combat.take_cover(me)
			_player_acted())
	if combat.can_patch(me):
		_add_button("Poser une rustine sur la combinaison · Survie %d %%" % _chance(player, "survie", "normale"), func() -> void:
			combat.patch(me)
			_player_acted())
	if combat.can_first_aid(me):
		_add_button("Arrêter son saignement · Premiers secours %d %%" % _chance(player, "premiers_secours", "normale"), func() -> void:
			combat.first_aid(me)
			_player_acted())
	if combat.can_call_ceasefire(me):
		var mods := combat.ceasefire_modifiers(me)
		_add_button("Ordonner le cessez-le-feu · Commandement %d %%" % _chance(player, "commandement", "difficile", mods), func() -> void:
			combat.call_ceasefire(me)
			_player_acted())
	_add_button("Finir le tour", func() -> void:
		combat.end_turn()
		_continue_combat())


# --- Fiche ---------------------------------------------------------------------------------

func _bar(value: int, maximum: int) -> String:
	return "%s%s %d/%d" % ["■".repeat(value), "·".repeat(maxi(0, maximum - value)), value, maximum]


func _conditions_text(ch: CharacterData) -> String:
	var names: Array[String] = [Conditions.NAMES.get(ch.position, ch.position)]
	for c in ch.conditions:
		names.append(Conditions.NAMES.get(c, c))
	if ch.hypoxia > 0:
		names.append("Hypoxie %d" % ch.hypoxia)
	return ", ".join(names)


func _injuries_text(ch: CharacterData) -> String:
	if ch.injuries.is_empty():
		return "aucune"
	var parts: Array[String] = []
	for i in ch.injuries:
		parts.append("%s (%s)" % [CombatEngine.ZONE_NAMES.get(i["location"], i["location"]), CombatEngine.SEVERITY_NAMES.get(i["severity"], i["severity"])])
	return ", ".join(parts)


func _render_sheet() -> void:
	var dim := TerminalTheme.hex(TerminalTheme.AMBER_DIM)
	var bright := TerminalTheme.hex(TerminalTheme.AMBER_BRIGHT)
	var t := "[color=%s][b]%s[/b][/color]\nSauveteur du vide · Mutuelle\n" % [bright, player.name.to_upper()]
	t += "[color=%s]FOR %d CON %d COO %d RÉF %d ADA %d\nPER %d INT %d VOL %d PRÉ %d[/color]\n\n" % [dim,
		player.characteristic("for"), player.characteristic("con"), player.characteristic("coo"), player.characteristic("ref"),
		player.characteristic("ada"), player.characteristic("per"), player.characteristic("int"), player.characteristic("vol"), player.characteristic("pre")]
	t += "Endurance  %s\nSang-froid %s\nSeuil de blessure %d\n" % [_bar(player.endurance, player.endurance_max()), _bar(player.sang_froid, player.sang_froid_max()), player.wound_threshold()]
	t += "États : %s\nBlessures : %s\n" % [esc(_conditions_text(player)), esc(_injuries_text(player))]
	t += "Rustines : %d\n\n" % player.gear_count("rustine")
	if combat != null:
		t += "[color=%s]COMBAT · TOUR %d[/color]\n" % [bright, combat.round_number]
		for c in combat.order:
			var marker := "▶ " if c == combat.current() else "  "
			var state := "hors de combat" if c.is_out() else ("à couvert" if c.cover != 0 else "à découvert")
			var arm: String = "désarmé" if c.disarmed else "%s %d/%d" % [c.weapon.get("name", "sans arme"), c.ammo, c.weapon.get("ammo", 0)]
			t += "%s[b]%s[/b] · %s\n    End. %d/%d · %s\n    %s\n    Blessures : %s\n" % [marker, c.display_name(), state,
				c.character.endurance, c.character.endurance_max(), esc(_conditions_text(c.character)), arm, esc(_injuries_text(c.character))]
		_sheet.text = t
		return
	t += "[color=%s]COMPÉTENCES[/color]\n" % bright
	for key in ["persuasion", "negociation", "commandement", "psychologie", "intimidation", "premiers_secours", "systemes_de_survie", "mecanique", "electronique", "fouille", "armes_de_poing", "esquive", "manoeuvre_apesanteur"]:
		t += "%-24s %3d\n" % [_skill_label(key), player.skill_score(DataDB.get_skill(key))]
	t += "\n[color=%s]PRÉSENTS[/color]\n" % bright
	for id in NPC_IDS:
		var ch := GameState.get_character(id)
		var attitude := _attitude(id)
		t += "[b]%s[/b] · %s\n  End. %d/%d · %s\n  Blessures : %s\n" % [ch.name, attitude, ch.endurance, ch.endurance_max(), esc(_conditions_text(ch)), esc(_injuries_text(ch))]
	_sheet.text = t


func _attitude(id: String) -> String:
	match id:
		"lina":
			return "soignée" if GameState.has_flag("lina_soignee") else "blessée"
		"kael":
			return "arme baissée" if GameState.has_flag("kael_calme") else "vous tient en joue"
		"voronov":
			if GameState.has_flag("voronov_hors_combat"):
				return "hors de combat"
			return "arme baissée" if GameState.has_flag("voronov_calme") else "vous tient en joue"
	return ""
