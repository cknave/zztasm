In a perfect world, an IDC script could generate these ASM files.  As it is, I'm copy pasting
them from IDA pro and cleaning them up with vim:

1. Clear out address column:

    gg<C-v>G11lx

2. Fix arrow encoding:

    :%s/\%x18/↑/g
    :%s/\%x19/↓/g

This can be combined into a single `FormatZZT` command:

    command FormatZZT execute 'normal gg<C-v>G11lx' | :%s/\%x18/↑/g | :%s/\%x19/↓/g
