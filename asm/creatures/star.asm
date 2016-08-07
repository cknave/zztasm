; ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦ S U B R O U T I N E ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦

; Attributes: bp-based frame

TickStar        proc far                ; DATA XREF: InitTileTypes+484↓o

DestTilePtr     = dword ptr -8
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
;
; Decrement ticks left (Param2) and check if still alive
;
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Param2]
                xor     ah, ah
                dec     ax
                les     di, [bp+ParamPtr]
                mov     es:[di+ParamRecord.Param2], al
                les     di, [bp+ParamPtr]
                cmp     es:[di+ParamRecord.Param2], 0
                ja      short StarStillAlive
;
; Out of ticks, time to die
;
                push    [bp+ParamIdx]
                call    RemoveParamIdx
                jmp     DoneTickStar
; ---------------------------------------------------------------------------
;
; Move every 2 ticks; otherwise just redraw
;

StarStillAlive:                         ; CODE XREF: TickStar+3B↑j
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Param2]
                xor     ah, ah
                cwd
                mov     cx, 2
                idiv    cx
                xchg    ax, dx
                or      ax, ax
                jz      short StarTryMove
                jmp     RedrawStar
; ---------------------------------------------------------------------------
;
; Try to step towards the player
;

StarTryMove:                            ; CODE XREF: TickStar+5A↑j
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
; Check the destination tile
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
                add     di, offset BoardTopLeft
                mov     word ptr [bp+DestTilePtr], di
                mov     word ptr [bp+DestTilePtr+2], ds
                les     di, [bp+DestTilePtr]
; Attack the player or a breakable wall
                cmp     es:[di+Tile.Type], TTPlayer
                jz      short StarAttack
                les     di, [bp+DestTilePtr]
                cmp     es:[di+Tile.Type], TTBreakable
                jnz     short StarCheckPassable

StarAttack:                             ; CODE XREF: TickStar+C6↑j
                push    [bp+ParamIdx]
                les     di, [bp+ParamPtr]
                mov     al, es:[di]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                add     ax, es:[di+2]
                push    ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+1]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                add     ax, es:[di+4]
                push    ax
                call    DieAttackingTile
                jmp     StarDoneAction
; ---------------------------------------------------------------------------

StarCheckPassable:                      ; CODE XREF: TickStar+CF↑j
                les     di, [bp+DestTilePtr]
                mov     al, es:[di+Tile.Type]
                xor     ah, ah
                mov     dx, size TileType
                mul     dx
                mov     di, ax
                cmp     TileTypes.Passable[di], 0
                jnz     short StarDestPassable
;
; Try pushing the destination tile out of the way
;
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
                les     di, [bp+ParamPtr]
                push    es:[di+ParamRecord.StepX]
                les     di, [bp+ParamPtr]
                push    es:[di+ParamRecord.StepY]
                push    cs
                call    near ptr TryPush ; Try pushing the tile at X,Y in direction StepX,StepY
;
; If pushing worked, check if we can move into this tile now
;

StarDestPassable:                       ; CODE XREF: TickStar+111↑j
                les     di, [bp+DestTilePtr]
                mov     al, es:[di+Tile.Type]
                xor     ah, ah
                mov     dx, size TileType
                mul     dx
                mov     di, ax
                cmp     TileTypes.Passable[di], 0
                jnz     short DoStarMove
; Also allow stars to move over water
                les     di, [bp+DestTilePtr]
                cmp     es:[di+Tile.Type], TTWater
                jnz     short StarDoneAction

DoStarMove:                             ; CODE XREF: TickStar+15A↑j
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

StarDoneAction:                         ; CODE XREF: TickStar+FA↑j
                                        ; TickStar+163↑j
                jmp     short DoneTickStar
; ---------------------------------------------------------------------------

RedrawStar:                             ; CODE XREF: TickStar+5C↑j
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                push    ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                push    ax
                call    DrawTile

DoneTickStar:                           ; CODE XREF: TickStar+45↑j
                                        ; TickStar:StarDoneAction↑j
                mov     sp, bp
                pop     bp
                retf    2
TickStar        endp
