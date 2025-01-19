/*
File:   main.c
Author: Taylor Robbins
Date:   01\19\2025
Description: 
	** Holds the main entry point for the game and #includes all source files
	** that are needed for the game to build
*/

#define BUILD_WITH_RAYLIB 1

#include "base/base_all.h"
#include "std/std_all.h"
#include "os/os_all.h"
#include "misc/misc_all.h"
#include "mem/mem_all.h"
#include "struct/struct_all.h"
#include "gfx/gfx_all.h"

#include "third_party/raylib/raylib.h"

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
	
	SetTraceLogCallback(RaylibLogCallback);
	InitWindow(800, 600, PROJECT_READABLE_NAME_STR);
	SetWindowMinSize(400, 200);
	SetWindowState(FLAG_WINDOW_RESIZABLE);
	SetTargetFPS(60);
	
	Slice checkerImageFile = Str8_Empty;
	if (!OsReadFile(FilePathLit("resources/image/pig_checker_blue.png"), loadScratch, false, &checkerImageFile)) { WriteLine_E("Failed to read pig_checker_blue.png texture!"); return 1; }
	ImageData checkerImageData;
	Result loadImageResult = TryParseImageFile(checkerImageFile, stdHeap, &checkerImageData);
	if (loadImageResult != Result_Success) { PrintLine_E("Failed to parse pig_checker_blue.png texture: %s", GetResultStr(loadImageResult)); return 1; }
	Image checkerImage = ZEROED;
	checkerImage.data = checkerImageData.pixels;
	checkerImage.width = checkerImageData.size.Width;
	checkerImage.height = checkerImageData.size.Height;
	checkerImage.mipmaps = 1; //aka no mipmaps
	checkerImage.format = PIXELFORMAT_UNCOMPRESSED_R8G8B8A8;
	Texture2D checkerTexture = LoadTextureFromImage(checkerImage);
	
	ScratchEnd(loadScratch);
	
	// +--------------------------------------------------------------+
	// |                        Main Game Loop                        |
	// +--------------------------------------------------------------+
	while (!WindowShouldClose())
	{
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
	
	CloseWindow();
	return 0;
}
