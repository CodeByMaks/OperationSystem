[bits 16]
%include "config.inc"

section .text
    global get_resize_area
    global start_window_resize
    global update_window_size
    global draw_resize_handles
    
    extern draw_rectangle
    extern draw_line
    extern mouse_get_position
    extern wm_draw_all

; Получение области изменения размера под курсором
; Вход: bx = x курсора, cx = y курсора, dx = id окна
; Выход: ax = флаги области изменения размера (RESIZE_*)
get_resize_area:
    push bp
    mov bp, sp
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Получаем параметры окна
    mov si, dx          ; si = window_id
    call get_window_rect
    
    ; Проверяем левую границу
    mov dx, ax          ; dx = window_x
    add dx, RESIZE_BORDER_SIZE
    cmp bx, dx
    jg .check_right
    
    mov ax, RESIZE_LEFT
    
    ; Проверяем верхний левый угол
    mov dx, di          ; dx = window_y
    add dx, RESIZE_BORDER_SIZE
    cmp cx, dx
    jg .check_bottom_left
    
    or ax, RESIZE_TOP
    jmp .done
    
.check_bottom_left:
    ; Проверяем нижний левый угол
    mov dx, di
    add dx, [window_height]
    sub dx, RESIZE_BORDER_SIZE
    cmp cx, dx
    jl .done
    
    or ax, RESIZE_BOTTOM
    jmp .done
    
.check_right:
    ; Проверяем правую границу
    mov dx, ax
    add dx, [window_width]
    sub dx, RESIZE_BORDER_SIZE
    cmp bx, dx
    jl .check_top
    
    mov ax, RESIZE_RIGHT
    
    ; Проверяем верхний правый угол
    mov dx, di
    add dx, RESIZE_BORDER_SIZE
    cmp cx, dx
    jg .check_bottom_right
    
    or ax, RESIZE_TOP
    jmp .done
    
.check_bottom_right:
    ; Проверяем нижний правый угол
    mov dx, di
    add dx, [window_height]
    sub dx, RESIZE_BORDER_SIZE
    cmp cx, dx
    jl .done
    
    or ax, RESIZE_BOTTOM
    jmp .done
    
.check_top:
    ; Проверяем верхнюю границу
    mov dx, di
    add dx, RESIZE_BORDER_SIZE
    cmp cx, dx
    jg .check_bottom
    
    mov ax, RESIZE_TOP
    jmp .done
    
.check_bottom:
    ; Проверяем нижнюю границу
    mov dx, di
    add dx, [window_height]
    sub dx, RESIZE_BORDER_SIZE
    cmp cx, dx
    jl .no_resize
    
    mov ax, RESIZE_BOTTOM
    jmp .done
    
.no_resize:
    xor ax, ax
    
.done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop bp
    ret

; Начало изменения размера окна
; Вход: ax = id окна, bx = флаги области изменения размера
start_window_resize:
    push bp
    mov bp, sp
    push ax
    push bx
    
    ; Сохраняем параметры
    mov [resize_window_id], ax
    mov [resize_flags], bx
    
    ; Получаем текущую позицию мыши
    call mouse_get_position
    mov [resize_start_x], ax
    mov [resize_start_y], bx
    
    ; Сохраняем текущие размеры окна
    mov ax, [resize_window_id]
    call get_window_rect
    mov [window_start_x], ax
    mov [window_start_y], di
    mov ax, [window_width]
    mov [window_start_width], ax
    mov ax, [window_height]
    mov [window_start_height], ax
    
    ; Устанавливаем флаг изменения размера
    or byte [window_flags], WINDOW_FLAG_RESIZING
    
    pop bx
    pop ax
    pop bp
    ret

; Обновление размера окна
; Вход: bx = новый x курсора, cx = новый y курсора
update_window_size:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Вычисляем смещение мыши
    sub bx, [resize_start_x]    ; dx = смещение по x
    sub cx, [resize_start_y]    ; dy = смещение по y
    
    ; Получаем текущие параметры окна
    mov ax, [window_start_x]
    mov dx, [window_start_width]
    mov si, [window_start_y]
    mov di, [window_start_height]
    
    ; Обрабатываем изменение размера по горизонтали
    test byte [resize_flags], RESIZE_LEFT
    jz .check_right
    
    ; Изменяем левую границу
    add ax, bx              ; Новый x
    sub dx, bx              ; Новая ширина
    
    ; Проверяем минимальную ширину
    cmp dx, WINDOW_MIN_WIDTH
    jge .check_vertical
    
    mov dx, WINDOW_MIN_WIDTH
    mov ax, [window_start_x]
    add ax, [window_start_width]
    sub ax, WINDOW_MIN_WIDTH
    jmp .check_vertical
    
.check_right:
    test byte [resize_flags], RESIZE_RIGHT
    jz .check_vertical
    
    ; Изменяем правую границу
    add dx, bx              ; Новая ширина
    
    ; Проверяем минимальную ширину
    cmp dx, WINDOW_MIN_WIDTH
    jge .check_vertical
    
    mov dx, WINDOW_MIN_WIDTH
    
.check_vertical:
    ; Обрабатываем изменение размера по вертикали
    test byte [resize_flags], RESIZE_TOP
    jz .check_bottom
    
    ; Изменяем верхнюю границу
    add si, cx              ; Новый y
    sub di, cx              ; Новая высота
    
    ; Проверяем минимальную высоту
    cmp di, WINDOW_MIN_HEIGHT
    jge .update_window
    
    mov di, WINDOW_MIN_HEIGHT
    mov si, [window_start_y]
    add si, [window_start_height]
    sub si, WINDOW_MIN_HEIGHT
    jmp .update_window
    
.check_bottom:
    test byte [resize_flags], RESIZE_BOTTOM
    jz .update_window
    
    ; Изменяем нижнюю границу
    add di, cx              ; Новая высота
    
    ; Проверяем минимальную высоту
    cmp di, WINDOW_MIN_HEIGHT
    jge .update_window
    
    mov di, WINDOW_MIN_HEIGHT
    
.update_window:
    ; Обновляем параметры окна
    mov [window_x], ax
    mov [window_y], si
    mov [window_width], dx
    mov [window_height], di
    
    ; Перерисовываем окно
    call wm_draw_all
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret

; Рисование маркеров изменения размера
; Вход: ax = id окна
draw_resize_handles:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Получаем параметры окна
    mov si, ax              ; si = window_id
    call get_window_rect
    
    ; Рисуем угловые маркеры
    mov al, COLOR_WHITE     ; Цвет маркеров
    
    ; Верхний левый угол
    push ax
    push di
    mov bx, ax
    mov cx, di
    mov dx, RESIZE_CORNER_SIZE
    mov di, RESIZE_CORNER_SIZE
    call draw_resize_handle
    pop di
    pop ax
    
    ; Верхний правый угол
    push ax
    push di
    mov bx, ax
    add bx, [window_width]
    sub bx, RESIZE_CORNER_SIZE
    mov cx, di
    mov dx, RESIZE_CORNER_SIZE
    mov di, RESIZE_CORNER_SIZE
    call draw_resize_handle
    pop di
    pop ax
    
    ; Нижний левый угол
    push ax
    push di
    mov bx, ax
    mov cx, di
    add cx, [window_height]
    sub cx, RESIZE_CORNER_SIZE
    mov dx, RESIZE_CORNER_SIZE
    mov di, RESIZE_CORNER_SIZE
    call draw_resize_handle
    pop di
    pop ax
    
    ; Нижний правый угол
    mov bx, ax
    add bx, [window_width]
    sub bx, RESIZE_CORNER_SIZE
    mov cx, di
    add cx, [window_height]
    sub cx, RESIZE_CORNER_SIZE
    mov dx, RESIZE_CORNER_SIZE
    mov di, RESIZE_CORNER_SIZE
    call draw_resize_handle
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret

; Рисование маркера изменения размера
; Вход: bx = x, cx = y, dx = width, di = height, al = цвет
draw_resize_handle:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    
    ; Рисуем прямоугольник
    call draw_rectangle
    
    ; Рисуем диагональные линии
    mov al, COLOR_DGRAY
    
    ; Первая диагональ
    push bx
    push cx
    mov dx, bx
    add dx, di
    mov di, cx
    add di, di
    call draw_line
    pop cx
    pop bx
    
    ; Вторая диагональ
    add bx, di
    call draw_line
    
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret

section .data
    resize_cursors:
        db 0x0C    ; Курсор по умолчанию
        db 0x1C    ; Горизонтальное изменение размера
        db 0x1D    ; Вертикальное изменение размера
        db 0x1E    ; Диагональное изменение размера (/)
        db 0x1F    ; Диагональное изменение размера (\)

section .bss
    resize_window_id resw 1      ; ID окна, размер которого изменяется
    resize_flags resw 1          ; Флаги области изменения размера
    resize_start_x resw 1        ; Начальная x позиция мыши
    resize_start_y resw 1        ; Начальная y позиция мыши
    window_start_x resw 1        ; Начальная x позиция окна
    window_start_y resw 1        ; Начальная y позиция окна
    window_start_width resw 1    ; Начальная ширина окна
    window_start_height resw 1   ; Начальная высота окна
