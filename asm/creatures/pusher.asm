; ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦ S U B R O U T I N E ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦

; Attributes: bp-based frame

TickPusher      proc far                ; DATA XREF: InitTileTypes+BCF↓o

ParamPtr        = dword ptr -0Ah
Y               = word ptr -6
X               = word ptr -4
UnblockedPusherParamIdx= word ptr -2
ParamIdx        = word ptr  6

                push    bp
                mov     bp, sp
                mov     ax, 0Ah
                call    CheckStack
                sub     sp, 0Ah
                mov     ax, [bp+ParamIdx]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                add     di, offset BoardParams
                mov     word ptr [bp+ParamPtr], di
                mov     word ptr [bp+ParamPtr+2], ds
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                mov     [bp+X], ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                mov     [bp+Y], ax
;
; If the destination tile isn't passable, try pushing it out of the way
;
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
                jnz     short loc_13F66
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
                les     di, [bp+ParamPtr]
                push    es:[di+ParamRecord.StepX]
                les     di, [bp+ParamPtr]
                push    es:[di+ParamRecord.StepY]
                push    cs
                call    near ptr TryPush ; Try pushing the tile at X,Y in direction StepX,StepY
; This resets ParamIdx and ParamPtr to the object at X, Y
; ...but this object is still at X, Y...

loc_13F66:                              ; CODE XREF: TickPusher+77↑j
                push    [bp+X]
                push    [bp+Y]
                call    ParamIdxForXY   ; Index for param at (X, Y) or -1 if not found
                mov     [bp+ParamIdx], ax
                mov     ax, [bp+ParamIdx]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                add     di, offset BoardParams
                mov     word ptr [bp+ParamPtr], di
                mov     word ptr [bp+ParamPtr+2], ds
;
; Check if the destination tile is passable now
;
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
                jnz     short MovePusher
                jmp     DoneTickPusher
; ---------------------------------------------------------------------------

MovePusher:                             ; CODE XREF: TickPusher+10C↑j
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
                mov     ax, 2
                push    ax
                mov     di, offset sndPush
                push    cs
                push    di
                call    PlaySoundPriority ; Not 100% sure on this yet but...
                                        ; Priority: higher priority overwrites the buffer,
                                        ;           -1 is maybe always overwrite?
                                        ; SoundPtr: binary representation in a pascal string
;
; Check if there's a pusher of the same direction behind our old tile
;
                les     di, [bp+ParamPtr]
                mov     ax, es:[di+ParamRecord.StepY]
                shl     ax, 1
                mov     dx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                sub     ax, dx
                shl     ax, 1
                mov     cx, ax
                les     di, [bp+ParamPtr]
                mov     ax, es:[di+ParamRecord.StepX]
                shl     ax, 1
                mov     dx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                sub     ax, dx
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                cmp     byte ptr BoardTopLeft.Type[di], TTPusher
                jnz     short DoneTickPusher
; Get the other pusher's params
                les     di, [bp+ParamPtr]
                mov     ax, es:[di+ParamRecord.StepX]
                shl     ax, 1
                mov     dx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                sub     ax, dx
                push    ax
                les     di, [bp+ParamPtr]
                mov     ax, es:[di+ParamRecord.StepY]
                shl     ax, 1
                mov     dx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                sub     ax, dx
                push    ax
                call    ParamIdxForXY   ; Index for param at (X, Y) or -1 if not found
; Check the direction matches ours
                mov     [bp+UnblockedPusherParamIdx], ax
                mov     ax, [bp+UnblockedPusherParamIdx]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                mov     ax, BoardParams.StepX[di]
                les     di, [bp+ParamPtr]
                cmp     ax, es:[di+ParamRecord.StepX]
                jnz     short DoneTickPusher
                mov     ax, [bp+UnblockedPusherParamIdx]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                mov     ax, BoardParams.StepY[di]
                les     di, [bp+ParamPtr]
                cmp     ax, es:[di+ParamRecord.StepY]
                jnz     short DoneTickPusher
                push    [bp+UnblockedPusherParamIdx]
                call    TileTypes.TickFunction+(size TileType*TTPusher)

DoneTickPusher:                         ; CODE XREF: TickPusher+10E↑j
                                        ; TickPusher+185↑j ...
                mov     sp, bp
                pop     bp
                retf    2
TickPusher      endp
