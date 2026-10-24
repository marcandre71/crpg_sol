class_name TerminalTheme
extends RefCounted
## Thème rétro-futuriste : texte ambre sur fond noir, police à chasse fixe.

const BACKGROUND := Color("0b0a07")
const PANEL := Color("14110a")
const AMBER := Color("ffb000")
const AMBER_DIM := Color("a8740a")
const AMBER_BRIGHT := Color("ffd27a")
const SUCCESS := Color("8fe36b")
const FAILURE := Color("ff6a4a")
const FONT_SIZE := 17

static var _theme: Theme


static func font() -> SystemFont:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Consolas", "DejaVu Sans Mono", "Liberation Mono", "Courier New", "monospace"])
	return f


static func hex(c: Color) -> String:
	return "#" + c.to_html(false)


static func _box(bg: Color, border: Color, width: int = 1) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	return sb


static func build() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font = font()
	t.default_font_size = FONT_SIZE
	for type in ["Label", "Button", "RichTextLabel"]:
		t.set_color("font_color", type, AMBER)
	t.set_color("default_color", "RichTextLabel", AMBER)
	t.set_color("font_hover_color", "Button", BACKGROUND)
	t.set_color("font_pressed_color", "Button", BACKGROUND)
	t.set_color("font_focus_color", "Button", AMBER_BRIGHT)
	t.set_color("font_disabled_color", "Button", AMBER_DIM)
	t.set_stylebox("normal", "Button", _box(BACKGROUND, AMBER_DIM))
	t.set_stylebox("hover", "Button", _box(AMBER, AMBER))
	t.set_stylebox("pressed", "Button", _box(AMBER_BRIGHT, AMBER_BRIGHT))
	t.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), AMBER_BRIGHT, 2))
	t.set_stylebox("disabled", "Button", _box(BACKGROUND, Color("3a2a08")))
	t.set_stylebox("panel", "PanelContainer", _box(PANEL, AMBER_DIM))
	t.set_color("color", "HSeparator", AMBER_DIM)
	_theme = t
	return t
