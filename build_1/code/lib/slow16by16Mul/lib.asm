

;16-bit multiply with 32-bit product
;source from 6502.org

multiplier   = R0
multiplicand = R1
product      = R2

mult16.16:
      lda   #$00
      sta   <product+2      ; clear upper bits of product
      sta   <product+3
      ldx   #$10           ; set binary count to 16
.shift_r
      lsr   <multiplier+1   ; divide multiplier by 2
      ror   <multiplier
    bcc .rotate_r
      lda   <product+2      ; get upper half of product and add multiplicand
      clc
      adc   <multiplicand
      sta   <product+2
      lda   <product+3
      adc   <multiplicand+1
.rotate_r
      ror   a               ; rotate partial product
      sta   <product+3
      ror   <product+2
      ror   <product+1
      ror   <product
      dex
    bne   .shift_r
rts

mult8.16:
      lda   #$00
      sta   <product+2      ; clear upper bits of product
      sta   <product+3
      ldx   #$8            ; set binary count to 16
.shift_r
      lsr   <multiplier+1   ; divide multiplier by 2
      ror   <multiplier
    bcc .rotate_r
      lda   <product+2      ; get upper half of product and add multiplicand
      clc
      adc   <multiplicand
      sta   <product+2
      lda   <product+3
      adc   <multiplicand+1
.rotate_r
      ror   a               ; rotate partial product
      sta   <product+3
      ror   <product+2
      ror   <product+1
      ror   <product
      dex
    bne   .shift_r
rts


