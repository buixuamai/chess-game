// Chess Game JavaScript
// Uses chess.js for game logic and chessboard.js for UI

// Initialize game state
let game = new Chess();
let board = null;
let moveHistory = [];
let $status = $('#status');
let $fen = $('#fen');
let $pgn = $('#pgn');

// Game configuration
const config = {
    draggable: true,
    position: 'start',
    onDragStart: onDragStart,
    onDrop: onDrop,
    onSnapEnd: onSnapEnd,
    pieceTheme: 'https://chessboardjs.com/img/chesspieces/wikipedia/{piece}.png'
};

// Initialize board on page load
$(document).ready(function() {
    board = Chessboard('board', config);
    updateStatus();
    updateMoveHistory();
    
    // Button event listeners
    $('#new-game-btn').on('click', newGame);
    $('#undo-btn').on('click', undoMove);
});

// Called when the piece drag begins
function onDragStart(source, piece, position, orientation) {
    // Do not pick up pieces if the game is over
    if (game.game_over()) return false;

    // Only pick up pieces for the side to move
    if ((game.turn() === 'w' && piece.search(/^b/) !== -1) ||
        (game.turn() === 'b' && piece.search(/^w/) !== -1)) {
        return false;
    }
}

// Called when the piece is dropped
function onDrop(source, target) {
    // See if the move is legal
    const move = game.move({
        from: source,
        to: target,
        promotion: 'q' // Always promote to queen
    });

    // Illegal move
    if (move === null) return 'snapback';

    // Store move for undo functionality
    moveHistory.push({
        move: move,
        fen: game.fen()
    });

    updateStatus();
    updateMoveHistory();
}

// Update the board position after the piece snap
// for castling, en passant, pawn promotion
function onSnapEnd() {
    board.position(game.fen());
}

// Update the game status
function updateStatus() {
    let status = '';
    let moveColor = game.turn() === 'b' ? 'Black' : 'White';

    // Check for game over
    if (game.in_checkmate()) {
        status = 'Game over, ' + moveColor + ' is in checkmate.';
        $('#status').addClass('game-over');
        $('#status').removeClass('check');
    } else if (game.in_draw()) {
        status = 'Game over, drawn position';
        $('#status').removeClass('check');
    } else {
        // Game continues
        status = moveColor + "'s Turn";
        $('#status').removeClass('game-over');

        // Check for check
        if (game.in_check()) {
            status += ', ' + moveColor + ' is in check';
            $('#status').addClass('check');
        } else {
            $('#status').removeClass('check');
        }
    }

    $('#status').text(status);
}

// Update the move history display
function updateMoveHistory() {
    const historyElement = $('#move-history');
    historyElement.empty();

    const history = game.history({ verbose: true });
    
    // Display moves in pairs (white, black)
    for (let i = 0; i < history.length; i += 2) {
        const moveNumber = Math.floor(i / 2) + 1;
        
        const whiteMove = history[i] ? history[i].san : '';
        const blackMove = history[i + 1] ? history[i + 1].san : '';
        
        const moveDiv = $('<div class="move-row"></div>');
        moveDiv.html(`
            <span class="move-number">${moveNumber}.</span>
            <span class="white-move ${i === history.length - 1 ? 'last-move' : ''}">${whiteMove}</span>
            <span class="black-move ${i + 1 === history.length - 1 ? 'last-move' : ''}">${blackMove}</span>
        `);
        
        historyElement.append(moveDiv);
    }

    // Scroll to bottom
    historyElement.scrollTop(historyElement[0].scrollHeight);
}

// Start a new game
function newGame() {
    game.reset();
    board.start();
    moveHistory = [];
    updateStatus();
    updateMoveHistory();
    $('#status').removeClass('check game-over');
}

// Undo the last move
function undoMove() {
    if (moveHistory.length === 0) return;
    
    // Undo twice to undo both white and black moves
    game.undo();
    game.undo();
    
    // Remove the moves from history
    moveHistory = moveHistory.slice(0, -2);
    
    // Update board
    board.position(game.fen());
    updateStatus();
    updateMoveHistory();
}
