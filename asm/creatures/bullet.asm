; ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦ S U B R O U T I N E ¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦¦

; Attributes: bp-based frame

TickBullet      proc far                ; DATA XREF: InitTileTypes+442↓o

ParamPtr        = dword ptr -0Ch
CanRicochet     = byte ptr -8
TypeAtNextPos   = byte ptr -7
ObjectParamIdx  = word ptr -6
NextY           = word ptr -4
NextX           = word ptr -2
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
                mov     [bp+CanRicochet], 1
;
; Check if we can move through the next tile
;

TryNext:                                ; CODE XREF: TickBullet+CD↓j
                                        ; TickBullet+1AD↓j ...
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                add     ax, es:[di+ParamRecord.StepX]
                mov     [bp+NextX], ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                add     ax, es:[di+ParamRecord.StepY]
                mov     [bp+NextY], ax
                mov     ax, [bp+NextY]
                shl     ax, 1
                mov     cx, ax
                mov     ax, [bp+NextX]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                mov     al, byte ptr BoardTopLeft.Type[di]
                mov     [bp+TypeAtNextPos], al
                mov     al, [bp+TypeAtNextPos]
                xor     ah, ah
                mov     dx, size TileType
                mul     dx
                mov     di, ax
                cmp     TileTypes.Passable[di], 0
                jnz     short MoveBullet
; Water is not passable but we can still move over it
                cmp     [bp+TypeAtNextPos], TTWater
                jnz     short CheckRicochet
;
: Move into the next tile
;

MoveBullet:                             ; CODE XREF: TickBullet+76↑j
                push    [bp+ParamIdx]
                push    [bp+NextX]
                push    [bp+NextY]
                call    MoveTile
                jmp     DoneTickBullet
; ---------------------------------------------------------------------------
; Bounce off a ricochet

CheckRicochet:                          ; CODE XREF: TickBullet+7C↑j
                cmp     [bp+TypeAtNextPos], TTRicochet
                jnz     short CheckBreakable
                cmp     [bp+CanRicochet], 0
                jz      short CheckBreakable
;
; Ricochet: flip stepX and stepY
;
                les     di, [bp+ParamPtr]
                mov     ax, es:[di+ParamRecord.StepX]
                neg     ax
                les     di, [bp+ParamPtr]
                mov     es:[di+ParamRecord.StepX], ax
                les     di, [bp+ParamPtr]
                mov     ax, es:[di+ParamRecord.StepY]
                neg     ax
                les     di, [bp+ParamPtr]
                mov     es:[di+ParamRecord.StepY], ax
                mov     ax, 1
                push    ax
                mov     di, offset sndRicochet
                push    cs
                push    di
                call    PlaySoundPriority ; Not 100% sure on this yet but...
                                        ; Priority: higher priority overwrites the buffer,
                                        ;           -1 is maybe always overwrite?
                                        ; SoundPtr: binary representation in a pascal string
                mov     [bp+CanRicochet], 0
; Now try to move with the new direction
                jmp     TryNext
; ---------------------------------------------------------------------------
                jmp     DoneTickBullet
; ---------------------------------------------------------------------------
; Breakables aren't "destructible", but can be killed with bullets

CheckBreakable:                         ; CODE XREF: TickBullet+93↑j
                                        ; TickBullet+99↑j
                cmp     [bp+TypeAtNextPos], TTBreakable
                jz      short AttackNextTile
;
; Check if the tile we're blocked by is destructible
;
                mov     al, [bp+TypeAtNextPos]
                xor     ah, ah
                mov     dx, size TileType
                mul     dx
                mov     di, ax
                cmp     TileTypes.Destructible[di], 0
                jz      short CheckClocRicochet
; If we hit the player, just attack; don't check for corner ricochet
                cmp     [bp+TypeAtNextPos], TTPlayer
                jz      short AttackNextTile
; If we're an enemy bullet and hit something destructible that's not the
; player, check for ricochet like we hit something non-destructible
                les     di, [bp+ParamPtr]
                cmp     es:[di+ParamRecord.Param1], SOPlayer
                jnz     short CheckClocRicochet
;
; Check if attacking this tile gives score
;

AttackNextTile:                         ; CODE XREF: TickBullet+D7↑j
                                        ; TickBullet+F0↑j
                mov     al, [bp+TypeAtNextPos]
                xor     ah, ah
                mov     dx, size TileType
                mul     dx
                mov     di, ax
                cmp     TileTypes.Score[di], 0
                jz      short BulletAttacks
;
; Update the score and redraw the sidebar
;
                mov     al, [bp+TypeAtNextPos]
                xor     ah, ah
                mov     dx, size TileType
                mul     dx
                mov     di, ax
                mov     ax, TileTypes.Score[di]
                add     ax, CurrentScore
                mov     CurrentScore, ax
                call    UpdateSideBar

BulletAttacks:                          ; CODE XREF: TickBullet+10D↑j
                push    [bp+ParamIdx]
                push    [bp+NextX]
                push    [bp+NextY]
                call    DieAttackingTile
                jmp     DoneTickBullet
; ---------------------------------------------------------------------------
; Check the clockwise tile for a corner ricochet

CheckClocRicochet:                      ; CODE XREF: TickBullet+EA↑j
                                        ; TickBullet+FA↑j
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                add     ax, es:[di+ParamRecord.StepX]
                shl     ax, 1
                mov     cx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                add     ax, es:[di+ParamRecord.StepY]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                cmp     byte ptr BoardTopLeft.Type[di], TTRicochet
                jnz     short CheckCounRicochet
                cmp     [bp+CanRicochet], 0
                jz      short CheckCounRicochet
                les     di, [bp+ParamPtr]
                mov     ax, es:[di+ParamRecord.StepX]
                mov     [bp+NextX], ax
                les     di, [bp+ParamPtr]
                mov     ax, es:[di+ParamRecord.StepY]
                neg     ax
                les     di, [bp+ParamPtr]
                mov     es:[di+ParamRecord.StepX], ax
                mov     ax, [bp+NextX]
                neg     ax
                les     di, [bp+ParamPtr]
                mov     es:[di+ParamRecord.StepY], ax
                mov     ax, 1
                push    ax
                mov     di, offset sndRicochet
                push    cs
                push    di
                call    PlaySoundPriority ; Not 100% sure on this yet but...
                                        ; Priority: higher priority overwrites the buffer,
                                        ;           -1 is maybe always overwrite?
                                        ; SoundPtr: binary representation in a pascal string
                mov     [bp+CanRicochet], 0
                jmp     TryNext
; ---------------------------------------------------------------------------
                jmp     DoneTickBullet
; ---------------------------------------------------------------------------

CheckCounRicochet:                      ; CODE XREF: TickBullet+16D↑j
                                        ; TickBullet+173↑j
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.Y]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                sub     ax, es:[di+ParamRecord.StepX]
                shl     ax, 1
                mov     cx, ax
                les     di, [bp+ParamPtr]
                mov     al, es:[di+ParamRecord.X]
                xor     ah, ah
                les     di, [bp+ParamPtr]
                sub     ax, es:[di+ParamRecord.StepY]
                mov     dx, BytesPerColumn
                mul     dx
                mov     di, ax
                add     di, cx
                cmp     byte ptr BoardTopLeft.Type[di], TTRicochet
                jnz     short BulletDies
                cmp     [bp+CanRicochet], 0
                jz      short BulletDies
                les     di, [bp+ParamPtr]
                mov     ax, es:[di+2]
                mov     [bp+NextX], ax
                les     di, [bp+ParamPtr]
                mov     ax, es:[di+4]
                les     di, [bp+ParamPtr]
                mov     es:[di+2], ax
                mov     ax, [bp+NextX]
                les     di, [bp+ParamPtr]
                mov     es:[di+4], ax
                mov     ax, 1
                push    ax
                mov     di, offset sndRicochet
                push    cs
                push    di
                call    PlaySoundPriority ; Not 100% sure on this yet but...
                                        ; Priority: higher priority overwrites the buffer,
                                        ;           -1 is maybe always overwrite?
                                        ; SoundPtr: binary representation in a pascal string
                mov     [bp+CanRicochet], 0
                jmp     TryNext
; ---------------------------------------------------------------------------
                jmp     short DoneTickBullet
; ---------------------------------------------------------------------------
;
; Hit an indestructible tile, we die!
;

BulletDies:                             ; CODE XREF: TickBullet+1E4↑j
                                        ; TickBullet+1EA↑j
                push    [bp+ParamIdx]
                call    RemoveParamIdx
                mov     ax, word_2CADA
                dec     ax
                mov     word_2CADA, ax
; If we hit an object or scroll, send it to SHOT
                cmp     [bp+TypeAtNextPos], TTObject
                jz      short SendObjectShot
                cmp     [bp+TypeAtNextPos], TTScroll
                jnz     short DoneTickBullet

SendObjectShot:                         ; CODE XREF: TickBullet+238↑j
                push    [bp+NextX]
                push    [bp+NextY]
                call    ParamIdxForXY   ; Index for param at (X, Y) or -1 if not found
                mov     [bp+ObjectParamIdx], ax
                mov     ax, [bp+ObjectParamIdx]
                neg     ax
                push    ax
                mov     di, offset aShot ; "SHOT"
                push    cs
                push    di
                mov     al, 0
                push    ax
                call    Send
                or      al, al
                jz      short $+2

DoneTickBullet:                         ; CODE XREF: TickBullet+8C↑j
                                        ; TickBullet+D0↑j ...
                mov     sp, bp
                pop     bp
                retf    2
TickBullet      endp
