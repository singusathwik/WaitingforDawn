extends Node
## Host-owned interactions. Peers receive state; geometry and camera presentation are local.
const DOORS = [
	{"pos":Vector3(9,0,15),"axis":2,"name":"Parlour"},
	{"pos":Vector3(33,0,15),"axis":2,"name":"Kitchen"},
	{"pos":Vector3(9,0,24),"axis":2,"name":"Mourning room"},
	{"pos":Vector3(24,0,9),"axis":0,"name":"East hallway"},
	{"pos":Vector3(24,5,9),"axis":0,"name":"Nursery"},
	{"pos":Vector3(24,-5,30),"axis":0,"name":"Boiler room"},
	{"pos":Vector3(12,-5,40.5),"axis":2,"name":"Crypt stair"},
	{"pos":Vector3(12,-10,40.5),"axis":2,"name":"Crypt"},
	{"pos":Vector3(22.5,5,9),"axis":0,"name":"Nursery east"},
	{"pos":Vector3(22.5,-5,30),"axis":0,"name":"Service passage"}
]
const NOTES = [Vector3(18,5,6),Vector3(6,5,12),Vector3(6,-5,33)]
const BEDS = [Vector3(15,0,33),Vector3(15,5,15),Vector3(15,-5,36)]
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
var door_focus: MeshInstance3D

func setup(g):
	game=g
	wood=StandardMaterial3D.new()
	wood.albedo_texture=load("res://assets/textures/worn-oak.png")
	wood.albedo_color=Color(.48,.46,.4)
	wood.roughness=.95
	door_focus=MeshInstance3D.new()
	var ring=TorusMesh.new();ring.inner_radius=.055;ring.outer_radius=.075;ring.rings=16;ring.ring_segments=8
	door_focus.mesh=ring
	var glow=StandardMaterial3D.new();glow.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;glow.albedo_color=Color(.9,.8,.5)
	door_focus.material_override=glow
	game.world.add_child(door_focus);door_focus.hide()
	for p in game._hiding_spots(): _cupboard(p)
	for p in BEDS: _bed(p)
	for spec in DOORS: _door(spec)
	for i in range(NOTES.size()):
		if i<2: continue # Keeper and diary meshes are part of the approved native room.
		var p=NOTES[i]
		if i!=0: panel(game.world,p+Vector3(0,0.55,0),Vector3(0.8,1.1,0.5))
		var paper=game._box(game.world,p+Vector3(0,.35 if i==0 else 1.13,0),Vector3(0.6,0.025,0.4),Color(.7,.62,.42))
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
	if p==Vector3(6,5,6):
		game.nursery.register_hiding(self,"cupboard",p)
		return
	var angle=PI/2 if p.x<40 or p.x>60 else -PI/2
	var root=Node3D.new()
	game.world.add_child(root)
	root.position=p
	root.rotation.y=angle
	for x in [-.83,.83]: panel(root,Vector3(x,1.15,0),Vector3(0.12,2.3,1.5),true)
	panel(root,Vector3(0,1.15,-0.72),Vector3(1.7,2.3,0.1),true)
	for y in [.06,2.3]: panel(root,Vector3(0,y,0),Vector3(1.85,0.12,1.6))
	var front_blocker=panel(root,Vector3(0,1.15,0.73),Vector3(1.6,2.3,0.09),true)
	front_blocker.visible=false
	var hinge=Node3D.new()
	root.add_child(hinge)
	hinge.position=Vector3(-0.8,0,0.73)
	# A real eye-level aperture, not an opaque replacement screen.
	panel(hinge,Vector3(0.8,0.73,0),Vector3(1.6,1.46,0.09))
	panel(hinge,Vector3(0.8,1.93,0),Vector3(1.6,0.74,0.09))
	for x in [.06,1.54]: panel(hinge,Vector3(x,1.51,0),Vector3(0.12,0.1,0.09))
	for x in [.12,1.48]:
		for y in [.65,1.97]: panel(hinge,Vector3(x,y,.06),Vector3(0.05,0.95,0.04))
	for y in [.19,1.12,1.72,2.2]: panel(hinge,Vector3(.8,y,.06),Vector3(1.4,0.05,0.04))
	for child in root.get_children():
		if child is MeshInstance3D:child.hide()
	for child in hinge.get_children():
		if child is MeshInstance3D:child.hide()
	preload("res://repaired_art.gd").model(root,"wardrobe_case")
	preload("res://repaired_art.gd").model(hinge,"wardrobe_leaf")
	leaves.append(hinge)
	slots.append({"pos":p,"entry":p+Vector3(0,0,1.6).rotated(Vector3.UP,angle),"eye":p+Vector3(0,1.51,0.43).rotated(Vector3.UP,angle),"angle":angle,"kind":"cupboard"})
	occupied.append(false)
	game._sign("CUPBOARD / USE",p+Vector3(0,2.6,0))

func _bed(p: Vector3):
	if p==Vector3(15,5,15):
		game.nursery.register_hiding(self,"bed",p)
		return
	var angle=PI if p.y==0 else -PI/2
	var root=Node3D.new()
	game.world.add_child(root)
	root.position=p
	root.rotation.y=angle
	for x in [-.85,.85]:
		for z in [-1.3,1.3]: panel(root,Vector3(x,.45,z),Vector3(0.13,0.9,0.13),true)
	panel(root,Vector3(0,0.72,0),Vector3(1.9,0.15,2.9),true)
	panel(root,Vector3(0,1.1,-1.4),Vector3(2,1.3,0.12),true)
	for child in root.get_children():
		if child is MeshInstance3D: child.hide()
	preload("res://repaired_art.gd").model(root,"bed")
	slots.append({"pos":p,"entry":p+Vector3(0,0,2).rotated(Vector3.UP,angle),"eye":p+Vector3(0,0.25,0.2).rotated(Vector3.UP,angle),"angle":angle,"kind":"bed"})
	leaves.append(null)
	occupied.append(false)
	game._sign("UNDER BED / USE",p+Vector3(0,1.8,0))

func _door(spec: Dictionary):
	var root=Node3D.new()
	game.world.add_child(root)
	root.position=spec.pos
	root.rotation.y=PI/2 if spec.axis==0 else 0
	var blocker=panel(root,Vector3(0,1.7,0),Vector3(3,3.4,0.16),true)
	blocker.visible=false
	var pivot=Node3D.new()
	root.add_child(pivot)
	pivot.position=Vector3(-1.5,0,0)
	var leaf=preload("res://repaired_art.gd").model(pivot,"door",Vector3(.15,0,0))
	for side in [-1,1]: panel(root,Vector3(side*1.55,1.75,0),Vector3(.12,3.5,.28))
	panel(root,Vector3(0,3.46,0),Vector3(3.2,.14,.28))
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
	game.nursery.wardrobe(false,false)
	clues=[]
	journal.hide()
	notice=""
	local_hidden=false
	for i in range(opened.size()): opened[i]=not is_instance_valid(game.dawn) or i not in [0,1,2,6,7]
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
		if occupied[i]!=used and slots[i].pos==Vector3(6,5,6): game.nursery.wardrobe(used)
		occupied[i]=used

func near_door(p: Vector3) -> int:
	for i in range(DOORS.size()):
		if p.distance_to(DOORS[i].pos)<2.3: return i
	return -1

func target_door(id: int) -> int:
	var p=game.people[id]
	var view_yaw=game.yaw if id==game.multiplayer.get_unique_id() else game.commands.get(id,{}).get("yaw",p.yaw)
	var forward=Vector3(0,0,-1).rotated(Vector3.UP,view_yaw)
	var best=-1;var score=INF
	for i in range(doors.size()):
		if absf(p.pos.y-DOORS[i].pos.y)>.75:continue
		var handle=doors[i].pivot.to_global(Vector3(2.53,1.35,0))
		var offset=handle-(p.pos+Vector3(0,1.35,0))
		var d=offset.length()
		if d>3.0 or (d>.75 and forward.dot(offset.normalized())<.15):continue
		var query=PhysicsRayQueryParameters3D.create(p.pos+Vector3(0,1.5,0),handle,1)
		query.exclude=[doors[i].shape.get_parent().get_rid()]
		if not game.get_world_3d().direct_space_state.intersect_ray(query).is_empty():continue
		var rank=d*(1.4-forward.dot(offset.normalized()))
		if rank<score:score=rank;best=i
	return best

func door_prompt(index: int) -> String:
	return "USE — "+("close " if opened[index] else "open ")+DOORS[index].name+" door"

func _process(_delta):
	if not is_instance_valid(door_focus):return
	var id=game.multiplayer.get_unique_id()
	var target=target_door(id) if game.phase=="playing" and game.people.has(id) and not game.people[id].hidden else -1
	door_focus.visible=target>=0 and game.exploration.intro_left<=0
	if target>=0:
		var handle=doors[target].pivot.to_global(Vector3(2.53,1.4,0))
		# Offset toward the viewer: the ring must sit outside either face of the leaf.
		door_focus.global_position=handle+(game.camera.global_position-handle).normalized()*.22
		door_focus.look_at(game.camera.global_position,Vector3.UP)
		door_focus.rotate_object_local(Vector3.RIGHT,PI/2)

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
	var d=target_door(id)
	if d>=0: return door_prompt(d)
	for i in range(NOTES.size()):
		if p.pos.distance_to(NOTES[i])<2.2: return "USE — read "+["the letter in the dead man's coat","nursery diary","soot-stained page"][i]
	for slot in slots:
		if p.pos.distance_to(slot.entry)<2.0: return "USE — "+("enter cupboard and close it" if slot.kind=="cupboard" else "crawl under bed")
	return notice if Time.get_ticks_msec()<notice_until else ""

func use(id: int) -> bool:
	var p=game.people[id]
	if p.hidden:
		p.hidden=false
		p.pos=p.hide_exit
		game.actors[id].position=p.pos
		p.hide_slot=-1
		game.sound_event.rpc(p.pos,.25,"door")
		return true
	var hiding=aimed_hiding(id)
	var d=target_door(id) if hiding<0 else -1
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

func aimed_hiding(id: int) -> int:
	var p=game.people[id]
	if p.hidden: return p.hide_slot
	var view_yaw=game.yaw if id==game.multiplayer.get_unique_id() else game.commands.get(id,{}).get("yaw",p.yaw)
	var direction=Vector3(0,0,-1).rotated(Vector3.UP,view_yaw)
	for i in range(slots.size()):
		var slot=slots[i]
		var delta=slot.pos-p.pos
		if p.pos.distance_to(slot.entry)<1.9 and absf(p.pos.y-slot.pos.y)<.4 and direction.dot(delta.normalized())>.55: return i
	return -1
