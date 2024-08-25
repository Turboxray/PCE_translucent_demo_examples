    .bss

    songTrack:          .ds 1
    songTrackLen:       .ds 1

    scrollDirection:    .ds 1

    ghost.pos.x:        .ds 2
    ghost.pos.y:        .ds 2

    ghostOld.pos.x:     .ds 2
    ghostOld.pos.y:     .ds 2

    screen.tile.addr:   .ds 2            

    ghostFrame:         .ds 1
    ghostFrameOld:      .ds 1

    ghostSet:           .ds 1

    frameDelayCounter:  .ds 1
    frameDelayDiv:      .ds 1

    palBuff_0._B:       .ds 256
    palBuff_0._R:       .ds 256
    palBuff_0._G:       .ds 256

    palBuff_1._R:       .ds 256
    palBuff_1._B:       .ds 256
    palBuff_1._G:       .ds 256

    palDelta._R:        .ds 256
    palDelta._B:        .ds 256
    palDelta._G:        .ds 256

    palLimit._R:        .ds 256
    palLimit._B:        .ds 256
    palLimit._G:        .ds 256

    destPalBuff:        .ds 256 * 2

    enableColorDMA:     .ds 1

    fadeCount:          .ds 1
    fadeDirection:      .ds 1
    fadeDelay:          .ds 1
    fadeDelayCNT:       .ds 1

    b_gb_select:        .ds 1


