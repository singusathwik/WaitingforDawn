extends SceneTree
func _initialize(): run.call_deferred()
func run():
 var g=load("res://main.tscn").instantiate()
 root.add_child(g)
 for i in range(4): await physics_frame
 g.navigation.set_point_disabled(g.nav_ids[Vector3(33,0,24)],true)
 var origin=Vector3(9,0,9)
 for p in [Vector3(12,0,18),Vector3(48,0,9),Vector3(66,5,9),Vector3(72,5,6),Vector3(84,5,9),Vector3(96,5,9),Vector3(105,5,9),Vector3(48,0,30),Vector3(66,-5,30),Vector3(75,-5,30)]:
  print("NAV ",p," path=",g._nav_path(origin,p).size()," disabled=",g.navigation.is_point_disabled(g.nav_ids.get(p,0)))
 for pair in [[Vector3(48,0,9),Vector3(66,5,9)],[Vector3(84,5,9),Vector3(96,5,9)]]:
  for step in range(6):
   var a=pair[0].lerp(pair[1],step/6.0)
   var b=pair[0].lerp(pair[1],(step+1)/6.0)
   print(a," -> ",b," clear=",g._line_clear(a,b)," path ",g._nav_path(a,b))
 quit()
