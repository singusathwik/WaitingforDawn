extends Node
var g
func setup(game):
 g=game
 run.call_deferred()
func aim(index):
 var c=g.exploration.compartments[index]
 var floor_y=5.0*floor(c.pos.y/5.0)
 var p=Vector3(c.pos.x,floor_y,c.pos.z+2)
 g.people[1].pos=p
 g.actors[1].position=p
 var delta=c.pos-(p+Vector3(0,1.65,0))
 g.yaw=0
 g.pitch=atan2(delta.y,Vector2(delta.x,delta.z).length())
 g.last_action.clear()
func run():
 await get_tree().physics_frame
 await get_tree().physics_frame
 g._host(); g._start(); g.set_physics_process(false); g.grace=10000
 await get_tree().physics_frame
 assert(g.exploration.compartments.size()==81)
 assert(g.keys.size()==12)
 # Locked storage cannot be brute-force searched, even when the key is physically there.
 aim(0); g._act(1,"use")
 assert(not g.exploration.searched.has(0) and g.found.is_empty())
 assert(not g.horror.opened[6] and not g.horror.opened[7])
 for key in range(12):
  var selected=-1
  for i in range(81):
   if g.exploration.compartments[i].pos==g.keys[key]: selected=i
  assert(selected>=0 and g.dawn.unlocked(selected))
  assert(not g._nav_path(g.people[1].pos,g.exploration.approach(g.keys[key])).is_empty(),"Key unreachable in progression: "+str(key))
  aim(selected)
  assert(g.exploration.target(1)==selected,"Aim failed: "+str(selected))
  g._act(1,"use")
  assert(g.found.has(key),"Progression key missing: "+str(key))
  g.last_action.clear(); g._act(1,"use")
  assert(g.found.size()==key+1,"Duplicate key awarded")
 assert(g.horror.opened[6] and g.horror.opened[7])
 for i in range(81):
  aim(i)
  assert(g.exploration.target(1)==i,"Cannot aim compartment "+str(i))
  g._act(1,"use")
  assert(g.exploration.searched.has(i),"Search failed "+str(i))
 assert(g.found.size()==12)
 print("PASS 81 individually aimed compartments, twelve-key dependency chain, locked storage, crypt gates, portraits and duplicate protection")
 # Garage alone is insufficient; ignition is separately required.
 g.found.erase(11); g.door_open=true
 g.people[1].pos=Vector3(42,0,29); g.actors[1].position=g.people[1].pos
 g.last_action.clear(); g._act(1,"use")
 assert(not g.people[1].boarded)
 g.dawn.remaining=.05; g.dawn.tick(.1)
 assert(g.phase=="lost" and g.message.contains("Dawn"))
 g._start(); g.set_physics_process(false)
 assert(g.dawn.remaining==g.dawn.MINUTES[g.difficulty]*60 and g.found.is_empty())
 print("PASS ignition requirement, dawn loss and full restart reset")
 for i in range(4):
  g.difficulty=i
  g.grace=0
  g.ghost_mode="patrol"
  g.exploration.pending_sounds=[]
  g.exploration.disturb(Vector3(12,0,18))
  var delay=[6.0,4.5,3.0,2.0][i]
  g.exploration.tick(delay-.1)
  assert(g.ghost_mode=="patrol")
  g.exploration.tick(.11)
  assert(g.ghost_mode=="investigate" and g.ghost_goal==Vector3(12,0,18))
 print("PASS Easy/Normal/Hard/Extreme sound delays: 6/4.5/3/2 seconds")
 g.exploration.reset()
 g.grace=0
 for i in range(20): g.exploration.disturb(Vector3(12,0,18))
 assert(g.exploration.pending_sounds.size()==8)
 g.exploration.reset()
 assert(g.exploration.pending_sounds.is_empty() and g.exploration.searched.is_empty())
 for center in g.exploration.extra_centers:
  assert(not g._nav_path(Vector3(9,0,9),center).is_empty(),"Unreachable wing "+str(center))
 print("PASS sound queue bounded and reset; new wings connected")
 g._quit()
