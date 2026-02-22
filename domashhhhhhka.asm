.286
.model tiny
.code
org 100h

Start:
            dd  90909090h
            mov ax, 3508h       ; AH = 35h (получить вектор), AL = 08h (номер прерывания)
            int 21h             ; возвращает ES:BX = старый вектор
            mov word ptr offset old08Ofs, bx
            mov bx, es
            mov word ptr offset old08Seg, bx    ; сохранили смещение и сегмент
            dd 90909090h

            ; --- устанавливаем свой обработчик ---
            push 0
            pop es                      ;ES = 0 (сегмент таблицы векторов прерываний)
            mov bx, 4*08h               ;смещение вектора 08h в таблице (каждый вектор 4 байта)
            cli
            mov es:[bx], offset New08_tyt_yzhe_ne_skataesh  ;запишем смещение нового обработчика
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

            push 0b800h
            pop es
            mov di, (80d*5+30d)*2       ;выводим где-то в середине

            ; --- АХ ---
            mov ax, 0F41h
            stosw
            mov ax, 0F58h
            stosw
            mov ax, 0F3Dh
            stosw
            mov bx, [bp+18]
            call HexOut
            add di, 160-14         ; переход на след строку

            ; --- BX ---
            mov ax, 0F42h       ; B
            stosw
            mov ax, 0F58h       ; X
            stosw
            mov ax, 0F3Dh       ; =
            stosw
            mov bx, [bp+16]     ; значение BX
            call HexOut
            add di, 160-14

            ; --- CX ---
            mov ax, 0F43h       ; C
            stosw
            mov ax, 0F58h       ; X
            stosw
            mov ax, 0F3Dh       ; =
            stosw
            mov bx, [bp+14]     ; значение CX
            call HexOut
            add di, 160-14

            ; --- DX ---
            mov ax, 0F44h       ; D
            stosw
            mov ax, 0F58h       ; X
            stosw
            mov ax, 0F3Dh       ; =
            stosw
            mov bx, [bp+12]      ; значение DX
            call HexOut
            add di, 160-14

            ; --- SI---
            mov ax, 0F53h  ; 'S'
            stosw
            mov ax, 0F49h  ; 'I'
            stosw
            mov ax, 0F3Dh
            stosw
            mov bx, [bp+10] ; SI
            call HexOut
            add di, 160-14

            ;;~~~ ВТОРОЙ СТОЛБЕЦ ~~~
            mov di, (80d*5+40d)*2

            ; DI
            mov ax, 0F44h
            stosw
            mov ax, 0F49h
            stosw
            mov ax, 0F3Dh
            stosw
            mov bx, [bp+8]
            call HexOut
            add di, 160-14       ; переход на следующую строку (правая колонка)

            ; BP
            mov ax, 0F42h
            stosw
            mov ax, 0F50h
            stosw
            mov ax, 0F3Dh
            stosw
            mov bx, [bp+6]
            call HexOut
            add di, 160-14

            ; DS
            mov ax, 0F44h
            stosw
            mov ax, 0F53h
            stosw
            mov ax, 0F3Dh
            stosw
            mov bx, [bp+4]
            call HexOut
            add di, 160-14

            ; ES
            mov ax, 0F45h
            stosw
            mov ax, 0F53h
            stosw
            mov ax, 0F3Dh
            stosw
            mov bx, [bp+2]
            call HexOut
            add di, 160-14

            ; SS
            mov ax, 0F53h
            stosw
            mov ax, 0F53h
            stosw
            mov ax, 0F3Dh
            stosw
            mov bx, [bp]
            call HexOut

            ; --- ТРЕТИЙ СТОЛБЕЦ ---
            mov di, (80d*5+50d)*2

            ; SP (исходный указатель стека)
            ; если бы просто вывели текущий SP, то получили бы адрес, указывающий на последний помещённый в стек элемент,
            ; а не исходное значение SP прерванной программы.
            ; чтобы восстановить исходный SP, нужно прибавить к текущему SP (он = BP) количество байт, помещённых в стек с момента прерывания
            mov ax, 0F53h
            stosw
            mov ax, 0F50h
            stosw
            mov ax, 0F3Dh
            stosw
            mov bx, bp
            add bx, 26          ; bp + 20 (наши push) + 6 (автоматические)
            call HexOut
            add di, 160-14

            ; CS
            mov ax, 0F43h
            stosw
            mov ax, 0F53h
            stosw
            mov ax, 0F3Dh
            stosw
            mov bx, [bp+22]
            call HexOut
            add di, 160-14

            ; IP
            mov ax, 0F49h
            stosw
            mov ax, 0F50h
            stosw
            mov ax, 0F3Dh
            stosw
            mov bx, [bp+20]
            call HexOut

                        ; --- ЧЕТВЁРТЫЙ СТОЛБЕЦ (флаги) ---
            mov di, (80d*5+60d)*2
            mov ax, [bp+24]
            push ax                      ; сохраняем в стеке, так как будем многократно использовать

            ; CF (бит 0)
            pop ax
            push ax
            mov bx, ax
            and bx, 1
            add bl, '0'
            mov ah, 0Fh                 ; атрибут
            mov al, 'C'
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
            mov ah, 0Fh
            mov al, 'P'
            stosw
            mov al, bl
            stosw
            add di, 160-10                 ; переход на следующую строку с учётом выведенных символов

            ; AF (бит 4)
            pop ax
            push ax
            mov bx, ax
            shr bx, 4
            and bx, 1
            add bl, '0'
            mov ah, 0Fh
            mov al, 'A'
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
            mov ah, 0Fh
            mov al, 'Z'
            stosw
            mov al, bl
            stosw
            add di, 160-10

            ; SF (бит 7)
            pop ax
            push ax
            mov bx, ax
            shr bx, 7
            and bx, 1
            add bl, '0'
            mov ah, 0Fh
            mov al, 'S'
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
            mov ah, 0Fh
            mov al, 'T'
            stosw
            mov al, bl
            stosw
            add di, 160-10

            ; IF (бит 9)
            pop ax
            push ax
            mov bx, ax
            shr bx, 9
            and bx, 1
            add bl, '0'
            mov ah, 0Fh
            mov al, 'I'
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
            mov ah, 0Fh
            mov al, 'D'
            stosw
            mov al, bl
            stosw
            add di, 160-10

            ; OF (бит 11)
            pop ax                         ; последний раз извлекаем, не пушим обратно
            mov bx, ax
            shr bx, 11
            and bx, 1
            add bl, '0'
            mov ah, 0Fh
            mov al, 'O'
            stosw
            mov al, bl
            stosw

            mov al, 20h
            out 20h, al

            pop ss es ds bp di si dx cx bx ax

                            ; iret использует cs и ip
            db 0EAh         ; опкод дальнего джампа
old08Ofs:   dw 0
old08Seg:   dw 0

            endp
EOP:

end         Start
