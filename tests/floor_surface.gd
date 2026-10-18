extends SceneTree
func _initialize():run.call_deferred()
func run():
	var g=load("res://main.tscn").instantiate();root.add_child(g)
	while not g.startup_ready:await physics_frame
	for p in [Vector3(16,5,12),Vector3(12,5,4),Vector3(7,5,16),Vector3(18,5,5)]:
		print("SURFACE ",p," ",g.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p+Vector3.UP*.5,p-Vector3.UP*.5,1)))
	for child in g.nursery.get_children():
		if child is StaticBody3D and child.position.y<0:child.get_child(0).disabled=true
	await physics_frame;await physics_frame
	for p in [Vector3(16,5,12),Vector3(12,5,4),Vector3(7,5,16),Vector3(18,5,5)]:
		print("WITHOUT_SLAB ",p," ",g.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p+Vector3.UP*.5,p-Vector3.UP*.5,1)))
	g._quit()
