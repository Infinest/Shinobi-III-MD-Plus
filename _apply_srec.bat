copy ROMS\in.md OUTPUT\out_temp.md
fsutil file seteof OUTPUT\out_temp.md 2097152
TOOLS\srecpatch.exe "OUTPUT\out_temp.md" OUTPUT\out.md<srecfile.txt
del "OUTPUT\out_temp.md"
del srecfile.txt