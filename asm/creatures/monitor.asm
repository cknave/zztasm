; Key code bitmap: ESC, 'A', 'E', 'H', 'N', 'P', 'Q', 'R', 'S', 'W', '|'
MonitorKeyBitmap db 3 dup(0), 8, 4 dup(0), 22h, 41h, 8Fh, 4 dup(0), 10h
                                        ; DATA XREF: TickMonitor+14↓o
                db 10h dup(0)

; ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦ S U B R O U T I N E ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦

; Attributes: bp-based frame

TickMonitor     proc far                ; DATA XREF: InitTileTypes+145↓o
                push    bp
                mov     bp, sp
                xor     ax, ax
                call    CheckStack
                mov     al, LastKeyCode
                push    ax
                call    ToUpper         ; Translate a-z to A-Z
                push    ax
                mov     di, offset MonitorKeyBitmap
                push    cs
                push    di
                call    CheckBitmap     ; Check if a bit is set in a bitmap
                jz      short DoneTickMonitor
                mov     ShouldHandleKeyPress, 1

DoneTickMonitor:                        ; CODE XREF: TickMonitor+1E↑j
                mov     sp, bp
                pop     bp
                retf    2
TickMonitor     endp
