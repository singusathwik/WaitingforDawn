extends Node
## Search, sound scheduling and discovery are host authoritative.
var game
var compartments: Array=[]
var searched: Array=[]
var pending_sounds: Array=[]
var intro_left=0.0
var intro: ColorRect
var narration: AudioStreamPlayer
var subtitle: Label
var establishing: TextureRect
var cinema_fill: OmniLight3D
var extra_centers=[Vector3(105,5,9),Vector3(105,10,39),Vector3(105,-5,30)]
var extra_links=[[Vector3(84,5,9),Vector3(96,5,9)],[Vector3(105,5,18),Vector3(105,10,30)],[Vector3(105,5,0),Vector3(105,-5,21)],[Vector3(96,-5,30),Vector3(84,-5,30)]]

func geometry(g):
 game=g
 # East wing, attic and service basement form a second loop back to the boiler.
 for center in extra_centers:
  game._box(game.world,center-Vector3(0,.2,0),Vector3(21,.4,21),Color(.25,.22,.19),true)
  game._box(game.world,center+Vector3(0,3.8,0),Vector3(21,.3,21),Color(.1,.09,.08))
  for axis in [0,2]:
   for side in [-1,1]:
    for offset in [-6,6]:
     var pos=center+Vector3(side*10.5,1.8,offset) if axis==0 else center+Vector3(offset,1.8,side*10.5)
     game._box(game.world,pos,Vector3(.3,3.6,9) if axis==0 else Vector3(9,3.6,.3),Color(.25,.22,.19),true)
 for spec in [[Vector3(105,5,-1.5),Vector3(3,3.6,.3)],[Vector3(94.5,10,39),Vector3(.3,3.6,3)],[Vector3(115.5,10,39),Vector3(.3,3.6,3)],[Vector3(105,10,49.5),Vector3(3,3.6,.3)],[Vector3(105,-5,19.5),Vector3(3,3.6,.3)],[Vector3(105,-5,40.5),Vector3(3,3.6,.3)]]:
  game._box(game.world,spec[0]+Vector3(0,1.8,0),spec[1],Color(.25,.22,.19),true)
 # Original east walls need openings; rebuilt with a central doorway in game._room.
 game._ramp(Vector3(85.5,5,9),Vector3(94.5,5,9))
 game._ramp(Vector3(105,5,19.5),Vector3(105,10,28.5))
 # Service stair descends from north wing along the outside east wall, not through a floor.
 game._ramp(Vector3(115.5,5,9),Vector3(130.5,-5,9))
 game._box(game.world,Vector3(132,-5.2,19.5),Vector3(3,.4,24),Color(.2,.18,.16),true)
 for x in [130.4,133.6]: game._box(game.world,Vector3(x,-4.2,19.5),Vector3(.2,1.6,17 if x<132 else 24),Color(.17,.16,.14),true)
 game._box(game.world,Vector3(132,-3.2,7.5),Vector3(3,3.6,.2),Color(.17,.16,.14),true)
 game._box(game.world,Vector3(132,-3.2,31.5),Vector3(3,3.6,.2),Color(.17,.16,.14),true)
 game._ramp(Vector3(115.5,-5,30),Vector3(130.5,-5,30))
 game._ramp(Vector3(85.5,-5,30),Vector3(94.5,-5,30))
 # Split the new wings with offset openings, giving corridors and blind corners.
 for center in extra_centers:
  for offset in [-6,6]:
   game._box(game.world,center+Vector3(offset,1.7,3),Vector3(9,3.4,.25),Color(.23,.21,.17),true)
  game._box(game.world,center+Vector3(-3,1.7,-6),Vector3(.25,3.4,6),Color(.23,.21,.17),true)

func setup():
 for center in extra_centers:
  for x in range(-3,4):
   for z in range(-3,4): game._nav_add(center+Vector3(x*3,0,z*3))
 var links=[[Vector3(84,5,9),Vector3(96,5,9)],[Vector3(105,5,18),Vector3(105,10,30)],[Vector3(114,5,9),Vector3(115.5,5,9)],[Vector3(115.5,5,9),Vector3(130.5,-5,9)],[Vector3(130.5,-5,9),Vector3(132,-5,9)],[Vector3(132,-5,9),Vector3(132,-5,30)],[Vector3(132,-5,30),Vector3(114,-5,30)],[Vector3(96,-5,30),Vector3(84,-5,30)]]
 for pair in links:
  var previous=game._nav_add(pair[0])
  var steps=int(ceil(pair[0].distance_to(pair[1])/2))
  for step in range(1,steps+1):
   var next=game._nav_add(pair[0].lerp(pair[1],float(step)/steps))
   game.navigation.connect_points(previous,next)
   previous=next
 for p in game.nav_ids:
  for offset in [Vector3(3,0,0),Vector3(0,0,3)]:
   if game.nav_ids.has(p+offset) and not game.navigation.are_points_connected(game.nav_ids[p],game.nav_ids[p+offset]):
    if p.x>90: game.navigation.connect_points(game.nav_ids[p],game.nav_ids[p+offset])
 # Six independently aimed drawers per dresser. Contents are selected by the host each round.
 for spec in [[Vector3(72,5,3),0,"Nursery dresser"],[Vector3(81,5,15),0,"Toy chest"],[Vector3(72,-5,24),1,"Work bench"],[Vector3(81,-5,36),1,"Coal cabinet"],[Vector3(72,-10,54),2,"Burial drawers"],[Vector3(81,-10,66),2,"Keepsake chest"],[Vector3(36,0,3),-1,"Kitchen cabinet"],[Vector3(42,0,3),-1,"Sink cabinet"],[Vector3(99,5,3),-1,"Bathroom cabinet"],[Vector3(108,10,33),-1,"Attic dresser"],[Vector3(99,-5,24),-1,"Pantry cupboard"]]:
  dresser(spec[0],spec[1],spec[2])
 for center in [Vector3(36,0,3),Vector3(42,0,3)]:
  for column in range(3):
   container(center+Vector3((column-1)*1.1,2.5,.1),-1,"Wall cupboard "+str(column+1),Vector3(1,1,.65))
 # Ceramic bathroom fittings around the searchable cistern.
 game.atmosphere._sphere(game.world,Vector3(108,5.4,3.7),Vector3(.55,.4,.7),Color(.42,.4,.33))
 game.atmosphere._sphere(game.world,Vector3(108,5.71,3.8),Vector3(.4,.06,.5),Color(.055,.05,.04))
 game._box(game.world,Vector3(108,5.23,3.6),Vector3(.45,.46,.6),Color(.36,.35,.3),true)
 for spec in [[Vector3(108,5,3),"Toilet cistern"],[Vector3(111,10,45),"Packing box"],[Vector3(102,-5,36),"Flour bin"],[Vector3(39,0,12),"Bread box"],[Vector3(72,5,15),"Under-bed box"]]:
  container(spec[0]+Vector3(0,.65,0),-1,spec[1],Vector3(1,.8,.8))
 for p in [Vector3(99,5,15),Vector3(99,10,45),Vector3(111,-5,36)]: game.horror._cupboard(p)
 for p in [Vector3(108,5,15),Vector3(102,10,42)]: game.horror._bed(p)
 # Crib, scattered toys, kitchen counter and basin give rooms visual identities.
 game.horror.panel(game.world,Vector3(39,1.3,3),Vector3(10,.12,1.5),true)
 game._box(game.world,Vector3(42,1.38,3),Vector3(1.4,.09,1),Color(.3,.32,.29))
 for x in [-.6,.6]: game._box(game.world,Vector3(42+x,1.55,3),Vector3(.08,.3,1),Color(.35,.36,.32))
 for i in range(7): game.atmosphere._sphere(game.world,Vector3(74+i*.4,5.17,13+sin(i)*.5),Vector3(.18,.18,.18),Color(.3+.05*i,.18,.12))
 # A fallen keeper: imported articulated human silhouette, laid on the upstairs floor.
 var body=load("res://assets/models/wraith.glb").instantiate()
 game.world.add_child(body)
 body.position=game.horror.NOTES[0]+Vector3(0,.3,0)
 body.rotation.z=PI/2
 body.scale=Vector3.ONE*.27
 add_portraits()
 furnish()
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
 for a in game.navigation.get_point_ids():
  for b in game.navigation.get_point_connections(a):
   # Garage passability is controlled by its disabled nav point; preserve its two edges.
   if game.navigation.get_point_position(a)==Vector3(33,0,24) or game.navigation.get_point_position(b)==Vector3(33,0,24): continue
   if a<b and (not game._line_clear(game.navigation.get_point_position(a),game.navigation.get_point_position(b)) or not game._line_clear(game.navigation.get_point_position(a)-Vector3(0,.7,0),game.navigation.get_point_position(b)-Vector3(0,.7,0))):
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
 game.horror.panel(game.world,p+Vector3(0,.8,-.18),Vector3(3.5,1.7,.8),true)
 for row in range(2):
  for col in range(3): container(p+Vector3((col-1)*1.1,.45+row*.7,.36),group,title+" / drawer "+str(row*3+col+1),Vector3(1,.58,.55))

func container(pos: Vector3,group: int,title: String,size: Vector3):
 var root=Node3D.new()
 game.world.add_child(root)
 root.position=pos
 game.horror.panel(root,Vector3.ZERO,size)
 game._box(root,Vector3(0,0,size.z*.5+.04),Vector3(.3,.05,.06),Color(.45,.37,.23))
 compartments.append({"pos":pos,"group":group,"title":title,"mesh":root,"home":pos})

func choose_keys() -> Array:
 return game.dawn.choose_keys()

func key_available(i: int) -> bool:
 for n in searched:
  if compartments[n].pos==game.keys[i] and game.dawn.unlocked(n): return true
 return false

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
 return ("Searched — " if searched.has(i) else "Turn over — " if compartments[i].get("portrait",false) else "Open — ")+compartments[i].title

func use(id: int) -> bool:
 var i=target(id)
 if i<0: return false
 if searched.has(i):
  game.interaction_notice.rpc_id(id,"Already searched.")
  return true
 if not game.dawn.unlocked(i):
  disturb(game.people[id].pos)
  game.interaction_notice.rpc_id(id,"Locked. The "+game.dawn.NAMES[game.dawn.required_key(i)]+" fits here.")
  return true
 searched.append(i)
 disturb(game.people[id].pos)
 game.sound_event.rpc(compartments[i].pos,.55,"door")
 var key=game.keys.find(compartments[i].pos)
 if key>=0 and not game.found.has(key):
  game.dawn.collect(id,key)
  game.sound_event.rpc(compartments[i].pos,.45,"key")

 else: game.interaction_notice.rpc_id(id,"Nothing here. Listen before searching again.")
 return true

@rpc("authority","call_local","reliable")
func sync_state(state: Array,round_number: int):
 if round_number!=game.round_id or game.phase!="playing": return
 searched=state.duplicate()
 for i in range(compartments.size()):
  var c=compartments[i]
  if c.get("portrait",false):
   var turn=PI if searched.has(i) else 0.0
   if absf(c.mesh.rotation.y-turn)>.01: create_tween().tween_property(c.mesh,"rotation:y",turn,.65)
   continue
  var destination=c.home+Vector3(0,0,.45 if searched.has(i) else 0)
  if c.mesh.position.distance_to(destination)>.01:
   var tween=create_tween()
   tween.tween_property(c.mesh,"position",destination,.3)

func disturb(pos: Vector3):
 if game.grace>0: return
 # Bounded FIFO: new sounds never postpone the first response or overwrite it.
 if pending_sounds.size()>=8: return
 pending_sounds.append({"pos":pos,"left":[6.0,4.5,3.0,2.0][game.difficulty]})
 if pending_sounds.size()==1: game.sound_event.rpc(game.ghost_pos,.65,"wail")

func tick(delta: float):
 for sound in pending_sounds: sound.left-=delta
 if pending_sounds.is_empty() or pending_sounds[0].left>0: return
 var sound=pending_sounds.pop_front()
 if game.ghost_mode!="chase":
  game.ghost_goal=sound.pos
  game.ghost_mode="investigate"
  game.ghost_timer=45

func reset():
 searched=[]
 pending_sounds=[]
 for c in compartments:
  c.mesh.position=c.home
  c.mesh.rotation.y=0
 intro_left=36.0 if game.test_mode=="" else 0.0
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
 establishing.texture=load("res://assets/ui/title.png")
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
 intro.hide()

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
  if intro_left==0: narration.stop()

func approach(key: Vector3) -> Vector3:
 return Vector3(key.x,5.0*floor(key.y/5.0),key.z+2)

func add_portraits():
 for p in [Vector3(6,1.6,1.95),Vector3(18,1.6,1.95),Vector3(30,1.6,1.95),Vector3(45,1.6,1.95)]:
  container(p,-1,"Family portrait",Vector3(1.2,1.5,.09))
  var c=compartments.back()
  c.portrait=true
  var root=c.mesh
  for side in [-1,1]:
   game._box(root,Vector3(side*.6,0,.08),Vector3(.09,1.6,.12),Color(.28,.19,.08))
   game._box(root,Vector3(0,side*.75,.08),Vector3(1.2,.09,.12),Color(.28,.19,.08))
  var portrait=game._box(root,Vector3(0,0,.065),Vector3(1.1,1.4,.015),Color(.25,.22,.17))
  if ResourceLoader.exists("res://assets/ui/title.png"):
   var paint=StandardMaterial3D.new()
   paint.albedo_texture=load("res://assets/ui/title.png")
   paint.albedo_color=Color(.65,.55,.4)
   portrait.material_override=paint
  # A recessed backing and hook are revealed when the frame turns.
  game._box(root,Vector3(0,0,-.08),Vector3(.95,1.2,.02),Color(.12,.08,.045))

func furnish():
 # Wall-side props preserve the main circulation routes; collisions are pruned from navigation above.
 for p in [Vector3(14,0,3),Vector3(4,0,27),Vector3(70,5,1),Vector3(100,5,0),Vector3(110,10,48),Vector3(110,-5,39)]:
  preload("res://realistic_art.gd").place(game.world,"ClassicConsole_01",p,1.1)
  var collider=game.horror.panel(game.world,p+Vector3(0,.5,0),Vector3(1.8,1,.7),true)
  collider.visible=false
  game.navigation.set_point_disabled(game.navigation.get_closest_point(p),true)
  for n in range(4):
   var book=game.horror.panel(game.world,p+Vector3((n-1.5)*.23,1.15+n*.025,0),Vector3(.19,.07,.34))
   book.rotation.y=n*.18
 for p in [Vector3(3,0,4),Vector3(21,0,34),Vector3(84,5,3),Vector3(96,5,17),Vector3(114,10,46)]:
  preload("res://realistic_art.gd").place(game.world,"ArmChair_01",p,1.4,PI)
  var blocker=game.horror.panel(game.world,p+Vector3(0,.55,0),Vector3(1,1.1,1),true)
  blocker.visible=false
  game.navigation.set_point_disabled(game.navigation.get_closest_point(p),true)
 # Dresser cornices, shaped feet, inner drawer rails and brass escutcheons.
 for c in compartments:
  if c.get("portrait",false): continue
  var root=c.mesh
  for x in [-.43,.43]: game.horror.panel(root,Vector3(x,0,.3),Vector3(.035,.48,.035))
  game._box(root,Vector3(0,-.11,.335),Vector3(.055,.08,.025),Color(.36,.27,.12))

func cinematic_camera():
 if intro_left<=0: return
 var t=36-intro_left
 var shot=mini(4,int(t/7.2))
 var f=fmod(t,7.2)/7.2
 var starts=[Vector3(12,1.8,12),Vector3(9,1.7,20),Vector3(75,6.8,12),Vector3(80,6.4,9),Vector3(39,1.8,27)]
 var ends=[Vector3(12,1.7,7),Vector3(9,1.5,17),Vector3(78,6.6,10),Vector3(80,5.9,7.5),Vector3(40,1.5,28)]
 var targets=[Vector3(18,1.4,3),Vector3(9,1.4,15),Vector3(81,5.6,6),Vector3(81,5.4,6),Vector3(42,1,30)]
 game.camera.position=starts[shot].lerp(ends[shot],smoothstep(0,1,f))
 game.camera.look_at(targets[shot])
 game.lamp.visible=false
 game.touch.hide()
 game.hint.hide()
