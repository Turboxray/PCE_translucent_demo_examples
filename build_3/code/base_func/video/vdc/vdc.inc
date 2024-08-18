
include "..\base_func\video\vdc\equ.inc"

;//................................................................................
;// MACROS


;//................
WAITVBLANK        .macro
        .if (\#=0)
            ldx #1
        .endif

        .if (\#>0)
            ldx #\1
        .endif


        jsr __wait_vblank
    .endm

;//................
VDC1    .macro            ;hardware I/O page must be mapped to the first bank

    stz $000E

    .endm


;//................
VDC2    .macro            ;hardware I/O page must be mapped to the first bank

    inc $000E

    .endm

;//................
notsafe_VDC.reg     .macro

    .if    (\?2=1)
    st0 #\1
    sta $0002
    stz $0003
    .endif

    .if    (\#=1)
    st0 #\1
    .endif

    .if    (\#=2 & \?2 = 2)
    st0 #\1
    st1 #LOW(\2)
    st2 #HIGH(\2)
     .endif

    .if    (\#=3 & \?2 = 6)
    st0 #\1
    lda \2
    sta $0002
    lda \3
    sta $0003
    .endif

    .if    (\#=2 & \?2 = 6)
    st0 #\1
    lda \2
    sta $0002
    lda \2+1
    sta $0003
    .endif

    .if    (\#=2 & \?2 = 3)
    st0 #\1
    lda \2
    sta $0002
    lda \2+1
    sta $0003
    .endif

    .endm

;//................
sVDC.reg     .macro

    .if    (\?2=1)
    lda #\1
    sta <vdc_reg
    st0 #\1
    sta $0002
    stz $0003
    .endif

    .if    (\#=1)
    lda #\1
    sta <vdc_reg
    st0 #\1
    .endif

    .if    (\#=2 & \?2 = 2)
    lda #\1
    sta <vdc_reg
    st0 #\1
    st1 #LOW(\2)
    st2 #HIGH(\2)
     .endif

    .if    (\#=3 & \?2 = 6)
    lda #\1
    sta <vdc_reg
    st0 #\1
    lda \2
    sta $0002
    lda \3
    sta $0003
    .endif

    .if    (\#=2 & \?2 = 6)
    lda #\1
    sta <vdc_reg
    st0 #\1
    lda \2
    sta $0002
    lda \2+1
    sta $0003
    .endif

    .if    (\#=2 & \?2 = 3)
    lda #\1
    sta <vdc_reg
    st0 #\1
    lda \2
    sta $0002
    lda \2+1
    sta $0003
    .endif

    .endm

;//................
VDC2.reg .macro                ;macro for SuperGrafx

    .if    (\?2=1)
    st0 #\1
    sta $0012
    stz $0013
    .endif

    .if    (\#=1)
    st0 #\1
    .endif

    .if    (\#=2 & \?2 != 1)
    st0 #\1
    st1 #LOW(\2)
    st2 #HIGH(\2)
     .endif

    .if    (\#=3 & \?3 != 1)
    st0 #\1
    lda \2
    sta $0012
    lda \3
    sta $0013
    .endif

    .endm


;//................
ST1.w .macro

     st1 #LOW(\1)
     st2 #HIGH(\1)

    .endm

;//................
STOW.YA.vport .macro

     sta $0002
     sty $0003

    .endm

;//................
STOW.XA.vport .macro

     sta $0002
     stx $0003

    .endm

;//................
STOW.YA.vport2 .macro

     sta $0012
     sty $0013

    .endm

;//................
STOW.XA.vport2 .macro

     sta $0012
     stx $0013

    .endm
