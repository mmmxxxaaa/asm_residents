.286
.model tiny
.code
org 100h

Start:      dd  90909090h
            mov ax, 3509h       ; AH = 35h (получить вектор), AL = 09h (номер прерывания)
            int 21h             ; возвращает ES:BX = старый вектор
            mov word ptr offset old09Ofs, bx
            mov bx, es
            mov word ptr offset old09Seg, bx    ; сохранили смещение и сегмент
            dd 90909090h

            ; --- устанавливаем свой обработчик ---
            push 0
            pop es                      ;ES = 0 (сегмент таблицы векторов прерываний)
            mov bx, 4*09h               ;смещение вектора 09h в таблице (каждый вектор 4 байта)
            cli
            mov es:[bx], offset New09_ne_katai_slovovslovo_s_sema  ;запишем смещение нового обработчика
            mov ax, cs
            mov es:[bx+2], ax           ;+2, так как у нас little-endian  ;;(забиваем на стандартный драйвер клавиатуры)
            sti

            mov ax, 3100h               ; функция DOS 31h (завершить программу, оставив её в памяти (TSR))
            mov dx, offset EOPPPPPPPPPPP
            shr dx, 4
            inc dx                      ;нацело может не делиться
            int 21h

New09_ne_katai_slovovslovo_s_sema proc
            push ax bx es
            push 0b800h
            pop es
            mov bx, (80d*5+40d)*2
            mov ah, 4eh
            in  al, 60h
            mov es:[bx], ax

            ;--- Подтверждение прерывания ---
            in al, 61h
            or al, 80h      ;Установка бита 7 порта 61h даёт сигнал подтверждения, что текущий scan-код обработан
            out 61h, al
            and al, not 80h
            out 61h, al
            mov al, 20h     ;20h - End Of Interrupt
            out 20h, al

            pop es bx ax
            db 0EAh         ; опкод дальнего джампа
old09Ofs:   dw 0
old09Seg:   dw 0

            endp

EOPPPPPPPPPPP:

end         Start
