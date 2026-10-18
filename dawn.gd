extends Node
## Twelve-key dependency chain. Locks apply to every candidate container, not just the winning drawer.
const NAMES = ["Brass key", "Nursery key", "Pantry key", "Washroom key", "Bedroom key", "Furnace key", "Crypt ward", "Mourning key", "Locket key", "Portrait key", "Garage key", "Ignition key"]
const USES = ["nursery dresser", "pantry cupboard", "washroom cabinet", "attic dresser", "furnace workbench", "coal cabinet", "crypt doors and burial drawers", "keepsake chest", "portrait backs", "toy chest", "garage and sink cabinet", "car ignition"]
const POOLS = [[36,37,38,39,40,41],[0,1,2,3,4,5],[60,61,62,63,64,65],[48,49,50,51,52,53],[54,55,56,57,58,59],[12,13,14,15,16,17],[18,19,20,21,22,23],[24,25,26,27,28,29],[30,31,32,33,34,35],[77,78,79,80],[6,7,8,9,10,11],[42,43,44,45,46,47]]
const MINUTES = [40.0,32.0,26.0,20.0]
var g
var remaining=1920.0
var clock_label: Label
var toast: Label
var toast_left=0.0
var bag: AcceptDialog
var contents: RichTextLabel
var clock_sync=0.0
var warning_stage=0

func setup(game):
	g=game
	clock_label=Label.new()
	clock_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	clock_label.add_theme_font_size_override("font_size",20)
	clock_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	g.touch.add_child(clock_label)
	toast=Label.new()
	toast.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	toast.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	toast.add_theme_color_override("font_color",Color(.92,.79,.52))
	toast.mouse_filter=Control.MOUSE_FILTER_IGNORE
	g.touch.add_child(toast)
	bag=AcceptDialog.new()
	bag.title="Shared satchel"
	var leather=StyleBoxFlat.new()
	leather.bg_color=Color(.065,.052,.039,.97)
	leather.border_color=Color(.4,.31,.18)
	leather.set_border_width_all(3)
	leather.set_corner_radius_all(14)
	bag.add_theme_stylebox_override("panel",leather)
	bag.get_ok_button().text="Close bag"
	g.ui.add_child(bag)
	contents=RichTextLabel.new()
	contents.custom_minimum_size=Vector2(630,400)
	contents.bbcode_enabled=true
	contents.add_theme_font_size_override("normal_font_size",20)
	bag.add_child(contents)
	bag.visibility_changed.connect(func():
		if not bag.visible and g.phase=="playing" and not g.menu.visible and not g._is_mobile(): Input.mouse_mode=Input.MOUSE_MODE_CAPTURED)

func choose_keys() -> Array:
	var result=[]
	for pool in POOLS: result.append(g.exploration.compartments[pool[g.rng.randi_range(0,pool.size()-1)]].pos)
	return result

func required_key(container: int) -> int:
	for i in range(1,POOLS.size()):
		if POOLS[i].has(container): return i-1
	return -1

func unlocked(container: int) -> bool:
	var requirement=required_key(container)
	return requirement<0 or g.found.has(requirement)

func reset():
	remaining=MINUTES[g.difficulty]*60
	warning_stage=0
	clock_sync=0
	toast_left=0
	bag.hide()

func collect(id: int,key: int):
	if g.found.has(key): return
	g.found.append(key)
	if key==6:
		for door in [6,7]: g.horror.opened[door]=true
		g.horror.apply_doors()
		g.sound_event.rpc(g.horror.DOORS[6].pos,.6,"door")
	announce.rpc(g.people[id].name+" found the "+NAMES[key]+". Added to the shared bag.",g.round_id)

@rpc("authority","call_local","reliable")
func announce(message: String,round_number: int):
	if round_number!=g.round_id or g.phase!="playing": return
	toast.text=message
	toast_left=7

@rpc("authority","call_remote","reliable")
func sync_clock(seconds: float,round_number: int):
	if round_number==g.round_id and g.phase in ["playing","escaping"]: remaining=seconds

func tick(delta: float):
	if g.exploration.intro_left>0: return
	remaining=maxf(0,remaining-delta)
	clock_sync+=delta
	if clock_sync>=1:
		clock_sync=0
		sync_clock.rpc(remaining,g.round_id)
	if remaining<=0:
		g.finish.rpc("lost","Dawn. The house keeps those who fail to leave. Find the garage and ignition keys, then board together before 6 AM.")
	elif remaining<=60 and warning_stage<2:
		warning_stage=2
		announce.rpc("The sky is turning. One minute remains. Everyone to the car!",g.round_id)
	elif remaining<=300 and warning_stage<1:
		warning_stage=1
		announce.rpc("Five minutes until dawn. The garage and ignition keys are your last chance.",g.round_id)

func show_bag():
	if g.phase!="playing": return
	var text="[center][font_size=28]OUR SATCHEL[/font_size]\nShared discoveries • "+str(g.found.size())+" / 12[/center]\n\n"
	if g.found.is_empty(): text+="No keys yet. Search the house; use the hand to open drawers and turn portraits.\n"
	for key in g.found: text+="[color=#dcc38c]"+NAMES[key]+"[/color] — fits the "+USES[key]+"\n"
	var player=g.people.get(g.multiplayer.get_unique_id(),{})
	text+="\nBottles in your bag: "+str(player.get("bottles",0))+"\nRecovered papers: "+str(g.horror.clues.size())+" / 3\n\nKeys are kept automatically and shared with your team. They are never consumed. Open recovered letters with the paper icon.\n\nEscape before 6 AM: unlock the garage, start the car, board together."
	contents.text=text
	g.touch_move=Vector2.ZERO
	g.move_finger=-1
	g.look_finger=-1
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	bag.popup_centered(Vector2i(680,510))

func _process(delta):
	if not is_instance_valid(clock_label): return
	var size=g.get_viewport().get_visible_rect().size
	clock_label.position=Vector2(size.x*.5-185,28)
	clock_label.size=Vector2(370,60)
	toast.position=Vector2(size.x*.24,100)
	toast.size=Vector2(size.x*.52,70)
	toast_left=maxf(0,toast_left-delta)
	toast.visible=toast_left>0 and g.exploration.intro_left<=0
	var night=int(clampf(1-remaining/(MINUTES[g.difficulty]*60),0,1)*360)
	clock_label.text="%02d:%02d AM  •  DAWN IN %02d:%02d" % [12 if night<60 else night/60,night%60,int(ceil(remaining))/60,int(ceil(remaining))%60]
	clock_label.modulate=Color(1,.4,.3) if remaining<=300 else Color(.85,.81,.71)
	clock_label.visible=g.exploration.intro_left<=0
