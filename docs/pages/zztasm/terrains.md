---
title: Terrains
keywords: Tick functions, Blink wall, Messenger, Monitor, Transporter
sidebar: zztasm_sidebar
permalink: terrains.html
---

## Blink wall

Blink walls fire a ray periodically.  The ray destroys destructible tiles, and hurts the
player while knocking them back.  If the player can't be moved out of the way, they are
killed immediately.

Although this is implemented as a single procedure in ZZT, I have broken it into several
smaller functions for clarity.


### Tick function

{% include asmlink.html file="terrains/blinkwall.asm" line="5" %}

```swift
func TickBlinkWall(int16 ParamIdx) {
    let Params = BoardParams[ParamIdx]
    // If the current time is 0, reset it to the starting time.
    if Params.Param3 == 0 {  // current time
        Params.Param3 = Params.Param1 + 1  // starting time
    }

    // Each tick, count current time down to 1.
    if Params.Param3 != 1 {  // current time
        Params.Param3 -= 1
        return
    }

    // Either erase a ray or fire a ray.
    if EraseRay(Params) {
        return
    }
    FireRay(Params)

    // Reset the timer to the beginning of the period (in double ticks) plus 1
    Params.Param3 = 2*Params.Param2 + 1
}


//
// Erase the ray from this blinkwall, returning if any tiles were erased.
//
func EraseRay(ParamRecord* Params) -> Bool {
    var DestX = Params.X + Params.StepX
    var DestY = Params.Y + Params.StepY
    let RayType = (Params.StepX == 0) ? TTBlinkRayV : TTBlinkRayH  // vert or horiz ray?
    let RayColor = BoardTiles[Params.X][Params.Y].Color
    while true {
        // Only erase rays in the correct direction and color
        let Tile = BoardTiles[DestX][DestY]
        if (Tile.Type == RayType) && (Tile.Color == RayColor) {
            // Erase the tile
            BoardTiles[DestX][DestY].Type = TTEmpty
            DrawTile(DestX, DestY)
            // Advance to the next
            DestX += Params.StepX
            DestY += Params.StepY
            // Set the timer to the beginning of the period (in double ticks) plus 1
            Params.Param3 = 2*Params.Param2 + 1
        }
    }
    // If we're still 1 tile past the start point, we didn't move.
    return (DestX != Params.X + Params.StepX) && (DestY != Params.Y + Params.StepY)
}


//
// Fire a ray from this blinkwall
//
func FireRay(ParamRecord* Params) {
    var DestX = Params.X + Params.StepX
    var DestY = Params.Y + Params.StepY
    var StopLoop = false
    do {
        // Destroy any destructible tiles in the way
        let Tile = BoardTiles[DestX][DestY]
        if (Tile.Type != TTEmpty) && (TileTypes[Tile.Type].Destructible != 0) {
            Destroy(DestX, DestY)
        }
        // Hurt and move the player if they intersect the ray
        if Tile.Type == TTPlayer {
            // If the player is now dead, we can stop.
            StopLoop = PushOrKillPlayer(Params, DestX, DestY)
        }
        // Try adding rays until we hit a non-empty tile.
        if Tile.Type != TTEmpty {
            StopLoop = 1
        } else {
        }
        // Advance to the next tile
        DestX += Params.StepX
        DestY += Params.StepY
    } while !StopLoop
}


//
// Push the player out of the way, hurting them.  If not possible, kill them.
// Return true if player was killed.
//
func PushOrKillPlayer(ParamRecord* Params, int16 X, int16 Y) -> Bool {
    let PlayerParamIdx = ParamIdxForXY(X, Y)  // should always be 0
    if Params.StepX == 0 {
        // Firing vertically; try moving the player horizontally
        if BoardTiles[DestX+1][DestY] == TTEmpty {
            // Move the player into the empty space to the east
            MoveTileWithIdx(PlayerParamIdx, DestX + 1, DestY)
        } else if BoardTiles[DestX-1][DestY] == TTEmpty {
            // BUG!  We checked to the west, but we're still moving the player east.
            MoveTileWithIdx(PlayerParamIdx, DestX + 1, DestY)
        }
    } else {
        // Firing horizontally; try moving the player vertically
        if BoardTiles[DestX][DestY-1] == TTEmpty {
            // Move the player into the empty space to the north
            MoveTileWithIdx(PlayerParamIdx, DestX, DestY - 1)
        } else if BoardTiles[DestX][DestY+1] == TTEmpty {
            // Move the player into the empty space to the south
            MoveTileWithIdx(PlayerParamIdx, DestX, DestY + 1)
        }
    }

    // If the player isn't there any more, we don't have to kill them
    if BoardTiles[DestX][DestY] != TTPlayer {
        return false
    }
    // Drain player's health until they're dead
    while(CurrentHealth > 0) {
        Attack(PlayerParamIdx)
    }
    return true
}
```


## Messenger

This tile is spawned outside the bounds of the board (at 0, 0) to update the message at the
bottom of the screen.  When it counts down enough time, it clears the message and dies.

### Tick function

{% include asmlink.html file="terrains/messenger.asm" line="5" %}

```swift
func TickMessenger(int16 ParamIdx) {
    let Params = BoardParams[ParamIdx]
    // Only show a message if our X coordinate is 0 (off screen).
    if Params.X != 0 {
        return
    }
    // Draw the message centered horizontally at the center of the screen.
    let X = (60 - CurrentMessage.Length) / 2
    let Y = 24
    // Cycle between the seven bright colors (9 to 15)
    let TicksLeft = Params.Param2
    let Color = 9 + (TicksLeft % 7)
    // Pad the message with a space on either side
    var PaddedMessage: string[255] = " " + CurrentMessage + " "
    PutStr(X, Y, Color, PaddedMessage)
    
    // Decrement the ticks left.  When there's no ticks left, die and clear the message.
    Params.Param2 = TicksLeft - 1
    if Params.Param2 <= 0 {
        // Remove this messenger and decrement the current param index.
        RemoveParamIdx(ParamIdx)
        CurrentPraamIdx -= 1
        // Clear the on-screen and in-memory message
        RedrawBorder()
    }
}
```


## Monitor

This tile replaces the player on the title screen and listens for relevant key presses.

### Tick function

{% include asmlink.html file="terrains/monitor.asm" line="10" %}

```swift
func TickMonitor(int16 ParamIdx) {
    // Bitmap of keycodes: ESC, 'A', 'E', 'H', 'N', 'P', 'Q', 'R', 'S', 'W', '|'
    let MonitorKeyBitmap = [0x00, 0x00, 0x00, 0x08, 0x00, 0x00, 0x00, 0x00, 0x22, 0x41,
                            0x8f, 0x00, 0x00, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00, 0x00,
                            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                            0x00, 0x00]
    let KeyCode = ToUpper(LastKeyCode)  // global variable of last keycode value
    if CheckBitmap(KeyCode, MonitorKeyBitmap) {
        ShouldHandleKeyPress = true  // global variable to handle the current keypress
    }
}
```


## Transporter

Transporters provide a shortcut across the board to another aligned transporter.

### Tick function

{% include asmlink.html file="terrains/transporter.asm" line="5" %}

```swift
func TickTransporter(int16 ParamIdx) {
    let Params = BoardParams[ParamIdx]
    // Force a redraw every tick
    DrawTile(Params.X, Params.Y)
}
```

{% include links.html %}
