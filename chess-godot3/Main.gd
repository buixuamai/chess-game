extends Node2D

# Chess game logic for Godot 3.x

var board = []
var turn = true  # true = white, false = black
var selected_piece = null
var square_size = 80

func _ready():
	init_board()

func _process(delta):
	update()

func is_upper(p):
	return p >= "A" and p <= "Z"

func is_lower(p):
	return p >= "a" and p <= "z"

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

func _draw():
	# Draw chess board
	for y in range(8):
		for x in range(8):
			var color = Color("#f0d9b5") if (x + y) % 2 == 0 else Color("#b58863")
			draw_rect(Rect2(x * square_size, y * square_size, square_size, square_size), color)
	
	# Draw selected piece highlight
	if selected_piece != null:
		var x = selected_piece.x
		var y = selected_piece.y
		var highlight = Color(1, 1, 0, 0.5)
		draw_rect(Rect2(x * square_size, y * square_size, square_size, square_size), highlight)
	
	# Draw pieces using simple shapes
	for y in range(8):
		for x in range(8):
			var piece = board[y][x]
			if piece != "":
				draw_piece(x, y, piece)

func draw_piece(x, y, piece):
	var cx = x * square_size + square_size / 2
	var cy = y * square_size + square_size / 2
	var is_white = is_upper(piece)
	var color = Color.white if is_white else Color.black
	
	# Draw piece based on type
	match piece:
		"k", "K":  # King - circle with cross
			draw_circle(Vector2(cx, cy), 30, color)
			draw_circle(Vector2(cx, cy), 28, Color.black if is_white else Color.gray)
			draw_line(Vector2(cx - 10, cy - 10), Vector2(cx + 10, cy + 10), color, 3)
			draw_line(Vector2(cx + 10, cy - 10), Vector2(cx - 10, cy + 10), color, 3)
		"q", "Q":  # Queen - circle with crown
			draw_circle(Vector2(cx, cy), 30, color)
			draw_circle(Vector2(cx, cy), 28, Color.black if is_white else Color.gray)
			for i in range(-20, 21, 10):
				draw_circle(Vector2(cx + i, cy - 15), 5, color)
		"r", "R":  # Rook - square
			draw_rect(Rect2(cx - 25, cy - 25, 50, 50), color)
			draw_rect(Rect2(cx - 23, cy - 23, 46, 46), Color.black if is_white else Color.gray)
		"b", "B":  # Bishop - circle with line
			draw_circle(Vector2(cx, cy), 28, color)
			draw_circle(Vector2(cx, cy), 26, Color.black if is_white else Color.gray)
			draw_line(Vector2(cx, cy - 20), Vector2(cx, cy + 20), color, 3)
		"n", "N":  # Knight - triangle
			var points = [Vector2(cx, cy - 28), Vector2(cx + 25, cy + 20), Vector2(cx - 25, cy + 20)]
			draw_colored_polygon(points, color)
			draw_line(Vector2(cx, cy - 28), Vector2(cx, cy + 20), Color.black if is_white else Color.gray, 2)
		"p", "P":  # Pawn - small circle
			draw_circle(Vector2(cx, cy), 20, color)
			draw_circle(Vector2(cx, cy), 18, Color.black if is_white else Color.gray)

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		var x = int(event.position.x / square_size)
		var y = int(event.position.y / square_size)
		
		if x >= 0 and x < 8 and y >= 0 and y < 8:
			handle_click(x, y)

func handle_click(x, y):
	var piece = board[y][x]
	var is_white_piece = piece != "" and is_upper(piece)
	var is_black_piece = piece != "" and is_lower(piece)
	
	if selected_piece == null:
		if turn and is_white_piece:
			selected_piece = Vector2(x, y)
		elif not turn and is_black_piece:
			selected_piece = Vector2(x, y)
	else:
		var from_x = selected_piece.x
		var from_y = selected_piece.y
		
		if is_valid_move(from_x, from_y, x, y):
			board[y][x] = board[from_y][from_x]
			board[from_y][from_x] = ""
			turn = not turn
			selected_piece = null
		else:
			if turn and is_white_piece:
				selected_piece = Vector2(x, y)
			elif not turn and is_black_piece:
				selected_piece = Vector2(x, y)
			else:
				selected_piece = null

func is_valid_move(from_x, from_y, to_x, to_y):
	var piece = board[from_y][from_x]
	var target = board[to_y][to_x]
	
	if target != "":
		var target_is_white = is_upper(target)
		var piece_is_white = is_upper(piece)
		if target_is_white == piece_is_white:
			return false
	
	match piece:
		"P":
			return is_valid_pawn_move(from_x, from_y, to_x, to_y, true)
		"p":
			return is_valid_pawn_move(from_x, from_y, to_x, to_y, false)
		"R", "r":
			return is_straight_move(from_x, from_y, to_x, to_y)
		"B", "b":
			return is_diagonal_move(from_x, from_y, to_x, to_y)
		"N", "n":
			return is_knight_move(from_x, from_y, to_x, to_y)
		"Q", "q":
			return is_straight_move(from_x, from_y, to_x, to_y) or is_diagonal_move(from_x, from_y, to_x, to_y)
		"K", "k":
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
