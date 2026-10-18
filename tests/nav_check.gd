extends SceneTree
func _initialize(): run.call_deferred()
func run():
 var g=load("res://main.tscn").instantiate()
 root.add_child(g)
 for i in range(4): await physics_frame
 for index in range(g.horror.opened.size()): g.horror.opened[index]=true
 g.horror.apply_doors(false)
 var origin=Vector3(9,0,9)
 for p in [Vector3(12,5,9),Vector3(36,5,9),Vector3(12,10,9),Vector3(36,10,9),Vector3(12,-5,30),Vector3(36,-5,30),Vector3(12,-10,30)]:
  var path=g._nav_path(origin,p)
  assert(path.size()>1, "Disconnected floor: "+str(p))
  print("NAV PASS ",p," waypoints=",path.size())
 g._quit()
