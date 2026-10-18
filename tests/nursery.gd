extends Node
var g
var mode=""

func setup(game,test_mode: String):
	g=game
	mode=test_mode
	get_tree().create_timer(50 if mode=="nursery-benchmark" else 15).timeout.connect(func(): g._quit(1))
	run.call_deferred()

func run():
	await get_tree().physics_frame
	await get_tree().physics_frame
	g._host(); g._start(); g.grace=10000
	if mode=="nursery-check":
		g.set_physics_process(false)
		await get_tree().physics_frame
		# The journal exists before Dawn's bag during asynchronous world setup.
		var saved_dawn=g.dawn
		g.dawn=null
		g._input(InputEventMouseMotion.new())
		g._unhandled_input(InputEventMouseMotion.new())
		g.dawn=saved_dawn
		assert(g.nursery.parts.size()==16,"Native room parts missing")
		g.nursery.set_texture_detail(true)
		assert(g.nursery.baked_material.albedo_texture.get_width()==2048)
		g.nursery.set_texture_detail(false)
		assert(g.nursery.baked_material.albedo_texture.get_width()==4096)
		g.people[1].pos=Vector3(75,-5,30);g.actors[1].position=g.people[1].pos
		g.light_on=false
		var key=InputEventKey.new();key.keycode=KEY_F;key.pressed=true
		g._unhandled_input(key);g._visual_update(.01)
		assert(g.lamp.visible and g.environment.ambient_light_energy<.002)
		g.people[1].pos=Vector3(66,5,9);g.actors[1].position=g.people[1].pos
		g._visual_update(.01)
		assert(not g.lamp.visible,"Torch must stay off upstairs")
		for i in range(12):
			var c=g.exploration.compartments[i]
			assert(c.get("native",false))
			assert(c.mesh==g.nursery.drawer(i))
			assert(not g._nav_path(Vector3(66,5,9),g.exploration.approach(c.pos)).is_empty(),"Native drawer unreachable "+str(i))
		# The new partitions must stop physical sight and ghost shortcuts.
		assert(not g._line_clear(Vector3(78,5,9),Vector3(78,5,3)))
		assert(g._line_clear(Vector3(80.5,5,9),Vector3(80.5,5,7)))
		for index in [3,7]:
			var slot=g.horror.slots[index]
			g.people[1].pos=slot.entry;g.actors[1].position=slot.entry
			g.yaw=slot.angle;g.pitch=0
			g.last_action.clear();g._act(1,"use")
			assert(g.people[1].hidden and g.people[1].hide_slot==index)
			g._visual_update(.01)
			assert(g.camera.position.is_equal_approx(slot.eye))
			assert(not g.lamp.visible)
			g.last_action.clear();g._act(1,"use")
			assert(not g.people[1].hidden)
		print("PASS native nursery: 16 meshes, 12 searchable drawer bindings, routes, partition occlusion, cupboard/bed entry and cameras")
		g._quit()
		return
	# Render the actual game from approved review coordinates; this also works in the APK.
	var p=Vector3(77.1,5,5.9)
	var target=Vector3(81,5.8,3)
	if mode=="nursery-drawers": p=Vector3(74.2,5,6.7);target=Vector3(72,6,3)
	if mode=="nursery-wardrobe": p=Vector3(72.3,5,7.1);target=Vector3(69,6.2,6)
	if mode in ["nursery-hide","nursery-bed"]:
		var slot=g.horror.slots[3 if mode=="nursery-hide" else 7]
		p=slot.entry
		g.yaw=slot.angle;g.pitch=0
		g.people[1].pos=p;g.actors[1].position=p;g.last_action.clear();g._act(1,"use")
		g.ghost_pos=slot.entry+Vector3(3,0,0)
	else:
		g.people[1].pos=p;g.actors[1].position=p
		var d=target-(p+Vector3(0,1.65,0))
		g.yaw=atan2(-d.x,-d.z);g.pitch=atan2(d.y,Vector2(d.x,d.z).length())
	await get_tree().create_timer(3).timeout
	if mode=="nursery-benchmark":
		var elapsed=0.0
		var frames=[]
		while elapsed<15:
			await get_tree().process_frame
			var delta=get_process_delta_time()
			elapsed+=delta
			frames.append(delta*1000)
		frames.sort()
		print("NURSERY BENCH platform=",OS.get_name()," frames=",frames.size()," p50_ms=",frames[int(frames.size()*.5)]," p95_ms=",frames[int(frames.size()*.95)]," texture_bytes=",Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)," draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	g._capture_test_image(mode+".png")
	if OS.get_cmdline_user_args().has("--report-render"):
		var request=HTTPRequest.new()
		add_child(request)
		request.timeout=8
		var png=g.get_viewport().get_texture().get_image().save_png_to_buffer()
		var err=request.request_raw("http://127.0.0.1:8871/"+mode+".png",PackedStringArray(["Content-Type: image/png"]),HTTPClient.METHOD_POST,png)
		assert(err==OK,"Could not send test render")
		var response=await request.request_completed
		assert(response[1]==200,"Test render collector did not accept the image")
	print("NURSERY RENDER ",mode," camera=",g.camera.position," triangles=",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
	g._quit()
