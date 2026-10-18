extends Node
## Presentation only. Never mutates authoritative gameplay state.
var game
var fixtures: Array = []
var voices: Array[AudioStreamPlayer3D] = []
var sounds: Dictionary = {}
var ambience: AudioStreamPlayer
var breathing: AudioStreamPlayer
var pursuit: AudioStreamPlayer
var overlay: ColorRect
var danger = 0.0
var noise_alert=0.0
var elapsed = 0.0
var next_creak = 8.0
var was_down = false
var was_chased = false
var ghost_head: Node3D
var ghost_visual: Node3D
var ghost_animation: AnimationPlayer
var scare_animation: AnimationPlayer
var scare_skeleton: Skeleton3D
var scare_light: OmniLight3D
var head_bone=-1
var current_clip=""
var arms: Array[Node3D] = []
var jaw: Node3D
var scare: Node3D
var scare_time=0.0
var scare_cooldown=0.0
var seen_round=-1
var seen_keys=0
var curtains: Array = []
var previous_ghost=Vector3.ZERO
var stride=0.0
var haunting_stride=0.0
var trembling_props:Array=[]

func setup(owner_game):
	game=owner_game
	preload("res://realistic_art.gd").setup_house(game)
	game.environment.ambient_light_color=Color(.32,.40,.48)
	game.environment.fog_enabled=true
	game.environment.fog_light_color=Color(.035,.055,.07)
	game.environment.fog_density=.009
	game.environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	game.lamp.spot_range=15
	game.lamp.spot_angle=38
	game.lamp.light_energy=2.0
	game.lamp.spot_attenuation=1.1
	# Keep the same stable flashlight path on phones and desktop. Compatibility
	# spot shadows produced diagonal self-shadow bands on the thick wall shell.
	game.lamp.shadow_enabled=false
	for x in [9,18,33,42]: _window(Vector3(x,2,1.55))
	for center in [Vector3(12,0,9),Vector3(36,0,9),Vector3(12,0,33),Vector3(12,-5,30),Vector3(12,-10,30)]:
		_fixture(center+Vector3(-4,2.8,-4),Color(1,.62,.32))
	game.nursery.fixtures(self)
	# Architectural profiles are exported meshes with worn wood PBR maps.
	_build_architecture()
	_build_ghost()
	for key in ["ambient","pursuit","foot_wood","foot_stone","glass","door","chair","key","stinger","breath","creak","engine","wail"]:
		sounds[key]=load("res://assets/audio/"+key+".wav")
	for key in ["ambient","pursuit","breath"]:
		sounds[key].loop_mode=AudioStreamWAV.LOOP_FORWARD
		sounds[key].loop_end=int(sounds[key].get_length()*sounds[key].mix_rate)
	ambience=AudioStreamPlayer.new()
	add_child(ambience)
	ambience.stream=sounds.ambient
	ambience.volume_db=-27
	if DisplayServer.get_name()!="headless": ambience.play()
	pursuit=AudioStreamPlayer.new()
	add_child(pursuit)
	pursuit.stream=sounds.pursuit
	pursuit.volume_db=-60
	if DisplayServer.get_name()!="headless": pursuit.play()
	breathing=AudioStreamPlayer.new()
	add_child(breathing)
	breathing.stream=sounds.breath
	breathing.volume_db=-60
	# A bounded pool avoids allocating/leaking audio players on every footstep.
	for i in range(12):
		var voice=AudioStreamPlayer3D.new()
		game.world.add_child(voice)
		voice.max_distance=32
		voice.unit_size=3
		voices.append(voice)
	var layer=CanvasLayer.new()
	layer.layer=-1
	game.add_child(layer)
	overlay=ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var material=ShaderMaterial.new()
	material.shader=load("res://shaders/vignette.gdshader")
	overlay.material=material
	layer.add_child(overlay)

func _window(p: Vector3):
	var pane=MeshInstance3D.new()
	var quad=QuadMesh.new()
	quad.size=Vector2(2,1.9)
	pane.mesh=quad
	var glass=StandardMaterial3D.new()
	glass.albedo_color=Color(.12,.19,.24)
	glass.albedo_texture=load("res://assets/textures/rough_plaster_broken/rough.jpg")
	glass.roughness=.62
	glass.emission_enabled=true
	glass.emission=Color(.025,.045,.065)
	pane.material_override=glass
	game.world.add_child(pane)
	pane.position=p+Vector3(0,0,0.025)
	_fixture(p+Vector3(0,0,1),Color(.27,.48,.7),false)

func _portrait(p: Vector3):
	game._box(game.world,p,Vector3(1.4,1.8,0.09),Color(.35,.25,.12))
	game._box(game.world,p+Vector3(0,0,0.06),Vector3(1.2,1.6,0.02),Color(.045,.055,.05))
	_sphere(game.world,p+Vector3(0,0.18,0.11),Vector3(0.28,0.38,0.03),Color(.28,.27,.21))
	game._box(game.world,p+Vector3(0,-0.4,0.1),Vector3(0.65,0.6,0.02),Color(.09,.1,.085))

func _fixture(p: Vector3,color: Color,lantern=true):
	if lantern:
		preload("res://realistic_art.gd").place(game.world,"Lantern_01",p-Vector3(0,0.28,0),.55)
	var light=OmniLight3D.new()
	game.world.add_child(light)
	light.position=p
	light.light_color=color
	light.omni_range=6.5
	light.light_energy=.4 if lantern else .3
	light.set_meta("base_energy",light.light_energy)
	light.shadow_enabled=false
	fixtures.append(light)

func _sphere(parent: Node,p: Vector3,size: Vector3,color: Color) -> MeshInstance3D:
	var mesh=MeshInstance3D.new()
	var sphere=SphereMesh.new()
	sphere.radial_segments=20
	sphere.rings=12
	mesh.mesh=sphere
	mesh.material_override=game._material(color)
	if color.r>.3 and color.g>.3:
		var skin=ShaderMaterial.new()
		skin.shader=load("res://shaders/skin.gdshader")
		skin.set_shader_parameter("tint",color)
		mesh.material_override=skin
	parent.add_child(mesh)
	mesh.position=p
	mesh.scale=size
	return mesh

func _build_ghost():
	for child in game.ghost.get_children(): child.queue_free()
	ghost_visual=load("res://assets/models/mourning_ghost.glb").instantiate()
	game.ghost.add_child(ghost_visual)
	ghost_visual.scale=Vector3.ONE*(2.35/7.216115)
	ghost_visual.rotation.y=PI
	for mesh in preload("res://realistic_art.gd").meshes(ghost_visual):
		for surface in range(mesh.mesh.get_surface_count()):
			var material=mesh.get_active_material(surface).duplicate()
			if material is StandardMaterial3D:
				material.albedo_color=Color(.07,.085,.09) if ("mourning" in str(mesh.name).to_lower() or "veil" in str(mesh.name).to_lower()) else Color(.53,.60,.54)
				material.roughness=.94
				material.emission_enabled=true
				material.emission=Color(.012,.022,.019)
			mesh.set_surface_override_material(surface,material)
	ghost_animation=ghost_visual.find_children("*","AnimationPlayer",true,false)[0]
	for name in ghost_animation.get_animation_list():
		if name in ["idle","walk","run"]: ghost_animation.get_animation(name).loop_mode=Animation.LOOP_LINEAR
	ghost_animation.play("idle")
	# The scare uses the same skinned mesh and a real attack clip.
	scare=ghost_visual.duplicate()
	game.camera.add_child(scare)
	scare.visible=false
	scare.rotation.y=0
	scare_animation=scare.find_children("*","AnimationPlayer",true,false)[0]
	scare_skeleton=scare.find_children("*","Skeleton3D",true,false)[0]
	head_bone=scare_skeleton.find_bone("head")
	var fill=OmniLight3D.new()
	game.camera.add_child(fill)
	fill.position=Vector3(0.2,0.15,-0.3)
	fill.omni_range=1.3
	fill.light_color=Color(.55,.69,.72)
	fill.light_energy=.18
	fill.visible=false
	scare_light=fill


func trigger_scare():
	if scare_cooldown>0: return
	scare_time=1.05
	scare_animation.play("attack2",.08)
	scare_cooldown=18
	play("stinger",game.camera.position-Vector3.UP,.7)

func _animate_horror(delta: float):
	if seen_round!=game.round_id:
		seen_round=game.round_id
		seen_keys=game.found.size()
		was_down=false
		scare_time=0
		scare_cooldown=0
	scare_cooldown=maxf(0,scare_cooldown-delta)
	var id=game.multiplayer.get_unique_id()
	if game.people.has(id):
		var down=game.people[id].down
		if down and not was_down: trigger_scare()
		was_down=down
		if game.found.size()>seen_keys and game.phase=="playing":
			# One brief apparition at the second shared key, once per round.
			if game.found.size()==2: trigger_scare()
		seen_keys=game.found.size()
	if game.phase in ["menu","lobby","won"]: scare_time=0
	scare.visible=scare_time>0
	game.hint.visible=game.phase in ["playing","escaping"] and scare_time<=0
	scare_light.visible=scare_time>0
	if scare_time>0:
		game.lamp.visible=false
		scare_time=maxf(0,scare_time-delta)
		var attack=clampf((1.05-scare_time)*5,0,1)
		var target=Vector3(0,.02,-lerpf(2.2,.68,attack))
		if head_bone>=0:
			var head=scare_skeleton.global_transform*scare_skeleton.get_bone_global_pose(head_bone).origin
			scare.position+=target-game.camera.to_local(head)
	if game.phase=="lost": game.menu.visible=scare_time<=0
	var motion=game.ghost_pos-previous_ghost
	previous_ghost=game.ghost_pos
	if game.phase=="playing" and game.grace<=0 and motion.length()<1.0:
		haunting_stride+=motion.length()
		if haunting_stride>.85:
			haunting_stride=0.0
			play("foot_stone",game.ghost_pos,.32 if game.ghost_mode=="chase" else .18)
	stride+=delta
	var clip="run" if game.ghost_mode=="chase" else ("walk" if motion.length()>.003 else "idle")
	if game.ghost_pos.distance_to(game.camera.position)<2.5 and game.ghost_mode=="chase": clip="attack1_l"
	if clip!=current_clip:
		ghost_animation.play(clip,.22)
		current_clip=clip
	ghost_animation.speed_scale=.85 if clip=="walk" else (1.1 if clip=="run" else 1.0)
	if motion.length()>.003:
		game.ghost.rotation.y=lerp_angle(game.ghost.rotation.y,atan2(motion.x,motion.z)+PI,1-exp(-delta*8))
	for item in curtains: item.rotation.x=sin(elapsed*.65+item.position.x)*.018
	for item in trembling_props:
		var proximity=clampf(1-item.global_position.distance_to(game.ghost_pos)/9.0,0,1) if game.phase=="playing" and game.grace<=0 else 0.0
		item.rotation.z=sin(elapsed*18+item.position.x)*.018*proximity

func play(kind: String,pos: Vector3,strength: float):
	if DisplayServer.get_name()=="headless": return
	if not sounds.has(kind): return
	for voice in voices:
		if not voice.playing:
			voice.position=pos+Vector3.UP
			voice.stream=sounds[kind]
			voice.volume_db=linear_to_db(maxf(strength,.01))
			voice.pitch_scale=1.0 if kind in ["key","engine","stinger"] else randf_range(.92,1.08)
			voice.play()
			return

func _process(delta):
	if not is_instance_valid(game): return
	elapsed+=delta
	_animate_horror(delta)
	var active=game.phase in ["playing","escaping"]
	overlay.visible=active
	var close=0.0
	if active and game.ghost.visible and is_instance_valid(game.horror):
		close=game.horror.threat()
	noise_alert=maxf(0,noise_alert-delta)
	danger=lerpf(danger,maxf(close,noise_alert*.18),1-exp(-delta*3))
	overlay.material.set_shader_parameter("danger",danger)
	pursuit.volume_db=lerpf(-60,-13,danger) if active else -60
	ambience.volume_db=-24 if active else -33
	if close>.15 and active:
		breathing.volume_db=lerpf(-26,-9,close)
		breathing.pitch_scale=lerpf(.85,1.35,close)
		if not breathing.playing and DisplayServer.get_name()!="headless": breathing.play()
	else: breathing.stop()
	if not active: was_chased=false
	if active:
		var chase=game.ghost_mode=="chase" and close>.25
		if chase and not was_chased: play("stinger",game.ghost_pos,.55)
		was_chased=chase
		game.ghost.rotation.z=sin(stride)*.025


	# Only three nearby decorative lights + the flashlight contribute at once.
	fixtures.sort_custom(func(a,b): return a.global_position.distance_squared_to(game.camera.position)<b.global_position.distance_squared_to(game.camera.position))
	for i in range(fixtures.size()):
		fixtures[i].visible=active and i<3 and fixtures[i].global_position.y>0
		if i<3:
			var presence=clampf(1-fixtures[i].global_position.distance_to(game.ghost_pos+Vector3.UP)/8.0,0,1) if game.grace<=0 else 0.0
			var flutter=lerpf(1.0,.55+.35*sin(elapsed*19+i),presence)
			fixtures[i].light_energy=flutter*(float(fixtures[i].get_meta("base_energy",.7))+sin(elapsed*2.7+i)*.025)*(.25 if scare_time>0 else (.12 if fmod(elapsed+i*3,17)<.18 else 1.0))

func stop_audio():
	for voice in voices:
		if is_instance_valid(voice): voice.stop(); voice.stream=null
	breathing.stop()
	breathing.stream=null
	ambience.stop()
	pursuit.stop()
	ambience.stream=null
	pursuit.stream=null

func _dress_house():
	# Uneven skirting, pane cracks and water-damaged plaster add scale and age.
	for center in [Vector3(12,0,9),Vector3(36,0,9),Vector3(12,0,33),Vector3(12,5,9),Vector3(12,-5,30),Vector3(12,-10,30)]:
		for side in [-1,1]:
			for height in [.12,.23]:
				game._box(game.world,center+Vector3(side*5.65,height,0),Vector3(0.12,0.07,10.8),Color(.12,.10,.075))
	for x in [9,18,33,42]:
		for i in range(5):
			var crack=game._box(game.world,Vector3(x-.6+i*.17,2.6-i*.13,1.69),Vector3(0.012,0.28,0.008),Color(.055,.075,.08))
			crack.rotation.z=.5+sin(i)*.5
	for node in game.world.get_children():
		if node is MeshInstance3D and node.mesh is BoxMesh:
			if node.mesh.size.y==2.35: curtains.append(node)
	# A worn central runner, edging and loose papers remain outside collision paths.
	for z in [12,18,21]:
		game._box(game.world,Vector3(27,.025,z),Vector3(1.9,0.018,2.7),Color(.16,.055,.035))
		for x in [-.88,.88]: game._box(game.world,Vector3(27+x,.037,z),Vector3(0.06,0.012,2.7),Color(.32,.23,.12))
	for i in range(18):
		var paper=game._box(game.world,Vector3(16+sin(i*4.7)*2,.035,17+cos(i*2.1)*2),Vector3(0.18,0.008,0.28),Color(.30,.28,.21))
		paper.rotation.y=i*1.7

func _build_architecture():
	if not ResourceLoader.exists("res://assets/models/architecture.glb"): return
	var wood=preload("res://realistic_art.gd").pbr("old_wooden_floor_01",.5)
	for x in [9,18,33,42]:
		var frame=load("res://assets/models/architecture.glb").instantiate()
		game.world.add_child(frame)
		frame.position=Vector3(x,0,1.65)
		for mesh in preload("res://realistic_art.gd").meshes(frame):
			if "Curtain" in mesh.name:
				var fabric=preload("res://realistic_art.gd").pbr("quatrefoil_jacquard_fabric",.8)
				fabric.albedo_color=Color(.27,.16,.12)
				fabric.cull_mode=BaseMaterial3D.CULL_DISABLED
				mesh.material_override=fabric
				curtains.append(mesh)
			else: mesh.material_override=wood
