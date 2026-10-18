extends Node
## Geometry and navigation share these measured stair landings.
var game
var routes: Array=[]
var loose: Array=[]

func build(g):
	game=g
	game._room(Vector3(12,10,9),"BEDROOMS",Color(.2,.18,.15),"east")
	for level in [-5.0,0.0,5.0]:
		routes.append([Vector3(45,level,9),Vector3(52.5,level,9),Vector3(52.5,level+2.5,18),Vector3(57,level+2.5,18),Vector3(57,level+5,9),Vector3(45,level+5,9)])
	routes.append([Vector3(45,0,30),Vector3(52.5,0,30),Vector3(52.5,-2.5,39),Vector3(57,-2.5,39),Vector3(57,-5,30),Vector3(45,-5,30)])
	routes.append([Vector3(12,-5,39),Vector3(12,-5,43.5),Vector3(7.5,-5,43.5),Vector3(7.5,-7.5,51.5),Vector3(12,-7.5,51.5),Vector3(12,-10,42.5),Vector3(12,-10,39)])
	routes.append([Vector3(45,-5,9),Vector3(36,-5,9),Vector3(36,-5,21)])
	routes.append([Vector3(21,5,9),Vector3(27,5,9)])
	routes.append([Vector3(21,10,9),Vector3(27,10,9)])
	routes.append([Vector3(21,-5,30),Vector3(27,-5,30)])
	# Landing platforms are three metres deep. End slopes at their edges rather
	# than under their centres, otherwise their front riser blocks a walking capsule.
	for index in range(routes.size()):
		var expanded=[]
		var source=routes[index]
		for i in range(source.size()-1):
			var a=source[i];var b=source[i+1]
			expanded.append(a)
			if absf(a.y-b.y)>.1:
				var horizontal=Vector3(b.x-a.x,0,b.z-a.z).normalized()*1.5
				expanded.append(a+horizontal)
				expanded.append(b-horizontal)
		expanded.append(source.back())
		routes[index]=expanded
	for route in routes:
		for i in range(route.size()-1): flight(route[i],route[i+1])
	# Seal unused openings. Every exterior doorway leads to a room or enclosed stair.
	for p in [Vector3(1.5,5,9),Vector3(1.5,-5,30),Vector3(36,5,-1.5),Vector3(36,5,19.5),Vector3(36,10,-1.5),Vector3(36,10,19.5),Vector3(36,-5,40.5)]:
		game._box(game.world,p+Vector3(0,1.8,0),Vector3(.35,3.6,3) if p.x in [1.5,25.5] else Vector3(3,3.6,.35),Color(.18,.17,.14),true)
	# Stair towers have an outside shell, intermediate landings and roof.
	for spec in [[9.0,-5.0,19.0],[30.0,-5.0,9.0]]:
		var z=spec[0]; var bottom=spec[1]; var height=spec[2]
		for x in [50.7,58.8]: game._box(game.world,Vector3(x,bottom+height/2,z+5.8),Vector3(.3,height,8.4),Color(.16,.17,.16),true)
		game._box(game.world,Vector3(54.75,bottom+height/2,z+10.7),Vector3(8.4,height,.3),Color(.16,.17,.16),true)
		game._box(game.world,Vector3(54.75,bottom+height/2,z-1.7),Vector3(8.4,height,.3),Color(.16,.17,.16),true)
		game._box(game.world,Vector3(54.75,bottom+height,z+4.5),Vector3(8.4,.3,12.7),Color(.1,.12,.12))
	# Back stair foundation enclosure.
	for x in [5.8,13.8]: game._box(game.world,Vector3(x,-5,47),Vector3(.3,10,13),Color(.12,.15,.14),true)
	game._box(game.world,Vector3(9.8,-5,53.2),Vector3(8,10,.3),Color(.12,.15,.14),true)
	game._box(game.world,Vector3(9.8,.1,47),Vector3(8,.3,13),Color(.12,.15,.14),true)
	# Foundation and surrounding land stop the blank void at the house boundary.
	var apron=game._box(game.world,Vector3(29,-.25,58.25),Vector3(62,.5,35.5),Color(.13,.14,.11),true)
	apron.material_override=preload("res://realistic_art.gd").pbr("rough_plaster_broken",.18)
	apron.material_override.albedo_color=Color(.16,.18,.13)
	apron.set_meta("outdoor_ground",true)
	game._box(game.world,Vector3(16,-10.5,20),Vector3(120,.5,120),Color(.06,.075,.05),true)
	for spec in [[Vector3(-21,-.25,20),Vector3(38,.5,110)],[Vector3(67,-.25,20),Vector3(14,.5,110)],[Vector3(29,-.25,-19),Vector3(62,.5,34)],[Vector3(29,-.25,64),Vector3(62,.5,22)]]:
		var earth=game._box(game.world,spec[0],spec[1],Color(.1,.12,.08),true)
		earth.material_override=preload("res://realistic_art.gd").pbr("rough_plaster_broken",.16)
		earth.material_override.albedo_color=Color(.13,.16,.10)
		earth.set_meta("outdoor_ground",true)
	for x in [-40,72]: game._box(game.world,Vector3(x,-2,20),Vector3(.5,16,115),Color(.09,.11,.09),true)
	for z in [-36,76]: game._box(game.world,Vector3(16,-2,z),Vector3(112,16,.5),Color(.09,.11,.09),true)
	# High contrast raised boards are the only footstep-triggered noise areas.
	for p in [Vector3(15,0,18),Vector3(36,0,9),Vector3(9,0,9),Vector3(36,5,9),Vector3(36,10,9)]:
		loose.append(p)
		for i in range(3):
			var plank=game._box(game.world,p+Vector3((i-1)*.34,.025,0),Vector3(.30,.04,1.8),Color(.20,.13,.07))
			plank.rotation.z=.018*(i-1)

func flight(a: Vector3,b: Vector3):
	var direction=(b-a).normalized()
	var width=Vector3(direction.z,0,-direction.x).normalized()
	var up=direction.cross(width).normalized()
	var floor_mesh=game._box(game.world,(a+b)*.5-up*.15,Vector3(3,.3,a.distance_to(b)+.08),Color(.17,.12,.08),true)
	floor_mesh.basis=Basis(width,up,direction)
	if absf(a.y-b.y)>.1:
		for side in [-1,1]:
			var rail=game._box(game.world,(a+b)*.5+width*side*1.43+Vector3.UP,Vector3(.09,.10,a.distance_to(b)),Color(.10,.065,.035),true)
			rail.basis=Basis(width,up,direction)
			for f in [.05,.35,.65,.95]:
				game._box(game.world,a.lerp(b,f)+width*side*1.43+Vector3.UP*.5,Vector3(.065,1,.065),Color(.12,.08,.045),true)
		var steps=int(ceil(absf(a.y-b.y)/.18))
		for i in range(steps):
			var f=(float(i)+.5)/steps
			var p=a.lerp(b,f)-Vector3(0,.10,0)
			var tread=game._box(game.world,p,Vector3(2.95,.12,Vector2(b.x-a.x,b.z-a.z).length()/steps+.02),Color(.24,.18,.11))
			tread.rotation.y=atan2(b.x-a.x,b.z-a.z)
			# The smooth collision ramp lies above the treads for reliable mobile movement.
	else:
		for side in [-1,1]:
			# Flat bridges have solid walls except at their open ends.
			if a.distance_to(b)>5 and maxf(a.x,b.x)<49:
				var wall=game._box(game.world,(a+b)*.5+width*side*1.65+Vector3(0,1.8,0),Vector3(.22,3.6,a.distance_to(b)-3.3),Color(.19,.17,.14),true)
				wall.rotation.y=atan2(b.x-a.x,b.z-a.z)

func navigation():
	for x in range(-3,4):
		for z in range(-3,4):game._nav_add(Vector3(12+x*3,10,9+z*3))
	for p in game.nav_ids:
		if p.y==10:
			for offset in [Vector3(3,0,0),Vector3(0,0,3)]:
				if game.nav_ids.has(p+offset):game.navigation.connect_points(game.nav_ids[p],game.nav_ids[p+offset])
	for route in routes:
		for i in range(route.size()-1):
			var a=route[i];var b=route[i+1]
			var steps=int(ceil(a.distance_to(b)/1.5))
			var previous=game._nav_add(a)
			for step in range(1,steps+1):
				var next=game._nav_add(a.lerp(b,float(step)/steps))
				game.navigation.connect_points(previous,next)
				previous=next

func loose_board(p: Vector3) -> bool:
	for point in loose:
		if absf(p.y-point.y)<.3 and Vector2(p.x-point.x,p.z-point.z).length()<1.5: return true
	return false
