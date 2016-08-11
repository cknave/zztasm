---
title: Creature Behaviors
keywords: Tick functions, Bear, Bullet, Centipede, Duplicator, Head, Lion, Segment, Star, Tiger
sidebar: zztasm_sidebar
permalink: creature_behaviors.html
---


## Bear

### Tick function

A bear will check if the player is within the range defined by its Sensitivity parameter and
walk towards them if they are.  If the bear encounters the player or a breakable wall, it dies
attacking that tile.

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

### Tick function

Bullets move until they hit something.  If they hit a destructible tile, they attack it.
If they hit an indestructible tile, they die.

A bullet that hits a ricochet will bounce back.  A bullet that hits a tile with an adjacent
ricochet will bounce at a right angle to its current direction, away from the ricochet.
Enemy bullets can "corner ricochet" off destructible tiles, but player bullets will destroy
them.

Although this is implemented as a single procedure in ZZT, I have broken it into several
smaller functions for clarity.

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
            RemoveParamAtIdx(ParamIdx)
            MYSTERYParamCount -= 1  // TODO: what is this thing?
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


## Centipede Head

### Tick function

A centipede head will move towards the player when aligned if it passes an intelligence check.
Otherwise, it will randomly change direction if it passes a deviance check.

The centipede head tick function is implemented as a single procedure, but its behavior is
so complex that I have broken it into multiple functions for this analysis.  All functions
are listed in the [Centipede heads][centipede_heads] section.

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


## Centipede Segment

### Tick function

A centipede head doesn't need to do anything as long as it has a leader.  Its movement is
handled by the head of the centipede.  If it has no leader, it waits a tick by decrementing
its leader index, then turns into a new head.

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


## Duplicator

### Tick function

Duplicators periodically copy the tile from the source side to the opposite side.  If blocked,
they will try to push the blocking tile out of the way.

If the player stands in the destination tile of a duplicator when it's active, the duplicator
will call the source tile's touch function.

Although this is implemented as a single procedure in ZZT, I have broken it into several
smaller functions for clarity.


{% include asmlink.html file="creatures/duplicator.asm" line="5" %}

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


## Lion

### Tick function

A lion will, depending on its intelligence parameter, either walk towards the player or in a
random direction.

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


## Scroll

### Tick function

Scrolls are objects that die when touched.  Every tick the scroll cycles through the intense
foreground colors.

{% include asmlink.html file="creatures/scroll.asm" line="5" %}

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


## Star

### Tick function

Stars have a limited lifetime, and constantly seek the player.  They are able to push other
tiles out of the way.

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

### Tick function

A tiger is a lion that will shoot bullets or stars at the player depending on its firing rate
and alignment to the player.

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
