extends Node3D
## Approved native room. Presentation parts bind to the existing host-owned state.
var game
var parts: Dictionary = {}
var wardrobe_tween: Tween
var baked_material: StandardMaterial3D
var last_brightness=-1.0

func build(g):
	game=g
	name="EleanorsNursery"
	position=Vector3(12,5,9)
	var model=load("res://assets/models/nursery/nursery.glb").instantiate()
	add_child(model)
	var material=StandardMaterial3D.new()
	baked_material=material
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	var config=ConfigFile.new()
	config.load("user://settings.cfg")
	set_texture_detail(config.get_value("settings","low_textures",false) or OS.get_cmdline_user_args().has("--nursery-low"))
	material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	for mesh in preload("res://realistic_art.gd").meshes(model):
		parts[String(mesh.name)]=mesh
		mesh.material_override=material
		if mesh.name=="Room_static": mesh.create_trimesh_collision()
	# The original preserved box was a solid block. Keep its binding, replace the
	# presentation with the hollow Blender tray used by the rest of the house.
	var old_box=parts["Search_box"]
	old_box.hide()
	var box=Node3D.new();add_child(box);box.position=old_box.position
	var tray=preload("res://repaired_art.gd").model(box,"drawer")
	tray.scale=Vector3(1,.8/.58,.8/.75)
	parts["Search_box"]=box
	# Hiding teleports through this closed front, matching other cupboards. The actual
	# eye slit remains open in the rendered mesh; no visual proxy covers it.
	blocker(Vector3(-5.24,1.2,-3),Vector3(0.1,2.4,1.7))
	for p in [Vector3(-3,0.78,-6),Vector3(6,0.78,6)]: blocker(p,Vector3(3.4,1.5,0.75))
	blocker(Vector3(-3,0.4,6),Vector3(1,0.8,0.8))

func set_texture_detail(low: bool):
	baked_material.albedo_texture=load("res://assets/models/nursery/nursery-lit-low.png" if low else "res://assets/models/nursery/nursery-lit.png")

func _process(_delta):
	if game and not is_equal_approx(last_brightness,game.brightness):
		last_brightness=game.brightness
		baked_material.albedo_color=Color(last_brightness/.65,last_brightness/.65,last_brightness/.65)

func blocker(p: Vector3,size: Vector3):
	var body=StaticBody3D.new()
	add_child(body)
	body.position=p
	body.set_meta("impact",true)
	var shape=CollisionShape3D.new()
	shape.shape=BoxShape3D.new()
	shape.shape.size=size
	body.add_child(shape)

func drawer(index: int) -> Node3D:
	return parts["Drawer_"+str(index)]

func register_hiding(horror,kind: String,p: Vector3):
	var angle=PI/2 if kind=="cupboard" else -PI/2
	horror.slots.append({"pos":p,"entry":p+Vector3(0,0,1.6 if kind=="cupboard" else 2).rotated(Vector3.UP,angle),"eye":p+Vector3(0,1.51 if kind=="cupboard" else .25,.43 if kind=="cupboard" else .2).rotated(Vector3.UP,angle),"angle":angle,"kind":kind})
	horror.leaves.append(null)
	horror.occupied.append(false)

func wardrobe(used: bool,animate: bool=true):
	if wardrobe_tween and wardrobe_tween.is_running(): wardrobe_tween.kill()
	var left=parts["Wardrobe_leaf_left"]
	var right=parts["Wardrobe_leaf_right"]
	if not animate:
		left.rotation.y=0
		right.rotation.y=0
		return
	wardrobe_tween=create_tween().set_parallel(true)
	if used:
		left.rotation.y=-1.2
		right.rotation.y=1.2
		wardrobe_tween.tween_property(left,"rotation:y",0.0,.65)
		wardrobe_tween.tween_property(right,"rotation:y",0.0,.65)
	else:
		wardrobe_tween.tween_property(left,"rotation:y",-1.2,.25)
		wardrobe_tween.tween_property(right,"rotation:y",1.2,.25)
		wardrobe_tween.chain().tween_interval(.8)
		wardrobe_tween.chain().tween_property(left,"rotation:y",0.0,.5)
		wardrobe_tween.parallel().tween_property(right,"rotation:y",0.0,.5)

func fixtures(atmosphere):
	# Positions and colours match lighting-manifest.json. The baked scene supplies
	# indirect light; these bounded real lights illuminate characters in the room.
	var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/models/nursery/lighting-manifest.json"))
	for fixture in manifest.fixtures:
		if fixture.role!="practical": continue
		var light=OmniLight3D.new()
		add_child(light)
		var p=fixture.location
		var c=fixture.color
		light.position=Vector3(p[0],p[2],-p[1])
		light.light_color=Color(c[0],c[1],c[2])
		light.light_energy=.48
		light.omni_range=7
		light.set_meta("base_energy",.48)
		atmosphere.fixtures.append(light)

func prune_navigation():
	# Navigation must reserve the same body width as the player, including doorway edges.
	var query=PhysicsShapeQueryParameters3D.new()
	var capsule=CapsuleShape3D.new()
	capsule.radius=.31
	capsule.height=1.7
	query.shape=capsule
	query.collision_mask=1
	var space=game.world.get_world_3d().direct_space_state
	for id in game.navigation.get_point_ids():
		var p=game.navigation.get_point_position(id)
		if p.y!=5 or p.x<1 or p.x>23 or p.z< -2 or p.z>20: continue
		query.transform=Transform3D(Basis.IDENTITY,p+Vector3(0,0.9,0))
		query.motion=Vector3.ZERO
		var overlap=space.intersect_shape(query,1)
		if not overlap.is_empty():
			game.navigation.set_point_disabled(id,true)
		for other in game.navigation.get_point_connections(id):
			var destination=game.navigation.get_point_position(other)
			# Existing stair links approximate foot height; their physics follows the
			# ramp surface. Keep their tested connectors out of this flat-room sweep.
			if not is_equal_approx(destination.y,5.0): continue
			query.motion=destination-p
			var result=space.cast_motion(query)
			if result[0]<.99: game.navigation.disconnect_points(id,other)

func seed_navigation():
	# The old 3 m grid misses the approved offset 2.4 m doorways. A 1.5 m grid
	# supplies actual intermediate routes; physics pruning removes blocked nodes/edges.
	for x in range(15):
		for z in range(15): game._nav_add(Vector3(1.5+x*1.5,5,-1.5+z*1.5))
	for x in range(15):
		for z in range(15):
			var p=Vector3(1.5+x*1.5,5,-1.5+z*1.5)
			for offset in [Vector3(1.5,0,0),Vector3(0,0,1.5)]:
				if game.nav_ids.has(p+offset): game.navigation.connect_points(game.nav_ids[p],game.nav_ids[p+offset])
