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
        sVDC.reg VDR  , #$00df
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
        MOVE.w #$00, _BYR
        MOVE.w #$40, _RCR

        ;................................
        ;start the party
        Interrupts.enable

        ; Initialize the demo vars. 
        MOVE.w #$28, ghost.pos.x
        MOVE.w #$28, ghost.pos.y
        MOVE.b #$00, ghostFrame

        ; Keep track of previous position/state/frame for undo-ing sections.
        MOVE.w ghost.pos.x, ghostOld.pos.x   
        MOVE.w ghost.pos.y, ghostOld.pos.y
        MOVE.b ghostFrame, ghostFrameOld

        MOVE.b #$00, frameDelayCounter
        MOVE.b #$04, frameDelayDiv

main_loop:

      WAITVBLANK
      ; On screen border color benchmark.. if enabled.
      debugBENCH 7,0,7
        call DrawGhost
      debugBENCH 0,0,0

        lda frameDelayCounter
        inc a
        cmp frameDelayDiv
      bcc .skip
        cla
.skip
        sta frameDelayCounter

        call Gamepad.READ_IO.single_controller
        call Controls.ProcessInput
        call DoGhostControls

      jmp main_loop

;//...................................................................


;Func
;//...................................................................


;..................]
;..................]
DoGhostControls:

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
      jmp .out

.unhide.check
      lda ghostFrame
      cmp #$06
    beq .left.unhide
      cmp #$00
    beq .right.unhide
      jmp .out
.right.unhide
      lda #$01
    bra .unhide
.left.unhide
      lda #$05
.unhide
      sta ghostFrame
      jmp .check.b1


;........
.check.b1
        lda input_state.buttons
        and #control.b1.mask
        cmp #control.b1.pressed
      bne .out
.do_b1
      nop
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