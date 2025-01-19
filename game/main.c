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

#include "third_party/raylib/raylib.h"

int main()
{
	InitWindow(800, 600, PROJECT_READABLE_NAME_STR);
	SetWindowMinSize(400, 200);
	SetWindowState(FLAG_WINDOW_RESIZABLE);
	SetTargetFPS(60);
	
	// +--------------------------------------------------------------+
	// |                        Main Game Loop                        |
	// +--------------------------------------------------------------+
	while (!WindowShouldClose())
	{
		int windowWidth = GetRenderWidth();
		int windowHeight = GetRenderHeight();
		BeginDrawing();
		ClearBackground(RAYWHITE);
		Str8 textStr = StrLit(PROJECT_READABLE_NAME_STR);
		int textWidth = MeasureText(textStr.chars, (int)textStr.length);
		DrawText(textStr.chars, windowWidth/2 - textWidth/2, windowHeight/2 - (int)textStr.length/2, (int)textStr.length, LIGHTGRAY);
		
		//TODO: Draw more stuff
		
		EndDrawing();
	}
	
	CloseWindow();
	return 0;
}
