extends Control
## Écran titre : présentation de la démo et lancement d'une partie.

const GAME_SCENE := "res://Scenes/UI/Game.tscn"


func _ready() -> void:
	theme = TerminalTheme.build()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = TerminalTheme.BACKGROUND
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(720, 0)
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)

	var title := Label.new()
	title.text = "SOL, NOUVELLE ÈRE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", TerminalTheme.AMBER_BRIGHT)
	box.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "L'IMPASSE DE L'HABITAT THULÉ-7"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 22)
	box.add_child(subtitle)
	box.add_child(HSeparator.new())
	var pitch := Label.new()
	pitch.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pitch.add_theme_color_override("font_color", TerminalTheme.AMBER_DIM)
	pitch.text = "2187. Ceinture d'astéroïdes. Vous êtes Ezra Tal, sauveteur du vide de la Mutuelle. " \
		+ "L'habitat minier Thulé-7 ne répond plus depuis dix-neuf jours. Dans le sas principal, le support vital lâche, " \
		+ "et trois survivants se tiennent en joue autour d'un conteneur cryogénique.\n\n" \
		+ "Parlez, réparez ou combattez : vous avez quinze minutes."
	box.add_child(pitch)
	box.add_child(HSeparator.new())

	var start := Button.new()
	start.text = "Nouvelle partie"
	start.pressed.connect(func() -> void: get_tree().change_scene_to_file(GAME_SCENE))
	box.add_child(start)
	var quit := Button.new()
	quit.text = "Quitter"
	quit.pressed.connect(func() -> void: get_tree().quit())
	box.add_child(quit)
	var version := Label.new()
	version.text = "Démo technique · Godot 4.7.2 · règles D100 (Livre de règles v0.2)"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.add_theme_font_size_override("font_size", 13)
	version.add_theme_color_override("font_color", TerminalTheme.AMBER_DIM)
	box.add_child(version)
	start.grab_focus()
