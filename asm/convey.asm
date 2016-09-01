; ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦ S U B R O U T I N E ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦

; Attributes: bp-based frame

Convey          proc far                ; CODE XREF: TickConveyorCW+52↓p
                                        ; TickConveyorCCW+52↓p

CurrentTile     = dword ptr -24h
SrcTile         = word ptr -20h
OffsetEnd       = word ptr -1Eh
OffsetStart     = word ptr -1Ch
Tiles           = word ptr -1Ah
PrevTileMovable = byte ptr -9
DestY           = word ptr -8
DestX           = word ptr -6
SrcParamIdx     = word ptr -4
OffsetIdx       = word ptr -2
Direction       = word ptr  6
Y               = word ptr  8
X               = word ptr  0Ah

                push    bp
                mov     bp, sp
                mov     ax, 24h ; '$'
                call    CheckStack
                sub     sp, 24h
                cmp     [bp+Direction], 1
                jnz     short InitBackwardsLoop
; Loop in [0,8)
                xor     ax, ax
                mov     [bp+OffsetStart], ax
                mov     [bp+OffsetEnd], 8
                jmp     short PrepareGetTilesLoop
; ---------------------------------------------------------------------------
; Loop in [7,-1)

InitBackwardsLoop:                      ; CODE XREF: Convey+12↑j
                mov     [bp+OffsetStart], 7
                mov     [bp+OffsetEnd], -1

PrepareGetTilesLoop:                    ; CODE XREF: Convey+1E↑j
                mov     [bp+PrevTileMovable], 1
                mov     ax, [bp+OffsetStart]
                mov     [bp+OffsetIdx], ax
;
; Get all the tiles around this conveyor, looping over the conveyor X and Y offsets
; Keep track of whether the last tile is empty or pushable
;

GetTilesLoop:                           ; CODE XREF: Convey+AB↓j
                mov     ax, [bp+Y]
                mov     di, [bp+OffsetIdx]
                shl     di, 1
                add     ax, ConveyorYOffsets[di]
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+X]
                mov     di, [bp+OffsetIdx]
                shl     di, 1
                add     ax, ConveyorXOffsets[di]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                mov     ax, BoardTopLeft[di]
                mov     di, [bp+OffsetIdx]
                shl     di, 1
                mov     [bp+di+Tiles], ax
                mov     di, [bp+OffsetIdx]
                shl     di, 1
                lea     di, [bp+di+Tiles]
                mov     word ptr [bp+CurrentTile], di
                mov     word ptr [bp+CurrentTile+2], ss
                les     di, [bp+CurrentTile]
                cmp     es:[di+Tile.Type], TTEmpty
                jnz     short GetTilesNonEmpty
                mov     [bp+PrevTileMovable], 1
                jmp     short CheckGetTilesLoop
; ---------------------------------------------------------------------------

GetTilesNonEmpty:                       ; CODE XREF: Convey+7A↑j
                les     di, [bp+CurrentTile]
                mov     al, es:[di+Tile.Type]
                xor     ah, ah
                mov     dx, size TileType
                mul     dx
                mov     di, ax
                cmp     TileTypes.Pushable[di], 0
                jnz     short CheckGetTilesLoop
                mov     [bp+PrevTileMovable], 0

CheckGetTilesLoop:                      ; CODE XREF: Convey+80↑j
                                        ; Convey+96↑j
                mov     ax, [bp+OffsetIdx]
                add     ax, [bp+Direction]
                mov     [bp+OffsetIdx], ax
                mov     ax, [bp+OffsetIdx]
                cmp     ax, [bp+OffsetEnd]
                jnz     short GetTilesLoop
                mov     ax, [bp+OffsetStart]
                mov     [bp+OffsetIdx], ax
;
; Start rotating as soon as the previous tile is movable
;

RotateLoop:                             ; CODE XREF: Convey+2E7↓j
                mov     di, [bp+OffsetIdx]
                shl     di, 1
                lea     di, [bp+di+Tiles]
                mov     word ptr [bp+CurrentTile], di
                mov     word ptr [bp+CurrentTile+2], ss
                cmp     [bp+PrevTileMovable], 0
                jnz     short MovableCheckPushable
                jmp     CheckCurrentEmpty
; ---------------------------------------------------------------------------

MovableCheckPushable:                   ; CODE XREF: Convey+C5↑j
                les     di, [bp+CurrentTile]
                mov     al, es:[di]
                xor     ah, ah
                mov     dx, size TileType
                mul     dx
                mov     di, ax
                cmp     TileTypes.Pushable[di], 0
                jnz     short PrepareToRotate
                jmp     MovableNotPushable
; ---------------------------------------------------------------------------
;
; Prepare to rotate the previous tile into this tile's space
;

PrepareToRotate:                        ; CODE XREF: Convey+DE↑j
                mov     ax, [bp+OffsetIdx]
                sub     ax, [bp+Direction]
                add     ax, 8
                cwd
                mov     cx, 8
                idiv    cx
                xchg    ax, dx
                mov     di, ax
                shl     di, 1
                mov     ax, ConveyorXOffsets[di]
                add     ax, [bp+X]
                mov     [bp+DestX], ax
                mov     ax, [bp+OffsetIdx]
                sub     ax, [bp+Direction]
                add     ax, 8
                cwd
                mov     cx, 8
                idiv    cx
                xchg    ax, dx
                mov     di, ax
                shl     di, 1
                mov     ax, ConveyorYOffsets[di]
                add     ax, [bp+Y]
                mov     [bp+DestY], ax
; Check if the current tile has params (cycle != -1)
                les     di, [bp+CurrentTile]
                mov     al, es:[di+Tile.Type]
                xor     ah, ah
                mov     dx, size TileType
                mul     dx
                mov     di, ax
                cmp     TileTypes.Cycle[di], -1
                jg      short RotateParamTile
                jmp     RotatePlainTile
; ---------------------------------------------------------------------------
; Get the parameter index at the source tile

RotateParamTile:                        ; CODE XREF: Convey+133↑j
                mov     ax, [bp+Y]
                mov     di, [bp+OffsetIdx]
                shl     di, 1
                add     ax, ConveyorYOffsets[di]
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+X]
                mov     di, [bp+OffsetIdx]
                shl     di, 1
                add     ax, ConveyorXOffsets[di]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                mov     ax, BoardTopLeft[di]
                mov     [bp+SrcTile], ax
                mov     ax, [bp+X]
                mov     di, [bp+OffsetIdx]
                shl     di, 1
                add     ax, ConveyorXOffsets[di]
                push    ax
                mov     ax, [bp+Y]
                mov     di, [bp+OffsetIdx]
                shl     di, 1
                add     ax, ConveyorYOffsets[di]
                push    ax
                call    ParamIdxForXY   ; Index for param at (X, Y) or -1 if not found
;
; Set the correct tile types at the source and destination, then move
;
                mov     [bp+SrcParamIdx], ax
                mov     di, [bp+OffsetIdx]
                shl     di, 1
                mov     bx, [bp+di+Tiles]
                mov     ax, [bp+Y]
                mov     di, [bp+OffsetIdx]
                shl     di, 1
                add     ax, ConveyorYOffsets[di]
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+X]
                mov     di, [bp+OffsetIdx]
                shl     di, 1
                add     ax, ConveyorXOffsets[di]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                mov     BoardTopLeft[di], bx
                mov     ax, [bp+DestY]
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+DestX]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                mov     byte ptr BoardTopLeft.Type[di], TTEmpty
                push    [bp+SrcParamIdx]
                push    [bp+DestX]
                push    [bp+DestY]
                call    MoveTileWithIdx
                mov     bx, [bp+SrcTile]
                mov     ax, [bp+Y]
                mov     di, [bp+OffsetIdx]
                shl     di, 1
                add     ax, ConveyorYOffsets[di]
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+X]
                mov     di, [bp+OffsetIdx]
                shl     di, 1
                add     ax, ConveyorXOffsets[di]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                mov     BoardTopLeft[di], bx
                jmp     short CheckNextPushable
; ---------------------------------------------------------------------------
; No params to move, just copy the tile

RotatePlainTile:                        ; CODE XREF: Convey+135↑j
                mov     di, [bp+OffsetIdx]
                shl     di, 1
                mov     bx, [bp+di+Tiles]
                mov     ax, [bp+DestY]
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+DestX]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                mov     BoardTopLeft[di], bx
                push    [bp+DestX]
                push    [bp+DestY]
                call    DrawTile
;
; If the next tile isn't pushable, clear out the (now vacated)
; current tile.  This is not necessary if the next tile is pushable
; since it will be pushed into this spot.
;

CheckNextPushable:                      ; CODE XREF: Convey+209↑j
                mov     ax, [bp+OffsetIdx]
                add     ax, [bp+Direction]
                add     ax, 8
                cwd
                mov     cx, 8
                idiv    cx
                xchg    ax, dx
                mov     di, ax
                shl     di, 1
                mov     al, byte ptr [bp+di+Tiles]
                xor     ah, ah
                mov     dx, size TileType
                mul     dx
                mov     di, ax
                cmp     TileTypes.Pushable[di], 0
                jnz     short DoneRotation
                mov     ax, [bp+Y]
                mov     di, [bp+OffsetIdx]
                shl     di, 1
                add     ax, ConveyorYOffsets[di]
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+X]
                mov     di, [bp+OffsetIdx]
                shl     di, 1
                add     ax, ConveyorXOffsets[di]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                mov     byte ptr BoardTopLeft.Type[di], TTEmpty
                mov     ax, [bp+X]
                mov     di, [bp+OffsetIdx]
                shl     di, 1
                add     ax, ConveyorXOffsets[di]
                push    ax
                mov     ax, [bp+Y]
                mov     di, [bp+OffsetIdx]
                shl     di, 1
                add     ax, ConveyorYOffsets[di]
                push    ax
                call    DrawTile

DoneRotation:                           ; CODE XREF: Convey+25A↑j
                jmp     short PrepareToLoop
; ---------------------------------------------------------------------------

MovableNotPushable:                     ; CODE XREF: Convey+E0↑j
                mov     [bp+PrevTileMovable], 0

PrepareToLoop:                          ; CODE XREF: Convey:DoneRotation↑j
                jmp     short CheckRotateLoop
; ---------------------------------------------------------------------------

CheckCurrentEmpty:                      ; CODE XREF: Convey+C7↑j
                les     di, [bp+CurrentTile]
                cmp     es:[di+Tile.Type], TTEmpty
                jnz     short CurrentNotEmpty
                mov     [bp+PrevTileMovable], 1
                jmp     short CheckRotateLoop
; ---------------------------------------------------------------------------

CurrentNotEmpty:                        ; CODE XREF: Convey+2B4↑j
                les     di, [bp+CurrentTile]
                mov     al, es:[di+Tile.Type]
                xor     ah, ah
                mov     dx, size TileType
                mul     dx
                mov     di, ax
                cmp     TileTypes.Pushable[di], 0
                jnz     short CheckRotateLoop
                mov     [bp+PrevTileMovable], 0

CheckRotateLoop:                        ; CODE XREF: Convey:PrepareToLoop↑j
                                        ; Convey+2BA↑j ...
                mov     ax, [bp+OffsetIdx]
                add     ax, [bp+Direction]
                mov     [bp+OffsetIdx], ax
                mov     ax, [bp+OffsetIdx]
                cmp     ax, [bp+OffsetEnd]
                jz      short DoneConvey
                jmp     RotateLoop
; ---------------------------------------------------------------------------

DoneConvey:                             ; CODE XREF: Convey+2E5↑j
                mov     sp, bp
                pop     bp
                retf    6
Convey          endp
