loadCellToVram  .macro

      .if (\# = 2)
            MAP_BANK.2 #(\1.cell) , MPR2
            sVDC.reg MAWR, #\2
            sVDC.reg VRWR
            DMA.word.port \1.cell, Page.2, vdata_port, \1.cell.size
      .endif

      .if (\# = 1)
            MAP_BANK.2 #(\1.cell) , MPR2
            DMA.word.port \1.cell, Page.2, vdata_port, \1.cell.size
      .endif
  .endm

loadCellToVram.3banks  .macro

      .if (\# = 2)
            MAP_BANK.3 #(\1.cell) , MPR2
            sVDC.reg MAWR, #\2
            sVDC.reg VRWR
            DMA.word.port \1.cell, Page.2, vdata_port, \1.cell.size
      .endif

      .if (\# = 1)
            MAP_BANK.3 #(\1.cell) , MPR2
            DMA.word.port \1.cell, Page.2, vdata_port, \1.cell.size
      .endif
  .endm

loadCellToVram.4banks  .macro

      .if (\# = 2)
            MAP_BANK.4 #(\1.cell) , MPR2
            sVDC.reg MAWR, #\2
            sVDC.reg VRWR
            DMA.word.port \1.cell, Page.2, vdata_port, \1.cell.size
      .endif

      .if (\# = 1)
            MAP_BANK.4 #(\1.cell) , MPR2
            DMA.word.port \1.cell, Page.2, vdata_port, \1.cell.size
      .endif
  .endm

loadCellToCram.BG  .macro

        MAP_BANK.2 #(\1.pal) , MPR2
        VCE.BGblock \2
        DMA.word.port \1.pal, Page.2, vce_data, \1.pal.size
  .endm

loadCellToCram.SPR  .macro

        MAP_BANK.2 #(\1.pal) , MPR2
        VCE.SPRblock \2
        DMA.word.port \1.pal, Page.2, vce_data, \1.pal.size
  .endm

debugBENCH  .macro
.ifdef DEBUG_BENCHMARK
      stz $402
      lda #$1
      sta $403
      lda #low((\1<<3) + (\2<<6) + (\3))
      sta $404
      lda #high((\1<<3) + (\2<<6) + (\3))
      sta $405
      ; MAP_BANK.2 #(\1.pal) , MPR2
      ; VCE.SPRblock \2
      ; DMA.word.port \1.pal, Page.2, vce_data, \1.pal.size
.endif
  .endm

loadDataToVram.4banks  .macro

        sVDC.reg MAWR, #\2
        sVDC.reg VRWR
        MAP_BANK.4 #(\1) , MPR2
        DMA.word.port \1, Page.2, vdata_port, (\1.size)

  .endm

loadDataToVram.3banks  .macro

        sVDC.reg MAWR, #\2
        sVDC.reg VRWR
        MAP_BANK.3 #(\1) , MPR2
        DMA.word.port \1, Page.2, vdata_port, (\1.size)

  .endm

loadDataToVram.2banks  .macro

        sVDC.reg MAWR, #\2
        sVDC.reg VRWR
        MAP_BANK.2 #(\1) , MPR2
        DMA.word.port \1, Page.2, vdata_port, (\1.size)

  .endm

loadDataToVram.1bank  .macro

        sVDC.reg MAWR, #\2
        sVDC.reg VRWR
        MAP_BANK #(\1) , MPR2
        DMA.word.port \1, Page.2, vdata_port, (\1.size)

  .endm

loadDataToVram  .macro

        sVDC.reg MAWR, #\2
        sVDC.reg VRWR
        MAP_BANK.2 #(\1) , MPR2
        DMA.word.port \1, Page.2, vdata_port, (\1.size)

  .endm


loadDataToCram.BG  .macro

        MAP_BANK.4 #(\1) , MPR2
        VCE.BGblock \2
        DMA.word.port \1, Page.2, vce_data, \1.size
  .endm
