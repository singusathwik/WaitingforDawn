extends RefCounted
## Shared materials and authored Blender models, used by the actual playable rooms.
static var cache: Dictionary={}
static func model(parent: Node3D,asset: String,p: Vector3=Vector3.ZERO,angle: float=0) -> Node3D:
	var instance=load("res://assets/models/repair/"+asset+".glb").instantiate()
	parent.add_child(instance)
	instance.position=p
	instance.rotation.y=angle
	for mesh in preload("res://realistic_art.gd").meshes(instance):
		for i in range(mesh.mesh.get_surface_count()):
			var material=mesh.mesh.surface_get_material(i)
			if not material: continue
			var title=material.resource_name
			if title=="Faded green enamel":
				if not cache.has(title):
					var m=ShaderMaterial.new();m.shader=load("res://shaders/aged_enamel.gdshader")
					m.set_shader_parameter("grime",load("res://assets/textures/rough_plaster_broken/diff.jpg"))
					cache[title]=m
				mesh.set_surface_override_material(i,cache[title])
			if title=="Dusty glass" and asset=="car":
				var m=material.duplicate();m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
				m.albedo_color=Color(.08,.11,.12,.65);m.roughness=.28;m.cull_mode=BaseMaterial3D.CULL_DISABLED
				mesh.set_surface_override_material(i,m)
			if title in ["Exterior masonry","Roof slate"]:
				if not cache.has(title):
					var m=preload("res://realistic_art.gd").pbr("rough_plaster_broken",.32)
					m.albedo_color=Color(.42,.44,.40) if title=="Exterior masonry" else Color(.075,.09,.1)
					cache[title]=m
				mesh.set_surface_override_material(i,cache[title])
			if title in ["Worn oak","Old textile"]:
				if not cache.has(title):
					var mat=StandardMaterial3D.new()
					mat.albedo_texture=load("res://assets/textures/worn-oak.png" if title=="Worn oak" else "res://assets/textures/quatrefoil_jacquard_fabric/diff.jpg")
					mat.albedo_color=Color(.45,.46,.42) if title=="Worn oak" else Color(.4,.37,.30)
					mat.roughness=.93
					cache[title]=mat
				mesh.set_surface_override_material(i,cache[title])
	return instance

static func furnish(game):
	var facade=model(game.world,"facade")
	for mesh in preload("res://realistic_art.gd").meshes(facade): mesh.layers=2
	var moon=DirectionalLight3D.new()
	game.world.add_child(moon)
	moon.rotation_degrees=Vector3(-38,-25,0)
	moon.light_color=Color(.43,.56,.7)
	moon.light_energy=.7
	moon.light_cull_mask=2
	moon.shadow_enabled=false
	# Exterior surfaces receive moonlight without brightening the dark basements.
	for spec in [[Vector3(16.5,1.8,40.56),Vector3(36,3.6,.08)],[Vector3(48,1.8,40.56),Vector3(3,3.6,.08)]]:
		var wall=game._box(game.world,spec[0],spec[1],Color(.26,.27,.23))
		wall.material_override=preload("res://realistic_art.gd").pbr("rough_plaster_broken",.35)
		wall.material_override.albedo_color=Color(.35,.38,.34)
		wall.layers=2
	for node in game.world.get_children():
		if node is MeshInstance3D and node.has_meta("outdoor_ground"): node.layers=2
	var car=model(game.world,"car",Vector3(42,0,33))
	game.escape_car=car
	car.name="GarageEstateCar"
	var collider=game._box(car,Vector3(0,.75,0),Vector3(1.85,1.5,4.8),Color.BLACK,true)
	collider.hide()
	model(game.world,"kitchen",Vector3(39,0,3))
	var tiles=MeshInstance3D.new();tiles.mesh=PlaneMesh.new();tiles.mesh.size=Vector2(18,12)
	game.world.add_child(tiles);tiles.position=Vector3(36,.018,8)
	var tile_mat=ShaderMaterial.new();tile_mat.shader=load("res://shaders/dirty_tiles.gdshader")
	tile_mat.set_shader_parameter("dirt",load("res://assets/textures/rough_plaster_broken/diff.jpg"));tiles.material_override=tile_mat
	var concrete=game._box(game.world,Vector3(36,.015,32),Vector3(20,.018,12),Color(.2,.21,.18))
	concrete.material_override=preload("res://realistic_art.gd").pbr("rough_plaster_broken",.35)
	concrete.material_override.albedo_color=Color(.28,.28,.23)
	for p in [Vector3(4,0,2),Vector3(20,0,27),Vector3(28,5,1),Vector3(43,10,1),Vector3(29,-5,22)]:
		var shelf=model(game.world,"shelf",p)
		var blocker=game._box(shelf,Vector3(0,1.2,0),Vector3(1.7,2.4,.5),Color.BLACK,true)
		blocker.hide()
		blocker.get_child(0).set_meta("impact",true)
	for p in [Vector3(12,0,2),Vector3(30,0,2),Vector3(40,5,0),Vector3(32,10,0)]: model(game.world,"radiator",p)
	for p in [Vector3(12,0,9),Vector3(18,0,30),Vector3(39,0,9),Vector3(30,5,12),Vector3(36,10,6),Vector3(15,-5,33),Vector3(39,-5,27),Vector3(9,-10,33)]:
		model(game.world,"debris",p)
		var rug=game._box(game.world,p+Vector3(0,.012,0),Vector3(5,.018,3.6),Color(.23,.14,.09))
		rug.material_override=preload("res://realistic_art.gd").pbr("quatrefoil_jacquard_fabric",.15)
		rug.material_override.albedo_color=Color(.35,.32,.27)
		for x in [-2.35,2.35]: game._box(game.world,p+Vector3(x,.032,0),Vector3(.06,.008,3.3),Color(.25,.20,.11))
		for z in [-1.65,1.65]: game._box(game.world,p+Vector3(0,.032,z),Vector3(4.7,.008,.06),Color(.25,.20,.11))
	# Furniture left in human arrangements, plus toppled chairs in circulation areas.
	for p in [Vector3(17,0,11),Vector3(20,0,11),Vector3(29,0,11),Vector3(39,5,16),Vector3(39,10,16),Vector3(9,-5,36)]:
		preload("res://realistic_art.gd").place(game.world,"ArmChair_01",p,1.15,.5)
		var blocker=game._box(game.world,p+Vector3(0,.5,0),Vector3(.9,1,.85),Color.BLACK,true)
		blocker.hide();blocker.get_child(0).set_meta("impact",true)
	# A readable lock plate and slatted garage gate; both use the authoritative garage state.
	for y in range(10):
		var rib=game._box(game.door,Vector3(0,-1.35+y*.3,-.18),Vector3(2.72,.045,.08),Color(.18,.21,.2))
		var material=StandardMaterial3D.new();material.albedo_color=Color(.21,.23,.21);material.metallic=.7;material.roughness=.7;rib.material_override=material
	game._box(game.door,Vector3(.9,-.15,-.23),Vector3(.25,.42,.06),Color(.45,.32,.12))
	game._box(game.door,Vector3(.9,-.15,-.27),Vector3(.045,.10,.012),Color(.01,.009,.006))
	game.garage_exit=Node3D.new()
	game.garage_exit.name="OutsideGarageDoor"
	game.world.add_child(game.garage_exit)
	game.garage_exit.position=Vector3(40.5,0,39)
	var shutter=game._box(game.garage_exit,Vector3(0,1.7,0),Vector3(12,3.4,.22),Color(.16,.18,.16),true)
	shutter.material_override=preload("res://realistic_art.gd").pbr("rough_plaster_broken",.45)
	shutter.material_override.albedo_color=Color(.25,.28,.26)
	shutter.material_override.metallic=.65
	shutter.layers=3
	game.garage_exit_shape=shutter.get_child(0).get_child(0)
	for y in range(17):
		for side in [-1,1]:
			var rib=game._box(game.garage_exit,Vector3(0,.1+y*.2,side*.15),Vector3(11.95,.04,.06),Color(.23,.25,.21))
			rib.layers=3
	# The fixed key plate stays reachable while the shutter rolls upward.
	game._box(game.world,Vector3(46.65,1.5,38.8),Vector3(.2,3,.3),Color(.17,.18,.15),true)
	game._box(game.world,Vector3(44.7,.65,38.8),Vector3(.18,1.3,.18),Color(.15,.17,.15),true)
	game._box(game.world,Vector3(44.7,1.3,38.6),Vector3(.32,.48,.10),Color(.46,.32,.13))
	game._box(game.world,Vector3(44.7,1.3,38.53),Vector3(.055,.14,.02),Color(.012,.01,.006))
	# Water stains, displaced trim and dark corners break up the clean flat room surfaces.
	for p in [Vector3(7,.8,1.55),Vector3(19,1.2,1.55),Vector3(30,1.1,1.55),Vector3(44,.6,1.55),Vector3(34,6.3,-1.31),Vector3(43,11,-1.31)]:
		var patch=game._box(game.world,p,Vector3(1.8,1.4,.02),Color(.12,.14,.1))
		patch.material_override=preload("res://realistic_art.gd").pbr("rough_plaster_broken",.9)
	for p in [Vector3(15,2.9,18),Vector3(33,2.9,18),Vector3(36,7.9,9),Vector3(36,12.9,9),Vector3(54.5,7.8,14)]:
		game.atmosphere._fixture(p,Color(.9,.64,.32))
