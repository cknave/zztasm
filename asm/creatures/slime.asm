; ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦ S U B R O U T I N E ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦

; Attributes: bp-based frame

TickSlime       proc far                ; DATA XREF: InitTileTypes+892o

ParamPtr        = dword ptr -0Eh
Y               = word ptr -0Ah
X               = word ptr -8
NumPassableTiles= word ptr -6
Color           = word ptr -4
OffsetIdx       = word ptr -2
ParamIdx        = word ptr  6

                push    bp
                mov     bp, sp
                mov     ax, 0Eh
                call    CheckStack
                sub     sp, 0Eh
                mov     ax, [bp+ParamIdx]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                add     di, offset BoardParams
                mov     word ptr [bp+ParamPtr], di
                mov     word ptr [bp+ParamPtr+2], ds
                les     di, [bp+ParamPtr]
;
; Increment tick count until it's time to move
;
                mov     al, es:[di+ParamRecord.Param1] ; ticks to move
                les     di, [bp+ParamPtr]
                cmp     al, es:[di+ParamRecord.Param2] ; movement speed
                jnb     short PrepareToLoop
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Param1] ; ticks to move
                xor     ah, ah
                inc     ax
                les     di, [bp+ParamPtr]
                mov     es:[di+ParamRecord.Param1], al
                jmp     EndTickSlime
; ---------------------------------------------------------------------------
; Get slime color

PrepareToLoop:                          ; CODE XREF: TickSlime+30j
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
                mov     al, BoardTopLeft.Color[di]
                xor     ah, ah
                mov     [bp+Color], ax
; Reset ticks to move
                les     di, [bp+ParamPtr]
                mov     es:[di+ParamRecord.Param1], 0 ; ticks to move
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                mov     [bp+X], ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                mov     [bp+Y], ax
;
; Loop over the directions N, S, W, E
;
                xor     ax, ax
                mov     [bp+NumPassableTiles], ax
                xor     ax, ax
                mov     [bp+OffsetIdx], ax ; Offset into the SlimeXOffsets and SlimeYOffsets arrays
                jmp     short ExpandLoop
; ---------------------------------------------------------------------------

NextLoop:                               ; CODE XREF: TickSlime+18Ej
                inc     [bp+OffsetIdx]
;
; Slime expansion loop
;

; Check if the next tile is passable

ExpandLoop:                             ; CODE XREF: TickSlime+96j
                mov     ax, [bp+Y]
                mov     di, [bp+OffsetIdx]
                shl     di, 1
                add     ax, SlimeYOffsets[di]
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+X]
                mov     di, [bp+OffsetIdx]
                shl     di, 1
                add     ax, SlimeXOffsets[di]
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
                jnz     short MoveOrSpawn
                jmp     CheckLoop
; ---------------------------------------------------------------------------
;
; If this is the first passable tile found, move into that tile, and create a
; breakable wall at the original space.
;
; For every other passable tile found, spawn a new slime in that tile.
;

MoveOrSpawn:                            ; CODE XREF: TickSlime+D2j
                cmp     [bp+NumPassableTiles], 0
                jnz     short SpawnSlime
;
; Move and create a breakable wall at the old location
;
                push    [bp+ParamIdx]
                mov     ax, [bp+X]
                mov     di, [bp+OffsetIdx]
                shl     di, 1
                add     ax, SlimeXOffsets[di]
                push    ax
                mov     ax, [bp+Y]
                mov     di, [bp+OffsetIdx]
                shl     di, 1
                add     ax, SlimeYOffsets[di]
                push    ax
                call    MoveTileWithIdx
                mov     bl, byte ptr [bp+Color]
                mov     ax, [bp+Y]
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+X]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                mov     BoardTopLeft.Color[di], bl
                mov     ax, [bp+Y]
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+X]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                mov     byte ptr BoardTopLeft.Type[di], TTBreakable
; Draw the new breakable
                push    [bp+X]
                push    [bp+Y]
                call    DrawTile
                jmp     short IncrementPassable
; ---------------------------------------------------------------------------
;
; Spawn a new slime
;

SpawnSlime:                             ; CODE XREF: TickSlime+DBj
                mov     ax, [bp+X]
                mov     di, [bp+OffsetIdx]
                shl     di, 1
                add     ax, SlimeXOffsets[di]
                push    ax
                mov     ax, [bp+Y]
                mov     di, [bp+OffsetIdx]
                shl     di, 1
                add     ax, SlimeYOffsets[di]
                push    ax
                mov     al, TTSlime
                push    ax
                push    [bp+Color]
                push    TileTypes.Cycle+(size TileType*TTSlime)
                mov     di, offset UnknownParamBuf
                push    ds
                push    di
                call    Spawn           ; X, Y, Type, Color, Cycle, SrcParam
; Copy movement speed to new slime
                les     di, [bp+ParamPtr]
                mov     cl, es:[di+ParamRecord.Param2] ; movement speed
                mov     ax, BoardParamCount
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                mov     BoardParams.Param2[di], cl

IncrementPassable:                      ; CODE XREF: TickSlime+13Cj
                mov     ax, [bp+NumPassableTiles]
                inc     ax
                mov     [bp+NumPassableTiles], ax

CheckLoop:                              ; CODE XREF: TickSlime+D4j
                cmp     [bp+OffsetIdx], 3
                jz      short DoneLoop
                jmp     NextLoop
; ---------------------------------------------------------------------------

DoneLoop:                               ; CODE XREF: TickSlime+18Cj
                cmp     [bp+NumPassableTiles], 0
                jnz     short EndTickSlime
;
; Couldn't find any passable tiles to move into.
; Die and turn into a breakable.
;
                push    [bp+ParamIdx]
                call    RemoveParamIdx
                mov     ax, [bp+Y]
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+X]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                mov     byte ptr BoardTopLeft.Type[di], TTBreakable
                mov     bl, byte ptr [bp+Color]
                mov     ax, [bp+Y]
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+X]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                mov     BoardTopLeft.Color[di], bl
; Draw the new breakable
                push    [bp+X]
                push    [bp+Y]
                call    DrawTile

EndTickSlime:                           ; CODE XREF: TickSlime+43j
                                        ; TickSlime+195j
                mov     sp, bp
                pop     bp
                retf    2
TickSlime       endp
