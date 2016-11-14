TickDuplicator  proc far                ; DATA XREF: InitTileTypes+663↓o

ParamPtr        = dword ptr -6
SourceParamIdx  = word ptr -2
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
; Cycle through 5 frames of animation before duplicating
;
                cmp     es:[di+ParamRecord.Param1], 4 ; frame
                ja      short CheckPlayerAtDest
; Increment frame number
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Param1]
                xor     ah, ah
                inc     ax
                les     di, [bp+ParamPtr]
                mov     es:[di+ParamRecord.Param1], al
; Redraw this tile
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                push    ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                push    ax
                call    DrawTile
                jmp     DoneTickDuplicator
; ---------------------------------------------------------------------------
;
; Check if the player is at the destination tile
;

CheckPlayerAtDest:                      ; CODE XREF: TickDuplicator+2A↑j
                les     di, [bp+ParamPtr]
                mov     es:[di+ParamRecord.Param1], 0 ; frame
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                sub     ax, es:[di+ParamRecord.StepY]
                shl     ax, 1
                mov     cx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                sub     ax, es:[di+ParamRecord.StepX]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                cmp     byte ptr BoardTopLeft.Type[di], TTPlayer
                jnz     short CheckEmptyAtDest
;
; Send a touch from the player to the duplicator source
;
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
                xor     ax, ax
                push    ax
                mov     di, offset TouchRelated1 ; not sure what this is but it's related to touch functions
                push    ds
                push    di
                mov     di, offset TouchRelated2 ; not sure what this is but it's related to touch functions
                push    ds
                push    di
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
                call    TileTypes.TouchFunction[di]
                jmp     DoneDuplicating
; ---------------------------------------------------------------------------

CheckEmptyAtDest:                       ; CODE XREF: TickDuplicator+91↑j
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                sub     ax, es:[di+ParamRecord.StepY]
                shl     ax, 1
                mov     cx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                sub     ax, es:[di+ParamRecord.StepX]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                cmp     byte ptr BoardTopLeft.Type[di], TTEmpty
                jz      short CheckEmptyAgain
;
; Destination is not empty.  Try pushing it out of the way.
;
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                sub     ax, es:[di+ParamRecord.StepX]
                push    ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                sub     ax, es:[di+ParamRecord.StepY]
                push    ax
                les     di, [bp+ParamPtr]
                mov     ax, es:[di+ParamRecord.StepX]
                neg     ax
                push    ax
                les     di, [bp+ParamPtr]
                mov     ax, es:[di+ParamRecord.StepY]
                neg     ax
                push    ax
                push    cs
                call    near ptr TryPush ; Try pushing the tile at X,Y in direction StepX,StepY

CheckEmptyAgain:                        ; CODE XREF: TickDuplicator+132↑j
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                sub     ax, es:[di+ParamRecord.StepY]
                shl     ax, 1
                mov     cx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                sub     ax, es:[di+ParamRecord.StepX]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                cmp     byte ptr BoardTopLeft.Type[di], TTEmpty
                jz      short DestIsEmpty
                jmp     PlayBlockedSound
; ---------------------------------------------------------------------------
;
; Check if the source tile has a parameter record
;

DestIsEmpty:                            ; CODE XREF: TickDuplicator+19E↑j
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
                call    ParamIdxForXY   ; Index for param at (X, Y) or -1 if not found
                mov     [bp+SourceParamIdx], ax
                cmp     [bp+SourceParamIdx], 0
                jg      short CheckParamCount
                jmp     CheckZeroIdx
; ---------------------------------------------------------------------------
;
; Check if the param count is less than 174.
; (It always is because the max is 150.)
;

CheckParamCount:                        ; CODE XREF: TickDuplicator+1D0↑j
                cmp     BoardParamCount, 0AEh ; '«'
                jl      short DupBySpawn
                jmp     FinishedSpawn
; ---------------------------------------------------------------------------
;
; Duplicate by spawning a new tile
;

DupBySpawn:                             ; CODE XREF: TickDuplicator+1DB↑j
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                sub     ax, es:[di+ParamRecord.StepX]
                push    ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                sub     ax, es:[di+ParamRecord.StepY]
                push    ax
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
                push    ax
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
                mov     al, BoardTopLeft.Color[di]
                xor     ah, ah
                push    ax
                mov     ax, [bp+SourceParamIdx]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                push    BoardParams.Cycle[di]
                mov     ax, [bp+SourceParamIdx]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                add     di, offset BoardParams
                push    ds
                push    di
                call    Spawn
; Draw the destination tile
; Spawn already does this but not if Y=0
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                sub     ax, es:[di+ParamRecord.StepX]
                push    ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                sub     ax, es:[di+ParamRecord.StepY]
                push    ax
                call    DrawTile

FinishedSpawn:                          ; CODE XREF: TickDuplicator+1DD↑j
                jmp     PlayDupSound
; ---------------------------------------------------------------------------
;
; If the player is at the source, don't duplicate
;

CheckZeroIdx:                           ; CODE XREF: TickDuplicator+1D2↑j
                cmp     [bp+SourceParamIdx], 0
                jnz     short DupByCopy
                jmp     PlayDupSound
; ---------------------------------------------------------------------------
; Copy the full tile from the source to the destination

DupByCopy:                              ; CODE XREF: TickDuplicator+2B5↑j
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
                mov     bx, BoardTopLeft[di]
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                sub     ax, es:[di+ParamRecord.StepY]
                shl     ax, 1
                mov     cx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                sub     ax, es:[di+ParamRecord.StepX]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                mov     BoardTopLeft[di], bx
; Redraw the destination tile
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                sub     ax, es:[di+ParamRecord.StepX]
                push    ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                sub     ax, es:[di+ParamRecord.StepY]
                push    ax
                call    DrawTile

PlayDupSound:                           ; CODE XREF: TickDuplicator:FinishedSpawn↑j
                                        ; TickDuplicator+2B7↑j
                mov     ax, 3
                push    ax
                mov     di, offset sndDup
                push    cs
                push    di
                call    PlaySoundPriority ; Not 100% sure on this yet but...
                                        ; Priority: higher priority overwrites the buffer,
                                        ;           -1 is maybe always overwrite?
                                        ; SoundPtr: binary representation in a pascal string
                jmp     short DoneDuplicating
; ---------------------------------------------------------------------------

PlayBlockedSound:                       ; CODE XREF: TickDuplicator+1A0↑j
                mov     ax, 3
                push    ax
                mov     di, offset sndBlocked
                push    cs
                push    di
                call    PlaySoundPriority ; Not 100% sure on this yet but...
                                        ; Priority: higher priority overwrites the buffer,
                                        ;           -1 is maybe always overwrite?
                                        ; SoundPtr: binary representation in a pascal string

DoneDuplicating:                        ; CODE XREF: TickDuplicator+FE↑j
                                        ; TickDuplicator+34E↑j
                les     di, [bp+ParamPtr]
                mov     es:[di+ParamRecord.Param1], 0
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                push    ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                push    ax
                call    DrawTile
; Cycle = (9 - Rate) * 3
; i.e. duplication rates range from 3 to 24 cycles

DoneTickDuplicator:                     ; CODE XREF: TickDuplicator+55↑j
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Param2] ; duplication rate
                xor     ah, ah
                mov     dx, ax
                mov     ax, 9
                sub     ax, dx
                mov     cx, 3
                imul    cx
                les     di, [bp+ParamPtr]
                mov     es:[di+ParamRecord.Cycle], ax
                mov     sp, bp
                pop     bp
                retf    2
TickDuplicator  endp
