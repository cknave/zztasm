; ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦ S U B R O U T I N E ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦

; Attributes: bp-based frame

TickSpinningGun proc far                ; DATA XREF: InitTileTypes+70B↓o

ParamPtr        = dword ptr -0Ch
ShootType       = byte ptr -7
StepY           = word ptr -6
StepX           = word ptr -4
DidShoot        = byte ptr -1
ParamIdx        = word ptr  6

                push    bp
                mov     bp, sp
                mov     ax, 0Ch
                call    CheckStack
                sub     sp, 0Ch
                mov     ax, [bp+ParamIdx]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                add     di, offset BoardParams
                mov     word ptr [bp+ParamPtr], di
                mov     word ptr [bp+ParamPtr+2], ds
;
; Redraw every tick
;
                les     di, [bp+ParamPtr]
                mov     al, es:[di]
                xor     ah, ah
                push    ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+1]
                xor     ah, ah
                push    ax
                call    DrawTile
;
; Check the high bit of the firing rate for shoot type
;
                mov     [bp+ShootType], TTBullet
                les     di, [bp+ParamPtr]
                cmp     es:[di+ParamRecord.Param2], FiringRateStarMask
                jb      short PickedShootType
                mov     [bp+ShootType], TTStar
;
; Firing rate check
;

PickedShootType:                        ; CODE XREF: TickSpinningGun+46↑j
                mov     ax, 9
                push    ax
                call    Random
                mov     bx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Param2] ; firing rate
                xor     ah, ah
; Clear star flag by integer division
                cwd
                mov     cx, FiringRateStarMask
                idiv    cx
                xchg    ax, dx
                cmp     ax, bx
                ja      short IntelligenceCheck
                jmp     DoneTickSpinningGun
; ---------------------------------------------------------------------------
;
; Shoot seek only if we pass an intelligence check.
; Otherwise shoot randomly
;

IntelligenceCheck:                      ; CODE XREF: TickSpinningGun+69↑j
                mov     ax, 9
                push    ax
                call    Random
                mov     dx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Param1]
                xor     ah, ah
                cmp     ax, dx
                jnb     short CheckCloseXAxis
                jmp     ShootRandomly
; ---------------------------------------------------------------------------
;
; If the player's close on the X axis, shoot on the Y axis
;

CheckCloseXAxis:                        ; CODE XREF: TickSpinningGun+84↑j
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                push    ax
                mov     al, BoardParams.X
                xor     ah, ah
                push    ax
                call    Distance        ; Calculate the distance between two ints
                cmp     ax, 2
                jg      short NotCloseOnX
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
                mov     [bp+DidShoot], al
                jmp     short CheckShotYAxis
; ---------------------------------------------------------------------------

NotCloseOnX:                            ; CODE XREF: TickSpinningGun+A0↑j
                mov     [bp+DidShoot], 0

CheckShotYAxis:                         ; CODE XREF: TickSpinningGun+E1↑j
                cmp     [bp+DidShoot], 0
                jnz     short DoneTryingToShoot
;
; If the player's close on the Y axis, shoot on the X axis
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
                jg      short DoneTryingToShoot
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
                mov     ax, 1
                push    ax
                call    Shoot           ; Shoot a ShootType from (FromX,FromY) at (StepX,StepY)
                                        ; Owner 0=player, 1=enemy
                mov     [bp+DidShoot], al

DoneTryingToShoot:                      ; CODE XREF: TickSpinningGun+EB↑j
                                        ; TickSpinningGun+105↑j
                jmp     short DoneTickSpinningGun
; ---------------------------------------------------------------------------

ShootRandomly:                          ; CODE XREF: TickSpinningGun+86↑j
                lea     di, [bp+StepX]
                push    ss
                push    di
                lea     di, [bp+StepY]
                push    ss
                push    di
                call    RandomStep
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
                push    [bp+StepX]
                push    [bp+StepY]
                mov     ax, SOEnemy
                push    ax
                call    Shoot           ; Shoot a ShootType from (FromX,FromY) at (StepX,StepY)
                                        ; Owner 0=player, 1=enemy
                mov     [bp+DidShoot], al

DoneTickSpinningGun:                    ; CODE XREF: TickSpinningGun+6B↑j
                                        ; TickSpinningGun:DoneTryingToShoot↑j
                mov     sp, bp
                pop     bp
                retf    2
TickSpinningGun endp
