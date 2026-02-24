.286
.model tiny
.code
org 100h

ATTR_NORMAL      equ 0Fh          ; белый на чёрном
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

Start:
            mov ax, 3509h
            int 21h
            mov word ptr cs:[old09Ofs], bx
            mov word ptr cs:[old09Seg], es

            mov ax, 3508h       ; AH = 35h (получить вектор), AL = 08h (номер прерывания)
            int 21h             ; возвращает ES:BX = старый вектор
            mov word ptr offset old08Ofs, bx
            mov bx, es
            mov word ptr offset old08Seg, bx    ; сохранили смещение и сегмент

            ; --- устанавливаем свой обработчик ---
            push 0
            pop es                      ;ES = 0 (сегмент таблицы векторов прерываний)
            mov bx, 4*09h               ;смещение вектора 08h в таблице (каждый вектор 4 байта)
            cli
            mov es:[bx], offset New09  ;запишем смещение нового обработчика
            mov ax, cs
            mov es:[bx+2], ax           ;+2, так как у нас little-endian
            sti

            dd  90909090h
            int 08h
            dd  90909090h

            mov ax, 3100h               ; функция DOS 31h (завершить программу, оставив её в памяти (TSR))
            mov dx, offset EOP

            add dx, 15                     ; округление вверх до параграфа
            shr dx, 4
                                    ;Хуевое округление
                                    ;shr dx, 4
                                    ;inc dx                      ;нацело может не делиться

            int 21h

;;!!! документацию сделать !!!
HexOut      proc
            mov cx, 4
            mov dx, bx

@@next_digit:
            mov bx, dx
            shr bx, 12
            and bx, 0Fh
            cmp bl, 10
            jb  @@digit
            add bl, 'A' - 10
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
HexOut      endp


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
            jne @@display_registers
            jmp @@skip_display
@@display_registers:
            push 0b800h
            pop es
            mov di, (80d*5+15d)*2       ;выводим где-то в середине

            ; --- АХ ---
            mov ax, (ATTR_NORMAL shl 8) or SYM_A
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_X
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_EQU
            stosw
            mov bx, [bp+18]
            call HexOut
            add di, 160-14         ; переход на след строку

            ; --- BX ---
            mov ax, (ATTR_NORMAL shl 8) or SYM_B
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_X
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_EQU
            stosw
            mov bx, [bp+16]     ; значение BX
            call HexOut
            add di, 160-14

            ; --- CX ---
            mov ax, (ATTR_NORMAL shl 8) or SYM_C
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_X
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_EQU
            stosw
            mov bx, [bp+14]     ; значение CX
            call HexOut
            add di, 160-14

            ; --- DX ---
            mov ax, (ATTR_NORMAL shl 8) or SYM_D
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_X
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_EQU
            stosw
            mov bx, [bp+12]      ; значение DX
            call HexOut
            add di, 160-14

            ; --- SI---
            mov ax, (ATTR_NORMAL shl 8) or SYM_S
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_I
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_EQU
            stosw
            mov bx, [bp+10]
            call HexOut
            add di, 160-14

            ;;~~~ ВТОРОЙ СТОЛБЕЦ ~~~
            mov di, (80d*5+25d)*2

            ; DI
            mov ax, (ATTR_NORMAL shl 8) or SYM_D
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_I
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_EQU
            stosw
            mov bx, [bp+8]
            call HexOut
            add di, 160-14       ; переход на следующую строку (правая колонка)

            ; BP
            mov ax, (ATTR_NORMAL shl 8) or SYM_B
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_P
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_EQU
            stosw
            mov bx, [bp+6]
            call HexOut
            add di, 160-14

            ; DS
            mov ax, (ATTR_NORMAL shl 8) or SYM_D
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_S
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_EQU
            stosw
            mov bx, [bp+4]
            call HexOut
            add di, 160-14

            ; ES
            mov ax, (ATTR_NORMAL shl 8) or SYM_E
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_S
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_EQU
            stosw
            mov bx, [bp+2]
            call HexOut
            add di, 160-14

            ; SS
            mov ax, (ATTR_NORMAL shl 8) or SYM_S
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_S
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_EQU
            stosw
            mov bx, [bp]
            call HexOut

            ; --- ТРЕТИЙ СТОЛБЕЦ ---
            mov di, (80d*5+35d)*2

            ; SP (исходный указатель стека)
            ; если бы просто вывели текущий SP, то получили бы адрес, указывающий на последний помещённый в стек элемент,
            ; а не исходное значение SP прерванной программы.
            ; чтобы восстановить исходный SP, нужно прибавить к текущему SP (он = BP) количество байт, помещённых в стек с момента прерывания
            mov ax, (ATTR_NORMAL shl 8) or SYM_S
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_P
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_EQU
            stosw
            mov bx, bp
            add bx, 26          ; bp + 20 (наши push) + 6 (автоматические)
            call HexOut
            add di, 160-14

            ; CS
            mov ax, (ATTR_NORMAL shl 8) or SYM_C
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_S
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_EQU
            stosw
            mov bx, [bp+22]
            call HexOut
            add di, 160-14

            ; IP
            mov ax, (ATTR_NORMAL shl 8) or SYM_I
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_P
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_EQU
            stosw
            mov bx, [bp+20]
            call HexOut

                        ; --- ЧЕТВЁРТЫЙ СТОЛБЕЦ (флаги) ---
            mov di, (80d*5+45d)*2
            mov ax, [bp+24]
            push ax                      ; сохраняем в стеке, так как будем многократно использовать

            ; CF (бит 0)
            pop ax
            push ax
            mov bx, ax
            and bx, 1
            add bl, '0'
            mov ax, (ATTR_NORMAL shl 8) or SYM_C
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_F
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_EQU
            stosw
            mov al, bl
            stosw
            add di, 2

            ; PF (бит 2)
            pop ax
            push ax
            mov bx, ax
            shr bx, 2
            and bx, 1
            add bl, '0'
            mov ax, (ATTR_NORMAL shl 8) or SYM_P
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_F
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_EQU
            stosw
            mov al, bl
            stosw
            add di, 160-18                 ; переход на следующую строку с учётом выведенных символов

            ; AF (бит 4)
            pop ax
            push ax
            mov bx, ax
            shr bx, 4
            and bx, 1
            add bl, '0'
            mov ax, (ATTR_NORMAL shl 8) or SYM_A
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_F
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_EQU
            stosw
            mov al, bl
            stosw
            add di, 2

            ; ZF (бит 6)
            pop ax
            push ax
            mov bx, ax
            shr bx, 6
            and bx, 1
            add bl, '0'
            mov ax, (ATTR_NORMAL shl 8) or SYM_Z
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_F
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_EQU
            stosw
            mov al, bl
            stosw
            add di, 160-18

            ; SF (бит 7)
            pop ax
            push ax
            mov bx, ax
            shr bx, 7
            and bx, 1
            add bl, '0'
            mov ax, (ATTR_NORMAL shl 8) or SYM_S
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_F
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_EQU
            stosw
            mov al, bl
            stosw
            add di, 2

            ; TF (бит 8)
            pop ax
            push ax
            mov bx, ax
            shr bx, 8
            and bx, 1
            add bl, '0'
            mov ax, (ATTR_NORMAL shl 8) or SYM_T
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_F
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_EQU
            stosw
            mov al, bl
            stosw
            add di, 160-18

            ; IF (бит 9)
            pop ax
            push ax
            mov bx, ax
            shr bx, 9
            and bx, 1
            add bl, '0'
            mov ax, (ATTR_NORMAL shl 8) or SYM_I
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_F
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_EQU
            stosw
            mov al, bl
            stosw
            add di, 2

            ; DF (бит 10)
            pop ax
            push ax
            mov bx, ax
            shr bx, 10
            and bx, 1
            add bl, '0'
            mov ax, (ATTR_NORMAL shl 8) or SYM_D
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_F
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_EQU
            stosw
            mov al, bl
            stosw
            add di, 160-18

            ; OF (бит 11)
            pop ax                         ; последний раз извлекаем, не пушим обратно
            mov bx, ax
            shr bx, 11
            and bx, 1
            add bl, '0'
            mov ax, (ATTR_NORMAL shl 8) or SYM_O
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_F
            stosw
            mov ax, (ATTR_NORMAL shl 8) or SYM_EQU
            stosw
            mov al, bl
            stosw

@@skip_display:
            mov al, 20h
            out 20h, al

            pop ss es ds bp di si dx cx bx ax

                            ; iret использует cs и ip
            db 0EAh         ; опкод дальнего джампа
old08Ofs:   dw 0
old08Seg:   dw 0

            endp

ClearTable proc
            push ax bx cx dx si di ds es
            push 0b800h
            pop es
            mov ax, (ATTR_NORMAL shl 8) or ' '
            mov cx, 5
            mov di, (80d*5 + 15d)*2              ; начальная позиция
@@next_row:
            push cx
            mov cx, 46
            rep stosw
            add di, 160-46*2
            pop cx
            loop @@next_row
            pop ds es di si dx cx bx ax
            ret
            endp

New09       proc
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
old09Ofs:   dw 0
old09Seg:   dw 0

New09       endp

flag08inst db 0          ; 0 - ещё не установлен, 1 - уже установлен
show_flag  db 0          ; 1 - таблица должна отображаться

EOP:
end         Start
