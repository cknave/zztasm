; ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦ S U B R O U T I N E ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦

; Attributes: bp-based frame

TickMessenger   proc far                ; DATA XREF: InitTileTypes+E02↓o

PaddedMessage   = word ptr -104h
ParamPtr        = dword ptr -4
ParamIdx        = word ptr  6

                push    bp
                mov     bp, sp
                mov     ax, 104h
                call    CheckStack
                sub     sp, 104h
                mov     ax, [bp+ParamIdx]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                add     di, offset BoardParams
                mov     word ptr [bp+ParamPtr], di
                mov     word ptr [bp+ParamPtr+2], ds
;
; Only show a message if our X coordinate is 0
;
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                cmp     al, 0
                jz      short ShowMessage
                jmp     DoneTickMessenger
; ---------------------------------------------------------------------------
;
; Display the message in a different color every tick
;

; Get the message X position, centered horizontally

ShowMessage:                            ; CODE XREF: TickMessenger+2B↑j
                mov     al, CurrentMessage
                xor     ah, ah
                mov     dx, ax
                mov     ax, 60
                sub     ax, dx
                cwd
                mov     cx, 2
                idiv    cx
                push    ax
; Draw the message at the bottom of the screen
                mov     al, 24
                push    ax
; Cycle between the 7 bright colors
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Param2] ; ticks left
                xor     ah, ah
                cwd
                mov     cx, 7
                idiv    cx
                xchg    ax, dx
                add     ax, 9
                push    ax
; Pad the message with a space on either side
                lea     di, [bp+PaddedMessage]
                push    ss
                push    di
                mov     di, offset a_space ; " "
                push    cs
                push    di
                call    StrCopy
                mov     di, offset CurrentMessage
                push    ds
                push    di
                call    StrCat
                mov     di, offset a_space ; " "
                push    cs
                push    di
                call    StrCat
                call    PutStr
; Decrement the ticks left
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Param2]
                xor     ah, ah
                dec     ax
                les     di, [bp+ParamPtr]
                mov     es:[di+ParamRecord.Param2], al
                les     di, [bp+ParamPtr]
;
; If there's no ticks left, die and clear the message
;
                cmp     es:[di+ParamRecord.Param2], 0
                ja      short DoneTickMessenger
; Remove this messenger, and decrement the current param index
                push    [bp+ParamIdx]
                call    RemoveParamIdx
                mov     ax, CurrentParamIdx ; index of the param record being handled
                dec     ax
                mov     CurrentParamIdx, ax ; index of the param record being handled
; Clear the on-screen message
                call    RedrawBorder
; Clear the current message buffer
                mov     CurrentMessage, 0

DoneTickMessenger:                      ; CODE XREF: TickMessenger+2D↑j
                                        ; TickMessenger+9B↑j
                mov     sp, bp
                pop     bp
                retf    2
TickMessenger   endp
