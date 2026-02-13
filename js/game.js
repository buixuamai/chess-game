// Chess Game JavaScript
// Uses chess.js for game logic and chessboard.js for UI
// Uses stockfish.js for AI

// Initialize game state
let game = new Chess();
let board = null;
let moveHistory = [];
let $status = $('#status');

// Game mode: 'pvp' (player vs player) or 'ai' (player vs computer)
let gameMode = 'pvp';
let aiLevel = 3; // 1-20 (skill level)

// Stockfish AI
let stockfish = null;
let isAiThinking = false;

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
    
    // Initialize Stockfish AI
    stockfish = new Worker('https://cdnjs.cloudflare.com/ajax/libs/stockfish.js/10.0.0/stockfish.js');
    
    stockfish.onmessage = function(event) {
        // Parse AI move
        if (event.data.startsWith('bestmove')) {
            const bestMove = event.data.split(' ')[1];
            if (bestMove && bestMove !== '(none)') {
                const move = game.move({
                    from: bestMove.substring(0, 2),
                    to: bestMove.substring(2, 4),
                    promotion: 'q'
                });
                
                if (move) {
                    moveHistory.push({
                        move: move,
                        fen: game.fen()
                    });
                    
                    board.position(game.fen());
                    updateStatus();
                    updateMoveHistory();
                }
            }
            isAiThinking = false;
            updateAiIndicator();
        }
    };
    
    // Button event listeners
    $('#new-game-btn').on('click', newGame);
    $('#undo-btn').on('click', undoMove);
    $('#mode-btn').on('click', toggleMode);
    $('#ai-level').on('change', function() {
        aiLevel = parseInt($(this).val());
    });
});

// Toggle between PvP and AI mode
function toggleMode() {
    if (gameMode === 'pvp') {
        gameMode = 'ai';
        $('#mode-btn').text('Play vs Player');
        $('#mode-btn').removeClass('btn-primary').addClass('btn-ai');
        $('.ai-controls').show();
    } else {
        gameMode = 'pvp';
        $('#mode-btn').text('Play vs AI');
        $('#mode-btn').removeClass('btn-ai').addClass('btn-primary');
        $('.ai-controls').hide();
    }
    newGame();
}

// Called when the piece drag begins
function onDragStart(source, piece, position, orientation) {
    // Do not pick up pieces if the game is over
    if (game.game_over()) return false;

    // In AI mode, only allow player to move their color
    if (gameMode === 'ai') {
        const playerColor = board.orientation() === 'white' ? 'w' : 'b';
        if (playerColor === 'w' && piece.search(/^b/) !== -1) return false;
        if (playerColor === 'b' && piece.search(/^w/) !== -1) return false;
    } else {
        // PvP mode - only pick up pieces for the side to move
        if ((game.turn() === 'w' && piece.search(/^b/) !== -1) ||
            (game.turn() === 'b' && piece.search(/^w/) !== -1)) {
            return false;
        }
    }
    
    // Don't allow AI to move while thinking
    if (isAiThinking) return false;
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
    
    // If playing against AI and game not over, make AI move
    if (gameMode === 'ai' && !game.game_over()) {
        makeAiMove();
    }
}

// Make AI move using Stockfish
function makeAiMove() {
    isAiThinking = true;
    updateAiIndicator();
    
    // Set skill level
    stockfish.postMessage('setoption name Skill Level value ' + aiLevel);
    
    // Send position to Stockfish
    const fen = game.fen();
    stockfish.postMessage('position fen ' + fen);
    stockfish.postMessage('go depth 15');
}

// Update AI thinking indicator
function updateAiIndicator() {
    if (isAiThinking) {
        $('#status').text('AI is thinking...');
    }
}

// Update the board position after the piece snap
function onSnapEnd() {
    board.position(game.fen());
}

// Update the game status
function updateStatus() {
    let status = '';
    let moveColor = game.turn() === 'b' ? 'Black' : 'White';

    // Check for game over
    if (game.in_checkmate()) {
        status = 'Game over, ' + moveColor + ' is in checkmate!';
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

    if (!isAiThinking) {
        $('#status').text(status);
    }
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
    isAiThinking = false;
    updateAiIndicator();
    updateStatus();
    updateMoveHistory();
    $('#status').removeClass('check game-over');
}

// Undo the last move
function undoMove() {
    if (moveHistory.length === 0) return;
    
    // In AI mode, undo two moves (player + AI)
    if (gameMode === 'ai' && moveHistory.length >= 2) {
        game.undo();
        game.undo();
        moveHistory = moveHistory.slice(0, -2);
    } else {
        game.undo();
        moveHistory = moveHistory.slice(0, -1);
    }
    
    // Update board
    board.position(game.fen());
    updateStatus();
    updateMoveHistory();
}
