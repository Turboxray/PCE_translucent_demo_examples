cd ../assets/BG_map/

call convert_tmx.bat --filein level1_layer1_test1.tmx --fileout level1_SPRlayer --colOffset 85

call build_BBG.bat

del level1_BBG.map
del level1_BBG.tle
del level1_BBG.pal

ren pce_0.map level1_BBG.map
ren pce.tle level1_BBG.tle
ren pce.pal level1_BBG.pal

cd ../status_bar/
call build_SBAR.bat
call build_debugtiles.bat

cd ../player/
call convert_player.bat

cd ../../main
pceas -raw main.asm -l 3 -S
c:\Projects\PCE_DEV\meddy\mednafen.exe main.pce
pause