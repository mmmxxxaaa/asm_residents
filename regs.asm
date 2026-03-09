.286
.model tiny
.code
org 100h

VIDEOSEGMENT            equ 0b800h
COMMAND_STRING_LEN_ADDR equ 80h

ATTR_NORMAL      equ 0Fh          ; белый на чёрном
COLOR_GREEN      equ 02h

SCANCODE_YO      equ 029h
SCANCODE_EQUAL   equ 0Dh

SYM_A   equ 'A'
SYM_B   equ 'B'
SYM_C   equ 'C'
SYM_D   equ 'D'
SYM_E   equ 'E'
SYM_F   equ 'F'
SYM_I   equ 'I'
SYM_L   equ 'L'
SYM_O   equ 'O'
SYM_P   equ 'P'
SYM_S   equ 'S'
SYM_T   equ 'T'
SYM_X   equ 'X'
SYM_Z   equ 'Z'

SYM_EQU equ '='

BOX_TOP_LEFT     equ 0C9h   ; ╔
BOX_TOP_RIGHT    equ 0BBh   ; ╗
BOX_BOTTOM_LEFT  equ 0C8h   ; ╚
BOX_BOTTOM_RIGHT equ 0BCh   ; ╝
BOX_HORIZ        equ 0CDh   ; ═
BOX_VERT         equ 0BAh   ; ║

SCREEN_WIDTH_IN_BYTES equ 160

FRAME_TOP    equ 4
FRAME_BOTTOM equ 9
FRAME_LEFT   equ 14
FRAME_RIGHT  equ 64

;-------------------------------------------------------------------------------
; Descr:    Макрос для вывода одного флага в видеопамять.
; Entry:    DX = регистр флагов
;           ES:DI = позиция в видеопамяти, куда будет выведен флаг
;           char1, char2 = символы двух букв для названия флага
;           bit = номер бита во флагах (0-15)
; Exit:     DI увеличен на SCREEN_WIDTH_IN_BYTES - 8, то есть переходит на начало
;           следующей строки в том же столбце
; Destr:    AX, BX, DI
; Expected: DF = 0 (для правильной работы STOSW)
;--------------------------------------------------------------------------------
PrintFlagMacro macro char1, char2, n_of_bit
    mov bx, dx
    shr bx, n_of_bit
    and bl, 1
    mov ah, ATTR_NORMAL
    mov al, char1
    stosw
    mov al, char2
    stosw
    mov al, SYM_EQU
    stosw
    mov al, bl
    add al, '0'
    stosw
    add di, SCREEN_WIDTH_IN_BYTES - 8
    endm

;-------------------------------------------------------------------------------
; Descr:    Макрос для вывода значения регистра в видеопамять.
; Entry:    BX = 16-битное значение для вывода в шестнадцатеричном виде
;           ES:DI = позиция в видеопамяти, куда будет выведен флаг
;           char1, char2 = символы двух букв для названия регистра
; Exit:     DI увеличен на SCREEN_WIDTH_IN_BYTES - 14, то есть переходит на начало
;           следующей строки в том же столбце
; Destr:    AX, BX, CX, DX, DI (так как внутри вызывается HexOut)
; Expected: DF = 0 (для правильной работы STOSW)
;--------------------------------------------------------------------------------
PrintRegMacro macro char1, char2
    mov ah, ATTR_NORMAL
    mov al, char1
    stosw
    mov al, char2
    stosw
    mov al, SYM_EQU
    stosw
    call HexOut
    add di, SCREEN_WIDTH_IN_BYTES - 14  ; (2 буквы [4 байта] '=' [2 байта]  4 цифры [8 байт]. Итого 14 байт)

    endm


Start:
                jmp Init

;-------------------------------------------------------------------------------
; Descr:    Выводит 16-битное значение из BX в шестнадцатеричном виде
;           (4 цифры) в видеопамять по текущему адресу DI.
; Entry:    BX = выводимое число
;           ES:DI = адрес в видеопамяти, куда будут записаны символы
; Exit:     DI увеличивается на 8 (4 символа * 2 байта)
; Expected: DF = 0
; Destr:    AX, BX, CX, DX, DI
;--------------------------------------------------------------------------------
HexOut          proc
                mov cx, 4
                mov dx, bx

@@next_digit:
                mov bx, dx
                shr bx, 12                  ; получаем старший полубайт
                and bx, 0Fh                 ; оставляет только младшие 4 бита
                cmp bl, 10
                jb  @@digit
                add bl, 'A' - 10            ; Для 15: 15 + (65 - 10) = 70 -> 'F'
                jmp @@store
@@digit:
                add bl, '0'
@@store:
                mov ax, bx
                mov ah, 0Fh
                stosw
                shl dx, 4                    ; убираем уже обработанный старший полубайт и подтягиваем следующий на его место
                loop @@next_digit
                ret
HexOut          endp

;-------------------------------------------------------------------------------
; Description: Очищает прямоугольную область внутри рамки
; Entry:       ...
; Exit:        Область экрана внутри рамки заполнена пробелами.
; Expected:    ...
; Destr:       ...
;--------------------------------------------------------------------------------
ClearTable      proc
                push ax bx cx dx si di ds es
                push VIDEOSEGMENT
                pop es
                mov ax, (ATTR_NORMAL shl 8) or ' '
                mov di, (FRAME_TOP*80 + FRAME_LEFT)*2
                mov bx, FRAME_BOTTOM - FRAME_TOP + 1
@@next_row:
                push bx
                mov cx, FRAME_RIGHT - FRAME_LEFT + 1
                rep stosw
                add di, SCREEN_WIDTH_IN_BYTES - (FRAME_RIGHT - FRAME_LEFT + 1)*2
                pop bx
                dec bx
                jnz @@next_row
                pop ds es di si dx cx bx ax
                ret
                endp

;-------------------------------------------------------------------------------
; Description: Рисует рамку символами. Перед рисованием очищает внутренность
;              рамки вызовом ClearTable.
; Entry:       ...
; Exit:        На экране появляется зелёная рамка.
; Expected:    ...
; Destr:       ...
;--------------------------------------------------------------------------------
DrawFrame       proc
                push ax bx cx dx si di ds es

                call ClearTable

                push VIDEOSEGMENT
                pop es
                mov ah, COLOR_GREEN

                push cs                         ;чтобы к переменным нормально обращаться (то есть чтобы иметь доступ к данным в кодовом сегменте)
                pop  ds

                mov di, (FRAME_TOP*80 + FRAME_LEFT)*2
                mov al, [frame_top_left]
                stosw
                mov al, [frame_horiz]
                mov cx, FRAME_RIGHT - FRAME_LEFT - 1
                rep stosw
                mov al, [frame_top_right]
                stosw

                mov di, (FRAME_BOTTOM*80 + FRAME_LEFT)*2
                mov al, [frame_bottom_left]
                stosw
                mov al, [frame_horiz]
                mov cx, FRAME_RIGHT - FRAME_LEFT - 1
                rep stosw
                mov al, [frame_bottom_right]
                stosw

                mov al, [frame_vert]
                mov di, (FRAME_TOP*80 + FRAME_LEFT)*2 + SCREEN_WIDTH_IN_BYTES
                mov cx, FRAME_BOTTOM - FRAME_TOP - 1
@@left:
                stosw
                add di, SCREEN_WIDTH_IN_BYTES - 2
                loop @@left

                mov di, (FRAME_TOP*80 + FRAME_RIGHT)*2 + SCREEN_WIDTH_IN_BYTES
                mov cx, FRAME_BOTTOM - FRAME_TOP - 1
@@right:
                stosw
                add di, SCREEN_WIDTH_IN_BYTES - 2
                loop @@right

                pop es ds di si dx cx bx ax
                ret
                endp

;===============================================================================
; Новый обработчик прерывания таймера (8-ое)
; Включается только после нажатия "ё". Выводит в рамке значения всех регистров
; и флагов прерванной программы.
;===============================================================================
New08_tyt_yzhe_ne_skataesh proc
                push ax bx cx dx si di bp ds es ss

                mov bp, sp
                            ; Теперь стек (относительно bp):
                            ; [bp]    = ss
                            ; [bp+2]  = es
                            ; [bp+4]  = ds
                            ; [bp+6]  = bp (старое)
                            ; [bp+8]  = di
                            ; [bp+10] = si
                            ; [bp+12] = dx
                            ; [bp+14] = cx
                            ; [bp+16] = bx
                            ; [bp+18] = ax
                            ; [bp+20] = ip (автоматически)
                            ; [bp+22] = cs
                            ; [bp+24] = flags

                cmp byte ptr cs:[show_flag], 0
                jne @@display_info
                jmp @@skip_display
@@display_info:
                push VIDEOSEGMENT
                pop es
                call DrawFrame

                ;~~~ ПЕРВЫЙ СТОЛБЕЦ ~~~~~~~~~~~~~~~~~~~~~~~~
                mov di, (80d*5+15d)*2                   ;выводим где-то в середине

                mov bx, [bp+18]
                PrintRegMacro 'A', 'X'

                mov bx, [bp+16]
                PrintRegMacro 'B', 'X'

                mov bx, [bp+14]
                PrintRegMacro 'C', 'X'

                mov bx, [bp+12]   ; DX
                PrintRegMacro 'D', 'X'

                ;~~~ ВТОРОЙ СТОЛБЕЦ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                mov di, (80d*5+25d)*2

                mov bx, [bp+4]    ; DS
                PrintRegMacro 'D', 'S'

                mov bx, [bp+2]    ; ES
                PrintRegMacro 'E', 'S'

                mov bx, [bp]      ; SS
                PrintRegMacro 'S', 'S'

                mov bx, [bp+22]   ; CS
                PrintRegMacro 'C', 'S'

                ; ~~~ ТРЕТИЙ СТОЛБЕЦ ~~~~~~~~~~~~~~~~~~~~~~~~~~~
                mov di, (80d*5+35d)*2

                mov bx, [bp+10]   ; SI
                PrintRegMacro 'S', 'I'

                mov bx, [bp+8]    ; DI
                PrintRegMacro 'D', 'I'

                mov bx, [bp+6]    ; BP
                PrintRegMacro 'B', 'P'

                ; SP (исходный указатель стека)
                ; если бы просто вывели текущий SP, то получили бы адрес, указывающий на последний помещённый в стек элемент,
                ; а не исходное значение SP прерванной программы.
                ; чтобы восстановить исходный SP, нужно прибавить к текущему SP (он = BP) количество байт, помещённых в стек с момента прерывания
                mov bx, bp
                add bx, 26        ; SP (восстановленное значение)
                PrintRegMacro 'S', 'P'

                ; ~~~ ЧЕТВЁРТЫЙ СТОЛБЕЦ  ~~~~~~~~~~~~~~~~~~
                mov di, (80d*5+45d)*2

                mov bx, [bp+20]   ; IP
                PrintRegMacro 'I', 'P'

                ; ~~~ ПЯТЫЙ СТОЛБЕЦ (флаги) ~~~~~~~~~~~~~~~~~~~~
                mov di, (80d*5+55d)*2
                mov dx, [bp+24]

                PrintFlagMacro 'C','F', 0
                PrintFlagMacro 'Z','F', 6
                PrintFlagMacro 'S','F', 7
                PrintFlagMacro 'O','F', 11

                ;~~~ ШЕСТОЙ СТОЛБЕЦ ~~~~~~~~~~~~~~~~~~~~~~~~~~~
                mov di, (80d*5+60d)*2

                PrintFlagMacro 'P','F', 2
                PrintFlagMacro 'A','F', 4
                PrintFlagMacro 'I','F', 9
                PrintFlagMacro 'D','F', 10

@@skip_display:
                mov al, 20h
                out 20h, al

                pop ss es ds bp di si dx cx bx ax

                                ; iret использует cs и ip
                db 0EAh         ; опкод дальнего джампа
old08Ofs:       dw 0
old08Seg:       dw 0

                endp

;===============================================================================
; Новый обработчик прерывания клавиатуры (9-ое)
; Реагирует на нажатия:
;   "ё"   — включает отображение регистров (и подменяет функцию восьмого прерывания при первом нажатии)
;   "="   — выключает отображение и очищает экран
; Все нажатия передаются старому обработчику.
;===============================================================================
New09           proc
                push ax bx cx dx si di bp ds es ss
                mov bp, sp

                in al, 60h
                cmp al, SCANCODE_YO
                je @@check_yo
                cmp al, SCANCODE_EQUAL
                je @@check_equal
                jmp @@skip

@@check_yo:
                test al, 80h
                jnz @@skip
                cmp byte ptr cs:[flag08inst], 0
                jne @@already_set
                push 0
                pop es
                mov bx, 4*08h
                cli
                mov es:[bx], offset New08_tyt_yzhe_ne_skataesh
                mov ax, cs
                mov es:[bx+2], ax
                sti
                mov byte ptr cs:[flag08inst], 1
@@already_set:
                mov byte ptr cs:[show_flag], 1
                jmp @@skip
@@check_equal:
                test al, 80h
                jnz @@skip
                mov byte ptr cs:[show_flag], 0      ;выключаем отображение (DS в этот момент не равен сегменту кода TSR, надо явно указывать )
                call ClearTable
@@skip:
                ; ---- EOI ----
                in al, 61h
                or al, 80h
                out 61h, al
                and al, not 80h
                out 61h, al
                mov al, 20h
                out 20h, al

                pop ss es ds bp di si dx cx bx ax
                db 0EAh
old09Ofs:       dw 0
old09Seg:       dw 0

New09           endp


flag08inst      db 0          ; 0 - ещё не установлен, 1 - уже установлен
show_flag       db 0          ; 1 - таблица должна отображаться

frame_top_left      db BOX_TOP_LEFT
frame_horiz         db BOX_HORIZ
frame_top_right     db BOX_TOP_RIGHT
frame_vert          db BOX_VERT
frame_bottom_left   db BOX_BOTTOM_LEFT
frame_bottom_right  db BOX_BOTTOM_RIGHT

ResidentEnd:

Init:
                call GetCommandLine
                jc @@continue
                                                ; SI указывает на первый символ командной строки, CX = длина
                mov di, offset frame_top_left
                cmp cx, 6
                jbe @@copy_all
                mov cx, 6                       ; копируем не более 6 символов
@@copy_all:
                rep movsb                       ; move string byte из [DS:SI] в [ES:DI]

@@continue:
                mov ax, 3509h                           ; AH = 35h (получить вектор), AL = 09h (номер прерывания)
                int 21h                                 ; возвращает ES:BX = старый вектор
                mov word ptr cs:[old09Ofs], bx
                mov word ptr cs:[old09Seg], es

                mov ax, 3508h
                int 21h
                mov word ptr cs:[old08Ofs], bx
                mov word ptr cs:[old08Seg], es

                ; --- устанавливаем свой обработчик ---
                push 0
                pop es                              ;ES = 0 (сегмент таблицы векторов прерываний)
                mov bx, 4*09h                       ;смещение вектора 09h в таблице (каждый вектор 4 байта)
                cli
                mov es:[bx], offset New09           ;запишем смещение нового обработчика
                mov ax, cs
                mov es:[bx+2], ax                   ;+2, так как у нас little-endian
                sti

                mov ax, 3100h                       ; функция DOS 31h (завершить программу, оставив её в памяти (TSR))
                mov dx, offset ResidentEnd

                add dx, 15                          ; округление вверх до параграфа
                shr dx, 4

                int 21h

;-------------------------------------------------------------------------------
; Description: Takes length of command line and pointer
;	           to its text, skips heading space (if it exists)
; Entry:       NO
; Exit:        String NOT empty: CF = 0, CX = length, SI = the first symbol addr
;	           String IS  empty: CF = 1, CX and SI are not stated
; Expected:    NO
; Destr:       CX, SI
;--------------------------------------------------------------------------------
GetCommandLine proc

	            mov si, COMMAND_STRING_LEN_ADDR
	            mov cl, [si]
	            mov ch, 0					;CX = length
	            cmp cl, 0
	            je @@empty

		        inc si
@@skip_spaces:
		        cmp byte ptr [si], ' '
		        jne @@no_space
		        inc si
		        dec cx
		        cmp cx, 0
		        je @@empty
		        jmp @@skip_spaces
@@no_space:
                clc
                ret
@@empty:
		        stc				; CF=1 - empty string
		        ret
GetCommandLine  endp

end         Start
