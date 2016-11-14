; ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦ S U B R O U T I N E ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦

; Attributes: bp-based frame

TickRuffian     proc far                ; DATA XREF: InitTileTypes+79B↓o

TargetTilePtr   = dword ptr -8
ParamPtr        = dword ptr -4
ParamIdx        = word ptr  6

                push    bp
                mov     bp, sp
                mov     ax, 8
                call    CheckStack
                sub     sp, 8
                mov     ax, [bp+ParamIdx]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                add     di, offset BoardParams
                mov     word ptr [bp+ParamPtr], di
                mov     word ptr [bp+ParamPtr+2], ds
                les     di, [bp+ParamPtr]
; Check if we're moving on the X axis
                cmp     es:[di+ParamRecord.StepX], 0
                jz      short NotMovingX
                jmp     CheckAlignedY
; ---------------------------------------------------------------------------
; Check if we're moving on the Y axis

NotMovingX:                             ; CODE XREF: TickRuffian+2A↑j
                les     di, [bp+ParamPtr]
                cmp     es:[di+ParamRecord.StepY], 0
                jnz     short CheckAlignedY
;
; Resting time check
;
                mov     ax, 11h
                push    ax
                call    Random
                mov     dx, ax          ; random in [0,11)
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Param2] ; resting time
                xor     ah, ah
                add     ax, 8
                cmp     ax, dx
                ja      short DontMove  ; if (8 + resting time) > Random(11)
;
; Intelligence check to step towards the player or randomly
;
                mov     ax, 9
                push    ax
                call    Random
                mov     dx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Param1] ; intelligence
                xor     ah, ah
                cmp     ax, dx
                jb      short FailedIntCheck
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                push    ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                push    ax
                les     di, [bp+ParamPtr]
                add     di, ParamRecord.StepX
                push    es
                push    di
                les     di, [bp+ParamPtr]
                add     di, ParamRecord.StepY
                push    es
                push    di
                call    SeekStep
                jmp     short DontMove
; ---------------------------------------------------------------------------

FailedIntCheck:                         ; CODE XREF: TickRuffian+6A↑j
                les     di, [bp+ParamPtr]
                add     di, ParamRecord.StepX
                push    es
                push    di
                les     di, [bp+ParamPtr]
                add     di, ParamRecord.StepY
                push    es
                push    di
                call    RandomStep

DontMove:                               ; CODE XREF: TickRuffian+52↑j
                                        ; TickRuffian+96↑j
                jmp     DoneTickRuffian
; ---------------------------------------------------------------------------
;
; We're currently moving.
;
; If we're aligned with the player, do an intelligence check to seek them
;

CheckAlignedY:                          ; CODE XREF: TickRuffian+2C↑j
                                        ; TickRuffian+37↑j
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                cmp     al, BoardParams.Y
                jz      short AlignedWPlayer
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                cmp     al, BoardParams.X
                jnz     short PrepareToMove

AlignedWPlayer:                         ; CODE XREF: TickRuffian+BD↑j
                mov     ax, 9
                push    ax
                call    Random
                mov     dx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Param1] ; intelligence
                xor     ah, ah
                cmp     ax, dx
                jb      short PrepareToMove
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                push    ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                push    ax
                les     di, [bp+ParamPtr]
                add     di, ParamRecord.StepX
                push    es
                push    di
                les     di, [bp+ParamPtr]
                add     di, ParamRecord.StepY
                push    es
                push    di
                call    SeekStep
;
; Check if we're about to hit the player
;

PrepareToMove:                          ; CODE XREF: TickRuffian+C9↑j
                                        ; TickRuffian+E1↑j
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
                add     di, offset BoardTopLeft
                mov     word ptr [bp+TargetTilePtr], di
                mov     word ptr [bp+TargetTilePtr+2], ds
                les     di, [bp+TargetTilePtr]
                cmp     es:[di+Tile.Type], TTPlayer
                jnz     short CheckBlocked
;
; Die attacking the player
;
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
                jmp     DoneTickRuffian
; ---------------------------------------------------------------------------

CheckBlocked:                           ; CODE XREF: TickRuffian+14A↑j
                les     di, [bp+TargetTilePtr]
                mov     al, es:[di+Tile.Type]
                xor     ah, ah
                mov     dx, size TileType
                mul     dx
                mov     di, ax
                cmp     TileTypes.Passable[di], 0
                jz      short IsBlocked
; Move in the current direction
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
                call    MoveTileWithIdx
;
; Resting time check to stop moving
;
                mov     ax, 11h
                push    ax
                call    Random
                mov     dx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Param2] ; resting time
                xor     ah, ah
                add     ax, 8
                cmp     ax, dx
                ja      short DoneMoving ; stop if (8 + resting time) <= Random(11)
                les     di, [bp+ParamPtr]
                xor     ax, ax
                mov     es:[di+ParamRecord.StepX], ax
                les     di, [bp+ParamPtr]
                xor     ax, ax
                mov     es:[di+ParamRecord.StepY], ax

DoneMoving:                             ; CODE XREF: TickRuffian+1D0↑j
                jmp     short DoneTickRuffian
; ---------------------------------------------------------------------------
;
; Stop moving when blocked
;

IsBlocked:                              ; CODE XREF: TickRuffian+18C↑j
                les     di, [bp+ParamPtr]
                xor     ax, ax
                mov     es:[di+ParamRecord.StepX], ax
                les     di, [bp+ParamPtr]
                xor     ax, ax
                mov     es:[di+ParamRecord.StepY], ax

DoneTickRuffian:                        ; CODE XREF: TickRuffian:DontMove↑j
                                        ; TickRuffian+175↑j ...
                mov     sp, bp
                pop     bp
                retf    2
TickRuffian     endp
