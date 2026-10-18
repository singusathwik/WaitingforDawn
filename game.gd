extends Node3D
signal important_state_received
## All gameplay mutations execute on peer 1. Clients send bounded input and action intents.
const VERSION = "0.8.2"
const DIFFICULTIES = [
	{"name":"Easy","chase":2.7,"patrol":1.6,"vision":12.0,"hearing":0.7,"memory":2.0,"grace":18.0,"drain":16.0,"regen":20.0,"bottles":5},
	{"name":"Normal","chase":3.5,"patrol":2.0,"vision":16.0,"hearing":1.0,"memory":3.0,"grace":10.0,"drain":22.0,"regen":14.0,"bottles":3},
	{"name":"Hard","chase":3.9,"patrol":2.3,"vision":19.0,"hearing":1.2,"memory":4.0,"grace":7.0,"drain":25.0,"regen":12.0,"bottles":2},
	{"name":"Extreme","chase":4.3,"patrol":2.6,"vision":22.0,"hearing":1.45,"memory":5.0,"grace":4.0,"drain":28.0,"regen":10.0,"bottles":1}
]
var difficulty = 1
var difficulty_picker: OptionButton
var difficulty_description: Label
const PORT = 28741
const DISCOVERY_PORT = 28742
const CELL = 3.0
const MAP = [
 "#################",
 "#.......#.......#",
 "#.......#.......#",
 "#................",
 "#.......#.......#",
 "###.#######.#####",
 "................#",
 "#...............#",
 "###.#######.#####",
 "#.......#.......#",
 "#.......#........",
 "#...............#",
 "#.......#.......#",
 "############....#"]
var people: Dictionary = {}
var actors: Dictionary = {}
var commands: Dictionary = {}
var last_action: Dictionary = {}
var pending: Dictionary = {}
var phase = "menu"
var peer: ENetMultiplayerPeer
var world: Node3D
var camera: Camera3D
var lamp: SpotLight3D
var ghost: Node3D
var ghost_pos = Vector3(42,0,33)
var ghost_mode = "patrol"
var ghost_goal = Vector3.ZERO
var ghost_timer = 0.0
var grace = 10.0
var keys: Array = []
var found: Array = []
var door_open = false
var door: Node3D
var garage_exit: Node3D
var garage_exit_shape: CollisionShape3D
var garage_exit_tween: Tween
var escape_car: Node3D
var key_meshes: Array = []
var snapshot_clock = 0.0
var input_clock = 0.0
var noise_clock: Dictionary = {}
var rng = RandomNumberGenerator.new()
var grid = AStarGrid2D.new()
var navigation = AStar3D.new()
var nav_ids: Dictionary = {}
var ui: CanvasLayer
var menu: PanelContainer
var stack: VBoxContainer
var status: Label
var roster: Label
var hud: Label
var hint: Label
var name_edit: LineEdit
var ip_edit: LineEdit
var start_button: Button
var ready_button: Button
var touch: Control
var yaw = 0.0
var pitch = 0.0
var sensitivity = 0.003
var brightness = 0.65
var low_textures=false
var volume = 0.6
var control_scale = 1.0
var shake = false
var environment: Environment
var move_finger = -1
var look_finger = -1
var move_origin = Vector2.ZERO
var touch_move = Vector2.ZERO
var sprint = false
var crouch = false
var light_on = true
var connect_deadline = 0
var udp = PacketPeerUDP.new()
var discovery_clock = 0.0
var rooms: Dictionary = {}
var room_label: Label
var message = ""
var end_clock = 0.0
var test_mode = ""
var test_clock = 0.0
var test_stage = 0
var received_frames = 0
var audio_stream: AudioStreamWAV
var test_route: PackedVector3Array = []
var test_destination = 0
var test_origin = Vector3.ZERO
var test_moved = false
var broken: Array = []
var glass_meshes: Array = []
var prop_clock: Dictionary = {}
var frames: Array[float] = []
var witnessed_hides: Dictionary = {}
var credits: AcceptDialog
var move_guide: Control
var stamina_bar: ProgressBar
var dawn: Node
var exploration: Node
var nursery: Node3D
var round_id = 0
var horror: Node
var noise_warning_until=0
var atmosphere: Node
var quitting=false
var home: Control
var startup_ready=false
var step_distance: Dictionary={}
var next_creak_step: Dictionary={}
var repair_layout: Node

func _difficulty() -> Dictionary:
	return DIFFICULTIES[difficulty]

func _set_difficulty(index: int):
	if index<0 or index>=DIFFICULTIES.size(): return
	if phase!="menu" and (phase!="lobby" or not multiplayer.is_server()): return
	if difficulty==index: return
	difficulty=index
	if test_mode=="": _save_settings()
	if phase=="lobby":
		# A changed ruleset needs fresh consent from every joining player.
		for id in people:
			if id!=1: people[id].ready=false
		_broadcast_lobby()
	_refresh_menu()

func _is_mobile(platform: String = OS.get_name()) -> bool:
	return platform in ["Android", "iOS"]

func _network_help() -> String:
	return " On iPhone, allow Local Network in Settings > Privacy & Security, then retry." if OS.get_name()=="iOS" else ""

func _quit(code: int=0):
	if quitting: return
	quitting=true
	set_physics_process(false)
	set_process(false)
	if is_instance_valid(atmosphere):
		atmosphere.set_process(false)
		atmosphere.stop_audio()
	await get_tree().create_timer(.65).timeout
	get_tree().quit.call_deferred(code)

func _ready():
	rng.randomize()
	Engine.max_fps = 60
	_build_grid()
	_build_world()
	_build_estate()
	exploration=preload("res://exploration.gd").new()
	add_child(exploration)
	exploration.geometry(self)
	repair_layout=preload("res://estate_layout.gd").new()
	add_child(repair_layout)
	repair_layout.build(self)
	_build_navigation()
	nursery.seed_navigation()
	for pos in [Vector3(15,0,18),Vector3(9,5,9),Vector3(9,-5,30)]:
		glass_meshes.append(_box(world,pos+Vector3(0,0.025,0),Vector3(1.8,0.05,1.8),Color(0.32,0.53,0.54)))
	_load_settings()
	_build_ui()
	atmosphere=preload("res://atmosphere.gd").new()
	add_child(atmosphere)
	atmosphere.setup(self)
	horror=preload("res://horror_interactions.gd").new()
	add_child(horror)
	horror.setup(self)
	await exploration.setup()
	dawn=preload("res://dawn.gd").new()
	add_child(dawn)
	dawn.setup(self)
	multiplayer.peer_disconnected.connect(_departed)
	multiplayer.peer_connected.connect(_connected_peer)
	multiplayer.connected_to_server.connect(_joined)
	multiplayer.connection_failed.connect(func(): _leave("Connection failed. Check IP, same Wi-Fi and firewall UDP %s." % PORT + _network_help()))
	multiplayer.server_disconnected.connect(func(): _leave("Host left or connection was lost. Your team is back at the menu."))
	# iOS uses direct unicast only; broadcast discovery requires an Apple entitlement.
	if OS.get_name() != "iOS":
		udp.set_broadcast_enabled(true)
		udp.bind(DISCOVERY_PORT, "0.0.0.0")
	home=preload("res://home_screen.gd").new()
	ui.add_child(home)
	home.build(self)
	home.hide()
	startup_ready=true
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--test="): test_mode = arg.get_slice("=", 1)
	if test_mode!="":
		difficulty=1
		get_tree().create_timer(1600 if test_mode=="traverse" else 115).timeout.connect(func(): _quit(1))
	if test_mode in ["host","host4","lobbyhost","departurehost","repeat-host"]: _host()
	elif test_mode in ["client","mismatch","late","waiting","full","departclient","timeout"]:
		ip_edit.text = "127.0.0.1"
		_join()
	elif test_mode == "rules": call_deferred("_test_rules")
	elif test_mode in ["visual","scarevisual","ghostvisual","facereview"]:
		_host(); _start()
		if test_mode=="ghostvisual":
			grace=10000
			ghost_pos=Vector3(9,0,6)
	elif test_mode in ["cupboardview","bedview","clueview","doorview","searchview"]:
		_host(); _start(); grace=10000
		if test_mode in ["cupboardview","bedview"]:
			var slot=horror.slots[0 if test_mode=="cupboardview" else 6]
			people[1].pos=slot.entry
			actors[1].position=slot.entry
			_act(1,"use")
			ghost_pos=slot.entry+Vector3(0,0,3).rotated(Vector3.UP,slot.angle)
		elif test_mode=="searchview":
			people[1].pos=Vector3(9,5,6)
			actors[1].position=people[1].pos
			yaw=0; pitch=-.2
		elif test_mode=="clueview":
			horror.clues=[0,1,2]
			horror.show_journal()
		else:
			people[1].pos=Vector3(3,5,9)
			actors[1].position=people[1].pos
			_act(1,"use")
			yaw=PI/2
	elif test_mode=="exploration":
		var driver=preload("res://tests/exploration.gd").new()
		add_child(driver)
		driver.setup(self)
	elif test_mode.begins_with("repair-"):
		var driver=preload("res://tests/repair_views.gd").new()
		add_child(driver)
		driver.setup(self,test_mode.trim_prefix("repair-"))
	elif test_mode.begins_with("nursery-"):
		var driver=preload("res://tests/nursery.gd").new()
		add_child(driver)
		driver.setup(self,test_mode)
	elif test_mode=="horror": call_deferred("_test_horror")
	elif test_mode=="difficulty": call_deferred("_test_difficulty")
	elif test_mode=="art": call_deferred("_test_art")
	elif test_mode=="scares": call_deferred("_test_scares")
	elif test_mode == "traverse":
		_host()
		_start()
		for i in [0,1,2]: horror.opened[i]=true
		horror.apply_doors(false)
		grace=10000
		Engine.time_scale=4
		test_route=_test_key_route(0)
	elif test_mode == "benchmark": _host(); _start(); grace=10000
	_refresh_menu()
	if test_mode=="": home.show(); menu.hide()
	if test_mode.begins_with("search-") or test_mode.begins_with("room-"):
		var driver=preload("res://tests/search_network.gd").new()
		add_child(driver)
		driver.setup(self,test_mode)
	if test_mode.begins_with("horror-"):
		var driver=preload("res://tests/horror_network.gd").new()
		add_child(driver)
		driver.setup(self,test_mode)
	if test_mode.begins_with("coop-"):
		var driver=preload("res://tests/coop_driver.gd").new()
		add_child(driver)
		driver.setup(self,test_mode)

func _build_grid():
	grid.region = Rect2i(0, 0, 17, 14)
	grid.cell_size = Vector2(CELL, CELL)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	for z in range(14):
		for x in range(17): grid.set_point_solid(Vector2i(x,z), MAP[z][x] == "#")

func _material(color: Color, glow = false) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.95
	if glow:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.6
	return mat

func _box(parent: Node, pos: Vector3, size: Vector3, color: Color, solid = false) -> MeshInstance3D:
	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _material(color)
	parent.add_child(mesh)
	mesh.position = pos
	if solid:
		var body = StaticBody3D.new()
		var shape = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		body.add_child(shape)
		mesh.add_child(body)
	return mesh

func _sign(text: String, pos: Vector3, color = Color(0.74,0.82,0.74)):
	return
	var label = Label3D.new()
	label.text = text
	label.font_size = 34
	label.pixel_size = 0.009
	label.modulate = color
	label.no_depth_test = false
	world.add_child(label)
	label.position = pos

func _build_world():
	world = Node3D.new()
	add_child(world)
	var env_node = WorldEnvironment.new()
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.025,0.035,0.045)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.4,0.52,0.58)
	environment.ambient_light_energy = brightness
	env_node.environment = environment
	world.add_child(env_node)
	_box(world, Vector3(24,-0.2,19.5), Vector3(51,0.4,42), Color(0.18,0.21,0.22), true)
	_box(world, Vector3(24,3.8,19.5), Vector3(51,0.3,42), Color(0.08,0.10,0.12))
	for z in range(14):
		for x in range(17):
			if MAP[z][x] == "#":
				_box(world,Vector3(x*CELL,1.8,z*CELL),Vector3(3,3.6,3),Color(0.19+float(z%3)*0.025,0.24,0.25),true)
	for p in [Vector3(6,0,6),Vector3(33,0,6),Vector3(6,0,30)]:
		_box(world,p+Vector3(0,0.65,0),Vector3(2.4,1.3,1.4),Color(0.28,0.20,0.14),true)
		_box(world,p+Vector3(0,1.35,0),Vector3(2.7,0.15,1.6),Color(0.42,0.30,0.19))
	for p in [Vector3(18,0,9),Vector3(36,0,12)]:
		var chair=_box(world,p+Vector3(0,0.55,0),Vector3(0.8,1.1,0.8),Color(0.3,0.22,0.14),true)
		chair.get_child(0).set_meta("impact",true)
		_box(world,p+Vector3(0,1.3,0.3),Vector3(0.8,0.8,0.15),Color(0.3,0.22,0.14))

	_sign("NO ONE\nLEAVES ALONE",Vector3(13.5,1.9,1.6),Color(0.56,0.48,0.35))
	_sign("01 / PARLOUR",Vector3(12,2.9,1.6))
	_sign("02 / ARCHIVE",Vector3(36,2.9,1.6))
	_sign("03 / MOURNING ROOM",Vector3(12,2.8,25.6))
	_sign("GARAGE / ALL SURVIVORS MUST BOARD",Vector3(39,2.8,25.6),Color(0.8,0.6,0.3))
	_sign("UPPER FLOOR  →",Vector3(43,2.6,7.4),Color(0.8,0.6,0.3))
	_sign("BASEMENT  →",Vector3(43,2.6,28.4),Color(0.8,0.6,0.3))
	for z in [3,12,18,27,36]:
		_box(world,Vector3(24,3.35,z),Vector3(45,0.25,0.25),Color(0.19,0.15,0.12))
	for p in [Vector3(12,0.015,9),Vector3(36,0.015,9),Vector3(12,0.015,33)]:
		_box(world,p,Vector3(6,0.03,4),Color(0.29,0.19,0.18))
		for x in [-2.7,2.7]: _box(world,p+Vector3(x,0.02,0),Vector3(0.12,0.02,3.8),Color(0.53,0.41,0.27))
	door = _box(world,Vector3(33,1.5,24),Vector3(2.8,3,0.3),Color(0.38,0.24,0.12),true)
	ghost = Node3D.new()
	world.add_child(ghost)
	var body = MeshInstance3D.new()
	var cone = CylinderMesh.new()
	cone.top_radius = 0.18
	cone.bottom_radius = 0.62
	cone.height = 2.4
	cone.radial_segments = 7
	body.mesh = cone
	body.material_override = _material(Color(0.46,0.58,0.55),true)
	ghost.add_child(body)
	body.position.y = 1.4
	_box(ghost,Vector3(0,2.3,-0.18),Vector3(0.4,0.12,0.15),Color(0.04,0.02,0.02))
	camera = Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(12,1.65,10)
	camera.far = 65
	camera.current = true
	lamp = SpotLight3D.new()
	camera.add_child(lamp)
	lamp.light_color = Color(1,0.86,0.63)
	lamp.light_energy = 2.2
	lamp.spot_range = 20
	lamp.spot_angle = 40
	world.visible = false

func _hiding_spots() -> Array:
	return [Vector3(4,0,11),Vector3(45,0,11),Vector3(4,0,35),Vector3(6,5,6),Vector3(6,-5,27),Vector3(6,-10,27)]

func _build_estate():
	# Each wing has a single wide ramp. Floors and navigation share the same coordinates.
	nursery=preload("res://nursery_room.gd").new()
	world.add_child(nursery)
	nursery.build(self)
	_room(Vector3(12,-5,30),"BASEMENT / THE BOILER",Color(0.23,0.28,0.22),"west_south")
	_room(Vector3(12,-10,30),"UNDERGROUND CRYPT",Color(0.24,0.25,0.3),"south")

	_box(world,Vector3(-12,-0.2,18),Vector3(27,0.4,21),Color(0.16,0.22,0.17),true)
	for pos in [Vector3(-25.5,1.5,18),Vector3(-12,1.5,7.5),Vector3(-12,1.5,28.5)]:
		_box(world,pos,Vector3(0.5,3,21) if pos.x < -25 else Vector3(27,3,0.5),Color(0.18,0.22,0.23),true)
	_sign("REAR GRAVEYARD",Vector3(-12,2.8,8))
	for x in [-21,-15,-9]:
		for z in [12,24]:
			_box(world,Vector3(x,0.65,z),Vector3(0.8,1.3,0.35),Color(0.37,0.4,0.4),true)
	for spot in [Vector3(15,-5,30),Vector3(15,-10,30)]:
		_box(world,spot+Vector3(0,0.5,0),Vector3(2.4,1,1.2),Color(0.31,0.24,0.19),true)
	for x in [67,83]:
		for z in [54,66]: _box(world,Vector3(x,-8.2,z),Vector3(0.7,3.6,0.7),Color(0.31,0.32,0.36))
	for x in [68,70,72]:
		_box(world,Vector3(x,-3.2,20.5),Vector3(0.22,3.2,0.22),Color(0.33,0.32,0.23))
	_sign("CRYPT / VEHICLE KEY  ↓",Vector3(12,-2.3,36.8),Color(0.8,0.6,0.3))

func _room(center: Vector3,label: String,color: Color,opening: String):
	_box(world,center+Vector3(0,-0.2,0),Vector3(21,0.4,21),color,true)
	_box(world,center+Vector3(0,3.8,0),Vector3(21,0.3,21),color.darkened(0.5))
	for side in ["west","east","north","south"]:
		var gap=(side=="east" and (center.y in [5.0,-5.0] or opening=="east")) or (side=="west" and opening.begins_with("west")) or (side=="south" and opening in ["west_south","south"]) or (side=="north" and opening=="north")
		if gap:
			for offset in [-6.0,6.0]:
				var pos=center+Vector3(-10.5 if side=="west" else 10.5,1.8,offset) if side in ["west","east"] else center+Vector3(offset,1.8,-10.5 if side=="north" else 10.5)
				_box(world,pos,Vector3(0.4,3.6,9) if side in ["west","east"] else Vector3(9,3.6,0.4),color,true)
		else:
			var pos=center+Vector3(-10.5 if side=="west" else 10.5,1.8,0) if side in ["west","east"] else center+Vector3(0,1.8,-10.5 if side=="north" else 10.5)
			_box(world,pos,Vector3(0.4,3.6,21) if side in ["west","east"] else Vector3(21,3.6,0.4),color,true)
	_sign(label,center+Vector3(0,2.8,-9.9))

func _ramp(a: Vector3,b: Vector3):
	var horizontal=Vector2(b.x-a.x,b.z-a.z).length()
	var along_x=absf(b.x-a.x)>1
	var mesh=_box(world,(a+b)*0.5-Vector3(0,0.15,0),Vector3(a.distance_to(b),0.3,3) if along_x else Vector3(3,0.3,a.distance_to(b)),Color(0.31,0.27,0.21),true)
	if along_x: mesh.rotation.z=atan2(b.y-a.y,b.x-a.x)
	else: mesh.rotation.x=-atan2(b.y-a.y,b.z-a.z)
	var ceiling=_box(world,(a+b)*.5+Vector3(0,3.8,0),mesh.mesh.size,Color(.12,.11,.1))
	ceiling.rotation=mesh.rotation
	for offset in [-1.6,1.6]:
		var rail=_box(world,(a+b)*0.5+Vector3(0,1.8,offset) if along_x else (a+b)*0.5+Vector3(offset,1.8,0),Vector3(a.distance_to(b),3.6,0.2) if along_x else Vector3(0.2,3.6,a.distance_to(b)),Color(0.18,0.20,0.20),true)
		if along_x: rail.rotation.z=mesh.rotation.z
		else: rail.rotation.x=mesh.rotation.x

func _nav_add(p: Vector3) -> int:
	if nav_ids.has(p): return nav_ids[p]
	var id=navigation.get_available_point_id()
	navigation.add_point(id,p)
	nav_ids[p]=id
	return id

func _build_navigation():
	for z in range(14):
		for x in range(17):
			if MAP[z][x]!="#": _nav_add(Vector3(x*3,0,z*3))
	for center in [Vector3(12,5,9),Vector3(12,-5,30),Vector3(12,-10,30),Vector3(-12,0,18)]:
		for x in range(-3,4):
			for z in range(-3,4): _nav_add(center+Vector3(x*3,0,z*3))
	for p in nav_ids:
		for offset in [Vector3(3,0,0),Vector3(0,0,3)]:
			if nav_ids.has(p+offset): navigation.connect_points(nav_ids[p],nav_ids[p+offset])
	repair_layout.navigation()
	for obstacle in [Vector3(6,0,6),Vector3(33,0,6),Vector3(6,0,30),Vector3(18,0,9),Vector3(36,0,12),Vector3(42,0,33),Vector3(15,-5,30),Vector3(15,-10,30)]:
		if nav_ids.has(obstacle): navigation.set_point_disabled(nav_ids[obstacle],true)

func _nav_path(a: Vector3,b: Vector3) -> PackedVector3Array:
	return navigation.get_point_path(navigation.get_closest_point(a),navigation.get_closest_point(b))

func _build_ui():
	ui = CanvasLayer.new()
	add_child(ui)
	var back = TextureRect.new()
	back.texture=load("res://assets/ui/manor.png")
	back.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	back.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	back.name = "Backdrop"
	ui.add_child(back)
	menu = PanelContainer.new()
	var panel_style=StyleBoxFlat.new()
	panel_style.bg_color=Color(.025,.029,.032,.87)
	panel_style.border_color=Color(0.4,0.35,0.23)
	panel_style.set_border_width_all(2)
	menu.add_theme_stylebox_override("panel",panel_style)
	menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	menu.offset_left = -390
	menu.offset_right = 390
	menu.offset_top = -330
	menu.offset_bottom = 330
	ui.add_child(menu)
	var margin = MarginContainer.new()
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,22)
	menu.add_child(margin)
	stack = VBoxContainer.new()
	stack.add_theme_constant_override("separation",6)
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.add_child(stack)
	var title = Label.new()
	title.text = "WAITING FOR DAWN"
	title.add_theme_font_size_override("font_size",30)
	title.add_theme_color_override("font_color",Color(0.83,0.73,0.48))
	stack.add_child(title)
	var sub = Label.new()
	sub.text = "A house that listens. A ride that waits.   •   v"+VERSION
	stack.add_child(sub)
	name_edit = LineEdit.new()
	name_edit.placeholder_text = "Your name"
	name_edit.text = "Survivor"
	name_edit.max_length = 20
	stack.add_child(name_edit)
	ip_edit = LineEdit.new()
	ip_edit.placeholder_text = "Host local IPv4 address (for example 192.168.1.12)"
	stack.add_child(ip_edit)
	var row = HBoxContainer.new()
	stack.add_child(row)
	_button(row,"BACK",func():
		if phase=="menu": menu.hide(); home.show()
		elif phase=="playing": _show_pause())
	_button(row,"HOST ROOM",_host)
	_button(row,"JOIN IP",_join)
	_button(row,"CREDITS",func(): credits.popup_centered(Vector2i(900,560)))
	credits=AcceptDialog.new()
	credits.title="Waiting for Dawn — original assets / Godot and third-party licenses"
	ui.add_child(credits)
	var license_text=TextEdit.new()
	license_text.editable=false
	license_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	license_text.offset_bottom=-60
	license_text.text="Waiting for Dawn original layout and audio. Imported art: Thin Zombie by Rosswet Mobile (CC BY 3.0), adapted as a tinted spectral character, converted to glTF with selected animations. https://opengameart.org/node/14826 | https://creativecommons.org/licenses/by/3.0/ . Furniture and scanned textures: Poly Haven (CC0), https://polyhaven.com . Full asset sources and modifications: ASSETS.md.\n\n"+Engine.get_license_text()+"\n\n"
	for item in Engine.get_license_info(): license_text.text+=str(item)+"\n"+Engine.get_license_info()[item]+"\n\n"
	credits.add_child(license_text)
	var difficulty_row=HBoxContainer.new()
	stack.add_child(difficulty_row)
	var difficulty_label=Label.new()
	difficulty_label.text="Difficulty (host selects)"
	difficulty_label.custom_minimum_size.x=240
	difficulty_row.add_child(difficulty_label)
	difficulty_picker=OptionButton.new()
	difficulty_picker.custom_minimum_size.y=44
	difficulty_picker.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for option in DIFFICULTIES: difficulty_picker.add_item(option.name)
	difficulty_picker.select(difficulty)
	difficulty_picker.item_selected.connect(_set_difficulty)
	difficulty_row.add_child(difficulty_picker)
	difficulty_description=Label.new()
	difficulty_description.add_theme_font_size_override("font_size",16)
	stack.add_child(difficulty_description)
	var actions = HBoxContainer.new()
	stack.add_child(actions)
	ready_button = _button(actions,"READY / NOT READY",_toggle_ready)
	start_button = _button(actions,"START / RESTART",_start)
	_button(actions,"LEAVE ROOM",func(): _leave("Left room."))
	_button(actions,"LOBBY",_return_lobby)
	roster = Label.new()
	stack.add_child(roster)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.y = 54
	stack.add_child(status)
	room_label = Label.new()
	room_label.text = "iPhone: use JOIN IP on the same Wi-Fi. Allow Local Network when prompted." if OS.get_name()=="iOS" else "Nearby rooms appear here; enter their address above."
	stack.add_child(room_label)
	_slider("Brightness",0.25,1.2,brightness,func(v): brightness=v; environment.ambient_light_energy=v*.55; _save_settings())
	_slider("Look sensitivity",0.001,0.008,sensitivity,func(v): sensitivity=v; _save_settings())
	_slider("Audio",0,1,volume,func(v): volume=v; AudioServer.set_bus_volume_db(0,linear_to_db(maxf(v,0.001))); _save_settings())
	_slider("Touch size",0.8,1.4,control_scale,func(v): control_scale=v; _layout_touch(); _save_settings())
	var shake_toggle=CheckButton.new()
	shake_toggle.text="Camera motion (off = reduced motion)"
	shake_toggle.button_pressed=shake
	shake_toggle.toggled.connect(func(v): shake=v; _save_settings())
	stack.add_child(shake_toggle)
	var texture_toggle=CheckButton.new()
	texture_toggle.text="Lower texture detail (uses less memory)"
	texture_toggle.button_pressed=low_textures
	texture_toggle.toggled.connect(func(v): low_textures=v; nursery.set_texture_detail(v); _save_settings())
	stack.add_child(texture_toggle)
	var help = Label.new()
	help.text = "WASD move • mouse look • Shift sprint • Ctrl crouch\nE interact / revive • F light • Q throw • Esc release mouse / menu\nSearch for 12 linked keys. Escape by car before 6 AM.
B: shared bag • J: recovered papers. Use your torch wherever the house is dark."
	help.add_theme_font_size_override("font_size",16)
	stack.add_child(help)
	hud = Label.new()
	hud.position = Vector2(32,24)
	hud.add_theme_font_size_override("font_size",22)
	ui.add_child(hud)
	hint = Label.new()
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	hint.position = Vector2(-250,40)
	hint.size = Vector2(700,130)
	hint.position.x=-350
	hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size",22)
	ui.add_child(hint)
	touch = Control.new()
	touch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	touch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(touch)
	for spec in [["USE",func(): _request_action("use")],["LIGHT",_toggle_light],["CROUCH",func(): crouch=not crouch],["RUN",func(): sprint=not sprint],["THROW",func(): _request_action("throw")],["MENU",func(): _show_pause()],["CLUES",func(): horror.show_journal()],["BAG",func(): dawn.show_bag()]]:
		var b=_button(touch,spec[0],spec[1])
		b.set_meta("action",spec[0])
		b.tooltip_text=spec[0]
		b.text=""
		b.icon=load("res://assets/ui/"+str(spec[0]).to_lower()+".svg")
		b.expand_icon=true
		b.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER
		b.add_theme_constant_override("icon_max_width",39)
		b.custom_minimum_size=Vector2.ZERO
		for state in ["normal","hover","pressed","focus"]:
			var circle=StyleBoxFlat.new()
			circle.bg_color=Color(.07,.08,.075,.65 if state=="normal" else .9)
			circle.border_color=Color(.72,.69,.58,.5)
			circle.set_border_width_all(1)
			circle.set_corner_radius_all(60)
			b.add_theme_stylebox_override(state,circle)
		if _is_mobile(): b.mouse_filter=Control.MOUSE_FILTER_IGNORE
	move_guide=preload("res://mobile_joystick.gd").new()
	move_guide.mouse_filter=Control.MOUSE_FILTER_IGNORE
	touch.add_child(move_guide)
	var crosshair=Label.new()
	crosshair.text="·"
	crosshair.add_theme_font_size_override("font_size",28)
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position=Vector2(-4,-19)
	crosshair.mouse_filter=Control.MOUSE_FILTER_IGNORE
	touch.add_child(crosshair)
	stamina_bar=ProgressBar.new()
	stamina_bar.show_percentage=false
	stamina_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var bg=StyleBoxFlat.new()
	bg.bg_color=Color(.03,.05,.04,.65)
	bg.set_corner_radius_all(5)
	var fill=StyleBoxFlat.new()
	fill.bg_color=Color(.27,.62,.38,.9)
	fill.set_corner_radius_all(5)
	stamina_bar.add_theme_stylebox_override("background",bg)
	stamina_bar.add_theme_stylebox_override("fill",fill)
	touch.add_child(stamina_bar)
	_layout_touch()
	get_viewport().size_changed.connect(_layout_touch)

func _button(parent: Node,text: String,callback: Callable) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(120,44)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func _slider(text: String,low: float,high: float,value: float,callback: Callable):
	var row = HBoxContainer.new()
	stack.add_child(row)
	var label = Label.new()
	label.text = text
	label.custom_minimum_size.x = 180
	row.add_child(label)
	var slider = HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = (high-low)/100.0
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	slider.value_changed.connect(callback)

func _layout_touch():
	if not is_instance_valid(touch): return
	var size = get_viewport().get_visible_rect().size
	var inset = Vector2(32,24)
	if _is_mobile():
		var safe = DisplayServer.get_display_safe_area()
		var screen = DisplayServer.screen_get_size()
		if screen.x > 0: inset.x = maxf(32,float(maxi(safe.position.x,screen.x-safe.end.x))/screen.x*size.x+16)
		if screen.y > 0: inset.y = maxf(24,float(maxi(safe.position.y,screen.y-safe.end.y))/screen.y*size.y+16)
	if is_instance_valid(hud): hud.position=inset
	var d=72*control_scale
	for child in touch.get_children():
		if not child is Button: continue
		child.size=Vector2(d,d)
		var action=child.get_meta("action")
		var top=["MENU","CLUES","LIGHT"].find(action)
		if action=="BAG": child.position=Vector2(size.x-inset.x-d,inset.y)
		elif top>=0: child.position=inset+Vector2(top*(d+12),0)
		else:
			var i=["USE","CROUCH","RUN","THROW"].find(action)
			child.position=size-inset-Vector2((2-i%2)*(d+14),(2-i/2)*(d+14))
	move_guide.size=Vector2(190,190)*control_scale
	move_guide.position=Vector2(inset.x,size.y-inset.y-move_guide.size.y)
	move_guide.queue_redraw()
	stamina_bar.position=Vector2(size.x*.36,size.y-inset.y-20)
	stamina_bar.size=Vector2(size.x*.28,10)

func _save_settings():
	var c = ConfigFile.new()
	c.set_value("settings","brightness",brightness)
	c.set_value("settings","low_textures",low_textures)
	c.set_value("settings","sensitivity",sensitivity)
	c.set_value("settings","audio",volume)
	c.set_value("settings","controls",control_scale)
	c.set_value("settings","shake",shake)
	c.set_value("settings","difficulty",difficulty)
	c.save("user://settings.cfg")

func _load_settings():
	var c = ConfigFile.new()
	if c.load("user://settings.cfg") == OK:
		brightness=c.get_value("settings","brightness",0.65)
		low_textures=c.get_value("settings","low_textures",false)
		sensitivity=c.get_value("settings","sensitivity",0.003)
		volume=c.get_value("settings","audio",0.6)
		control_scale=c.get_value("settings","controls",1.0)
		shake=c.get_value("settings","shake",false)
		difficulty=clampi(int(c.get_value("settings","difficulty",1)),0,DIFFICULTIES.size()-1)
	environment.ambient_light_energy=brightness*.55
	AudioServer.set_bus_volume_db(0,linear_to_db(maxf(volume,0.001)))
	_layout_touch()

func _host():
	if phase != "menu": return
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(PORT,3)
	if err != OK:
		message = "Cannot host: UDP %s unavailable (%s). Close another host or check network permission." % [PORT,err]
		_refresh_menu()
		return
	multiplayer.multiplayer_peer = peer
	people = {1:_new_person(name_edit.text)}
	people[1].ready = true
	phase = "lobby"
	message = "Room open. LAN addresses: " + _lan_addresses() + "  | UDP " + str(PORT)
	_refresh_menu()

func _lan_addresses() -> String:
	var addresses: Array[String] = []
	for address in IP.get_local_addresses():
		if address.contains(".") and not address.begins_with("127.") and not address.begins_with("169.254."): addresses.append(address)
	return ", ".join(addresses) if addresses.size() else "No LAN IPv4 found; connect to Wi-Fi or enable a hotspot."

func _join():
	if phase != "menu": return
	if not ip_edit.text.strip_edges().is_valid_ip_address():
		message = "Enter the host's local IP address shown on its lobby screen."
		_refresh_menu()
		return
	peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip_edit.text.strip_edges(),PORT)
	if err != OK:
		message = "Cannot open network connection (%s). Check network access." % err
		_refresh_menu()
		return
	multiplayer.multiplayer_peer = peer
	phase = "connecting"
	connect_deadline = Time.get_ticks_msec()+10000
	message = "Connecting… Check same Wi-Fi, AP isolation and firewall if this times out."
	_refresh_menu()

func _joined():
	register.rpc_id(1,"incompatible" if test_mode=="mismatch" else VERSION,name_edit.text)

func _return_lobby():
	if not multiplayer.is_server() or phase not in ["won","lost"]: return
	phase="lobby"
	world.hide()
	ui.get_node("Backdrop").show()
	_broadcast_lobby()

func _connected_peer(id: int):
	if multiplayer.is_server(): pending[id] = Time.get_ticks_msec()+5000

@rpc("any_peer","call_remote","reliable")
func register(version: String,player_name: String):
	if not multiplayer.is_server(): return
	var id = multiplayer.get_remote_sender_id()
	if not pending.has(id): return
	pending.erase(id)
	var reason = ""
	if version != VERSION: reason = "Incompatible version. Install v"+VERSION+" on every device."
	elif phase != "lobby": reason = "Match already active. Join after the host returns to the lobby."
	elif people.size() >= 4: reason = "Room full: four players maximum."
	if reason != "":
		rejected.rpc_id(id,reason)
		pending[id]=Time.get_ticks_msec()+500
		return
	people[id] = _new_person(player_name)
	_broadcast_lobby()

@rpc("authority","call_remote","reliable")
func rejected(reason: String):
	_leave(reason)

func _new_person(player_name: String) -> Dictionary:
	return {"name":player_name.strip_edges().left(20) if not player_name.strip_edges().is_empty() else "Survivor","ready":false,"pos":Vector3(12,0,10),"yaw":0.0,"down":false,"hidden":false,"hide_slot":-1,"hide_exit":Vector3.ZERO,"boarded":false,"stamina":100.0,"bottles":int(_difficulty().bottles),"light":true}

func _toggle_ready():
	if phase != "lobby": return
	if multiplayer.is_server(): people[1].ready = not people[1].ready; _broadcast_lobby()
	else: ready_request.rpc_id(1)

@rpc("any_peer","call_remote","reliable")
func ready_request():
	var id = multiplayer.get_remote_sender_id()
	if multiplayer.is_server() and phase == "lobby" and people.has(id):
		people[id].ready = not people[id].ready
		_broadcast_lobby()

func _broadcast_lobby():
	lobby_state.rpc(people,difficulty)
	_refresh_menu()

@rpc("authority","call_remote","reliable")
func lobby_state(data: Dictionary,level: int):
	difficulty=clampi(level,0,DIFFICULTIES.size()-1)
	people = data
	phase = "lobby"
	world.visible = false
	menu.show()
	ui.get_node("Backdrop").show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	message = "Connected. Ready up; the host starts when everyone is ready."
	_refresh_menu()

func _start():
	if not multiplayer.is_server() or phase not in ["lobby","won","lost"]: return
	for p in people.values():
		if not p.ready:
			message = "Everyone must be ready first."
			_refresh_menu()
			return
	found=[]
	broken=[]
	prop_clock.clear()
	witnessed_hides.clear()
	door_open=false
	if is_instance_valid(escape_car): escape_car.position=Vector3(42,0,33)
	keys=[]
	var groups = [[Vector3(9,5,6),Vector3(18,5,12)],[Vector3(9,-5,27),Vector3(18,-5,33)],[Vector3(9,-10,27),Vector3(18,-10,33)]]
	for group in groups: keys.append(group[rng.randi_range(0,group.size()-1)])
	keys=dawn.choose_keys()
	var i = 0
	for id in people:
		var n = people[id].name
		people[id]=_new_person(n)
		people[id].ready=true
		people[id].pos=Vector3(9+i,0,10)
		i+=1
	commands.clear()
	last_action.clear()
	noise_clock.clear()
	step_distance.clear()
	next_creak_step.clear()
	ghost_pos=Vector3(27,0,18)
	ghost_goal=Vector3(30,0,18)
	ghost_mode="patrol"
	grace=_difficulty().grace+(36 if test_mode=="" and round_id==0 else 0)
	round_id+=1
	begin_match.rpc(people,keys,round_id,difficulty)

@rpc("authority","call_local","reliable")
func begin_match(data: Dictionary,placements: Array,round_number: int,level: int):
	difficulty=clampi(level,0,DIFFICULTIES.size()-1)
	round_id=round_number
	if is_instance_valid(horror): horror.reset()
	noise_warning_until=0
	people=data
	keys=placements
	exploration.reset()
	dawn.reset()
	found=[]
	broken=[]
	door_open=false
	for glass in glass_meshes: glass.show()
	phase="playing"
	grace=_difficulty().grace+exploration.intro_left
	ghost_pos=Vector3(27,0,18)
	ghost.position=ghost_pos
	move_finger=-1
	look_finger=-1
	touch_move=Vector2.ZERO
	sprint=false
	crouch=false
	light_on=false
	message=""
	menu.hide()
	if is_instance_valid(home): home.hide()
	ui.get_node("Backdrop").hide()
	world.show()
	for actor in actors.values(): actor.queue_free()
	actors.clear()
	for id in people:
		var actor = CharacterBody3D.new()
		var shape = CollisionShape3D.new()
		var capsule = CapsuleShape3D.new()
		capsule.radius=0.3
		capsule.height=1.7
		shape.shape=capsule
		shape.position.y=0.85
		actor.add_child(shape)
		world.add_child(actor)
		actor.position=people[id].pos
		actor.collision_layer=2
		actor.collision_mask=1
		actor.floor_snap_length=0.5
		if id != multiplayer.get_unique_id():
			_box(actor,Vector3(0,0.9,0),Vector3(0.5,1.6,0.4),Color(0.56,0.40,0.21))
			var label=Label3D.new()
			label.text=people[id].name
			label.position.y=2
			label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
			actor.add_child(label)
		actors[id]=actor
	for k in key_meshes: k.queue_free()
	key_meshes.clear()
	for i in range(keys.size()):
		var k=preload("res://repaired_art.gd").model(world,"key",keys[i])
		k.scale=Vector3.ONE*1.4
		key_meshes.append(k)
	_update_door()
	yaw=0.0
	pitch=0.0
	if not _is_mobile() and test_mode == "": Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if exploration.intro_left>0 else Input.MOUSE_MODE_CAPTURED
	for glass in glass_meshes: glass.show()
	_refresh_menu()

func _refresh_menu():
	difficulty_picker.select(difficulty)
	difficulty_picker.disabled=not (phase=="menu" or (phase=="lobby" and multiplayer.is_server()))
	difficulty_description.text=["Slower ghost, forgiving stamina, 5 bottles, 18s head start.","Standard ghost, balanced stamina, 3 bottles, 10s head start.","Faster, sharper hearing, less stamina, 2 bottles, 7s head start.","Relentless pursuit, sharp hearing, 1 bottle, 4s head start."][difficulty]
	status.text=message
	roster.text=""
	for id in people: roster.text += ("✓  " if people[id].ready else "○  ")+people[id].name+("  [HOST]" if id==1 else "")+"     "
	start_button.disabled=not multiplayer.is_server() or phase not in ["lobby","won","lost"]
	ready_button.disabled=phase != "lobby"
	ready_button.visible=phase=="lobby"
	name_edit.visible=phase in ["menu","connecting","lobby"]
	ip_edit.visible=name_edit.visible
	start_button.text="Try again" if phase in ["won","lost"] else "Start game"
	start_button.visible=phase in ["lobby","won","lost"]
	touch.visible=phase=="playing" and not menu.visible
	hud.visible=phase in ["playing","escaping"]
	hint.visible=hud.visible

func _departed(id: int):
	if not multiplayer.is_server(): return
	people.erase(id)
	pending.erase(id)
	commands.erase(id)
	if actors.has(id): actors[id].queue_free(); actors.erase(id)
	if phase=="lobby": _broadcast_lobby()
	elif phase=="playing": call_deferred("_sync_important"); _check_outcome()

func _leave(reason: String):
	if peer: peer.close()
	multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new()
	peer=null
	phase="menu"
	if is_instance_valid(horror): horror.reset()
	move_finger=-1
	look_finger=-1
	touch_move=Vector2.ZERO
	people.clear()
	pending.clear()
	world.hide()
	menu.hide()
	home.show()
	ui.get_node("Backdrop").show()
	message=reason
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	_refresh_menu()

func _notification(what):
	if what==NOTIFICATION_APPLICATION_PAUSED and phase != "menu": _leave("App backgrounded. Rejoin from the lobby when the team is ready.")

func _exit_tree():
	if is_instance_valid(atmosphere): atmosphere.stop_audio()
	udp.close()
	if peer: peer.close()
	if is_instance_valid(world):
		for node in world.get_children():
			if node is AudioStreamPlayer3D: node.stop(); node.stream=null
	audio_stream=null

func _toggle_light():
	light_on=not light_on

func _show_pause():
	menu.visible=not menu.visible
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if menu.visible or _is_mobile() else Input.MOUSE_MODE_CAPTURED
	message="Paused controls only; the match continues. Use LEAVE ROOM to disconnect." if menu.visible else ""
	_refresh_menu()

func _input(event):
	if is_instance_valid(exploration) and exploration.intro_left>0: return
	if is_instance_valid(horror) and horror.journal.visible: return
	if is_instance_valid(dawn) and dawn.bag.visible: return
	# Raw touch dispatch keeps action buttons independent of the movement/look fingers.
	if phase!="playing" or menu.visible or not event is InputEventScreenTouch or not event.pressed: return
	for button in touch.get_children():
		if button is Button and button.get_global_rect().has_point(event.position):
			button.pressed.emit()
			get_viewport().set_input_as_handled()
			return

func _unhandled_input(event):
	if is_instance_valid(exploration) and exploration.intro_left>0: return
	if is_instance_valid(horror) and horror.journal.visible: return
	if is_instance_valid(dawn) and dawn.bag.visible: return
	if phase != "playing": return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE: _show_pause()
			KEY_E: if not menu.visible: _request_action("use")
			KEY_Q: if not menu.visible: _request_action("throw")
			KEY_F: _toggle_light()
			KEY_J: horror.show_journal()
			KEY_B: dawn.show_bag()
	if menu.visible: return
	if event is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
		yaw-=event.relative.x*sensitivity
		pitch=clampf(pitch-event.relative.y*sensitivity,-1.3,1.3)
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < get_viewport().get_visible_rect().size.x*0.45 and move_finger==-1:
				move_finger=event.index
				move_origin=event.position
			elif look_finger==-1: look_finger=event.index
		else:
			if event.index==move_finger: move_finger=-1; touch_move=Vector2.ZERO
			if event.index==look_finger: look_finger=-1
	if event is InputEventScreenDrag:
		if event.index==move_finger: touch_move=((event.position-move_origin)/80).limit_length()
		if event.index==look_finger:
			yaw-=event.relative.x*sensitivity
			pitch=clampf(pitch-event.relative.y*sensitivity,-1.3,1.3)

func _physics_process(delta):
	if phase=="playing":
		input_clock+=delta
		if input_clock>=0.05:
			input_clock=0
			var movement=touch_move
			if not menu.visible and not horror.journal.visible and not dawn.bag.visible and exploration.intro_left<=0:
				movement+=Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
			else: movement=Vector2.ZERO
			var cmd={"move":movement.limit_length(),"yaw":yaw,"pitch":pitch,"run":sprint or Input.is_physical_key_pressed(KEY_SHIFT),"crouch":crouch or Input.is_physical_key_pressed(KEY_CTRL),"light":light_on}
			if multiplayer.is_server():
				if test_mode!="traverse": _accept_input(1,cmd)
			else: input_request.rpc_id(1,cmd)
		if multiplayer.is_server():
			dawn.tick(delta)
			if phase!="playing": return
			_simulate_players(delta)
			exploration.tick(delta)
			_tick_ghost(delta)
			snapshot_clock+=delta
			if snapshot_clock>=0.05:
				snapshot_clock=0
				var moving: Dictionary={}
				for id in people:
					moving[id]={"pos":people[id].pos,"yaw":people[id].yaw,"stamina":people[id].stamina,"light":people[id].light}
				movement_state.rpc(moving,ghost_pos,ghost_mode,round_id,grace)
		_visual_update(delta)
	elif phase=="escaping" and multiplayer.is_server():
		dawn.tick(delta)
		if phase!="escaping": return
		end_clock-=delta
		if end_clock<=0: finish.rpc("won","The engine catches. Everyone aboard escapes Waiting for Dawn.")
	if test_mode != "": _tick_test(delta)

@rpc("any_peer","call_remote","unreliable_ordered",1)
func input_request(cmd: Dictionary):
	if multiplayer.is_server(): _accept_input(multiplayer.get_remote_sender_id(),cmd)

func _accept_input(id: int,cmd: Dictionary):
	if phase!="playing" or not people.has(id) or exploration.intro_left>0: return
	if typeof(cmd.get("move"))!=TYPE_VECTOR2 or typeof(cmd.get("yaw")) not in [TYPE_FLOAT,TYPE_INT]: return
	if typeof(cmd.get("pitch",0)) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(cmd.get("pitch",0))): return
	if not cmd.move.is_finite() or not is_finite(cmd.yaw): return
	commands[id]={"move":cmd.move.limit_length(),"yaw":wrapf(cmd.yaw,-PI,PI),"pitch":clampf(float(cmd.get("pitch",0)),-1.3,1.3),"run":cmd.get("run")==true,"crouch":cmd.get("crouch")==true,"light":cmd.get("light")==true,"time":Time.get_ticks_msec()}

func _simulate_players(delta: float):
	for id in people:
		var p=people[id]
		var cmd=commands.get(id,{})
		if cmd.is_empty() or Time.get_ticks_msec()-cmd.time>400 or p.down or p.boarded: continue
		if p.hidden:
			p.stamina=minf(100,p.stamina+delta*_difficulty().regen)
			continue
		var speed=2.8
		if cmd.crouch:
			speed=1.4
			p.stamina=minf(100,p.stamina+delta*_difficulty().regen)
		elif cmd.run and p.stamina>0 and cmd.move.length()>0.1:
			speed=4.6
			p.stamina=maxf(0,p.stamina-delta*_difficulty().drain)
		else: p.stamina=minf(100,p.stamina+delta*_difficulty().regen)
		var direction=Vector3(cmd.move.x,0,cmd.move.y).rotated(Vector3.UP,cmd.yaw)
		var actor: CharacterBody3D=actors[id]
		var vertical=actor.velocity.y
		actor.velocity=direction*speed
		actor.velocity.y=vertical-delta*18 if not actor.is_on_floor() else -0.2
		var previous_position=actor.position
		actor.move_and_slide()
		# Step over small landing seams without jumping or allowing walls/furniture to be climbed.
		if direction.length()>.1 and actor.get_slide_collision_count()>0:
			var ahead=actor.position+direction.normalized()*.36
			var query=PhysicsRayQueryParameters3D.create(ahead+Vector3.UP*.22,ahead-Vector3.UP*.08,1)
			var support=world.get_world_3d().direct_space_state.intersect_ray(query)
			if not support.is_empty() and support.normal.y>.8:
				var rise=support.position.y-actor.position.y
				if rise>.015 and rise<.18 and not actor.test_move(actor.global_transform.translated(Vector3.UP*(rise+.015)),direction.normalized()*.1):
					actor.position.y+=rise+.015
		p.pos=actor.position
		p.yaw=cmd.yaw
		p.light=cmd.light
		# Count travelled footsteps, not frames or button presses. Only marked loose boards creak.
		if direction.length()>.1:
			step_distance[id]=step_distance.get(id,0.0)+Vector2(actor.position.x-previous_position.x,actor.position.z-previous_position.z).length()
			if not next_creak_step.has(id): next_creak_step[id]=rng.randi_range(20,50)*.65
			if step_distance[id]>=next_creak_step[id] and repair_layout.loose_board(p.pos) and not cmd.crouch:
				step_distance[id]=0.0
				next_creak_step[id]=rng.randi_range(20,50)*.65
				exploration.disturb(p.pos)
				sound_event.rpc(p.pos,.6,"creak")
		if direction.length()>0.1:
			for i in range(glass_meshes.size()):
				if not broken.has(i) and p.pos.distance_to(glass_meshes[i].position)<1.2:
					broken.append(i)
					_noise(p.pos,22)
					exploration.disturb(p.pos)
					sound_event.rpc(p.pos,0.8,"glass")
					_sync_important()
			if actor.get_slide_collision_count()>0 and Time.get_ticks_msec()-int(prop_clock.get(id,0))>1500:
				for collision in range(actor.get_slide_collision_count()):
					if actor.get_slide_collision(collision).get_collider().get_meta("impact",false):
						prop_clock[id]=Time.get_ticks_msec()
						exploration.disturb(p.pos)
						sound_event.rpc(p.pos,0.5,"chair")
						break

@rpc("authority","call_remote","unreliable_ordered",1)
func movement_state(data: Dictionary,gpos: Vector3,mode: String,round_number: int,safe_time: float):
	if phase!="playing" or round_number!=round_id: return
	for id in data:
		if people.has(id):
			for key in data[id]: people[id][key]=data[id][key]
	ghost_pos=gpos
	ghost_mode=mode
	grace=safe_time
	received_frames+=1

func _visual_update(delta: float):
	if is_instance_valid(move_guide): move_guide.direction=touch_move; move_guide.queue_redraw()
	for id in actors:
		if not people.has(id): actors[id].visible=false; continue
		if not multiplayer.is_server(): actors[id].position=actors[id].position.lerp(people[id].pos,1-exp(-delta*18))
		actors[id].visible=not people[id].hidden and not people[id].boarded
		actors[id].rotation.y=people[id].yaw
	ghost.position=ghost.position.lerp(ghost_pos,1-exp(-delta*12))
	ghost.visible=grace<=0
	var id=multiplayer.get_unique_id()
	if not people.has(id): return
	var p=people[id]
	camera.position=actors[id].position+Vector3(0,0.65 if p.down or crouch else 1.65,0)
	camera.rotation=Vector3(pitch,yaw,0)
	horror.hide_camera(p)
	if shake and not p.down and not p.hidden: camera.position.y+=sin(Time.get_ticks_msec()*0.012)*touch_move.length()*0.025
	lamp.visible=light_on and not p.hidden and not p.down
	environment.ambient_light_energy=brightness*(.001 if camera.position.y<0 else .35)
	var pulse=fmod(Time.get_ticks_msec()/1000.0,19.0)
	lamp.light_energy=2.35*(.16 if pulse>17.8 and sin(pulse*87)>-.2 else 1.0)
	hud.text=""
	stamina_bar.value=p.stamina
	hint.text=_prompt(id)
	for button in touch.get_children():
		if not button is Button: continue
		var action=button.get_meta("action")
		var active=(action=="RUN" and sprint) or (action=="CROUCH" and crouch) or (action=="LIGHT" and lamp.visible)
		button.modulate=Color(1,.83,.5) if active else Color.WHITE
	if horror.threat()>.35: hint.text+="\n"+("Stay quiet. Footsteps close outside." if p.hidden else "FOOTSTEPS CLOSE — FIND COVER")
	for i in range(key_meshes.size()):
		key_meshes[i].visible=exploration.key_available(i) and not found.has(i)
		key_meshes[i].global_position=exploration.key_display_position(i)
	touch.visible=not menu.visible and exploration.intro_left<=0
	exploration.cinematic_camera()

func _prompt(id: int) -> String:
	var p=people[id]
	if p.boarded: return "Waiting for every living teammate to board…"
	if p.down: return "Call for a teammate."
	if p.hidden: return horror.prompt(id)
	for other in people:
		if other!=id and people[other].down and p.pos.distance_to(people[other].pos)<2.4: return "USE — revive "+people[other].name
	var hide_target=horror.aimed_hiding(id)
	if hide_target>=0: return "USE — "+("hide in wardrobe" if horror.slots[hide_target].kind=="cupboard" else "crawl under bed")
	var search_prompt=exploration.prompt(id)
	if not search_prompt.is_empty(): return search_prompt
	var interaction=horror.prompt(id)
	if not interaction.is_empty(): return interaction
	if _near_garage_lock(p.pos): return "USE — open / close garage" if found.has(10) else "Garage requires its matching key"
	if _near_car(p.pos): return "USE — board the last ride" if door_open and found.has(11) else "Bring the garage and ignition keys"
	return ""

func _near_garage_lock(p: Vector3) -> bool:
	return p.distance_to(Vector3(33,0,24))<3.1 or p.distance_to(Vector3(44.7,0,38.4))<2.5

func _near_car(p: Vector3) -> bool:
	return p.distance_to(Vector3(42,0,30))<3 or p.distance_to(Vector3(42,0,33))<3.3

@rpc("authority","call_local","reliable")
func interaction_notice(text: String):
	horror.notice=text
	horror.notice_until=Time.get_ticks_msec()+7000

@rpc("authority","call_local","unreliable")
func noise_reply(source: Vector3):
	var p=people.get(multiplayer.get_unique_id(),{})
	if not p.is_empty() and p.pos.distance_to(source)<10:
		horror.notice="She heard that. Find cover."
		horror.notice_until=Time.get_ticks_msec()+2600
		atmosphere.noise_alert=1.5

func _request_action(action: String):
	if phase!="playing": return
	if multiplayer.is_server(): _act(1,action)
	else: action_request.rpc_id(1,action)

@rpc("any_peer","call_remote","reliable")
func action_request(action: String):
	if multiplayer.is_server(): _act(multiplayer.get_remote_sender_id(),action)

func _act(id: int,action: String):
	if phase!="playing" or not people.has(id) or exploration.intro_left>0: return
	var now=Time.get_ticks_msec()
	if now-int(last_action.get(id,-1000))<350: return
	last_action[id]=now
	var p=people[id]
	if p.down or p.boarded: return
	if action=="throw" and not p.hidden and p.bottles>0:
		p.bottles-=1
		var target=p.pos+Vector3(0,0,-9).rotated(Vector3.UP,p.yaw)
		for i in range(9,0,-1):
			target=p.pos+Vector3(0,0,-i).rotated(Vector3.UP,p.yaw)
			if _walkable(target) and _line_clear(p.pos,target): break
		_land_bottle(target,round_id)
		bottle_visual.rpc(p.pos,target)
	elif action=="use":
		if p.hidden: horror.use(id)
		else:
			var done=false
			for other in people:
				if other!=id and people[other].down and p.pos.distance_to(people[other].pos)<2.4 and _line_clear(p.pos,people[other].pos):
					people[other].down=false
					people[other].hidden=false
					witnessed_hides.erase(other)
					grace=3
					done=true
					break
			if not done:
				for i in range(keys.size()):
					if exploration.key_available(i) and exploration.target(id)==exploration.index_for_key(i) and not found.has(i):
						dawn.collect(id,i)
						sound_event.rpc(keys[i],0.45,"key")
						done=true
						break
			if not done and horror.aimed_hiding(id)>=0: done=horror.use(id)
			if not done: done=exploration.use(id)
			if not done: done=horror.use(id)
			if not done and _near_garage_lock(p.pos) and found.has(10):
				door_open=not door_open
				_update_door()
				_noise(p.pos,20)
				sound_event.rpc(p.pos,0.7,"door")
			elif not done and _near_car(p.pos) and door_open and found.has(11):
				p.boarded=true
	_sync_important()
	_check_outcome()

func _sync_important():
	important_state.rpc(people,found,door_open,broken,horror.opened,horror.clues,round_id)
	exploration.sync_state.rpc(exploration.searched,round_id,exploration.opened)

func _land_bottle(pos: Vector3,thrown_round: int):
	await get_tree().create_timer(.5).timeout
	if phase=="playing" and round_id==thrown_round and multiplayer.is_server():
		_noise(pos,24)
		exploration.disturb(pos)
		sound_event.rpc(pos,.8,"glass")

@rpc("authority","call_local","reliable")
func important_state(data: Dictionary,collected: Array,opened: bool,shards: Array,room_doors: Array,read_clues: Array,state_round: int):
	if state_round!=round_id or phase!="playing": return
	people=data
	found=collected
	door_open=opened
	broken=shards
	horror.receive(room_doors,read_clues)
	important_state_received.emit()
	for i in range(glass_meshes.size()): glass_meshes[i].visible=not broken.has(i)
	_update_door()

@rpc("authority","call_local","unreliable")
func bottle_visual(origin: Vector3,target: Vector3):
	var bottle=_box(world,origin+Vector3.UP,Vector3(0.12,0.3,0.12),Color(0.3,0.6,0.5))
	# The projectile crosses the flashlight near plane; casting there causes striped shadows.
	bottle.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var tween=create_tween()
	tween.tween_property(bottle,"position",(origin+target)*0.5+Vector3(0,2,0),0.25)
	tween.tween_property(bottle,"position",target,0.25)
	tween.tween_callback(bottle.queue_free)

func _update_door():
	door.visible=not door_open
	door.get_child(0).get_child(0).set_deferred("disabled",door_open)
	if is_instance_valid(garage_exit):
		garage_exit_shape.set_deferred("disabled",door_open)
		if garage_exit.get_meta("opened",false)!=door_open:
			garage_exit.set_meta("opened",door_open)
			if garage_exit_tween: garage_exit_tween.kill()
			garage_exit_tween=create_tween()
			garage_exit_tween.tween_property(garage_exit,"position:y",3.6 if door_open else 0.0,1.3).set_trans(Tween.TRANS_SINE)
	grid.set_point_solid(Vector2i(11,8),not door_open)
	if nav_ids.has(Vector3(33,0,24)): navigation.set_point_disabled(nav_ids[Vector3(33,0,24)],not door_open)

func _walkable(p: Vector3) -> bool:
	var id=navigation.get_closest_point(p)
	return id>=0 and navigation.get_point_position(id).distance_to(p)<2.4

func _line_clear(a: Vector3,b: Vector3) -> bool:
	if is_instance_valid(horror) and horror.blocks(a,b): return false
	if a.distance_to(b)<0.05: return true
	var query=PhysicsRayQueryParameters3D.create(a+Vector3(0,1.4,0),b+Vector3(0,1.4,0),1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _noise(pos: Vector3,radius: float):
	if grace>0: return
	var attenuation=1.0 if _line_clear(ghost_pos,pos) else 0.4
	if ghost_pos.distance_to(pos)<radius*attenuation*_difficulty().hearing and ghost_mode!="chase":
		ghost_goal=pos
		ghost_mode="investigate"
		ghost_timer=180
		if Time.get_ticks_msec()>noise_warning_until:
			noise_warning_until=Time.get_ticks_msec()+8000
			sound_event.rpc(ghost_pos,.6,"wail")

func _tick_ghost(delta: float):
	grace=maxf(0,grace-delta)
	if grace>0: return
	var nearest=-1
	var distance=float(_difficulty().vision)
	for id in people:
		var p=people[id]
		if p.down or p.boarded: continue
		if p.hidden:
			if Time.get_ticks_msec()>int(witnessed_hides.get(id,0)): continue
			var entry=p.hide_exit
			var route=_nav_path(ghost_pos,entry)
			var d=ghost_pos.distance_to(entry)
			if not route.is_empty() and d<distance and not horror.blocks(ghost_pos,entry): nearest=id; distance=d
			continue
		var d=ghost_pos.distance_to(p.pos)
		if d<distance and _line_clear(ghost_pos,p.pos): nearest=id; distance=d
	if nearest!=-1:
		ghost_mode="chase"
		ghost_goal=people[nearest].hide_exit if people[nearest].hidden else people[nearest].pos
		ghost_timer=_difficulty().memory
		if distance<1.2:
			if people[nearest].hidden: horror.use(nearest)
			people[nearest].down=true
			sound_event.rpc(people[nearest].pos,.8,"stinger")
			_sync_important()
			_check_outcome()
	else:
		ghost_timer-=delta
		if ghost_mode=="chase" and ghost_timer<=0: ghost_mode="search"; ghost_timer=5
		elif ghost_mode=="investigate" and (ghost_pos.distance_to(ghost_goal)<1 or ghost_timer<=0): ghost_mode="search"; ghost_timer=5
		elif ghost_mode=="search" and ghost_timer<=0: ghost_mode="return"
		elif ghost_mode=="return": ghost_mode="patrol"; ghost_goal=Vector3(30,0,18)
		elif ghost_mode=="patrol" and ghost_pos.distance_to(ghost_goal)<1:
			var choices=[Vector3(12,0,9),Vector3(36,0,9),Vector3(12,0,33),Vector3(30,0,18),Vector3(9,5,6),Vector3(9,-5,27),Vector3(9,-10,27),Vector3(-12,0,18)]
			ghost_goal=choices[rng.randi_range(0,choices.size()-1)]
	if ghost_mode=="search": return
	var path=_nav_path(ghost_pos,ghost_goal)
	if path.is_empty():
		# A closed room cannot strand her indefinitely. Approach its nearest reachable side.
		var nearest_point=ghost_pos
		var best_distance=INF
		for point in navigation.get_point_ids():
			if navigation.is_point_disabled(point): continue
			var candidate=navigation.get_point_position(point)
			if candidate.distance_to(ghost_goal)>=best_distance: continue
			var route=_nav_path(ghost_pos,candidate)
			if route.size()>1: nearest_point=candidate; best_distance=candidate.distance_to(ghost_goal)
		ghost_goal=nearest_point
		path=_nav_path(ghost_pos,ghost_goal)
		if path.size()<2: ghost_mode="search"; ghost_timer=2
	if path.size()>1:
		var target=path[1]
		var speed=_difficulty().chase if ghost_mode=="chase" else _difficulty().patrol*1.65 if ghost_mode=="investigate" else _difficulty().patrol
		var step=ghost_pos.move_toward(target,delta*speed)
		if not horror.blocks(ghost_pos,step): ghost_pos=step
	elif path.size()==1:
		var step=ghost_pos.move_toward(ghost_goal,delta*(_difficulty().chase if ghost_mode=="chase" else _difficulty().patrol))
		if _line_clear(ghost_pos,step): ghost_pos=step

func _check_outcome():
	if phase!="playing": return
	var alive=0
	var boarded=0
	for p in people.values():
		if not p.down:
			alive+=1
			if p.boarded: boarded+=1
	if alive==0: finish.rpc("lost","The house falls silent. All survivors are down. Restart to try again.")
	elif alive==boarded:
		end_clock=4
		escape_started.rpc()

@rpc("authority","call_local","reliable")
func escape_started():
	phase="escaping"
	for actor in actors.values(): actor.hide()
	hint.text="THE LAST RIDE\nThe engine turns…"
	touch.hide()
	sound_event(Vector3(42,0,30),1,"engine")

@rpc("authority","call_local","reliable")
func finish(result: String,text: String):
	horror.journal.hide()
	phase=result
	message=("ESCAPED — " if result=="won" else "GAME OVER — ")+_difficulty().name+"\n"+text+" Host can restart, or leave the room."
	menu.show()
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	_refresh_menu()

func _process(delta):
	if phase=="escaping":
		camera.position=camera.position.lerp(Vector3(42,2.6,29),delta*2)
		camera.rotation=Vector3(0,PI,0)
		if is_instance_valid(escape_car): escape_car.position.z+=delta*6
	if test_mode=="benchmark" and test_clock>2: frames.append(delta*1000)
	if phase=="connecting" and Time.get_ticks_msec()>connect_deadline: _leave("Connection timed out. Room may be full, Wi-Fi may isolate clients, or UDP %s is blocked." % PORT + _network_help())
	if multiplayer.is_server():
		for id in pending.keys():
			if Time.get_ticks_msec()>pending[id]: peer.disconnect_peer(id); pending.erase(id)
	discovery_clock+=delta
	if discovery_clock>2 and OS.get_name() != "iOS":
		discovery_clock=0
		if phase=="lobby" and multiplayer.is_server():
			udp.set_dest_address("255.255.255.255",DISCOVERY_PORT)
			udp.put_packet(JSON.stringify({"game":"WaitingForDawn","v":VERSION,"name":people[1].name,"count":people.size()}).to_utf8_buffer())
		for address in rooms.keys():
			if Time.get_ticks_msec()-rooms[address].time>6000: rooms.erase(address)
		room_label.text="Nearby: "
		for address in rooms: room_label.text+=address+" ("+str(rooms[address].count)+"/4)  "
	while udp.get_available_packet_count()>0:
		var packet=udp.get_packet()
		var address=udp.get_packet_ip()
		if packet.size()>512: continue
		var data=JSON.parse_string(packet.get_string_from_utf8())
		if data is Dictionary and data.get("game")=="WaitingForDawn" and data.get("v")==VERSION:
			rooms[address]={"count":data.get("count",0),"time":Time.get_ticks_msec()}

func _make_audio():
	audio_stream=AudioStreamWAV.new()
	audio_stream.format=AudioStreamWAV.FORMAT_16_BITS
	audio_stream.mix_rate=22050
	var bytes=PackedByteArray()
	bytes.resize(11025*2)
	var random=RandomNumberGenerator.new()
	random.seed=47
	for i in range(11025):
		var t=float(i)/22050
		var value=(sin(t*TAU*73)*0.45+random.randf_range(-0.3,0.3))*exp(-t*9)
		bytes.encode_s16(i*2,int(value*25000))
	audio_stream.data=bytes

@rpc("authority","call_local","unreliable")
func sound_event(pos: Vector3,strength: float,kind: String="chair"):
	if is_instance_valid(atmosphere): atmosphere.play(kind,pos,strength)

func _tick_test(delta: float):
	test_clock+=delta
	if test_mode=="traverse":
		if int(test_clock/30)>test_stage:
			test_stage=int(test_clock/30)
			print("ROUTE position ",people[1].pos," next ",test_route[0] if not test_route.is_empty() else Vector3.ZERO)
		if test_clock>1500:
			print("TEST traversal FAILED at ",people[1].pos," target ",test_route[0] if test_route.size() else Vector3.ZERO)
			_quit(1)
			return
		if test_route.size():
			var offset=test_route[0]-people[1].pos
			if Vector2(offset.x,offset.z).length()<0.28 and absf(offset.y)<0.7:
				test_route.remove_at(0)
			else:
				_accept_input(1,{"move":Vector2(offset.x,offset.z).normalized(),"yaw":0.0})
		elif test_destination<keys.size():
			var delta_key=keys[test_destination]-(people[1].pos+Vector3(0,1.65,0))
			yaw=atan2(-delta_key.x,-delta_key.z)
			pitch=atan2(delta_key.y,Vector2(delta_key.x,delta_key.z).length())
			last_action.clear()
			_act(1,"use")
			last_action.clear()
			_act(1,"use")
			print("TEST reached key ",test_destination," at ",people[1].pos," collected=",found.size()," target=",exploration.target(1)," key=",keys[test_destination]," prompt=",_prompt(1))
			if not found.has(test_destination): _quit(1); return
			test_destination+=1
			if test_destination<keys.size(): test_route=_test_key_route(test_destination)
			else: test_route=_nav_path(people[1].pos,Vector3(33,0,21))
		elif test_destination==keys.size():
			last_action.clear()
			_act(1,"use")
			test_destination=keys.size()+1
			test_route=_nav_path(people[1].pos,Vector3(42,0,30))
		else:
			last_action.clear()
			_act(1,"use")
			print("TEST traversal finished keys=",found.size()," phase=",phase)
			_quit(0 if phase=="escaping" else 1)
	if test_mode in ["cupboardview","bedview"]: ghost.visible=true
	if test_mode in ["cupboardview","bedview","clueview","doorview","searchview"] and test_clock>3:
		_capture_test_image(test_mode+"-060.png")
		_quit()
	if test_mode=="facereview":
		atmosphere.scare_time=.4
		atmosphere.scare_animation.play("idle")
		atmosphere.scare.rotation.y=float(test_stage)*PI/2
		if test_clock>2+test_stage:
			_capture_test_image("face-"+str(test_stage)+".png")
			test_stage+=1
			if test_stage==4: _quit()
	if test_mode=="ghostvisual":
		ghost.visible=true
		ghost.position=Vector3(9,0,6)
	if test_mode=="scarevisual" and test_clock>1.5 and test_stage==0:
		atmosphere.trigger_scare()
		test_stage=1
	if test_mode in ["visual","menuvisual","scarevisual","ghostvisual"] and test_clock>2:
		_capture_test_image(test_mode+"-040.png")
		_quit()
	if test_mode=="benchmark" and test_clock>15:
		frames.sort()
		print("BENCH desktop rendered frames=",frames.size()," p50_ms=",frames[int(frames.size()*0.5)]," p95_ms=",frames[int(frames.size()*0.95)]," static_memory_bytes=",Performance.get_monitor(Performance.MEMORY_STATIC))
		_quit()
	if test_mode in ["host","host4","departurehost","repeat-host"] and phase=="lobby" and people.size()==(4 if test_mode=="host4" else 2) and test_clock>3: _start()
	if test_mode in ["client","departclient"] and phase=="lobby" and test_stage==0: _toggle_ready(); test_stage=1
	if test_mode=="departclient" and test_clock>5:
		_leave("Test departure")
		print("TEST client left voluntarily")
		_quit()
	if test_mode=="departurehost" and test_clock>4 and test_stage==0:
		found=[0]
		test_stage=1
	if test_mode=="repeat-host" and test_clock>6 and test_stage==0:
		finish.rpc("won","Repeat match fixture")
		_start()
		test_stage=1
		print("TEST repeated network match")
	if test_mode=="client" and phase=="playing" and test_stage==1:
		print("TEST client began match; peers=",people.size())
		test_origin=people[multiplayer.get_unique_id()].pos
		test_stage=2
	if test_mode=="client" and phase=="playing" and test_stage==2:
		touch_move=Vector2(1,0) if test_clock<5 else Vector2.ZERO
		if people[multiplayer.get_unique_id()].pos.distance_to(test_origin)>0.5: test_moved=true
	if test_mode in ["host","host4","departurehost","repeat-host"] and test_clock>9:
		print("TEST host peers=",people.size()," phase=",phase)
		var expected=4 if test_mode=="host4" else (1 if test_mode=="departurehost" else 2)
		var passed=people.size()==expected and phase=="playing"
		if test_mode=="departurehost": passed=passed and found.has(0); print("TEST shared key persists=",found.has(0))
		_quit(0 if passed else 1)
	if test_mode=="client" and test_clock>10:
		print("TEST client snapshots=",received_frames)
		print("TEST authoritative movement=",test_moved)
		print("TEST host departure returned menu=",phase=="menu")
		_quit(0 if received_frames>20 and phase=="menu" and test_moved else 1)
	if test_mode=="mismatch" and test_clock>3:
		print("TEST mismatch rejected=",phase=="menu" and message.contains("Incompatible"))
		_quit(0 if phase=="menu" and message.contains("Incompatible") else 1)
	if test_mode=="late" and test_clock>2:
		print("TEST active match rejection=",message.contains("already active"))
		_quit(0 if message.contains("already active") else 1)
	if test_mode in ["full","timeout"] and test_clock>11:
		print("TEST connection timeout=",phase=="menu" and message.contains("timed out"))
		_quit(0 if phase=="menu" and message.contains("timed out") else 1)
	if test_mode=="lobbyhost" and test_clock>14:
		print("TEST lobby capacity=",people.size())
		_quit(0 if people.size()==4 else 1)
	if test_mode=="waiting" and test_clock>15:
		print("TEST waiting client host departure=",phase=="menu")
		_quit(0 if phase=="menu" else 1)

func _test_rules():
	_host()
	_start()
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert(phase=="playing")
	assert(hud.visible and touch.visible and not menu.visible,"Match HUD transition failed")
	for i in [0,1,2,6,7]: horror.opened[i]=true
	horror.apply_doors(false)
	for key in keys:
		assert(not _nav_path(Vector3(9,0,9),exploration.approach(key)).is_empty(),"Unreachable key "+str(key))
	for candidate in [Vector3(9,5,6),Vector3(18,5,12),Vector3(9,-5,27),Vector3(18,-5,33),Vector3(9,-10,27),Vector3(18,-10,33)]:
		assert(not _nav_path(Vector3(9,0,9),candidate).is_empty(),"Unreachable random placement")
	_accept_input(99,{"move":Vector2.ONE,"yaw":0.0})
	assert(not commands.has(99),"Unregistered input accepted")
	_accept_input(1,{"move":Vector2(999,999),"yaw":0.0})
	assert(commands[1].move.length()<=1.001,"Unbounded movement")
	people[2]=_new_person("Second")
	actors[2]=CharacterBody3D.new()
	world.add_child(actors[2])
	for n in range(exploration.compartments.size()):
		if keys.has(exploration.compartments[n].pos): exploration.searched.append(n); exploration.opened.append(n)
	_test_aim_key(1,0)
	_test_aim_key(2,0)
	_act(1,"use")
	_act(2,"use")
	assert(found.size()==1,"Duplicate pickup")
	last_action.clear()
	people[1].pos=Vector3(9,0,10)
	_act(1,"use")
	assert(found.size()==1,"Out of range pickup")
	var bottle_count=people[1].bottles
	last_action.clear()
	_act(1,"throw")
	_act(1,"throw")
	assert(people[1].bottles==bottle_count-1,"Cooldown bypass")
	people[1].pos=horror.slots[0].entry
	last_action.clear()
	_act(1,"use")
	assert(people[1].hidden)
	ghost_pos=people[1].pos
	grace=0
	_tick_ghost(0.1)
	assert(not people[1].down,"Hidden player tracked")
	people[1].hidden=false
	people[2].pos=people[1].pos
	people[2].down=true
	last_action.clear()
	_act(1,"use")
	assert(not people[2].down,"Revive failed")
	found=range(12)
	people[1].pos=Vector3(33,0,22)
	last_action.clear()
	_act(1,"use")
	assert(door_open)
	people[1].pos=Vector3(42,0,29)
	last_action.clear()
	_act(1,"use")
	assert(phase=="playing","Escaped before team boarded")
	people[2].pos=Vector3(42,0,29)
	last_action.clear()
	_act(2,"use")
	assert(phase=="escaping")
	finish("won","test")
	people.erase(2)
	_start()
	assert(found.is_empty() and not door_open and phase=="playing")
	grace=0
	ghost_mode="patrol"
	ghost_pos=Vector3(12,0,18)
	_noise(Vector3(14,0,18),4)
	assert(ghost_mode=="investigate","Nearby sound not heard")
	ghost_mode="patrol"
	_noise(Vector3(42,0,18),3)
	assert(ghost_mode=="patrol","Far sound heard")
	ghost_pos=Vector3(12,0,12)
	_noise(Vector3(12,0,18),10)
	assert(ghost_mode=="patrol","Wall did not attenuate noise")
	people[1].pos=Vector3(15,0,18)
	ghost_pos=Vector3(15,0,18.5)
	_tick_ghost(0.1)
	assert(phase=="lost")
	print("TEST rules PASS: all placements reachable, input ownership/bounds, duplicate/range pickup, cooldown, hiding, revive, door, team escape, restart, noise falloff/walls, ghost targeting, solo defeat")
	_quit()

func _test_scares():
	_host()
	_start()
	grace=10000
	await get_tree().create_timer(.06).timeout
	found=[0,1]
	await get_tree().create_timer(.06).timeout
	assert(atmosphere.scare_time>0,"Second key did not trigger apparition")
	var before=atmosphere.scare_time
	atmosphere.trigger_scare()
	assert(atmosphere.scare_time<=before,"Scare cooldown failed")
	await get_tree().create_timer(1.2).timeout
	assert(not atmosphere.scare.visible,"Scare did not clear")
	finish("won","Fixture outcome")
	_return_lobby()
	_start()
	await get_tree().create_timer(.06).timeout
	assert(atmosphere.scare_cooldown==0,"Restart did not clear scare state")
	people[1].down=true
	_check_outcome()
	await get_tree().create_timer(.06).timeout
	assert(atmosphere.scare_time>0 and not menu.visible,"Capture scare was obscured")
	await get_tree().create_timer(1.2).timeout
	assert(menu.visible and not atmosphere.scare.visible,"Defeat menu did not return")
	_leave("test")
	await get_tree().create_timer(.06).timeout
	assert(not atmosphere.scare.visible,"Scare leaked into menu")
	print("PASS scares: objective, cooldown, expiry, restart, capture, defeat menu, leave")
	_quit()

func _test_art():
	var animations=atmosphere.ghost_animation.get_animation_list()
	for clip in ["idle","walk","run","attack1_l","attack2"]:
		assert(animations.has(clip),"Missing imported clip: "+clip)
	var skeleton=atmosphere.ghost_visual.find_children("*","Skeleton3D",true,false)[0]
	assert(skeleton.get_bone_count()>30,"Imported skeletal rig missing")
	atmosphere.ghost_animation.play("run")
	atmosphere.ghost_animation.advance(.1)
	skeleton.force_update_all_bone_transforms()
	var before=skeleton.get_bone_global_pose(skeleton.find_bone("hand.L"))
	atmosphere.ghost_animation.advance(.25)
	skeleton.force_update_all_bone_transforms()
	var after=skeleton.get_bone_global_pose(skeleton.find_bone("hand.L"))
	assert(not before.is_equal_approx(after),"Imported animation did not deform bones")
	assert(atmosphere.head_bone>=0,"Scare head anchor missing")
	assert(atmosphere.curtains.size()==8,"Imported pleated curtains missing")
	print("PASS imported art: five skeletal clips, ",skeleton.get_bone_count()," bones, animated hand, head anchor, eight cloth meshes")
	_quit()

func _capture_test_image(filename: String):
	var base="user://" if _is_mobile() else "res://artifacts/"
	var result=get_viewport().get_texture().get_image().save_png(base+filename)
	if result!=OK: push_error("Test screenshot failed: "+str(result))

func _test_difficulty():
	_host()
	var previous_speed=0.0
	for level in range(DIFFICULTIES.size()):
		phase="lobby"
		_set_difficulty(level)
		_start()
		assert(difficulty==level and people[1].bottles==_difficulty().bottles)
		assert(is_equal_approx(grace,float(_difficulty().grace)))
		_set_difficulty((level+1)%4)
		assert(difficulty==level,"Difficulty changed during a match")
		people[1].stamina=50.0
		_accept_input(1,{"move":Vector2.ZERO,"yaw":0.0,"crouch":true})
		_simulate_players(.1)
		assert(people[1].stamina>50.0,"Crouching must recover stamina")
		people[1].stamina=50.0
		_accept_input(1,{"move":Vector2(0,-1),"yaw":0.0,"run":true})
		_simulate_players(.1)
		assert(is_equal_approx(people[1].stamina,50.0-.1*_difficulty().drain))
		grace=0
		ghost_mode="patrol"
		ghost_pos=Vector3(12,0,18)
		_noise(Vector3(20,0,18),10)
		assert((ghost_mode=="investigate")== (level>0),"Hearing difficulty not applied")
		people[1].pos=Vector3(21,0,18)
		ghost_pos=Vector3(12,0,18)
		_tick_ghost(.1)
		assert(ghost_mode=="chase")
		var moved=ghost_pos.distance_to(Vector3(12,0,18))
		assert(moved>previous_speed,"Pursuit must increase with difficulty")
		previous_speed=moved
		people[1].boarded=true
		_check_outcome()
		assert(phase=="escaping")
		_physics_process(4.1)
		assert(phase=="won" and message.contains("ESCAPED"),"Escape ending missing")
		_start()
		people[1].down=true
		_check_outcome()
		assert(phase=="lost" and message.contains("GAME OVER"))
		_start()
		assert(not people[1].down and not people[1].boarded and found.is_empty())
		print("PASS difficulty and both endings: ",_difficulty().name)
	phase="lobby"
	people[2]=_new_person("ready fixture")
	people[2].ready=true
	_set_difficulty(0)
	assert(not people[2].ready,"Difficulty change must reset client readiness")
	_set_difficulty(-1)
	assert(difficulty==0)
	_set_difficulty(99)
	assert(difficulty==0)
	print("PASS difficulty locking, ready reset, invalid selection and stamina recovery")
	_quit()

func _test_horror():
	await get_tree().physics_frame
	await get_tree().physics_frame
	for edges in horror.door_edges: assert(not edges.is_empty(),"Room door does not cross a walkable route")
	_host()
	_start()
	set_physics_process(false)
	grace=10000
	await get_tree().physics_frame
	for i in range(3):
		people[1].pos=horror.NOTES[i]+Vector3(0,0,1.6)
		actors[1].position=people[1].pos
		last_action.clear()
		_act(1,"use")
		assert(horror.clues.has(i),"Clue was not discovered")
		assert(not horror.clue_text(i).contains("MOON"),"Pinpoint spoiler returned")
	assert(horror.clues.size()==3)
	print("PASS thematic papers discovered and shared without pinpoint markers")
	people[1].pos=Vector3(25.5,5,9)
	actors[1].position=people[1].pos
	ghost_pos=Vector3(21,5,9)
	last_action.clear()
	_act(1,"use")
	assert(not horror.opened[4],"Upper door did not close")
	assert(not _line_clear(Vector3(22.5,5,9),Vector3(25.5,5,9)))
	assert(horror.blocks(Vector3(22.5,5,9),Vector3(25.5,5,9)),"Closed doorway did not block direct entry")
	await get_tree().physics_frame
	for i in range(30):
		_accept_input(1,{"move":Vector2(-1,0),"yaw":0.0})
		_simulate_players(.05)
	assert(people[1].pos.x>24.2,"Player passed through shut door")
	ghost_pos=Vector3(22,5,9)
	ghost_mode="investigate"
	ghost_goal=Vector3(27,5,9)
	grace=0
	for i in range(60): _tick_ghost(.05)
	assert(ghost_pos.x<24,"Ghost crossed closed door")
	people[1].pos=Vector3(25.5,5,9)
	actors[1].position=people[1].pos
	last_action.clear()
	_act(1,"use")
	assert(horror.opened[4])
	assert(not _nav_path(Vector3(22,5,9),Vector3(27,5,9)).is_empty())
	print("PASS shut room door blocks physics, sight and ghost path; reopening restores route")
	grace=10000
	for slot_index in [0,6]:
		var slot=horror.slots[slot_index]
		people[1].pos=slot.entry
		actors[1].position=slot.entry
		last_action.clear()
		_act(1,"use")
		assert(people[1].hidden and people[1].hide_slot==slot_index)
		_visual_update(.01)
		assert(camera.position.is_equal_approx(slot.eye),"Hiding camera is outside the prop")
		assert(not lamp.visible)
		people[2]=people[1].duplicate()
		people[1].hidden=false
		people[1].pos=slot.entry
		assert(horror.use(1))
		assert(not people[1].hidden,"Two players occupied one hiding place")
		people[1].hidden=true
		people.erase(2)
		last_action.clear()
		_act(1,"use")
		assert(not people[1].hidden and people[1].pos.is_equal_approx(slot.entry))
	print("PASS cupboard slit and low bed camera, occupancy, exit and flashlight concealment")
	var slot=horror.slots[0]
	people[1].pos=slot.entry
	actors[1].position=slot.entry
	ghost_pos=slot.entry+Vector3(0,0,3)
	grace=0
	last_action.clear()
	_act(1,"use")
	assert(witnessed_hides.has(1),"Witnessed hiding not remembered")
	ghost_pos=slot.entry+Vector3(0,0,0.5)
	_tick_ghost(.01)
	assert(people[1].down and not people[1].hidden,"Ghost failed to search witnessed hiding place")
	_start()
	assert(horror.clues.is_empty() and horror.opened.count(false)==5 and not horror.opened[6] and not horror.opened[7] and not people[1].hidden)
	set_physics_process(false)
	grace=0
	ghost_pos=Vector3(12,0,18)
	ghost_mode="patrol"
	_noise(Vector3(14,0,18),8)
	assert(ghost_mode=="investigate" and noise_warning_until>Time.get_ticks_msec())
	camera.position=ghost_pos+Vector3(0,1.5,2)
	assert(horror.threat()>.7)
	grace=10
	assert(horror.threat()==0)
	print("PASS witnessed hide capture, round reset, noise investigation/wail cooldown and proximity warning")
	_quit()

func _test_key_route(index: int) -> PackedVector3Array:
	var destination=exploration.approach(keys[index])
	var path=_nav_path(people[1].pos,destination)
	path.append(destination)
	return path

func _test_aim_key(id: int,index: int):
	var p=exploration.approach(keys[index])
	people[id].pos=p
	if actors.has(id):actors[id].position=p
	var d=keys[index]-(p+Vector3(0,1.65,0))
	var view_yaw=atan2(-d.x,-d.z)
	var view_pitch=atan2(d.y,Vector2(d.x,d.z).length())
	if id==multiplayer.get_unique_id():yaw=view_yaw;pitch=view_pitch
	_accept_input(id,{"move":Vector2.ZERO,"yaw":view_yaw,"pitch":view_pitch})
