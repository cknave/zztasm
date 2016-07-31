; ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦ S U B R O U T I N E ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦

; Attributes: bp-based frame

TickBear        proc far                ; DATA XREF: InitTileTypes+819↓o

BearTile        = dword ptr -0Ch
ParamPtr        = dword ptr -8
StepY           = word ptr -4
StepX           = word ptr -2
ParamIdx        = word ptr  6

                push    bp
                mov     bp, sp
                mov     ax, 0Ch
                call    CheckStack
                sub     sp, 0Ch
; Get the address of the bear's parameter record
                mov     ax, [bp+ParamIdx]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                add     di, offset BoardParams
                mov     word ptr [bp+ParamPtr], di
                mov     word ptr [bp+ParamPtr+2], ds
;
; Check if aligned on the X axis
;
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                cmp     al, BoardParams.X ; Player X
                jz      short BearCheckX
;
; Check if within sensitivity range on Y axis
;
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                push    ax
                mov     al, BoardParams.Y ; Player Y
                xor     ah, ah
                push    ax
                call    Distance        ; Calculate the distance between two ints
                mov     cx, ax          ; Y-axis distance to the player
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Param1] ; Sensitivity
                xor     ah, ah
                mov     dx, ax
                mov     ax, 8
                sub     ax, dx          ; (8-sensitivity)
                cmp     ax, cx
                jl      short BearCheckX
; Move in the X direction
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                mov     dx, ax
                mov     al, BoardParams.X
                xor     ah, ah
                sub     ax, dx
                push    ax
                call    StepForDelta    ; Return step (-1, 0, or 1) for (negative, 0, or positive) delta
                mov     [bp+StepX], ax
                xor     ax, ax
                mov     [bp+StepY], ax
                jmp     short BearCheckMove
; ---------------------------------------------------------------------------
;
; Check if within sensitivity range on X axis
;

BearCheckX:                             ; CODE XREF: TickBear+2C↑j
                                        ; TickBear+57↑j
                les     di, [bp+ParamPtr]
                mov     al, es:[di]
                xor     ah, ah
                push    ax
                mov     al, BoardParams.X
                xor     ah, ah
                push    ax
                call    Distance        ; Calculate the distance between two ints
                mov     cx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Param1]
                xor     ah, ah
                mov     dx, ax
                mov     ax, 8
                sub     ax, dx
                cmp     ax, cx
                jl      short BearDontMove
; Move in the Y direction
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                mov     dx, ax
                mov     al, BoardParams.Y
                xor     ah, ah
                sub     ax, dx
                push    ax
                call    StepForDelta    ; Return step (-1, 0, or 1) for (negative, 0, or positive) delta
                mov     [bp+StepY], ax
                xor     ax, ax
                mov     [bp+StepX], ax
                jmp     short BearCheckMove
; ---------------------------------------------------------------------------
; Not within sensitivity range; don't move

BearDontMove:                           ; CODE XREF: TickBear+A2↑j
                xor     ax, ax
                mov     [bp+StepX], ax
                xor     ax, ax
                mov     [bp+StepY], ax
;
; Check if we can move towards (StepX, StepY)
;

; Get the tile at (X+StepX, Y+StepY)

BearCheckMove:                          ; CODE XREF: TickBear+78↑j
                                        ; TickBear+C4↑j
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                add     ax, [bp+StepY]
                shl     ax, 1
                mov     cx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                add     ax, [bp+StepX]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                add     di, offset BoardTopLeft
                mov     word ptr [bp+BearTile], di
                mov     word ptr [bp+BearTile+2], ds
                les     di, [bp+BearTile]
                mov     al, es:[di+Tile.Type]
                xor     ah, ah
; Check if that tile is passable
                mov     dx, size TileType
                mul     dx
                mov     di, ax
                cmp     TileTypes.Passable[di], 0
                jz      short BearBlocked
;
; Move to the destination tile
;
                push    [bp+ParamIdx]
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                add     ax, [bp+StepX]
                push    ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                add     ax, [bp+StepY]
                push    ax
                call    MoveTile
                jmp     short BearDone
; ---------------------------------------------------------------------------
; Check if we're blocked by the player

BearBlocked:                            ; CODE XREF: TickBear+112↑j
                les     di, [bp+BearTile]
                cmp     es:[di+Tile.Type], TTPlayer
                jz      short BearAttack
; If we're blocked by a breakable wall, we can also attack that
                les     di, [bp+BearTile]
                cmp     es:[di+Tile.Type], TTBreakable
                jnz     short BearDone

BearAttack:                             ; CODE XREF: TickBear+13E↑j
                push    [bp+ParamIdx]
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                add     ax, [bp+StepX]
                push    ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                add     ax, [bp+StepY]
                push    ax
                call    DieAttackingTile

BearDone:                               ; CODE XREF: TickBear+135↑j
                                        ; TickBear+147↑j
                mov     sp, bp
                pop     bp
                retf    2
TickBear        endp
