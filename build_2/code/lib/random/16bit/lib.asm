;
; Source: https://codebase64.org/doku.php?id=base:16bit_xorshift_random_generator
; Author: Veikko Sariola
;
;


;..................................................................
;
; You can get 8-bit random numbers in A or 16-bit numbers
; from the zero page addresses. Leaves X/Y unchanged.

random.rnd:
        lda random.RNG.hi
        lsr a
        lda random.RNG.lo
        ror a
        eor random.RNG.hi
        sta random.RNG.hi ; high part of x ^= x << 7 done
        ror a            ; A has now x >> 9 and high bit comes from low byte
        eor random.RNG.lo
        sta random.RNG.lo  ; x ^= x >> 9 and the low part of x ^= x << 7 done
        eor random.RNG.hi
        sta random.RNG.hi ; x ^= x << 8 done
  rts

