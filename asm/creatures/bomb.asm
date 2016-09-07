; ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦ S U B R O U T I N E ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦

; Attributes: bp-based frame

TickBomb        proc far                ; DATA XREF: InitTileTypes+C2F↓o

ParamPtr        = dword ptr -8
Y               = word ptr -4
X               = word ptr -2
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
; Check if the bomb is counting down
;
                les     di, [bp+ParamPtr]
                cmp     es:[di+ParamRecord.Param1], 0 ; countdown
                ja      short DecrCountdown
                jmp     DoneTickBomb
; ---------------------------------------------------------------------------
;
; Decrement the countdown and redraw
;

DecrCountdown:                          ; CODE XREF: TickBomb+2A↑j
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Param1] ; countdown
                xor     ah, ah
                dec     ax
                les     di, [bp+ParamPtr]
                mov     es:[di+ParamRecord.Param1], al
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                push    ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                push    ax
                call    DrawTile
;
; Check if it's time to explode
;
                les     di, [bp+ParamPtr]
                cmp     es:[di+ParamRecord.Param1], 1 ; countdown
                jnz     short CheckZero
                mov     ax, 1
                push    ax
                mov     di, offset byte_121F7
                push    cs
                push    di
                call    PlaySoundPriority ; Not 100% sure on this yet but...
                                        ; Priority: higher priority overwrites the buffer,
                                        ;           -1 is maybe always overwrite?
                                        ; SoundPtr: binary representation in a pascal string
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                push    ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                push    ax
                mov     ax, EMBomb
                push    ax
                push    cs
                call    near ptr Explode
                jmp     short DoneTickBomb
; ---------------------------------------------------------------------------
;
; Check if it's time to clean up after the explosion
;

CheckZero:                              ; CODE XREF: TickBomb+60↑j
                les     di, [bp+ParamPtr]
                cmp     es:[di+ParamRecord.Param1], 0 ; countdown
                jnz     short PlayTickTock
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                mov     [bp+X], ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                mov     [bp+Y], ax
                push    [bp+ParamIdx]
                call    RemoveParamIdx
                push    [bp+X]
                push    [bp+Y]
                mov     ax, EMCleanUp
                push    ax
                push    cs
                call    near ptr Explode
                jmp     short DoneTickBomb
; ---------------------------------------------------------------------------

PlayTickTock:                           ; CODE XREF: TickBomb+95↑j
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Param1] ; countdown
                xor     ah, ah
                cwd
                mov     cx, 2
                idiv    cx
                xchg    ax, dx
                or      ax, ax
                jnz     short BombTock
                mov     ax, 1
                push    ax
                mov     di, offset sndBombTick
                push    cs
                push    di
                call    PlaySoundPriority ; Not 100% sure on this yet but...
                                        ; Priority: higher priority overwrites the buffer,
                                        ;           -1 is maybe always overwrite?
                                        ; SoundPtr: binary representation in a pascal string
                jmp     short DoneTickBomb
; ---------------------------------------------------------------------------

BombTock:                               ; CODE XREF: TickBomb+D8↑j
                mov     ax, 1
                push    ax
                mov     di, offset sndBombTock
                push    cs
                push    di
                call    PlaySoundPriority ; Not 100% sure on this yet but...
                                        ; Priority: higher priority overwrites the buffer,
                                        ;           -1 is maybe always overwrite?
                                        ; SoundPtr: binary representation in a pascal string

DoneTickBomb:                           ; CODE XREF: TickBomb+2C↑j
                                        ; TickBomb+8B↑j ...
                mov     sp, bp
                pop     bp
                retf    2
TickBomb        endp
