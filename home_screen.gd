extends Control
var game
func build(g):
	game=g
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade=ColorRect.new()
	shade.color=Color(.015,.012,.014,.28)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var column=VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	column.position=Vector2(80,-270)
	column.size=Vector2(400,540)
	column.add_theme_constant_override("separation",16)
	add_child(column)
	var title=Label.new()
	title.text="WAITING\nFOR DAWN"
	title.add_theme_font_size_override("font_size",58)
	title.add_theme_color_override("font_color",Color(.84,.81,.70))
	var serif=SystemFont.new();serif.font_names=PackedStringArray(["Georgia","Noto Serif","serif"])
	title.add_theme_font_override("font",serif)
	column.add_child(title)
	var tagline=Label.new();tagline.text="SHE HEARS WHAT THE HOUSE REMEMBERS."
	tagline.add_theme_font_size_override("font_size",14)
	tagline.modulate=Color(.56,.56,.51)
	column.add_child(tagline)
	var gap=Control.new();gap.custom_minimum_size.y=12;column.add_child(gap)
	button(column,"Play",func(): play.call_deferred())
	button(column,"Join with friends",func(): hide();game.menu.show())
	button(column,"Exit",func():game._quit())
	var options=HBoxContainer.new();column.add_child(options)
	var label=Label.new();label.text="Difficulty   ";options.add_child(label)
	var picker=OptionButton.new()
	for level in game.DIFFICULTIES:picker.add_item(level.name)
	picker.select(game.difficulty);picker.item_selected.connect(game._set_difficulty)
	options.add_child(picker)
	var settings=Button.new();settings.text="Settings & credits";settings.flat=true
	settings.pressed.connect(func():hide();game.menu.show())
	column.add_child(settings)
	var version=Label.new();version.text="v"+game.VERSION+"   •   Headphones recommended"
	version.position=Vector2(80,0);version.set_anchors_preset(Control.PRESET_BOTTOM_LEFT);version.offset_top=-40
	version.modulate=Color(.5,.5,.46);add_child(version)

func button(parent: Node,title: String,action: Callable):
	var b=Button.new();b.text=title;b.custom_minimum_size=Vector2(360,62)
	b.alignment=HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size",27)
	var box=StyleBoxFlat.new();box.bg_color=Color(.09,.025,.028,.87);box.border_color=Color(.34,.25,.18)
	box.border_width_left=3;box.border_width_top=1;box.border_width_bottom=1
	box.content_margin_left=24;box.content_margin_right=24
	b.add_theme_stylebox_override("normal",box)
	var hover=box.duplicate();hover.bg_color=Color(.18,.055,.05,.95)
	b.add_theme_stylebox_override("hover",hover);b.add_theme_stylebox_override("pressed",hover)
	b.pressed.connect(action);parent.add_child(b)

func play():
	if not game.startup_ready or game.phase!="menu": return
	hide();game.menu.hide()
	game._host()
	if game.phase=="lobby": game._start()
	else: show()
