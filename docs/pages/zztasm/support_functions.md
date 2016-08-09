---
title: Support Functions
keywords: DieAttackingTile, Distance, MoveTileWithIdx, Random, RandomStep, SeekStep, StepForDelta
sidebar: zztasm_sidebar
permalink: support_functions.html
---

## About support functions

These functions are called by creatures during gameplay.  Full disassembly and pseudocode
are not yet complete.


## DieAttackingTile

```swift
func DieAttackingTile(int16 ParamIdx, int16 X, int16 Y)
```

Attack the tile at (X, Y) and kill the tile with the given parameter record.


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


## RemoveParamIdx

```swift
func RemoveParamIdx(int16 Index)
```

Full analysis to come.  Removes the object at this Index from `BoardParams`.


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

## StepForDelta

```swift
func StepForDelta(int16 Delta) -> int16
```

Return -1 for a negative delta, 0 for 0, and 1 for a positive delta.


## UpdateSideBar

```swift
func UpdateSideBar()
```

Redraw the sidebar.


{% include links.html %}
