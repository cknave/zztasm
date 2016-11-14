; ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦ S U B R O U T I N E ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦

; Attributes: bp-based frame

TickPlayer      proc far                ; DATA XREF: InitTileTypes+20B↓o

ParamCount      = word ptr -10h
ParamPtr        = dword ptr -0Eh
NumPlayerBullets= word ptr -0Ah
CountParamIdx   = word ptr -8
ParamIdx        = word ptr  6

                push    bp
                mov     bp, sp
                mov     ax, 10h
                call    CheckStack
                sub     sp, 10h
                mov     ax, [bp+ParamIdx]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                add     di, offset BoardParams
                mov     word ptr [bp+ParamPtr], di
                mov     word ptr [bp+ParamPtr+2], ds
;
; Check if the player is energized
;
                cmp     EnergizerCycles, 0
                jg      short PlayerEnergized
                jmp     PlayerNotEnergized
; ---------------------------------------------------------------------------
; Toggle the player character between 01 and 02

PlayerEnergized:                        ; CODE XREF: TickPlayer+27↑j
                cmp     TileTypes.Character+(size TileType*TTPlayer), 2
                jnz     short SetPlayerChar02
                mov     TileTypes.Character+(size TileType*TTPlayer), 1
                jmp     short UpdatePlayerColor
; ---------------------------------------------------------------------------

SetPlayerChar02:                        ; CODE XREF: TickPlayer+31↑j
                mov     TileTypes.Character+(size TileType*TTPlayer), 2
;
; Cycle through background colors
;

UpdatePlayerColor:                      ; CODE XREF: TickPlayer+38↑j
                mov     ax, TickNumber  ; increments every cycle
                cwd
                mov     cx, 2
                idiv    cx
                xchg    ax, dx
                or      ax, ax
                jz      short SetNextBGColor
; Set the player tile's color to white on black
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                shl     ax, 1
                mov     cx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                mov     BoardTopLeft.Color[di], 0Fh
                jmp     short DrawNRGPlayer
; ---------------------------------------------------------------------------
; Set the player tile's color to white on the next BG color

SetNextBGColor:                         ; CODE XREF: TickPlayer+4B↑j
                mov     ax, TickNumber  ; increments every cycle
                cwd
                mov     cx, 7
                idiv    cx
                xchg    ax, dx
                inc     ax
                mov     cx, 4
                shl     ax, cl
                add     ax, 0Fh
                mov     bl, al
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                shl     ax, 1
                mov     cx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                mov     BoardTopLeft.Color[di], bl
; Draw the energized player

DrawNRGPlayer:                          ; CODE XREF: TickPlayer+70↑j
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                push    ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                push    ax
                call    DrawTile
                jmp     short CheckPlayerDead
; ---------------------------------------------------------------------------

PlayerNotEnergized:                     ; CODE XREF: TickPlayer+29↑j
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                shl     ax, 1
                mov     cx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
; Check if the color is correct
                cmp     BoardTopLeft.Color[di], 1Fh
                jnz     short ResetPlayerLook
; Check if the character is correct
                cmp     TileTypes.Character+(size TileType*TTPlayer), 2
                jz      short CheckPlayerDead
; Reset the player color back to 1F and char back to 2

ResetPlayerLook:                        ; CODE XREF: TickPlayer+E6↑j
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                shl     ax, 1
                mov     cx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                mov     BoardTopLeft.Color[di], 1Fh
                mov     TileTypes.Character+(size TileType*TTPlayer), 2
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                push    ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                push    ax
                call    DrawTile
;
; If the player has no health, end the game
;

CheckPlayerDead:                        ; CODE XREF: TickPlayer+C1↑j
                                        ; TickPlayer+ED↑j
                cmp     CurrentHealth, 0
                jg      short CheckPlayerMoving
; Stop the player moving and shooting
                xor     ax, ax
                mov     PlayerXStep, ax
                xor     ax, ax
                mov     PlayerYStep, ax
                mov     ShiftArrowPressed, 0
; If there's no messenger at (0, 0), say the game over message
                xor     ax, ax
                push    ax
                xor     ax, ax
                push    ax
                call    ParamIdxForXY   ; Index for param at (X, Y) or -1 if not found
                cmp     ax, -1
                jnz     short SetGameOver
                mov     ax, 32000
                push    ax
                mov     di, offset aGameOverPressE ; " Game over  -  Press ESCAPE"
                push    cs
                push    di
                call    SayMessage
; Fast-forward the game by setting the time between cycles to 0

SetGameOver:                            ; CODE XREF: TickPlayer+153↑j
                xor     ax, ax
                mov     TimePerCycle, ax
                mov     GameIsOver, 1

CheckPlayerMoving:                      ; CODE XREF: TickPlayer+134↑j
                cmp     ShiftArrowPressed, 0
                jnz     short PrepareShootDirection
                cmp     LastKeyCode, 20h ; ' '
                jz      short PrepareShootDirection
                jmp     CheckPlayerStep
; ---------------------------------------------------------------------------
;
; If the player is pressing shift-arrow, update the shoot direction
;

PrepareShootDirection:                  ; CODE XREF: TickPlayer+172↑j
                                        ; TickPlayer+179↑j
                cmp     ShiftArrowPressed, 0
                jz      short CheckHasShootDirection
                cmp     PlayerXStep, 0
                jnz     short UpdateShootDirection
                cmp     PlayerYStep, 0
                jz      short CheckHasShootDirection

UpdateShootDirection:                   ; CODE XREF: TickPlayer+18A↑j
                mov     ax, PlayerXStep
                mov     PlayerShootXStep, ax
                mov     ax, PlayerYStep
                mov     PlayerShootYStep, ax
;
; Must have a shoot direction to shoot
;

CheckHasShootDirection:                 ; CODE XREF: TickPlayer+183↑j
                                        ; TickPlayer+191↑j
                cmp     PlayerShootXStep, 0
                jnz     short HasShootDirection
                cmp     PlayerShootYStep, 0
                jnz     short HasShootDirection
                jmp     GotoCheckLastKeyCode
; ---------------------------------------------------------------------------
; Check if shooting is allowed on this board

HasShootDirection:                      ; CODE XREF: TickPlayer+1A4↑j
                                        ; TickPlayer+1AB↑j
                cmp     MaxShots, 0
                jnz     short CheckEnoughAmmo
                cmp     ShouldSayCantShootHere, 0
                jz      short DoneSayingCantShootHere
                mov     ax, StdMessageDuration
                push    ax
                mov     di, offset aCanTShootInThi ; "Can't shoot in this place!"
                push    cs
                push    di
                call    SayMessage

DoneSayingCantShootHere:                ; CODE XREF: TickPlayer+1BC↑j
                mov     ShouldSayCantShootHere, 0
                jmp     GotoCheckLastKeyCode
; ---------------------------------------------------------------------------
; Check if the player has any ammo

CheckEnoughAmmo:                        ; CODE XREF: TickPlayer+1B5↑j
                cmp     CurrentAmmo, 0
                jnz     short CountPlayerBullets
                cmp     ShouldSayOutOfAmmo, 0
                jz      short DoneSayingOutOfAmmo
                mov     ax, StdMessageDuration
                push    ax
                mov     di, offset aYouDonTHaveAny ; "You don't have any ammo!"
                push    cs
                push    di
                call    SayMessage

DoneSayingOutOfAmmo:                    ; CODE XREF: TickPlayer+1E0↑j
                mov     ShouldSayOutOfAmmo, 0
                jmp     GotoCheckLastKeyCode
; ---------------------------------------------------------------------------
;
; Count the player bullets on the board to see if they're under the board's Max Shots
;

CountPlayerBullets:                     ; CODE XREF: TickPlayer+1D9↑j
                xor     ax, ax
                mov     [bp+NumPlayerBullets], ax
                mov     ax, BoardParamCount
                mov     [bp+ParamCount], ax
; Skip the loop if there's no param records on the board
                xor     ax, ax
                cmp     ax, [bp+ParamCount]
                jg      short CheckMaxBullets
                mov     [bp+CountParamIdx], ax
                jmp     short CheckIsBullet
; ---------------------------------------------------------------------------

NextBulletLoop:                         ; CODE XREF: TickPlayer+264↓j
                inc     [bp+CountParamIdx]
;
; Get a total of the bullets owned by the player on the board
;

CheckIsBullet:                          ; CODE XREF: TickPlayer+20D↑j
                mov     ax, [bp+CountParamIdx]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                mov     al, BoardParams.Y[di]
                xor     ah, ah
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+CountParamIdx]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                mov     al, byte ptr BoardParams.X[di]
                xor     ah, ah
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
; Check for a bullet
                cmp     byte ptr BoardTopLeft.Type[di], TTBullet
                jnz     short CheckNextBulletLoop
; Check it's a player bullet
                mov     ax, [bp+CountParamIdx]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                cmp     BoardParams.Param1[di], SOPlayer
                jnz     short CheckNextBulletLoop
; It's a player bullet! Increment the count.
                mov     ax, [bp+NumPlayerBullets]
                inc     ax
                mov     [bp+NumPlayerBullets], ax

CheckNextBulletLoop:                    ; CODE XREF: TickPlayer+244↑j
                                        ; TickPlayer+255↑j
                mov     ax, [bp+CountParamIdx]
                cmp     ax, [bp+ParamCount]
                jnz     short NextBulletLoop

CheckMaxBullets:                        ; CODE XREF: TickPlayer+208↑j
                mov     al, MaxShots
                xor     ah, ah
                cmp     ax, [bp+NumPlayerBullets]
                jle     short GotoCheckLastKeyCode
;
; Player bullets are under the max count.  Fire!
;
                mov     al, TTBullet
                push    ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                push    ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                push    ax
                push    PlayerShootXStep
                push    PlayerShootYStep
                xor     ax, ax          ; ax = SOPlayer
                push    ax
                call    Shoot           ; Shoot a ShootType from (FromX,FromY) at (StepX,StepY)
                                        ; Owner 0=player, 1=enemy
; If shooting was successful, update the player
                or      al, al
                jz      short GotoCheckLastKeyCode
; Decrement the available ammo
                mov     ax, CurrentAmmo
                dec     ax
                mov     CurrentAmmo, ax
; Update the sidebar to show the new ammo value
                call    UpdateSideBar
; Play the shooting sound
                mov     ax, 2
                push    ax
                mov     di, offset sndShoot
                push    cs
                push    di
                call    PlaySoundPriority ; Not 100% sure on this yet but...
                                        ; Priority: higher priority overwrites the buffer,
                                        ;           -1 is maybe always overwrite?
                                        ; SoundPtr: binary representation in a pascal string
; Cancel any player movement
                xor     ax, ax
                mov     PlayerXStep, ax
                xor     ax, ax
                mov     PlayerYStep, ax

GotoCheckLastKeyCode:                   ; CODE XREF: TickPlayer+1AD↑j
                                        ; TickPlayer+1D1↑j ...
                jmp     CheckLastKeyCode
; ---------------------------------------------------------------------------
;
; If the player has an X or Y step, send touch to their destination
;

CheckPlayerStep:                        ; CODE XREF: TickPlayer+17B↑j
                cmp     PlayerXStep, 0
                jnz     short SendTouch
                cmp     PlayerYStep, 0
                jnz     short SendTouch
                jmp     CheckLastKeyCode
; ---------------------------------------------------------------------------
; Copy the current direction for shooting later

SendTouch:                              ; CODE XREF: TickPlayer+2C6↑j
                                        ; TickPlayer+2CD↑j
                mov     ax, PlayerXStep
                mov     PlayerShootXStep, ax
                mov     ax, PlayerYStep
                mov     PlayerShootYStep, ax
                les     di, [bp+ParamPtr]
; Calculate the position of the destination
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                add     ax, PlayerXStep
                push    ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                add     ax, PlayerYStep
                push    ax
                xor     ax, ax          ; param index = 0
                push    ax
                mov     di, offset PlayerXStep
                push    ds
                push    di
                mov     di, offset PlayerYStep
                push    ds
                push    di
; Look up the touch function for the destination's tile type
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                add     ax, PlayerYStep
                shl     ax, 1
                mov     cx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                add     ax, PlayerXStep
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                mov     al, byte ptr BoardTopLeft.Type[di]
                xor     ah, ah
                mov     dx, size TileType
                mul     dx
                mov     di, ax
                call    TileTypes.TouchFunction[di]
;
; Check if the player is still moving after calling the touch function
;
                cmp     PlayerXStep, 0
                jnz     short PlayerStillMoving
                cmp     PlayerYStep, 0
                jnz     short PlayerStillMoving
                jmp     CheckLastKeyCode
; ---------------------------------------------------------------------------

PlayerStillMoving:                      ; CODE XREF: TickPlayer+342↑j
                                        ; TickPlayer+349↑j
                cmp     SoundEnabled, 0
                jz      short CheckDestPassable
                cmp     SoundBusy, 0    ; affects player footstep sound
                jnz     short CheckDestPassable
; Play 110 Hz footstep sound
                mov     ax, 110
                push    ax
                call    Sound
;
; Check if the destination tile is passable
;

CheckDestPassable:                      ; CODE XREF: TickPlayer+353↑j
                                        ; TickPlayer+35A↑j
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                add     ax, PlayerYStep
                shl     ax, 1
                mov     cx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                add     ax, PlayerXStep
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                mov     al, byte ptr BoardTopLeft.Type[di]
                xor     ah, ah
                mov     dx, size TileType
                mul     dx
                mov     di, ax
                cmp     TileTypes.Passable[di], 0
                jz      short DestNotPassable
                cmp     SoundEnabled, 0
                jz      short MovePlayer
                cmp     SoundBusy, 0    ; affects player footstep sound
                jnz     short MovePlayer
                call    SoundOff
;
; Move the player tile to its destination
;

MovePlayer:                             ; CODE XREF: TickPlayer+3A4↑j
                                        ; TickPlayer+3AB↑j
                xor     ax, ax
                push    ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                add     ax, PlayerXStep
                push    ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                add     ax, PlayerYStep
                push    ax
                call    MoveTileWithIdx
                jmp     short CheckLastKeyCode
; ---------------------------------------------------------------------------

DestNotPassable:                        ; CODE XREF: TickPlayer+39D↑j
                cmp     SoundEnabled, 0
                jz      short CheckLastKeyCode
                cmp     SoundBusy, 0    ; affects player footstep sound
                jnz     short CheckLastKeyCode
                call    SoundOff
;
; Handle player keyboard input
;


CheckLastKeyCode:                       ; CODE XREF: TickPlayer:GotoCheckLastKeyCode↑j
                                        ; TickPlayer+2CF↑j ...
                mov     al, LastKeyCode
                push    ax
                call    ToUpper         ; Translate a-z to A-Z
                cmp     al, 54h ; 'T'
                jnz     short TestESC
;
; T - light a torch
;

; If a torch is already lit, nothing to do
                cmp     TorchCyclesLeft, 0
                jg      short DoneTorch
; If there are no torches left, say a warning if we haven't already
                cmp     CurrentTorches, 0
                jle     short CheckSayOutOfTorches
; If the board isn't dark, say a warning if we haven't already
                cmp     BoardIsDark, 0
                jz      short BoardNotDark
                mov     ax, CurrentTorches
                dec     ax
                mov     CurrentTorches, ax
                mov     TorchCyclesLeft, 200
                les     di, [bp+ParamPtr]
                mov     al, es:[di]
                xor     ah, ah
                push    ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+1]
                xor     ah, ah
                push    ax
                xor     ax, ax
                push    ax              ; EMRedrawOnly
                push    cs
                call    near ptr Explode
                call    UpdateSideBar
                jmp     short GotoDoneTorch
; ---------------------------------------------------------------------------

BoardNotDark:                           ; CODE XREF: TickPlayer+40A↑j
                cmp     ShouldSayDontNeedTorch, 0
                jz      short GotoDoneTorch
                mov     ax, StdMessageDuration
                push    ax
                mov     di, offset aDonTNeedTorchR ; "Don't need torch - room is not dark!"
                push    cs
                push    di
                call    SayMessage
                mov     ShouldSayDontNeedTorch, 0

GotoDoneTorch:                          ; CODE XREF: TickPlayer+438↑j
                                        ; TickPlayer+43F↑j
                jmp     short DoneTorch
; ---------------------------------------------------------------------------

CheckSayOutOfTorches:                   ; CODE XREF: TickPlayer+403↑j
                cmp     ShouldSayOutOfTorches, 0
                jz      short DoneTorch
                mov     ax, StdMessageDuration
                push    ax
                mov     di, offset aYouDonTHaveA_0 ; "You don't have any torches!"
                push    cs
                push    di
                call    SayMessage
                mov     ShouldSayOutOfTorches, 0

DoneTorch:                              ; CODE XREF: TickPlayer+3FC↑j
                                        ; TickPlayer:GotoDoneTorch↑j ...
                jmp     CheckTorchLit
; ---------------------------------------------------------------------------
;
; ESC or Q - prompt to quit
;

TestESC:                                ; CODE XREF: TickPlayer+3F5↑j
                cmp     al, 1Bh
                jz      short EscOrQPressed
                cmp     al, 51h ; 'Q'
                jnz     short TestS

EscOrQPressed:                          ; CODE XREF: TickPlayer+475↑j
                push    cs
                call    near ptr PromptQuit ; Prompts and sets ShouldQuit
                jmp     CheckTorchLit
; ---------------------------------------------------------------------------
;
; S - Save game
;

TestS:                                  ; CODE XREF: TickPlayer+479↑j
                cmp     al, 53h ; 'S'
                jnz     short TestP
                mov     di, offset aSaveGame ; "Save game:"
                push    cs
                push    di
                mov     di, offset SaveFilename
                push    ds
                push    di
                mov     di, offset a_sav ; ".SAV"
                push    cs
                push    di
                call    PromptSaveWorld
                jmp     short CheckTorchLit
; ---------------------------------------------------------------------------
;
; P - Pause
;

TestP:                                  ; CODE XREF: TickPlayer+484↑j
                cmp     al, 50h ; 'P'
                jnz     short TestB
; Can't pause if the player's dead
                cmp     CurrentHealth, 0
                jle     short DonePause
                mov     IsPaused, 1

DonePause:                              ; CODE XREF: TickPlayer+4A5↑j
                jmp     short CheckTorchLit
; ---------------------------------------------------------------------------
;
; B - toggle sound
;

TestB:                                  ; CODE XREF: TickPlayer+49E↑j
                cmp     al, 42h ; 'B'
                jnz     short TestH
                cmp     SoundEnabled, 0
                jz      short EnableSound
                mov     al, 0
                jmp     short UpdateSoundState
; ---------------------------------------------------------------------------

EnableSound:                            ; CODE XREF: TickPlayer+4B7↑j
                mov     al, 1

UpdateSoundState:                       ; CODE XREF: TickPlayer+4BB↑j
                mov     SoundEnabled, al
                call    StopPlayingSound
                call    UpdateSideBar
                mov     LastKeyCode, 20h ; ' '
                jmp     short CheckTorchLit
; ---------------------------------------------------------------------------
;
; H - show help
;

TestH:                                  ; CODE XREF: TickPlayer+4B0↑j
                cmp     al, 48h ; 'H'
                jnz     short TestF
                mov     di, offset aGame_hlp ; "GAME.HLP"
                push    cs
                push    di
                mov     di, offset aPlayingZzt ; "Playing ZZT"
                push    cs
                push    di
                call    ShowHelpFile
                jmp     short CheckTorchLit
; ---------------------------------------------------------------------------
;
; F - show order form
;

TestF:                                  ; CODE XREF: TickPlayer+4D5↑j
                cmp     al, 46h ; 'F'
                jnz     short TestQuestionMark
                mov     di, offset aOrder_hlp ; "ORDER.HLP"
                push    cs
                push    di
                mov     di, offset aOrderForm ; "Order form"
                push    cs
                push    di
                call    ShowHelpFile
                jmp     short CheckTorchLit
; ---------------------------------------------------------------------------
;
; ? - debug prompt
;

TestQuestionMark:                       ; CODE XREF: TickPlayer+4EA↑j
                cmp     al, 3Fh ; '?'
                jnz     short CheckTorchLit
                call    ShowDebugPrompt
                mov     LastKeyCode, 0
; If a torch is lit, decrement its cycles left

CheckTorchLit:                          ; CODE XREF: TickPlayer:DoneTorch↑j
                                        ; TickPlayer+47F↑j ...
                cmp     TorchCyclesLeft, 0
                jle     short UpdateEnergizer
                mov     ax, TorchCyclesLeft
                dec     ax
                mov     TorchCyclesLeft, ax
;
; If the torch just died, redraw the tiles around the player and play a sound
;
                cmp     TorchCyclesLeft, 0
                jg      short UpdateTorchSidebar
; Redraw tiles around the player
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                push    ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                push    ax
                xor     ax, ax
                push    ax              ; 0 = EMRedrawOnly
                push    cs
                call    near ptr Explode
; Play the torch died sound
                mov     ax, 3
                push    ax
                mov     di, offset sndTorchDied
                push    cs
                push    di
                call    PlaySoundPriority ; Not 100% sure on this yet but...
                                        ; Priority: higher priority overwrites the buffer,
                                        ;           -1 is maybe always overwrite?
                                        ; SoundPtr: binary representation in a pascal string
; Update the sidebar every 40 torch cycles

UpdateTorchSidebar:                     ; CODE XREF: TickPlayer+51E↑j
                mov     ax, TorchCyclesLeft
                cwd
                mov     cx, 40
                idiv    cx
                xchg    ax, dx
                or      ax, ax
                jnz     short UpdateEnergizer
                call    UpdateSideBar
;
; If the player is energized, update the energizer cycles
;

UpdateEnergizer:                        ; CODE XREF: TickPlayer+510↑j
                                        ; TickPlayer+554↑j
                cmp     EnergizerCycles, 0
                jle     short CheckTimeLimit
; Decrement the cycles left
                mov     ax, EnergizerCycles
                dec     ax
; When there are 10 cycles left, play the energizer done sound
                mov     EnergizerCycles, ax
                cmp     EnergizerCycles, 10
                jnz     short CheckEnergizerDone
                mov     ax, 9
                push    ax
                mov     di, offset sndEnergizerDone
                push    cs
                push    di
                call    PlaySoundPriority ; Not 100% sure on this yet but...
                                        ; Priority: higher priority overwrites the buffer,
                                        ;           -1 is maybe always overwrite?
                                        ; SoundPtr: binary representation in a pascal string
                jmp     short CheckTimeLimit
; ---------------------------------------------------------------------------
;
; If the energizer just finished, fix the player color
;

CheckEnergizerDone:                     ; CODE XREF: TickPlayer+56E↑j
                cmp     EnergizerCycles, 0
                jg      short CheckTimeLimit
; Update the player tile color
                mov     bl, TileTypes.Color+(size TileType*TTPlayer)
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                shl     ax, 1
                mov     cx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                mov     BoardTopLeft.Color[di], bl
; Redraw the player tile
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                push    ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                push    ax
                call    DrawTile
;
; If the board has a time limit, update the time elapsed
;

CheckTimeLimit:                         ; CODE XREF: TickPlayer+560↑j
                                        ; TickPlayer+57E↑j ...
                cmp     TimeLimit, 0
                jle     short DoneTickPlayer
                cmp     CurrentHealth, 0
                jle     short DoneTickPlayer
; Every 100 centiseconds (1 second) increment the time elapsed
                mov     di, offset BoardTimerCentis
                push    ds
                push    di
                mov     ax, 100
                push    ax
                call    CheckTimeElapsed ; Returns 1 if at least Duration centiseconds have
                                        ; elapsed since the value at TimePtr; also updates
                                        ; TimePtr with the current centiseconds if true
                or      al, al
                jz      short DoneTickPlayer
; Increment the time elapsed
                mov     ax, TimeElapsed
                inc     ax
                mov     TimeElapsed, ax
; When there's 10 seconds left, show the running out of time message and sound
                mov     ax, TimeLimit
                sub     ax, 10
                cmp     ax, TimeElapsed
                jnz     short ChcekTimeUp
; Show the running out of time message
                mov     ax, StdMessageDuration
                push    ax
                mov     di, offset aRunningOutOfTi ; "Running out of time!"
                push    cs
                push    di
                call    SayMessage
; Play the running out of time sound
                mov     ax, 3
                push    ax
                mov     di, offset sndRunningOutOfTime
                push    cs
                push    di
                call    PlaySoundPriority ; Not 100% sure on this yet but...
                                        ; Priority: higher priority overwrites the buffer,
                                        ;           -1 is maybe always overwrite?
                                        ; SoundPtr: binary representation in a pascal string
                jmp     short DoneTime
; ---------------------------------------------------------------------------

ChcekTimeUp:                            ; CODE XREF: TickPlayer+5F6↑j
                mov     ax, TimeElapsed
                cmp     ax, TimeLimit
                jle     short DoneTime
                xor     ax, ax
                push    ax
                call    Attack

DoneTime:                               ; CODE XREF: TickPlayer+614↑j
                                        ; TickPlayer+61D↑j
                call    UpdateSideBar

DoneTickPlayer:                         ; CODE XREF: TickPlayer+5CA↑j
                                        ; TickPlayer+5D1↑j ...
                mov     sp, bp
                pop     bp
                retf    2
TickPlayer      endp
