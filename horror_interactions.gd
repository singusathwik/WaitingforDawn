extends Node
## Host-owned interactions. Peers receive state; geometry and camera presentation are local.
const DOORS = [
	{"pos":Vector3(9,0,15),"axis":2,"name":"Parlour"},
	{"pos":Vector3(33,0,15),"axis":2,"name":"Archive"},
	{"pos":Vector3(9,0,24),"axis":2,"name":"Mourning room"},
	{"pos":Vector3(24,0,9),"axis":0,"name":"East hallway"},
	{"pos":Vector3(64.5,5,9),"axis":0,"name":"Nursery"},
	{"pos":Vector3(64.5,-5,30),"axis":0,"name":"Boiler room"},
	{"pos":Vector3(75,-5,40.5),"axis":2,"name":"Crypt stair"},
	{"pos":Vector3(75,-10,49.5),"axis":2,"name":"Crypt"},
	{"pos":Vector3(85.5,5,9),"axis":0,"name":"Nursery east"},
	{"pos":Vector3(85.5,-5,30),"axis":0,"name":"Service passage"}
]
const NOTES = [Vector3(81,5,6),Vector3(69,5,12),Vector3(69,-5,33)]
const BEDS = [Vector3(15,0,33),Vector3(78,5,15),Vector3(78,-5,36)]
var game
var opened: Array = []
var clues: Array = []
var doors: Array = []
var slots: Array = []
var door_edges: Array = []
var leaves: Array = []
var occupied: Array = []
var local_hidden=false
var journal: AcceptDialog
var journal_text: RichTextLabel
var notice=""
var notice_until=0
var wood: StandardMaterial3D

func setup(g):
	game=g
	wood=preload("res://realistic_art.gd").pbr("old_wooden_floor_01",.5)
	for p in game._hiding_spots(): _cupboard(p)
	for p in BEDS: _bed(p)
	for spec in DOORS: _door(spec)
	for i in range(NOTES.size()):
		var p=NOTES[i]
		if i!=0: panel(game.world,p+Vector3(0,.55,0),Vector3(.8,1.1,.5))
		var paper=game._box(game.world,p+Vector3(0,.35 if i==0 else 1.13,0),Vector3(.6,.025,.4),Color(.7,.62,.42))
		paper.material_override=game._material(Color(.7,.62,.42),true)
		game._sign(["KEEPER'S LETTER","NURSERY DIARY","BOILER LOG"][i],p+Vector3(0,1.8,0))
	# Cache graph edges cut by each doorway. Both AI navigation and physics honor doors.
	for spec in DOORS:
		var edges=[]
		for a in game.navigation.get_point_ids():
			for b in game.navigation.get_point_connections(a):
				if a<b and crosses(spec,game.navigation.get_point_position(a),game.navigation.get_point_position(b)):
					edges.append(Vector2i(a,b))
		door_edges.append(edges)
	var cabinet_blocker=panel(game.world,Vector3(46.5,1,20),Vector3(1.6,2,1.2),true)
	cabinet_blocker.visible=false
	for p in game._hiding_spots():
		game.navigation.set_point_disabled(game.navigation.get_closest_point(p),true)
	for p in BEDS+NOTES+[Vector3(48,0,21)]:
		if game.nav_ids.has(p): game.navigation.set_point_disabled(game.nav_ids[p],true)
	journal=AcceptDialog.new()
	journal.title="Recovered papers"
	journal.borderless=true
	var paper_style=StyleBoxFlat.new()
	paper_style.bg_color=Color(.67,.57,.38)
	paper_style.border_color=Color(.25,.12,.07)
	paper_style.set_border_width_all(9)
	journal.add_theme_stylebox_override("panel",paper_style)
	game.ui.add_child(journal)
	journal.visibility_changed.connect(func():
		if not journal.visible and game.phase=="playing" and not game.menu.visible and not game._is_mobile(): Input.mouse_mode=Input.MOUSE_MODE_CAPTURED)
	var stains=TextureRect.new()
	stains.texture=load("res://assets/ui/parchment.png")
	stains.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	stains.stretch_mode=TextureRect.STRETCH_SCALE
	stains.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stains.mouse_filter=Control.MOUSE_FILTER_IGNORE
	journal.add_child(stains)
	journal_text=RichTextLabel.new()
	journal_text.bbcode_enabled=true
	journal_text.add_theme_color_override("default_color",Color(.15,.08,.045))
	var font=SystemFont.new()
	font.font_names=PackedStringArray(["Georgia","Noto Serif","serif"])
	journal_text.add_theme_font_override("normal_font",font)
	journal_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	journal_text.offset_left=18
	journal_text.offset_top=18
	journal_text.offset_right=-18
	journal_text.offset_bottom=-65
	journal_text.add_theme_font_size_override("normal_font_size",21)
	var paper_margin=MarginContainer.new()
	for edge in ["left","right","top","bottom"]: paper_margin.add_theme_constant_override("margin_"+edge,28)
	paper_margin.add_child(journal_text)
	journal.add_child(paper_margin)
	journal.get_ok_button().text="Fold paper"
	reset()

func panel(parent: Node3D,p: Vector3,size: Vector3,solid=false) -> MeshInstance3D:
	var mesh=game._box(parent,p,size,Color(.2,.13,.075),solid)
	mesh.material_override=wood
	if solid: mesh.get_child(0).set_meta("impact",true)
	return mesh

func _cupboard(p: Vector3):
	var angle=PI/2 if p.x<40 or p.x>60 else -PI/2
	var root=Node3D.new()
	game.world.add_child(root)
	root.position=p
	root.rotation.y=angle
	for x in [-.83,.83]: panel(root,Vector3(x,1.15,0),Vector3(.12,2.3,1.5),true)
	panel(root,Vector3(0,1.15,-.72),Vector3(1.7,2.3,.1),true)
	for y in [.06,2.3]: panel(root,Vector3(0,y,0),Vector3(1.85,.12,1.6))
	var front_blocker=panel(root,Vector3(0,1.15,.73),Vector3(1.6,2.3,.09),true)
	front_blocker.visible=false
	var hinge=Node3D.new()
	root.add_child(hinge)
	hinge.position=Vector3(-.8,0,.73)
	# A real eye-level aperture, not an opaque replacement screen.
	panel(hinge,Vector3(.8,.73,0),Vector3(1.6,1.46,.09))
	panel(hinge,Vector3(.8,1.93,0),Vector3(1.6,.74,.09))
	for x in [.06,1.54]: panel(hinge,Vector3(x,1.51,0),Vector3(.12,.1,.09))
	for x in [.12,1.48]:
		for y in [.65,1.97]: panel(hinge,Vector3(x,y,.06),Vector3(.05,.95,.04))
	for y in [.19,1.12,1.72,2.2]: panel(hinge,Vector3(.8,y,.06),Vector3(1.4,.05,.04))
	game._box(hinge,Vector3(1.4,1.0,.1),Vector3(.06,.2,.08),Color(.5,.38,.17))
	leaves.append(hinge)
	slots.append({"pos":p,"entry":p+Vector3(0,0,1.6).rotated(Vector3.UP,angle),"eye":p+Vector3(0,1.51,.43).rotated(Vector3.UP,angle),"angle":angle,"kind":"cupboard"})
	occupied.append(false)
	game._sign("CUPBOARD / USE",p+Vector3(0,2.6,0))

func _bed(p: Vector3):
	var angle=PI if p.x<60 else -PI/2
	var root=Node3D.new()
	game.world.add_child(root)
	root.position=p
	root.rotation.y=angle
	for x in [-.85,.85]:
		for z in [-1.3,1.3]: panel(root,Vector3(x,.45,z),Vector3(.13,.9,.13),true)
	panel(root,Vector3(0,.72,0),Vector3(1.9,.15,2.9),true)
	panel(root,Vector3(0,1.1,-1.4),Vector3(2,1.3,.12),true)
	var mattress=game._box(root,Vector3(0,.91,0),Vector3(1.8,.25,2.7),Color(.3,.25,.2))
	mattress.material_override=preload("res://realistic_art.gd").pbr("quatrefoil_jacquard_fabric",.7)
	game._box(root,Vector3(0,1.09,-.9),Vector3(1.2,.15,.55),Color(.48,.43,.32))
	slots.append({"pos":p,"entry":p+Vector3(0,0,2).rotated(Vector3.UP,angle),"eye":p+Vector3(0,.25,.2).rotated(Vector3.UP,angle),"angle":angle,"kind":"bed"})
	leaves.append(null)
	occupied.append(false)
	game._sign("UNDER BED / USE",p+Vector3(0,1.8,0))

func _door(spec: Dictionary):
	var root=Node3D.new()
	game.world.add_child(root)
	root.position=spec.pos
	root.rotation.y=PI/2 if spec.axis==0 else 0
	var blocker=panel(root,Vector3(0,1.7,0),Vector3(3,3.4,.16),true)
	blocker.visible=false
	var pivot=Node3D.new()
	root.add_child(pivot)
	pivot.position=Vector3(-1.5,0,0)
	panel(pivot,Vector3(1.5,1.7,0),Vector3(3,3.4,.13))
	for x in [.15,1.5,2.85]: panel(pivot,Vector3(x,1.7,.09),Vector3(.08,3.1,.06))
	for y in [.16,1.1,2.3,3.23]: panel(pivot,Vector3(1.5,y,.09),Vector3(2.8,.08,.06))
	game._box(pivot,Vector3(2.7,1.3,.17),Vector3(.1,.25,.1),Color(.55,.4,.16))
	game._sign(spec.name+" / DOOR",spec.pos+Vector3(0,3.5,0))
	doors.append({"pivot":pivot,"shape":blocker.get_child(0).get_child(0),"tween":null})
	opened.append(true)

func crosses(spec: Dictionary,a: Vector3,b: Vector3) -> bool:
	var axis=int(spec.axis)
	var da=a[axis]-spec.pos[axis]
	var db=b[axis]-spec.pos[axis]
	if da*db>0 or absf(da-db)<.00001: return false
	var p=a.lerp(b,da/(da-db))
	var width_axis=2 if axis==0 else 0
	return absf(p[width_axis]-spec.pos[width_axis])<1.65 and p.y>spec.pos.y-1.0 and p.y<spec.pos.y+3.5

func blocks(a: Vector3,b: Vector3) -> bool:
	for i in range(DOORS.size()):
		if not opened[i] and crosses(DOORS[i],a,b): return true
	return false

func reset():
	clues=[]
	journal.hide()
	notice=""
	local_hidden=false
	for i in range(opened.size()): opened[i]=not is_instance_valid(game.dawn) or i not in [6,7]
	apply_doors(false)
	for i in range(occupied.size()):
		occupied[i]=false
		if leaves[i]!=null: leaves[i].rotation.y=0

func apply_doors(animate=true):
	for i in range(doors.size()):
		var d=doors[i]
		d.shape.set_deferred("disabled",opened[i])
		var angle=-PI/2 if opened[i] else 0.0
		if d.tween!=null and d.tween.is_running(): d.tween.kill()
		if animate:
			d.tween=create_tween()
			d.tween.tween_property(d.pivot,"rotation:y",angle,.3)
		else: d.pivot.rotation.y=angle
		for edge in door_edges[i]:
			if opened[i] and not game.navigation.are_points_connected(edge.x,edge.y): game.navigation.connect_points(edge.x,edge.y)
			elif not opened[i] and game.navigation.are_points_connected(edge.x,edge.y): game.navigation.disconnect_points(edge.x,edge.y)

func receive(door_state: Array,read_clues: Array):
	if door_state!=opened:
		opened=door_state.duplicate()
		apply_doors()
	clues=read_clues.duplicate()
	var local_player=game.people.get(game.multiplayer.get_unique_id(),{})
	if local_player.get("hidden",false) and not local_hidden: game.yaw=PI+slots[local_player.hide_slot].angle; game.pitch=0.0
	local_hidden=local_player.get("hidden",false)
	if journal.visible: update_journal()
	for i in range(slots.size()):
		var used=false
		for p in game.people.values():
			if p.hidden and p.get("hide_slot",-1)==i: used=true
		if occupied[i]!=used and leaves[i]!=null:
			var leaf=leaves[i]
			var tween=create_tween()
			if used:
				leaf.rotation.y=-1.3
				tween.tween_property(leaf,"rotation:y",0.0,.65)
			else:
				tween.tween_property(leaf,"rotation:y",-1.3,.25)
				tween.tween_interval(.8)
				tween.tween_property(leaf,"rotation:y",0.0,.5)
		occupied[i]=used

func near_door(p: Vector3) -> int:
	for i in range(DOORS.size()):
		if p.distance_to(DOORS[i].pos)<2.3: return i
	return -1

func toggle_door(id: int,index: int):
	if index in [6,7] and not game.found.has(6):
		game.interaction_notice.rpc_id(id,"The crypt ward fits this door.")
		game.exploration.disturb(game.people[id].pos)
		return
	var spec=DOORS[index]
	if opened[index]:
		# Never close a solid slab through a survivor or the ghost.
		var positions=[game.ghost_pos]
		for player in game.people.values(): positions.append(player.pos)
		for pos in positions:
			if absf(pos[spec.axis]-spec.pos[spec.axis])<.65 and pos.distance_to(spec.pos)<2.0:
				game.interaction_notice.rpc_id(id,"Doorway blocked. Step clear before closing.")
				return
	opened[index]=not opened[index]
	apply_doors()
	game.exploration.disturb(game.people[id].pos)
	game.sound_event.rpc(spec.pos,.55,"door")

func clue_text(index: int) -> String:
	return [
	 "October 17.\n\nIf you are reading this, she let you climb the stairs. Eleanor still thinks the children are sleeping. Every creak is a little footstep to her. Every opened drawer is a child she cannot find.\n\nI heard her singing to an empty cradle. I hid what I could among the things she would never throw away. Twelve iron teeth, each fitting another lock. He locked one memory inside another. Where she once fed them, the brass begins the chain; the portraits hide what the family could not face. The garage and the ignition must both turn. Leave together before six.\n\nDo not let her see where you hide. Close the room door before you search. She cannot cross it, but she remembers.",
	 "Her diary.\n\nI fold their clothes every morning. They will need them when they wake. The small wooden horse has lost a wheel. I must not move their things.\n\nHe said the house was cold. He took his tools below. I heard metal sliding over metal long after the fire went out.",
	 "A soot-stained page.\n\nShe keeps warm rooms for children who never return. I keep a furnace that never burns. Below us lie the things the family could not bear to bury outside.\n\nI put our last chance among their keepsakes. May someone living turn it again."
	][index]

func update_journal():
	var text="[center][font_size=30]The papers we carried[/font_size][/center]\n\n"
	if clues.is_empty(): text+="No pages found. Only the silence upstairs.\n\n"
	for i in clues: text+=clue_text(i)+"\n\n"
	text+="[center]— In our pockets —[/center]\n"
	text+="Keys: "+str(game.found.size())+" / 12     Garage: "+("open" if game.door_open else "locked")
	var p=game.people.get(game.multiplayer.get_unique_id(),{})
	text+="\nBottles: "+str(p.get("bottles",0))+"     Papers: "+str(clues.size())+" / 3"
	journal_text.text=text

func show_journal():
	if game.phase!="playing": return
	update_journal()
	game.touch_move=Vector2.ZERO
	game.move_finger=-1
	game.look_finger=-1
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	journal.popup_centered(Vector2i(900,520))

func prompt(id: int) -> String:
	var p=game.people[id]
	if p.hidden: return "USE — leave "+slots[p.hide_slot].kind+"  |  Look through the gap"
	if Time.get_ticks_msec()<notice_until: return notice
	var d=near_door(p.pos)
	if d>=0: return "USE — "+("close " if opened[d] else "open ")+DOORS[d].name+" door"
	for i in range(NOTES.size()):
		if p.pos.distance_to(NOTES[i])<2.2: return "USE — read "+["the letter in the dead man's coat","nursery diary","soot-stained page"][i]
	for slot in slots:
		if p.pos.distance_to(slot.entry)<2.0: return "USE — "+("enter cupboard and close it" if slot.kind=="cupboard" else "crawl under bed")
	return ""

func use(id: int) -> bool:
	var p=game.people[id]
	if p.hidden:
		p.hidden=false
		p.pos=p.hide_exit
		game.actors[id].position=p.pos
		p.hide_slot=-1
		game.sound_event.rpc(p.pos,.25,"door")
		return true
	var d=near_door(p.pos)
	if d>=0:
		toggle_door(id,d)
		return true
	for i in range(NOTES.size()):
		if p.pos.distance_to(NOTES[i])<2.2 and game._line_clear(p.pos,NOTES[i]):
			if not clues.has(i):
				clues.append(i)
				game.dawn.announce.rpc(game.people[id].name+" recovered "+["the keeper's letter","a diary page","a soot-stained page"][i]+".",game.round_id)
			game.interaction_notice.rpc_id(id,"A page recovered. Open the paper icon to read it.")
			game.sound_event.rpc(p.pos,.3,"key")
			return true
	for i in range(slots.size()):
		var slot=slots[i]
		if p.pos.distance_to(slot.entry)>=2.0 or not game._line_clear(p.pos,slot.entry): continue
		for other in game.people.values():
			if other.hidden and other.hide_slot==i:
				game.interaction_notice.rpc_id(id,"Someone is already hiding here.")
				return true
		if game.grace<=0 and game.ghost_pos.distance_to(p.pos)<game._difficulty().vision and game._line_clear(game.ghost_pos,p.pos):
			game.witnessed_hides[id]=Time.get_ticks_msec()+15000
		p.hide_exit=p.pos
		p.hidden=true
		p.hide_slot=i
		p.pos=slot.pos
		game.actors[id].position=p.pos
		game.sound_event.rpc(slot.pos,.22,"door" if slot.kind=="cupboard" else "foot_wood")
		return true
	return false

func hide_camera(p: Dictionary):
	if not p.hidden or p.hide_slot<0: return
	var slot=slots[p.hide_slot]
	game.camera.position=slot.eye
	# A restricted peek prevents looking through the back/sides of the furniture.
	game.camera.rotation=Vector3(clampf(game.pitch,-.13,.13) if slot.kind=="cupboard" else clampf(game.pitch,-.08,.18),PI+slot.angle+clampf(wrapf(game.yaw-PI-slot.angle,-PI,PI),-.55,.55),0)

func threat() -> float:
	if game.phase!="playing" or game.grace>0: return 0.0
	var d=game.camera.position.distance_to(game.ghost_pos+Vector3.UP)
	return clampf(1-d/15.0,0,1)*(.35 if blocks(game.camera.position,game.ghost_pos+Vector3.UP) else 1.0)
