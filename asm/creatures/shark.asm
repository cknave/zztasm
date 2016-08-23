; ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦ S U B R O U T I N E ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦

; Attributes: bp-based frame

TickShark       proc far                ; DATA XREF: InitTileTypes+8F2o

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
; Intelligence check to step towards player instead of randomly
;
                mov     ax, 0Ah
                push    ax
                call    Random
                mov     dx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Param1] ; intelligence
                xor     ah, ah
                cmp     ax, dx
                jnb     short loc_12C9C
                lea     di, [bp+StepX]
                push    ss
                push    di
                lea     di, [bp+StepY]
                push    ss
                push    di
                call    RandomStep
                jmp     short CheckDestWater
; ---------------------------------------------------------------------------

loc_12C9C:                              ; CODE XREF: TickShark+38j
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
;
; Check if the destination tile has water
;

CheckDestWater:                         ; CODE XREF: TickShark+49j
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
                cmp     byte ptr BoardTopLeft.Type[di], TTWater
                jnz     short CheckPlayer
;
; Move to the destination water tile
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
                call    MoveTileWithIdx
                jmp     short EndTickShark
; ---------------------------------------------------------------------------
;
; If blocked by the player, die attacking them
;

CheckPlayer:                            ; CODE XREF: TickShark+96j
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
                cmp     byte ptr BoardTopLeft.Type[di], TTPlayer
                jnz     short EndTickShark
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

EndTickShark:                           ; CODE XREF: TickShark+B9j
                                        ; TickShark+E4j
                mov     sp, bp
                pop     bp
                retf    2
TickShark       endp
