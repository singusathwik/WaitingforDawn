extends SceneTree
var g
func _initialize(): run.call_deferred()
func check(value: bool,message: String):
	if not value:
		push_error("REPAIR FAIL: "+message)
		quit(1)
		return false
	print("REPAIR PASS: ",message)
	return true
func run():
	g=load("res://main.tscn").instantiate();root.add_child(g)
	while not g.startup_ready: await physics_frame
	# Exercise the same Play action the home screen uses, with the real first-round intro.
	g.home.play()
	if not check(g.phase=="playing" and not g.menu.visible and not g.home.visible and g.exploration.intro_left>0,"Play closes menus and enters the story"):return
	g.set_physics_process(false)
	if not check(g.grace>g.exploration.intro_left,"ghost cannot spawn during the opening story"):return
	g.exploration.skip_story(g.round_id)
	if not check(g.exploration.intro_left==0 and not g.exploration.intro.visible and g.grace==g._difficulty().grace,"story skip restores controls and fair grace period"):return
	g.finish("lost","regression fixture");g._start();g.set_physics_process(false)
	if not check(g.exploration.intro_left==0,"death retry does not replay the story"):return
	g.grace=0
	g.people[1].hidden=true
	var origin=g.ghost_pos
	g.ghost_goal=Vector3(30,0,18)
	var travelled=0.0
	for i in range(20):
		g._tick_ghost(.1)
		travelled=maxf(travelled,g.ghost_pos.distance_to(origin))
	if not check(travelled>1,"ghost patrol leaves its actual default spawn"):return
	g.exploration.pending_sounds=[]
	var destination=Vector3(15,0,18)
	g.ghost_mode="patrol"
	g.exploration.disturb(destination)
	g.exploration.tick(4.6)
	var minimum=INF
	for i in range(300):
		g._tick_ghost(.1)
		minimum=minf(minimum,g.ghost_pos.distance_to(destination))
	if not check(minimum<1.6,"scheduled noise makes the ghost physically reach the hallway"):return
	# Players must leave the approach doors open; the ghost cannot cross closed rooms.
	for door in [0,1,2]:g.horror.opened[door]=true
	g.horror.apply_doors(false)
	await physics_frame
	for destination_floor in [Vector3(36,5,9),Vector3(36,10,9),Vector3(36,-5,30)]:
		g.ghost_goal=destination_floor;g.ghost_mode="investigate";g.ghost_timer=300
		minimum=INF
		for i in range(3000):
			g._tick_ghost(.05)
			minimum=minf(minimum,g.ghost_pos.distance_to(destination_floor))
			if minimum<1.5:break
		if minimum>=1.5:print("GHOST ROUTE FAILURE pos=",g.ghost_pos," goal=",g.ghost_goal," mode=",g.ghost_mode," path=",g._nav_path(g.ghost_pos,g.ghost_goal))
		if not check(minimum<1.5,"ghost follows stairs to "+str(destination_floor)):return
	# A closed door protects a room, and opening restores its route.
	g.horror.opened[0]=false;g.horror.apply_doors(false)
	await physics_frame
	if not check(g.horror.blocks(Vector3(9,0,13),Vector3(9,0,17)),"closed room door blocks the ghost"):return
	g.horror.opened[0]=true;g.horror.apply_doors(false)
	await physics_frame
	if not check(not g.horror.blocks(Vector3(9,0,13),Vector3(9,0,17)),"opening the same door restores passage"):return
	g.people[1].hidden=false;g.grace=10000
	for index in [0,3,6,7]:
		var slot=g.horror.slots[index]
		g.people[1].pos=slot.entry;g.actors[1].position=slot.entry;g.yaw=slot.angle;g.pitch=0
		g.last_action.clear();g._act(1,"use")
		if not check(g.people[1].hidden and g.people[1].hide_slot==index,"enter hiding slot "+str(index)):return
		g._visual_update(.1)
		if not check(g.camera.position.is_equal_approx(slot.eye),"camera is inside hiding slot "+str(index)):return
		g.last_action.clear();g._act(1,"use")
		if not check(not g.people[1].hidden,"leave hiding slot "+str(index)):return
	g.people[1].pos=Vector3(36,10,9);g.actors[1].position=g.people[1].pos
	g.light_on=true;g._visual_update(.1)
	if not check(g.lamp.visible,"torch works on the bedroom floor"):return
	g.people[1].pos=Vector3(36,-5,30);g.actors[1].position=g.people[1].pos
	g.light_on=false;g._visual_update(.1)
	if not check(not g.lamp.visible and g.environment.ambient_light_energy<.002,"basement stays dark without torch"):return
	g.found=range(12)
	g.people[1].pos=Vector3(44.7,0,37.8);g.actors[1].position=g.people[1].pos
	g.yaw=PI;g.pitch=0
	g.last_action.clear();g._act(1,"use")
	await physics_frame
	if not check(g.door_open and g.garage_exit_shape.disabled,"outside garage key plate opens the shutter"):return
	await create_timer(1.5).timeout
	if not check(g.garage_exit.position.y>3.5,"garage shutter lifts clear of the car"):return
	g.people[1].pos=Vector3(44.5,0,33);g.actors[1].position=g.people[1].pos
	g.last_action.clear();g._act(1,"use")
	if not check(g.phase=="escaping","boarding from the car side starts escape"):return
	await create_timer(2).timeout
	if not check(g.escape_car.position.z>43,"car drives through the open outside door"):return
	g.finish("won","regression fixture");g._start();g.set_physics_process(false)
	if not check(g.escape_car.position==Vector3(42,0,33) and not g.door_open,"retry resets the car and garage lock"):return
	g._quit()
