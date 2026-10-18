extends Node
var g
var host=false
var stage=0
var elapsed=0.0
var client=0
var selected=-1
var next=0.0
var saw_clock=false
var key_index=0
func setup(game,mode):
 g=game
 host=mode in ["search-host","room-host"]
 key_index=1 if mode.begins_with("room-") else 0
 if host: g._host()
 else:
  g.ip_edit.text="127.0.0.1"
  for arg in OS.get_cmdline_user_args():
   if arg.begins_with("--server="): g.ip_edit.text=arg.get_slice("=",1)
  g._join()
func _process(delta):
 elapsed+=delta
 if elapsed>60:
  push_error("Search multiplayer timed out at "+str(stage))
  g._quit(1); set_process(false); return
 if host:
  if stage==0 and g.people.size()==2:
   for id in g.people:
    if id!=1: client=id
   if not g.people[client].ready: return
   g._start(); g.grace=10000
   if key_index==1: g.found=[0]
   for i in range(g.exploration.compartments.size()):
    if g.exploration.compartments[i].pos==g.keys[key_index]: selected=i
   var c=g.exploration.compartments[selected]
   var pos=g.exploration.approach(c.pos)
   g.people[client].pos=pos; g.actors[client].position=pos
   g._sync_important(); stage=1
  elif stage==1 and g.found.has(key_index):
   assert(g.exploration.searched.has(selected))
   print("SEARCH NET PASS remote aimed drawer recovered one key and replicated open state")
   next=elapsed+2; stage=2
  elif stage==2 and elapsed>next:
   assert(g.found.size()==key_index+1)
   g.finish.rpc("won","fixture")
   g._return_lobby(); g._start(); g.grace=10000
   next=elapsed+1; stage=3
  elif stage==3 and elapsed>next:
   assert(g.exploration.searched.is_empty())
   print("SEARCH NET PASS duplicate use idempotent; restart cleared compartments")
   g._quit(); set_process(false)
 else:
  if g.phase=="lobby" and stage==0: g._toggle_ready(); stage=1
  if g.phase=="playing" and g.round_id==1:
   if g.dawn.remaining<g.dawn.MINUTES[g.difficulty]*60 and g.dawn.remaining>g.dawn.MINUTES[g.difficulty]*60-25: saw_clock=true
   var c=g.keys[key_index]
   var p=g.people[g.multiplayer.get_unique_id()].pos
   var diff=c-(p+Vector3(0,1.65,0))
   g.yaw=0; g.pitch=atan2(diff.y,Vector2(diff.x,diff.z).length())
   if elapsed>next:
    g._request_action("use"); next=elapsed+.6
   if g.found.has(key_index) and not g.exploration.searched.is_empty():
    assert(g.dawn.toast.text.contains("Nursery key" if key_index==1 else "Brass key"),"Teammate notification missing")
    stage=2
  if g.phase=="playing" and g.round_id==2:
   assert(stage>=2 and saw_clock and g.exploration.searched.is_empty())
   stage=3
  if stage==3 and g.phase=="menu":
   print("SEARCH CLIENT PASS key, open drawer, restart and departure")
   g._quit(); set_process(false)
