extends Node
var game
var host=false
var stage=0
var time=0.0
var client=0
var deadline=0.0
var next_action=0.0
var saw_clue=false
var saw_door=false
var saw_hidden=false
var saw_exit=false

func setup(g,mode):
	game=g
	host=mode=="horror-host"
	if host: game._host()
	else:
		game.ip_edit.text="127.0.0.1"
		game._join()

func place(id: int,p: Vector3):
	game.people[id].pos=p
	game.actors[id].position=p
	game._sync_important()

func _process(delta):
	time+=delta
	if time>30:
		print("HORROR FAIL timeout stage ",stage)
		game._quit(1)
		set_process(false)
		return
	if host: host_step()
	else: client_step()

func host_step():
	if stage==0 and game.people.size()==2:
		for id in game.people:
			if id!=1: client=id
		if not game.people[client].ready: return
		game._start()
		game.grace=1000
		place(client,game.horror.NOTES[0]+Vector3(0,0,1.6))
		stage=1
	elif stage==1 and game.horror.clues.has(0):
		print("HORROR NET PASS client discovered shared clue")
		place(client,Vector3(66,5,9))
		stage=2
	elif stage==2 and not game.horror.opened[4]:
		assert(game.horror.blocks(Vector3(63,5,9),Vector3(66,5,9)))
		print("HORROR NET PASS client closed authoritative room door")
		place(client,game.horror.slots[3].entry)
		stage=3
	elif stage==3 and game.people[client].hidden:
		assert(game.people[client].hide_slot==3)
		deadline=time+.8
		stage=4
	elif stage==4 and time>deadline and not game.people[client].hidden:
		print("HORROR NET PASS cupboard entry and exit replicated")
		place(client,game.horror.slots[7].entry)
		stage=5
	elif stage==5 and game.people[client].hidden:
		assert(game.people[client].hide_slot==7)
		deadline=time+.8
		stage=6
	elif stage==6 and time>deadline and not game.people[client].hidden:
		print("HORROR NET PASS under-bed entry and exit replicated")
		game.finish.rpc("won","Interaction test complete")
		deadline=time+.8
		stage=7
	elif stage==7 and time>deadline:
		game._return_lobby()
		game._start()
		game.grace=1000
		deadline=time+1
		stage=8
	elif stage==8 and time>deadline:
		assert(game.horror.clues.is_empty() and game.horror.opened.count(false)==2 and not game.horror.opened[6] and not game.horror.opened[7])
		print("HORROR NET PASS restart cleared clues, doors and hiding")
		game._quit()
		set_process(false)

func act():
	if time<next_action: return
	next_action=time+.5
	game._request_action("use")

func client_step():
	if game.phase=="lobby" and stage==0: game._toggle_ready(); stage=1
	if game.phase=="playing":
		var p=game.people[game.multiplayer.get_unique_id()]
		if game.round_id==2:
			assert(game.horror.clues.is_empty() and game.horror.opened.count(false)==2 and not game.horror.opened[6] and not game.horror.opened[7] and not p.hidden)
			stage=10
			return
		if stage==1 and p.pos.distance_to(game.horror.NOTES[0])<2: act()
		if game.horror.clues.has(0) and stage==1: saw_clue=true; stage=2
		if stage==2 and p.pos.distance_to(Vector3(66,5,9))<.5: act()
		if not game.horror.opened[4] and stage==2: saw_door=true; stage=3
		if stage==3 and p.pos.distance_to(game.horror.slots[3].entry)<.5:
			game.yaw=PI/2
			act()
		if stage==3 and p.hidden: saw_hidden=true; deadline=time+1; stage=4
		if stage==4 and time>deadline:
			if p.hidden: act()
			else: saw_exit=true; stage=5
		if stage==5 and p.pos.distance_to(game.horror.slots[7].entry)<.5:
			game.yaw=-PI/2
			act()
		if stage==5 and p.hidden: deadline=time+1; stage=6
		if stage==6 and time>deadline:
			if p.hidden: act()
			else: stage=7
	if stage==10 and game.phase=="menu":
		assert(saw_clue and saw_door and saw_hidden and saw_exit)
		print("HORROR CLIENT PASS shared clue, room door, cupboard, bed, restart and departure")
		game._quit()
		set_process(false)
