extends SceneTree
func _initialize():run.call_deferred()
func run():
	var g=load("res://main.tscn").instantiate();root.add_child(g)
	while not g.startup_ready:await physics_frame
	g.test_mode="capture-only"
	g.people={1:g._new_person("Survivor")}
	g.begin_match(g.people,g.dawn.choose_keys(),2,1)
	g.set_physics_process(false);g.grace=10000
	g.people[1].pos=Vector3(9.9,0,12.8);g.actors[1].position=g.people[1].pos;g.yaw=PI;g.pitch=-.08
	g._visual_update(.1)
	await create_timer(2).timeout
	g._visual_update(.1)
	await RenderingServer.frame_post_draw
	g._capture_test_image("repair-door.png")
	print("DOOR RENDER prompt=",g._prompt(1))
	g._quit()
