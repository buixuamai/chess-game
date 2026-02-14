extends Node2D

# Enhanced Chess Game for Godot 3.x

var board = []
var turn = true  # true = white, false = black
var selected_piece = null
var square_size = 80
var board_offset_x = 20
var board_offset_y = 80

# Game state
var game_over = false
var winner = ""
var move_history = []

# UI elements
var new_game_btn
var undo_btn

func _ready():
	# Create UI
	create_ui()
	init_board()

func create_ui():
	# Create buttons
	new_game_btn = Button.new()
	new_game_btn.text = "New Game"
	new_game_btn.rect_position = Vector2(680, 20)
	new_game_btn.rect_size = Vector2(120, 40)
	new_game_btn.connect("pressed", self, "on_new_game_pressed")
	add_child(new_game_btn)
	
	undo_btn = Button.new()
	undo_btn.text = "Undo"
	undo_btn.rect_position = Vector2(810, 20)
	undo_btn.rect_size = Vector2(120, 40)
	undo_btn.connect("pressed", self, "on_undo_pressed")
	add_child(undo_btn)
	
	# Create turn indicator label
	var turn_label = Label.new()
	turn_label.name = "TurnLabel"
	turn_label.rect_position = Vector2(680, 80)
	turn_label.text = "Turn: White"
	add_child(turn_label)
	
	# Create status label
	var status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.rect_position = Vector2(680, 120)
	status_label.text = "Click a piece to select"
	add_child(status_label)
	
	# Create instructions
	var instructions = Label.new()
	instructions.rect_position = Vector2(680, 160)
	instructions.text = "White pieces: Click to move\nBlack pieces: Click to move\nClick same piece to deselect"
	add_child(instructions)

func _process(delta):
	update()

func on_new_game_pressed():
	init_board()

func on_undo_pressed():
	if move_history.size() > 0:
		var last_move = move_history.pop_back()
		board[last_move.from_y][last_move.from_x] = board[last_move.to_y][last_move.to_x]
		board[last_move.to_y][last_move.to_x] = last_move.captured
		turn = not turn
		game_over = false
		winner = ""
		update_ui()

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

func update_ui():
	var turn_label = get_node("TurnLabel")
	var status_label = get_node("StatusLabel")
	
	if game_over:
		turn_label.text = "Game Over!"
		status_label.text = winner + " wins!"
	else:
		turn_label.text = "Turn: " + ("White" if turn else "Black")
		status_label.text = "Click a piece to select"

func _draw():
	# Draw background
	draw_rect(Rect2(0, 0, 1000, 700), Color(0.1, 0.1, 0.15))
	
	# Draw board
	for y in range(8):
		for x in range(8):
			var bx = board_offset_x + x * square_size
			var by = board_offset_y + y * square_size
			var color = Color("#f0d9b5") if (x + y) % 2 == 0 else Color("#b58863")
			draw_rect(Rect2(bx, by, square_size, square_size), color)
	
	# Draw selected piece highlight
	if selected_piece != null:
		var x = selected_piece.x
		var y = selected_piece.y
		var bx = board_offset_x + x * square_size
		var by = board_offset_y + y * square_size
		var highlight = Color(1, 1, 0, 0.4)
		draw_rect(Rect2(bx, by, square_size, square_size), highlight)
		# Draw possible moves
		draw_possible_moves(x, y)
	
	# Draw pieces
	for y in range(8):
		for x in range(8):
			var piece = board[y][x]
			if piece != "":
				draw_piece(x, y, piece)

func draw_possible_moves(x, y):
	for ty in range(8):
		for tx in range(8):
			if is_valid_move(x, y, tx, ty):
				var bx = board_offset_x + tx * square_size + square_size/2
				var by = board_offset_y + ty * square_size + square_size/2
				draw_circle(Vector2(bx, by), 10, Color(0, 1, 0, 0.5))

func draw_piece(x, y, piece):
	var cx = board_offset_x + x * square_size + square_size / 2
	var cy = board_offset_y + y * square_size + square_size / 2
	var is_white = piece >= "A" and piece <= "Z"
	
	# Draw piece shadow
	draw_circle(Vector2(cx + 2, cy + 2), 32, Color(0, 0, 0, 0.3))
	
	# Draw piece background
	var bg_color = Color.white if is_white else Color.black
	draw_circle(Vector2(cx, cy), 30, bg_color)
	
	# Draw piece inner circle
	var inner_color = Color(0.9, 0.9, 0.9) if is_white else Color(0.2, 0.2, 0.2)
	draw_circle(Vector2(cx, cy), 26, inner_color)
	
	# Draw piece symbol
	draw_piece_symbol(cx, cy, piece)

func draw_piece_symbol(cx, cy, piece):
	var p = piece.to_lower()
	var color = Color.black if piece >= "A" and piece <= "Z" else Color.white
	var line_color = Color.white if piece >= "A" and piece <= "Z" else Color.black
	var bg_color = Color(0.9, 0.9, 0.9) if piece >= "A" and piece <= "Z" else Color(0.3, 0.3, 0.3)
	
	match p:
		"k":  # King
			draw_circle(Vector2(cx, cy), 18, color)
			draw_line(Vector2(cx - 10, cy - 10), Vector2(cx + 10, cy + 10), line_color, 3)
			draw_line(Vector2(cx + 10, cy - 10), Vector2(cx - 10, cy + 10), line_color, 3)
		"q":  # Queen
			draw_circle(Vector2(cx, cy), 18, color)
			for i in range(-12, 13, 6):
				draw_circle(Vector2(cx + i, cy - 10), 4, color)
		"r":  # Rook
			draw_rect(Rect2(cx - 15, cy - 15, 30, 30), color)
			draw_rect(Rect2(cx - 12, cy - 12, 24, 24), bg_color)
		"b":  # Bishop
			draw_circle(Vector2(cx, cy), 18, color)
			draw_circle(Vector2(cx, cy), 8, line_color)
		"n":  # Knight
			var points = [Vector2(cx, cy - 18), Vector2(cx + 15, cy + 12), Vector2(cx - 15, cy + 12)]
			draw_colored_polygon(points, color)
			# Draw eye
			draw_circle(Vector2(cx + 3, cy - 3), 4, line_color)
		"p":  # Pawn
			draw_circle(Vector2(cx, cy), 14, color)
			draw_circle(Vector2(cx, cy - 2), 8, line_color)

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		var x = int((event.position.x - board_offset_x) / square_size)
		var y = int((event.position.y - board_offset_y) / square_size)
		
		if x >= 0 and x < 8 and y >= 0 and y < 8:
			handle_click(x, y)

func handle_click(x, y):
	var piece = board[y][x]
	var is_white_piece = piece != "" and piece >= "A" and piece <= "Z"
	var is_black_piece = piece != "" and piece >= "a" and piece <= "z"
	
	if selected_piece == null:
		if turn and is_white_piece:
			selected_piece = Vector2(x, y)
			get_node("StatusLabel").text = "Piece selected - click destination"
		elif not turn and is_black_piece:
			selected_piece = Vector2(x, y)
			get_node("StatusLabel").text = "Piece selected - click destination"
	else:
		var from_x = selected_piece.x
		var from_y = selected_piece.y
		
		if is_valid_move(from_x, from_y, x, y):
			# Save move to history
			var move = {
				"from_x": from_x,
				"from_y": from_y,
				"to_x": x,
				"to_y": y,
				"captured": board[y][x]
			}
			move_history.append(move)
			
			# Make the move
			board[y][x] = board[from_y][from_x]
			board[from_y][from_x] = ""
			turn = not turn
			selected_piece = null
			
			# Check for game over
			check_game_over()
			update_ui()
		else:
			# Select new piece or deselect
			if turn and is_white_piece:
				selected_piece = Vector2(x, y)
				get_node("StatusLabel").text = "Piece selected - click destination"
			elif not turn and is_black_piece:
				selected_piece = Vector2(x, y)
				get_node("StatusLabel").text = "Piece selected - click destination"
			else:
				selected_piece = null
				get_node("StatusLabel").text = "Click a piece to select"

func check_game_over():
	# Simple check - if no pieces of one color, game over
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
