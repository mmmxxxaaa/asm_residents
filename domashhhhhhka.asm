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
            push bp
            push ax bx cx dx si di es ds

            mov bp, sp
                            ; Теперь стек выглядит так (сверху вниз, адреса относительно BP):
                            ; [BP]   = DS
                            ; [BP+2] = ES
                            ; [BP+4] = DI
                            ; [BP+6] = SI
                            ; [BP+8] = DX
                            ; [BP+10]= CX
                            ; [BP+12]= BX
                            ; [BP+14]= AX


            push 0b800h
            pop es

            mov di, 0       ;выводим с самого начала видеопамяти

            ; --- строка с АХ ---
            mov ax, 0F41h
            stosw
            mov ax, 0F58h
            stosw
            mov ax, 0F3Dh
            stosw

            mov bx, [bp+14]

            call HexOut

            add di, 148         ; переход на след строку

            ; --- строка c BX ---
            mov ax, 0F42h       ; B
            stosw
            mov ax, 0F58h       ; X
            stosw
            mov ax, 0F3Dh       ; =
            stosw
            mov bx, [bp+12]     ; значение BX
            call HexOut
            add di, 148

            ; --- строка с CX ---
            mov ax, 0F43h       ; C
            stosw
            mov ax, 0F58h       ; X
            stosw
            mov ax, 0F3Dh       ; =
            stosw
            mov bx, [bp+10]     ; значение CX
            call HexOut
            add di, 148

            ; --- строка с DX ---
            mov ax, 0F44h       ; D
            stosw
            mov ax, 0F58h       ; X
            stosw
            mov ax, 0F3Dh       ; =
            stosw
            mov bx, [bp+8]      ; значение DX
            call HexOut

            mov al, 20h
            out 20h, al

            pop ds
            pop es
            pop di
            pop si
            pop dx
            pop cx
            pop bx
            pop ax
            pop bp

            db 0EAh         ; опкод дальнего джампа
old08Ofs:   dw 0
old08Seg:   dw 0

            endp

EOP:

end         Start
