extends RefCounted
## Imported art, separate from collision and host simulation.
static func pbr(asset: String,scale_uv: float=0.5) -> StandardMaterial3D:
	var mat=StandardMaterial3D.new()
	var base="res://assets/textures/"+asset+"/"
	mat.albedo_texture=load(base+"diff.jpg")
	mat.normal_enabled=true
	mat.normal_texture=load(base+"nor_gl.jpg")
	mat.normal_scale=.65
	mat.roughness_texture=load(base+"rough.jpg")
	mat.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_RED
	mat.uv1_triplanar=true
	mat.uv1_world_triplanar=true
	mat.uv1_scale=Vector3.ONE*scale_uv
	mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return mat

static func meshes(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D]=[]
	if node is MeshInstance3D: result.append(node)
	for child in node.get_children(): result.append_array(meshes(child))
	return result

static func place(parent: Node3D,asset: String,pos: Vector3,height: float,angle: float=0) -> Node3D:
	var instance=load("res://assets/models/"+asset+"/"+asset+".gltf").instantiate()
	parent.add_child(instance)
	var bounds=AABB()
	var first=true
	for mesh in meshes(instance):
		var aabb=instance.global_transform.affine_inverse()*mesh.global_transform*mesh.get_aabb()
		bounds=aabb if first else bounds.merge(aabb)
		first=false
	var factor=height/maxf(bounds.size.y,.01)
	var offset=Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)
	instance.scale=Vector3.ONE*factor
	instance.rotation.y=angle
	instance.position=pos-(offset*factor).rotated(Vector3.UP,angle)
	return instance

static func setup_house(game):
	var wallpaper=pbr("decrepit_wallpaper",.42)
	var wood=pbr("old_wooden_floor_01",.3)
	wood.albedo_color=Color(.48,.46,.41)
	wood.roughness=1.0
	var plaster=pbr("rough_plaster_broken",.38)
	for node in game.world.get_children():
		if not node is MeshInstance3D or not node.mesh is BoxMesh or node.has_meta("outdoor_ground"): continue
		var size=node.mesh.size
		if size.y>=3 and maxf(size.x,size.z)>=3:
			node.material_override=wallpaper if node.position.y>=0 else plaster
		elif size.y<.5 and minf(size.x,size.z)>10:
			node.material_override=wood if node.position.y<0.1 or is_equal_approx(node.position.y,4.8) else plaster
		elif size.x>10 or size.z>10: node.material_override=wood
		# Replace visual furniture only. Its stable collision shape remains active.
		if size.is_equal_approx(Vector3(2.4,1.3,1.4)) or size.is_equal_approx(Vector3(2.7,0.15,1.6)) or size.is_equal_approx(Vector3(0.8,1.1,0.8)) or size.is_equal_approx(Vector3(0.8,0.8,0.15)) or size.is_equal_approx(Vector3(1.6,2,1.2)):
			node.visible=false
		# Replace old flat rugs with timber; a rug asset can be introduced separately.
		if size.is_equal_approx(Vector3(6,0.03,4)) or size.is_equal_approx(Vector3(0.12,0.02,3.8)): node.visible=false
	for p in [Vector3(6,0,6),Vector3(33,0,6),Vector3(6,0,30)]:
		place(game.world,"ClassicConsole_01",p,1.3)
	for p in [Vector3(18,0,9),Vector3(36,0,12)]:
		place(game.world,"ArmChair_01",p,1.55,PI)
	# Interactive cupboards have hollow interiors and animated slotted doors.
	place(game.world,"GothicCabinet_01",Vector3(46.5,0,20),2.25)
