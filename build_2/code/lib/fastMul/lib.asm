;World's fastest 16x16 unsigned mult for 6502
;you can go faster, but not without more code and/or data
;and being less elegant and harder to follow.
;by Repose 2017
;table generator by Graham
;addition improvement suggested by JackAsser

;time: 258 cycles @ PCE

;How to use:
;put numbers in x:y and result is Y reg, X reg, z1, z0


sqrlo     = $c000 ;511 bytes
sqrhi     = $c200 ;511 bytes
negsqrlo  = $c400 ;511 bytes
negsqrhi  = $c600 ;511 bytes

;pointers to square tables above
p_sqr_lo    = R0.l
p_sqr_hi    = R0.h
p_invsqr_lo = R1.l
p_invsqr_hi = R1.h

; input
x0 = D0     ;multiplier, 2 bytes
x1 = D0.h
y0 = D1     ;multiplicand, 2 bytes
y1 = D1.h

; output
z0 = D2     ;product, 2 bytes
z1 = D2.h
;z2=$82 returned in X reg
;z3=$83 returned in Y reg

InitMulTables:
;init zp square tables pointers
      lda #>sqrlo
      sta p_sqr_lo+1
      lda #>sqrhi
      sta p_sqr_hi+1
      lda #>negsqrlo
      sta p_invsqr_lo+1
      lda #>negsqrhi
      sta p_invsqr_hi+1
  rts

umult16:
;set multiplier as x0
      lda <x0
      sta <p_sqr_lo
      sta <p_sqr_hi
      eor #$ff
      sta <p_invsqr_lo
      sta <p_invsqr_hi      ;22

      ldy <y0
      sec
      lda [p_sqr_lo],y
      sbc [p_invsqr_lo],y
      sta <z0               ;x0*y0l
      lda [p_sqr_hi],y
      sbc [p_invsqr_hi],y
      sta <c1a              ;x0*y0h;42
      ;c1a means column 1, row a [partial product to be added later]

      ldy <y1
      ;sec  ;notice that the high byte of sub above is always +ve
      lda [p_sqr_lo],y
      sbc [p_invsqr_lo],y
      sta <c1b              ;x0*y1l
      lda [p_sqr_hi],y
      sbc [p_invsqr_hi],y
      sta <c2a              ;x0*y1h;40

      ;set multiplier as x1
      lda <x1
      sta <p_sqr_lo
      sta <p_sqr_hi
      eor #$ff
      sta <p_invsqr_lo
      sta <p_invsqr_hi      ;22

      ldy <y0
      ;sec
      lda [p_sqr_lo],y
      sbc [p_invsqr_lo],y
      sta <c1c              ;x1*y0l
      lda [p_sqr_hi],y
      sbc [p_invsqr_hi],y
      sta <c2b              ;x1*y1h;40

      ldy <y1
      ;sec
      lda [p_sqr_lo],y
      sbc [p_invsqr_lo],y
      sta <c2c              ;x1*y1l
      lda [p_sqr_hi],y
      sbc [p_invsqr_hi],y
      tay                   ;x1*y1h;Y=z3, 38 cycles

;22+42+40+22+40+38=204 cycles for main multiply part

.do_adds
;-add the first two numbers of column 1
      clc
      lda <c1a
      adc <c1b
      sta <z1               ;14

;-continue to first two numbers of column 2
      lda <c2a
      adc <c2b:
      tax                   ;X=z2, 10 cycles
    bcc .c1c                ;4/6 avg 5
      iny                   ;z3++
      clc

;-add last number of column 1
.c1c
      lda <c1c
      adc <z1
      sta <z1               ;12

;-add last number of column 2
      txa                   ;A=z2
      adc <c2c
      tax                   ;X=z2, 8
    bcc .fin                ;2/4 avg 4
      iny                   ;z3++

;Y=z3, X=z2
;14+10+5+12+8+4=53
.fin
  rts

; Diagram of the additions
;                  d    b
;              x   c    a
;                 --------
;               ab.h  ab.l
; +       ad.h  ad.l
; +       cb.h  cb.l
; + cd.h  cd.l
; ------------------------
;     z3    z2    z1    z0

