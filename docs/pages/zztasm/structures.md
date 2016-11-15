---
title: Structures
sidebar: zztasm_sidebar
permalink: structures.html
---


## Definitions

These data types will be used to define the notable memory structures in ZZT:

| Type        | Description                                                              |
|-------------+--------------------------------------------------------------------------|
| `bool`      | Boolean (typically the Z flag)                                           |
| `uint8`     | Unsigned 8 bit integer                                                   |
| `int16`     | Signed 16 bit integer                                                    |
| `void*`     | 32 bit pointer                                                           |
| `string[n]` | Pascal string (uint8 length field followed by an *n*-byte string buffer) |



## Tile

A board in ZZT is composed of 60x25 tiles.  In memory, ZZT provides 1 tile of border around
the visible board, making the total size of the board in memory 62x27 tiles.  The tiles are
laid out in [column-major order][ordering] in memory.

{% include asmlink.html file="constants.asm" line="64" %}

```
struct Tile {
    uint8 Type   // Tile type code
    uint8 Color  // Foreground in low nybble, background in high nybble
}

global Tile[62*27] BoardTiles
global Tile* BoardTopLeft = BoardTiles + 28  // Skip 1 column and 1 row
```

[ordering]: https://en.wikipedia.org/wiki/Column-major_order


## Parameter Record

This record stores the parameters for every interactive object on the board, including the
player.  In ZZT, there is a maximum of 151 parameter records per board.

{% include asmlink.html file="constants.asm" line="71" %}

```
struct ParamRecord {
    uint8 X                 // X coordinate, 1 is left
    uint8 Y                 // Y coordinate, 1 is top
    int16 StepX             // Direction of motion on the X axis
    int16 StepY             // Direction of motion on the Y axis
    int16 Cycle             // Duty cycle for ticks 1=tick every game tick
    uint8 Param1            // Depends on tile type
    uint8 Param2            // Depends on tile type
    uint8 Param3            // Depends on tile type
    int16 Follower          // Centipede follower BoardParams index
    int16 Leader            // Centipede leader BoardParams index
    uint8 UnderType         // Tile type under this tile
    uint8 UnderColor        // Tile color under this tile
    void* Code              // Pointer to object/scroll code during execution
    int16 InstructionPtr    // Offset into code for current object instruction
    int16 Length            // Length of Code
    void* field_19          // Unknown field 1
    void* field_1D          // Unknown field 2
}

global ParamRecord[151] BoardParams

global uint8* PlayerX = BoardParams[0].X
global uint8* PlayerY = BoardParams[0].Y
```


## Tile Info

This structure contains details about each tile type.  There are 54 different tile types in
ZZT.

{% include asmlink.html file="constants.asm" line="93" %}

```
struct TileType {
    uint8      Character        // Tile character
    uint8      Color            // Tile color
    uint8      Destructible     // If the tile can be destroyed
    uint8      Pushable         // If the tile can be pushed
    uint8      field_4
    uint8      DefaultColor     // Default color flag
    uint8      Passable         // 0=blocks player, 1=passable
    uint8      field_7
    void*      DrawFunction
    int16      field_C
    void*      TickFunction     // Pointer to tick function
    void*      TouchFunction    // Pointer to touch function
    int16      EditorPage       // Editor menu page number
    uint8      EditorKey        // Editor menu key
    string[20] Name             // Tile name
    string[20] EditorSection    // Editor section header
    string[20] Param1Prompt     // Prompt for editing Param1
    string[20] Param2Prompt     // Prompt for editing Param2
    string[20] Param3Prompt     // Prompt for editing Param3
    string[20] field_82
    string[20] field_97
    string[20] field_AC
    int16      Score            // Score to give when killed
}

global TileType[54] TileTypes
```

{% include links.html %}
