extends Node2D

# Chess game logic for Godot
# Piece types: King, Queen, Rook, Bishop, Knight, Pawn
# Colors: White (true), Black (false)

var board = []
var turn = true  # true = white, false = black
var selected_piece = null
var game_over = false

const PIECE_SYMBOLS = {
	"K": "♔", "Q": "♕", "R": "♖", "B": "♗", "N": "♘", "P": "♙",
	"k": "♚", "q": "♛", "r": "♜", "b": "♝", "n": "♞", "p": "♟"
}

func _ready():
	init_board()

func init_board():
	# Standard chess starting position
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
	game_over = false
	queue_redraw()

func _draw():
	# Draw the chess board
	var square_size = 80
	for y in range(8):
		for x in range(8):
			var color = Color("#f0d9b5") if (x + y) % 2 == 0 else Color("#b58863")
			draw_rect(Rect2(x * square_size, y * square_size, square_size, square_size), color)
			
			# Draw pieces
			var piece = board[y][x]
			if piece != "":
				var symbol = PIECE_SYMBOLS.get(piece, "?")
				var piece_color = Color.WHITE if piece.is_upper() else Color.BLACK
				var font = ThemeDB.fallback_font
				draw_string(font, Vector2(x * square_size + 25, y * square_size + 55), symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, 48, piece_color)
	
	# Highlight selected piece
	if selected_piece != null:
		var x = selected_piece.x
		var y = selected_piece.y
		draw_rect(Rect2(x * square_size, y * square_size, square_size, square_size), Color(1, 1, 0, 0.5))

func _input(event):
	if game_over:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			init_board()
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var x = int(event.position.x / 80)
		var y = int(event.position.y / 80)
		
		if x >= 0 and x < 8 and y >= 0 and y < 8:
			handle_click(x, y)

func handle_click(x, y):
	var piece = board[y][x]
	var is_white_piece = piece != "" and piece.is_upper()
	var is_black_piece = piece != "" and piece.is_lower()
	
	if selected_piece == null:
		# Selecting a piece
		if turn and is_white_piece:
			selected_piece = Vector2(x, y)
			queue_redraw()
		elif not turn and is_black_piece:
			selected_piece = Vector2(x, y)
			queue_redraw()
	else:
		# Moving selected piece
		var from_x = selected_piece.x
		var from_y = selected_piece.y
		
		if is_valid_move(from_x, from_y, x, y):
			board[y][x] = board[from_y][from_x]
			board[from_y][from_x] = ""
			turn = not turn
			selected_piece = null
			queue_redraw()
		else:
			# Select new piece if valid
			if turn and is_white_piece:
				selected_piece = Vector2(x, y)
				queue_redraw()
			elif not turn and is_black_piece:
				selected_piece = Vector2(x, y)
				queue_redraw()
			else:
				selected_piece = null
				queue_redraw()

func is_valid_move(from_x, from_y, to_x, to_y):
	var piece = board[from_y][from_x]
	var target = board[to_y][to_x]
	
	if target != "":
		var target_is_white = target.is_upper()
		var piece_is_white = piece.is_upper()
		if target_is_white == piece_is_white:
			return false
	
	# Simplified movement rules
	match piece.to_lower():
		"p":
			return is_valid_pawn_move(from_x, from_y, to_x, to_y, piece.is_upper())
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

func is_pawn_move(from_x, from_y, to_x, to_y, is_white):
	var direction = -1 if is_white else 1
	var start_row = 6 if is_white else 1
	
	if from_x == to_x:
		# Forward move
		if to_y - from_y == direction:
			return board[to_y][to_x] == ""
		# Double move from start
		if from_y == start_row and to_y - from_y == 2 * direction:
			return board[from_y + direction][from_x] == "" and board[to_y][to_x] == ""
	else:
		# Capture move
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
