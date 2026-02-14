extends Node2D

# Chess Game for Godot 3.x

var board = []
var turn = true  # true = white, false = black
var selected_piece = null
var square_size = 80
var board_offset_x = 20
var board_offset_y = 80

var game_over = false
var winner = ""
var move_history = []

# AI features
var ai_enabled = false
var ai_making_move = false

# Additional features
var captured_white = []
var captured_black = []
var white_time = 300
var black_time = 300
var game_started = false

# UI elements
var new_game_btn
var undo_btn
var ai_btn
var save_btn
var load_btn
var history_label
var timer_label
var captured_white_label
var captured_black_label
var status_label
var turn_label

func _ready():
	randomize()
	create_ui()
	init_board()

func create_ui():
	# Title
	var title = Label.new()
	title.rect_position = Vector2(20, 10)
	title.text = "Chess Game"
	add_child(title)
	
	# Buttons
	new_game_btn = Button.new()
	new_game_btn.text = "New"
	new_game_btn.rect_position = Vector2(680, 20)
	new_game_btn.rect_size = Vector2(80, 35)
	new_game_btn.connect("pressed", self, "on_new_game_pressed")
	add_child(new_game_btn)
	
	undo_btn = Button.new()
	undo_btn.text = "Undo"
	undo_btn.rect_position = Vector2(765, 20)
	undo_btn.rect_size = Vector2(80, 35)
	undo_btn.connect("pressed", self, "on_undo_pressed")
	add_child(undo_btn)
	
	ai_btn = Button.new()
	ai_btn.text = "AI: OFF"
	ai_btn.rect_position = Vector2(850, 20)
	ai_btn.rect_size = Vector2(80, 35)
	ai_btn.connect("pressed", self, "on_ai_toggled")
	add_child(ai_btn)
	
	# Turn indicator
	turn_label = Label.new()
	turn_label.rect_position = Vector2(680, 65)
	turn_label.text = "Turn: White"
	add_child(turn_label)
	
	# Timer
	timer_label = Label.new()
	timer_label.rect_position = Vector2(850, 65)
	timer_label.text = "5:00 - 5:00"
	add_child(timer_label)
	
	# Captured
	captured_black_label = Label.new()
	captured_black_label.rect_position = Vector2(680, 100)
	captured_black_label.text = "White taken:"
	add_child(captured_black_label)
	
	captured_white_label = Label.new()
	captured_white_label.rect_position = Vector2(680, 250)
	captured_white_label.text = "Black taken:"
	add_child(captured_white_label)
	
	# Status
	status_label = Label.new()
	status_label.rect_position = Vector2(680, 310)
	status_label.text = "Click piece to move"
	add_child(status_label)
	
	# Move history
	var hist_title = Label.new()
	hist_title.rect_position = Vector2(680, 350)
	hist_title.text = "History:"
	add_child(hist_title)
	
	history_label = Label.new()
	history_label.rect_position = Vector2(680, 380)
	add_child(history_label)

func on_ai_toggled():
	ai_enabled = not ai_enabled
	ai_btn.text = "AI: ON" if ai_enabled else "AI: OFF"
	init_board()

func on_new_game_pressed():
	init_board()

func on_undo_pressed():
	if move_history.size() > 0:
		var last = move_history.pop_back()
		board[last.to_y][last.to_x] = last.captured
		board[last.from_y][last.from_x] = last.piece
		turn = last.turn_before
		if last.captured != "":
			if turn:
				captured_white.erase(last.captured)
			else:
				captured_black.erase(last.captured)
		game_over = false
		ai_making_move = false
		update_ui()
		update()

func init_board():
	board = [
		["r", "n", "b", "q", "k", "b", "n", "r"],
		["p", "p", "p", "p", "p", "p", "p", "p"],
		["", "", "", "", "", "", "", ""],
		["", "", "", "", "", "", "", ""],
		["", "", "", "", "", "", "", ""],
		["", "", "", "", "", "", "", ""],
		["P", "P", "P", "P", "P", "P", "P", "P"],
		["R", "N", "B", "Q", "K", "B", "N", "R"]
	]
	turn = true
	selected_piece = null
	game_over = false
	winner = ""
	move_history = []
	captured_white = []
	captured_black = []
	white_time = 300
	black_time = 300
	game_started = false
	ai_making_move = false
	update_ui()
	update()

func _process(delta):
	# Timer
	if game_started and not game_over:
		if turn:
			white_time -= delta
		else:
			black_time -= delta
	
	# AI move - only after player has moved
	if ai_enabled and not turn and not game_over and not ai_making_move:
		if move_history.size() > 0:
			ai_making_move = true
			call_deferred("do_ai_move")

func do_ai_move():
	yield(get_tree().create_timer(0.5), "timeout")
	
	var moves = []
	for y in range(8):
		for x in range(8):
			var p = board[y][x]
			if p != "" and p >= "a" and p <= "z":
				for ty in range(8):
					for tx in range(8):
						if is_valid_move(x, y, tx, ty):
							moves.append({"fx": x, "fy": y, "tx": tx, "ty": ty, "piece": p, "target": board[ty][tx]})
	
	if moves.size() > 0:
		# Simple AI - pick random move with capture preference
		var best = moves[0]
		var best_score = -1
		for m in moves:
			var score = randi() % 10
			if m.target != "":
				score += 5
			if score > best_score:
				best_score = score
				best = m
		
		var move = {
			"from_x": best.fx, "from_y": best.fy,
			"to_x": best.tx, "to_y": best.ty,
			"captured": best.target, "piece": best.piece,
			"turn_before": turn
		}
		move_history.append(move)
		board[best.ty][best.tx] = board[best.fy][best.fx]
		board[best.fy][best.fx] = ""
		
		if best.target != "":
			captured_white.append(best.target)
		
		turn = not turn
		
		if not game_started:
			game_started = true
		
		check_game_over()
	
	ai_making_move = false
	update_ui()
	update()

func check_game_over():
	var wk = false
	var bk = false
	for y in range(8):
		for x in range(8):
			if board[y][x] == "K":
				wk = true
			elif board[y][x] == "k":
				bk = true
	if not wk:
		game_over = true
		winner = "Black"
	elif not bk:
		game_over = true
		winner = "White"

func update_ui():
	if game_over:
		turn_label.text = "Game Over"
		status_label.text = winner + " wins!"
	else:
		turn_label.text = "Turn: " + ("White" if turn else "Black")
		if ai_enabled:
			status_label.text = "Your turn" if turn else "AI thinking..."
		else:
			status_label.text = "Click piece to move"
	
	# Timer
	var wm = int(white_time) / 60
	var ws = int(white_time) % 60
	var bm = int(black_time) / 60
	var bs = int(black_time) % 60
	timer_label.text = str(wm) + ":" + ("%02d" % ws) + " - " + str(bm) + ":" + ("%02d" % bs)
	
	# Captured
	var wt = "White taken: "
	for p in captured_white:
		wt += p + " "
	captured_black_label.text = wt if wt != "White taken: " else "White taken: none"
	
	var bt = "Black taken: "
	for p in captured_black:
		bt += p + " "
	captured_white_label.text = bt if bt != "Black taken: " else "Black taken: none"
	
	# History
	var hist = ""
	var i = 0
	while i < move_history.size():
		var wm = move_history[i] if i < move_history.size() else null
		var bm = move_history[i + 1] if i + 1 < move_history.size() else null
		var mn = str(int(i / 2) + 1) + ". "
		if wm:
			mn += get_notation(wm.from_x, wm.from_y, wm.to_x, wm.to_y, wm.piece, wm.captured)
		if bm:
			mn += " " + get_notation(bm.from_x, bm.from_y, bm.to_x, bm.to_y, bm.piece, bm.captured)
		hist += mn + "\n"
		i += 2
	history_label.text = hist

func get_notation(fx, fy, tx, ty, p, cap):
	var files = ["a", "b", "c", "d", "e", "f", "g", "h"]
	var ranks = ["8", "7", "6", "5", "4", "3", "2", "1"]
	var pn = {"K": "K", "Q": "Q", "R": "R", "B": "B", "N": "N", "P": ""}
	var pc = pn.get(p.to_upper(), "")
	if cap != "":
		return pc + files[fx] + "x" + files[tx] + ranks[ty]
	return pc + files[tx] + ranks[ty]

func _draw():
	# Background
	draw_rect(Rect2(0, 0, 1100, 800), Color(0.1, 0.1, 0.15))
	
	# Board
	for y in range(8):
		for x in range(8):
			var bx = board_offset_x + x * square_size
			var by = board_offset_y + y * square_size
			var c = Color("#f0d9b5") if (x + y) % 2 == 0 else Color("#b58863")
			draw_rect(Rect2(bx, by, square_size, square_size), c)
	
	# Selected
	if selected_piece:
		var x = selected_piece.x
		var y = selected_piece.y
		var bx = board_offset_x + x * square_size
		var by = board_offset_y + y * square_size
		draw_rect(Rect2(bx, by, square_size, square_size), Color(1, 1, 0, 0.4))
		
		# Show possible moves
		for ty in range(8):
			for tx in range(8):
				if is_valid_move(x, y, tx, ty):
					var mx = board_offset_x + tx * square_size + square_size/2
					var my = board_offset_y + ty * square_size + square_size/2
					draw_circle(Vector2(mx, my), 10, Color(0, 1, 0, 0.5))
	
	# Pieces
	for y in range(8):
		for x in range(8):
			var p = board[y][x]
			if p != "":
				draw_piece(x, y, p)

func draw_piece(x, y, p):
	var cx = board_offset_x + x * square_size + square_size/2
	var cy = board_offset_y + y * square_size + square_size/2
	var white = p >= "A" and p <= "Z"
	var pc = p.to_lower()
	
	var bc = Color(0.95, 0.95, 0.9) if white else Color(0.15, 0.15, 0.15)
	var fc = Color(0.7, 0.7, 0.65) if white else Color(0.08, 0.08, 0.08)
	var ic = Color(0.9, 0.9, 0.85) if white else Color(0.2, 0.2, 0.2)
	
	draw_circle(Vector2(cx + 2, cy + 2), 30, Color(0, 0, 0, 0.25))
	
	match pc:
		"k":
			draw_circle(Vector2(cx, cy + 5), 25, bc)
			draw_circle(Vector2(cx, cy + 5), 22, fc)
			draw_rect(Rect2(cx - 4, cy - 10, 8, 18), bc)
			draw_rect(Rect2(cx - 12, cy - 12, 24, 5), bc)
			draw_rect(Rect2(cx - 3, cy - 18, 6, 14), bc)
		"q":
			draw_circle(Vector2(cx, cy + 5), 25, bc)
			draw_circle(Vector2(cx, cy + 5), 22, fc)
			draw_rect(Rect2(cx - 4, cy - 8, 8, 16), bc)
			draw_rect(Rect2(cx - 10, cy - 16, 20, 5), bc)
			draw_circle(Vector2(cx - 8, cy - 18), 4, bc)
			draw_circle(Vector2(cx, cy - 20), 4, bc)
			draw_circle(Vector2(cx + 8, cy - 18), 4, bc)
		"r":
			draw_rect(Rect2(cx - 20, cy - 5, 40, 30), bc)
			draw_rect(Rect2(cx - 18, cy - 3, 36, 26), fc)
			draw_rect(Rect2(cx - 22, cy - 18, 10, 14), bc)
			draw_rect(Rect2(cx - 5, cy - 20, 10, 16), bc)
			draw_rect(Rect2(cx + 12, cy - 18, 10, 14), bc)
		"b":
			draw_circle(Vector2(cx, cy + 5), 22, bc)
			draw_circle(Vector2(cx, cy + 5), 19, fc)
			draw_rect(Rect2(cx - 4, cy - 8, 8, 14), bc)
			draw_circle(Vector2(cx, cy - 10), 14, bc)
			draw_rect(Rect2(cx - 2, cy - 22, 4, 6), bc)
		"n":
			draw_rect(Rect2(cx - 15, cy - 5, 30, 25), bc)
			draw_rect(Rect2(cx - 13, cy - 3, 26, 21), fc)
			draw_rect(Rect2(cx + 5, cy - 18, 14, 16), bc)
			draw_rect(Rect2(cx + 15, cy - 22, 5, 7), bc)
		"p":
			draw_circle(Vector2(cx, cy + 8), 18, bc)
			draw_circle(Vector2(cx, cy + 8), 15, fc)
			draw_rect(Rect2(cx - 3, cy - 5, 6, 14), bc)
			draw_circle(Vector2(cx, cy - 5), 10, bc)

func _input(event):
	if ai_making_move:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		var x = int((event.position.x - board_offset_x) / square_size)
		var y = int((event.position.y - board_offset_y) / square_size)
		
		if x >= 0 and x < 8 and y >= 0 and y < 8:
			handle_click(x, y)

func handle_click(x, y):
	var p = board[y][x]
	var white_p = p != "" and p >= "A" and p <= "Z"
	var black_p = p != "" and p >= "a" and p <= "z"
	
	# AI mode - only white pieces
	if ai_enabled and turn and black_p:
		return
	
	if selected_piece:
		var fx = selected_piece.x
		var fy = selected_piece.y
		
		if is_valid_move(fx, fy, x, y):
			var cap = board[y][x]
			
			var mv = {
				"from_x": fx, "from_y": fy,
				"to_x": x, "to_y": y,
				"captured": cap, "piece": board[fy][fx],
				"turn_before": turn
			}
			move_history.append(mv)
			
			board[y][x] = board[fy][fx]
			board[fy][fx] = ""
			
			if cap != "":
				if turn:
					captured_black.append(cap)
				else:
					captured_white.append(cap)
			
			turn = not turn
			selected_piece = null
			
			if not game_started:
				game_started = true
			
			check_game_over()
			update_ui()
			update()
		else:
			# Select different piece
			if turn and white_p:
				selected_piece = Vector2(x, y)
			elif not turn and black_p and not ai_enabled:
				selected_piece = Vector2(x, y)
			else:
				selected_piece = null
	else:
		if turn and white_p:
			selected_piece = Vector2(x, y)
		elif not turn and black_p and not ai_enabled:
			selected_piece = Vector2(x, y)
	
	update()

func is_valid_move(fx, fy, tx, ty):
	if fx == tx and fy == ty:
		return false
	
	var p = board[fy][fx]
	var t = board[ty][tx]
	
	if t != "":
		var tw = t >= "A" and t <= "Z"
		var pw = p >= "A" and p <= "Z"
		if tw == pw:
			return false
	
	match p.to_lower():
		"p":
			return pawn_move(fx, fy, tx, ty, p >= "A" and p <= "Z")
		"r":
			return straight_move(fx, fy, tx, ty)
		"b":
			return diag_move(fx, fy, tx, ty)
		"n":
			return knight_move(fx, fy, tx, ty)
		"q":
			return straight_move(fx, fy, tx, ty) or diag_move(fx, fy, tx, ty)
		"k":
			return abs(tx - fx) <= 1 and abs(ty - fy) <= 1
	
	return false

func pawn_move(fx, fy, tx, ty, white):
	var dir = -1 if white else 1
	var start = 6 if white else 1
	
	if fx == tx:
		if ty - fy == dir and board[ty][tx] == "":
			return true
		if fy == start and ty - fy == 2 * dir and board[fy + dir][fx] == "" and board[ty][tx] == "":
			return true
	else:
		if ty - fy == dir and abs(tx - fx) == 1 and board[ty][tx] != "":
			return true
	return false

func straight_move(fx, fy, tx, ty):
	if fx != tx and fy != ty:
		return false
	return clear_path(fx, fy, tx, ty)

func diag_move(fx, fy, tx, ty):
	if abs(tx - fx) != abs(ty - fy):
		return false
	return clear_path(fx, fy, tx, ty)

func knight_move(fx, fy, tx, ty):
	var dx = abs(tx - fx)
	var dy = abs(ty - fy)
	return (dx == 2 and dy == 1) or (dx == 1 and dy == 2)

func clear_path(fx, fy, tx, ty):
	var dx = sign(tx - fx)
	var dy = sign(ty - fy)
	var x = fx + dx
	var y = fy + dy
	
	while x != tx or y != ty:
		if board[y][x] != "":
			return false
		x += dx
		y += dy
	return true
