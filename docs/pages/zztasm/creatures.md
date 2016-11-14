---
title: Creatures
keywords: Tick functions, Bear, Bullet, Centipede, Clockwise, Conveyor, Counterclockwise, Head,
          Lion, Object, Pusher, Ruffian, Segment, Shark, Slime, Spinning Gun, Star, Tiger
sidebar: zztasm_sidebar
permalink: creatures.html
redirect_from: creature_behaviors.html
---

## Bear

A bear will check if the player is within the range defined by its Sensitivity parameter and
walk towards them if they are.  If the bear encounters the player or a breakable wall, it dies
attacking that tile.

### Tick function

{% include asmlink.html file="creatures/bear.asm" line="5" %}

```swift
func TickBear(int16 ParamIdx) {
    // Get the parameters for this bear.
    let Params = BoardParams[ParamIdx]
    let Sensitivity = Params.Param1

    // Decide if we should move, and in which direction.
    var StepX = 0
    var StepY = 0

    // If the player is within sensitivity range on the Y axis, move in the X direction
    // unless the player is exactly aligned on the X axis.
    if (PlayerX != Params.X) && (Distance(Params.Y, PlayerY) < (8 - Sensitivity)) {
        StepX = StepForDelta(Params.X - PlayerX)
    }
    // Otherwise if the player is within sensitivity range on the X axis, move in the Y
    // direction.
    else if Distance(Params.X, PlayerX) < (8 - Sensitivity) {
        StepY = StepForDelta(Params.Y - PlayerY)
    }

    // Check if we can move in the selected direction.  Note that if we decided not to move,
    // we will be blocking ourselves!
    let DestX = Params.X + StepX
    let DestY = Params.Y + StepY
    let DestTile = BoardTiles[DestX][DestY]
    if TileType[DestTile.Type].Passable {
        MoveTileWithIdx(ParamIdx, DestX, DestY)
        return
    }

    // If we're blocked by the player or a breakable wall, die attacking that tile.
    if DestTile.Type == TTPlayer || DestTile.Type == TTBreakable {
        DieAttackingTile(ParamIdx, DestX, DestY)
    }
}
```


## Bullet

Bullets move until they hit something.  If they hit a destructible tile, they attack it.
If they hit an indestructible tile, they die.

A bullet that hits a ricochet will bounce back.  A bullet that hits a tile with an adjacent
ricochet will bounce at a right angle to its current direction, away from the ricochet.
Enemy bullets can "corner ricochet" off destructible tiles, but player bullets will destroy
them.

Although this is implemented as a single procedure in ZZT, I have broken it into several
smaller functions for clarity.

### Tick function

{% include asmlink.html file="creatures/bullet.asm" line="5" %}

```swift
func TickBullet(int16 ParamIdx) {
    let Params = BoardParams[ParamIdx]

    // We can try moving an extra time if ricocheting.
    var CanRicochet = true
    while true {
        // If we can move through the next tile, move and we're done.
        // (Water is not passable, but bullets can still move over it.)
        let NextX = Params.X + Params.StepX
        let NextY = Params.Y + Params.StepY
        let NextTileType = BoardTiles[NextX][NextY]
        if (TileTypes[NextTileType].Passable != 0) || (NextTileType == TTWater) {
            MoveTileWithIdx(ParamIdx, NextX, NextY)
            return
        }

        // Flip direction if hitting a ricochet and try moving again.
        if (NextTileType == TTRicochet) && CanRicochet {
            Params.StepX = -Params.StepX
            Params.Stepy = -Params.StepY
            PlaySoundPriority(1, Sounds.Ricochet)
            CanRicochet = false
            continue
        }

        // Breakables aren't "destructible" but can be killed with bullets.
        if NextTileType == TTBreakable {
            AttackNextTile(ParamIdx, NextTileType, NextX, NextY)
            return
        }

        // Check for corner ricochet.  Player bullets only check on indestructible tiles.
        if (TileTypes[NextTileType].Destructible == 0) || (Params.Param1 != SOPlayer) {
            // Don't check for corner ricochet off the player, just attack.
            if NextTileType == TTPlayer {
                AttackNextTile(ParamIdx, NextTileType, NextX, NextY)
                return
            }

            // If we can corner ricochet, update our step and try moving again.
            if CanRicochet && TryCornerRicochet(Params.X, Params.StepX, Params.Y, Params.StepY) {
                PlaySoundPriority(1, Sounds.Ricochet)
                CanRicochet = false
                continue
            }
        }

        // We didn't ricochet, so either die hitting a destructible tile or attack a
        // destructible one.
        if TileTypes[NextTileType].Destructible == 0 {
            // Remove the param record, and decrement the current index
            RemoveParamAtIdx(ParamIdx)
            CurrentParamIdx -= 1
            // If we hit an object or scroll, send it to SHOT.
            if (NextTileType == TTObject) || (NextTileType == TTScroll) {
                let DestIdx = ParamIdxForXY(NextX, NextY)
                Send(-DestIdx, "SHOT", 0)
            }
        } else {
            AttackNextTile(ParamIdx, NextTileType, NextX, NextY)
        }
        return
    }
}


func AttackNextTile(int16 ParamIdx, int16 Type, int16 X, int16 Y) {
    if TileTypes[Type].Score != 0 {
        // Update the score and redraw the sidebar
        CurrentScore += TileTypes[Type].Score
        UpdateSideBar()
    }
    DieAttackingTile(ParamIdx, X, Y)
}


func TryCornerRicochet(int16 X, int16 StepX, int16 Y, int16 StepY) -> Bool {
    // Check clockwise.
    if BoardTiles[X + StepY][Y + StepX] == TTRicochet {
        let Temp = Params.StepX
        Params.StepX = -Params.StepY
        Params.StepY = -Temp
        return true
    }

    // Check counterclockwise.
    if BoardTiles[X - StepY][Y - Stepx] == TTRicochet
        let Temp = Params.StepX
        Params.StepX = Params.StepY
        Params.StepY = Temp
        return true
    }

    return false
}
```


## Centipede head

A centipede head will move towards the player when aligned if it passes an intelligence check.
Otherwise, it will randomly change direction if it passes a deviance check.

The centipede head tick function is implemented as a single procedure, but its behavior is
so complex that I have broken it into multiple functions for this analysis.  All functions
are listed in the [Centipede head][centipede_head] section.

### Tick function

{% include asmlink.html file="creatures/head.asm" line="5" %}

```swift
func TickHead(int16 ParamIdx) {
    let Params = BoardParams[ParamIdx]

    // Seek the player if aligned and pass an intelligence check.  Otherwise change direction
    // if we pass a deviance check.
    ChooseDirection(Params)

    // If we're blocked at the destination tile (but not by the player), try all other directions
    // to find an unblocked tile.
    ChangeStepIfBlocked(Params)

    // If we're blocked (step is 0), become a segment with no leader and reverse the direction
    // of this centipede.
    if (Params.StepX == 0) && (Params.StepY == 0) {
        BoardTiles[Params.X][Params.Y].Type = TTSegment
        Params.Leader = -1
        ReverseCentipede(ParamIdx)
        return
    }

    // Die attacking the player if we're moving into them.
    if BoardTiles[Params.X + Params.StepX][Params.Y + Params.StepY].Type == TTPlayer {
        // Before attacking, free our follower if we have one.
        if Params[Follower] != -1 {
            MakeFollowerNewHead(Params)
        }
        DieAttackingPlayer(ParamIdx, Params.X + Params.StepX, Params.Y + Params.StepY)
        return
    }

    // Move the entire centipede in the step we chose, attaching any adjacent leaderless segments
    // to the tail.
    MoveAndReattachCentipede(ParamIdx)
}
```


## Centipede segment

A centipede head doesn't need to do anything as long as it has a leader.  Its movement is
handled by the head of the centipede.  If it has no leader, it waits a tick by decrementing
its leader index, then turns into a new head.

### Tick function

{% include asmlink.html file="creatures/segment.asm" line="5" %}

```swift

func TickSegment(int16 ParamIdx) {
    // If this segment has a leader, no need to do anything.
    let Params = BoardParams[ParamIdx]
    if Params.Leader >= 0 {
        return
    }

    // If the leader index is -1, decrease it.  This lets us wait a tick until turning
    // into a head.
    if Params.Leader == -1 {
        Params.Leader -= 1
        return
    }

    // The leader index is now -2, time to turn into a head.
    BoardTiles[Params.X][Params.Y].Type = TTHead
}
```


## Lion

A lion will, depending on its intelligence parameter, either walk towards the player or in a
random direction.

### Tick function

{% include asmlink.html file="creatures/lion.asm" line="5" %}

```swift
func TickLion(int16 ParamIdx) {
    // Get the parameters for this lion.
    let Params = BoardParams[ParamIdx]
    let Intelligence = Params.Param1

    // Decide which direction to move.  If we pass an intelligence check, step towards the
    // player.  Otherwise move in a random direction.
    let StepX
    let StepY
    if Random(10) >= Intelligence {
        StepX, StepY = SeekStep(Params.X, Params.Y)
    } else {
        StepX, StepY = RandomStep()
    }

    // If we're not blocked in that direction, move there.
    let DestX = Params.X + StepX
    let DestY = Params.Y + StepY
    let DestTile = BoardTiles[DestX][DestY]
    if TileTypes[DestTile.Type].Passable {
        MoveTileWithIdx(ParamIdx, DestX, DestY)
        return
    }

    // If we're blocked by the player, die attacking them.
    if DestTile.Type == TTPlayer {
        DieAttackingTile(ParamIdx, DestX, DestY)
    }
}
```


## Object

An object runs its program every tick if it's active, and can move.

### Tick function

{% include asmlink.html file="creatures/object.asm" line="5" %}

```swift
func TickObject(int16 ParamIdx) {
    let Params = BoardParams[ParamIdx]
    // If the program is active (instruction pointer > 0), run a cycle.
    if Params.InstructionPtr >= 0 {
        RunCodeCycle(ParamIdx, Params.InstructionPtr, "Interaction")
    }
    // If the object is moving, handle movement.
    if (Params.StepX != 0) || (Params.StepY != 0) {
        // Try to move.  If blocked, send THUD.
        let Tile = BoardTiles[Params.X + Params.StepX][Params.Y + Params.StepY]
        if TileTypes[Tile.Type].Passable == 0 {
            Send(-ParamIdx, "THUD", 0)
        } else {
            MoveTileWIthIdx(ParamIdx, Params.X + Params.StepX, Params.Y + Params.StepY)
        }
    }
}
```


## Ruffian

Ruffians do a resting time check to start or stop moving.  They stay moving in the same
direction, unless aligned with the player.  If aligned, the ruffian will do an intelligence
check to change direction towards the player.

### Tick function

{% include asmlink.html file="creatures/ruffian.asm" line="5" %}

```swift
func TickRuffian(int16 ParamIdx) {
    let Params = BoardParams[ParamIdx]
    let Intelligence = Params.Param1
    let RestingTime = Params.Param2
    
    // If we're not moving, do a resting time check.  If passed, set our direction towards the
    // player if we pass an intelligence check.  Otherwise, set it randomly.
    if (Params.StepX == 0) && (Params.StepY == 0) {
        if (RestingTime + 8) < Random(11) {
            if Intelligence >= Random(9) {
                (Params.StepX, Params.StepY) = SeekStep(Params.X, Params.Y)
            } else {
                (Params.StepX, Params.StepY) = RandomStep()
            }
        }
        return
    }

    // We're currently moving.  If we're aligned with the player, do an intelligence check
    // to seek them.
    if (Params.Y == PlayerY) || (Params.X == PlayerX) {
        if Intelligence >= Random(9) {
            (Params.StepX, Params.StepY) = SeekStep(Params.X, Params.Y)
        }
    }

    // If we'll hit the player, attack.
    let TargetTile = BoardTiles[Params.X + Params.StepX][Params.Y + Params.StepY]
    if TargetTile.Type == TTPlayer {
        DieAttackingTile(Params.X + Params.StepX, Params.Y + Params.StepY)
        return
    }

    // If we're blocked, stop moving.
    if TileTypes[TargetTile.Type].Passable == 0 {
        Params.StepX = 0
        Params.StepY = 0
        return
    }

    // Move in the current direction.
    MoveTileWIthIdx(ParamIdx, Params.X + Params.StepX, Params.Y + Params.StepY)

    // Resting time check to stop moving.
    if (RestingTime + 8) <= Random(11) {
        Params.StepX = 0
        Params.StepY = 0
    }
}
```


## Shark

Sharks move through water tiles only.  If they pass an intelligence check, they move towards
the player.  Otherwise they move randomly.

### Tick function

{% include asmlink.html file="creatures/shark.asm" line="5" %}

```swift
func TickShark(int16 ParamIdx) {
    let Params = BoardParams[ParamIdx]

    // Intelligence check to step towards player instead of randomly
    if Params.Param1 < Random(10) {
        (Params.StepX, Params.StepY) = RandomStep()
    } else {
        (Params.StepX, Params.StepY) = SeekStep(Params.X, Params.Y)
    }

    // Move through water tiles, or die attacking the player
    if BoardTiles[Params.X + Params.StepX][Params.Y + Params.StepY] == TTWater {
        MoveTileWithIdx(ParamIdx, Params.X + Params.StepX, Params.Y + Params.StepY)
    } else if BoardTiles[Params.X + Params.StepX][Params.Y + Params.StepY] == TTPlayer) {
        DieAttackingTile(ParamIdx, Params.X + Params.StepX, Params.Y + Params.StepY)
    }
}
```


## Slime

Slimes expand out in all 4 directions, leaving a trail of breakables behind.  In ZZT, this
expansion is accomplished by moving into the first passable tile, and spawning new slimes
in the remaining passable tiles.

### Tick function

{% include asmlink.html file="creatures/slime.asm" line="5" %}

```swift
func TickSlime(int16 ParamIdx) {
    let Params = BoardParams[ParamIdx]

    // Increment tick count until it's time to move
    let TicksToMove = Params.Param1
    let MovementSpeed = Params.Param2
    if TicksToMove < MovementSpeed {
        Params.Param1 += 1
        return
    }
    // Reset ticks to next move
    Params.Param1 = 0

    let X = Params.X
    let Y = Params.Y
    let Color = BoardTiles[X][Y].Color

    // Loop over the directions N, S, W, E
    var NumPassableTiles = 0
    for (XOffset, YOffset) in [(0, -1), (0, 1), (-1, 0), (1, 0)] {
        // Check if the next tile is passable
        let Tile = BoardTiles[X + XOffset][Y + YOffset]
        if TileTypes[Tile.Type].Passable == 0 {
            continue
        }
        // If this is the first passable tile found, move into that tile and create a breakable
        // wall at the original space.
        //
        // For every other passable tile found, spawn a new slime in that tile.
        if NumPassableTiles == 0 {
            MoveTileWithIdx(ParamIdx, X + XOffset, Y + YOffset)
            BoardTiles[X][Y].Color = Color
            BoardTiles[X][Y].Type = TTBreakable
            DrawTile(X, Y)
        } else {
            Spawn(X + XOffset, Y + YOffset, TTSlime, Color, TileTypes[TTSlime].Cycle,
                  UnknownParamBuf)  // TODO: what is this parameter buffer?
            BoardParams[BoardParamCount].Param2 = MovementSpeed
        }
        NumPassableTiles += 1
    }

    // If we couldn't find any passable tiles to move into, die and turn into a breakable.
    if NumPassableTiles == 0 {
        RemoveParamIdx(ParamIdx)
        BoardTiles[X][Y].Color = Color
        BoardTiles[X][Y].Type = TTBreakable
        DrawTile(X, Y)
    }
}
```


## Spinning gun

### Tick function

Spinning guns have a random chance of shooting based on their firing rate.  If they do fire,
they have a random chance of shooting towards a player that is nearly aligned based on their
intelligence.

{% include asmlink.html file="creatures/spinning_gun.asm" line="5" %}

```swift
func TickSpinningGun(int16 ParamIdx) {
    // Redraw every tick to keep spinning
    let Params = BoardParams[ParamIdx]
    DrawTile(Params.X, Params.Y)

    // Check the high bit of the firing rate for the shoot type
    let FiringRate = Params.Param2 & 0x7f
    let ShootStars = Params.Param2 & 0x80
    let ShootType = ShootStars ? TTStar : TTBullet

    // Firing rate check
    if FiringRate <= Random(9) {
        return
    }

    // Intelligence check
    var DidShoot = false
    if Params.Param1 < Random(9) {
        // Shoot randomly
        let StepX, StepY = RandomStep()
        DidShoot = Shoot(ShootType, Params.X, Params.Y, StepX, StepY, SOEnemy)
    } else {
        // If the player's close on the X axis, shoot on the Y axis
        if Distance(Params.X, PlayerX) <= 2 {
            let StepY = StepForDelta(PlayerY - Params.Y)
            DidShoot = Shoot(ShootType, Params.X, Params.Y, 0, StepY, SOEnemy)
        }
        // If we haven't shot yet, and the player's close on the Y axis, shoot on the X axis
        if !DidShoot && Distance(Params.Y, PlayerY) <= 2 {
            let StepX = StepForDelta(PlayerX - Params.X)
            DidShoot = Shoot(ShootType, Params.X, Params.Y, StepX, 0, SOEnemy)
        }
    }
}
```


## Star

Stars have a limited lifetime, and constantly seek the player.  They are able to push other
tiles out of the way.

### Tick function

{% include asmlink.html file="creatures/star.asm" line="5" %}

```swift
func TickStar(int16 ParamIdx) {
    // Decrement ticks left (Param2) and check if still alive.
    let Params = BoardParams[ParamIdx]
    Params.Param2 -= 1
    if Params.Param2 <= 0 {
        // Out of ticks, time to die.
        RemoveParamIdx(ParamIdx)
        return
    }

    // Move every 2 ticks; otherwise just redraw.
    if Params.Param2 % 2 == 0 {
        DrawTile(Params.X, Params.Y)
        return
    }

    // Try to step towards the player.
    Params.StepX, Params.StepY = SeekStep(Params.X, Params.Y)
    let DestTile = BoardTiles[Params.X + Params.StepX][Params.Y + Params.StepY]

    // Attack the player or breakable wall.
    if (DestTile.Type == TTPlayer) || (DestTile.Type == TTBreakable) {
        DieAttackingTile(ParamIdx, Params.X + Params.StepX, Params.Y + Params.StepY)
        return
    }

    // If blocked, try pushing the tile out of the way.
    if TileTypes[DestTile.Type].Passable == 0 {
        TryPush(Params.X + Params.StepX, Params.Y + Params.StepY, Params.StepX, Params.StepY)
    }

    // We can move over passable tiles as well as water.
    if (TileTypes[DestTile.Type].Passable != 0) || (DestTile.Type == TTWater) {
        MoveTileWithIdx(ParamIdx, Params.X + Params.StepX, Params.Y + Params.StepY)
    }
}
```


## Tiger

A tiger is a lion that will shoot bullets or stars at the player depending on its firing rate
and alignment to the player.

### Tick function

{% include asmlink.html file="creatures/tiger.asm" line="5" %}

```swift
func TickTiger(int16 ParamIdx) {
    // Unpack Param2 into firing rate and type.
    let Params = BoardParams[ParamIdx]
    let FiringRate = Params.Param2 & 0x7f
    let ShootStars = Params.Param2 & 0x80
    let ShootType = ShootStars ? TTStar : TTBullet

    // Decide if we're going to shoot this tick.  Note that because the random number is
    // multiplied by 3, there are effectively only 3 different firing rates: 0-2, 3-5, and
    // 6-8.
    var DidShoot = false
    if Random(10) * 3 >= FiringRate {
        // If the player is within 2 tiles on the X axis, shoot on the Y axis.
        if Distance(Params.X, PlayerX) <= 2 {
            let StepY = StepForDelta(Params.Y - PlayerY)
            DidShoot = Shoot(ShootType, Params.X, Params.Y, 0, StepY, SOEnemy)
        }

        // If we haven't shot on the Y axis, check the X axis.
        if !DidShoot && Distance(Params.Y, PlayerY) <= 2 {
            let StepX = StepForDelta(Params.X - PlayerX)
            DidShoot = Shoot(ShootType, Params.X, Params.Y, StepX, 0, SOEnemy)
        }
    }

    // Use the same movement behavior as a lion.
    TickLion(ParamIdx)
}
```

{% include links.html %}
