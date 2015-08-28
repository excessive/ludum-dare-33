@echo on
set cwd="%~dp0"
set love="%cwd%bin\love.exe"
set b7z="%cwd%bin\7z.exe"
set output=shark-swimulator
@echo on

%b7z% a -tzip %output%.love %cwd%*.lua %cwd%assets %cwd%libs %cwd%ffi %cwd%scenes %cwd%systems -mmt -mx0

copy /b %love%+%output%.love %output%.exe

%b7z% a -tzip %output%-win32.zip %cwd%%output%.exe %cwd%bin/love.dll %cwd%bin/lua51.dll %cwd%bin/mpg123.dll %cwd%bin/OpenAL32.dll %cwd%bin/SDL2.dll %cwd%bin/msvcp120.dll %cwd%bin/msvcr120.dll

REM del %output%.love
del %output%.exe
