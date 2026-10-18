extends Node
## Search, sound scheduling and discovery are host authoritative.
var game
var compartments: Array=[]
var searched: Array=[]
var opened: Array=[]
var animated_opened: Array=[]
var drawer_tweens: Dictionary={}
var pending_sounds: Array=[]
var intro_left=0.0
var intro: ColorRect
var narration: AudioStreamPlayer
var subtitle: Label
var establishing: TextureRect
var cinema_fill: OmniLight3D
var extra_centers=[Vector3(36,5,9),Vector3(36,10,9),Vector3(36,-5,30)]
var extra_links=[[Vector3(21,5,9),Vector3(27,5,9)],[Vector3(36,5,18),Vector3(36,10,0)],[Vector3(36,5,0),Vector3(36,-5,21)],[Vector3(27,-5,30),Vector3(21,-5,30)]]

func geometry(g):
 game=g
 # East wing, attic and service basement form a second loop back to the boiler.
 for center in extra_centers:
  game._box(game.world,center-Vector3(0,0.2,0),Vector3(21,0.4,21),Color(.25,.22,.19),true)
  game._box(game.world,center+Vector3(0,3.8,0),Vector3(21,0.3,21),Color(.1,.09,.08))
  for axis in [0,2]:
   for side in [-1,1]:
    for offset in [-6,6]:
     var pos=center+Vector3(side*10.5,1.8,offset) if axis==0 else center+Vector3(offset,1.8,side*10.5)
     game._box(game.world,pos,Vector3(0.3,3.6,9) if axis==0 else Vector3(9,3.6,0.3),Color(.25,.22,.19),true)
 for spec in [[Vector3(36,5,-1.5),Vector3(3,3.6,0.3)],[Vector3(36,10,19.5),Vector3(3,3.6,0.3)],[Vector3(36,-5,40.5),Vector3(3,3.6,0.3)]]:
  game._box(game.world,spec[0]+Vector3(0,1.8,0),spec[1],Color(.25,.22,.19),true)
 # Split the new wings with offset openings, giving corridors and blind corners.
 for center in extra_centers:
  for offset in [-6,6]:
   game._box(game.world,center+Vector3(offset,1.7,3),Vector3(9,3.4,0.25),Color(.23,.21,.17),true)
  game._box(game.world,center+Vector3(-3,1.7,-6),Vector3(0.25,3.4,6),Color(.23,.21,.17),true)

func setup():
 for center in extra_centers:
  for x in range(-3,4):
   for z in range(-3,4): game._nav_add(center+Vector3(x*3,0,z*3))
 for p in game.nav_ids:
  for offset in [Vector3(3,0,0),Vector3(0,0,3)]:
   if game.nav_ids.has(p+offset) and not game.navigation.are_points_connected(game.nav_ids[p],game.nav_ids[p+offset]):
    if p.x>=25 and p.y!=0: game.navigation.connect_points(game.nav_ids[p],game.nav_ids[p+offset])
 game.repair_layout.navigation()
 # Six independently aimed drawers per dresser. Contents are selected by the host each round.
 for spec in [[Vector3(9,5,3),0,"Nursery dresser"],[Vector3(18,5,15),0,"Toy chest"],[Vector3(9,-5,24),1,"Work bench"],[Vector3(18,-5,36),1,"Coal cabinet"],[Vector3(9,-10,24),2,"Burial drawers"],[Vector3(18,-10,36),2,"Keepsake chest"],[Vector3(36,0,3),-1,"Kitchen cabinet"],[Vector3(42,0,3),-1,"Sink cabinet"],[Vector3(30,5,3),-1,"Bathroom cabinet"],[Vector3(39,10,3),-1,"Bedroom dresser"],[Vector3(30,-5,24),-1,"Pantry cupboard"]]:
  dresser(spec[0],spec[1],spec[2])
 for center in [Vector3(36,0,3),Vector3(42,0,3)]:
  for column in range(3):
   container(center+Vector3((column-1)*1.1,2.5,.1),-1,"Wall cupboard "+str(column+1),Vector3(1,1,0.65))
 # Ceramic bathroom fittings around the searchable cistern.
 game.atmosphere._sphere(game.world,Vector3(39,5.4,3.7),Vector3(0.55,0.4,0.7),Color(.42,.4,.33))
 game.atmosphere._sphere(game.world,Vector3(39,5.71,3.8),Vector3(0.4,0.06,0.5),Color(.055,.05,.04))
 game._box(game.world,Vector3(39,5.23,3.6),Vector3(0.45,0.46,0.6),Color(.36,.35,.3),true)
 for spec in [[Vector3(39,5,3),"Toilet cistern"],[Vector3(42,10,15),"Packing box"],[Vector3(33,-5,36),"Flour bin"],[Vector3(39,0,12),"Bread box"],[Vector3(9,5,15),"Under-bed box"]]:
  container(spec[0]+Vector3(0,0.65,0),-1,spec[1],Vector3(1,0.8,0.8))
 for p in [Vector3(30,5,15),Vector3(30,10,15),Vector3(42,-5,36)]: game.horror._cupboard(p)
 for p in [Vector3(39,5,15),Vector3(33,10,12)]: game.horror._bed(p)
 for p in [Vector3(6,10,3),Vector3(18,10,15)]: game.horror._bed(p)
 game.horror._cupboard(Vector3(6,10,15))
 # Crib, scattered toys, kitchen counter and basin give rooms visual identities.
 for x in [36,42]: game.horror.panel(game.world,Vector3(x,1.22,3),Vector3(3.7,.10,1.5))
 game._box(game.world,Vector3(42,1.38,3),Vector3(1.4,0.09,1),Color(.3,.32,.29))
 for x in [-.6,.6]: game._box(game.world,Vector3(42+x,1.55,3),Vector3(0.08,0.3,1),Color(.35,.36,.32))
 # Nursery dressing and keeper are baked from the approved editable Blender scene.
 add_portraits()
 furnish()
 preload("res://decay_dressing.gd").build(game)
 for c in compartments:
  var floor_pos=Vector3(c.pos.x,5.0*floor(c.pos.y/5.0),c.pos.z-.36)
  var point=game.navigation.get_closest_point(floor_pos)
  if game.navigation.get_point_position(point).distance_to(floor_pos)<1.2:
   game.navigation.set_point_disabled(point,true)
 for slot in game.horror.slots:
  var point=game.navigation.get_closest_point(slot.pos)
  if game.navigation.get_point_position(point).distance_to(slot.pos)<1: game.navigation.set_point_disabled(point,true)
 # Prevent AI graph routes through furniture and the new partitions.
 await game.get_tree().physics_frame
 await game.get_tree().physics_frame
 game.repair_layout.seal_edges()
 await game.get_tree().physics_frame
 game.nursery.prune_navigation()
 for a in game.navigation.get_point_ids():
  for b in game.navigation.get_point_connections(a):
   # Garage passability is controlled by its disabled nav point; preserve its two edges.
   if game.navigation.get_point_position(a)==Vector3(33,0,24) or game.navigation.get_point_position(b)==Vector3(33,0,24): continue
   if a<b and (not game._line_clear(game.navigation.get_point_position(a),game.navigation.get_point_position(b)) or not game._line_clear(game.navigation.get_point_position(a)-Vector3(0,0.7,0),game.navigation.get_point_position(b)-Vector3(0,0.7,0))):
    game.navigation.disconnect_points(a,b)
 game.horror.door_edges.clear()
 for spec in game.horror.DOORS:
  var edges=[]
  for a in game.navigation.get_point_ids():
   for b in game.navigation.get_point_connections(a):
    if a<b and game.horror.crosses(spec,game.navigation.get_point_position(a),game.navigation.get_point_position(b)): edges.append(Vector2i(a,b))
  game.horror.door_edges.append(edges)
 build_intro()

func dresser(p: Vector3,group: int,title: String):
 if p in [Vector3(9,5,3),Vector3(18,5,15)]:
  var first=0 if p.x==9 else 6
  for i in range(6):
   var mesh=game.nursery.drawer(first+i)
   compartments.append({"pos":mesh.global_position+Vector3(0,0,0.06),"group":group,"title":title+" / drawer "+str(i+1),"mesh":mesh,"home":mesh.position,"native":true})
  return
 var compact=p.y==0 and p.x in [36.0,42.0]
 var scale_y=.67 if compact else 1.0
 var case=preload("res://repaired_art.gd").model(game.world,"dresser",p)
 case.scale.y=scale_y
 var blocker=game.horror.panel(game.world,p+Vector3(0,.8*scale_y,-.18),Vector3(3.5,1.7*scale_y,.8),true)
 blocker.hide()
 for row in range(2):
  for col in range(3): container(p+Vector3((col-1)*1.1,(.45+row*.7)*scale_y,.36),group,title+" / drawer "+str(row*3+col+1),Vector3(1,.58*scale_y,.55))

func container(pos: Vector3,group: int,title: String,size: Vector3):
 if title=="Under-bed box":
  var mesh=game.nursery.parts["Search_box"]
  compartments.append({"pos":mesh.global_position,"group":group,"title":"Reading-room box","mesh":mesh,"home":mesh.position,"native":true})
  return
 var root=Node3D.new()
 game.world.add_child(root)
 root.position=pos
 var tray=preload("res://repaired_art.gd").model(root,"drawer")
 tray.scale=Vector3(size.x,size.y/.58,size.z/.75)
 compartments.append({"pos":pos,"group":group,"title":title,"mesh":root,"home":pos,"height":size.y})

func choose_keys() -> Array:
 return game.dawn.choose_keys()

func index_for_key(i: int) -> int:
 for n in range(compartments.size()):
  if compartments[n].pos==game.keys[i]: return n
 return 0

func key_available(i: int) -> bool:
 return opened.has(index_for_key(i)) and game.dawn.unlocked(index_for_key(i))

func key_display_position(i: int) -> Vector3:
 var c=compartments[index_for_key(i)]
 if c.get("portrait",false):return c.mesh.global_position+Vector3(0,0,.14)
 return c.mesh.global_position+Vector3(0,-.21*c.get("height",.58)/.58,-.35 if c.get("native",false) else -.18)

func target(id: int) -> int:
 var p=game.people[id]
 if p.hidden or p.down: return -1
 var cmd=game.commands.get(id,{})
 var low=game.crouch if id==game.multiplayer.get_unique_id() else cmd.get("crouch",false)
 var eye=p.pos+Vector3(0,.65 if low else 1.65,0)
 var yaw=game.yaw if id==game.multiplayer.get_unique_id() else float(cmd.get("yaw",p.yaw))
 var pitch=game.pitch if id==game.multiplayer.get_unique_id() else float(cmd.get("pitch",0))
 var direction=Vector3(0,0,-1).rotated(Vector3.RIGHT,pitch).rotated(Vector3.UP,yaw)
 var best=.93
 var selected=-1
 for i in range(compartments.size()):
  var c=compartments[i]
  var delta=c.pos-eye
  if delta.length()>3.2: continue
  var score=direction.dot(delta.normalized())
  if score>best and game._line_clear(p.pos,Vector3(c.pos.x,p.pos.y,c.pos.z+1)):
   best=score
   selected=i
 return selected

func prompt(id: int) -> String:
 var i=target(id)
 if i<0: return ""
 if not game.dawn.unlocked(i): return "Locked — needs the "+game.dawn.NAMES[game.dawn.required_key(i)]
 var key=game.keys.find(compartments[i].pos)
 if opened.has(i) and key>=0 and not game.found.has(key): return "Take "+game.dawn.NAMES[key]+" → bag"
 return ("Close — " if opened.has(i) else "Turn over — " if compartments[i].get("portrait",false) else "Open — ")+compartments[i].title

func use(id: int) -> bool:
 var i=target(id)
 if i<0: return false
 if not game.dawn.unlocked(i):
  disturb(game.people[id].pos)
  game.interaction_notice.rpc_id(id,"Locked. The "+game.dawn.NAMES[game.dawn.required_key(i)]+" fits here.")
  return true
 if not searched.has(i): searched.append(i)
 if opened.has(i): opened.erase(i)
 else: opened.append(i)
 disturb(game.people[id].pos)
 game.sound_event.rpc(compartments[i].pos,.55,"door")
 var key=game.keys.find(compartments[i].pos)
 if opened.has(i):
  game.interaction_notice.rpc_id(id,"Something catches the light. Look inside, then use to take it." if key>=0 and not game.found.has(key) else "Empty. Use again to close.")
 return true

@rpc("authority","call_local","reliable")
func sync_state(state: Array,round_number: int,open_state: Array=[]):
 if round_number!=game.round_id or game.phase!="playing": return
 searched=state.duplicate()
 opened=open_state.duplicate()
 for i in range(compartments.size()):
  if opened.has(i)==animated_opened.has(i): continue
  var c=compartments[i]
  if drawer_tweens.has(i) and drawer_tweens[i].is_running(): drawer_tweens[i].kill()
  var tween=create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
  drawer_tweens[i]=tween
  if c.get("portrait",false): tween.tween_property(c.mesh,"rotation:y",PI if opened.has(i) else 0.0,.65)
  else: tween.tween_property(c.mesh,"position",c.home+Vector3(0,0,.78 if opened.has(i) else 0),.38)
 animated_opened=opened.duplicate()

func disturb(pos: Vector3):
 if game.grace>0: return
 # Bounded FIFO: new sounds never postpone the first response or overwrite it.
 if pending_sounds.size()>=8: return
 pending_sounds.append({"pos":pos,"left":[6.0,4.5,3.0,2.0][game.difficulty]})
 if pending_sounds.size()==1:
  # Response comes from her actual position, not from the opened drawer.
  game.sound_event.rpc(game.ghost_pos,.55,"wail")
  game.noise_reply.rpc(pos)

func tick(delta: float):
 for sound in pending_sounds: sound.left-=delta
 if pending_sounds.is_empty() or pending_sounds[0].left>0: return
 var sound=pending_sounds.pop_front()
 if game.ghost_mode!="chase":
  game.ghost_goal=sound.pos
  game.ghost_mode="investigate"
  # Investigation lasts long enough to cross the house and climb stairs.
  game.ghost_timer=180

func reset():
 searched=[]
 opened=[]
 animated_opened=[]
 for tween in drawer_tweens.values():
  if tween and tween.is_running(): tween.kill()
 drawer_tweens.clear()
 pending_sounds=[]
 for c in compartments:
  c.mesh.position=c.home
  c.mesh.rotation.y=0
 intro_left=36.0 if game.test_mode=="" and game.round_id==1 else 0.0
 if is_instance_valid(intro):
  intro.visible=intro_left>0
  if intro_left>0 and narration.stream: narration.play()

func build_intro():
 intro=ColorRect.new()
 intro.color=Color(0,0,0,0)
 intro.mouse_filter=Control.MOUSE_FILTER_IGNORE
 intro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 game.ui.add_child(intro)
 establishing=TextureRect.new()
 establishing.texture=load("res://assets/ui/manor.png")
 establishing.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 establishing.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
 establishing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 intro.add_child(establishing)
 subtitle=Label.new()
 subtitle.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
 subtitle.position=Vector2(-430,160)
 subtitle.size=Vector2(860,140)
 subtitle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 subtitle.add_theme_font_size_override("font_size",26)
 subtitle.add_theme_color_override("font_color",Color(.8,.74,.6))
 intro.add_child(subtitle)
 subtitle.add_theme_color_override("font_shadow_color",Color.BLACK)
 subtitle.add_theme_constant_override("shadow_offset_x",2)
 subtitle.add_theme_constant_override("shadow_offset_y",2)
 for bottom in [false,true]:
  var bar=ColorRect.new()
  bar.color=Color.BLACK
  bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE if bottom else Control.PRESET_TOP_WIDE)
  bar.offset_top=-48 if bottom else 0
  bar.offset_bottom=0 if bottom else 48
  intro.add_child(bar)
 cinema_fill=OmniLight3D.new()
 game.camera.add_child(cinema_fill)
 cinema_fill.omni_range=7
 cinema_fill.light_color=Color(.65,.52,.36)
 cinema_fill.light_energy=.8
 cinema_fill.visible=false
 narration=AudioStreamPlayer.new()
 add_child(narration)
 narration.stream=load("res://assets/audio/introduction.wav")
 var skip=Button.new()
 skip.text="Skip story  ›"
 skip.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
 skip.offset_left=-210;skip.offset_right=-24;skip.offset_top=20;skip.offset_bottom=74
 skip.pressed.connect(func():
  if game.multiplayer.is_server(): skip_story.rpc(game.round_id)
  else: request_skip.rpc_id(1,game.round_id))
 intro.add_child(skip)
 intro.hide()

@rpc("any_peer","call_remote","reliable")
func request_skip(number: int):
 if game.multiplayer.is_server() and number==game.round_id and game.people.has(game.multiplayer.get_remote_sender_id()): skip_story.rpc(number)

@rpc("authority","call_local","reliable")
func skip_story(number: int):
 if number!=game.round_id or game.phase!="playing" or intro_left<=0: return
 intro_left=0
 intro.hide()
 narration.stop()
 game.grace=game._difficulty().grace
 game.touch.show()
 game.hint.show()
 if not game._is_mobile(): Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func _process(delta):
 if not is_instance_valid(intro): return
 cinema_fill.visible=game.phase=="playing" and intro_left>0
 if game.phase!="playing":
  intro.hide()
  narration.stop()
  intro_left=0
 if intro_left>0:
  intro_left=maxf(0,intro_left-delta)
  var passages=["WAITING FOR DAWN\nOctober, 1996\nA late-night detour. One house. No way back.","The gate was open. Our friends dared us to step inside.\nThen every lock turned at once.","They said Eleanor kept this house warm for her children.\nWhen the fire took them, she never stopped listening for their footsteps.","Someone upstairs had tried to leave before us.\nHis coat held a letter. His hand still gripped the stairs.","Twelve keys. One last ride.\nUnlock the garage. Start the car. Leave together before dawn."]
  subtitle.text=passages[mini(4,int((36-intro_left)/7.2))]
  establishing.visible=intro_left>28.8
  establishing.scale=Vector2.ONE*(1+(36-intro_left)*.004)
  intro.visible=intro_left>0
  if intro_left==0:
   narration.stop()
   if not game._is_mobile(): Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func approach(key: Vector3) -> Vector3:
 return Vector3(key.x,5.0*floor(key.y/5.0),key.z+2)

func add_portraits():
 for p in [Vector3(6,1.6,1.95),Vector3(18,1.6,1.95),Vector3(30,1.6,1.95),Vector3(45,1.6,1.95)]:
  container(p,-1,"Family portrait",Vector3(1.2,1.5,0.09))
  var c=compartments.back()
  c.portrait=true
  var root=c.mesh
  for side in [-1,1]:
   game._box(root,Vector3(side*.6,0,.08),Vector3(0.09,1.6,0.12),Color(.28,.19,.08))
   game._box(root,Vector3(0,side*.75,.08),Vector3(1.2,0.09,0.12),Color(.28,.19,.08))
  var portrait=game._box(root,Vector3(0,0,0.065),Vector3(1.1,1.4,0.015),Color(.25,.22,.17))
  if ResourceLoader.exists("res://assets/ui/title.png"):
   var paint=StandardMaterial3D.new()
   paint.albedo_texture=load("res://assets/ui/title.png")
   paint.albedo_color=Color(.65,.55,.4)
   portrait.material_override=paint
  # A recessed backing and hook are revealed when the frame turns.
  game._box(root,Vector3(0,0,-0.08),Vector3(0.95,1.2,0.02),Color(.12,.08,.045))

func furnish():
 preload("res://repaired_art.gd").furnish(game)
 # Wall-side props preserve the main circulation routes; collisions are pruned from navigation above.
 for p in [Vector3(14,0,3),Vector3(4,0,27),Vector3(31,5,0),Vector3(41,10,18),Vector3(41,-5,39)]:
  preload("res://realistic_art.gd").place(game.world,"ClassicConsole_01",p,1.1)
  var collider=game.horror.panel(game.world,p+Vector3(0,0.5,0),Vector3(1.8,1,0.7),true)
  collider.visible=false
  game.navigation.set_point_disabled(game.navigation.get_closest_point(p),true)
  for n in range(4):
   var book=game.horror.panel(game.world,p+Vector3((n-1.5)*.23,1.15+n*.025,0),Vector3(0.19,0.07,0.34))
   book.rotation.y=n*.18
 for p in [Vector3(3,0,4),Vector3(21,0,34),Vector3(27,5,17),Vector3(45,10,16)]:
  preload("res://realistic_art.gd").place(game.world,"ArmChair_01",p,1.4,PI)
  var blocker=game.horror.panel(game.world,p+Vector3(0,0.55,0),Vector3(1,1.1,1),true)
  blocker.visible=false
  game.navigation.set_point_disabled(game.navigation.get_closest_point(p),true)
func cinematic_camera():
 if intro_left<=0: return
 var t=36-intro_left
 var shot=mini(4,int(t/7.2))
 var f=fmod(t,7.2)/7.2
 var starts=[Vector3(12,1.8,12),Vector3(9,1.7,20),Vector3(52.5,6.8,12),Vector3(39,6.7,14),Vector3(39,1.8,27)]
 var ends=[Vector3(12,1.7,7),Vector3(9,1.5,17),Vector3(52.5,6.8,14),Vector3(39,6.6,12),Vector3(40,1.5,28)]
 var targets=[Vector3(18,1.4,3),Vector3(9,1.4,15),Vector3(57,7.5,18),Vector3(36,6.2,9),Vector3(42,1,33)]
 game.camera.position=starts[shot].lerp(ends[shot],smoothstep(0,1,f))
 game.camera.look_at(targets[shot])
 game.lamp.visible=false
 game.touch.hide()
 game.hint.hide()
