.286
.model tiny
.code
org 100h

VIDEOSEGMENT     equ 0b800h
COMMAND_STRING_LEN_ADDR         equ 80h


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

Start:
                call GetCommandLine
                jc @@continue

                ; SI указывает на первый символ командной строки, CX = длина
                mov di, offset frame_top_left
                cmp cx, 6
                jbe @@copy_all
                mov cx, 6                     ; копируем не более 6 символов
@@copy_all:
                rep movsb

@@continue:
                mov ax, 3509h
                int 21h
                mov word ptr cs:[old09Ofs], bx
                mov word ptr cs:[old09Seg], es

                mov ax, 3508h                       ; AH = 35h (получить вектор), AL = 08h (номер прерывания)
                int 21h                             ; возвращает ES:BX = старый вектор
                mov word ptr offset old08Ofs, bx
                mov bx, es
                mov word ptr offset old08Seg, bx    ; сохранили смещение и сегмент

                ; --- устанавливаем свой обработчик ---
                push 0
                pop es                              ;ES = 0 (сегмент таблицы векторов прерываний)
                mov bx, 4*09h                       ;смещение вектора 08h в таблице (каждый вектор 4 байта)
                cli
                mov es:[bx], offset New09           ;запишем смещение нового обработчика
                mov ax, cs
                mov es:[bx+2], ax                   ;+2, так как у нас little-endian
                sti

                mov ax, 3100h                       ; функция DOS 31h (завершить программу, оставив её в памяти (TSR))
                mov dx, offset EOP

                add dx, 15                          ; округление вверх до параграфа
                shr dx, 4

                int 21h

;-------------------------------------------------------------------------------
; Description: Takes length of command line and pointer
;	       to its text, skips heading space (if it exists)
; Entry:       NO
; Exit:        String NOT empty: CF = 0, CX = length, SI = the first symbol addr
;	       String IS  empty: CF = 1, CX and SI are not stated
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
                shr bx, 12
                and bx, 0Fh
                cmp bl, 10
                jb  @@digit
                add bl, 'A' - 10            ;Для 15: 15 + (65 - 10) = 70 -> 'F'
                jmp @@store
@@digit:
                add bl, '0'
@@store:
                mov ax, bx
                mov ah, 0Fh
                stosw
                shl dx, 4
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
;//FIXME на эту функцию особое внимание, потому что за эту функцию будет оценка за первое задание
;//FIXME надо сделать так чтобы хотя бы что-то читалось из командной строки (либо цвет, либо символ рамки).
;        так как это резидентная прога, то можно просто в командную строку написать символ и тогда дефолтные меняются на него
;        BOX_TOP_LEFT_DEFAULT и BOX_TOP_LEFT_USER
DrawFrame       proc
                push ax bx cx dx si di ds es

                call ClearTable
                push VIDEOSEGMENT
                pop es
                mov ah, COLOR_GREEN

                push cs                                 ;чтобы к переменным нормально обращаться
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

;-------------------------------------------------------------------------------
; Descr: выводит строку вида "XX=xxxx" в видеопамять по адресу ES:DI
; Entry: AL = первая буква
;        AH = вторая буква
;        BX = 16-битное значение для вывода в шестнадцатеричном виде
;        ES:DI = текущая позиция в видеопамяти
; Exit:  DI перемещён на начало следующей строки в том же столбце
; Destr: AX, BX, CX, DX, DI
;-------------------------------------------------------------------------------
PrintReg        proc

                push ax
                push bx
                push cx
                push dx

                push ax

                mov ah, ATTR_NORMAL
                stosw

                pop ax

                mov al, ah
                mov ah, ATTR_NORMAL
                stosw

                mov al, SYM_EQU
                mov ah, ATTR_NORMAL
                stosw

                call HexOut

                add di, SCREEN_WIDTH_IN_BYTES - 14

                pop dx
                pop cx
                pop bx
                pop ax
                ret

                endp

;-------------------------------------------------------------------------------
; Descr: выводит один флаг в формате "XX=0" или "XX=1"
; Entry: AL = первая буква (например, 'C' для CF)
;        AH = вторая буква (например, 'F')
;        BL = значение бита (0 или 1)
;        ES:DI = текущая позиция в видеопамяти
; Exit:  DI увеличен на (6 + CX) байт
; Destr: AX, DI, BL
;-------------------------------------------------------------------------------
PrintFlag       proc
                push ax

                mov ah, ATTR_NORMAL
                stosw                   ; выводим первую букву

                pop ax
                mov al, ah
                mov ah, ATTR_NORMAL
                stosw                   ; выводим вторую букву

                mov al, SYM_EQU
                mov ah, ATTR_NORMAL
                stosw

                mov al, bl              ; значение бита (0 или 1)
                add al, '0'             ; преобразуем в символ
                mov ah, ATTR_NORMAL
                stosw

                add di, SCREEN_WIDTH_IN_BYTES - 8
                ret
PrintFlag       endp

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

                mov bx, [bp+18]   ; AX
                mov al, 'A'
                mov ah, 'X'
                call PrintReg

                mov bx, [bp+16]   ; BX
                mov al, 'B'
                mov ah, 'X'
                call PrintReg

                mov bx, [bp+14]   ; CX
                mov al, 'C'
                mov ah, 'X'
                call PrintReg

                mov bx, [bp+12]   ; DX
                mov al, 'D'
                mov ah, 'X'
                call PrintReg

                ;~~~ ВТОРОЙ СТОЛБЕЦ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                mov di, (80d*5+25d)*2

                mov bx, [bp+4]    ; DS
                mov al, 'D'
                mov ah, 'S'
                call PrintReg

                mov bx, [bp+2]    ; ES
                mov al, 'E'
                mov ah, 'S'
                call PrintReg

                mov bx, [bp]      ; SS
                mov al, 'S'
                mov ah, 'S'
                call PrintReg

                mov bx, [bp+22]   ; CS
                mov al, 'C'
                mov ah, 'S'
                call PrintReg

                ; ~~~ ТРЕТИЙ СТОЛБЕЦ ~~~~~~~~~~~~~~~~~~~~~~~~~~~
                mov di, (80d*5+35d)*2

                mov bx, [bp+10]   ; SI
                mov al, 'S'
                mov ah, 'I'
                call PrintReg

                mov bx, [bp+8]    ; DI
                mov al, 'D'
                mov ah, 'I'
                call PrintReg

                mov bx, [bp+6]    ; BP
                mov al, 'B'
                mov ah, 'P'
                call PrintReg

                ; SP (исходный указатель стека)
                ; если бы просто вывели текущий SP, то получили бы адрес, указывающий на последний помещённый в стек элемент,
                ; а не исходное значение SP прерванной программы.
                ; чтобы восстановить исходный SP, нужно прибавить к текущему SP (он = BP) количество байт, помещённых в стек с момента прерывания
                mov bx, bp
                add bx, 26        ; SP (восстановленное значение)
                mov al, 'S'
                mov ah, 'P'
                call PrintReg

                ; ~~~ ЧЕТВЁРТЫЙ СТОЛБЕЦ (IP) ~~~~~~~~~~~~~~~~~~
                mov di, (80d*5+45d)*2

                mov bx, [bp+20]   ; IP
                mov al, 'I'
                mov ah, 'P'
                call PrintReg

                ; ~~~ ПЯТЫЙ СТОЛБЕЦ (флаги) ~~~~~~~~~~~~~~~~~~~~
                mov di, (80d*5+55d)*2
                mov ax, [bp+24]
                push ax                      ; сохраняем в стеке, так как будем многократно использовать

                ; CF (бит 0)
                pop ax
                push ax
                mov bl, al
                and bl, 1
                mov al, 'C'
                mov ah, 'F'
                call PrintFlag

                ; ZF
                pop ax
                push ax
                mov bl, al
                shr bl, 6
                and bl, 1
                mov al, 'Z'
                mov ah, 'F'
                call PrintFlag

                ; SF
                pop ax
                push ax
                mov bl, al
                shr bl, 7
                and bl, 1
                mov al, 'S'
                mov ah, 'F'
                call PrintFlag

                ; OF
                pop ax
                push ax
                mov bl, al
                shr bl, 11
                and bl, 1
                mov al, 'O'
                mov ah, 'F'
                call PrintFlag

                ;~~~ ШЕСТОЙ СТОЛБЕЦ ~~~~~~~~~~~~~~~~~~~~~~~~~~~
                mov di, (80d*5+60d)*2

                ; PF (бит 2)
                pop ax
                push ax
                mov bl, al
                shr bl, 2
                and bl, 1
                mov al, 'P'
                mov ah, 'F'
                call PrintFlag

                ; AF (бит 4)
                pop ax
                push ax
                mov bl, al
                shr bl, 4
                and bl, 1
                mov al, 'A'
                mov ah, 'F'
                call PrintFlag

                ; IF (бит 9)
                pop ax
                push ax
                mov bl, al
                shr bl, 9
                and bl, 1
                mov al, 'I'
                mov ah, 'F'
                call PrintFlag

                ; DF (бит 10)
                pop ax                    ; последний раз
                mov bl, al
                shr bl, 10
                and bl, 1
                mov al, 'D'
                mov ah, 'F'
                call PrintFlag
                                                        ; функция
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

                              ; //ДЕЛО СДЕЛАНО высота рамки 4, перегруппировать регистры
                              ; //ДЕЛО СДЕЛАНО (проверил, всё так) что-то не то с сегментными регистрами
                              ; //ДЕЛО СДЕЛАНО создал функции PrintReg и PrintFlag, которые сделали код компактнее
EOP:
end         Start
