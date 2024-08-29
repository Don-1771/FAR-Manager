.code
;---------------------------------------------------------------------------------------------------
Make_Sum proc
;extern "C" int Make_Sum(int one_value, int another_value);
; RCX - one_value (RCX - размером 8 байт (64 бит), а EAX 4 байта (32 бита)
                  ;в функции мы обращаемся к ECX, так как это младший регистр RCX
				  ;ECX - размером 4 байта (32 бита))
; RDX - another_value (аналогично используем EDX)
; Возврат в регистре EAX

	mov eax, ecx
	add eax, edx

	ret
Make_Sum endp
;---------------------------------------------------------------------------------------------------
Get_Pos_Address proc
; RCX - screen_buffer
; RDX - pos
; результат: RDI

;1. вычисляем адрес вывода: address_offset = (pos.Y * pos.Screen_Width + pos.X) * 4
;1.1 вычисляем pos.Y * pos.Screen_Width
mov rax, rdx
shr rax, 16
movzx rax, ax

	mov rbx, rdx
	shr rbx, 32  ; BX = pos.Screen_Width
	movzx rbx, bx  ; RBX = BX = pos.Screen_Width

	imul rax, rbx  ; RAX = RAX * RBX = pos.Y_Pos * pos.Screen_Width

	; 1.2. Добавим pos.X к RAX
	movzx rbx, dx  ; RBX = DX = pox.X_Pos
	add rax, rbx  ; RAX = pos.Y_Pos * pos.Screen_Width + pox.X_Pos = смещение в символах

; 1.3 rax содержит смещение начала строки в символах, а надо - в байтах
; т.к. каждый символ занимает 4 байта, надо умножить это смещение на 4
shl rax, 2 ; rax = rax * 4 = address_offset

mov rdi, rcx  ; rdi = screen_buffer
add rdi, rax  ; rdi = screen_buffer + address_offset

ret
Get_Pos_Address endp
;-------------------------------------------------------------------------------------------------------------
Draw_Start_Symbol proc
; Выводим стартовый символ
; Параметры:
; RDI - текущий адрес в буфере окна
; R8 - symbol
; Возврат: нет

	push rax
	push rbx

	mov eax, r8d
	mov rbx, r8
	shr rbx, 32  ; RBX = EBX = { symbol.Start_Symbol, symbol.End_Symbol }
	mov ax, bx  ; EAX = { symbol.Attributes, symbol.Start_Symbol }

	stosd

	pop rbx
	pop rax

	ret

Draw_Start_Symbol endp
;-------------------------------------------------------------------------------------------------------------
Draw_End_Symbol proc
; Выводим конечный символ
; Параметры:
; EAX - { symbol.Attributes, symbol.Main_Symbol }
; RDI - текущий адрес в буфере окна
; R8 - symbol
; Возврат: нет

	mov rbx, r8
	shr rbx, 48  ; RBX = BX = symbol.End_Symbol
	mov ax, bx  ; EAX = { symbol.Attributes, symbol.End_Symbol }

	stosd

	ret

Draw_End_Symbol endp
;---------------------------------------------------------------------------------------------------
Draw_Line_Horizontal proc
;extern "C" void Draw_Line_Horizontal(CHAR_INFO * screen_buffer, SPos pos, ASymbol symbol)
; RCX - screen_buffer
; RDX - pos
; R8 - символ
; результат: нет

	push rax
	push rbx
	push rcx
	push rdi

	; 1. Вычисляем адрес вывода
	call Get_Pos_Address  ; RDI = позиция символа в буфере screen_buffer в позиции pos

	; 2. Выводим стартовый символ
	call Draw_Start_Symbol

	; 3. Выводим символы symbol.Main_Symbol
	mov eax, r8d
	mov rcx, rdx
	shr rcx, 48  ; RCX = CX = pos.Len

	rep stosd
	;Если нам надо многократно скопировать некоторое значение в строку, то применяется префикс rep 
	;При каждом копировании он уменьшает значение в RCX и, если RCX равно нулю, завершает копирование
	;stosd - сохраняет 32-битное значение из регистра EAX в строку

	; 4. Выводим конечный символ
	call Draw_End_Symbol

	pop rdi
	pop rcx
	pop rbx
	pop rax

	ret

Draw_Line_Horizontal endp
;---------------------------------------------------------------------------------------------------
Draw_Line_Vertical proc
;extern "C" void Draw_Line_Vertical(CHAR_INFO* screen_buffer, SPos pos, ASymbol symbol)

; RCX - screen_buffer
; RDX - pos
; R8 - символ
; результат: нет

	push rax
	push rcx
	push rdi
	push r11

	; 1. Вычисляем адрес вывода
	call Get_Pos_Address  ; RDI = позиция символа в буфере screen_buffer в позиции pos

	; 2. Вычисление коррекции позиции вывода
	call Get_Screen_Width_Size  ; R11 = pos.Screen_Width * 4 = Ширина экрана в байтах
	sub r11, 4

	; 3. Выводим стартовый символ
	call Draw_Start_Symbol

	add rdi, r11

;3. Готовим циклы
	mov rcx, rdx
	shr rcx, 48  ; RCX = CX = pos.Len
	mov eax, r8d  ; EAX = symbol

_1:
	stosd  ; Выводим символ
	add rdi, r11

	loop _1
	; уменьшаем значение в rcx на 1, переходим к метке _1, если rcx не содержит 0
	; 5. Выводим конечный символ
	call Draw_End_Symbol

	pop r11
	pop rdi
	pop rcx
	pop rax

	ret

Draw_Line_Vertical endp
;---------------------------------------------------------------------------------------------------
Show_Color_Proc proc
;extern "C" void Show_Color_Proc(CHAR_INFO* screen_buffer, SPos pos, CHAR_INFO symbol);
; RCX - screen_buffer
; RDX - pos
; R8 - символ
; результат: нет

	push rax
	push rbx
	push rcx
	push rdi
	push r10
	push r11

	; 1. Вычисляем адрес вывода
	call Get_Pos_Address  ; RDI = позиция символа в буфере screen_buffer в позиции pos

	mov r10, rdi

	; 2. Вычисление коррекции позиции вывода
	call Get_Screen_Width_Size ; R11 = pos.Screen_Width * 4 = Ширина экрана в байтах

;3. Готовим циклы
mov rax, r8		; rax = r8 = simbol  simbol- {0000 0000 attriburt char}
and rax, 0ffffh ; rax = simbol  simbol- {0000 0000 0000 char}
mov rbx, 16

xor rcx, rcx ; rcx = 0

_0:
	mov cl, 16

_1:
stosd ;сохраняет двойное слово из регистра EAX в место по адресу из регистра RDI
add rax, 010000h ; еденица смещенная влево на 16 разрядов (т.е. элементарный шаг для атрибутов)
				 ; rax = simbol  simbol- {0000 0000 0001 char}

loop _1 ; уменьшаем значение в rcx на 1, переходим к метке _1, если rcx не содержит 0

add r10, r11
mov rdi, r10

dec rbx
jnz _0 ;eсли флаг нуля НЕ установлен (то есть если в RBX НЕ нулевое значение), то переходим обратно к метке _1

pop r11
pop r10
pop rdi
pop rcx
pop rbx
pop rax
ret
Show_Color_Proc endp
;---------------------------------------------------------------------------------------------------
Get_Screen_Width_Size proc
; Вычисляет ширину экрана в байтах
; RDX - SPos pos или SArea_Pos pos
; Возврат: R11 = pos.Screen_Width * 4

	mov r11, rdx
	shr r11, 32  ; R11 = pos
	movzx r11, r11w  ; R11 = R11W = pos.Screen_Width
	shl r11, 2  ; R11 = pos.Screen_Width * 4 = Ширина экрана в байтах

	ret

Get_Screen_Width_Size endp
;---------------------------------------------------------------------------------------------------
Clear_Area proc
; extern "C" void Clear_Area(CHAR_INFO *screen_buffer, SArea_Pos area_pos, ASymbol symbol);
; Параметры:
; RCX - screen_buffer
; RDX - area_pos
; R8 - symbol
; Возврат: нет

	push rax
	push rbx
	push rcx
	push rdi
	push r10
	push r11

	; 1. Вычисляем адрес вывода
	call Get_Pos_Address  ; RDI = позиция символа в буфере screen_buffer в позиции pos

	mov r10, rdi

	; 2. Вычисление коррекции позиции вывода
	call Get_Screen_Width_Size  ; R11 = pos.Screen_Width * 4 = Ширина экрана в байтах

	; 3. Готовим циклы
	mov rax, r8  ; RAX = EAX = symbol

	mov rbx, rdx
	shr rbx, 48  ; BH = area_pos.Height, BL = area_pos.Width

	xor rcx, rcx  ; RCX = 0

_0:
	mov cl, bl
	rep stosd

	add r10, r11
	mov rdi, r10

	dec bh
	jnz _0

	pop r11
	pop r10
	pop rdi
	pop rcx
	pop rbx
	pop rax

	ret

Clear_Area endp
;---------------------------------------------------------------------------------------------------
Draw_Text proc
;extern "C" int Draw_Text(CHAR_INFO * screen_buffer, SText_Pos text_pos, const wchar_t* symbol)
; Параметры:
; RCX - screen_buffer
; RDX - area_pos {Attributes, Screen_Width, Y_Pos, X_Pos}
; R8 - symbol
; Возврат: rax - количество символов в строке

	push rbx
	push rdi
	push r8

	; 1. Вычисляем адрес вывода
	call Get_Pos_Address  ; RDI = позиция символа в буфере screen_buffer в позиции pos

	mov rax, rdx
	shr rax, 32 ;старшая половина eax = text_pos.Attributes
	xor rbx, rbx

_1:
	mov ax, [r8] ;AX-очередной символ из строки в R8
	cmp ax, 0
	je _exit
	add r8, 2 ;переводим указатель на следующий символ
	stosd
	inc rbx
	jmp _1
_exit:

	mov rax, rbx
	pop r8
	pop rdi
	pop rbx

	ret
Draw_Text endp
;---------------------------------------------------------------------------------------------------
Draw_Limited_Text proc
;extern "C" void Draw_Limited_Text(CHAR_INFO * screen_buffer, SText_Pos text_pos, const wchar_t* symbol, unsigned short limit)
; Параметры:
; RCX - screen_buffer
; RDX - area_pos {Attributes, Screen_Width, Y_Pos, X_Pos}
; R8 - symbol
; R9 - limit
; Возврат: нет

	push rax
	push rcx
	push rdi
	push r8

	; 1. Вычисляем адрес вывода
	call Get_Pos_Address  ; RDI = позиция символа в буфере screen_buffer в позиции pos

	mov rax, rdx
	shr rax, 32 ;старшая половина eax = text_pos.Attributes
	

_1:
	mov ax, [r8] ;AX-очередной символ из строки в R8
	cmp ax, 0
	je _space
	
	add r8, 2 ;переводим указатель на следующий символ
	stosd
	dec r9
	cmp r9, 0
	je _exit
	jmp _1

_space:
	mov ax, 020h ; младшая половина eax = пробел (020h - код пробела)
	mov rcx, r9
	rep stosd ;выполняется до тех пор, пока в rcx!=0 (декрементирует rcx)

_exit:
	pop r8
	pop rdi
	pop rcx
	pop rax

	ret
Draw_Limited_Text endp
;---------------------------------------------------------------------------------------------------
end
