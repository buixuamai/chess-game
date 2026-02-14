extends Node2D

# Enhanced Chess Game for Godot 3.x - Real Chess Piece Shapes

var board = []
var turn = true
var selected_piece = null
var square_size = 80
var board_offset_x = 20
var board_offset_y = 80

var game_over = false
var winner = ""
var move_history = []

var ai_enabled = false

var new_game_btn
var undo_btn
var ai_btn
var history_label

func _ready():
	create_ui()
	init_board()

func create_ui():
	var title = Label.new()
	title.rect_position = Vector2(20, 10)
	title.text = "Chess Game"
	add_child(title)
	
	new_game_btn = Button.new()
	new_game_btn.text = "New Game"
	new_game_btn.rect_position = Vector2(680, 20)
	new_game_btn.rect_size = Vector2(100, 35)
	new_game_btn.connect("pressed", self, "on_new_game_pressed")
	add_child(new_game_btn)
	
	undo_btn = Button.new()
	undo_btn.text = "Undo"
	undo_btn.rect_position = Vector2(790, 20)
	undo_btn.rect_size = Vector2(100, 35)
	undo_btn.connect("pressed", self, "on_undo_pressed")
	add_child(undo_btn)
	
	ai_btn = Button.new()
	ai_btn.text = "AI: OFF"
	ai_btn.rect_position = Vector2(900, 20)
	ai_btn.rect_size = Vector2(100, 35)
	ai_btn.connect("pressed", self, "on_ai_toggled")
	add_child(ai_btn)
	
	var turn_label = Label.new()
	turn_label.name = "TurnLabel"
	turn_label.rect_position = Vector2(680, 65)
	turn_label.text = "Turn: White"
	add_child(turn_label)
	
	var status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.rect_position = Vector2(680, 95)
	status_label.text = "Click a piece to select"
	add_child(status_label)
	
	var history_title = Label.new()
	history_title.rect_position = Vector2(680, 140)
	history_title.text = "Move History:"
	add_child(history_title)
	
	history_label = Label.new()
	history_label.name = "HistoryLabel"
	history_label.rect_position = Vector2(680, 170)
	add_child(history_label)
	
	var instructions = Label.new()
	instructions.rect_position = Vector2(20, 680)
	instructions.text = "White: You | Black: AI | Click piece to select, click destination to move"
	add_child(instructions)

func on_ai_toggled():
	ai_enabled = not ai_enabled
	ai_btn.text = "AI: ON" if ai_enabled else "AI: OFF"
	get_node("StatusLabel").text = "AI mode " + ("enabled" if ai_enabled else "disabled")

func on_new_game_pressed():
	init_board()

func on_undo_pressed():
	if move_history.size() > 0:
		undo_last_move()
		update_ui()

func undo_last_move():
	if move_history.size() > 0:
		var last_move = move_history.pop_back()
		board[last_move.to_y][last_move.to_x] = last_move.captured
		board[last_move.from_y][last_move.from_x] = last_move.piece
		turn = last_move.turn_before
		game_over = false
		winner = ""

func get_piece_name(p):
	match p.to_lower():
		"K": return "King"
		"Q": return "Queen"
		"R": return "Rook"
		"B": return "Bishop"
		"N": return "Knight"
		"P": return "Pawn"
	return ""

func get_move_notation(from_x, from_y, to_x, to_y, piece, captured):
	var files = ["a", "b", "c", "d", "e", "f", "g", "h"]
	var ranks = ["8", "7", "6", "5", "4", "3", "2", "1"]
	
	var piece_name = get_piece_name(piece)
	if piece_name == "Pawn" and captured != "":
		return files[from_x] + "x" + files[to_x] + ranks[to_y]
	elif captured != "":
		return piece_name[0] + "x" + files[to_x] + ranks[to_y]
	else:
		return piece_name[0] + files[to_x] + ranks[to_y]

func update_ui():
	var turn_label = get_node("TurnLabel")
	var status_label = get_node("StatusLabel")
	
	if game_over:
		turn_label.text = "Game Over!"
		status_label.text = winner + " wins!"
	else:
		turn_label.text = "Turn: " + ("White (You)" if turn else "Black (AI)")
		status_label.text = "Your turn" if turn else "AI turn"
	
	var history_text = ""
	var move_num = 1
	var i = 0
	while i < move_history.size():
		var white_move = move_history[i] if i < move_history.size() else null
		var black_move = move_history[i + 1] if i + 1 < move_history.size() else null
		
		var line = str(move_num) + ". "
		if white_move != null:
			line += get_move_notation(white_move.from_x, white_move.from_y, white_move.to_x, white_move.to_y, white_move.piece, white_move.captured)
		if black_move != null:
			line += "  " + get_move_notation(black_move.from_x, black_move.from_y, black_move.to_x, black_move.to_y, black_move.piece, black_move.captured)
		
		history_text += line + "\n"
		move_num += 1
		i += 2
	
	history_label.text = history_text

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
	update_ui()

func _process(delta):
	if ai_enabled and not turn and not game_over:
		if selected_piece == null:
			yield(get_tree().create_timer(0.5), "timeout")
			make_ai_move()
	update()

func make_ai_move():
	var possible_moves = []
	
	for y in range(8):
		for x in range(8):
			var piece = board[y][x]
			if piece != "" and piece >= "a" and piece <= "z":
				for ty in range(8):
					for tx in range(8):
						if is_valid_move(x, y, tx, ty):
							possible_moves.append({
								"from_x": x, "from_y": y,
								"to_x": tx, "to_y": ty,
								"piece": piece, "target": board[ty][tx]
							})
	
	if possible_moves.size() > 0:
		var capture_moves = []
		var safe_moves = []
		
		for move in possible_moves:
			if move.target != "":
				capture_moves.append(move)
			else:
				safe_moves.append(move)
		
		var selected_move
		if capture_moves.size() > 0 and randf() < 0.7:
			selected_move = capture_moves[randi() % capture_moves.size()]
		elif safe_moves.size() > 0:
			selected_move = safe_moves[randi() % safe_moves.size()]
		else:
			selected_move = possible_moves[randi() % possible_moves.size()]
		
		var move = {
			"from_x": selected_move.from_x, "from_y": selected_move.from_y,
			"to_x": selected_move.to_x, "to_y": selected_move.to_y,
			"captured": selected_move.target, "piece": selected_move.piece,
			"turn_before": turn
		}
		move_history.append(move)
		
		board[selected_move.to_y][selected_move.to_x] = board[selected_move.from_y][selected_move.from_x]
		board[selected_move.from_y][selected_move.from_x] = ""
		turn = not turn
		
		check_game_over()
		update_ui()

func _draw():
	# Background
	draw_rect(Rect2(0, 0, 1100, 800), Color(0.1, 0.1, 0.15))
	
	# Board
	for y in range(8):
		for x in range(8):
			var bx = board_offset_x + x * square_size
			var by = board_offset_y + y * square_size
			var color = Color("#f0d9b5") if (x + y) % 2 == 0 else Color("#b58863")
			draw_rect(Rect2(bx, by, square_size, square_size), color)
	
	# Selected piece highlight
	if selected_piece != null:
		var x = selected_piece.x
		var y = selected_piece.y
		var bx = board_offset_x + x * square_size
		var by = board_offset_y + y * square_size
		draw_rect(Rect2(bx, by, square_size, square_size), Color(1, 1, 0, 0.4))
		draw_possible_moves(x, y)
	
	# Draw all pieces
	for y in range(8):
		for x in range(8):
			var piece = board[y][x]
			if piece != "":
				draw_chess_piece(x, y, piece)

func draw_chess_piece(x, y, piece):
	var cx = board_offset_x + x * square_size + square_size / 2
	var cy = board_offset_y + y * square_size + square_size / 2
	var is_white = piece >= "A" and piece <= "Z"
	var p = piece.to_lower()
	
	# Colors
	var base_color = Color(0.95, 0.95, 0.9) if is_white else Color(0.15, 0.15, 0.15)
	var border_color = Color(0.7, 0.7, 0.65) if is_white else Color(0.08, 0.08, 0.08)
	var fill_color = Color(0.9, 0.9, 0.85) if is_white else Color(0.2, 0.2, 0.2)
	
	# Shadow
	draw_circle(Vector2(cx + 2, cy + 2), 30, Color(0, 0, 0, 0.25))
	
	match p:
		"k":  # King - tall with cross on top
			# Base
			draw_circle(Vector2(cx, cy + 5), 25, base_color)
			draw_circle(Vector2(cx, cy + 5), 22, border_color)
			draw_circle(Vector2(cx, cy + 5), 18, fill_color)
			# Stem
			draw_rect(Rect2(cx - 4, cy - 10, 8, 18), base_color)
			# Cross horizontal
			draw_rect(Rect2(cx - 12, cy - 12, 24, 5), base_color)
			# Cross vertical
			draw_rect(Rect2(cx - 3, cy - 18, 6, 14), base_color)
			
		"q":  # Queen - tall with crown
			# Base
			draw_circle(Vector2(cx, cy + 5), 25, base_color)
			draw_circle(Vector2(cx, cy + 5), 22, border_color)
			draw_circle(Vector2(cx, cy + 5), 18, fill_color)
			# Stem
			draw_rect(Rect2(cx - 4, cy - 8, 8, 16), base_color)
			# Crown
			draw_rect(Rect2(cx - 10, cy - 16, 20, 5), base_color)
			# Crown points
			draw_circle(Vector2(cx - 8, cy - 18), 4, base_color)
			draw_circle(Vector2(cx, cy - 20), 4, base_color)
			draw_circle(Vector2(cx + 8, cy - 18), 4, base_color)
			
		"r":  # Rook - castle shape
			# Base
			draw_rect(Rect2(cx - 20, cy - 5, 40, 30), base_color)
			draw_rect(Rect2(cx - 18, cy - 3, 36, 26), border_color)
			draw_rect(Rect2(cx - 16, cy - 1, 32, 22), fill_color)
			# Battlements
			draw_rect(Rect2(cx - 22, cy - 18, 10, 14), base_color)
			draw_rect(Rect2(cx - 5, cy - 20, 10, 16), base_color)
			draw_rect(Rect2(cx + 12, cy - 18, 10, 14), base_color)
			# Battlements holes
			draw_rect(Rect2(cx - 12, cy - 10, 4, 6), border_color)
			draw_rect(Rect2(cx + 8, cy - 10, 4, 6), border_color)
			
		"b":  # Bishop - tall with hat
			# Base
			draw_circle(Vector2(cx, cy + 5), 22, base_color)
			draw_circle(Vector2(cx, cy + 5), 19, border_color)
			draw_circle(Vector2(cx, cy + 5), 15, fill_color)
			# Stem
			draw_rect(Rect2(cx - 4, cy - 8, 8, 14), base_color)
			# Hat
			draw_circle(Vector2(cx, cy - 10), 14, base_color)
			draw_rect(Rect2(cx - 2, cy - 22, 4, 6), base_color)
			# Hole in hat
			draw_circle(Vector2(cx, cy - 10), 5, border_color)
			
		"n":  # Knight - horse head shape
			# Base
			draw_rect(Rect2(cx - 15, cy - 5, 30, 25), base_color)
			draw_rect(Rect2(cx - 13, cy - 3, 26, 21), border_color)
			draw_rect(Rect2(cx - 11, cy - 1, 22, 17), fill_color)
			# Head
			draw_rect(Rect2(cx + 5, cy - 18, 14, 16), base_color)
			draw_rect(Rect2(cx + 7, cy - 16, 10, 12), border_color)
			# Ear
			draw_rect(Rect2(cx + 15, cy - 22, 5, 7), base_color)
			# Eye
			draw_circle(Vector2(cx + 12, cy - 10), 3, border_color)
			
		"p":  # Pawn - simple circle on stem
			# Base
			draw_circle(Vector2(cx, cy + 8), 18, base_color)
			draw_circle(Vector2(cx, cy + 8), 15, border_color)
			draw_circle(Vector2(cx, cy + 8), 12, fill_color)
			# Stem
			draw_rect(Rect2(cx - 3, cy - 5, 6, 14), base_color)
			# Head
			draw_circle(Vector2(cx, cy - 5), 10, base_color)
			draw_circle(Vector2(cx, cy - 5), 7, border_color)

func draw_possible_moves(x, y):
	for ty in range(8):
		for tx in range(8):
			if is_valid_move(x, y, tx, ty):
				var bx = board_offset_x + tx * square_size + square_size/2
				var by = board_offset_y + ty * square_size + square_size/2
				draw_circle(Vector2(bx, by), 10, Color(0, 1, 0, 0.5))

func _input(event):
	if ai_enabled and not turn:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		var x = int((event.position.x - board_offset_x) / square_size)
		var y = int((event.position.y - board_offset_y) / square_size)
		
		if x >= 0 and x < 8 and y >= 0 and y < 8:
			handle_click(x, y)

func handle_click(x, y):
	var piece = board[y][x]
	var is_white_piece = piece != "" and piece >= "A" and piece <= "Z"
	var is_black_piece = piece != "" and piece >= "a" and piece <= "z"
	
	if ai_enabled and is_black_piece:
		return
	
	if selected_piece == null:
		if turn and is_white_piece:
			selected_piece = Vector2(x, y)
			get_node("StatusLabel").text = "Piece selected - click destination"
		elif not turn and is_black_piece and not ai_enabled:
			selected_piece = Vector2(x, y)
			get_node("StatusLabel").text = "Piece selected - click destination"
	else:
		var from_x = selected_piece.x
		var from_y = selected_piece.y
		
		if is_valid_move(from_x, from_y, x, y):
			var move = {
				"from_x": from_x, "from_y": from_y,
				"to_x": x, "to_y": y,
				"captured": board[y][x],
				"piece": board[from_y][from_x],
				"turn_before": turn
			}
			move_history.append(move)
			
			board[y][x] = board[from_y][from_x]
			board[from_y][from_x] = ""
			turn = not turn
			selected_piece = null
			
			check_game_over()
			update_ui()
		else:
			if turn and is_white_piece:
				selected_piece = Vector2(x, y)
			elif not turn and is_black_piece and not ai_enabled:
				selected_piece = Vector2(x, y)
			else:
				selected_piece = null
				get_node("StatusLabel").text = "Click a piece to select"

func check_game_over():
	var white_king = false
	var black_king = false
	
	for y in range(8):
		for x in range(8):
			if board[y][x] == "K":
				white_king = true
			elif board[y][x] == "k":
				black_king = true
	
	if not white_king:
		game_over = true
		winner = "Black"
	elif not black_king:
		game_over = true
		winner = "White"

func is_valid_move(from_x, from_y, to_x, to_y):
	if from_x == to_x and from_y == to_y:
		return false
		
	var piece = board[from_y][from_x]
	var target = board[to_y][to_x]
	
	if target != "":
		var target_is_white = target >= "A" and target <= "Z"
		var piece_is_white = piece >= "A" and piece <= "Z"
		if target_is_white == piece_is_white:
			return false
	
	match piece.to_lower():
		"p":
			return is_valid_pawn_move(from_x, from_y, to_x, to_y, piece >= "A" and piece <= "Z")
		"r":
			return is_straight_move(from_x, from_y, to_x, to_y)
		"b":
			return is_diagonal_move(from_x, from_y, to_x, to_y)
		"n":
			return is_knight_move(from_x, from_y, to_x, to_y)
		"q":
			return is_straight_move(from_x, from_y, to_x, to_y) or is_diagonal_move(from_x, from_y, to_x, to_y)
		"k":
			return abs(to_x - from_x) <= 1 and abs(to_y - from_y) <= 1
	
	return false

func is_straight_move(from_x, from_y, to_x, to_y):
	if from_x != to_x and from_y != to_y:
		return false
	return is_path_clear(from_x, from_y, to_x, to_y)

func is_diagonal_move(from_x, from_y, to_x, to_y):
	if abs(to_x - from_x) != abs(to_y - from_y):
		return false
	return is_path_clear(from_x, from_y, to_x, to_y)

func is_knight_move(from_x, from_y, to_x, to_y):
	var dx = abs(to_x - from_x)
	var dy = abs(to_y - from_y)
	return (dx == 2 and dy == 1) or (dx == 1 and dy == 2)

func is_valid_pawn_move(from_x, from_y, to_x, to_y, is_white):
	var direction = -1 if is_white else 1
	var start_row = 6 if is_white else 1
	
	if from_x == to_x:
		if to_y - from_y == direction:
			return board[to_y][to_x] == ""
		if from_y == start_row and to_y - from_y == 2 * direction:
			return board[from_y + direction][from_x] == "" and board[to_y][to_x] == ""
	else:
		if to_y - from_y == direction and abs(to_x - from_x) == 1:
			return board[to_y][to_x] != ""
	return false

func is_path_clear(from_x, from_y, to_x, to_y):
	var dx = sign(to_x - from_x)
	var dy = sign(to_y - from_y)
	var x = from_x + dx
	var y = from_y + dy
	
	while x != to_x or y != to_y:
		if board[y][x] != "":
			return false
		x += dx
		y += dy
	return true
