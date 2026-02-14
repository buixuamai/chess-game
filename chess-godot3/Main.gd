extends Node2D

var board = []
var turn = true
var selected = null
var sq = 80
var off_x = 20
var off_y = 80

var game_over = false
var winner = ""
var history = []

var ai_on = false
var ai_thinking = false
var ai_timer = 0

var cap_white = []
var cap_black = []
var white_t = 300
var black_t = 300
var game_started = false

var bt_new
var bt_undo
var bt_ai
var lb_turn
var lb_timer
var lb_cap_b
var lb_cap_w
var lb_status
var lb_hist

func _ready():
	create_buttons()
	init_game()

func create_buttons():
	var lb = Label.new()
	lb.rect_pos = Vector2(20, 10)
	lb.text = "Chess"
	add_child(lb)
	
	bt_new = Button.new()
	bt_new.text = "New"
	bt_new.rect_pos = Vector2(680, 20)
	bt_new.rect_size = Vector2(80, 30)
	bt_new.connect("pressed", self, "new_game")
	add_child(bt_new)
	
	bt_undo = Button.new()
	bt_undo.text = "Undo"
	bt_undo.rect_pos = Vector2(770, 20)
	bt_undo.rect_size = Vector2(80, 30)
	bt_undo.connect("pressed", self, "undo")
	add_child(bt_undo)
	
	bt_ai = Button.new()
	bt_ai.text = "AI: OFF"
	bt_ai.rect_pos = Vector2(860, 20)
	bt_ai.rect_size = Vector2(80, 30)
	bt_ai.connect("pressed", self, "toggle_ai")
	add_child(bt_ai)
	
	lb_turn = Label.new()
	lb_turn.rect_pos = Vector2(680, 60)
	lb_turn.text = "Turn: White"
	add_child(lb_turn)
	
	lb_timer = Label.new()
	lb_timer.rect_pos = Vector2(860, 60)
	lb_timer.text = "5:00 - 5:00"
	add_child(lb_timer)
	
	lb_cap_b = Label.new()
	lb_cap_b.rect_pos = Vector2(680, 100)
	lb_cap_b.text = "White taken:"
	add_child(lb_cap_b)
	
	lb_cap_w = Label.new()
	lb_cap_w.rect_pos = Vector2(680, 250)
	lb_cap_w.text = "Black taken:"
	add_child(lb_cap_w)
	
	lb_status = Label.new()
	lb_status.rect_pos = Vector2(680, 310)
	lb_status.text = "Click piece to move"
	add_child(lb_status)
	
	var lh = Label.new()
	lh.rect_pos = Vector2(680, 350)
	lh.text = "History:"
	add_child(lh)
	
	lb_hist = Label.new()
	lb_hist.rect_pos = Vector2(680, 380)
	add_child(lb_hist)

func new_game():
	init_game()

func toggle_ai():
	ai_on = not ai_on
	bt_ai.text = "AI: ON" if ai_on else "AI: OFF"
	init_game()

func undo():
	if history.size() > 0:
		var h = history.pop_back()
		board[h.to_y][h.to_x] = h.captured
		board[h.from_y][h.from_x] = h.piece
		turn = h.turn_before
		if h.captured != "":
			if turn:
				cap_white.erase(h.captured)
			else:
				cap_black.erase(h.captured)
		ai_thinking = false
		update_ui()
		update()

func init_game():
	board = [
		["r","n","b","q","k","b","n","r"],
		["p","p","p","p","p","p","p","p"],
		["","","","","","","",""],
		["","","","","","","",""],
		["","","","","","","",""],
		["","","","","","","",""],
		["P","P","P","P","P","P","P","P"],
		["R","N","B","Q","K","B","N","R"]
	]
	turn = true
	selected = null
	game_over = false
	winner = ""
	history = []
	cap_white = []
	cap_black = []
	white_t = 300
	black_t = 300
	game_started = false
	ai_thinking = false
	ai_timer = 0
	update_ui()
	update()

func _process(delta):
	if game_started and not game_over:
		if turn:
			white_t -= delta
		else:
			black_t -= delta
	
	# AI move after player moves
	if ai_on and not turn and not game_over and not ai_thinking:
		if history.size() > 0:
			ai_timer += delta
			if ai_timer >= 0.5:
				ai_thinking = true
				make_ai_move()

func make_ai_move():
	var moves = []
	for y in range(8):
		for x in range(8):
			var p = board[y][x]
			if p != "" and p >= "a" and p <= "z":
				for ty in range(8):
					for tx in range(8):
						if valid_move(x, y, tx, ty):
							moves.append({"fx":x,"fy":y,"tx":tx,"ty":ty,"p":p,"t":board[ty][tx]})
	
	if moves.size() > 0:
		var best = moves[randi() % moves.size()]
		if best.t != "":
			cap_white.append(best.t)
		
		var h = {"from_x":best.fx,"from_y":best.fy,"to_x":best.tx,"to_y":best.ty,"captured":best.t,"piece":best.p,"turn_before":turn}
		history.append(h)
		board[best.ty][best.tx] = board[best.fy][best.fx]
		board[best.fy][best.fx] = ""
		turn = not turn
		if not game_started:
			game_started = true
		check_end()
	
	ai_thinking = false
	ai_timer = 0
	update_ui()
	update()

func check_end():
	var wk = false
	var bk = false
	for y in range(8):
		for x in range(8):
			if board[y][x] == "K": wk = true
			elif board[y][x] == "k": bk = true
	if not wk: game_over = true; winner = "Black"
	elif not bk: game_over = true; winner = "White"

func update_ui():
	if game_over:
		lb_turn.text = "Game Over"
		lb_status.text = winner + " wins!"
	else:
		lb_turn.text = "Turn: " + ("White" if turn else "Black")
		lb_status.text = "Your turn" if turn else "AI thinking..."
	
	var wm = int(white_t)/60
	var ws = int(white_t)%60
	var bm = int(black_t)/60
	var bs = int(black_t)%60
	lb_timer.text = str(wm)+":"+("%02d"%ws)+" - "+str(bm)+":"+("%02d"%bs)
	
	var wt = "White taken: "
	for p in cap_white: wt += p+" "
	lb_cap_b.text = wt if wt != "White taken: " else "none"
	
	var bt = "Black taken: "
	for p in cap_black: bt += p+" "
	lb_cap_w.text = bt if bt != "Black taken: " else "none"
	
	var h = ""
	var i = 0
	while i < history.size():
		var wm = history[i] if i < history.size() else null
		var bm = history[i+1] if i+1 < history.size() else null
		var mn = str(int(i/2)+1)+". "
		if wm: mn += notf(wm.from_x,wm.from_y,wm.to_x,wm.to_y,wm.piece,wm.captured)
		if bm: mn += " "+notf(bm.from_x,bm.from_y,bm.to_x,bm.to_y,bm.piece,bm.captured)
		h += mn+"\n"
		i += 2
	lb_hist.text = h

func notf(fx,fy,tx,ty,p,c):
	var f = ["a","b","c","d","e","f","g","h"]
	var r = ["8","7","6","5","4","3","2","1"]
	var pc = {"K":"K","Q":"Q","R":"R","B":"B","N":"N","P":""}
	var pc2 = pc.get(p.to_upper(),"")
	if c != "": return pc2+f[fx]+"x"+f[tx]+r[ty]
	return pc2+f[tx]+r[ty]

func _draw():
	draw_rect(Rect2(0,0,1100,800),Color(0.1,0.1,0.15))
	
	for y in range(8):
		for x in range(8):
			var bx = off_x + x*sq
			var by = off_y + y*sq
			var c = Color("#f0d9b5") if (x+y)%2==0 else Color("#b58863")
			draw_rect(Rect2(bx,by,sq,sq),c)
	
	if selected:
		var x = selected.x
		var y = selected.y
		var bx = off_x + x*sq
		var by = off_y + y*sq
		draw_rect(Rect2(bx,by,sq,sq),Color(1,1,0,0.4))
		for ty in range(8):
			for tx in range(8):
				if valid_move(x,y,tx,ty):
					var mx = off_x + tx*sq + sq/2
					var my = off_y + ty*sq + sq/2
					draw_circle(Vector2(mx,my),10,Color(0,1,0,0.5))
	
	for y in range(8):
		for x in range(8):
			var p = board[y][x]
			if p != "": draw_piece(x,y,p)

func draw_piece(x,y,p):
	var cx = off_x + x*sq + sq/2
	var cy = off_y + y*sq + sq/2
	var white = p >= "A" and p <= "Z"
	var pc = p.to_lower()
	
	var bc = Color(0.95,0.95,0.9) if white else Color(0.15,0.15,0.15)
	var fc = Color(0.7,0.7,0.65) if white else Color(0.08,0.08,0.08)
	
	draw_circle(Vector2(cx+2,cy+2),30,Color(0,0,0,0.25))
	
	match pc:
		"k":
			draw_circle(Vector2(cx,cy+5),25,bc)
			draw_circle(Vector2(cx,cy+5),22,fc)
			draw_rect(Rect2(cx-4,cy-10,8,18),bc)
			draw_rect(Rect2(cx-12,cy-12,24,5),bc)
			draw_rect(Rect2(cx-3,cy-18,6,14),bc)
		"q":
			draw_circle(Vector2(cx,cy+5),25,bc)
			draw_circle(Vector2(cx,cy+5),22,fc)
			draw_rect(Rect2(cx-4,cy-8,8,16),bc)
			draw_rect(Rect2(cx-10,cy-16,20,5),bc)
			draw_circle(Vector2(cx-8,cy-18),4,bc)
			draw_circle(Vector2(cx,cy-20),4,bc)
			draw_circle(Vector2(cx+8,cy-18),4,bc)
		"r":
			draw_rect(Rect2(cx-20,cy-5,40,30),bc)
			draw_rect(Rect2(cx-18,cy-3,36,26),fc)
			draw_rect(Rect2(cx-22,cy-18,10,14),bc)
			draw_rect(Rect2(cx-5,cy-20,10,16),bc)
			draw_rect(Rect2(cx+12,cy-18,10,14),bc)
		"b":
			draw_circle(Vector2(cx,cy+5),22,bc)
			draw_circle(Vector2(cx,cy+5),19,fc)
			draw_rect(Rect2(cx-4,cy-8,8,14),bc)
			draw_circle(Vector2(cx,cy-10),14,bc)
			draw_rect(Rect2(cx-2,cy-22,4,6),bc)
		"n":
			draw_rect(Rect2(cx-15,cy-5,30,25),bc)
			draw_rect(Rect2(cx-13,cy-3,26,21),fc)
			draw_rect(Rect2(cx+5,cy-18,14,16),bc)
			draw_rect(Rect2(cx+15,cy-22,5,7),bc)
		"p":
			draw_circle(Vector2(cx,cy+8),18,bc)
			draw_circle(Vector2(cx,cy+8),15,fc)
			draw_rect(Rect2(cx-3,cy-5,6,14),bc)
			draw_circle(Vector2(cx,cy-5),10,bc)

func _input(event):
	if ai_thinking: return
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		var x = int((event.position.x - off_x) / sq)
		var y = int((event.position.y - off_y) / sq)
		if x >= 0 and x < 8 and y >= 0 and y < 8:
			click(x,y)

func click(x,y):
	var p = board[y][x]
	var wp = p != "" and p >= "A" and p <= "Z"
	var bp = p != "" and p >= "a" and p <= "z"
	
	if ai_on and turn and bp: return
	
	if selected:
		var fx = selected.x
		var fy = selected.y
		if valid_move(fx,fy,x,y):
			var c = board[y][x]
			var h = {"from_x":fx,"from_y":fy,"to_x":x,"to_y":y,"captured":c,"piece":board[fy][fx],"turn_before":turn}
			history.append(h)
			board[y][x] = board[fy][fx]
			board[fy][fx] = ""
			if c != "":
				if turn: cap_black.append(c)
				else: cap_white.append(c)
			turn = not turn
			selected = null
			if not game_started: game_started = true
			check_end()
			update_ui()
			update()
		else:
			if turn and wp: selected = Vector2(x,y)
			elif not turn and bp and not ai_on: selected = Vector2(x,y)
			else: selected = null
	else:
		if turn and wp: selected = Vector2(x,y)
		elif not turn and bp and not ai_on: selected = Vector2(x,y)
	update()

func valid_move(fx,fy,tx,ty):
	if fx==tx and fy==ty: return false
	var p = board[fy][fx]
	var t = board[ty][tx]
	if t != "":
		var tw = t >= "A" and t <= "Z"
		var pw = p >= "A" and p <= "Z"
		if tw == pw: return false
	match p.to_lower():
		"p": return pawn(fx,fy,tx,ty,p>="A"and p<="Z")
		"r": return line(fx,fy,tx,ty)
		"b": return diag(fx,fy,tx,ty)
		"n": return knight(fx,fy,tx,ty)
		"q": return line(fx,fy,tx,ty) or diag(fx,fy,tx,ty)
		"k": return abs(tx-fx)<=1 and abs(ty-fy)<=1
	return false

func pawn(fx,fy,tx,ty,white):
	var d = -1 if white else 1
	var s = 6 if white else 1
	if fx==tx:
		if ty-fy==d and board[ty][tx]=="": return true
		if fy==s and ty-fy==2*d and board[fy+d][fx]=="" and board[ty][tx]=="": return true
	else:
		if ty-fy==d and abs(tx-fx)==1 and board[ty][tx]!="": return true
	return false

func line(fx,fy,tx,ty):
	if fx!=tx and fy!=ty: return false
	return path(fx,fy,tx,ty)

func diag(fx,fy,tx,ty):
	if abs(tx-fx)!=abs(ty-fy): return false
	return path(fx,fy,tx,ty)

func knight(fx,fy,tx,ty):
	var dx = abs(tx-fx)
	var dy = abs(ty-fy)
	return (dx==2 and dy==1) or (dx==1 and dy==2)

func path(fx,fy,tx,ty):
	var dx = sign(tx-fx)
	var dy = sign(ty-fy)
	var x = fx+dx
	var y = fy+dy
	while x!=tx or y!=ty:
		if board[y][x]!="": return false
		x += dx
		y += dy
	return true
