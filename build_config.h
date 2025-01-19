/*
File:   build_config.h
Author: Taylor Robbins
Date:   01\19\2025
Description:
	** This file contains a bunch of options that control the build.bat.
	** This file is both a C header file that can be #included from a .c file,
	** and it is also scraped by the build.bat to extract values to change the work it performs.
	** Because it is scraped, and not parsed with the full C language spec, we must
	** be careful to keep this file very simple and not introduce any syntax that
	** would confuse the scraper when it's searching for values
*/

#ifndef _BUILD_CONFIG_H
#define _BUILD_CONFIG_H

// Build .exe binaries for Windows platform
#define BUILD_WINDOWS 1
// Build binaries for Linux platform(s)
#define BUILD_LINUX   1
// Build the WASM binary for operating as a webpage
#define BUILD_WEB     1

// Controls whether we are making a build that we want to run with a Debugger.
// This often sacrifices runtime speed or code size for extra debug information.
// Debug builds often take less time to compile as well.
#define DEBUG_BUILD   1

// Compiles piggen/main.c
#define BUILD_PIGGEN   0
// Generates code for all projects using piggen.exe (you can turn this off if you're not making changes to generated code and you've already generated it once)
#define RUN_PIGGEN     0

// Compiles game/main.c
#define BUILD_GAME   1
// Runs the result of compiling game/main.c, aka the game.exe
#define RUN_GAME     1

// Rather than compiling the project(s) it will simply output the
// result of the preprocessor's pass over the code to the build folder
#define DUMP_PREPROCESSOR 0

#define PROJECT_READABLE_NAME Pig Core Game Prototype
#define PROJECT_FOLDER_NAME   PigCoreGameProto
#define PROJECT_DLL_NAME      game_hot_reload
#define PROJECT_EXE_NAME      game

#define PROJECT_READABLE_NAME_STR  STRINGIFY_DEFINE(PROJECT_READABLE_NAME)
#define PROJECT_FOLDER_NAME_STR    STRINGIFY_DEFINE(PROJECT_FOLDER_NAME)
#define PROJECT_DLL_NAME_STR       STRINGIFY_DEFINE(PROJECT_DLL_NAME)
#define PROJECT_EXE_NAME_STR       STRINGIFY_DEFINE(PROJECT_EXE_NAME)

#endif //  _BUILD_CONFIG_H
