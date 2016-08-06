; ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦ S U B R O U T I N E ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦

; Attributes: bp-based frame

TickHead        proc far                ; DATA XREF: InitTileTypes:loc_15407↓o

LeaderParamPtr  = dword ptr -12h
ParamPtr        = dword ptr -0Eh
Temp            = word ptr -0Ah
CurrentY        = word ptr -8
CurrentX        = word ptr -6
OrigStepY       = word ptr -4
OrigStepX       = word ptr -2
ParamIdx        = word ptr  6

                push    bp
                mov     bp, sp
                mov     ax, 12h
                call    CheckStack
                sub     sp, 12h
;
; Determine which direction to move next
;
                mov     ax, [bp+ParamIdx]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                add     di, offset BoardParams
                mov     word ptr [bp+ParamPtr], di
                mov     word ptr [bp+ParamPtr+2], ds
                les     di, [bp+ParamPtr]
; Check if aligned on the X axis
                mov     al, es:[di+ParamRecord.X]
                cmp     al, BoardParams.X
                jnz     short HeadCheckY
;
; Intelligence check to seek player
;
                mov     ax, 0Ah
                push    ax
                call    Random
                mov     dx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Param1] ; Intelligence
                xor     ah, ah
                cmp     ax, dx
                jbe     short HeadCheckY
;
; Set step towards player on Y axis
;
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                mov     dx, ax
                mov     al, BoardParams.Y
                xor     ah, ah
                sub     ax, dx
                push    ax
                call    StepForDelta    ; Return step (-1, 0, or 1) for (negative, 0, or positive) delta
                les     di, [bp+ParamPtr]
                mov     es:[di+ParamRecord.StepY], ax
                les     di, [bp+ParamPtr]
                xor     ax, ax
                mov     es:[di+ParamRecord.StepX], ax
                jmp     HeadTryStep
; ---------------------------------------------------------------------------
; Check if aligned on the Y axis

HeadCheckY:                             ; CODE XREF: TickHead+2C↑j
                                        ; TickHead+44↑j
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                cmp     al, BoardParams.Y
                jnz     short DevianceCheck
;
; Intelligence check to seek player
;
                mov     ax, 0Ah
                push    ax
                call    Random
                mov     dx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Param1] ; Intelligence
                xor     ah, ah
                cmp     ax, dx
                jbe     short DevianceCheck
;
; Set step towards player on X axis
;
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                mov     dx, ax
                mov     al, BoardParams.X
                xor     ah, ah
                sub     ax, dx
                push    ax
                call    StepForDelta    ; Return step (-1, 0, or 1) for (negative, 0, or positive) delta
                les     di, [bp+ParamPtr]
                mov     es:[di+ParamRecord.StepX], ax
                les     di, [bp+ParamPtr]
                xor     ax, ax
                mov     es:[di+ParamRecord.StepY], ax
                jmp     short HeadTryStep
; ---------------------------------------------------------------------------
;
; Set step randomly if not moving, or passed a deviance check
;

DevianceCheck:                          ; CODE XREF: TickHead+7C↑j
                                        ; TickHead+94↑j
                mov     ax, 0Ah
                push    ax
                call    Random
                mov     cx, 2
                shl     ax, cl          ; 4 * Random(10)
                mov     dx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Param2] ; Deviance
                xor     ah, ah
                cmp     ax, dx
                ja      short HeadStepRandom
                les     di, [bp+ParamPtr]
                cmp     es:[di+ParamRecord.StepX], 0
                jnz     short HeadTryStep
                les     di, [bp+ParamPtr]
                cmp     es:[di+ParamRecord.StepY], 0
                jnz     short HeadTryStep

HeadStepRandom:                         ; CODE XREF: TickHead+DA↑j
                les     di, [bp+ParamPtr]
                add     di, ParamRecord.StepX
                push    es
                push    di
                les     di, [bp+ParamPtr]
                add     di, ParamRecord.StepY
                push    es
                push    di
                call    RandomStep
;
; Check if blocked at the destination tile
;

HeadTryStep:                            ; CODE XREF: TickHead+6E↑j
                                        ; TickHead+BD↑j ...
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                add     ax, es:[di+ParamRecord.StepY]
                shl     ax, 1
                mov     cx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                add     ax, es:[di+ParamRecord.StepX]
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
                jz      short HeadBlocked
                jmp     DoneSettingStep
; ---------------------------------------------------------------------------

HeadBlocked:                            ; CODE XREF: TickHead+145↑j
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                add     ax, es:[di+ParamRecord.StepY]
                shl     ax, 1
                mov     cx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                add     ax, es:[di+ParamRecord.StepX]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                cmp     byte ptr BoardTopLeft.Type[di], TTPlayer
                jnz     short NotBlockedByPlayer
                jmp     DoneSettingStep
; ---------------------------------------------------------------------------
; Blocked, but not by the player

;
; Randomly turn clockwise or counter-clockwise, i.e.
; Set StepX to randomly StepY or -StepY
; Set StepY to randomly StepX or -StepX
;

NotBlockedByPlayer:                     ; CODE XREF: TickHead+17B↑j
                les     di, [bp+ParamPtr]
                mov     ax, es:[di+ParamRecord.StepX]
                mov     [bp+OrigStepX], ax
                les     di, [bp+ParamPtr]
                mov     ax, es:[di+ParamRecord.StepY]
                mov     [bp+OrigStepY], ax
                mov     ax, 2
                push    ax
                call    Random
                shl     ax, 1
                dec     ax
                xor     dx, dx
                mov     cx, ax          ; -1 or 1
                mov     bx, dx
                les     di, [bp+ParamPtr]
                mov     ax, es:[di+ParamRecord.StepY]
                cwd
                call    Multiply32      ; 32 bit multiply
                                        ; ax:dx *= cx:bx
                mov     [bp+Temp], ax   ; StepY * (-1 or 1)
                mov     ax, 2
                push    ax
                call    Random
                shl     ax, 1
                dec     ax
                xor     dx, dx
                mov     cx, ax          ; -1 or 1
                mov     bx, dx
                les     di, [bp+ParamPtr]
                mov     ax, es:[di+ParamRecord.StepX]
                cwd
                call    Multiply32      ; 32 bit multiply
                                        ; ax:dx *= cx:bx
                les     di, [bp+ParamPtr]
                mov     es:[di+ParamRecord.StepY], ax ; StepX * (-1 or 1)
                mov     ax, [bp+Temp]
                les     di, [bp+ParamPtr]
                mov     es:[di+ParamRecord.StepX], ax
;
; Check if tile in new direction is blocked
;
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                add     ax, es:[di+ParamRecord.StepY]
                shl     ax, 1
                mov     cx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                add     ax, es:[di+ParamRecord.StepX]
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
                jz      short NewDirBlocked
                jmp     DoneSettingStep
; ---------------------------------------------------------------------------
;
; Check if the new direction is blocked by the player
;

NewDirBlocked:                          ; CODE XREF: TickHead+224↑j
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                add     ax, es:[di+ParamRecord.StepY]
                shl     ax, 1
                mov     cx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                add     ax, es:[di+ParamRecord.StepX]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                cmp     byte ptr BoardTopLeft.Type[di], TTPlayer
                jnz     short NotPlayerAgain
                jmp     DoneSettingStep
; ---------------------------------------------------------------------------
;
; Try turning in the opposite direction (negate current step)
;

; Negate StepX

NotPlayerAgain:                         ; CODE XREF: TickHead+25A↑j
                les     di, [bp+ParamPtr]
                mov     ax, es:[di+ParamRecord.StepX]
                neg     ax
                les     di, [bp+ParamPtr]
                mov     es:[di+ParamRecord.StepX], ax
; Negate StepY
                les     di, [bp+ParamPtr]
                mov     ax, es:[di+ParamRecord.StepY]
                neg     ax
                les     di, [bp+ParamPtr]
                mov     es:[di+ParamRecord.StepY], ax
; Check if this third direction is blocked
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                add     ax, es:[di+ParamRecord.StepY]
                shl     ax, 1
                mov     cx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                add     ax, es:[di+ParamRecord.StepX]
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
                jz      short ThirdDirBlocked
                jmp     DoneSettingStep
; ---------------------------------------------------------------------------
;
; Check if the third direction is blocked by the player
;

ThirdDirBlocked:                        ; CODE XREF: TickHead+2BD↑j
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                add     ax, es:[di+ParamRecord.StepY]
                shl     ax, 1
                mov     cx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                add     ax, es:[di+ParamRecord.StepX]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                cmp     byte ptr BoardTopLeft.Type[di], TTPlayer
                jnz     short StillNotPlayer
                jmp     DoneSettingStep
; ---------------------------------------------------------------------------
;
; Check if the opposite direction of the original one is blocked
;

StillNotPlayer:                         ; CODE XREF: TickHead+2F3↑j
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                sub     ax, [bp+OrigStepY]
                shl     ax, 1
                mov     cx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                sub     ax, [bp+OrigStepX]
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
                jnz     short NotBlockedInOppositeDirection
;
; Check if the fourth direction is blocked by the player
;
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                sub     ax, [bp+OrigStepY]
                shl     ax, 1
                mov     cx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                sub     ax, [bp+OrigStepX]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                cmp     byte ptr BoardTopLeft.Type[di], TTPlayer
                jnz     short HeadCantMove
; Set the step to the unblocked direction (opposite of the original)

NotBlockedInOppositeDirection:          ; CODE XREF: TickHead+32E↑j
                mov     ax, [bp+OrigStepX]
                neg     ax
                les     di, [bp+ParamPtr]
                mov     es:[di+ParamRecord.StepX], ax
                mov     ax, [bp+OrigStepY]
                neg     ax
                les     di, [bp+ParamPtr]
                mov     es:[di+ParamRecord.StepY], ax
                jmp     short DoneSettingStep
; ---------------------------------------------------------------------------
; Zero out the step

HeadCantMove:                           ; CODE XREF: TickHead+359↑j
                les     di, [bp+ParamPtr]
                xor     ax, ax
                mov     es:[di+ParamRecord.StepX], ax
                les     di, [bp+ParamPtr]
                xor     ax, ax
                mov     es:[di+ParamRecord.StepY], ax
; Check if moving horizontally

DoneSettingStep:                        ; CODE XREF: TickHead+147↑j
                                        ; TickHead+17D↑j ...
                les     di, [bp+ParamPtr]
                cmp     es:[di+ParamRecord.StepX], 0
                jz      short HeadNotMovingX
                jmp     CheckForPlayer
; ---------------------------------------------------------------------------
; Check if moving vertically

HeadNotMovingX:                         ; CODE XREF: TickHead+38F↑j
                les     di, [bp+ParamPtr]
                cmp     es:[di+ParamRecord.StepY], 0
                jz      short HeadNotMoving
                jmp     CheckForPlayer
; ---------------------------------------------------------------------------
;
; Can't move: become a segment with no leader and reverse the direction
; of this centipede.
;

HeadNotMoving:                          ; CODE XREF: TickHead+39C↑j
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
                mov     byte ptr BoardTopLeft.Type[di], TTSegment
                les     di, [bp+ParamPtr]
                mov     es:[di+ParamRecord.Leader], -1
;
; If we have no follower, become a detatched head
;

StoppedCheckFollower:                   ; CODE XREF: TickHead+422↓j
                mov     ax, [bp+ParamIdx]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                cmp     BoardParams.Follower[di], 0
                jle     short BecomeLeader
;
; Swap leader and follower
;
                mov     ax, [bp+ParamIdx]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                mov     ax, BoardParams.Follower[di]
                mov     [bp+Temp], ax   ; Temp = Follower
                mov     ax, [bp+ParamIdx]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                mov     cx, BoardParams.Leader[di]
                mov     ax, [bp+ParamIdx]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                mov     BoardParams.Follower[di], cx ; Follower = Leader
                mov     cx, [bp+Temp]
                mov     ax, [bp+ParamIdx]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                mov     BoardParams.Leader[di], cx ; Leader = Temp
                mov     ax, [bp+Temp]
;
; Change param index to the original follower.
;
;    _                   _
;  _( )                 ( )_
; (_, |      __ __      | ,_)
;    \'\    /  ^  \    /'/
;     '\'\,/\      \,/'/'
;       '\| []   [] |/'
;         (_  /^\  _)
;           \  ~  /
;           /HHHHH\
;         /'/{^^^}\'\
;     _,/'/'  ^^^  '\'\,_
;    (_, |           | ,_)
;      (_)           (_)
;
; WE ARE NOW OPERATING ON THE FOLLOWER!
;
                mov     [bp+ParamIdx], ax
                jmp     short StoppedCheckFollower
; ---------------------------------------------------------------------------
;
; The leader of this tile now becomes the follower
;

BecomeLeader:                           ; CODE XREF: TickHead+3DC↑j
                mov     ax, [bp+ParamIdx]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                mov     cx, BoardParams.Leader[di]
                mov     ax, [bp+ParamIdx]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                mov     BoardParams.Follower[di], cx
;
; Set this tile's type to Head
;
                mov     ax, [bp+ParamIdx]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                mov     al, BoardParams.Y[di]
                xor     ah, ah
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+ParamIdx]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                mov     al, byte ptr BoardParams.X[di]
                xor     ah, ah
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                mov     byte ptr BoardTopLeft.Type[di], TTHead
                jmp     TickHeadDone
; ---------------------------------------------------------------------------
;
; Check if the destination tile is blocked by the player
;

CheckForPlayer:                         ; CODE XREF: TickHead+391↑j
                                        ; TickHead+39E↑j
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                add     ax, es:[di+ParamRecord.StepY]
                shl     ax, 1
                mov     cx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                add     ax, es:[di+ParamRecord.StepX]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                cmp     byte ptr BoardTopLeft.Type[di], TTPlayer
                jz      short PrepareForAttack
                jmp     ReadyToMove
; ---------------------------------------------------------------------------
;
; Before attacking, free our follower if we have one
;

PrepareForAttack:                       ; CODE XREF: TickHead+4A6↑j
                les     di, [bp+ParamPtr]
                cmp     es:[di+ParamRecord.Follower], -1
                jnz     short HasFollower
                jmp     AttackPlayer
; ---------------------------------------------------------------------------
;
; Set the follower's tile to a Head
;

HasFollower:                            ; CODE XREF: TickHead+4B3↑j
                les     di, [bp+ParamPtr]
                mov     ax, es:[di+ParamRecord.Follower]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                mov     al, BoardParams.Y[di]
                xor     ah, ah
                shl     ax, 1
                mov     cx, ax
                les     di, [bp+ParamPtr]
                mov     ax, es:[di+ParamRecord.Follower]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                mov     al, byte ptr BoardParams.X[di]
                xor     ah, ah
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                mov     byte ptr BoardTopLeft.Type[di], TTHead
;
; Set our erstwhile follower's step to our own
;
                les     di, [bp+ParamPtr]
                mov     cx, es:[di+ParamRecord.StepX]
                les     di, [bp+ParamPtr]
                mov     ax, es:[di+ParamRecord.Follower]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                mov     BoardParams.StepX[di], cx
                les     di, [bp+ParamPtr]
                mov     cx, es:[di+ParamRecord.StepY]
                les     di, [bp+ParamPtr]
                mov     ax, es:[di+ParamRecord.Follower]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                mov     BoardParams.StepY[di], cx
;
; Redraw our erstwhile follower
;
                les     di, [bp+ParamPtr]
                mov     ax, es:[di+ParamRecord.Follower]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                mov     al, byte ptr BoardParams.X[di]
                xor     ah, ah
                push    ax
                les     di, [bp+ParamPtr]
                mov     ax, es:[di+ParamRecord.Follower]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                mov     al, BoardParams.Y[di]
                xor     ah, ah
                push    ax
                call    DrawTile

AttackPlayer:                           ; CODE XREF: TickHead+4B5↑j
                push    [bp+ParamIdx]
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                add     ax, es:[di+ParamRecord.StepX]
                push    ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                add     ax, es:[di+ParamRecord.StepY]
                push    ax
                call    DieAttackingTile
                jmp     TickHeadDone
; ---------------------------------------------------------------------------
;
; Move this tile
;

ReadyToMove:                            ; CODE XREF: TickHead+4A8↑j
                push    [bp+ParamIdx]
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                add     ax, es:[di+ParamRecord.StepX]
                push    ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                add     ax, es:[di+ParamRecord.StepY]
                push    ax
                call    MoveTile
;
; Record the original position of this tile and its step
; This is redundant as all 4 variables are overwritten in the next section
;
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                sub     ax, es:[di+ParamRecord.StepX]
                mov     [bp+CurrentX], ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                sub     ax, es:[di+ParamRecord.StepY]
                mov     [bp+CurrentY], ax
                les     di, [bp+ParamPtr]
                mov     ax, es:[di+ParamRecord.StepX]
                mov     [bp+OrigStepX], ax
                les     di, [bp+ParamPtr]
                mov     ax, es:[di+ParamRecord.StepY]
                mov     [bp+OrigStepY], ax
;
; Follow the step backwards to the previous position
;

FollowStepBackwards:                    ; CODE XREF: TickHead+825↓j
                mov     ax, [bp+ParamIdx]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                add     di, offset BoardParams
                mov     word ptr [bp+LeaderParamPtr], di
                mov     word ptr [bp+LeaderParamPtr+2], ds
                les     di, [bp+LeaderParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                les     di, [bp+LeaderParamPtr]
                sub     ax, es:[di+ParamRecord.StepX]
                mov     [bp+CurrentX], ax
                les     di, [bp+LeaderParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                les     di, [bp+LeaderParamPtr]
                sub     ax, es:[di+ParamRecord.StepY]
                mov     [bp+CurrentY], ax
                les     di, [bp+LeaderParamPtr]
                mov     ax, es:[di+ParamRecord.StepX]
                mov     [bp+OrigStepX], ax
                les     di, [bp+LeaderParamPtr]
                mov     ax, es:[di+ParamRecord.StepY]
                mov     [bp+OrigStepY], ax
                les     di, [bp+LeaderParamPtr]
;
; Check if this tile has a follower
;
                cmp     es:[di+ParamRecord.Follower], 0
                jl      short NoFollower
                jmp     MovingCheckFollower
; ---------------------------------------------------------------------------
;
; Check if there's a segment at the previous tile
;

NoFollower:                             ; CODE XREF: TickHead+636↑j
                mov     ax, [bp+CurrentY]
                sub     ax, [bp+OrigStepY]
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+CurrentX]
                sub     ax, [bp+OrigStepX]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                cmp     byte ptr BoardTopLeft.Type[di], TTSegment
                jnz     short NoSegmentAtPrevTile
; Check if the segment has a leader
                mov     ax, [bp+CurrentX]
                sub     ax, [bp+OrigStepX]
                push    ax
                mov     ax, [bp+CurrentY]
                sub     ax, [bp+OrigStepY]
                push    ax
                call    ParamIdxForXY   ; Index for param at (X, Y) or -1 if not found
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                cmp     BoardParams.Leader[di], 0
                jge     short NoSegmentAtPrevTile
;
; Set our follower to the segment at the previous tile
;
                mov     ax, [bp+CurrentX]
                sub     ax, [bp+OrigStepX]
                push    ax
                mov     ax, [bp+CurrentY]
                sub     ax, [bp+OrigStepY]
                push    ax
                call    ParamIdxForXY   ; Index for param at (X, Y) or -1 if not found
                les     di, [bp+LeaderParamPtr]
                mov     es:[di+ParamRecord.Follower], ax
                jmp     MovingCheckFollower
; ---------------------------------------------------------------------------
;
; Check for a leaderless segment at (X-StepY, Y-StepX)
;

NoSegmentAtPrevTile:                    ; CODE XREF: TickHead+659↑j
                                        ; TickHead+67A↑j
                mov     ax, [bp+CurrentY]
                sub     ax, [bp+OrigStepX]
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+CurrentX]
                sub     ax, [bp+OrigStepY]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                cmp     byte ptr BoardTopLeft.Type[di], TTSegment
                jnz     short NoSegAt2ndPosition
; Check if the segment has a leader
                mov     ax, [bp+CurrentX]
                sub     ax, [bp+OrigStepY]
                push    ax
                mov     ax, [bp+CurrentY]
                sub     ax, [bp+OrigStepX]
                push    ax
                call    ParamIdxForXY   ; Index for param at (X, Y) or -1 if not found
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                cmp     BoardParams.Leader[di], 0
                jge     short NoSegAt2ndPosition
;
; Set our follower to the segment at the 2nd try position
;
                mov     ax, [bp+CurrentX]
                sub     ax, [bp+OrigStepY]
                push    ax
                mov     ax, [bp+CurrentY]
                sub     ax, [bp+OrigStepX]
                push    ax
                call    ParamIdxForXY   ; Index for param at (X, Y) or -1 if not found
                les     di, [bp+LeaderParamPtr]
                mov     es:[di+ParamRecord.Follower], ax
                jmp     short MovingCheckFollower
; ---------------------------------------------------------------------------
;
; Check for a leaderless segment at (X+StepY, Y+StepX)
;

NoSegAt2ndPosition:                     ; CODE XREF: TickHead+6B7↑j
                                        ; TickHead+6D8↑j
                mov     ax, [bp+CurrentY]
                add     ax, [bp+OrigStepX]
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+CurrentX]
                add     ax, [bp+OrigStepY]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                cmp     byte ptr BoardTopLeft.Type[di], TTSegment
                jnz     short MovingCheckFollower
; Check if the segment has a leader
                mov     ax, [bp+CurrentX]
                add     ax, [bp+OrigStepY]
                push    ax
                mov     ax, [bp+CurrentY]
                add     ax, [bp+OrigStepX]
                push    ax
                call    ParamIdxForXY   ; Index for param at (X, Y) or -1 if not found
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                cmp     BoardParams.Leader[di], 0
                jge     short MovingCheckFollower
;
; Set our follower to the segment at the 3rd try position
;
                mov     ax, [bp+CurrentX]
                add     ax, [bp+OrigStepY]
                push    ax
                mov     ax, [bp+CurrentY]
                add     ax, [bp+OrigStepX]
                push    ax
                call    ParamIdxForXY   ; Index for param at (X, Y) or -1 if not found
                les     di, [bp+LeaderParamPtr]
                mov     es:[di+ParamRecord.Follower], ax

MovingCheckFollower:                    ; CODE XREF: TickHead+638↑j
                                        ; TickHead+696↑j ...
                les     di, [bp+LeaderParamPtr]
                cmp     es:[di+ParamRecord.Follower], 0
                jg      short MovingHasFollower
                jmp     DoneMoveFollower
; ---------------------------------------------------------------------------
; Set the original's follower to us

MovingHasFollower:                      ; CODE XREF: TickHead+759↑j
                mov     cx, [bp+ParamIdx]
                les     di, [bp+LeaderParamPtr]
                mov     ax, es:[di+ParamRecord.Follower]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                mov     BoardParams.Leader[di], cx
; Set our follower's intelligence to the original head's intelligence
                les     di, [bp+LeaderParamPtr]
                mov     cl, es:[di+ParamRecord.Param1]
                les     di, [bp+LeaderParamPtr]
                mov     ax, es:[di+ParamRecord.Follower]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                mov     BoardParams.Param1[di], cl
; Set our follower's deviance to the original head's deviance
                les     di, [bp+LeaderParamPtr]
                mov     cl, es:[di+ParamRecord.Param2]
                les     di, [bp+LeaderParamPtr]
                mov     ax, es:[di+ParamRecord.Follower]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                mov     BoardParams.Param2[di], cl
; Set the follower's StepX to CurrentX - Follower.X
                les     di, [bp+LeaderParamPtr]
                mov     ax, es:[di+ParamRecord.Follower]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                mov     al, byte ptr BoardParams.X[di]
                xor     ah, ah
                mov     dx, ax
                mov     ax, [bp+CurrentX]
                sub     ax, dx
                mov     cx, ax
                les     di, [bp+LeaderParamPtr]
                mov     ax, es:[di+ParamRecord.Follower]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                mov     BoardParams.StepX[di], cx
; Set the follower's StepY to CurrentY - Follower.Y
                les     di, [bp+LeaderParamPtr]
                mov     ax, es:[di+ParamRecord.Follower]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                mov     al, BoardParams.Y[di]
                xor     ah, ah
                mov     dx, ax
                mov     ax, [bp+CurrentY]
                sub     ax, dx
                mov     cx, ax
                les     di, [bp+LeaderParamPtr]
                mov     ax, es:[di+ParamRecord.Follower]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                mov     BoardParams.StepY[di], cx
; Move the follower tile to the new position
                les     di, [bp+LeaderParamPtr]
                push    es:[di+ParamRecord.Follower]
                push    [bp+CurrentX]
                push    [bp+CurrentY]
                call    MoveTile
;
; Change param index to the follower.
;
;    _                   _
;  _( )                 ( )_
; (_, |      __ __      | ,_)
;    \'\    /  ^  \    /'/
;     '\'\,/\      \,/'/'
;       '\| []   [] |/'
;         (_  /^\  _)
;           \  ~  /
;           /HHHHH\
;         /'/{^^^}\'\
;     _,/'/'  ^^^  '\'\,_
;    (_, |           | ,_)
;      (_)           (_)
;
; WE ARE NOW OPERATING ON THE FOLLOWER!
;

DoneMoveFollower:                       ; CODE XREF: TickHead+75B↑j
                les     di, [bp+LeaderParamPtr]
                mov     ax, es:[di+ParamRecord.Follower]
                mov     [bp+ParamIdx], ax
; If there are no more followers, we're done
                cmp     [bp+ParamIdx], -1
                jz      short TickHeadDone
                jmp     FollowStepBackwards
; ---------------------------------------------------------------------------

TickHeadDone:                           ; CODE XREF: TickHead+472↑j
                                        ; TickHead+57C↑j ...
                mov     sp, bp
                pop     bp
                retf    2
TickHead        endp
