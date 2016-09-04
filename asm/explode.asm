; ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦ S U B R O U T I N E ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦

; Attributes: bp-based frame

Explode         proc far                ; CODE XREF: TickBomb+88↑p
                                        ; TickBomb+C1↑p ...

TilePtr         = dword ptr -10h
LastY           = word ptr -0Ch
LastX           = word ptr -0Ah
DidSendBombed   = byte ptr -7
BombedParamIdx  = word ptr -6
CurrentY        = word ptr -4
CurrentX        = word ptr -2
Mode            = word ptr  6
CenterY         = word ptr  8
CenterX         = word ptr  0Ah

                push    bp
                mov     bp, sp
                mov     ax, 10h
                call    CheckStack
                sub     sp, 10h
                mov     ax, [bp+CenterX]
                add     ax, 8
                inc     ax
                mov     [bp+LastX], ax
                mov     ax, [bp+CenterX]
                sub     ax, 8
                dec     ax
                cmp     ax, [bp+LastX]
                jle     short InitCurrentX ; always true (x-8-1 < x+8+1)
                jmp     DoneExplode
; ---------------------------------------------------------------------------

InitCurrentX:                           ; CODE XREF: Explode+22↑j
                mov     [bp+CurrentX], ax ; X - 9
                jmp     short LoopX
; ---------------------------------------------------------------------------

IncrX:                                  ; CODE XREF: Explode+192↓j
                inc     [bp+CurrentX]
;
; Check inside left bound
;

LoopX:                                  ; CODE XREF: Explode+2A↑j
                cmp     [bp+CurrentX], 1
                jge     short CheckInRightBound
                jmp     CheckCurrentX
; ---------------------------------------------------------------------------
;
; Check inside right bound
;


CheckInRightBound:                      ; CODE XREF: Explode+33↑j
                cmp     [bp+CurrentX], 60
                jle     short PrepareYLoop
                jmp     CheckCurrentX
; ---------------------------------------------------------------------------

PrepareYLoop:                           ; CODE XREF: Explode+3C↑j
                mov     ax, [bp+CenterY]
                add     ax, 5
                inc     ax
                mov     [bp+LastY], ax
                mov     ax, [bp+CenterY]
                sub     ax, 5
                dec     ax
                cmp     ax, [bp+LastY]
                jle     short InitCurrentY ; always true (y-5-1 < y+5+1)
                jmp     CheckCurrentX
; ---------------------------------------------------------------------------

InitCurrentY:                           ; CODE XREF: Explode+55↑j
                mov     [bp+CurrentY], ax
                jmp     short LoopY
; ---------------------------------------------------------------------------

IncrY:                                  ; CODE XREF: Explode+187↓j
                inc     [bp+CurrentY]
;
; Check inside top bound
;

LoopY:                                  ; CODE XREF: Explode+5D↑j
                cmp     [bp+CurrentY], 1
                jge     short CheckInBottomBound
                jmp     CheckCurrentY
; ---------------------------------------------------------------------------
;
; Check inside bottom bound
;

CheckInBottomBound:                     ; CODE XREF: Explode+66↑j
                cmp     [bp+CurrentY], 25
                jle     short GetCurrentTile
                jmp     CheckCurrentY
; ---------------------------------------------------------------------------

GetCurrentTile:                         ; CODE XREF: Explode+6F↑j
                mov     ax, [bp+CurrentY]
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+CurrentX]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                add     di, offset BoardTopLeft
                mov     word ptr [bp+TilePtr], di
                mov     word ptr [bp+TilePtr+2], ds
                cmp     [bp+Mode], EMRedrawOnly
                jg      short CheckDistCenter
                jmp     DrawCurrentTile
; ---------------------------------------------------------------------------
;
; If the squared distance from the center is less than 50, it's bombed
;

CheckDistCenter:                        ; CODE XREF: Explode+95↑j
                mov     ax, [bp+CurrentY]
                sub     ax, [bp+CenterY]
                imul    ax
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+CurrentX]
                sub     ax, [bp+CenterX]
                imul    ax
                add     ax, cx
                cmp     ax, 50
                jl      short CheckBombMode
                jmp     DrawCurrentTile
; ---------------------------------------------------------------------------
;
; Check if we're bombing or cleaning up
;

CheckBombMode:                          ; CODE XREF: Explode+B3↑j
                cmp     [bp+Mode], EMBomb
                jz      short CheckCanHaveCode
                jmp     CheckBreakable
; ---------------------------------------------------------------------------
;
; If the tile can have code, send it to the BOMBED label
;

CheckCanHaveCode:                       ; CODE XREF: Explode+BC↑j
                les     di, [bp+TilePtr]
                mov     al, es:[di+Tile.Type]
                xor     ah, ah
                mov     dx, size TileType
                mul     dx
                mov     di, ax
                cmp     byte ptr TileTypes.EditCodePrompt[di], 0
                jz      short CheckDestroy
                push    [bp+CurrentX]
                push    [bp+CurrentY]
                call    ParamIdxForXY   ; Index for param at (X, Y) or -1 if not found
                mov     [bp+BombedParamIdx], ax
                cmp     [bp+BombedParamIdx], 0
                jle     short CheckDestroy
                mov     ax, [bp+BombedParamIdx]
                neg     ax
                push    ax
                mov     di, offset aBombed ; "BOMBED"
                push    cs
                push    di
                mov     al, 0
                push    ax
                call    Send
                mov     [bp+DidSendBombed], al
;
; If the tile is destructible or a star, destroy it
;

CheckDestroy:                           ; CODE XREF: Explode+D5↑j
                                        ; Explode+E9↑j
                les     di, [bp+TilePtr]
                mov     al, es:[di+Tile.Type]
                xor     ah, ah
                mov     dx, size TileType
                mul     dx
                mov     di, ax
                cmp     TileTypes.Destructible[di], 0
                jnz     short DestroyTile
                les     di, [bp+TilePtr]
                cmp     es:[di+Tile.Type], TTStar
                jnz     short CheckReplaceType

DestroyTile:                            ; CODE XREF: Explode+115↑j
                push    [bp+CurrentX]
                push    [bp+CurrentY]
                call    Destroy
;
; Replace empties and breakables with randomly colored breakables
;

CheckReplaceType:                       ; CODE XREF: Explode+11E↑j
                les     di, [bp+TilePtr]
                cmp     es:[di+Tile.Type], TTEmpty
                jz      short RndColorBreakable
                les     di, [bp+TilePtr]
                cmp     es:[di+Tile.Type], TTBreakable
                jnz     short DoneBombing

RndColorBreakable:                      ; CODE XREF: Explode+132↑j
                les     di, [bp+TilePtr]
                mov     es:[di+Tile.Type], TTBreakable
                mov     ax, 7
                push    ax
                call    Random
                add     ax, 9           ; random color, light blue through white
                les     di, [bp+TilePtr]
                mov     es:[di+Tile.Color], al
                push    [bp+CurrentX]
                push    [bp+CurrentY]
                call    DrawTile

DoneBombing:                            ; CODE XREF: Explode+13B↑j
                jmp     short DrawCurrentTile
; ---------------------------------------------------------------------------
;
; Replace any breakables with empties before redrawing
;

CheckBreakable:                         ; CODE XREF: Explode+BE↑j
                les     di, [bp+TilePtr]
                cmp     es:[di+Tile.Type], TTBreakable
                jnz     short DrawCurrentTile
                les     di, [bp+TilePtr]
                mov     es:[di+Tile.Type], TTEmpty

DrawCurrentTile:                        ; CODE XREF: Explode+97↑j
                                        ; Explode+B5↑j ...
                push    [bp+CurrentX]
                push    [bp+CurrentY]
                call    DrawTile

CheckCurrentY:                          ; CODE XREF: Explode+68↑j
                                        ; Explode+71↑j
                mov     ax, [bp+CurrentY]
                cmp     ax, [bp+LastY]
                jz      short CheckCurrentX
                jmp     IncrY
; ---------------------------------------------------------------------------

CheckCurrentX:                          ; CODE XREF: Explode+35↑j
                                        ; Explode+3E↑j ...
                mov     ax, [bp+CurrentX]
                cmp     ax, [bp+LastX]
                jz      short DoneExplode
                jmp     IncrX
; ---------------------------------------------------------------------------

DoneExplode:                            ; CODE XREF: Explode+24↑j
                                        ; Explode+190↑j
                mov     sp, bp
                pop     bp
                retf    6
Explode         endp
