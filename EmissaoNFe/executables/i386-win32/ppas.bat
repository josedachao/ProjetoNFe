@echo off
SET THEFILE=C:\Users\ASUSTUFI56600K\Desktop\ProjetoNFe\ProjetoNFe\EmissaoNFe\executables\i386-win32\nfeminima_emite.exe
echo Linking %THEFILE%
C:\lazarus\fpc\3.2.2\bin\i386-win32\ld.exe -b pei-i386 -m i386pe  --gc-sections  -s  --entry=_mainCRTStartup    -o C:\Users\ASUSTUFI56600K\Desktop\ProjetoNFe\ProjetoNFe\EmissaoNFe\executables\i386-win32\nfeminima_emite.exe C:\Users\ASUSTUFI56600K\Desktop\ProjetoNFe\ProjetoNFe\EmissaoNFe\executables\i386-win32\link15400.res
if errorlevel 1 goto linkend
C:\lazarus\fpc\3.2.2\bin\i386-win32\postw32.exe --subsystem console --input C:\Users\ASUSTUFI56600K\Desktop\ProjetoNFe\ProjetoNFe\EmissaoNFe\executables\i386-win32\nfeminima_emite.exe --stack 16777216
if errorlevel 1 goto linkend
goto end
:asmend
echo An error occurred while assembling %THEFILE%
goto end
:linkend
echo An error occurred while linking %THEFILE%
:end
