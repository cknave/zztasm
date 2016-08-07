; ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦ S U B R O U T I N E ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦

; Attributes: bp-based frame

TickLion        proc far                ; CODE XREF: TickTiger+11B↓p
                                        ; DATA XREF: InitTileTypes+263↓o

ParamPtr        = dword ptr -8
StepY           = word ptr -4
StepX           = word ptr -2
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
; Intelligence check
;
                mov     ax, 0Ah
                push    ax
                call    Random          ; Get random number in [0,10)
                mov     dx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Param1] ; Get intelligence
                xor     ah, ah
                cmp     ax, dx
                jnb     short LionGoSeek
                lea     di, [bp+StepX]
                push    ss
                push    di
                lea     di, [bp+StepY]
                push    ss
                push    di
                call    RandomStep
                jmp     short LionMove
; ---------------------------------------------------------------------------

LionGoSeek:                             ; CODE XREF: TickLion+38↑j
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                push    ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                push    ax
                lea     di, [bp+StepX]
                push    ss
                push    di
                lea     di, [bp+StepY]
                push    ss
                push    di
                call    SeekStep
; Get the tile at the proposed destination

LionMove:                               ; CODE XREF: TickLion+49↑j
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
                mov     al, byte ptr BoardTopLeft.Type[di]
                xor     ah, ah
                mov     dx, size TileType
                mul     dx
                mov     di, ax
; If it's not blocked, move to that tile
                cmp     TileTypes.Passable[di], 0
                jz      short LionBlocked
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
                call    MoveTileWithIdx
                jmp     short LionDoneTick
; ---------------------------------------------------------------------------
; We're blocked, check if it's by the player

LionBlocked:                            ; CODE XREF: TickLion+A3↑j
                les     di, [bp+ParamPtr]
                mov     al, es:[di+1]
                xor     ah, ah
                add     ax, [bp+StepY]
                shl     ax, 1
                mov     cx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di]
                xor     ah, ah
                add     ax, [bp+StepX]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                cmp     byte ptr BoardTopLeft.Type[di], TTPlayer
                jnz     short LionDoneTick
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

LionDoneTick:                           ; CODE XREF: TickLion+C6↑j
                                        ; TickLion+F1↑j
                mov     sp, bp
                pop     bp
                retf    2
TickLion        endp
