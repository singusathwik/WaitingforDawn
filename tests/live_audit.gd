extends SceneTree
var g
func _initialize(): run.call_deferred()
func run():
	g=load("res://main.tscn").instantiate();root.add_child(g)
	while not g.startup_ready: await physics_frame
	g.home.play();g.exploration.skip_story(g.round_id)
	g.set_physics_process(false)
	for frame in range(600):
		g.exploration.tick(.1);g._tick_ghost(.1)
		if frame%50==0:print("BASELINE ",frame/10," pos=",g.ghost_pos," goal=",g.ghost_goal," mode=",g.ghost_mode," path=",g._nav_path(g.ghost_pos,g.ghost_goal))
		if frame==150:
			g.people[1].pos=Vector3(9,0,13.2);g.actors[1].position=g.people[1].pos
			g.last_action.clear();g._act(1,"use")
			print("OPENED ",g.horror.opened," edges ",g.horror.door_edges[0]," prompt=",g._prompt(1))
		await physics_frame
	print("AUDIT COMPLETE")
	g._quit()
