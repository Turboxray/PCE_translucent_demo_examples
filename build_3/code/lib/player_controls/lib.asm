    ;tab
    ;
    ;
    ;

;............................................
;
PlayerControls.Init:
    ; Complete the new state status
        lda player.state
        and #$80+$20
        ora #player.stand
        sta player.state

        ; New animation.. start off with the first frame
        stz player.frame
        stz player.frame.counter
        stz player.state.counter

  rts

;............................................
;
UpdatePlayer.Logic:


player.x.speed = 3
player.y.speed = 3


.debug001
        lda input_state.directions
        and #control.rh.mask
        cmp #control.rh.held
      bne .do_left

.do_right
        jsr UpdatePlayer.collisionRight
        ADD.w <Map.col.obj.return.posX, player.position.x
        jsr UpdatePlayer.LevelMapBoundaries.check
        bra .update

.do_left
        lda input_state.directions
        and #control.lf.mask
        cmp #control.lf.held
      bne .update

        jsr UpdatePlayer.collisionLeft
        ADD.w <Map.col.obj.return.posX, player.position.x
        jsr UpdatePlayer.LevelMapBoundaries.check

.update


        jsr UpdatePlayer.state


.scroll.check.x
        CMP.w player.position.x, #104
      bcs .scrollMap.x

        MOVE.w player.position.x, player.adjusted.x
        ADD.w #32, player.adjusted.x
        MOVE.w player.adjusted.x, player.camera.x
        MOVE.w #0, map.x
        bra .scroll.check.y
.scrollMap.x
        MOVE.w #104, player.adjusted.x
        ADD.w #32, player.adjusted.x
        MOVE.w player.adjusted.x, player.camera.x
        MOVE.w player.position.x, map.x
        ADD.w #-$68, map.x
        bra .scroll.check.y

.scroll.check.y

        CMP.w player.position.y, #400
      bcs .move.char
        bra .scrollMap.y

.move.char
        MOVE.w player.position.y, player.adjusted.y
        ADD.w #64, player.adjusted.y
        MOVE.w player.adjusted.y, player.camera.y
        SUB.w map.y, player.camera.y
        bra .scroll.out
.scrollMap.y
        MOVE.w #64, player.adjusted.y
        ADD.w #64, player.adjusted.y
        MOVE.w player.adjusted.y, player.camera.y
        MOVE.w player.position.y, map.y
        ADD.w #-64, map.y


.scroll.out
        MOVE.w #$00, map.x.delta
        MOVE.w #$00, map.y.delta

  rts

;............................................
UpdatePlayer.collisionDown

        MOVE.w #player.y.speed, <Map.col.obj.offsetY
        MOVE.w #player.y.speed, <Map.col.obj.return.posY
        MOVE.w #0, <Map.col.obj.offsetX
        jsr UpdatePlayer.CheckHoriCollision
    rts



;............................................
UpdatePlayer.collisionUp

        MOVE.w #-player.y.speed, <Map.col.obj.offsetY
        MOVE.w #-player.y.speed, <Map.col.obj.return.posY
        MOVE.w #0, <Map.col.obj.offsetX
        jsr UpdatePlayer.CheckHoriCollision
    rts


;............................................
UpdatePlayer.collisionRight

        MOVE.w #0, <Map.col.obj.offsetY
        MOVE.w #player.x.speed, <Map.col.obj.offsetX
        jsr UpdatePlayer.CheckHoriCollision
    rts


;............................................
UpdatePlayer.collisionLeft

        MOVE.w #0, <Map.col.obj.offsetY
        MOVE.w #-player.x.speed, <Map.col.obj.offsetX
        jsr UpdatePlayer.CheckHoriCollision
    rts


UpdatePlayer.CheckHoriCollision

        MOVE.w player.position.x, <Map.col.obj.posX
        MOVE.w player.position.y, <Map.col.obj.posY
        call Map.collisionCheck
        lda <Map.col.collisionDetection
        cmp #$00
    rts


;............................................
;
UpdatePlayer.state:

        lda player.state
        and #$0f
        cmp #player.jump
      beq .do.UpdatePlayer.state
        cmp #player.fall
      beq .do.UpdatePlayer.state
        cmp #player.dead
      beq .do.UpdatePlayer.state

.do.Gravity_check
        ; NOTE: This just checks of a tile is underneath the player or not.
        ; This really needs to be updated and consolidated into the main check.
        jsr UpdatePlayer.collisionDown
      bne .do.UpdatePlayer.state
        lda player.state
        and #$80+$20
        ora #player.fall
        sta player.state
        stz player.frame
        bra .do.UpdatePlayer.state

.do.UpdatePlayer.state
        ;check current state
        lda player.state
        and #$0f
        asl a
        tax
        jmp [.tbl,x]

.tbl
    .dw   .stand, .walk, .block, .jump_up
    .dw   .fall_down, .attack, .attack_up, .hurt
    .dw   .dead, .land, .null, .null
    .dw   .null, .null, .null, .null





;...........................
.null

  rts


;...........................
.stand

        lda input_state.directions
      beq .stand.no_directions_check_buttons

; Directions pressed.. check buttons first
.stand.check.b1
        lda input_state.buttons
        and #control.b1.mask
        cmp #control.b1.pressed
      bne .stand.check.b2
        jmp .stand.prep_jump
.stand.check.b2
        lda input_state.buttons
        and #control.b2.mask
        cmp #control.b2.pressed
      bne .stand.check.st
        jmp .stand.prep_attack
.stand.check.st
        bit #control.st.held
      beq .stand.check.sl
        jmp .remain_standing
.stand.check.sl
        bit #control.sl.held
      beq .stand.check.directions
        jmp .remain_standing


; No buttons pressed.. check directions
.stand.check.directions
        lda input_state.directions
.stand.check.up
        bit #control.up.held
      beq .stand.check.dn
        jmp .remain_standing
.stand.check.dn
        bit #control.dn.held
      beq .stand.check.lf
        jmp .stand.prep_block
.stand.check.lf
        bit #control.lf.held
      beq .stand.check.rh
        jmp .stand.prep_walk
.stand.check.rh
        bit #control.rh.held
      beq .remain_standing
        jmp .stand.prep_walk

;Nothing was pressed
.stand.no_directions_check_buttons

.stand.no_directions_check.b1
        lda input_state.buttons
        and #control.b1.mask
        cmp #control.b1.pressed
      bne .stand.no_directions_check.b2
        jmp .stand.prep_jump
.stand.no_directions_check.b2
        lda input_state.buttons
        and #control.b2.mask
        cmp #control.b2.pressed
      bne .stand.no_directions_check.st
        jmp .stand.prep_attack
.stand.no_directions_check.st
        lda input_state.buttons
        bit #control.st.held
      beq .stand.no_directions_check.sl
        jmp .remain_standing
.stand.no_directions_check.sl
        bit #control.sl.held
      beq .remain_standing
        jmp .remain_standing

.remain_standing
        ;TODO do counter and frame update
  rts

.stand.prep_block

        ; Complete the new state status
        lda player.state
        and #$80+$20
        ora #player.block
        sta player.state

        ; New animation.. start off with the first frame
        stz player.frame
        stz player.frame.counter
        stz player.state.counter

  rts


.stand.prep_jump

        ; Complete the new state status
        lda player.state
        and #$80+$20
        ora #player.jump
        sta player.state

        ; New animation.. start off with the first frame
        stz player.frame
        stz player.frame.counter
        stz player.state.counter
        MOVE.b #$03, <_hk.EAX0.l
        MOVE.b #%00000001, <_hk.EAX0.m
        HuTrack.CallFar HuTrackEngine.playSFX

  rts

.stand.prep_attack

        ; Complete the new state status
        lda input_state.directions
        bit #control.up.held
      beq .stand.prep_attack.attack
        lda player.state
        and #$80+$20
        ora #player.attack_up
        sta player.state
        stz player.frame
        MOVE.b #$01, <_hk.EAX0.l
        MOVE.b #%00000001, <_hk.EAX0.m
        HuTrack.CallFar HuTrackEngine.playSFX
      bra .stand.prep_attack.cont

.stand.prep_attack.attack
        lda player.state
        and #$80+$20
        ora #player.attack
        sta player.state
        stz player.frame
        MOVE.b #$02, <_hk.EAX0.l
        MOVE.b #%00000001, <_hk.EAX0.m
        HuTrack.CallFar HuTrackEngine.playSFX

.stand.prep_attack.cont
        ; New animation.. start off with the first frame
        stz player.frame
        stz player.frame.counter
        stz player.state.counter

  rts

.stand.prep_walk

        ; Set the facing/moving direction
        stz <D0
        lda input_state.directions
        bit #control.rh.held
      beq .stand.prep_walk.cont
        lda #$80 + $20
        sta <D0

.stand.prep_walk.cont

        ; Complete the new state status
        lda #player.walk
        ora <D0
        sta player.state

        ; New animation.. start off with the first frame
        stz player.frame
        stz player.frame.counter
        stz player.state.counter

  rts




;...........................
.walk

        lda input_state.directions
      beq .walk.no_directions_check_buttons

; still check buttons first
        lda input_state.buttons
      beq .walk.continue_directions
.walk.check.button1
        and #control.b1.mask
        cmp #control.b1.pressed
      bne .walk.check.button2
        jmp .walk.prep_jump
.walk.check.button2
        lda input_state.buttons
        and #control.b2.mask
        cmp #control.b2.pressed
      bne .walk.continue_directions
        jmp .walk.prep_attack


.walk.continue_directions
        lda input_state.directions
.walk.check.lf
        bit #control.lf.held
      beq .walk.check.rh
        jmp .walk.remain.left
.walk.check.rh
        bit #control.rh.held
      beq .walk.check.dn
        jmp .walk.remain.right
.walk.check.dn
        bit #control.dn.held
      beq .walk.prep_stand
        jmp .walk.prep_block


.walk.no_directions_check_buttons
        lda input_state.buttons
      beq .walk.prep_stand
.walk.no_directions_check.button1
        and #control.b1.mask
        cmp #control.b1.pressed
      bne .walk.check.button2
        jmp .walk.prep_jump
.walk.no_directions_check.button2
        lda input_state.buttons
        and #control.b2.mask
        cmp #control.b2.pressed
      bne .walk.prep_stand
        jmp .walk.prep_attack

.walk.remain.left
        lda player.state
        and #$3f
        sta player.state
        bra .walk.remain

.walk.remain.right
        lda player.state
        ora #$80
        sta player.state


.walk.remain

  rts


.walk.prep_stand

        ; Complete the new state status
        lda player.state
        and #$80+$20
        ora #player.stand
        sta player.state

        ; New animation.. start off with the first frame
        stz player.frame
        stz player.frame.counter
        stz player.state.counter

  rts

.walk.prep_block

        ; Complete the new state status
        lda player.state
        and #$80+$20
        ora #player.block
        sta player.state

        ; New animation.. start off with the first frame
        stz player.frame
        stz player.frame.counter
        stz player.state.counter

  rts

.walk.prep_jump

        ; Complete the new state status
        lda player.state
        and #$80+$20
        ora #player.jump
        sta player.state

        ; New animation.. start off with the first frame
        stz player.frame
        stz player.frame.counter
        stz player.state.counter

        MOVE.b #$03, <_hk.EAX0.l
        MOVE.b #%00000001, <_hk.EAX0.m
        HuTrack.CallFar HuTrackEngine.playSFX

  rts

.walk.prep_attack

        ; Complete the new state status
        lda player.state
        and #$80+$20
        ora #player.attack
        sta player.state

        ; New animation.. start off with the first frame
        stz player.frame
        stz player.frame.counter
        stz player.state.counter

        MOVE.b #$00, <_hk.EAX0.l
        MOVE.b #%00000001, <_hk.EAX0.m
        HuTrack.CallFar HuTrackEngine.playSFX
  rts

;...........................
.block
        lda input_state.directions
      beq .block.prep_stand

.block.check.dn
        bit #control.dn.held
      beq .block.prep_stand
        jmp .block.remaining


.block.prep_stand
        ; Complete the new state status
        lda player.state
        and #$80+$20
        ora #player.stand
        sta player.state

        ; New animation.. start off with the first frame
        stz player.frame
        stz player.frame.counter
        stz player.state.counter

  rts

.block.remaining

  rts


;...........................
.jump_up

.jump_up.check.directions
        lda input_state.directions
.jump_up.check.lf
        bit #control.lf.held
      beq .jump_up.check.rh
        lda player.state
        and #$3f
        sta player.state
.jump_up.check.rh
        bit #control.rh.held
      beq .jump_up.continue
        lda player.state
        ora #$80
        sta player.state

.jump_up.continue
        inc player.state.counter
        lda player.state.counter
        cmp #24
      bcs .jump_up.prep_fall_down

.jump_up.check_buttons
        lda input_state.buttons
        and #control.b1.mask
.jump_up.check.not_held
      beq .jump_up.prep_fall_down


        jsr UpdatePlayer.collisionUp
          php
        ADD.w <Map.col.obj.return.posX, player.position.x
        ADD.w <Map.col.obj.return.posY, player.position.y
        jsr UpdatePlayer.LevelMapBoundaries.check
          plp
      bne .jump_up.prep_fall_down


.jump_up.do_accel.skip

  rts

.jump_up.prep_fall_down
        stz player.frame.accel.idx
        lda player.state
        and #$80+$20
        ora #player.fall
        sta player.state
        stz player.state.counter

  rts




;......
.jump_up.accel.table.frac
    .dwl $0110, $0190, $0210, $0245
.jump_up.accel.table
    .dwh $0110, $0190, $0210, $0245
.jump_up.accel.table.size = .jump_up.accel.table - .jump_up.accel.table.frac

.jump_up.decel.table.frac
    .dwl $0245, $0245, $0160, $0090
.jump_up.decel.table
    .dwh $0245, $0245, $0160, $0090

;...........................
.fall_down

.fall_down.check.directions
        lda input_state.directions
.fall_down.check.lf
        bit #control.lf.held
      beq .fall_down.check.rh
        lda player.state
        and #$3f
        sta player.state
.fall_down.check.rh
        bit #control.rh.held
      beq .fall_down.continue
        lda player.state
        ora #$80
        sta player.state

.fall_down.continue
        jsr UpdatePlayer.collisionDown
          php
        ADD.w <Map.col.obj.return.posX, player.position.x
        ADD.w <Map.col.obj.return.posY, player.position.y
        jsr UpdatePlayer.LevelMapBoundaries.check
          plp
      bne .fall_down.prep_stand

.fall_down.skip

  rts

.fall_down.prep_stand
        stz player.frame.accel.idx
        stz player.frame
        lda player.state
        and #$80+$20
        ora player.stand
        sta player.state
  rts


;...........................
.attack

  rts


;...........................
.attack_up

  rts


;...........................
.hurt

  rts


;...........................
.dead

  rts


;...........................
.land

  rts



; .update

  rts


;............................................
;
UpdatePlayer.animation:




;............................................
;
UpdatePlayer.LevelMapBoundaries.check

        CMP.w player.position.x, map.width.pixels
      bcc .UpdatePlayer.LevelMapBoundaries.check.skip0
        MOVE.w map.width.pixels, player.position.x
        SUB.w #10, player.position.x

.UpdatePlayer.LevelMapBoundaries.check.skip0
        CMP.w player.position.x, #$fff0
      bcc .UpdatePlayer.LevelMapBoundaries.check.skip1
        MOVE.w #$00, player.position.x

.UpdatePlayer.LevelMapBoundaries.check.skip1

        CMP.w player.position.y, map.height.pixels
      bcc .UpdatePlayer.LevelMapBoundaries.check.skip2
        MOVE.w map.height.pixels, player.position.y
        SUB.w #32, player.position.y

.UpdatePlayer.LevelMapBoundaries.check.skip2
        CMP.w player.position.y, #$fff0
      bcc .UpdatePlayer.LevelMapBoundaries.check.out
        MOVE.w #$00, player.position.y


.UpdatePlayer.LevelMapBoundaries.check.out
  rts