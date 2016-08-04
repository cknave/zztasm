; ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦ S U B R O U T I N E ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦

; Attributes: bp-based frame

RandomStep      proc far                ; CODE XREF: TickLion+44↑P
                                        ; seg001:03FB↑P ...

StepYPtr        = dword ptr  6
StepXPtr        = dword ptr  0Ah

                push    bp
                mov     bp, sp
                xor     ax, ax
                call    CheckStack
;
; Get a value between [-1,1] and assign it to StepX
;
                mov     ax, 3
                push    ax
                call    Random
                dec     ax
                les     di, [bp+StepXPtr]
                mov     es:[di], ax
                les     di, [bp+StepXPtr]
                cmp     word ptr es:[di], 0
                jnz     short ClearStepY
;
; Get a value that's either -1 or 1 and assign it to StepY
;
                mov     ax, 2
                push    ax
                call    Random
                shl     ax, 1
                dec     ax
                les     di, [bp+StepYPtr]
                mov     es:[di], ax
                jmp     short DoneRandomStep
; ---------------------------------------------------------------------------

ClearStepY:                             ; CODE XREF: RandomStep+21↑j
                les     di, [bp+StepYPtr]
                xor     ax, ax
                mov     es:[di], ax

DoneRandomStep:                         ; CODE XREF: RandomStep+35↑j
                mov     sp, bp
                pop     bp
                retf    8
RandomStep      endp


; ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦ S U B R O U T I N E ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦

; Attributes: bp-based frame

SeekStep        proc far                ; CODE XREF: TickLion+68↑P
                                        ; seg001:03E2↑P ...

StepYPtr        = dword ptr  6
StepXPtr        = dword ptr  0Ah
Y               = word ptr  0Eh
X               = word ptr  10h

                push    bp
                mov     bp, sp
                xor     ax, ax
                call    CheckStack
;
; Clear StepX and StepY
;
                les     di, [bp+StepXPtr]
                xor     ax, ax
                mov     es:[di], ax
                les     di, [bp+StepYPtr]
                xor     ax, ax
                mov     es:[di], ax
;
; Pick randomly whether to move on the X or Y axis
;
                mov     ax, 2
                push    ax
                call    Random
                cmp     ax, 1
                jb      short SetStepX
; If we picked Y but are already aligned on the Y axis, set X instead.
                mov     al, BoardParams.Y
                xor     ah, ah
                cmp     ax, [bp+Y]
                jnz     short CheckStepX
;
; Set StepX towards the player
;

SetStepX:                               ; CODE XREF: SeekStep+26↑j
                mov     al, BoardParams.X
                xor     ah, ah
                sub     ax, [bp+X]
                push    ax
                push    cs
                call    near ptr StepForDelta ; Return step (-1, 0, or 1) for (negative, 0, or positive) delta
                les     di, [bp+StepXPtr]
                mov     es:[di], ax
; Check if we decided to move on the X axis

CheckStepX:                             ; CODE XREF: SeekStep+30↑j
                les     di, [bp+StepXPtr]
                cmp     word ptr es:[di], 0
                jnz     short CheckEnergized
;
; Set StepY towards the player
;
                mov     al, BoardParams.Y
                xor     ah, ah
                sub     ax, [bp+Y]
                push    ax
                push    cs
                call    near ptr StepForDelta ; Return step (-1, 0, or 1) for (negative, 0, or positive) delta
                les     di, [bp+StepYPtr]
                mov     es:[di], ax
;
; Reverse the result if the player is energized
;

CheckEnergized:                         ; CODE XREF: SeekStep+4C↑j
                cmp     EnergizerCycles, 0
                jle     short DoneSeekStep
                les     di, [bp+StepXPtr]
                mov     ax, es:[di]
                neg     ax
                les     di, [bp+StepXPtr]
                mov     es:[di], ax
                les     di, [bp+StepYPtr]
                mov     ax, es:[di]
                neg     ax
                les     di, [bp+StepYPtr]
                mov     es:[di], ax

DoneSeekStep:                           ; CODE XREF: SeekStep+66↑j
                mov     sp, bp
                pop     bp
                retf    0Ch
SeekStep        endp
