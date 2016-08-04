; ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦ S U B R O U T I N E ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦

; Attributes: bp-based frame

TickSegment     proc far                ; DATA XREF: InitTileTypes+3EF↓o

ParamPtr        = dword ptr -4
ParamIdx        = word ptr  6

                push    bp
                mov     bp, sp
                mov     ax, 4
                call    CheckStack
                sub     sp, 4
                mov     ax, [bp+ParamIdx]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                add     di, offset BoardParams
                mov     word ptr [bp+ParamPtr], di
                mov     word ptr [bp+ParamPtr+2], ds
;
; If this segment has a leader, no need to do anything.
;
                les     di, [bp+ParamPtr]
                cmp     es:[di+ParamRecord.Leader], 0
                jge     short DoneTickSegment
                les     di, [bp+ParamPtr]
                cmp     es:[di+ParamRecord.Leader], -1
                jge     short SegmentWait
;
; The leader index is now -2, time to turn into a head.
;
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                shl     ax, 1
                mov     cx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                mov     byte ptr BoardTopLeft.Type[di], TTHead
                jmp     short DoneTickSegment
; ---------------------------------------------------------------------------
;
; If the leader index is -1, decrease it.  This lets us wait a tick
; until turning into a head.
;

SegmentWait:                            ; CODE XREF: TickSegment+34↑j
                les     di, [bp+ParamPtr]
                mov     ax, es:[di+ParamRecord.Leader]
                dec     ax
                les     di, [bp+ParamPtr]
                mov     es:[di+ParamRecord.Leader], ax

DoneTickSegment:                        ; CODE XREF: TickSegment+2A↑j
                                        ; TickSegment+59↑j
                mov     sp, bp
                pop     bp
                retf    2
TickSegment     endp
