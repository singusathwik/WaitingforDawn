extends Node
## Fixtures position players; all client actions travel through the real ENet RPCs.
var game
var host=false
var elapsed=0.0
var stage=0
var deadline=0.0
var saw_key=false
var saw_down=false
var saw_revive=false
var saw_win=false
var saw_restart=false
var done=false
var next_board_attempt=0.0

func setup(g,mode):
	game=g
	game.important_state_received.connect(_observe_state)
	host=mode=="coop-host"
	if host:
		game._host()
		game._set_difficulty(3)
	else:
		game.ip_edit.text="127.0.0.1"
		game._join()

func _observe_state():
	# Several reliable updates can arrive in one rendered frame. Observe each snapshot,
	# rather than losing the short down/revive state when another client revives first.
	if host or game.phase!="playing": return
	if game.found.size()==1: saw_key=true
	if game.people.has(1) and game.people[1].down:
		saw_down=true
		if stage==2:
			game._request_action("use")
			stage=3
	if saw_down and game.people.has(1) and not game.people[1].down: saw_revive=true

func check(ok: bool,label: String) -> bool:
	if not ok:
		print("COOP FAIL: ",label)
		done=true
		game._quit(1)
	return ok

func place(id: int,pos: Vector3):
	game.people[id].pos=pos
	game.actors[id].position=pos

func use(id: int):
	game.last_action.erase(id)
	game._act(id,"use")

func _process(delta):
	if done: return
	elapsed+=delta
	if elapsed>28: check(false,"timeout stage "+str(stage)); return
	if host: _host_step()
	else: _client_step()

func _host_step():
	if stage==0 and game.people.size()==4:
		for p in game.people.values():
			if not p.ready: return
		game._start()
		game.grace=1000
		for n in range(game.exploration.compartments.size()):
			if game.keys.has(game.exploration.compartments[n].pos): game.exploration.searched.append(n); game.exploration.opened.append(n)
		for id in game.people: game._test_aim_key(id,0)
		game._sync_important()
		deadline=elapsed+1
		stage=1
	elif stage==1 and elapsed>deadline:
		use(1)
		if not check(game.found.size()==1,"simultaneous RPC pickup counted once"): return
		print("COOP PASS pickup race")
		for id in game.people: place(id,Vector3(12,0,18))
		game.people[1].down=true
		game._sync_important()
		deadline=elapsed+1
		stage=2
	elif stage==2 and elapsed>deadline:
		if not check(not game.people[1].down,"remote revive"): return
		print("COOP PASS remote revive")
		for i in range(1,12): game._test_aim_key(1,i); use(1)
		place(1,Vector3(33,0,22))
		use(1)
		if not check(game.door_open and game.found.size()==12,"shared objectives and garage"): return
		for id in game.people: place(id,Vector3(42,0,29))
		game._sync_important()
		deadline=elapsed+5
		stage=3
	elif stage==3 and elapsed>deadline:
		if not check(game.phase=="playing","cannot escape without host boarding"): return
		use(1)
		if game.phase!="escaping": print(game.people)
		if not check(game.phase=="escaping","all clients boarded"): return
		print("COOP PASS all-player boarding")
		stage=4
	elif stage==4 and game.phase=="won":
		print("COOP PASS synchronized victory")
		deadline=elapsed+.5
		stage=7
	elif stage==7 and elapsed>deadline:
		game._return_lobby()
		deadline=elapsed+.75
		stage=5
	elif stage==5 and elapsed>deadline:
		game._set_difficulty(0)
		# Test fixture re-readies everyone after checking ruleset change semantics elsewhere.
		for person in game.people.values(): person.ready=true
		game._start()
		game.grace=1000
		for n in range(game.exploration.compartments.size()):
			if game.keys.has(game.exploration.compartments[n].pos): game.exploration.searched.append(n); game.exploration.opened.append(n)
		if not check(game.found.is_empty() and not game.door_open,"restart reset"): return
		deadline=elapsed+1
		stage=6
	elif stage==6 and elapsed>deadline:
		print("COOP PASS restart and host shutdown")
		done=true
		game._quit()

func _client_step():
	if game.phase=="lobby" and stage==0:
		if not check(game.difficulty==3,"lobby difficulty replication"): return
		game._set_difficulty(0)
		if not check(game.difficulty==3,"client changed host difficulty"): return
		game._toggle_ready(); stage=1
	if game.phase=="playing":
		if game.round_id==2:
			saw_restart=game.found.is_empty() and not game.door_open and game.difficulty==0
			return
		if stage==1:
			if not check(game.difficulty==3 and game.people[game.multiplayer.get_unique_id()].bottles==1,"match difficulty replication"): return
			game._test_aim_key(game.multiplayer.get_unique_id(),0)
			game.input_request.rpc_id(1,{"move":Vector2.ZERO,"yaw":game.yaw,"pitch":game.pitch})
			game._request_action("use")
			stage=2
		if game.found.size()==1: saw_key=true
		if game.people.has(1) and game.people[1].down:
			saw_down=true
			if stage==2: game._request_action("use"); stage=3
		if saw_down and not game.people[1].down: saw_revive=true
		if stage==3 and game.door_open and game.found.size()==12 and game.people[game.multiplayer.get_unique_id()].pos.distance_to(Vector3(42,0,29))<2:
			# Wait for authoritative acknowledgement; an earlier action may still be on cooldown.
			if game.people[game.multiplayer.get_unique_id()].boarded:
				stage=4
			elif elapsed>=next_board_attempt:
				game._request_action("use")
				next_board_attempt=elapsed+.4
	if game.phase=="won": saw_win=true
	if stage>=4 and game.phase=="menu":
		print("COOP observations ",saw_key," ",saw_down," ",saw_revive," ",saw_win," ",saw_restart)
		if not check(saw_key and saw_down and saw_revive and saw_win and saw_restart,"replicated objectives/revive/win/restart"): return
		print("COOP CLIENT PASS replicated pickup, revive, victory, reset, departure")
		done=true
		game._quit()
