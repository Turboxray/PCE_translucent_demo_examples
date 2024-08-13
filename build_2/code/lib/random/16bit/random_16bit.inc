



Random.seed .macro

      .if (\?1=2)
          lda #low(\1)
          sta random.RNG.lo
          lda #high(\1)
          sta random.RNG.hi
      .endif

      .if (\?1=1)
          sta random.RNG.lo
          stx random.RNG.hi
      .endif

      .if (\?1=3)
          lda \1
          sta random.RNG.lo
          lda \1+1
          sta random.RNG.hi
      .endif

      .if (\?1=3)
          lda \1
          sta random.RNG.lo
          lda \1+1
          sta random.RNG.hi
      .endif

      .if (\?1=6)
          lda \1
          sta random.RNG.lo
          lda \1+1
          sta random.RNG.hi
      .endif

      .if (\?1=4)
          lda [\1]
          sta random.RNG.lo
          ldy #$01
          lda [\1],y
          sta random.RNG.hi
      .endif


  .endm

