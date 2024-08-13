
; Source: codebase64.org

; Performance: low end is ~860+ cycles and cap is ~960

slow16.divisor   = R0    
slow16.dividend  = R1     
slow16.remainder = R2     
slow16.result    = dividend 

slow16bitDiv:

      stz <remainder      ;preset remainder to 0
      stz <remainder+1
      ldx #16             ;repeat for each bit: ...

.divloop   
      asl <dividend       ;dividend lb & hb*2, msb -> Carry
      rol <dividend+1   
      rol <remainder      ;remainder lb & hb * 2 + msb from carry
      rol <remainder+1
      lda <remainder
      sec
      sbc <divisor        ;substract divisor to see if it fits in
      tay                 ;lb result -> Y, for we may need it later
      lda <remainder+1
      sbc <divisor+1
    bcc .skip             ;if carry=0 then divisor didn't fit in yet

      sta <remainder+1    ;else save substraction result as new remainder,
      sty <remainder   
      inc <result         ;and INCrement result cause divisor fit in 1 times

.skip   
      dex
     bne .divloop   
   rts