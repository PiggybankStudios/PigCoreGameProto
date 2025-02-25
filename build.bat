@echo off

if not exist _build mkdir _build
pushd _build
set root=..
set game=../game
set core=../core

:: +--------------------------------------------------------------+
:: |                    Scrape build_config.h                     |
:: +--------------------------------------------------------------+
python --version > NUL 2> NUL
if errorlevel 1 (
	echo WARNING: Python isn't installed on this computer. Defines cannot be extracted from build_config.h! And build numbers won't be incremented
	exit
)

set extract_define=python %core%\_scripts\extract_define.py ../build_config.h
for /f "delims=" %%i in ('%extract_define% DEBUG_BUILD') do set DEBUG_BUILD=%%i
for /f "delims=" %%i in ('%extract_define% BUILD_PIGGEN') do set BUILD_PIGGEN=%%i
for /f "delims=" %%i in ('%extract_define% BUILD_PIGGEN_IF_NEEDED') do set BUILD_PIGGEN_IF_NEEDED=%%i
for /f "delims=" %%i in ('%extract_define% RUN_PIGGEN') do set RUN_PIGGEN=%%i
for /f "delims=" %%i in ('%extract_define% BUILD_INTO_SINGLE_UNIT') do set BUILD_INTO_SINGLE_UNIT=%%i
for /f "delims=" %%i in ('%extract_define% BUILD_PIG_CORE_LIB') do set BUILD_PIG_CORE_LIB=%%i
for /f "delims=" %%i in ('%extract_define% BUILD_PIG_CORE_LIB_IF_NEEDED') do set BUILD_PIG_CORE_LIB_IF_NEEDED=%%i
for /f "delims=" %%i in ('%extract_define% BUILD_GAME_EXE') do set BUILD_GAME_EXE=%%i
for /f "delims=" %%i in ('%extract_define% BUILD_GAME_DLL') do set BUILD_GAME_DLL=%%i
for /f "delims=" %%i in ('%extract_define% RUN_GAME') do set RUN_GAME=%%i
for /f "delims=" %%i in ('%extract_define% COPY_TO_DATA_DIRECTORY') do set COPY_TO_DATA_DIRECTORY=%%i
for /f "delims=" %%i in ('%extract_define% DUMP_PREPROCESSOR') do set DUMP_PREPROCESSOR=%%i
for /f "delims=" %%i in ('%extract_define% BUILD_WINDOWS') do set BUILD_WINDOWS=%%i
for /f "delims=" %%i in ('%extract_define% BUILD_LINUX') do set BUILD_LINUX=%%i
for /f "delims=" %%i in ('%extract_define% PROJECT_DLL_NAME') do set PROJECT_DLL_NAME=%%i
for /f "delims=" %%i in ('%extract_define% PROJECT_EXE_NAME') do set PROJECT_EXE_NAME=%%i

:: +--------------------------------------------------------------+
:: |                      Init MSVC Compiler                      |
:: +--------------------------------------------------------------+
for /F "tokens=1-4 delims=:.," %%a in ("%time%") do (
	set /A "vsdevcmd_start_time=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100"
)
if "%BUILD_WINDOWS%"=="1" (
	REM set VSCMD_DEBUG=3
	REM NOTE: Uncomment or change one of these lines to match your installation of Visual Studio compiler
	REM call "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" amd64
	REM call "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvarsall.bat" amd64 -no_logo
	call "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat" -arch=x64 -host_arch=x64 > NUL
)
for /F "tokens=1-4 delims=:.," %%a in ("%time%") do (
	set /A "vsdevcmd_end_time=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100"
)
set /A vsdevcmd_elapsed_hundredths=vsdevcmd_end_time-vsdevcmd_start_time
set /A vsdevcmd_elapsed_seconds_part=vsdevcmd_elapsed_hundredths/100
set /A vsdevcmd_elapsed_hundredths_part=vsdevcmd_elapsed_hundredths%%100
if %vsdevcmd_elapsed_hundredths_part% lss 10 set vsdevcmd_elapsed_hundredths_part=0%vsdevcmd_elapsed_hundredths_part%
if "%BUILD_WINDOWS%"=="1" ( echo VsDevCmd.bat took %vsdevcmd_elapsed_seconds_part%.%vsdevcmd_elapsed_hundredths_part% seconds )

:: +--------------------------------------------------------------+
:: |                       Compiler Options                       |
:: +--------------------------------------------------------------+
:: /FC = Full path for error messages
:: /nologo = Suppress the startup banner
:: /W4 = Warning level 4 [just below /Wall]
:: /WX = Treat warnings as errors
:: /std:clatest = Use latest C language spec features
:: /experimental:c11atomics = Enables _Atomic types
set common_cl_flags=/FC /nologo /W4 /WX /std:clatest /experimental:c11atomics
:: -fdiagnostics-absolute-paths = Print absolute paths in diagnostics TODO: Figure out how to resolve these back to windows paths for Sublime error linking?
:: -std=gnu2x = Use C20+ language spec (NOTE: We originally had -std=c2x but that didn't define MAP_ANONYMOUS and mmap was failing)
:: NOTE: Clang Warning Options: https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html
:: -Wall = This enables all the warnings about constructions that some users consider questionable, and that are easy to avoid (or modify to prevent the warning), even in conjunction with macros.
:: -Wextra = This enables some extra warning flags that are not enabled by -Wall.
:: -Wshadow = Warn whenever a local variable or type declaration shadows another variable, parameter, type, class member (in C++), or instance variable (in Objective-C) or whenever a built-in function is shadowed
:: -Wimplicit-fallthrough = Must use [[fallthrough]] on a case label that falls through to the next case
set common_clang_flags=-fdiagnostics-absolute-paths -std=gnu2x -Wall -Wextra -Wshadow -Wimplicit-fallthrough
:: /wd4130 = Logical operation on address of string constant [W4] TODO: Should we re-enable this one? Don't know any scenarios where I want to do this
:: /wd4201 = Nonstandard extension used: nameless struct/union [W4] TODO: Should we re-enable this restriction for ANSI compatibility?
:: /wd4324 = Structure was padded due to __declspec[align[]] [W4]
:: /wd4458 = Declaration of 'identifier' hides class member [W4]
:: /wd4505 = Unreferenced local function has been removed [W4]
:: /wd4996 = Usage of deprecated function, class member, variable, or typedef [W3]
:: /wd4706 = assignment within conditional expression [W?]
:: /we5262 = Enable the [[fallthrough]] missing warning
set common_cl_flags=%common_cl_flags% /wd4130 /wd4201 /wd4324 /wd4458 /wd4505 /wd4996 /wd4706 /we5262
:: -Wno-switch = 8 enumeration values not handled in switch: 'ArenaType_None', 'ArenaType_Funcs', 'ArenaType_Generic'...
:: -Wno-unused-function = unused function 'MeowExpandSeed'
set common_clang_flags=%common_clang_flags% -Wno-switch -Wno-unused-function
:: /I = Adds an include directory to search in when resolving #includes
set common_cl_flags=%common_cl_flags% /I"%root%" /I"%game%" /I"%core%"
:: -I = Add directory to the end of the list of include search paths
:: -lm = Include the math library (required for stuff like sinf, atan, etc.)
:: -ldl = Needed for dlopen and similar functions
:: -mssse3 = For MeowHash to work we need sse3 support
:: -maes = For MeowHash to work we need aes support
set linux_clang_flags=-lm -ldl -L "." -I "../%root%" -I "../%game%" -I "../%core%" -mssse3 -maes
if "%DEBUG_BUILD%"=="1" (
	REM /MDd = ?
	REM /Od = Optimization level: Debug
	REM /Zi = Generate complete debugging information
	REM /wd4065 = Switch statement contains 'default' but no 'case' labels
	REM /wd4100 = Unreferenced formal parameter [W4]
	REM /wd4101 = Unreferenced local variable [W3]
	REM /wd4127 = Conditional expression is constant [W4]
	REM /wd4189 = Local variable is initialized but not referenced [W4]
	REM /wd4702 = Unreachable code [W4]
	set common_cl_flags=%common_cl_flags% /MDd /Od /Zi /wd4065 /wd4100 /wd4101 /wd4127 /wd4189 /wd4702
	REM -Wno-unused-parameter = warning: unused parameter 'numBytes'
	set common_clang_flags=%common_clang_flags% -Wno-unused-parameter -Wno-unused-variable
) else (
	REM /MD = ?
	REM /Ot = Favors fast code over small code
	REM /Oy = Omit frame pointer [x86 only]
	REM /O2 = Optimization level 2: Creates fast code
	REM /Zi = Generate complete debugging information [optional]
	set common_cl_flags=%common_cl_flags% /MD /Ot /Oy /O2
	set common_clang_flags=%common_clang_flags%
)

:: -incremental:no = Suppresses warning about doing a full link when it can't find the previous .exe result. We don't need this when doing unity builds
:: /LIBPATH = Add a library search path
set common_ld_flags=-incremental:no
:: gdi32.lib    = ?
:: User32.lib   = ?
:: Shell32.lib  = Shlobj.h ? 
:: kernel32.lib = ?
:: winmm.lib    = ?
:: Winhttp.lib  = ?
:: Shlwapi.lib  = ?
:: Ole32.lib    = Combaseapi.h, CoCreateInstance
:: Advapi32.lib = Processthreadsapi.h, OpenProcessToken, GetTokenInformation
set common_ld_flags=%common_ld_flags% gdi32.lib User32.lib Shell32.lib kernel32.lib winmm.lib
:: TODO:: Compiling for Linux with raylib would require following instructions here: https://github.com/raysan5/raylib/wiki/Working-on-GNU-Linux

if "%BUILD_INTO_SINGLE_UNIT%"=="1" (
	set common_ld_flags=%common_ld_flags% raylib.lib
) else (
	set common_ld_flags=%common_ld_flags% raylibdll.lib
)

if "%DEBUG_BUILD%"=="1" (
	set common_ld_flags=%common_ld_flags% /LIBPATH:"%root%\third_party\_lib_debug" /LIBPATH:"%core%\third_party\_lib_debug"
) else (
	set common_ld_flags=%common_ld_flags% /LIBPATH:"%root%\third_party\_lib_release" /LIBPATH:"%core%\third_party\_lib_release"
)

set pig_core_defines=/DBUILD_WITH_RAYLIB=1 /DPIG_CORE_DLL_INCLUDE_GFX_SYSTEM_GLOBAL=1

if "%DUMP_PREPROCESSOR%"=="1" (
	REM /P = Output the result of the preprocessor to {file_name}.i (disables the actual compilation)
	REM /C = Preserve comments through the preprocessor
	set common_cl_flags=/P /C %common_cl_flags%
	REM -E = Only run the preprocessor
	set common_clang_flags=%common_clang_flags% -E
)

for /F "tokens=1-4 delims=:.," %%a in ("%time%") do (
	set /A "build_start_time=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100"
)

:: +--------------------------------------------------------------+
:: |                       Build piggen.exe                       |
:: +--------------------------------------------------------------+
:: /Fe = Set the output exe file name
set piggen_source_path=%core%/piggen/piggen_main.c
set piggen_exe_path=piggen.exe
set piggen_cl_args=%common_cl_flags% /Fe%piggen_exe_path% %piggen_source_path% /link %common_ld_flags%

if "%BUILD_PIGGEN_IF_NEEDED%"=="1" (
	if not exist %piggen_exe_path% (
		set BUILD_PIGGEN=1
	)
)

if "%BUILD_PIGGEN%"=="1" (
	echo.
	echo [Building piggen...]
	del %piggen_exe_path% > NUL 2> NUL
	cl %piggen_cl_args%
	echo [Built piggen!]
)

if "%RUN_PIGGEN%"=="1" (
	echo.
	echo [%piggen_exe_path%]
	%piggen_exe_path% %core%
	%piggen_exe_path% %game%
)

:: +--------------------------------------------------------------+
:: |                      Build pig_core.dll                      |
:: +--------------------------------------------------------------+
set pig_core_source_path=%core%/dll/dll_main.c
set pig_core_dll_path=pig_core.dll
set pig_core_lib_path=pig_core.lib
set pig_core_so_path=libpig_core.so
set pig_core_cl_args=%common_cl_flags% %pig_core_defines% /Fe%pig_core_dll_path% %pig_core_source_path% /link %common_ld_flags% /DLL
:: -fPIC = "Position Independent Code" (Required for globals to work properly?)
:: -shared = ?
set pig_core_clang_args=%common_clang_flags% %linux_clang_flags% -fPIC -shared -o %pig_core_so_path% ../%pig_core_source_path%

if "%BUILD_PIG_CORE_LIB_IF_NEEDED%"=="1" (
	if "%BUILD_WINDOWS%"=="1" (
		if not exist %pig_core_dll_path% (
			set BUILD_PIG_CORE_LIB=1
		)
	)
	if "%BUILD_LINUX%"=="1" (
		if not exist linux\%pig_core_so_path% (
			set BUILD_PIG_CORE_LIB=1
		)
	)
)

if "%BUILD_INTO_SINGLE_UNIT%"=="1" (
	if "%BUILD_WINDOWS%"=="1" (
		del "%pig_core_dll_path%" > NUL 2> NUL
		del "%pig_core_lib_path%" > NUL 2> NUL
	)
	if "%BUILD_LINUX%"=="1" (
		del "linux\%pig_core_so_path%" > NUL 2> NUL
	)
) else (
	if "%BUILD_PIG_CORE_LIB%"=="1" (
		if "%BUILD_WINDOWS%"=="1" (
			del "%pig_core_dll_path%" > NUL 2> NUL
			del "%pig_core_lib_path%" > NUL 2> NUL
			
			echo.
			echo [Building %pig_core_dll_path% for Windows...]
			cl %pig_core_cl_args%
			echo [Built %pig_core_dll_path% for Windows!]
			
			if "%COPY_TO_DATA_DIRECTORY%"=="1" (
				COPY %pig_core_dll_path% %root%\_data\%pig_core_dll_path% > NUL
			)
		)
		if "%BUILD_LINUX%"=="1" (
			echo.
			echo [Building %pig_core_so_path% for Linux...]
			if not exist linux mkdir linux
			pushd linux
			
			del "%pig_core_so_path%" > NUL 2> NUL
			wsl clang-18 %pig_core_clang_args%
			
			popd
			echo [Built %pig_core_so_path% for Linux!]
		)
	)
)

:: +--------------------------------------------------------------+
:: |                        Build game.exe                        |
:: +--------------------------------------------------------------+
set platform_source_path=%game%/platform_main.c
set platform_exe_path=%PROJECT_EXE_NAME%.exe
set platform_bin_path=%PROJECT_EXE_NAME%
set platform_cl_args=%common_cl_flags% /Fe%platform_exe_path% %platform_source_path% /link %common_ld_flags%
set platform_clang_args=%common_clang_flags% %linux_clang_flags% -o %platform_bin_path% ../%platform_source_path%
if "%BUILD_INTO_SINGLE_UNIT%"=="0" (
	REM -rpath = Add to RPATH so that libpig_core.so can be found in this folder (it doesn't need to be copied to any system folder)
	set platform_cl_args=%platform_cl_args% %pig_core_lib_path%
	set platform_clang_args=-lpig_core -rpath "." %platform_clang_args% 
)

if "%BUILD_GAME_EXE%"=="1" (
	if "%BUILD_WINDOWS%"=="1" (
		del %platform_exe_path% > NUL 2> NUL
		
		echo.
		echo [Building %platform_exe_path% for Windows...]
		cl %platform_cl_args%
		echo [Built %platform_exe_path% for Windows!]
		
		if "%COPY_TO_DATA_DIRECTORY%"=="1" (
			COPY %platform_exe_path% %root%\_data\%platform_exe_path% > NUL
		)
	)
	if "%BUILD_LINUX%"=="1" (
		echo.
		echo [Building %platform_bin_path% for Linux...]
		if not exist linux mkdir linux
		pushd linux
		
		del %platform_bin_path% > NUL 2> NUL
		wsl clang-18 %platform_clang_args%
		
		popd
		echo [Built %platform_bin_path% for Linux!]
	)
)

set game_source_path=%game%/game_main.c
set game_dll_path=%PROJECT_DLL_NAME%.dll
set game_so_path=%PROJECT_DLL_NAME%.so
set game_dll_cl_args=%common_cl_flags% /Fe%game_dll_path% %game_source_path% /link %common_ld_flags% %pig_core_lib_path% /DLL
set game_dll_clang_args=%common_clang_flags% %linux_clang_flags% -shared -lpig_core  -o %game_so_path% ../%game_source_path%

if "%BUILD_INTO_SINGLE_UNIT%"=="1" (
	if "%BUILD_WINDOWS%"=="1" (
		del "%game_dll_path%" > NUL 2> NUL
	)
	if "%BUILD_LINUX%"=="1" (
		del "linux\%game_so_path%" > NUL 2> NUL
	)
) else (
	if "%BUILD_GAME_DLL%"=="1" (
		if "%BUILD_WINDOWS%"=="1" (
			del %game_dll_path% > NUL 2> NUL
			
			echo.
			echo [Building %game_dll_path% for Windows...]
			cl %game_dll_cl_args%
			echo [Built %game_dll_path% for Windows!]
			
			if "%COPY_TO_DATA_DIRECTORY%"=="1" (
				COPY %game_dll_path% %root%\_data\%game_dll_path% > NUL
			)
		)
		if "%BUILD_LINUX%"=="1" (
			echo.
			echo [Building %game_so_path% for Linux...]
			if not exist linux mkdir linux
			pushd linux
			
			del %game_so_path% > NUL 2> NUL
			wsl clang-18 %game_dll_clang_args%
			
			popd
			echo [Built %game_so_path% for Linux!]
		)
	)
)

:: +--------------------------------------------------------------+
:: |                  Measure Build Elapsed Time                  |
:: +--------------------------------------------------------------+
for /F "tokens=1-4 delims=:.," %%a in ("%time%") do (
	set /A "build_end_time=(((%%a*60)+1%%b %% 100)*60+1%%c %% 100)*100+1%%d %% 100"
)
set /A build_elapsed_hundredths=build_end_time-build_start_time
set /A build_elapsed_seconds_part=build_elapsed_hundredths/100
set /A build_elapsed_hundredths_part=build_elapsed_hundredths%%100
if %build_elapsed_hundredths_part% lss 10 set build_elapsed_hundredths_part=0%build_elapsed_hundredths_part%
echo.
echo Build took %build_elapsed_seconds_part%.%build_elapsed_hundredths_part% seconds

:: +--------------------------------------------------------------+
:: |                          Run Things                          |
:: +--------------------------------------------------------------+

if "%RUN_GAME%"=="1" (
	echo.
	echo [%platform_exe_path%]
	%platform_exe_path%
)

echo.
popd