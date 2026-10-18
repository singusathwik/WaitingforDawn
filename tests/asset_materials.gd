extends SceneTree
func _initialize():
	for path in ["res://assets/models/decay/sofa.glb","res://assets/models/repair/car.glb"]:
		var model=load(path).instantiate()
		for m in preload("res://realistic_art.gd").meshes(model):
			for i in range(m.mesh.get_surface_count()):
				print(path," material=",m.mesh.surface_get_material(i).resource_name)
		model.free()
	quit()
