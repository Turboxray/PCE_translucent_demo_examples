;//........
TIRQ.custom
    jmp [timer_vect]

TIRQ:   ;// Not used
        BBS2 <vector_mask, TIRQ.custom
        stz $1403
        rti

;//........
BRK.custom
    jmp [brk_vect]
BRK:
        BBS1 <vector_mask, BRK.custom
        rti

;//........
VDC.custom
    jmp [vdc_vect]

VDC:
        BBS0 <vector_mask, VDC.custom
          pha
        lda IRQ.ackVDC
        sta <vdc_status
        bit #$20
        bne VDC.vsync
VDC.hsync
        BBS3 <vector_mask, VDC.custom.hsync
        BBS5 <vdc_status, VDC.vsync
          pla
        rti

VDC.custom.hsync
    jmp [vdc_hsync]

VDC.custom.vsync
    jmp [vdc_vsync]

VDC.vsync
        phx
        phy
      BBS4 <vector_mask, VDC.custom.vsync

        st0 #BXR
        lda _BXR
        sta $0002
        lda _BXR+1
        sta $0003

        st0 #BYR
        lda _BYR
        sta $0002
        lda _BYR+1
        sta $0003

        st0 #RCR
        lda _RCR
        sta $0002
        lda _RCR+1
        sta $0003

        lda <vdc_reg
        sta $0000

VDC.vsync.rtn
        ply
        plx
        pla
      stz __vblank
  rti

;//........
NMI:
        rti