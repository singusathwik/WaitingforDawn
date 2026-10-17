extends SceneTree
func _initialize(): run.call_deferred()
func run():
 var g=load("res://main.tscn").instantiate()
 root.add_child(g)
 for i in range(5): await physics_frame
 g.test_mode="estate-walk"
 g._host(); g._start(); g.set_physics_process(false); g.grace=10000
 Engine.time_scale=4
 var total=0.0
 for goal in [Vector3(105,5,9),Vector3(105,10,39),Vector3(105,5,9),Vector3(132,-5,9),Vector3(105,-5,30),Vector3(75,-5,30),Vector3(12,0,18)]:
  var path=g._nav_path(g.people[1].pos,goal)
  assert(not path.is_empty(),"Empty estate route")
  while not path.is_empty():
   await physics_frame
   var delta=g.get_physics_process_delta_time()
   total+=delta
   if total>650:
    print("ESTATE WALK FAIL ",g.people[1].pos," target ",path[0])
    quit(1);return
   var offset=path[0]-g.people[1].pos
   if Vector2(offset.x,offset.z).length()<.28 and absf(offset.y)<.7:
    path.remove_at(0)
   else:
    g._accept_input(1,{"move":Vector2(offset.x,offset.z).normalized(),"yaw":0.0})
    g._simulate_players(delta)
  print("ESTATE WALK PASS reached ",goal)
 print("ESTATE WALK PASS attic and alternate basement loop via physical movement")
 g._quit()
