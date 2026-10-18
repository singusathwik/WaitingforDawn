extends SceneTree
var g
func _initialize():run.call_deferred()
func check(value:bool,label:String)->bool:
	if not value:push_error("083 FAIL: "+label);quit(1);return false
	print("083 PASS: ",label);return true
func run():
	g=load("res://main.tscn").instantiate();root.add_child(g)
	while not g.startup_ready:await physics_frame
	g.home.play();g.exploration.skip_story(g.round_id);g.set_physics_process(false)
	# Start with real default doors and grace. No hidden-player or manually opened AI fixture.
	for i in range(110):g._tick_ghost(.1)
	g.people[1].pos=Vector3(9,0,12);g.actors[1].position=g.people[1].pos
	var sound=g.people[1].pos
	g.exploration.disturb(sound)
	for i in range(600):g.exploration.tick(.1);g._tick_ghost(.1)
	if not check(g.ghost_pos.distance_to(sound)<8 and g.ghost_goal==sound and g.ghost_mode=="investigate","normal noise reaches closed-room approach and is remembered for 60 seconds"):return
	if not check(g.ghost_pos.z>=15 and not g.people[1].down,"closed door still protects survivor"):return
	# Player looks toward the actual handle from within the room.
	g.people[1].pos=Vector3(9.9,0,12.8);g.actors[1].position=g.people[1].pos;g.yaw=PI
	if not check(g.horror.target_door(1)==0 and g._prompt(1).contains("open Parlour"),"handle has a clear Use prompt from 2.2 metres"):return
	g.last_action.clear();g._act(1,"use")
	await physics_frame
	if not check(g.horror.opened[0] and g._prompt(1).contains("USE"),"same Use action opens door without warning hiding its prompt"):return
	for i in range(300):g.exploration.tick(.1);g._tick_ghost(.1)
	if not check(g.people[1].down,"waiting ghost enters and catches exposed survivor after door opens"):return
	g._start();g.set_physics_process(false);g.grace=10000
	# Test every square metre of each actual room floor, including native nursery.
	var probes=0
	for centre in [Vector3(12,5,9),Vector3(12,10,9),Vector3(36,5,9),Vector3(36,10,9),Vector3(12,-5,30),Vector3(36,-5,30),Vector3(12,-10,30)]:
		for x in range(-10,11):
			for z in range(-10,11):
				var p=centre+Vector3(x,0,z)
				var hit=g.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p+Vector3.UP*.08,p-Vector3.UP*.3,1))
				if not check_floor(hit,p):return
				probes+=1
	if not check(probes==3087,"3087 room-floor support probes have no holes"):return
	for x in range(0,50):
		for z in range(0,41):
			var p=Vector3(x,0,z)
			var hit=g.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p+Vector3.UP*.08,p-Vector3.UP*.3,1))
			if not check_floor(hit,p):return
	if not check(true,"2050 additional ground-floor support probes have no holes"):return
	if not check(g.repair_layout.guard_count>50,"exposed landing edges have solid guards"):return
	# Walk a body sideways into the three former unguarded elevated landings.
	for p in [Vector3(54.7,2.5,18),Vector3(54.7,7.5,18),Vector3(49.5,5,9)]:
		g.people[1].pos=p;g.actors[1].position=p;g.actors[1].velocity=Vector3.ZERO
		for i in range(100):
			await physics_frame
			g._accept_input(1,{"move":Vector2(0,-1),"yaw":0.0})
			g._simulate_players(1.0/60)
		if not check(absf(g.people[1].pos.y-p.y)<.12,"off-centre walking contained at "+str(p)):return
	# Last-grounded recovery is a fallback, not a substitute for support/edge checks.
	g.safe_positions[1]=Vector3(9,0,10);g.actors[1].position=Vector3(24,-3,44);g.actors[1].velocity=Vector3(0,-9,0)
	for i in range(45):
		await physics_frame
		g._accept_input(1,{"move":Vector2.ZERO,"yaw":0.0});g._simulate_players(1.0/60)
	if not check(g.people[1].pos.distance_to(Vector3(9,0,10))<.1,"unexpected fall returns to last grounded point"):return
	g._quit()
func check_floor(hit:Dictionary,p:Vector3)->bool:
	if hit.is_empty():return check(false,"floor support at "+str(p))
	return true
