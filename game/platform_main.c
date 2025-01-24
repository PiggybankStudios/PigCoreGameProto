/*
File:   main.c
Author: Taylor Robbins
Date:   01\19\2025
Description: 
	** Holds the main entry point for the game and #includes all source files
	** that are needed for the game to build
*/

#include "build_config.h"
#define PIG_CORE_IMPLEMENTATION BUILD_INTO_SINGLE_UNIT
#define BUILD_WITH_RAYLIB TARGET_IS_WINDOWS

#include "base/base_all.h"
#include "std/std_all.h"
#include "os/os_all.h"
#include "misc/misc_all.h"
#include "mem/mem_all.h"
#include "struct/struct_all.h"
#include "gfx/gfx_all.h"

#if BUILD_WITH_RAYLIB
#include "third_party/raylib/raylib.h"
#endif

// +--------------------------------------------------------------+
// |                         Header Files                         |
// +--------------------------------------------------------------+
#include "defines.h"

// +--------------------------------------------------------------+
// |                           Globals                            |
// +--------------------------------------------------------------+
Arena* stdHeap = nullptr;

// +--------------------------------------------------------------+
// |                         Source Files                         |
// +--------------------------------------------------------------+
#include "raylib_interface.c"

// +--------------------------------------------------------------+
// |                       Main Entry Point                       |
// +--------------------------------------------------------------+
int main()
{
	Arena stdHeapLocal = ZEROED;
	InitArenaStdHeap(&stdHeapLocal);
	stdHeap = &stdHeapLocal;
	InitScratchArenasVirtual(Gigabytes(4));
	
	ScratchBegin(loadScratch);
	
	#if BUILD_WITH_RAYLIB
	SetTraceLogCallback(RaylibLogCallback);
	InitWindow(800, 600, PROJECT_READABLE_NAME_STR);
	SetWindowMinSize(400, 200);
	SetWindowState(FLAG_WINDOW_RESIZABLE);
	SetTargetFPS(60);
	
	FilePath checkerFilePath = FilePathLit("resources/image/pig_checker_blue.png");
	#if 1
	Texture2D checkerTexture = LoadTexture(checkerFilePath.chars);
	#else
	Slice checkerImageFile = Str8_Empty;
	if (!OsReadFile(checkerFilePath, loadScratch, false, &checkerImageFile)) { PrintLine_E("Failed to read \"%.*s\" texture!", StrPrint(checkerFilePath)); return 1; }
	ImageData checkerImageData;
	Result loadImageResult = TryParseImageFile(checkerImageFile, stdHeap, &checkerImageData);
	if (loadImageResult != Result_Success) { PrintLine_E("Failed to parse \"%.*s\" texture: %s", StrPrint(checkerFilePath), GetResultStr(loadImageResult)); return 1; }
	Image checkerImage = ZEROED;
	checkerImage.data = checkerImageData.pixels;
	checkerImage.width = checkerImageData.size.Width;
	checkerImage.height = checkerImageData.size.Height;
	checkerImage.mipmaps = 1; //aka no mipmaps
	checkerImage.format = PIXELFORMAT_UNCOMPRESSED_R8G8B8A8;
	Texture2D checkerTexture = LoadTextureFromImage(checkerImage);
	#endif
	
	#endif //BUILD_WITH_RAYLIB
	
	#if BUILD_INTO_SINGLE_UNIT
	WriteLine_N("Compiled as single unit!");
	#else
	
	#if TARGET_IS_WINDOWS
	FilePath dllPath = StrLit(PROJECT_DLL_NAME_STR ".dll");
	#elif TARGET_IS_LINUX
	FilePath dllPath = StrLit("./" PROJECT_DLL_NAME_STR ".so");
	#else
	#error Current TARGET doesn't have an implementation for shared library suffix!
	#endif
	
	OsDll gameDll;
	Result loadDllResult = OsLoadDll(dllPath, &gameDll);
	if (loadDllResult != Result_Success) { PrintLine_E("Failed to load \"%.*s\": %s", StrPrint(dllPath), GetResultStr(loadDllResult)); }
	Assert(loadDllResult == Result_Success);
	PrintLine_D("handle = %p", gameDll.handle);
	#endif
	
	ScratchEnd(loadScratch);
	
	// +--------------------------------------------------------------+
	// |                        Main Game Loop                        |
	// +--------------------------------------------------------------+
	#if BUILD_WITH_RAYLIB
	while (!WindowShouldClose())
	{
		//Grab all scratch arenas so we can ensure they get reset at the end of each frame
		ScratchBegin(scratch1);
		ScratchBegin1(scratch2, scratch1);
		ScratchBegin2(scratch3, scratch1, scratch2);
		
		int windowWidth = GetRenderWidth();
		int windowHeight = GetRenderHeight();
		BeginDrawing();
		ClearBackground(RAYWHITE);
		Str8 textStr = StrLit(PROJECT_READABLE_NAME_STR);
		int textWidth = MeasureText(textStr.chars, (int)textStr.length);
		DrawText(textStr.chars, windowWidth/2 - textWidth/2, windowHeight/2 - (int)textStr.length/2, (int)textStr.length, LIGHTGRAY);
		
		DrawTexture(checkerTexture, 10, 10, WHITE);
		
		EndDrawing();
		
		ScratchEnd(scratch1);
		ScratchEnd(scratch2);
		ScratchEnd(scratch3);
	}
	
	#if !BUILD_INTO_SINGLE_UNIT
	CloseWindow(); NOTE: Apparently this breaks because it conflicts with some dll from Windows when we compile into a single binary
	#endif
	#endif //BUILD_WITH_RAYLIB
	
	return 0;
}

#if BUILD_INTO_SINGLE_UNIT
#include "game/game_main.c"
#endif
