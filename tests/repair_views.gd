extends Node
var g
var shot="kitchen"
func setup(game,view):
	g=game;shot=view
	run.call_deferred()
func run():
	await get_tree().physics_frame
	if shot=="home":
		g.menu.hide();g.home.show()
	else:
		g.test_mode="repair-render"
		g._host();g._start();g.grace=10000;g.set_physics_process(false)
		var positions={"kitchen":[Vector3(32,0,10),Vector3(39,1.5,3)],"garage":[Vector3(38,0,37),Vector3(42,1,33)],"stairs":[Vector3(54,5,9),Vector3(52.5,7,17)],"bedroom":[Vector3(36,10,14),Vector3(33,11,12)],"nursery":[Vector3(14.1,5,5.9),Vector3(18,5.8,3)],"drawer":[Vector3(36,0,4.7),Vector3(36,.3,3.9)],"exterior":[Vector3(37,0,50),Vector3(30,7,20)]}
		var pair=positions[shot]
		g.people[1].pos=pair[0];g.actors[1].position=pair[0]
		var d=pair[1]-(pair[0]+Vector3(0,1.65,0))
		g.yaw=atan2(-d.x,-d.z);g.pitch=atan2(d.y,Vector2(d.x,d.z).length())
		g.light_on=true
		if shot=="drawer":
			g.keys[0]=g.exploration.compartments[37].pos
			g.exploration.sync_state([37],g.round_id,[37])
		g._visual_update(.1)
	await get_tree().create_timer(3).timeout
	if shot!="home":g._visual_update(.1)
	await RenderingServer.frame_post_draw
	g._capture_test_image("repair-"+shot+".png")
	if OS.get_cmdline_user_args().has("--report-render"):
		var request=HTTPRequest.new();add_child(request);request.timeout=8
		var png=g.get_viewport().get_texture().get_image().save_png_to_buffer()
		var err=request.request_raw("http://127.0.0.1:8871/repair-"+shot+".png",PackedStringArray(["Content-Type: image/png"]),HTTPClient.METHOD_POST,png)
		assert(err==OK)
		var response=await request.request_completed
		assert(response[1]==200)
	print("REPAIR RENDER repair-",shot," viewport=",get_tree().root.size)
	g._quit()
