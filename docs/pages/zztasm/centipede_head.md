---
title: Centipede Head
keywords: Tick Functions, Bear, Centipede, Head, Lion, Segment, Tiger
sidebar: zztasm_sidebar
permalink: centipede_head.html
---


## High-level overview

A centipede head will move towards the player when aligned if it passes an intelligence check.
Otherwise, it will randomly change direction if it passes a deviance check.

The centipede head tick function is implemented as a single procedure, but its behavior is
so complex that I have broken it into multiple functions for this analysis.


## Full pseudocode

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


//
// Update Params.StepX and Params.StepY if the centipede wants to change direction.
//
func ChooseDirection(ParamRecord* Params) {
    // If we're aligned with the player, move towards them if we pass an intelligence check
    // Otherwise randomly change direction if we pass a deviance check
    if Params.X == PlayerX {
        // Intelligence check to seek player
        if Params.Param1 > Random(10) {
            // Set step towards player on Y axis
            Params.StepY = StepForDelta(PlayerY - Params.Y)
            Params.StepX = 0
        }
    } else if Params.Y == PlayerY {
        if Params.Param1 > Random(10) {
            // Set step towards player on X axis
            Params.StepX = StepForDelta(PlayerX - Params.X)
            Params.StepY = 0
        }
    } else if Params.Param2 > 4*Random(10) {
        // Note that because the random number is multiplied by 4, there are effectively only
        // 3 deviance levels: 0-3, 4-7, and 8.
        Params.StepX, Params.StepY = RandomStep()
    }
}


//
// Check if we are blocked at this position, ignoring the player
//
func BlockedIgnoringPlayer(int16 X, int16 Y) -> Bool {
  let Type = BoardTiles[X][Y].Type
  return (TileTypes[Type].Passable == 0) || (Type == TTPlayer)
}


//
// If we're currently blocked (not by the player), try setting StepX and StepY to all other
// directions until we find a non-blocked destination tile.
//
func ChangeStepIfBlocked(ParamRecord* Params) {
    if !BlockedIgnoringPlayer(X+Params.StepX, Y+Params.StepY) {
        return
    }
    let OrigStepX = Params.StepX
    let OrigStepY = Params.StepY

    // Randomly turn clockwise or counter-clockwise, i.e.
    // Set StepX to randomly StepY or -StepY
    // Set StepY to randomly StepX or -StepX
    let Temp     = Params.StepY * (2*Random(2) - 1)  // times -1 or 1
    Params.StepY = Params.StepX * (2*Random(2) - 1)  // times -1 or 1
    Params.StepX = Temp
    if !BlockedIgnoringPlayer(X+Params.StepX, Y+Params.StepY) {
        return
    }

    // Try turning in the opposite direction (i.e. negate the step)
    Params.StepX = -Params.StepX
    Params.StepY = -Params.StepY
    if !BlockedIgnoringPlayer(X+Params.StepX, Y+Params.StepY) {
        return
    }

    // Try going backwards (compared to the original direction)
    if !BlockedIgnoringPlayer(X-OrigStepX, Y-OrigStepY) {
        Params.StepX = -OrigStepX
        Params.StepY = -OrigStepY
        return
    }

    // Otherwise, we can't move
    Params.StepX = 0
    Params.StepY = 0
}


//
// Make the follower of this head into a new head with the same step.
//
func MakeFollowerNewHead(ParamRecord* Params) {
    // Change the follower's type to a Head.
    let FollowerParams = BoardParams[Params[Follower]]
    BoardTiles[FollowerParams.X][FollowerParams.Y].Type = TTHead

    // Update its step to match ours.
    FollowerParams.StepX = Params.StepX
    FollowerParams.StepY = Params.StepY

    // Redraw our erstwhile follower.
    DrawTile(FollowerParams.X, FollowerParams.Y)
}


//
// Reverse the direction of the entire centipede attached to this tile.
//
func ReverseCentipede(int16 ParamIdx) {
    // Follow the centipede's followers, swapping leader and follower as we go.
    while let Params = BoardParams[ParamIdx] where (Params.Follower > 0) {
        // Swap leader and follower.
        let Temp = Params.Follower
        Params.Follower = Params.Leader
        Params.Leader = Temp
        // Continue to the next follower.
        ParamIdx = Temp
    }

    // This tile will be the new head.  Set its follower to its old leader.
    let Params = BoardParams[ParamIdx]
    Params.Follower = Params.Leader
    BoardTiles[Params.X][Params.Y].Type = TTHead
}


//
// Check if a segment exists at (X, Y) with no leader.
//
func LeaderlessSegmentAt(int16 X, int16 Y) -> Bool {
    if BoardTiles[X][Y].Type != TTSegment) {
        return false
    }

    let ParamIdx = ParamIdxForXY(X, Y)
    return (BoardParams[ParamIdx].Leader < 0)
}


//
// If there are any leaderless segments adjacent to (X, Y), attach them as a new follower.
//
func ReattachOrphan(ParamRecord* Params, int16 X, int16 Y, int16 StepX, int16 StepY) {
    if LeaderlessSegmentAt(X - StepX, Y - StepY) {
        OriginalParams.Follower = ParamIdxForXY(X - StepX, Y - StepY)
    } else if LeaderlessSegmentAt(X - StepY, Y - StepX) {
        OriginalParams.Follower = ParamIdxForXY(X - StepY, Y - StepX)
    } else if LeaderlessSegmentAt(X + StepY, Y + StepX) {
        OriginalParams.Follower = ParamIdxForXY(X + StepY, Y + StepX)
    }
}


//
// Move the head at these params, then move all of its followers along with it.
// Attach any adjacent leaderless segments to the tail.
//
func MoveAndReattachCentipede(int16 ParamIdx) {
    // Move this tile.
    var Params = BoardParams[ParamIdx]
    MoveTileWithIdx(ParamIdx, Params.X + Params.StepX, Params.Y + Params.StepY)

    // Move all followers.
    do {
        // Follow the step backwards to the previous position.
        let LeaderParams = BoardParams[ParamIdx]
        var CurrentX = LeaderParams.X - LeaderParams.StepX
        var CurrentY = LeaderParams.Y - LeaderParams.StepY

        // If this tile doesn't have a follower, check for an adjacent segment with no leader.
        if LeaderParams.Follower < 0 {
            ReattachOrphan(LeaderParams, CurrentX, LeaderParams.StepX,
                           CurrentY, LeaderParams.StepY)
        }
        
        // If we have a follower now, update its parameters and move it.
        if LeaderParams.Follower > 0 {
            let FollowerParams = BoardParams[OrigParams.Follower]
            FollowerParams.Leader = ParamIdx
            FollowerParams.Param1 = LeaderParams.Param1  // Intelligence
            FollowerParams.Param2 = LeaderParams.Param2  // Deviance
            FollowerParams.StepX = CurrentX - FollowerParams.X
            FollowerParams.StepY = CurrentY - FollowerParams.Y
            // Move the follower to its new position.
            MoveTileWithIdx(LeaderParams.Follower, CurrentX, CurrentY)
        }

        // Continue on to the next follower.
        ParamIdx = LeaderParams.Follower
    } while(ParamIdx != -1)
}
```


{% include links.html %}
