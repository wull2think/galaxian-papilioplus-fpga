@echo off

REM 69fe5dfbe6cde18ef4cae62da12b5c692c2c72b9 bh1
REM 720ce7af05ef596fb9a109591534c74d282955e8 bh2
REM 088bbbde66b7b5c36fa48cf14c22146e1444e67c bh3
REM d9b32db048a0e2a1195cd6f7326005e6622242a9 bh4
REM 3ed1ee0bc199c1625156d2771eecd18a57a0e6ed bh5
REM 430261bafe20fc182e6e6659019cf42643e95d54 bh6
REM c50d55f6ab81b803d67f5e18c1243ef85a1a2df1 bh7
REM 5768b573fac9aac168db2723462cca76d4d80552 bh8
REM f382ad5a34d282056c78a5ec00c30ec43772bae2 6l.bpr

set rom_path_src=..\roms\blkhole
set rom_path=..\build
set romgen_path=..\romgen_source

REM concatenate consecutive ROM regions
copy /b/y %rom_path_src%\bh7 + %rom_path_src%\bh8 %rom_path%\gfx1.bin > NUL
copy /b/y %rom_path_src%\bh1 + %rom_path_src%\bh2 + %rom_path_src%\bh3 + %rom_path_src%\bh4 + %rom_path_src%\bh5 + %rom_path_src%\bh6 %rom_path%\main.bin > NUL

REM generate RTL code for small PROMS
REM %romgen_path%\romgen %rom_path_src%\6l.bpr    GALAXIAN_6L  5 c     > %rom_path%\galaxian_6l.vhd
%romgen_path%\romgen %rom_path_src%\6l.bpr    GALAXIAN_6L  5 l r e     > %rom_path%\galaxian_6l.vhd

REM generate RAMB structures for larger ROMS
%romgen_path%\romgen %rom_path%\gfx1.bin        GFX1      12 l r e > %rom_path%\gfx1.vhd
%romgen_path%\romgen %rom_path%\main.bin        ROM_PGM_0 14 l r e > %rom_path%\rom0.vhd

%romgen_path%\romgen %rom_path_src%\bh7       GALAXIAN_1H 11 l r e > %rom_path%\galaxian_1h.vhd
%romgen_path%\romgen %rom_path_src%\bh8       GALAXIAN_1K 11 l r e > %rom_path%\galaxian_1k.vhd

REM %romgen_path%\romgen %rom_path_src%\mc_wav_2.bin GALAXIAN_WAV 18 l r e > %rom_path%\galaxian_wav.vhd

echo done
pause
