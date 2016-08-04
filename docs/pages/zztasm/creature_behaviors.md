---
title: Creature Behaviors
keywords: Tick Functions, Bear, Lion, Tiger
sidebar: zztasm_sidebar
permalink: creature_behaviors.html
---


## Bear

### Tick Function

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
        MoveTile(ParamIdx, DestX, DestY)
        return
    }

    // If we're blocked by the player or a breakable wall, die attacking that tile.
    if DestTile.Type == TTPlayer || DestTile.Type == TTBreakable {
        DieAttackingTile(ParamIdx, DestX, DestY)
    }
}
```


## Centipede Segment

### Tick Function

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


## Lion

### Tick Function

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
        MoveTile(ParamIdx, DestX, DestY)
        return
    }

    // If we're blocked by the player, die attacking them.
    if DestTile.Type == TTPlayer {
        DieAttackingTile(ParamIdx, DestX, DestY)
    }
}
```


## Tiger

### Tick Function

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
