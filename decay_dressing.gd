extends RefCounted
## Authored clusters sit beside circulation lanes; thin litter never blocks walking.
static var materials={}
static func place(g,asset: String,p: Vector3,angle: float=0,solid_size: Vector3=Vector3.ZERO):
	var item=load("res://assets/models/decay/"+asset+".glb").instantiate()
	g.world.add_child(item);item.name="Decay_"+asset;item.position=p;item.rotation.y=angle
	for mesh in preload("res://realistic_art.gd").meshes(item):
		for i in range(mesh.mesh.get_surface_count()):
			var source=mesh.mesh.surface_get_material(i)
			if not source:continue
			var title=source.resource_name
			if title in ["Splintered oak","Faded upholstery"]:
				if not materials.has(title):
					var mat=StandardMaterial3D.new();mat.roughness=.98
					mat.albedo_texture=load("res://assets/textures/worn-oak.png" if title=="Splintered oak" else "res://assets/textures/quatrefoil_jacquard_fabric/diff.jpg")
					mat.albedo_color=Color(.35,.33,.26) if title=="Faded upholstery" else Color(.38,.36,.29)
					materials[title]=mat
				mesh.set_surface_override_material(i,materials[title])
	if solid_size!=Vector3.ZERO:
		var blocker=g._box(item,Vector3(0,solid_size.y/2,0),solid_size,Color.BLACK,true)
		blocker.hide();blocker.get_child(0).set_meta("impact",true)
	return item

static func patch(g,p:Vector3,size:Vector2,angle:Vector3=Vector3.ZERO,index:float=0):
	var mesh=MeshInstance3D.new();mesh.mesh=PlaneMesh.new();mesh.mesh.size=size
	var material=ShaderMaterial.new();material.shader=load("res://shaders/decay_patch.gdshader")
	material.set_shader_parameter("seed",index*7.13);mesh.material_override=material
	g.world.add_child(mesh);mesh.position=p;mesh.rotation=angle
	mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

static func build(g):
	for p in [Vector3(15,0,3.4),Vector3(18,0,36.4),Vector3(17,10,3.4)]:
		place(g,"sofa",p,PI,Vector3(2.9,1.25,1.15))
	for p in [Vector3(16,0,7),Vector3(40,0,8),Vector3(15,0,30)]:
		place(g,"dining",p,.18,Vector3(2.4,.95,1.3))
	for p in [Vector3(18,0,5.7),Vector3(41.8,0,9.4),Vector3(17,0,31),Vector3(40,10,9),Vector3(15,-5,25)]:
		place(g,"fallen_chair",p,.55,Vector3(1.35,.72,.75))
	var patches=[Vector3(13,0,4),Vector3(18,0,7),Vector3(6,0,9),Vector3(39,0,6),Vector3(44,0,12),Vector3(15,0,32),Vector3(19,0,35),Vector3(29,0,19),Vector3(14,10,4),Vector3(39,10,6),Vector3(32,5,4),Vector3(42,5,15),Vector3(18,-5,25),Vector3(35,-5,33),Vector3(17,-10,28)]
	for i in range(patches.size()):
		var p:Vector3=patches[i]
		place(g,"litter",p,i*1.9)
		g.repair_layout.rattle_zones.append(p)
		patch(g,p+Vector3.UP*.045,Vector2(5,3.5),Vector3(0,i*.7,0),i)
	for p in [Vector3(16,5,12),Vector3(12,5,4),Vector3(7,5,16)]:
		var toys=place(g,"nursery_litter",p,.4)
		g.atmosphere.trembling_props.append(toys)
		patch(g,p+Vector3.UP*.048,Vector2(3.4,2.5),Vector3.ZERO,p.x)
	# Damp shapes with broken edges, not opaque rectangles on the wallpaper.
	for p in [Vector3(6,1.7,1.53),Vector3(18,1.2,1.53),Vector3(33,1.6,1.53),Vector3(43,1,1.53),Vector3(18,11.5,-1.28),Vector3(39,6.7,-1.28)]:
		patch(g,p,Vector2(3.2,3.3),Vector3(PI/2,0,0),p.x)
