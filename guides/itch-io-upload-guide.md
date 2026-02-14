# How to Upload Godot Game to Itch.io

## Overview
This guide explains how to upload your Godot 4.x chess game to itch.io, a free game hosting platform that supports Godot games.

## Why Itch.io?
- Free hosting for indie games
- Native support for Godot 4.x (with SharedArrayBuffer)
- Large gaming community
- Easy to use

## Files to Upload

The game files are in: `chess-godot/export/`

Required files:
- `index.html`
- `index.js`
- `index.wasm`
- `index.pck`
- `index.png` (icon)
- `index.audio.worklet.js`
- `index.audio.position.worklet.js`

## Step-by-Step Upload Process

### Step 1: Create Itch.io Account
1. Go to https://itch.io
2. Click "Sign up" to create an account
3. Verify your email

### Step 2: Create New Project
1. Click your username → "Create new project"
2. Or go directly to: https://itch.io/game/new

### Step 3: Configure Project Type
1. **Kind of project:** Select **HTML** (not HTML5, just "HTML")
2. This tells itch.io you're uploading an HTML/JavaScript game

### Step 4: Upload Files
1. Click "Upload files" button
2. Select all the files from `chess-godot/export/` folder:
   - index.html
   - index.js
   - index.wasm
   - index.pck
   - index.png
   - index.audio.worklet.js
   - index.audio.position.worklet.js
3. Wait for upload to complete

### Step 5: Configure Project Settings

**Important Settings:**

| Setting | Enable? | Notes |
|---------|----------|-------|
| Mobile friendly | ✅ Yes | Works on phones |
| Orientation | Default | Use default |
| Automatically start on page load | ❌ No | Can cause lag |
| Fullscreen button | ✅ Yes | Nice to have |
| Enable scrollbars | ❌ No | Not needed |
| **SharedArrayBuffer support** | ✅ **YES** | **CRITICAL for Godot 4.x!** |

### Step 6: Save and Publish
1. Scroll down and click "Save as draft"
2. When ready, click "Edit" → "View page"
3. Click "Publish" to make it public

## Troubleshooting

### Game Not Loading?
- Make sure you selected "HTML" as project type
- Check that SharedArrayBuffer support is enabled
- Verify all required files are uploaded

### Black Screen?
- This usually means SharedArrayBuffer is not enabled
- Go to project settings and enable it

### Performance Issues?
- Disable "Automatically start on page load"
- This can cause lag on slower devices

## Alternative: Use Butler CLI

If you prefer command-line upload:

1. Download Butler: https://itch.io/docs/butler
2. Login: `butler login`
3. Push: `butler push chess-godot/export/ yourusername/chess-game:html5`

## Your Published Game URL

After publishing, your game will be at:
`https://yourusername.itch.io/chess-game`

## Summary

✅ JavaScript Chess Game: https://buixuamai.github.io/chess-game/
✅ Godot Chess Game: Upload to itch.io using this guide!

Good luck!
