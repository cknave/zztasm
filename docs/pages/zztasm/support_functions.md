---
title: Support Functions
keywords: DieAttackingTile, Distance, MoveTile, Random, RandomStep, SeekStep, StepForDelta
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


## MoveTile

```swift
func MoveTile(int16 ParamIdx, int16 X, int16 Y)
```

Move the tile with the given parameter index to (X, Y).  The tile under the moved tile's
original location will be restored, and the background color of the tile will be updated to
match the background at the destination location.


## Random

```swift
func Random(int16 Max) -> int16
```

Return a random integer starting at 0 and up to, but not including, Max.


## RandomStep

```swift
func RandomStep() -> (int16 StepX, int16 StepY)
```

Return a random cardinal direction.  This function will never return a diagonal step.


## SeekStep

```swift
func SeekStep(int16 X, int16 Y) -> (int16 StepX, int16 StepY)
```

Given the position (X, Y), return a cardinal direction to walk towards the player.  If the
player is energized, return the opposite direction.

This function will never return a diagonal step.


## StepForDelta

```swift
func StepForDelta(int16 Delta) -> int16
```

Return -1 for a negative delta, 0 for 0, and 1 for a positive delta.

{% include links.html %}
