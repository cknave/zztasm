; ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦ S U B R O U T I N E ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦

; Attributes: bp-based frame

TickTiger       proc far                ; DATA XREF: InitTileTypes+2E1↓o

ParamPtr        = dword ptr -6
ShootType       = byte ptr -2
HasShot         = byte ptr -1
ParamIdx        = word ptr  6

                push    bp
                mov     bp, sp
                mov     ax, 6
                call    CheckStack
                sub     sp, 6
                mov     ax, [bp+ParamIdx]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                add     di, offset BoardParams
                mov     word ptr [bp+ParamPtr], di
                mov     word ptr [bp+ParamPtr+2], ds
                mov     [bp+ShootType], TTBullet
                les     di, [bp+ParamPtr]
                cmp     es:[di+ParamRecord.Param2], FiringRateStarMask ; Check for shooting star flag
                jb      short TigShootTypeSet
                mov     [bp+ShootType], TTStar
;
; Decide if we're going to shoot this tick
;

TigShootTypeSet:                        ; CODE XREF: TickTiger+2E↑j
                mov     ax, 0Ah
                push    ax
                call    Random          ; Get a random number in [0, 10)...
                mov     cx, 3
                mul     cx              ; ...and multiply by 3
                mov     bx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Param2] ; masked firing rate
; Clear the star mask by integer division!
                xor     ah, ah
                cwd
                mov     cx, FiringRateStarMask
                idiv    cx
                xchg    ax, dx          ; ax is now the unmasked firing rate
                cmp     ax, bx
                jnb     short TigerCheckXAxis
                jmp     EndTickTiger
; ---------------------------------------------------------------------------
;
; Check if the player is within 2 tiles on the X axis
;

TigerCheckXAxis:                        ; CODE XREF: TickTiger+56↑j
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                push    ax
                mov     al, BoardParams.X
                xor     ah, ah
                push    ax
                call    Distance        ; Calculate the distance between two ints
                cmp     ax, 2
                jg      short TigerDontShootY
;
; The player is close on the X axis, so shoot on the Y axis
;
                mov     al, [bp+ShootType]
                push    ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                push    ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                push    ax
                xor     ax, ax
                push    ax
; Get the Y direction to shoot
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                mov     dx, ax
                mov     al, BoardParams.Y
                xor     ah, ah
                sub     ax, dx
                push    ax
                call    StepForDelta    ; Return step (-1, 0, or 1) for (negative, 0, or positive) delta
                push    ax
                mov     ax, SOEnemy
                push    ax
                call    Shoot           ; Shoot a ShootType from (FromX,FromY) at (StepX,StepY)
                                        ; Owner 0=player, 1=enemy
                mov     [bp+HasShot], al
                jmp     short TigerCheckYAxis
; ---------------------------------------------------------------------------

TigerDontShootY:                        ; CODE XREF: TickTiger+72↑j
                mov     [bp+HasShot], 0

TigerCheckYAxis:                        ; CODE XREF: TickTiger+B3↑j
                cmp     [bp+HasShot], 0
                jnz     short EndTickTiger
;
; Check if the player is within 2 tiles on the Y axis
;
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                push    ax
                mov     al, BoardParams.Y
                xor     ah, ah
                push    ax
                call    Distance        ; Calculate the distance between two ints
                cmp     ax, 2
                jg      short EndTickTiger
;
; The player is close on the Y axis, so shoot on the X axis
;
                mov     al, [bp+ShootType]
                push    ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                push    ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                push    ax
; Get the X direction to shoot
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                mov     dx, ax
                mov     al, BoardParams.X
                xor     ah, ah
                sub     ax, dx
                push    ax
                call    StepForDelta    ; Return step (-1, 0, or 1) for (negative, 0, or positive) delta
                push    ax
                xor     ax, ax
                push    ax
                mov     ax, SOEnemy
                push    ax
                call    Shoot           ; Shoot a ShootType from (FromX,FromY) at (StepX,StepY)
                                        ; Owner 0=player, 1=enemy
                mov     [bp+HasShot], al

EndTickTiger:                           ; CODE XREF: TickTiger+58↑j
                                        ; TickTiger+BD↑j ...
                push    [bp+ParamIdx]
                push    cs
                call    near ptr TickLion ; Use the same movement behavior as a lion
                mov     sp, bp
                pop     bp
                retf    2
TickTiger       endp
