---
title: Items
keywords: Tick functions, Clockwise, Conveyor, Counterclockwise, Duplicator, Player, Scroll
sidebar: zztasm_sidebar
permalink: items.html
---

## Conveyor (clockwise)

Clockwise conveyors rotate pushable tiles around themselves.  The main work of this tile is
done by `Convey` in [support functions][support_functions].

### Tick function

{% include asmlink.html file="items/conveyor.asm" line="5" %}

```swift
func TickConveyorCW(int16 ParamIdx) {
    let Params = BoardParams[ParamIdx]
    // Force a redraw every tick
    DrawTile(Params.X, Params.Y)
    Convey(Params.X, Params.Y, 1)
}
```


## Conveyor (counterclockwise)

Counterclockwise conveyors rotate pushable tiles around themselves.  The main work of this
tile is done by `Convey` in [support functions][support_functions].

### Tick function

{% include asmlink.html file="items/conveyor.asm" line="54" %}

```swift
func TickConveyorCCW(int16 ParamIdx) {
    let Params = BoardParams[ParamIdx]
    // Force a redraw every tick
    DrawTile(Params.X, Params.Y)
    Convey(Params.X, Params.Y, -1)
}
```


## Duplicator

Duplicators periodically copy the tile from the source side to the opposite side.  If blocked,
they will try to push the blocking tile out of the way.

If the player stands in the destination tile of a duplicator when it's active, the duplicator
will call the source tile's touch function.

Although this is implemented as a single procedure in ZZT, I have broken it into several
smaller functions for clarity.

### Tick function

{% include asmlink.html file="items/duplicator.asm" line="5" %}

```swift
func TickDuplicator(int16 ParamIdx) {
    let Params = BoardParams[ParamIdx]

    // Cycle through 5 frames of animation before duplicating
    if Params.Param1 <= 4 {  // animation frame
        Params.Param1 += 1
        DrawTile(Params.X, Params.Y)
    } else {
        Params.Param1 = 0  // reset frame count
        TryDuplication(Params)
    }

    // Update the cycle based on the duplication rate, ranging from 3 to 24 cycles.
    let Rate = Params.Param2
    Params.Cycle = (9 - Rate) * 3
}


func TryDuplication(ParamRecord* Params) {
    if CanDuplicate(Params) {
        let SourceTile = BoardTiles[Params.X + Params.StepX][Params.Y + Params.StepY]
        let SourceParamIdx = ParamIdxForXY(Params.X + Params.StepX, Params.Y + Params.StepY)
        if SourceParamIdx > 0 {
            // If the source tile has a parameter index, we have to spawn a copy.
            // We also check if the param count is less than 176 even though the max is 150.
            if BoardParamCount < 174) {
                let SourceParams = BoardParams[SourceParamIdx]
                Spawn(Params.X - Params.StepX, Params.Y - Params.StepY, SourceTile.Type,
                      SourceTile.Color, SourceParams.Cycle, SourceParams)
                DrawTile(Params.X - Params.StepX, Params.Y - Params.StepY)
            }
        } else if SourceParamIdx != 0 {  // never duplicate the player
            // Otherwise we can just copy the tile.
            BoardTiles[Params.X - Params.StepX][Params.Y - Params.StepY] = SourceTile
            DrawTile(Params.X - Params.StepX, Params.Y - Params.StepY)
        }
        PlaySoundPriority(3, sndDup)
    }

    Params.Param1 = 0  // reset frame count (redundant)
    DrawTile(Params.X, Params.Y)
}


//
// Check if the destination is blocked, pushing or touching as a side effect.
//
func CanDuplicate(ParamRecord* Params) -> Bool {
    var DestTile = BoardTiles[Params.X - Params.StepX][Params.Y - Params.StepY]

    // If the player is at the destination tile, call the source tiles' touch function.
    if DestTile.Type == TTPlayer {
        let SourceTile = BoardTiles[Params.X + Params.StepX][Params.Y + Params.StepY]
        let Touch = TileTypes[SourceTile.Type].TouchFunction
        // TODO: What are these unknown variables?
        Touch(Params.X + Params.StepX, Params.Y + Params.StepY, 0, UNKNOWN1, UNKNOWN2)
        return false
    }

    // If the destination isn't empty, try pushing it out of the way.
    if DestTile.Type != TTEmpty {
        TryPush(Params.X - Params.StepX, Params.Y - Params.StepY, -Params.StepX, -Params.StepY)
        DestTile = BoardTiles[Params.X - Params.StepX][Params.Y - Params.StepY]
    }

    // If the destination is still blocked, play the blocked sound.
    if DestTile.Type != TTEmpty {
        PlaySoundPriority(3, sndBlocked)
        return false
    }
    
    return true
}
```


## Player

The player object handles energizer animation, shooting, moving, some keyboard input, and some
other board related functions.

The player tick function is implemented as a single procedure, but its behavior is so complex
that I have broken it into multiple functions for this analysis.  All functions are listed in
the [Player][player] section.


### Tick function

{% include asmlink.html file="items/player.asm" line="5" %}

```swift
func TickPlayer(int16 ParamIdx) {
    let Params = BoardParams[ParamIdx]

    // Animate the color/character changes when the player is energized.
    if EnergizerCycles > 0 {
        AnimateEnergized(Params)
    } else {
        RestorePlayerAppearance(Params)
    }

    // If the player has no health, end the game.
    if CurrentHealth <= 0 {
        EndGame()
    }

    // Shooting always overrides moving.
    if (ShiftArrowPressed != 0) || (LastKeyCode == ' ') {
        // Handle shooting if shift-arrow or space is pressed.
        TryShooting(Params)
    } else if (PlayerXStep != 0) || (PlayerYStep != 0) {
        // Handle moving if the player has an X- or Y-step.
        TryMoving(Params)
    }

    // Handle other keyboard input: quit, save, torch, etc.
    HandleOtherKeyboardInput(Params)

    // If a torch is lit, update the torch
    if TorchCyclesLeft > 0 {
        UpdateTorch(Params)
    }

    // If the player is energized, update their state
    if EnergizerCycles > 0 {
        UpdateEnergizer(Params)
    }

    // If the board has a time limit, update the time elapsed
    if TimeLimit > 0 {
        UpdateBoardTime()
    }
}
```


## Scroll

Scrolls are objects that die when touched.  Every tick the scroll cycles through the intense
foreground colors.

### Tick function

{% include asmlink.html file="items/scroll.asm" line="5" %}

```swift
func TickScroll(int16 ParamIdx) {
    // Increment the scroll's color
    let Params = BoardParams[ParamIdx]
    BoardTiles[Params.X][Params.Y].Color += 1

    // Wrap back around to blue after white
    if BoardTiles[Params.X][Params.Y].Color > 15 {
        BoardTiles[Params.X][Params.Y].Color = 9
    }

    DrawTile(Params.X, Params.Y)
}
```

{% include links.html %}
