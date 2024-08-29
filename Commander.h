#pragma once
#include <stdio.h>
#include "Panel.h"
#include <string>

//-----------------------------------------------------------------------------------------------------
class AMenu_Item {
public:
	unsigned short X_Pos;
	unsigned short Y_Pos;
	unsigned short Len;
	const wchar_t* Key, * Name;

	AMenu_Item(unsigned short x_pos, unsigned short y_pos, unsigned short len, const wchar_t* key, const wchar_t* name);
	void Draw(CHAR_INFO* screen_buffer, unsigned short screen_width);
};
//-----------------------------------------------------------------------------------------------------
class AsCommander {
private:
	HANDLE Std_Output_Handle = 0;
	HANDLE Std_Input_Handle = 0;
	HANDLE Screen_Buffer_Handle = 0;
	CONSOLE_SCREEN_BUFFER_INFO Screen_Buffer_Info{};
	CHAR_INFO* Screen_Buffer = 0;
	APanel* Right_Panel = 0;
	APanel* Left_Panel = 0;
	AMenu_Item* Menu[10]{};
	bool Can_Run;
	bool Need_Redraw;
	void Build_Draw();
	void Add_Menu_Item(int& index, int& pos_x, int step, const wchar_t* key, const wchar_t* name);
	bool Draw();

public:
	~AsCommander();
	bool Init();
	void Run();
};
//-----------------------------------------------------------------------------------------------------