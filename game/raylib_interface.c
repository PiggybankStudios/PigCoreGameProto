/*
File:   raylib_interface.c
Author: Taylor Robbins
Date:   01\19\2025
Description: 
	** None
*/

// +--------------------------------------------------------------+
// |                          Callbacks                           |
// +--------------------------------------------------------------+
#if BUILD_WITH_RAYLIB
void RaylibLogCallback(int logLevel, const char* text, va_list args)
{
	DbgLevel dbgLevel;
	switch (logLevel)
	{
		case LOG_TRACE:   dbgLevel = DbgLevel_Debug;   break;
		case LOG_DEBUG:   dbgLevel = DbgLevel_Debug;   break;
		case LOG_INFO:    dbgLevel = DbgLevel_Info;    break;
		case LOG_WARNING: dbgLevel = DbgLevel_Warning; break;
		case LOG_ERROR:   dbgLevel = DbgLevel_Error;   break;
		case LOG_FATAL:   dbgLevel = DbgLevel_Error;   break;
		default: dbgLevel = DbgLevel_Regular; break;
	}
	if (dbgLevel == DbgLevel_Debug && !ENABLE_RAYLIB_LOGS_DEBUG) { return; }
	if (dbgLevel == DbgLevel_Info && !ENABLE_RAYLIB_LOGS_INFO) { return; }
	if (dbgLevel == DbgLevel_Warning && !ENABLE_RAYLIB_LOGS_WARNING) { return; }
	if (dbgLevel == DbgLevel_Error && !ENABLE_RAYLIB_LOGS_ERROR) { return; }
	
	ScratchBegin(scratch);
	va_list argsCopy;
	va_copy(argsCopy, args);
	char* formattedText = nullptr;
	int formattedTextLength = MyVaListPrintf(nullptr, 0, text, args);
	if (formattedTextLength >= 0)
	{
		formattedText = AllocArray(char, scratch, formattedTextLength+1);
		if (formattedText != nullptr)
		{
			int secondPrintResult = MyVaListPrintf(formattedText, formattedTextLength+1, text, argsCopy);
			formattedText[formattedTextLength] = '\0';
		}
	}
	va_end(argsCopy);
	if (formattedText != nullptr)
	{
		WriteLineAt(dbgLevel, formattedText);
	}
	else
	{
		WriteLine_E("RaylibLogCallback PRINT FAILURE!");
		WriteLineAt(dbgLevel, text);
	}
	ScratchEnd(scratch);
}
#endif //BUILD_WITH_RAYLIB
