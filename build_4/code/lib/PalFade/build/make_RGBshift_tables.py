import argparse
import numpy
import os
import sys
import glob
import shutil
from pathlib import Path
from PIL import Image

APP_VERSION = "1.0.0"

HEXbase = 16
DECbase = 10

BlockHeaderComment = """

; Look up tables for converting to/from VCE format (GRB) and expanded format (_G_R_B).
;
; VCE GRB format is 9bits:
;
;    lsb = (g)RB.
;        Bits: 0-2 -> Blue
;        Bits: 3-5 -> Red
;        Bits: 6-7 -> Green    
;            Note: Last upper bit of Green is in MSB
;    msb = G(rb).
;        Bits: 1 -> Green    
;            Note: no red, blue in this MSB. Only the higest bit of green.
;
; Expanded _G_R_B format is 12bits:
;
;    lsb = _R_B
;        Bits: 0-2 -> Blue
;        Bits: 3 -> reserved (must be 0)
;        Bits: 4-6 -> Red
;        Bits: 7 -> reserved (must be 0)
;    msb = _G
;        Bits: 0-2 -> Green
;        Bits: 3-7 -> reserved (must be 0)
    
"""

class RGBScalerTables():

    def __init__(self, args):

        self.args    = args
        self.output  = f'{args.output}.inc'
        self.colRule = [' 0',' 1',' 2',' 3',' 4',' 5',' 6',' 7','xx','-7','-6','-5','-4','-3','-2','-1']
        self.outputInc = []

    def process(self):

        pcetoExpanded_lo = []
        pcetoExpanded_hi = []
        outputInc = self.outputInc

        outputInc.append(BlockHeaderComment)

        self.createRBdepackTable()
        self.createGreendepackTable()
        self.createRBpackTable()
        self.createGreenpackTable()


        try:
            with open (self.output,'w') as fout:
                for line in self.outputInc:
                    fout.write(line)
        except Exception as e:
            print('Error with output file:\n   {e}')
            sys.exit(1)

    def createGreenpackTable(self):
        outputInc = self.outputInc
        outputInc.append(f'\n\npackG2VCE.LUT.lsb:\n')
        outputInc.append(f'    ; _G -> G(rb).lsb \n')
        outputInc.append(f'  .db ')
        lineStr = ""
        for g in range(8):
            g_idx = g
            g = (g & 0x3) << 6
            val = hex(g)[2:]
            val = '0'*(2-len(val)) + val
            lineStr = lineStr +f' ${val}'
            lineStr += ('',',')[g_idx!=7]
        outputInc.append(lineStr + "\n")

        outputInc.append(f'\n\npackG2VCE.LUT.msb:\n')
        outputInc.append(f'    ; _G -> G(rb).msb \n')
        outputInc.append(f'  .db ')
        lineStr = ""
        for g in range(8):
            g_idx = g
            g = g >> 2
            val = hex(g)[2:]
            val = '0'*(2-len(val)) + val
            lineStr = lineStr +f' ${val}'
            lineStr += ('',',')[g_idx!=7]
        outputInc.append(lineStr + "\n")

    def createGreendepackTable(self):
        outputInc = self.outputInc
        outputInc.append(f'\n\ndepackVCE2G.LUT.lsb:\n')
        outputInc.append(f'    ; GRB.lsb -> _G & 0x03 \n')
        outputInc.append(f';       _0   _1   _2   _3   _4   _5   _6   _7  \n')
        outputInc.append(f'  .db ')
        valCount = 0
        lineStr = ""
        for rgbColor in range(256):
            b = ((rgbColor >> 0) & 0x7)
            r = ((rgbColor >> 3) & 0x7)
            g = ((rgbColor >> 6) & 0x7)

            G_val = g
            val = hex(G_val)[2:]
            val = '0'*(2-len(val)) + val
            lineStr = lineStr + f' ${val}'
            valCount += 1
            if valCount == 8:
                outputInc.append(lineStr + f"  ; RGB as {rgbColor}  \n")
                valCount = 0
                lineStr  = f'  .db '
            else:
                lineStr += ","


        outputInc = self.outputInc
        outputInc.append(f'\n\ndepackVCE2G.LUT.msb:\n')
        outputInc.append(f'    ; GRB.msb -> _G << 2 \n')
        outputInc.append(f'  .db $00, $04\n')


    def createRBdepackTable(self):
        outputInc = self.outputInc
        outputInc.append(f'\n\ndepackVCE2RB.LUT:\n')
        outputInc.append(f'    ; GRB.lsb -> _R_B\n')
        outputInc.append(f'; BLUE  _0   _1   _2   _3   _4   _5   _6   _7  \n')
        outputInc.append(f'  .db ')
        valCount = 0
        lineStr = ""
        for rgbColor in range(256):
            b = ((rgbColor >> 0) & 0x7)
            r = ((rgbColor >> 3) & 0x7)

            RB_val = ((r & 0xF) << 4) | (b & 0xF)
            val = hex(RB_val)[2:]
            val = '0'*(2-len(val)) + val
            lineStr = lineStr + f' ${val}'
            valCount += 1
            if valCount == 8:
                outputInc.append(lineStr + f"  ; {r}_  RED.    Green as {rgbColor>>6}  \n")
                valCount = 0
                lineStr  = f'  .db '
            else:
                lineStr += ","


    def createRBpackTable(self):
        outputInc = self.outputInc
        outputInc.append(f'\n\npackRB2VCE.LUT:\n')
        outputInc.append(f'    ; _R_B - > (g)RB.lsb \n')
        outputInc.append(f'; BLUE  _0   _1   _2   _3   _4   _5   _6   _7  \n')
        outputInc.append(f'  .db ')
        valCount = 0
        lineStr = ""
        for r in range(16):
            for b in range(16):

                RB_val = ((r & 0x7) << 3) | (b & 0x7)
                val = hex(RB_val)[2:]
                val = '0'*(2-len(val)) + val
                lineStr = lineStr + f' ${val}'
                valCount += 1
                if valCount == 8:
                    outputInc.append(lineStr + f"  ; {r}_  RED.\n")
                    valCount = 0
                    lineStr  = f'  .db '
                else:
                    lineStr += ","


def auto_int(val):
    return int(val, (DECbase,HEXbase)[val.startswith('0x')])
if __name__ == "__main__":

    parser = argparse.ArgumentParser(description=f'Build palette LUTs for bitpacking and unpacking. Ver {APP_VERSION}',
                                      formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--output',
                        '-o',
                        default='palColorConv_LUT',
                        help='File output name')
    args = parser.parse_args()

    RGBScalerTables(args).process()