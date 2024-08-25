;
;
;    {Assemble with PCEAS: ver 3.23 or higher}
;
;   Turboxray '24
;



;..............................................................................................................
;..............................................................................................................
;..............................................................................................................
;..............................................................................................................

    list
    mlist

; Uncomment the line below for visual benchmarking.
; DEBUG_BENCHMARK = 1

;..................................................
;                                                 .
;  Logical Memory Map:                            .
;                                                 .
;            $0000 = Hardware bank                .
;            $2000 = Sys Ram                      .
;            $4000 = Subcode                      .
;            $6000 = Data 0 / Cont. of Subcode    .
;            $8000 = Data 1                       .
;            $A000 = Data 2                       .
;            $C000 = Main                         .
;            $E000 = Fixed Libray                 .
;                                                 .
;..................................................


;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;//  Vars


    ;// Varibles defines
    .include "../base_func/vars.inc"
    .include "../base_func/video/vdc/vars.inc"
    .include "../base_func/video/vdc/sprites/vars.inc"
    .include "../base_func/IO/irq_controller/vars.inc"
    .include "../base_func/audio/wsg/vars.inc"
    .include "../base_func/IO/gamepad/vars.inc"


    .include "../lib/controls/vars.inc"
    .include "../lib/random/16bit/vars.inc"

    .include "../demo/vars.inc"

;....................................
    .code

    .bank $00, "Fixed Lib/Start up"
    .org $e000
;....................................

;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;// Support files: equates and macros

    ;// Support files for MAIN
    .include "../base_func/base.inc"
    .include "../base_func/video/video.inc"
    .include "../base_func/video/vdc/vdc.inc"
    .include "../base_func/video/vdc/sprites/sprites.inc"
    .include "../base_func/video/vce/vce.inc"
    .include "../base_func/timer/timer.inc"
    .include "../base_func/IO/irq_controller/irq.inc"
    .include "../base_func/IO/mapper/mapper.inc"
    .include "../base_func/audio/wsg/wsg.inc"
    .include "../base_func/IO/gamepad/gamepad.inc"

    .include "../lib/controls/controls.inc"
    .include "../lib/random/16bit/random_16bit.inc"

    .include "../demo/demo.inc"


;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;// Startup and fix lib @$E000

startup:
        ;................................
        ;Main initialization routine.
        InitialStartup
        CallFarWide init_audio
        CallFarWide init_video

        stz $2000
        tii $2000,$2001,$2000

        ;................................
        ;Set video parameters
        VCE.reg LO_RES|H_FILTER_ON
        sVDC.reg HSR  , #$0202
ifdef DEBUG_BENCHMARK
        sVDC.reg HDR  , #$051e
        sVDC.reg VSR  , #$1402
else
        sVDC.reg HDR  , #$041f
        sVDC.reg VSR  , #$1402
endif
        sVDC.reg VDR  , #$00d7
        sVDC.reg VDE  , #$00ff
        sVDC.reg DCR  , #AUTO_SATB_ON
        sVDC.reg CR   , #$0000
        sVDC.reg SATB , #$0800
        sVDC.reg MWR  , #SCR32_32

        IRQ.control IRQ2_ON|VIRQ_ON|TIRQ_OFF

        TIMER.port  _7.00khz
        TIMER.cmd   TMR_OFF

        MAP_BANK #MAIN, MPR6
        jmp MAIN

;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;// Data / fixed bank


;Stuff for printing on screen
    .include "../base_func/video/print/lib.asm"

;other basic functions
    .include "../base_func/video/vdc/lib.asm"
    .include "../base_func/video/vdc/sprites/lib.asm"

; Lib stuffs
    .include "../lib/controls/lib.asm"
    .include "../base_func/IO/gamepad/lib.asm"
    .include "../lib/slow16by16Mul/lib.asm"
    .include "../lib/random/16bit/lib.asm"

    .include "../lib/palFade/palFade_lib.asm"
    .include "../lib/palFade/palFade.inc"


;end DATA
;//...................................................................


;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;// Interrupt routines

    .include "../base_func/video/vdc/vectors.inc"

;end INT

;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;// INT VECTORS

  .org $fff6

    .dw BRK
    .dw VDC
    .dw TIRQ
    .dw NMI
    .dw startup

;..............................................................................................................
;..............................................................................................................
;..............................................................................................................
;..............................................................................................................
;Bank 0 end





;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;// Main code bank @ $C000

;....................................
    .bank $01, "MAIN"
    .org $c000
;....................................


MAIN
        ;................................
        Random.seed #$18ca    ; initailize random seed
        DMA.set.init          ; initialize Txx instruction in ram 

        ;................................
        ;Turn display on
        sVDC.reg CR , #(BG_ON|SPR_OFF|VINT_ON|HINT_ON)

        ;................................
        ;Load Ghosthouse assets
        loadCellToCram.BG     ghosthouse,     0       ; Load palette block starting at BG color #0
        loadDataToVram        ghosthouse.map, $0000   ; map is at vram address $0000
        loadCellToVram.4banks ghosthouse,     $1000   ; tiles start at vram address $1000

        ; Set sprite color #0 to black. This is the border color in overscan.
        stz $402
        lda #$01
        sta $403
        stz $404
        stz $405

        ;...............................
        ; TIRQ OFF
        TIMER.port  _7.00khz
        TIMER.cmd   TMR_OFF
        IRQ.control IRQ2_ON|VIRQ_ON|TIRQ_OFF

        ;...............................
        ; Set scroll positions
        MOVE.w #$00, _BXR
        MOVE.w #$08, _BYR
        MOVE.w #$40, _RCR

        ;................................
        ;start the party
        Interrupts.enable

        ; Initialize the demo vars. 
        MOVE.w #$28, ghost.pos.x
        MOVE.w #$28, ghost.pos.y
        MOVE.b #$01, ghostFrame

        ; Keep track of previous position/state/frame for undo-ing sections.
        MOVE.w ghost.pos.x, ghostOld.pos.x   
        MOVE.w ghost.pos.y, ghostOld.pos.y
        MOVE.b ghostFrame, ghostFrameOld

        ; Frame input delay for animation change of ghost.. for direction change
        MOVE.b #$00, frameDelayCounter
        MOVE.b #$04, frameDelayDiv

        ; Create the palettes we need to work with..
        jsr CreateExpandedPals

        ; Convert back to VCE format
        MOVE.b #$00, <R6.l
        MOVE.b #$00, <R6.h
        MOVE.b #$00, <R7.l
        jsr FadePalToOrg

        ; Write palette without blending colors.
        DoVCEDMA

        ; Initial ghost soft-sprite
        call DrawGhost

        ; Set the fade Deltas to Zero, and the fade in Ghost from BG
        MOVE.b #$07, <D7
        MOVE.b #$00, <R6.l
        MOVE.b #$00, <R6.h
        MOVE.b #$00, <R7.l

.loop.fade
        WAITVBLANK 2
  debugBENCH 7,7,0
        inc <R6.l
        jsr FadePalToOrg
  debugBENCH 0,0,0
        WAITVBLANK
        DoVCEDMA

        WAITVBLANK 2
  debugBENCH 7,7,0
        inc <R6.h
        inc <R7.l
        jsr FadePalToOrg
  debugBENCH 0,0,0
        WAITVBLANK 2
        DoVCEDMA

        dec <D7
      beq prep_main_loop
        jmp .loop.fade

        ; Fading in done. Initialize some interactive fade controls
prep_main_loop
        MOVE.b #$00, fadeCount
        MOVE.b #$00, fadeDirection
        MOVE.b #$02, fadeDelay
        MOVE.b fadeDelay, fadeDelayCNT

main_loop:

      WAITVBLANK

        ; Transfer any pending palette data
  debugBENCH 7,7,0
        jsr DmaPCEpal
  debugBENCH 0,0,0

      ; On screen border color benchmark.. if enabled.
  debugBENCH 7,0,7
        call DrawGhost
  debugBENCH 0,0,0

        ; Do I/O gamepad stuffs
        call Gamepad.READ_IO.single_controller
        call Controls.ProcessInput
        call DoGhostControls

        ; Any a 4 frame delay to any fades
        dec fadeDelayCNT
        lda fadeDelayCNT
        cmp #$00
      bne main_loop
        MOVE.b fadeDelay, fadeDelayCNT

        ; If a fade is pending.. prep the deltas!
        lda fadeCount
      bne .prep.fade
        jmp main_loop
.prep.fade
        jsr setFadeDeltas


        ; Apply the delta fades
.fade
  debugBENCH 0,7,7
        inc enableColorDMA
        jsr FadePalToOrg
  debugBENCH 0,0,0

      jmp main_loop



;//...................................................................


;Func
;//...................................................................

;..................]
;..................]
CreatePalDeltas:
  rts

;..................]
;..................]
resetFadeDeltas:
        lda fadeDirection
      beq .up.fade
.down.fade
        lda #$06
        sta fadeCount
        MOVE.b #$07, <R6.l
        MOVE.b #$07, <R6.h
        MOVE.b #$06, <R7.l
      rts
.up.fade
        MOVE.b #$01, <R6.l
        MOVE.b #$00, <R6.h
        MOVE.b #$00, <R7.l
      rts

;..................]
;..................]
changeFadeDirection:
        lda #$07
        sta fadeCount
        lda fadeDirection
        eor #$01
        sta fadeDirection
        lda #$00
        sta b_gb_select
        jsr resetFadeDeltas
  rts

;..................]
;..................]
setFadeDeltas:

      lda b_gb_select
      eor #$01
      sta b_gb_select

      lda fadeDirection
    beq .up.fade
.down.fade
        lda b_gb_select
      bne .down.rg
.down.b
        dec <R6.l
      rts
.down.rg
        dec <R6.h
        dec <R7.l
        dec fadeCount
      rts
        
.up.fade
        lda b_gb_select
      bne .up.rg
.up.b
        inc <R6.l
      rts
.up.rg
        inc <R6.h
        inc <R7.l
        dec fadeCount
      rts

  rts

;..................]
;..................]
CreateExpandedPals:
      PUSHBANK.2 MPR2
      MAP_BANK.2 #ghosthouse.pal , MPR2
      MOVE.w     #ghosthouse.pal, <A0

;........
; 1st part  - convert to expanded color format

      clx
.loop.color

      lda [<A0]                   ;# GRB
      INC.w <A0
      tay

      lda depackVCE2RB.LUT,y
      and #$0f
      sta palBuff_0._B,x          ; _B

      lda depackVCE2RB.LUT,y
      lsr a
      lsr a
      lsr a
      lsr a
      and #$0f
      sta palBuff_0._R,x          ; _R

      lda depackVCE2G.LUT.lsb,y
      sta palBuff_0._G,x

      lda [<A0]
      INC.w <A0    
      tay
      lda depackVCE2G.LUT.msb,y
      ora palBuff_0._G,x
      sta palBuff_0._G,x

      inx
    bne .loop.color

      PULLBANK.2 MPR2

;........
; 2nd part  - Create main palette without translucent values (repeat main values)

      MOVE.b #$0, <D0
      clx
.loop.outer

      cly
.loop.inner

      lda palBuff_0._B,x
      sta palBuff_1._B +0,x
      sta palBuff_1._B +4,x
      sta palBuff_1._B +8,x
      sta palBuff_1._B+12,x

      lda palBuff_0._R,x
      sta palBuff_1._R +0,x
      sta palBuff_1._R +4,x
      sta palBuff_1._R +8,x
      sta palBuff_1._R+12,x

      lda palBuff_0._G,x
      sta palBuff_1._G +0,x
      sta palBuff_1._G +4,x
      sta palBuff_1._G +8,x
      sta palBuff_1._G+12,x

      inx
      iny
      cpy #$04
    bne .loop.inner
      lda <D0
      clc
      adc #$10
      sta <D0
      tax
      cpx #$00
      bne .loop.outer

;.......
; 3rd part  - Create delta values between main and translucent set

      clx
.loop.delta

      ; blue
      lda palBuff_0._B,x
      sec
      sbc palBuff_1._B,x
      sta palDelta._B,x

      ; red
      lda palBuff_0._R,x
      sec
      sbc palBuff_1._R,x
      sta palDelta._R,x


      ; green
      lda palBuff_0._G,x
      sec
      sbc palBuff_1._G,x
      sta palDelta._G,x

      inx
    bne .loop.delta

  rts

;..................]
;..................]
CreatPCEpal:

      
  rts

;..................]
;..................]
DmaPCEpal:
      
      tst #$ff, enableColorDMA
    beq .out
      stz vce_clr.l
      stz vce_clr.h
      tia destPalBuff, vce_data, $200
.out
      stz enableColorDMA
  rts
;..................]
;..................]
FadePalDown:
  rts

;..................]
;..................]
FadePalUp:
  rts

;..................]
;..................]
FadePalToOrg:


  ldx <R6.l
  lda .tbl.scale.lo,x
  sta <A3.l
  lda .tbl.scale.hi,x
  sta <A3.h

  ldx <R6.h
  lda .tbl.scale.lo,x
  sta <A4.l
  lda .tbl.scale.hi,x
  sta <A4.h

  ldx <R7.l
  lda .tbl.scale.lo,x
  sta <A5.l
  lda .tbl.scale.hi,x
  sta <A5.h

  jmp .start

.tbl.scale.lo
  .db low(palDeltaScale_1), low(palDeltaScale_2), low(palDeltaScale_3), low(palDeltaScale_4)
  .db low(palDeltaScale_5), low(palDeltaScale_6), low(palDeltaScale_7), low(palDeltaScale_8)
.tbl.scale.hi
  .db high(palDeltaScale_1), high(palDeltaScale_2), high(palDeltaScale_3), high(palDeltaScale_4)
  .db high(palDeltaScale_5), high(palDeltaScale_6), high(palDeltaScale_7), high(palDeltaScale_8)



.start
        MOVE.w #destPalBuff, <A0

        clx
        clc
.loop

.blue
        ldy palDelta._B,x
        lda [<A3],y
        adc palBuff_1._B,x
        and #$07
        sta <D0
.red
        ldy palDelta._R,x
        lda [<A4],y
        adc palBuff_1._R,x
        asl a
        asl a
        asl a
        asl a
        ora <D0
        and #$77
        tay
        lda packRB2VCE.LUT,y
          pha
.green
        ldy palDelta._G,x        
        lda [<A5],y
        clc
        adc palBuff_1._G,x
        tay
          pla
        ora packG2VCE.LUT.lsb,y

        sta [<A0]
        INC.w <A0
        lda packG2VCE.LUT.msb,y
        sta [<A0]
        INC.w <A0

        inx
      bne .loop

  rts

;..................]
;..................]
DoGhostControls:

        lda frameDelayCounter
        inc a
        cmp frameDelayDiv
      bcc .skip
        cla
.skip
        sta frameDelayCounter

;..................
; Directions

;........
.check.rh
        lda input_state.directions
        and #control.rh.mask
        cmp #control.rh.held
      bne .check_left
.do_right
        lda frameDelayCounter
      bne .skip0
        lda ghostFrame
        cmp #$05
      bcs .skip0
        inc ghostFrame
.skip0
        lda ghost.pos.x
        cmp #(272-80)
      bcs .check_up
        inc ghost.pos.x
      jmp .check_up

;........
.check_left
        lda input_state.directions
        and #control.lf.mask
        cmp #control.lf.held
      bne .check_up
.do_left
        lda frameDelayCounter
      bne .skip1
        lda ghostFrame
        cmp #$01
      bcc .skip1
      beq .skip1
        dec ghostFrame
.skip1
        lda ghost.pos.x
        cmp #$8
      bcc .check_up
      beq .check_up
        dec ghost.pos.x
      jmp .check_up

;........
.check_up
        lda input_state.directions
        and #control.up.mask
        cmp #control.up.held
      bne .check_dn
.do_up
        lda ghost.pos.y
      beq .update
        dec ghost.pos.y
      jmp .update

;........
.check_dn
        lda input_state.directions
        and #control.dn.mask
        cmp #control.dn.held
      bne .update
.do_dn
        lda ghost.pos.y
        cmp #(232-8)
      bcs .update
        inc ghost.pos.y
      jmp .update

.update

;..................
; Buttons

;........
.check.b2
        lda input_state.buttons
        and #control.b2.mask
        cmp #control.b2.held
      bne .unhide.check
.do_b2
      lda ghostFrame
      cmp #3
    bcs .left.hide
.right.hide
      cla
    bra .hide
.left.hide
      lda #$06
.hide
      sta ghostFrame
      jmp .check.b1

.unhide.check
      lda ghostFrame
      cmp #$06
    beq .left.unhide
      cmp #$00
    beq .right.unhide
      jmp .check.b1
.right.unhide
      lda #$01
    bra .unhide
.left.unhide
      lda #$05
.unhide
      sta ghostFrame


;........
.check.b1
        lda input_state.buttons
        and #control.b1.mask
        cmp #control.b1.pressed
      bne .out
.do_b1
      ; Don't interrupt a pending fade
      lda fadeCount
    bne .out
      jsr changeFadeDirection
      jmp .out

.out

  rts

;..................]
;..................]
DrawGhost:
      PUSHBANK.4 MPR2

      lda ghost.pos.x
      and #$07
      tax
      MAP_BANK.4 frame.set.bank,x , MPR2

      MOVE.b #ia_DMA, int__dma_block.type
      MOVE.w #$0010, int__dma_block.len
      MOVE.w #vdata_port, int__dma_block.dest

      ldx ghostFrameOld
      MOVE.b  frame.mouthOffset.x,x , <R3.l
      MOVE.b  frame.mouthOffset.y,x , <R3.h
      MOVE.b  frame.addr.lo,x , <A0.l
      MOVE.b  frame.addr.hi,x , <A0.h
      MOVE.b  ghostOld.pos.x, <R2.l
      LSR.b.3 <R2.l
      MOVE.b  ghostOld.pos.y, <R2.h
      LSR.b.3 <R2.h
      call CalcScreenMapAddr
      call ClearPrevMap

      ldx ghostFrame
      MOVE.b  frame.mouthOffset.x,x , <R3.l
      MOVE.b  frame.mouthOffset.y,x , <R3.h
      MOVE.b  frame.addr.lo,x , <A0.l
      MOVE.b  frame.addr.hi,x , <A0.h
      MOVE.b  ghost.pos.x, <R2.l
      LSR.b.3 <R2.l
      MOVE.b  ghost.pos.y, <R2.h
      LSR.b.3 <R2.h
      call CalcScreenMapAddr
      call SetNewMap


      call CalcScreenTileAddr
      MOVE.b  #$a, <D0
      ADD.b   #$02, <R0.h
      AND.b.b ghost.pos.y, #$07, <D3.l
      ASL.b   <D3.l
      SUB.b.w <D3.l, <A0

.loop
      ldx #$9
      ; MOVE.w <A0, <A3 ;int__dma_block.source
      MOVE.w <A0, int__dma_block.source
      call DrawTile
      ADD.b.w #$10, <R0		; Get the next column
      ADD.b.w #$90, <A0
      dec <D0
    bne .loop

      MOVE.w ghost.pos.y, ghostOld.pos.y
      MOVE.w ghost.pos.x, ghostOld.pos.x
      MOVE.b ghostFrame, ghostFrameOld

      PULLBANK.4 MPR2
  rts

;..................]
;..................]
ClearPrevMap:
        sVDC.reg MAWR, <R0
        sVDC.reg MARR, <R0
        sVDC.reg VRWR    

        jsr .clearPrevMapEntries

        ADD.b.w #$20, <R0
        sVDC.reg MAWR, <R0
        sVDC.reg MARR, <R0
        sVDC.reg VRWR    

        jsr .clearPrevMapEntries
 
        ADD.b.w #$20, <R0
        sVDC.reg MAWR, <R0
        sVDC.reg MARR, <R0
        sVDC.reg VRWR    

        jsr .clearPrevMapEntries

  rts

;...................
.clearPrevMapEntries
        MOVE.b $0002, $0002
        lda $0003
        and #$7f
        sta $0003

        MOVE.b $0002, $0002
        lda $0003
        and #$7f
        sta $0003

        MOVE.b $0002, $0002
        lda $0003
        and #$7f
        sta $0003

        ldx ghostFrameOld
        lda frameMouthCheck,x
      beq .out

        MOVE.b $0002, $0002
        lda $0003
        and #$7f
        sta $0003
.out
  rts

;..................]
;..................]
SetNewMap:
        sVDC.reg MAWR, <R0
        sVDC.reg MARR, <R0
        sVDC.reg VRWR    

        jsr .setMapEntries

        ADD.b.w #$20, <R0
        sVDC.reg MAWR, <R0
        sVDC.reg MARR, <R0
        sVDC.reg VRWR    

        jsr .setMapEntries

        ADD.b.w #$20, <R0
        sVDC.reg MAWR, <R0
        sVDC.reg MARR, <R0
        sVDC.reg VRWR    

        jsr .setMapEntries

  rts
;...................
.setMapEntries
        MOVE.b $0002, $0002
        lda $0003
        ora #$80
        sta $0003

        MOVE.b $0002, $0002
        lda $0003
        ora #$80
        sta $0003

        MOVE.b $0002, $0002
        lda $0003
        ora #$80
        sta $0003

        ldx ghostFrame
        lda frameMouthCheck,x
      beq .out

        MOVE.b $0002, $0002
        lda $0003
        ora #$80
        sta $0003
.out
  rts
;..................]
;..................]
CalcScreenMapAddr:

      ; original: (Y*0x20) + x
      ; modified: (Y<<5) + x
      
      lda <R2.h         ; Y
      clc
      adc <R3.h         ; Y offset
      clc
      asl a
      asl a
      asl a
      stz <R0.h
      asl a
      rol <R0.h
      asl a
      rol <R0.h
      sta <R0.l

      lda <R2.l         ; X
      ora <R0.l
      sta <R0.l

      ADD.b.w <R3.l,<R0 ; X offset


  rts
;..................]
;..................]
CalcScreenTileAddr:

      ; original: (((Y*0x20) + x) * 0x10) + 0x1000
      ;        Note: the "+ 0x1000" is the tile address offset in vram
      ; mod 1:    (((Y<<5)   + x) << 4) + 0x1000
      ; mod 2:    (Y<<9) + (x << 4) + 0x1000
      ; mod 3:    (Y@msb<<1) + (x << 4) + 0x10@msb

      lda ghost.pos.x
        lsr a                       ; Chop off the lower bits to get the coarse address
        lsr a
        lsr a
      stz <R0+1             
      asl a
      asl a
      asl a
      asl a
      rol <R0+1
      ora #$08
      sta <R0
      lda ghost.pos.y
        lsr a			    ; Chop off the lower bits to get the coarse address
        lsr a
        lsr a
      asl a
      ora <R0+1
      adc #$10
      sta <R0+1

      SUB.w #$810, <R0  ; Do a final offset. This allows off screen positioning. Y = -0x8, X = -0x10
  rts

;..................]
;..................]
DrawEraseRow:
        MOVE.w <R0, <A1
.loop
        sVDC.reg MAWR, <A1
        sVDC.reg VRWR
        call DrawEraseTile
        ADD.b.w #$10, <A1
        dex
      bne .loop
  rts

;..................]
;..................]
DrawTile:
        MOVE.w <R0, <A1
        sVDC.reg MAWR, <A1
        sVDC.reg VRWR
        ADD.b.w #$02, <A1.h
.loop
        sVDC.reg MAWR, <A1
        sVDC.reg VRWR
        DMA.call
        ADD.b.w #$10, int__dma_block.source
        ADD.b   #$2, <A1.h			; next row
        dex
      bne .loop
        sVDC.reg MAWR, <A1
        sVDC.reg VRWR


; .loop
;         sVDC.reg MAWR, <A1
;         sVDC.reg VRWR
;           phx
;         ldx #$8
; .loop.tile
;           phx
;         lda [<A3],y
;         iny
;         tax

;         tax
;         tax
;         tax
;         ; ora <A4
;         sta $0002
;         lda [<A3],y
;         iny
;         tax

;         tax
;         tax
;         tax

;         ; ora <A4
;         sta $0003
;           plx
;         dex
;       bne .loop.tile
;         plx
;         ; DMA.call

;         ; ADD.b.w #$10, int__dma_block.source
;         ADD.b   #$2, <A1.h			; next row
;         dex
;       bne .loop
;         sVDC.reg MAWR, <A1
;         sVDC.reg VRWR
;           ply

  rts

;..................]
;..................]
DrawEraseTile:

        st1 #$00
        st2 #$00
        st2 #$00
        st2 #$00
        st2 #$00
        st2 #$00
        st2 #$00
        st2 #$00
        st2 #$00
rts

;.......................................
frame.mouthOffset.x:
  .db 1,1,1, 3, 3,4,4
frame.mouthOffset.y:
  .db 3,2,2, 2, 2,2,3

frameMouthCheck:
  .db 0,0,1, 0, 1,0,0
frame.set.bank:
  .db bank(ghost_0.cell),bank(ghost_1.cell),bank(ghost_2.cell),bank(ghost_3.cell)
  .db bank(ghost_4.cell),bank(ghost_5.cell),bank(ghost_6.cell),bank(ghost_7.cell)

frame.addr.lo:
  .db low(ghost_0.cell),       low(ghost_0.cell+$5A0),  low(ghost_0.cell+$b40),  low(ghost_0.cell+$10e0)
  .db low(ghost_0.cell+$1680), low(ghost_0.cell+$1c20), low(ghost_0.cell+$21c0), low(ghost_0.cell+$2760)

frame.addr.hi:
  .db high(ghost_0.cell),       high(ghost_0.cell+$5A0),  high(ghost_0.cell+$b40),  high(ghost_0.cell+$10e0)
  .db high(ghost_0.cell+$1680), high(ghost_0.cell+$1c20), high(ghost_0.cell+$21c0), high(ghost_0.cell+$2760)

;Main end
;//...................................................................




;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;

;....................................
    .code
    .bank $02, "Subcode 1"
    .org $8000
;....................................


  IncludeBinary Font.cell, "../base_func/video/print/font.dat"

Font.pal: .db $00,$00,$33,$01,$ff,$01,$ff,$01,$ff,$01,$ff,$01,$ff,$01,$f6,$01
Font.pal.size = sizeof(Font.pal)


    ;// Support files for MAIN
    .include "../base_func/init/InitHW.asm"


;..............................................................................................................
;..............................................................................................................
;..............................................................................................................
;..............................................................................................................
;Bank 1 end


;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////
;
;// Data/Code


;/////////////////////////////////////////////////////////////////////////////////
;

;....................................
  .bank $08, "ghosthouse"
    .org $4000
;....................................
    .page 2
    IncludeBinary ghosthouse.cell, "../assets/BG_tiles/ghosthouse.tbin"

    .page 2
    IncludeBinary ghosthouse.map,  "../assets/BG_map/ghosthouse.mbin"

    .page 2
    IncludeBinary ghosthouse.pal,  "../assets/BG_pal/pce.pbin"


;....................................
  .bank $10, "ghost_0"
    .org $4000
;....................................
    .page 2
    IncludeBinary ghost_0.cell, "../assets/ghost/ghost_0.tbin"

;....................................
  .bank $12, "ghost_1"
    .org $4000
;....................................
    .page 2
    IncludeBinary ghost_1.cell, "../assets/ghost/ghost_1.tbin"

;....................................
  .bank $14, "ghost_2"
    .org $4000
;....................................
    .page 2
    IncludeBinary ghost_2.cell, "../assets/ghost/ghost_2.tbin"

;....................................
  .bank $16, "ghost_3"
    .org $4000
;....................................
    .page 2
    IncludeBinary ghost_3.cell, "../assets/ghost/ghost_3.tbin"

;....................................
  .bank $18, "ghost_4"
    .org $4000
;....................................
    .page 2
    IncludeBinary ghost_4.cell, "../assets/ghost/ghost_4.tbin"

;....................................
  .bank $1a, "ghost_5"
    .org $4000
;....................................
    .page 2
    IncludeBinary ghost_5.cell, "../assets/ghost/ghost_5.tbin"

;....................................
  .bank $1c, "ghost_6"
    .org $4000
;....................................
    .page 2
    IncludeBinary ghost_6.cell, "../assets/ghost/ghost_6.tbin"

;....................................
  .bank $1e, "ghost_7"
    .org $4000
;....................................
    .page 2
    IncludeBinary ghost_7.cell, "../assets/ghost/ghost_7.tbin"



;....................................
    ;Pad the Rom
    .bank $7f, "PAD"
;....................................


;END OF FILE