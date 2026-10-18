extends SceneTree
func _initialize(): run.call_deferred()
func run():
 var g=load("res://main.tscn").instantiate()
 root.add_child(g)
 while not g.startup_ready: await physics_frame
 g.test_mode="estate-walk"
 g._host(); g._start(); g.set_physics_process(false); g.grace=10000
 for i in [0,1,2,6,7]: g.horror.opened[i]=true
 g.horror.apply_doors(false)
 await physics_frame
 Engine.time_scale=4
 var total=0.0
 var last_report=0.0
 for goal in [Vector3(36,5,9),Vector3(36,10,9),Vector3(36,5,9),Vector3(36,-5,9),Vector3(36,-5,30),Vector3(12,-5,30),Vector3(12,-10,30),Vector3(12,10,9),Vector3(12,0,18)]:
  var path=g._nav_path(g.people[1].pos,goal)
  assert(not path.is_empty(),"Empty estate route")
  while not path.is_empty():
   await physics_frame
   var delta=Engine.time_scale/Engine.physics_ticks_per_second
   total+=delta
   if total-last_report>20:
    last_report=total
    print("WALK ",g.people[1].pos," -> ",path[0])
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
