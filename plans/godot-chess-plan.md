# Godot Chess Game - Technical Specification

## Overview
A chess game built with Godot Engine 4.x, exportable to HTML5/Web for deployment on GitHub Pages.

## Performance Ranking for Web Games
1. **Rust + WebAssembly** - Best raw performance
2. **C++ + WebAssembly** - Excellent performance  
3. **Godot (GDScript)** - Great for 2D/3D, compiles to WebGL
4. **Unity WebGL** - Good but requires paid license for Web export
5. **JavaScript** - Easiest, great performance for casual games

## Why Godot?
- ✅ Free and open source
- ✅ Native Web export (no plugins needed)
- ✅ Great 2D game support
- ✅ Lightweight web builds
- ✅ Can export to HTML5 directly

## Godot Project Structure
```
chess-godot/
├── project.godot
├── scenes/
│   ├── Main.tscn           # Main game scene
│   ├── ChessBoard.tscn     # Board grid
│   ├── Square.tscn         # Individual square
│   └── Piece.tscn          # Chess piece
├── scripts/
│   ├── Main.gd             # Main game controller
│   ├── ChessBoard.gd      # Board logic
│   ├── ChessPiece.gd      # Piece movement
│   └── GameRules.gd       # Chess rules
├── assets/
│   ├── pieces/             # Piece sprites
│   └── themes/            # UI themes
└── export_presets.cfg     # Export settings
```

## Features
- Full chess rules (all piece movements)
- Castling, en passant, pawn promotion
- Move validation
- Check/checkmate detection
- Turn-based gameplay
- Beautiful 2D graphics

## Installation
1. Download Godot 4.x from https://godotengine.org/
2. Install and run Godot
3. Create new project

## Export Steps
1. Project → Export
2. Add Web export
3. Configure export settings
4. Export to HTML5
5. Deploy folder to GitHub

## GitHub Deployment
1. Create repository on GitHub
2. Push exported HTML5 files
3. Enable GitHub Pages
4. Game available at: https://username.github.io/repo-name
