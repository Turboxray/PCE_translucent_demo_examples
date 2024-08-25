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

; Scaling tables for packed 4bit signed deltas as byte input.
;
;
;

"""

class RGBScalerTables():

    def __init__(self, args):

        self.args    = args
        self.output  = f'{args.output}.inc'
        self.colRule = [' 0',' 1',' 2',' 3',' 4',' 5',' 6',' 7','x_','-7','-6','-5','-4','-3','-2','-1']

    def process(self):

        outputInc = []
        lutVals = [[]]*8
        outputInc.append(BlockHeaderComment)
        for scalar in range(8,0,-1):
            scale = (scalar) / 8.0
            outputInc.append(f'\n\npalDeltaScale_{scalar}:')
            outputInc.append(f'    ; Scaled by {scale:.3}\n')
            outputInc.append(f'     ;  0   1   2   3   4   5   6   7  _x  -7  -6  -5  -4  -3  -2  -1\n')
            for rDelta in range(16):
                lineStr = f'  .db '
                rowIdx = rDelta
                # Safe guard because you never know with floating point numbers..
                rDelta  = (rDelta,rDelta-16)[rDelta > 7]
                if scalar != 8:
                    rDelta = int(rDelta * scale)
                rDelta  = (rDelta,0)[rowIdx == 8]

                for bDelta in range(16):
                    colIdx = bDelta

                    bDelta = (bDelta,bDelta-16)[bDelta > 7]

                    # Safe guard because you never know with floating point numbers..
                    if scalar != 8:
                        bDelta = int(bDelta * scale)

                    bDelta  =  (bDelta,0)[colIdx == 8]
                    
                    # debug
                    # print(f' scale: {scale:.3}. r: {rowIdx}, {rDelta}, b: {colIdx}, {bDelta}.   scalar: {scalar}')

                    redVal  = (rDelta << 4) & 0xf0
                    blueVal = bDelta & 0xF
                    print(f' red val [{redVal}], blye val [{blueVal}]')
                    RB_val =  redVal | blueVal
                    val = hex(RB_val)[2:]
                    val = '0'*(2-len(val)) + val
                    lineStr = lineStr + f'${val}'
                    lineStr += ('',',')[colIdx!=15]

                lineStr = lineStr + f'    ; {self.colRule[rowIdx]}\n'
                outputInc.append(lineStr)

        try:
            with open (self.output,'w') as fout:
                for line in outputInc:
                    fout.write(line)
        except Exception as e:
            print('Error with output file:\n   {e}')
            sys.exit(1)
    

def auto_int(val):
    return int(val, (DECbase,HEXbase)[val.startswith('0x')])
if __name__ == "__main__":

    parser = argparse.ArgumentParser(description=f'Build palette fade scalar LUTs. Ver {APP_VERSION}',
                                      formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--output',
                        '-o',
                        default='palfade_LUT',
                        help='File output name')
    args = parser.parse_args()

    RGBScalerTables(args).process()