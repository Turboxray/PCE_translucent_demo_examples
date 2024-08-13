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

class BuildPalette():

    def __init__(self,args):
        self.imageFile = args.file
        self.output    = args.output
        self.image     = []
        self.tilesets  = []

        self.errorMsg  = ''

        self.funcs = [
            self.openImage,
            self.convertImage,
            self.outputFiles
        ]

    def process(self):

        for initialFuncs in self.funcs:
            if not initialFuncs():
                print(f'{self.errorMsg}')
                sys.exit(1)                

    def outputFiles(self):
        for t_idx, tileset in enumerate(self.tilesets):
            try:
                with open(f'{self.output}_{t_idx}.tbin', 'wb') as f_out:
                    f_out.write(bytearray(tileset))
            except Exception as e:
                self.errorMsg = f'Error: Issue opening output file.\n{e}\n'
                return False

        return True


    def convertImage(self):
        result = False
        content = None

        # dependency ladder
        while True:

            # Not gonna bother padding images.
            if self.image.width != 72:
                self.errorMsg = f'Error: Source image need to have a width of 72px.\n'
                break                                          
            if self.image.height != 256:
                self.errorMsg = f'Error: Source image need to have a height of 256px.\n'
                break

            curr_image = numpy.asarray(self.image, dtype=numpy.uint8)

            
            height = self.image.height
            width  = self.image.width + 8

            for offset in range(8):

                image = numpy.zeros(shape=(self.image.height,self.image.width + 8), dtype=numpy.uint8)
                for y in range(self.image.height):
                    for x in range(self.image.width):
                        image[y,x+offset] = curr_image[y,x]
                
                # debug
                # newImage = Image.fromarray(image)
                # newImage.save(f'{offset}.png')

                # Create tiles data from image
                tileset = [[]]*(height//8)
                for row in range(0,height,8):
                    tileset[row//8] = []
                    for col in range(0,width,8):
                        tile = [[]]*8
                        for y in range(8):
                            px_row = []
                            for x in range(8):
                                p = int(image[(row)+y , (col)+x])
                                p = (p,0)[p>4]
                                p = (p,1)[p==4]
                                px_row.append(p)
                            tile[y] = px_row[:]
                        tileset[row//8].append(tile[:])

                # Create planar 2bpp planar
                planar_tileset = [[]]*(height//8)
                temptileset = []
                for row in range(height//8):
                    for col in range(width//8):
                        tile = tileset[row][col]
                        planar_tile = [[]]*8
                        for y in range(8):
                            plane0 = 0
                            plane1 = 0
                            for x in range(8):
                                p = tile[y][x]
                                plane0 |= (p & 0x1) << (7-x)
                                plane1 |= (p >>  1) << (7-x)
                            planar_tile[y] = (plane0,plane1)
                            temptileset.append(plane0)
                            temptileset.append(plane1)
                        planar_tileset[row].append(planar_tile[:])
                
                self.tilesets.append(temptileset[:])


            # source images are ready!
            result = True
            break

        return result  

    def openImage(self):
    
        try:
            self.image = Image.open(self.imageFile)
        except Exception as e:
            self.errorMsg = f'Error opening {self.imageFile}\n{e}'
            return False
        if self.image.mode != 'P':
            self.errorMsg = f'Error: Image needs to be in 8bit index mode. Current image is in {self.image.mode} mode.\n'
            return False            

        return True

    #..............................................................
    # helper funcs        
    def openFile(self, aFile, name):
        try:
            with open(aFile,'r') as f_in:
                content = f_in.read()
        except Exception as e:
            self.errorMsg = f'Error: Problem opening {name} file.\n{e}'
        
        if not content:
            self.errorMsg = f'Error: the {name} file is empty.\n'
        
        return content

def auto_int(val):
    return int(val, (DECbase,HEXbase)[val.startswith('0x')])
if __name__ == "__main__":

    parser = argparse.ArgumentParser(description=f'Build palette colors from image. Ver {APP_VERSION}',
                                      formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--file',
                        '-i',
                        required=True,
                        default='',
                        help='Image to convert.')
    parser.add_argument('--output',
                        '-o',
                        default='test_',
                        help='Image to convert.')
    args = parser.parse_args()

    BuildPalette(args).process()
