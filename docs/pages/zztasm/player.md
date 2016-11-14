---
title: Player Tick Function
keywords: Tick Functions, Player
sidebar: zztasm_sidebar
permalink: player.html
---


## High-level overview

The player object handles energizer animation, shooting, moving, some keyboard input, and some
other board related functions.

The player tick function is implemented as a single procedure, but its behavior is so complex
that I have broken it into multiple functions for this analysis.


## Full pseudocode

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


func AnimateEnergized(ParamRecord* Params) {
    // Toggle the player character between 01 and 02
    if TileTypes[TTPlayer].Character == 2 {
        TileTypes[TTPlayer].Character = 1
    } else {
        TileTypes[TTPlayer].Character = 2
    }

    // Cycle through background colors
    if TickNumber % 2 == 0 {
        // Set the player's tile color to white on the next BG color
        let Color = ((TickNumber % 7) << 4) + 0x0f
        BoardTiles[Params.X][Params.Y].Color = Color
    } else {
        // Set the player's tile color to white on black
        BoardTiles[Params.X][Params.Y].Color = 0x0f
    }

    // Redraw the energized player
    DrawTile(Params.X, Params.Y)
}


func RestorePlayerAppearance(ParamRecord* Params) {
    // If the color or character is incorrect, reset them.
    if (BoardTiles[Params.X][Params.Y] != 0x1f) || (TileTypes[TTPlayer].Character != 2) {
        BoardTiles[Params.X][Params.Y] = 0x1f
        TileTypes[TTPlayer].Character = 2
        DrawTile(Params.X, Params.Y)
    }
}


func EndGame() {
    // Stop the player moving and shooting.
    PlayerXStep = 0
    PlayerYStep = 0
    ShiftArrowPressed = 0

    // If there isn't already a messenger at (0, 0), say the game over message.
    if ParamIdxForXY(0, 0) != -1 {
        SayMessage(32000, " Game over  -  Press ESCAPE")
    }
    // Fast-forward the game by setting the time between cycles to 0
    TimePerCycle = 0
    GameIsOver = 1
}


func TryShooting(ParamRecord* Params) {
    // If the player is pressing shift-arrow, update the shoot direction
    if (ShiftArrowPressed != 0) && ((PlayerXStep != 0) || (PlayerYStep != 0)) {
        PlayerShootXStep = PlayerXStep
        PlayerShootYStep = PlayerShootYStep
    }

    // Must have a direction to shoot
    if (PlayerShootXStep == 0) && (PlayerShootYStep == 0) {
        return
    }

    // Check if shooting is allowed on this board
    if MaxShots == 0 {
        if ShouldSayCantShootHere != 0 {
            SayMessage(StdMessageDuration, "Can't shoot in this place!")
        }
        ShouldSayCantShootHere = 0
        return
    }

    // Check if the player has any ammo
    if CurrentAmmo == 0 {
        if ShouldSayOutOfAmmo != 0 {
            SayMessage(StdMessageDuration, "You don't have any ammo!")
        }
        ShouldSayOutOfAmmo = 0
        return
    }

    // Count the player bullets on the board to see if you're under the board's Max Shots
    var NumPlayerBullets = 0
    let ParamCount = BoardParamCount
    if ParamCount > 0 {
        for CountIdx in range(ParamCount) {
            let CountParams = BoardParams[CountIdx]
            if BoardTiles[CountParams.X][CountParams.Y] == TTBullet {
                // Check it's a player bullet
                if CountParams.Param1 == SOPlayer {
                    NumPlayerBullets++
                }
            }
        }
    }
    if MaxShots <= NumPlayerBullets {
        return
    }

    // Player bullets are under the max count.  Fire!
    let DidShoot = Shoot(TTBullet, Params.X, Params.Y, PlayerShootXStep, PlayerShootYStep,
                         SOPlayer)
    if DidShoot {
        CurrentAmmo--
        UpdateSideBar()
        PlaySoundPriority(2, sndShoot)
        // Cancel any player movement
        PlayerXStep = 0
        PlayerYStep = 0
    }
}


func TryMoving(ParamRecord* Params) {
    // Copy the current direction for shooting later
    PlayerShootXStep = PlayerXStep
    PlayerShootYStep = PlayerYStep
    // Calculate the position of the destination
    let X = Params.X + PlayerXStep
    let Y = Params.Y + PlayerYStep
    // Look up the touch function for the destination's tile type
    let Touch = TileTypes[BoardTiles[X][Y].Type].TouchFunction
    // Call the destination's touch function
    let ParamIdx = 0
    Touch(X, Y, ParamIdx, &PlayerXStep, &PlayerYStep)

    // Check if the player is still moving after calling the touch function
    if (PlayerXStep == 0) && (PlayerYStep == 0) {
        return
    }

    // Play 110Hz footstep sound
    if SoundBusy == 0 {
        Sound(110)
    }

    // Check if the destination tile is passable
    if TileTypes[BoardTiles[X][Y].Type].Passable == 0 {
        // Stop the footstep click
        if (SoundEnabled != 0) && (SoundBusy == 0) {
            SoundOff()
        }
        return
    }

    // Stop the footstep click
    if (SoundEnabled != 0) && (SoundBusy == 0) {
        SoundOff()
    }

    // Move the player tile to its destination
    MoveTileWithIdx(0, X, Y)
}


func HandleOtherKeyboardInput(ParamRecord* Params) {
    if LastKeyCode == 'T' {
        // T - Light a torch
        TryLightTorch()
    } else if (LastKeyCode == '\x1b' || LastKeyCode == 'Q') {
        // ESC or Q - Prompt to quit
        PromptQuit()
    } else if LastKeyCode == 'S' {
        // S - Save game
        PromptSaveWorld("Save game:", SaveFilename, ".SAV")
    } else if LastKeyCode == 'P' {
        // P - Pause
        if CurrentHealth > 0 {  // can't pause if the player's dead
            IsPaused = 1
        }
    } else if LastKeyCode == 'B' {
        // B - Toggle sound
        SoundEnabled = (SoundEnabled == 0) ? 1 : 0
        StopPlayingSound()
        UpdateSideBar()
        LastKeyCode = ' '
    } else if LastKeyCode == 'H' {
        // H - Show help
        ShowHelpFile("GAME.HLP", "Playing ZZT")
    } else if LastKeyCode == 'F' {
        // F - Show order form
        ShowHelpFile("ORDER.HLP", "Order form")
    } else if LastKeyCode == '?' {
        // ? - Debug prompt
        ShowDebugPrompt()
        LastKeyCode = 0
    }
}


func TryLightTorch(ParamRecord* Params) {
    if TorchCyclesLeft > 0 {
        return  // A torch is already lit, nothing to do
    }

    // If there are no torches left, say a warning if we haven't already
    if CurrentTorches <= 0 {
        if ShouldSayOutOfTorches != 0 {
            SayMessage(StdMessageDuration, "You don't have any torches!")
            ShouldSayOutOfTorches = 0
        }
        return
    }

    // If the board is dark, say a warning if we haven't already
    if BoardIsDark == 0 {
        if ShouldSayDontNeedTorch != 0 {
            SayMessage(StdMessageDuration, "Don't need torch - room is not dark!")
            ShouldSayDontNeedTorch = 0
        }
        return
    }

    // Light a torch
    CurrentTorches--
    TorchCyclesLeft = 200
    // Redraw all the tiles in a circle around the player (torch/bomb share a radius)
    Explode(Params.X, Params.Y, EMRedrawOnly)
    UpdateStatusBar()
}


func UpdateTorch(ParamRecord* Params) {
    TorchCyclesLeft--
    // If the torch just died, redraw the tiles around the player and play a sound
    if TorchCyclesLeft == 0 {
        Explode(Params.X, Params.Y, EMRedrawOnly)
        PlaySoundPriority(3, sndTorchDied)
    }
    // Update the sidebar every 40 torch cycles
    if TorchCyclesLeft % 40 == 0 {
        UpdateSideBar()
    }
}


func UpdateEnergizer(ParamRecord* Params) {
    EnergizerCycles--
    // When there are 10 cycles left, play the energizer done sound
    if EnergizerCycles == 10 {
        PlaySoundPriority(9, sndEnergizerDone)
        return
    }

    // If the energizer just finished, fix the player color
    if EnergizerCycles <= 0 {
        BoardTiles[Params.X][Params.Y].Color = TileTypes[TTPlayer].Color
        DrawTile(Params.X, Params.Y)
    }
}


func UpdateBoardTime() {
    if CurrentHealth <= 0 {
        return
    }

    // Every 100 centiseconds (1 second) increment the time elapsed
    if !CheckTimeElapsed(&BoardTimerCentis, 100) {
        return
    }
    TimeElapsed++

    if TimeLimit - 10 == TimeElapsed {
        // When there's 10 seconds left, show the running out of time message and sound
        SayMessage(StdMessageDuration, "Running out of time!")
        PlaySoundPriority(3, sndRunningOutOfTime)
    } else if TimeElapsed > TimeLimit {
        // When time is up, attack the player
        Attack(0)  // param index 0 is the player
    }
    UpdateStatusBar()
}
```

{% include links.html %}
