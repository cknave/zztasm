---
title: Support Functions
keywords: Convey, DieAttackingTile, Distance, MoveTileWithIdx, Random, RandomStep, SeekStep,
          StepForDelta
sidebar: zztasm_sidebar
permalink: support_functions.html
---

## About support functions

These functions are called by creatures during gameplay.  Full disassembly and pseudocode
are not yet complete.


## Attack

[attack]: #attack

```swift
func Attack(int16 ParamIdx, int16 X, int16 Y)
```

If the tile at (X, Y) is the player, reduce their health and say "Ouch!"  For other tiles,
remove their parameter record.


## CheckBitmap

```swift
func CheckBitmap(uint8 Value, uint8[32] Bitmap) -> bool
```

Given a 256 bit (32 byte) Bitmap, return true if the *Value*th bit is set in the Bitmap.


## CheckTimeElapsed

```swift
func CheckTimeElapsed(uint16* LastTime, uint16 Duration) -> uint8
```

Check if Duration centiseconds have elapsed since the value pointed to by LastTime.  The
LastTime value should be a value in centiseconds less than 6000.  If this function returns
1 (true), the value pointed to by LastTime is updated to the current centiseconds offset.

If the time has not elapsed yet, 0 is returned.


## Convey

Rotate pushable tiles around a point.  Used by conveyors.

In the `Direction` parameter, 1 is clockwise and -1 is counterclockwise.

Although this is implemented as a single procedure in ZZT, I have broken it into several
smaller functions for clarity.

{% include asmlink.html file="convey.asm" line="5" %}

```swift
func Convey(int16 X, int16 Y, int16 Direction) {
    // Iterate over SW, S, SE, E, NE, N, NW, W; reverse it for counterclockwise.
    var Offsets = [(-1, 1), (0, 1), (1, 1), (1, 0), (1, -1), (0, -1), (-1, -1), (-1, 0)]
    if Direction != 1 {
        Offsets = reversed(Offsets)
    }

    // Get all the tiles around this conveyor.  Keep track of whether the last tile is
    // "movable": empty or pushable.
    var PrevTileMovable = true
    var Tiles = Tile[8]
    for (i, (XOffset, YOffset)) in enumerate(Offsets) {
        Tiles[i] = BoardTiles[X + XOffset][Y + YOffset]
        if Tiles[i].Type == TTEmpty {
            PrevTileMovable = true
        } else if TileTypes[Tiles[i]].Pushable == 0 {
            PrevTileMovable = false
        }
    }

    // Start rotating as soon as the previous tile is movable.
    for Index in len(Offsets) {
        var Tile = Tiles[i]
        if !PrevTileMovable {
            // Couldn't rotate this time.  If this tile is movable, we can rotate next time.
            PrevTileMovable = IsTileMovable(Tile)
        } else {
            // The previous tile can be moved.  As long as the current tile can be pushed
            // out of the way, we can rotate it into this space.
            if TileTypes[Tile.Type].Pushable {
                Rotate(X, Y, Direction, Offsets, Tiles, Index)
                // If the next tile isn't pushable, clear out the (now vacated) current tile.
                // This is not necessary if the next tile is pushable, since it will be pushed
                // into this spot.
                let NextTile = Tiles[(Index + Direction) % len(Tiles)]
                if TileTypes[NextTile.Type].Pushable == 0 {
                    let (OffsetX, OffsetY) = Offsets[Index]
                    BoardTiles[X + OffsetX][Y + OffsetY].Type = TTEmpty
                    DrawTile(X + OffsetX, Y + OffsetY)
                }
            } else {
                // We can't rotate this time since the destination isn't movable, and we won't
                // be able to rotate next time since the source won't be movable.
                PrevTileMovable = false
            }
        }
    }
}


func Rotate(int16 X, int16 Y, int16 Direction, int16 Offsets, int16 Tiles, int16 Index) {
    // Calculate source (Index) and destination (Index-1) locations.
    let (SrcXOffset, SrcYOffset) = Offsets[Index]
    let (SrcX, SrcY) = (X + SrcXOffset, Y + SrcYOffset)
    let (DestXOffset, DestYOffset) = Offsets[(Index - Direction) % len(Offsets)]
    let (DestX, DestY) = (X + DestXOffset, Y + DestYOffset)
    
    // If the current tile has params, move it.
    if TileTypes[Tiles[Index].Type].Cycle > -1 {
        let SrcTile = BoardTiles[SrcX][SrcY]
        let SrcParamIdx = ParamIdxForXY(SrcX, SrcY)
        // Set the correct tile types at the source and destination, then move.
        BoardTiles[SrcX][SrcY] = Tiles[Index]
        BoardTiles[DestX][DestY].Type = TTEmpty
        MoveTileWithIdx(SrcParamIdx, DestX, DestY)
    } else {
        // No params to move, just copy the tile.
        BoardTiles[DestX][DestY] = Tiles[Index]
        DrawTile(DestX, DestY)
    }
}


//
// Check if a tile is movable for a conveyor belt.  Empty and pushable tiles are movable.
//
func IsTileMovable(Tile tile) -> Bool {
    if Tile.Type == TTEmpty {
        return true
    } else {
        return (TileTypes[Tile.Type].Pushable != 0)
    }
}
```


## Destroy

```swift
func Destroy(int16 X, int16 Y)
```

If the tile at (X, Y) has a parameter record, [attack][attack] it.  Otherwise, replace it
with empty.


## DieAttackingTile

```swift
func DieAttackingTile(int16 ParamIdx, int16 X, int16 Y)
```

[Attack][attack] the tile at (X, Y) and kill the tile with the given parameter record.


## Distance

```swift
func Distance(int16 A, int16 B) -> int16
```

Calculate the distance between two scalar values, i.e. `abs(A - B)`.


## DrawTile

```swift
func DrawTile(int16 X, int16 Y)
```

Redraw the tile at (X, Y).


## Explode

```swift
func Explode(int16 CenterX, int16 CenterY, int16 Mode)
```

Manipulate a circle of tiles around a center point.  Normally used for bomb explosions, but
can also be used to draw the circle of visible tiles around the player in a dark board.

The Mode parameter selects what to do with the circle.  It takes the following values:

| Value | Enumeration  | Description                                                      |
|-------+--------------+------------------------------------------------------------------|
| 0     | EMRedrawOnly | Redraw tiles                                                     |
| 1     | EMBomb       | Send BOMBED, destroy destructibles, replace empty with breakable |
| 2     | EMCleanUp    | Replace breakable with empty                                     |



## MoveTileWithIdx

```swift
func MoveTileWithIdx(int16 ParamIdx, int16 X, int16 Y)
```

Move the tile with the given parameter index to (X, Y).  The tile under the moved tile's
original location will be restored, and the background color of the tile will be updated to
match the background at the destination location.


## ParamIdxForXY

```swift
func ParamIdxForXY(int16 X, int16 Y) -> int16
```

Get the index into `BoardParams` of the tile at (X, Y).  Return -1 if there are no parameters
for that tile.


## PlaySoundPriority

```swift
func PlaySoundPriority(int16 priority, string data)
```

Full analysis to come.  Seems to overwrite the sound buffer based on a priority number.


## PromptQuit

```swift
func PromptQuit()
```

Present a Y/N prompt to "End this game?"  If the user selects Y, the global `ShouldQuit` flag
is set.


## PromptSaveWorld

```swift
func PromptSaveWorld(string* Prompt, string* Filename, string* Extension)
```

Prompt the user to save the current world.  This is used both for saving worlds in the editor,
as well as making saved games by replacing the ".ZZT" extension with ".SAV".  If accepted, the
Filename is updated with the user's input, and the world will be saved to the specified file.


## Random

```swift
func Random(int16 Max) -> int16
```

Return a random integer starting at 0 and up to, but not including, Max.


## RandomStep

Return a random cardinal direction.  For each step, there is a 2/3 chance of moving horizontally
and a 1/3 chance of moving vertically.

This function will never return a diagonal step.

{% include asmlink.html file="step.asm" line="5" %}

```swift
func RandomStep() -> (int16 StepX, int16 StepY) {
    // Get a value between [-1,1] and assign it to StepX.
    let StepX = Random(3) - 1

    // Set StepY only if we got 0 for StepX.
    let StepY
    if StepX == 0 {
        // Get a value that's either -1 or 1 and assign it to StepY.
        StepY = 2*Random(2) - 1
    } else {
        StepY = 0
    }

    return (StepX, StepY)
}
```


## RedrawBorder

```swift
func RedrawBorder()
```

Redraw the outermost tiles on the board.


## RemoveParamIdx

```swift
func RemoveParamIdx(int16 Index)
```

Full analysis to come.  Removes the object at this Index from `BoardParams`.


## RunCodeCycle

```swift
func RunCodeCycle(int16 ParamIdx, uint8* InstructionPtr, string* DefaultTitle)
```

Run the ZZT-OOP interpreter starting on the given InstructionPtr, a pointer into the
object's code.

The DefaultTitle will be used as the default title if a text scroll is displayed, though
this can be overridden by the Scroll or Object.


## SayMessage

```swift
func SayMessage(int16 Duration, string* Message)
```

Remove any existing Messenger at (0, 0), and spawn a new Messenger at (0, 0) to say the
given Message for Duration (in centiseconds).

ZZT does not calculate the total time accurately, causing it to be slightly fast or much slower
depending on the user's selected game speed.


## SeekStep

Given the position (X, Y), return a cardinal direction to walk towards the player.  There is
a 50/50 chance of moving horizontally or vertically.

If the player is energized, return the opposite direction.

This function will never return a diagonal step.

{% include asmlink.html file="step.asm" line="56" %}

```swift
func SeekStep(int16 X, int16 Y) -> (int16 StepX, int16 StepY) {
    var StepX = 0
    var StepY = 0

    // Pick randomly whether to move on the X or Y axis
    let PickedY = (Random(2) == 1)

    // If we picked Y but are already aligned on the Y axis, set X instead
    if !PickedY || PlayerY == Y {
        // Set StepX towards the player
        StepX = StepForDelta(PlayerX - X)
    }

    // If we didn't move on the X axis, move on the Y axis
    if StepX == 0 {
        // Set StepY towards the player
        StepY = StepForDelta(PlayerY - Y)
    }

    // Reverse the result if the player is energized
    if EnergizerCycles > 0 {
        StepX = -StepX
        StepY = -StepY
    }

    return (StepX, StepY)
}
```


## Send

```swift
func Send(int16 Index, string Label, int16 OverrideLock) -> int16
```

For Objects and Scrolls, send the parameter record at `BoardParams[Index]` to the Label if they
have it.  If the label is something like "all:label", the destination prefix will be used and
all matching objects will be sent.

If the object has been locked, this call will be ignored unless OverrideLock is set.  If the
Index is negative, it won't override locking.  But if the Index is positive, it might.  More
analysis is needed.

Returns 1 if the message was sent and 0 if not.


## Shoot

```swift
func Shoot(uint8 ShootType, int16 X, int16 Y, int16 StepX, int16 StepY, uint8 Owner) -> uint8
```

From the tile at (X, Y) attempt to shoot towards (StepX, StepY).  ShootType should be TTBullet
or TTStar, and Owner should be SOPlayer or SOEnemy.

If the tile is blocked, nothing will happen and 0 will be returned.  On success, 1 is returned.


## ShowDebugPrompt

```swift
func ShowDebugPrompt()
```

Prompt the user for debug/cheat commands, and execute them.


## ShowHelpFile

```swift
func ShowHelpFile(string* Filename, string* Title)
```

Display a help file in a scroll, with the given title.


## Spawn

```swift
func Spawn(int16 X, int16 Y, int16 Type, int16 Color, int16 Cycle, ParamRecord* SourceParams)
```

Spawn a new tile with a parameter record copied from a source record.  If the source record
has code, the code will be copied as well.


## StepForDelta

```swift
func StepForDelta(int16 Delta) -> int16
```

Return -1 for a negative delta, 0 for 0, and 1 for a positive delta.


## TryPush

```swift
func TryPush(int16 X, int16 Y, int16 StepX, int16 StepY)
```

Try to push an object at (X, Y) in the direction of (StepX, StepY).  If the object is pushed
into a transporter, try to transport it.  If the object is pushed into a destructible tile,
destroy that tile.

If the object is blocked, recursively try to push the blocking object.


## UpdateSideBar

```swift
func UpdateSideBar()
```

Redraw the sidebar.


{% include links.html %}
