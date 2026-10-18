extends RefCounted
## Follow complete graph segments. Never discard the remembered sound when a door shuts.
var path=PackedVector3Array()
var goal=Vector3.INF
var refresh=0.0
var doors_hash=0
var knock_left=0.0
var waiting=false

func reset():
	path.clear();goal=Vector3.INF;refresh=0;knock_left=0;waiting=false

func route(g):
	path.clear()
	var start=-1
	var closest=INF
	for id in g.navigation.get_point_ids():
		if g.navigation.is_point_disabled(id):continue
		var p=g.navigation.get_point_position(id)
		var d=p.distance_squared_to(g.ghost_pos)
		if d<closest and g._line_clear(g.ghost_pos,p):start=id;closest=d
	if start<0:return
	# Find the reachable side of a locked/closed room, retaining the actual destination.
	var queue=[start];var visited={start:true};var cursor=0;var best=start;closest=INF
	while cursor<queue.size():
		var id=queue[cursor];cursor+=1
		var p=g.navigation.get_point_position(id)
		var d=p.distance_squared_to(g.ghost_goal)
		if d<closest:closest=d;best=id
		for next in g.navigation.get_point_connections(id):
			if not visited.has(next) and not g.navigation.is_point_disabled(next):
				visited[next]=true;queue.append(next)
	path=g.navigation.get_point_path(start,best)
	# A stair point is an explicit waypoint; do not cut diagonally across its landing.
	if not path.is_empty() and g.ghost_pos.distance_to(path[0])<.12:path.remove_at(0)
	var end=g.navigation.get_point_position(best)
	if end.distance_to(g.ghost_goal)<3.5 and g._line_clear(end,g.ghost_goal):path.append(g.ghost_goal)

func move(g,delta: float,speed: float):
	refresh-=delta;knock_left-=delta
	var changed=doors_hash!=hash(g.horror.opened)
	if goal.distance_to(g.ghost_goal)>.8 or changed or (path.is_empty() and refresh<=0):
		goal=g.ghost_goal;doors_hash=hash(g.horror.opened);refresh=1.0;route(g)
	waiting=false
	if not path.is_empty():
		var target=path[0]
		var step=g.ghost_pos.move_toward(target,delta*speed)
		if not g.horror.blocks(g.ghost_pos,step):g.ghost_pos=step
		else:path.clear()
		if g.ghost_pos.distance_to(target)<.06 and not path.is_empty():path.remove_at(0)
	else:
		waiting=g.ghost_pos.distance_to(g.ghost_goal)>1.5
		if waiting and g.ghost_mode=="patrol":
			# A randomly chosen locked room must not park an idle patrol forever.
			g.ghost_mode="search";g.ghost_timer=2
		if waiting and g.ghost_mode=="investigate" and knock_left<=0:
			knock_left=5.5
			g.sound_event.rpc(g.ghost_pos,.7,"door")
