; enum Constants
BytesPerColumn   = 36h
FiringRateStarMask  = 80h

; ---------------------------------------------------------------------------

; enum TileTypeIndex
TTEmpty          = 0
TTBoardEdge      = 1
TTMessenger      = 2
TTMonitor        = 3
TTPlayer         = 4
TTAmmo           = 5
TTTorch          = 6
TTGem            = 7
TTKey            = 8
TTDoor           = 9
TTScroll         = 0Ah
TTPassage        = 0Bh
TTDuplicator     = 0Ch
TTBomb           = 0Dh
TTEnergizer      = 0Eh
TTStar           = 0Fh
TTClockwise      = 10h
TTCounterCW      = 11h
TTBullet         = 12h
TTWater          = 13h
TTForest         = 14h
TTSolid          = 15h
TTNormal         = 16h
TTBreakable      = 17h
TTBoulder        = 18h
TTSliderNS       = 19h
TTSliderTW       = 1Ah
TTFake           = 1Bh
TTInvisible      = 1Ch
TTBlinkWall      = 1Dh
TTTransporter    = 1Eh
TTLine           = 1Fh
TTRicochet       = 20h
TTBlinkRayH      = 21h
TTBear           = 22h
TTRuffian        = 23h
TTObject         = 24h
TTSlime          = 25h
TTShark          = 26h
TTSpinningGun    = 27h
TTPusher         = 28h
TTLion           = 29h
TTTiger          = 2Ah
TTBlinkRayV      = 2Bh
TTHead           = 2Ch
TTSegment        = 2Dh
TTBlueText       = 2Fh
TTGreenText      = 30h
TTCyanText       = 31h
TTRedText        = 32h
TTPurpleText     = 33h
TTBrownText      = 34h
TTBlackText      = 35h

; ---------------------------------------------------------------------------

Tile            struc ; (sizeof=0x2)
Type            db ?
Color           db ?
Tile            ends

; ---------------------------------------------------------------------------

ParamRecord     struc ; (sizeof=0x21)
X               db ?
Y               db ?
StepX           dw ?
StepY           dw ?
Cycle           dw ?
Param1          db ?
Param2          db ?
Param3          db ?
Follower        dw ?
Leader          dw ?
UnderType       db ?
UnderColor      db ?
Code            dd ?
InstructionPtr  dw ?
Length          dw ?
field_19        dd ?                    ; Unknown field 1
field_1D        dd ?                    ; Unknown field 2
ParamRecord     ends

; ---------------------------------------------------------------------------

TileType        struc ; (sizeof=0xC3)
Character       db ?
Color           db ?
Destructible    db ?
field_3         db ?
field_4         db ?
field_5         db ?
Passable        db ?                    ; 0=blocks player, 1=passable
field_7         db ?
field_8         dw ?
field_A         dw ?
field_C         dw ?
TickFunction    dd ?
TouchFunction   dd ?
EditorPage      dw ?
EditorKey       db ?
Name            db 21 dup(?)            ; string(pascal)
EditorSection   db 21 dup(?)            ; string(pascal)
Param1Prompt    db 21 dup(?)            ; string(pascal)
Param2Prompt    db 21 dup(?)            ; string(pascal)
Param3Prompt    db 21 dup(?)            ; string(pascal)
field_82        db 21 dup(?)            ; string(pascal)
field_97        db 21 dup(?)            ; string(pascal)
field_AC        db 21 dup(?)            ; string(pascal)
Score           dw ?
TileType        ends

; ---------------------------------------------------------------------------

; enum ShootOwner
SOPlayer         = 0
SOEnemy          = 1

