[bits 16]
[org 0x4000]  ; Смещение модуля graphics

%include "config.inc"

; Константы графики
ICON_SIZE       equ 16    ; Размер иконки в пикселях

section .text
    global draw_pixel
    global draw_line
    global draw_rectangle
    global draw_text
    global draw_icon
    global save_screen_region
    global restore_screen_region

; Рисование пикселя
; Вход: ax = x, bx = y, cl = цвет
draw_pixel:
    push bp
    mov bp, sp
    push es
    push di
    
    ; Установка сегмента видеопамяти
    mov di, 0xA000
    mov es, di
    
    ; Вычисление смещения
    mov di, bx
    imul di, SCREEN_WIDTH
    add di, ax
    
    ; Установка цвета пикселя
    mov [es:di], cl
    
    pop di
    pop es
    pop bp
    ret

; Рисование линии (алгоритм Брезенхема)
; Вход: ax = x1, dx = y1, si = x2, di = y2, bx = цвет
draw_line:
    push bp
    mov bp, sp
    
    push ax      ; Сохраняем x1
    push dx      ; Сохраняем y1
    push si      ; Сохраняем x2
    push di      ; Сохраняем y2
    push bx      ; Сохраняем color
    
    ; Вычисление dx и dy
    mov ax, [bp-6]    ; x2
    sub ax, [bp-10]   ; x1
    mov [delta_x], ax
    
    mov ax, [bp-4]    ; y2
    sub ax, [bp-8]    ; y1
    mov [delta_y], ax
    
    ; Определение направления
    mov ax, [delta_x]
    test ax, ax
    jns .dx_positive
    neg ax
.dx_positive:
    mov [abs_dx], ax
    
    mov ax, [delta_y]
    test ax, ax
    jns .dy_positive
    neg ax
.dy_positive:
    mov [abs_dy], ax
    
    ; Выбор основного направления
    mov ax, [abs_dx]
    cmp ax, [abs_dy]
    jae .horizontal
    
    ; Вертикальная линия
    mov cx, [abs_dy]
    inc cx
    mov ax, [delta_y]
    test ax, ax
    jns .y_increment
    mov word [step_y], -1
    jmp .y_step_done
.y_increment:
    mov word [step_y], 1
.y_step_done:
    
    mov ax, [delta_x]
    shl ax, 1
    mov [error], ax
    mov ax, [abs_dy]
    shl ax, 1
    mov [delta_err], ax
    jmp .draw_loop
    
.horizontal:
    ; Горизонтальная линия
    mov cx, [abs_dx]
    inc cx
    mov ax, [delta_x]
    test ax, ax
    jns .x_increment
    mov word [step_x], -1
    jmp .x_step_done
.x_increment:
    mov word [step_x], 1
.x_step_done:
    
    mov ax, [delta_y]
    shl ax, 1
    mov [error], ax
    mov ax, [abs_dx]
    shl ax, 1
    mov [delta_err], ax
    
.draw_loop:
    ; Отрисовка точки
    mov ax, 0xA000
    mov es, ax
    
    mov ax, [bp-8]    ; y
    mov bx, SCREEN_WIDTH
    mul bx
    add ax, [bp-10]   ; x
    mov di, ax
    
    mov al, [bp-2]    ; color
    mov [es:di], al
    
    ; Обновление координат
    mov ax, [error]
    add ax, [delta_err]
    mov [error], ax
    
    test cx, cx
    jz .done
    
    dec cx
    jmp .draw_loop
    
.done:
    pop bx
    pop di
    pop si
    pop dx
    pop ax
    
    pop bp
    ret

; Рисование прямоугольника
; Вход: ax = x, dx = y, si = width, di = height, bx = цвет
draw_rectangle:
    push bp
    mov bp, sp
    
    push ax      ; Сохраняем x
    push dx      ; Сохраняем y
    push si      ; Сохраняем width
    push di      ; Сохраняем height
    push bx      ; Сохраняем color
    
    ; Вычисление адреса в видеопамяти
    mov ax, 0xA000
    mov es, ax
    
    ; Внешний цикл (по высоте)
.height_loop:
    mov cx, [bp-6]    ; Восстанавливаем width
    mov di, [bp-8]    ; Восстанавливаем x
    
    ; Вычисление смещения в видеопамяти
    mov ax, [bp-4]    ; y
    mov bx, SCREEN_WIDTH
    mul bx
    add ax, di
    mov di, ax
    
    ; Внутренний цикл (по ширине)
.width_loop:
    mov al, [bp-2]    ; color
    mov [es:di], al
    inc di
    loop .width_loop
    
    inc word [bp-4]   ; y++
    dec word [bp-10]  ; height--
    jnz .height_loop
    
    pop bx
    pop di
    pop si
    pop dx
    pop ax
    
    pop bp
    ret

; Рисование текста
; Вход: ax = x, dx = y, si = указатель на строку, bx = цвет
draw_text:
    push bp
    mov bp, sp
    
    push ax      ; Сохраняем x
    push dx      ; Сохраняем y
    push si      ; Сохраняем указатель на строку
    push bx      ; Сохраняем color
    
    ; Вычисление адреса в видеопамяти
    mov ax, 0xA000
    mov es, ax
    
.char_loop:
    lodsb           ; Загружаем следующий символ
    test al, al     ; Проверка на конец строки
    jz .done
    
    push si         ; Сохраняем указатель на строку
    
    ; Вычисление адреса символа в шрифте
    mov si, font_data
    mov ah, 0
    shl ax, 3      ; Умножаем на 8 (высота символа)
    add si, ax
    
    ; Вычисление адреса в видеопамяти
    mov ax, [bp-4]  ; y
    mov bx, SCREEN_WIDTH
    mul bx
    add ax, [bp-6]  ; x
    mov di, ax
    
    ; Отрисовка символа (8x8 пикселей)
    mov cx, 8       ; Высота символа
.pixel_loop:
    mov al, [si]    ; Загружаем строку пикселей
    mov ah, 8       ; Ширина символа
    
.bit_loop:
    shl al, 1       ; Сдвигаем биты влево
    jnc .skip_pixel ; Если бит = 0, пропускаем пиксель
    
    mov bl, [bp-2]  ; color
    mov [es:di], bl ; Рисуем пиксель
    
.skip_pixel:
    inc di
    dec ah
    jnz .bit_loop
    
    add di, SCREEN_WIDTH - 8  ; Переход на следующую строку
    inc si                    ; Следующая строка символа
    loop .pixel_loop
    
    pop si          ; Восстанавливаем указатель на строку
    add word [bp-6], 8  ; Смещаем x для следующего символа
    jmp .char_loop
    
.done:
    pop bx
    pop si
    pop dx
    pop ax
    
    pop bp
    ret

; Рисование иконки
; Вход: ax = x, dx = y, si = указатель на данные иконки
draw_icon:
    push bp
    mov bp, sp
    
    push ax      ; Сохраняем x
    push dx      ; Сохраняем y
    push si      ; Сохраняем указатель на данные
    
    ; Вычисление адреса в видеопамяти
    mov ax, 0xA000
    mov es, ax
    
    mov cx, ICON_SIZE    ; Высота иконки
.row_loop:
    push cx
    mov cx, ICON_SIZE    ; Ширина иконки
    
    ; Вычисление адреса строки в видеопамяти
    mov ax, [bp-4]       ; y
    mov bx, SCREEN_WIDTH
    mul bx
    add ax, [bp-6]       ; x
    mov di, ax
    
.pixel_loop:
    lodsb               ; Загружаем цвет пикселя
    mov [es:di], al     ; Записываем пиксель
    inc di
    loop .pixel_loop
    
    inc word [bp-4]     ; y++
    pop cx
    loop .row_loop
    
    pop si
    pop dx
    pop ax
    
    pop bp
    ret

; Сохранение области экрана
; Вход: ax = x, dx = y, si = width, di = height
save_screen_region:
    push bp
    mov bp, sp
    push ax
    push dx
    push si
    push di
    push es
    
    ; Установка сегмента видеопамяти
    mov si, 0xA000
    mov es, si
    
    ; Вычисление начального смещения
    mov si, dx
    imul si, SCREEN_WIDTH
    add si, ax
    
    ; Сохранение в буфер
    mov di, screen_buffer
    mov bx, di      ; счетчик строк
    
.next_row:
    push si
    push di
    rep movsb       ; копируем строку
    pop di
    pop si
    
    add si, SCREEN_WIDTH  ; следующая строка
    dec bx
    jnz .next_row
    
    pop es
    pop di
    pop si
    pop di
    pop dx
    pop ax
    pop bp
    ret

; Восстановление области экрана
; Вход: ax = x, dx = y, si = width, di = height
restore_screen_region:
    push bp
    mov bp, sp
    push ax
    push dx
    push si
    push di
    push es
    
    ; Установка сегмента видеопамяти
    mov di, 0xA000
    mov es, di
    
    ; Вычисление начального смещения
    mov di, dx
    imul di, SCREEN_WIDTH
    add di, ax
    
    ; Восстановление из буфера
    mov si, screen_buffer
    mov bx, di      ; счетчик строк
    
.next_row:
    push di
    push si
    rep movsb       ; копируем строку
    pop si
    pop di
    
    add di, SCREEN_WIDTH  ; следующая строка
    dec bx
    jnz .next_row
    
    pop es
    pop di
    pop si
    pop di
    pop dx
    pop ax
    pop bp
    ret

section .data
    ; 8x8 шрифт (ASCII 32-127)
    font_data:
        ; Пробел (32)
        db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
        ; ! (33)
        db 0x18, 0x18, 0x18, 0x18, 0x18, 0x00, 0x18, 0x00
        ; Остальные символы...
        ; Здесь должны быть определены все символы ASCII от 32 до 127
        
    ; Переменные для алгоритма Брезенхэма
    delta_x dw 0
    delta_y dw 0
    abs_dx  dw 0
    abs_dy  dw 0
    step_x  dw 0
    step_y  dw 0
    error   dw 0
    delta_err dw 0

section .bss
    screen_buffer: resb 64000  ; Буфер для сохранения области экрана (максимум 320x200)
