; ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦ S U B R O U T I N E ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦

; Attributes: bp-based frame

TickBlinkWall   proc far                ; DATA XREF: InitTileTypes+CA7↓o

ParamPtr        = dword ptr -0Eh
RayType         = word ptr -0Ah
PlayerParamIdx  = word ptr -8
StopLoop        = byte ptr -5
DestY           = word ptr -4
DestX           = word ptr -2
ParamIdx        = word ptr  6

                push    bp
                mov     bp, sp
                mov     ax, 0Eh
                call    CheckStack
                sub     sp, 0Eh
                mov     ax, [bp+ParamIdx]
                mov     dx, size ParamRecord
                mul     dx
                mov     di, ax
                add     di, offset BoardParams
                mov     word ptr [bp+ParamPtr], di
                mov     word ptr [bp+ParamPtr+2], ds
                les     di, [bp+ParamPtr]
                cmp     es:[di+ParamRecord.Param3], 0 ; current time
                jnz     short loc_12DB2
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Param1] ; starting time
                xor     ah, ah
                inc     ax
                les     di, [bp+ParamPtr]
                mov     es:[di+ParamRecord.Param3], al ; current time = starting time + 1

loc_12DB2:                              ; CODE XREF: TickBlinkWall+2A↑j
                les     di, [bp+ParamPtr]
                cmp     es:[di+ParamRecord.Param3], 1
                jz      short loc_12DBF
                jmp     DecrementTime
; ---------------------------------------------------------------------------

loc_12DBF:                              ; CODE XREF: TickBlinkWall+45↑j
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                add     ax, es:[di+ParamRecord.StepX]
                mov     [bp+DestX], ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                add     ax, es:[di+ParamRecord.StepY]
                mov     [bp+DestY], ax
                les     di, [bp+ParamPtr]
                cmp     es:[di+ParamRecord.StepX], 0
                jz      short IsVertical
; Direction is horizontal
                mov     [bp+RayType], TTBlinkRayH
                jmp     short EraseRayLoop
; ---------------------------------------------------------------------------
; Direction is vertical

IsVertical:                             ; CODE XREF: TickBlinkWall+77↑j
                mov     [bp+RayType], TTBlinkRayV
;
; Erase a ray of the expected type and color
;

EraseRayLoop:                           ; CODE XREF: TickBlinkWall+7E↑j
                                        ; TickBlinkWall+133↓j
                mov     ax, [bp+DestY]
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+DestX]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                mov     al, byte ptr BoardTopLeft.Type[di]
                xor     ah, ah
                cmp     ax, [bp+RayType]
                jz      short CompareRayColors
                jmp     NotMyRay
; ---------------------------------------------------------------------------
; Get color of this blinkwall

CompareRayColors:                       ; CODE XREF: TickBlinkWall+A1↑j
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
                mov     bl, BoardTopLeft.Color[di]
; Get the color of the destination blink ray
                mov     ax, [bp+DestY]
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+DestX]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                mov     al, BoardTopLeft.Color[di]
                cmp     al, bl
                jnz     short NotMyRay
;
; Ray colors are the same.
; Erase the ray.
;
                mov     ax, [bp+DestY]
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+DestX]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                mov     byte ptr BoardTopLeft.Type[di], TTEmpty
                push    [bp+DestX]
                push    [bp+DestY]
                call    DrawTile
                mov     ax, [bp+DestX]
                les     di, [bp+ParamPtr]
                add     ax, es:[di+ParamRecord.StepX]
                mov     [bp+DestX], ax
                mov     ax, [bp+DestY]
                les     di, [bp+ParamPtr]
                add     ax, es:[di+ParamRecord.StepY]
                mov     [bp+DestY], ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Param2] ; period
                xor     ah, ah
                shl     ax, 1
                inc     ax
                les     di, [bp+ParamPtr]
                mov     es:[di+ParamRecord.Param3], al ; reset timer to period (in 2*ticks) + 1
                jmp     EraseRayLoop
; ---------------------------------------------------------------------------
; If we moved in the X direction but didn't get anywhere, fire immediately

NotMyRay:                               ; CODE XREF: TickBlinkWall+A3↑j
                                        ; TickBlinkWall+E1↑j
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                add     ax, es:[di+ParamRecord.StepX]
                cmp     ax, [bp+DestX]
                jz      short CheckMovedY
                jmp     JumpToEnd
; ---------------------------------------------------------------------------
; If we moved in the Y direction but didn't get anywhere, fire immediately

CheckMovedY:                            ; CODE XREF: TickBlinkWall+148↑j
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                add     ax, es:[di+ParamRecord.StepY]
                cmp     ax, [bp+DestY]
                jz      short loc_12EDA
                jmp     JumpToEnd
; ---------------------------------------------------------------------------

loc_12EDA:                              ; CODE XREF: TickBlinkWall+160↑j
                mov     [bp+StopLoop], 0
;
; Destroy any destructible tiles in the way
;

LoopShootRay:                           ; CODE XREF: TickBlinkWall+369↓j
                mov     ax, [bp+DestY]
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+DestX]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                cmp     byte ptr BoardTopLeft.Type[di], TTEmpty
                jz      short NotDestructible
                mov     ax, [bp+DestY]
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+DestX]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                mov     al, byte ptr BoardTopLeft.Type[di]
                xor     ah, ah
                mov     dx, size TileType
                mul     dx
                mov     di, ax
                cmp     TileTypes.Destructible[di], 0
                jz      short NotDestructible
                push    [bp+DestX]
                push    [bp+DestY]
                call    Destroy
;
; Hurt and move the player if they intersect the ray
;

NotDestructible:                        ; CODE XREF: TickBlinkWall+181↑j
                                        ; TickBlinkWall+1A8↑j
                mov     ax, [bp+DestY]
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+DestX]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                cmp     byte ptr BoardTopLeft.Type[di], TTPlayer
                jz      short HitPlayer
                jmp     TryAddRay
; ---------------------------------------------------------------------------

HitPlayer:                              ; CODE XREF: TickBlinkWall+1CD↑j
                push    [bp+DestX]
                push    [bp+DestY]
                call    ParamIdxForXY   ; Index for param at (X, Y) or -1 if not found
                mov     [bp+PlayerParamIdx], ax
                les     di, [bp+ParamPtr]
                cmp     es:[di+ParamRecord.StepX], 0
                jz      short CheckPlayerE
; check for empty to the north of the player
                mov     ax, [bp+DestY]
                dec     ax
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+DestX]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                cmp     byte ptr BoardTopLeft.Type[di], TTEmpty
                jnz     short CheckPlayerS
; Push player north
                push    [bp+PlayerParamIdx]
                push    [bp+DestX]
                mov     ax, [bp+DestY]
                dec     ax
                push    ax
                call    MoveTileWithIdx
                jmp     short loc_12FB7
; ---------------------------------------------------------------------------
; Check for empty to the south of the player

CheckPlayerS:                           ; CODE XREF: TickBlinkWall+203↑j
                mov     ax, [bp+DestY]
                inc     ax
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+DestX]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                cmp     byte ptr BoardTopLeft.Type[di], TTEmpty
                jnz     short loc_12FB7
; Push player south
                push    [bp+PlayerParamIdx]
                push    [bp+DestX]
                mov     ax, [bp+DestY]
                inc     ax
                push    ax
                call    MoveTileWithIdx

loc_12FB7:                              ; CODE XREF: TickBlinkWall+215↑j
                                        ; TickBlinkWall+230↑j
                jmp     short CheckPlayerStillThere
; ---------------------------------------------------------------------------
; Check for empty to the east of the player

CheckPlayerE:                           ; CODE XREF: TickBlinkWall+1E8↑j
                mov     ax, [bp+DestY]
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+DestX]
                inc     ax
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                cmp     byte ptr BoardTopLeft.Type[di], TTEmpty
                jnz     short CheckPlayerW
; Push player east
                push    [bp+PlayerParamIdx]
                mov     ax, [bp+DestX]
                inc     ax
                push    ax
                push    [bp+DestY]
                call    MoveTileWithIdx
                jmp     short CheckPlayerStillThere
; ---------------------------------------------------------------------------
; Check for empty to the west of the player

CheckPlayerW:                           ; CODE XREF: TickBlinkWall+25D↑j
                mov     ax, [bp+DestY]
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+DestX]
                dec     ax
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                cmp     byte ptr BoardTopLeft.Type[di], TTEmpty
                jnz     short CheckPlayerStillThere
; BUG: push player east; should be west
                push    [bp+PlayerParamIdx]
                mov     ax, [bp+DestX]
                inc     ax
                push    ax
                push    [bp+DestY]
                call    MoveTileWithIdx

CheckPlayerStillThere:                  ; CODE XREF: TickBlinkWall:loc_12FB7↑j
                                        ; TickBlinkWall+26F↑j ...
                mov     ax, [bp+DestY]
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+DestX]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                cmp     byte ptr BoardTopLeft.Type[di], TTPlayer
                jnz     short TryAddRay
;
; Drain player's health until they're dead
;

KillPlayer:                             ; CODE XREF: TickBlinkWall+2C5↓j
                cmp     CurrentHealth, 0
                jle     short DoneKillingPlayer
                push    [bp+PlayerParamIdx]
                call    Attack
                jmp     short KillPlayer
; ---------------------------------------------------------------------------

DoneKillingPlayer:                      ; CODE XREF: TickBlinkWall+2BB↑j
                mov     [bp+StopLoop], 1
;
; Try adding rays until we hit a non-empty tile
;

TryAddRay:                              ; CODE XREF: TickBlinkWall+1CF↑j
                                        ; TickBlinkWall+2B4↑j
                mov     ax, [bp+DestY]
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+DestX]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                cmp     byte ptr BoardTopLeft.Type[di], TTEmpty
                jnz     short RayHitEnd
; Set tile type to ray
                mov     bl, byte ptr [bp+RayType]
                mov     ax, [bp+DestY]
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+DestX]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                mov     byte ptr BoardTopLeft.Type[di], bl
; Get this blinkwall's color
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
                mov     bl, BoardTopLeft.Color[di]
; Set the ray's color
                mov     ax, [bp+DestY]
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+DestX]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                mov     BoardTopLeft.Color[di], bl
                push    [bp+DestX]
                push    [bp+DestY]
                call    DrawTile
                jmp     short PrepareNextLoop
; ---------------------------------------------------------------------------

RayHitEnd:                              ; CODE XREF: TickBlinkWall+2E3↑j
                mov     [bp+StopLoop], 1

PrepareNextLoop:                        ; CODE XREF: TickBlinkWall+343↑j
                mov     ax, [bp+DestX]
                les     di, [bp+ParamPtr]
                add     ax, es:[di+ParamRecord.StepX]
                mov     [bp+DestX], ax
                mov     ax, [bp+DestY]
                les     di, [bp+ParamPtr]
                add     ax, es:[di+ParamRecord.StepY]
                mov     [bp+DestY], ax
                cmp     [bp+StopLoop], 0
                jnz     short DoneLoop
                jmp     LoopShootRay
; ---------------------------------------------------------------------------

DoneLoop:                               ; CODE XREF: TickBlinkWall+367↑j
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Param2] ; period
                xor     ah, ah
                shl     ax, 1
                inc     ax              ; 2*period + 1
                les     di, [bp+ParamPtr]
                mov     es:[di+ParamRecord.Param3], al

JumpToEnd:                              ; CODE XREF: TickBlinkWall+14A↑j
                                        ; TickBlinkWall+162↑j
                jmp     short EndTickBlinkWall
; ---------------------------------------------------------------------------

DecrementTime:                          ; CODE XREF: TickBlinkWall+47↑j
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Param3]
                xor     ah, ah
                dec     ax
                les     di, [bp+ParamPtr]
                mov     es:[di+ParamRecord.Param3], al

EndTickBlinkWall:                       ; CODE XREF: TickBlinkWall:JumpToEnd↑j
                mov     sp, bp
                pop     bp
                retf    2
TickBlinkWall   endp


; ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦ S U B R O U T I N E ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦
