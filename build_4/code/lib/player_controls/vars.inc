


  .bss

    player.state:           .ds 1           ; State of animation
                                            ; bits 0-3:
                                            ;     0 = standing
                                            ;     1 = walking
                                            ;     2 = block
                                            ;     3 = jump_up
                                            ;     4 = fall_down
                                            ;     5 = attack
                                            ;     6 = attack_up
                                            ;     7 = hurt
                                            ;     8 = dead
                                            ;     9 = landed
                                            ;
                                            ; bits 4
                                            ;     0 = continue animation state
                                            ;     1 = exit animation state
                                            ;
                                            ; bits 5
                                            ;     0 = movement left
                                            ;     1 = movement right
                                            ;
                                            ; bits 6 ; Can not transition into another state from player input when the state is locked.
                                            ;     0 = locked
                                            ;     1 = unlocked
                                            ;
                                            ; bits 7
                                            ;     0 = face left
                                            ;     1 = face right
                                            ;

    player.state.hi:          .ds 1         ; State of player
                                            ; bits 0-2:   "what the player is standing on.."
                                            ;           0 = not on tile
                                            ;           1 = on normal tile
                                            ;           2 = on partial slope tile
                                            ;           3 = on slope tile
                                            ;           4 = moving platform
                                            ;           5 = on spike
                                            ;           6 = Reserved
                                            ;           7 = Reserved
                                            ;
                                            ; bits 3-7: Reserved
                                            ;

    player.state.sub:         .ds 1           ; single level stack. I.e. jump + attack; jump state pushed to sub, while attack carried out.
    player.frame:             .ds 1
    player.frame.accel.idx:   .ds 2
    player.frame.ptr:         .ds 1
    player.frame.counter:     .ds 1
    player.state.counter:     .ds 1
    player.health:            .ds 1
    player.lives:             .ds 1
    player.coins:             .ds 2

    player.position.x.frac:   .ds 1
    player.position.x:        .ds 2
    player.position.y.frac:   .ds 1
    player.position.y:        .ds 2
    player.adjusted.x:        .ds 2
    player.adjusted.y:        .ds 2
    player.camera.x:          .ds 2
    player.camera.y:          .ds 2
    player.attribs:           .ds 2


