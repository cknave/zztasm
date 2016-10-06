; ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦ S U B R O U T I N E ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦

; Attributes: bp-based frame

TickObject      proc far                ; DATA XREF: InitTileTypes+DAA↓o

ParamPtr        = dword ptr -6
DidSend         = byte ptr -1
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
                les     di, [bp+ParamPtr]
;
; If the program is active (instruction pointer >= 0), run a cycle
;
                cmp     es:[di+ParamRecord.InstructionPtr], 0
                jl      short CheckMoving
                push    [bp+ParamIdx]
                les     di, [bp+ParamPtr]
                add     di, ParamRecord.InstructionPtr
                push    es
                push    di
                mov     di, offset aInteraction ; "Interaction"
                push    cs
                push    di
                call    RunCodeCycle
;
; If the object is moving, handle movement
;

CheckMoving:                            ; CODE XREF: TickObject+2A↑j
                les     di, [bp+ParamPtr]
                cmp     es:[di+ParamRecord.StepX], 0
                jnz     short TryMoving
                les     di, [bp+ParamPtr]
                cmp     es:[di+ParamRecord.StepY], 0
                jnz     short TryMoving
                jmp     DoneTickObject
; ---------------------------------------------------------------------------
;
; Try to move.  If blocked, send THUD.
;

TryMoving:                              ; CODE XREF: TickObject+4A↑j
                                        ; TickObject+54↑j
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
                mov     al, byte ptr BoardTopLeft.Type[di]
                xor     ah, ah
                mov     dx, size TileType
                mul     dx
                mov     di, ax
                cmp     TileTypes.Passable[di], 0
                jz      short SendThud
; Destination is passable
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
                jmp     short DoneTickObject
; ---------------------------------------------------------------------------

SendThud:                               ; CODE XREF: TickObject+97↑j
                mov     ax, [bp+ParamIdx]
                neg     ax
                push    ax
                mov     di, offset aThud ; "THUD"
                push    cs
                push    di
                mov     al, 0
                push    ax
                call    Send
                mov     [bp+DidSend], al

DoneTickObject:                         ; CODE XREF: TickObject+56↑j
                                        ; TickObject+C2↑j
                mov     sp, bp
                pop     bp
                retf    2
TickObject      endp
