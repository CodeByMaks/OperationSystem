[bits 16]
%include "config.inc"

section .text
    global draw_scrollbar
    global handle_scrollbar_click
    global update_scroll_position
    
    extern draw_rectangle
    extern draw_line
    extern mouse_get_position

; Структура полосы прокрутки:
; - word x
; - word y
; - word width
; - word height
; - word content_size    ; Полный размер содержимого
; - word visible_size    ; Видимый размер содержимого
; - word scroll_pos      ; Текущая позиция прокрутки
; - word thumb_size      ; Размер ползунка
; - word thumb_pos       ; Позиция ползунка

; Рисование полосы прокрутки
; Вход: bx = x, cx = y, dx = height, di = content_size, si = visible_size
draw_scrollbar:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Сохраняем параметры
    mov [scrollbar_x], bx
    mov [scrollbar_y], cx
    mov [scrollbar_height], dx
    mov [content_size], di
    mov [visible_size], si
    
    ; Рисуем фон полосы прокрутки
    mov al, COLOR_LGRAY
    mov dx, SCROLL_BAR_WIDTH
    call draw_rectangle
    
    ; Рисуем кнопку прокрутки вверх
    push bx
    push cx
    mov dx, SCROLL_BAR_WIDTH
    mov di, SCROLL_BTN_HEIGHT
    mov al, COLOR_DGRAY
    call draw_rectangle
    
    ; Рисуем стрелку вверх
    mov al, COLOR_WHITE
    add bx, SCROLL_BAR_WIDTH / 2
    add cx, SCROLL_BTN_HEIGHT / 2
    call draw_up_arrow
    pop cx
    pop bx
    
    ; Рисуем кнопку прокрутки вниз
    push bx
    push cx
    add cx, [scrollbar_height]
    sub cx, SCROLL_BTN_HEIGHT
    mov dx, SCROLL_BAR_WIDTH
    mov di, SCROLL_BTN_HEIGHT
    mov al, COLOR_DGRAY
    call draw_rectangle
    
    ; Рисуем стрелку вниз
    mov al, COLOR_WHITE
    add bx, SCROLL_BAR_WIDTH / 2
    add cx, SCROLL_BTN_HEIGHT / 2
    call draw_down_arrow
    pop cx
    pop bx
    
    ; Вычисляем размер и позицию ползунка
    call calculate_thumb_size
    call calculate_thumb_pos
    
    ; Рисуем ползунок
    add bx, 1
    add cx, [thumb_pos]
    mov dx, SCROLL_BAR_WIDTH - 2
    mov di, [thumb_size]
    mov al, COLOR_DGRAY
    call draw_rectangle
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret

; Обработка клика по полосе прокрутки
; Вход: bx = x клика, cx = y клика
; Выход: ax = 1 если клик обработан, 0 если нет
handle_scrollbar_click:
    push bp
    mov bp, sp
    push bx
    push cx
    push dx
    
    ; Проверяем, попал ли клик в полосу прокрутки
    mov dx, [scrollbar_x]
    cmp bx, dx
    jl .not_handled
    add dx, SCROLL_BAR_WIDTH
    cmp bx, dx
    jg .not_handled
    
    mov dx, [scrollbar_y]
    cmp cx, dx
    jl .not_handled
    add dx, [scrollbar_height]
    cmp cx, dx
    jg .not_handled
    
    ; Проверяем клик по кнопке вверх
    mov dx, [scrollbar_y]
    add dx, SCROLL_BTN_HEIGHT
    cmp cx, dx
    jge .check_down_button
    
    ; Прокручиваем вверх
    call scroll_up
    mov ax, 1
    jmp .done
    
.check_down_button:
    ; Проверяем клик по кнопке вниз
    mov dx, [scrollbar_y]
    add dx, [scrollbar_height]
    sub dx, SCROLL_BTN_HEIGHT
    cmp cx, dx
    jl .check_thumb
    
    ; Прокручиваем вниз
    call scroll_down
    mov ax, 1
    jmp .done
    
.check_thumb:
    ; Проверяем клик по ползунку
    mov dx, [scrollbar_y]
    add dx, [thumb_pos]
    cmp cx, dx
    jl .page_up
    add dx, [thumb_size]
    cmp cx, dx
    jg .page_down
    
    ; Начинаем перетаскивание ползунка
    mov [dragging_thumb], byte 1
    mov [drag_start_y], cx
    mov ax, [scroll_pos]
    mov [drag_start_pos], ax
    mov ax, 1
    jmp .done
    
.page_up:
    ; Прокручиваем на страницу вверх
    mov ax, [visible_size]
    call scroll_by
    mov ax, 1
    jmp .done
    
.page_down:
    ; Прокручиваем на страницу вниз
    mov ax, [visible_size]
    neg ax
    call scroll_by
    mov ax, 1
    jmp .done
    
.not_handled:
    xor ax, ax
    
.done:
    pop dx
    pop cx
    pop bx
    pop bp
    ret

; Обновление позиции прокрутки при перетаскивании
; Вход: cx = новая y позиция мыши
update_scroll_position:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    
    ; Проверяем, перетаскивается ли ползунок
    cmp byte [dragging_thumb], 0
    je .done
    
    ; Вычисляем смещение
    sub cx, [drag_start_y]
    
    ; Преобразуем смещение в пикселях в смещение содержимого
    mov ax, [content_size]
    sub ax, [visible_size]
    mov bx, [scrollbar_height]
    sub bx, 2 * SCROLL_BTN_HEIGHT
    sub bx, [thumb_size]
    
    imul cx                 ; ax = смещение * (content_size - visible_size)
    idiv bx                 ; ax = смещение в единицах содержимого
    
    ; Обновляем позицию прокрутки
    mov bx, [drag_start_pos]
    add bx, ax
    mov ax, bx
    
    ; Проверяем границы
    test ax, ax
    jns .check_max
    xor ax, ax
    jmp .set_pos
    
.check_max:
    mov bx, [content_size]
    sub bx, [visible_size]
    cmp ax, bx
    jle .set_pos
    mov ax, bx
    
.set_pos:
    mov [scroll_pos], ax
    
    ; Перерисовываем полосу прокрутки
    call draw_scrollbar
    
.done:
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret

; Вычисление размера ползунка
calculate_thumb_size:
    push ax
    push bx
    push dx
    
    ; Размер ползунка пропорционален отношению visible_size/content_size
    mov ax, [scrollbar_height]
    sub ax, 2 * SCROLL_BTN_HEIGHT  ; Вычитаем размер кнопок
    mov bx, [visible_size]
    mul bx
    mov bx, [content_size]
    div bx
    
    ; Проверяем минимальный размер
    cmp ax, SCROLL_MIN_THUMB
    jge .store_size
    mov ax, SCROLL_MIN_THUMB
    
.store_size:
    mov [thumb_size], ax
    
    pop dx
    pop bx
    pop ax
    ret

; Вычисление позиции ползунка
calculate_thumb_pos:
    push ax
    push bx
    push dx
    
    ; Позиция ползунка пропорциональна отношению scroll_pos/(content_size-visible_size)
    mov ax, [scrollbar_height]
    sub ax, 2 * SCROLL_BTN_HEIGHT  ; Вычитаем размер кнопок
    sub ax, [thumb_size]           ; Вычитаем размер ползунка
    mov bx, [scroll_pos]
    mul bx
    mov bx, [content_size]
    sub bx, [visible_size]
    div bx
    
    add ax, SCROLL_BTN_HEIGHT      ; Добавляем отступ для верхней кнопки
    mov [thumb_pos], ax
    
    pop dx
    pop bx
    pop ax
    ret

; Прокрутка вверх на одну строку
scroll_up:
    push ax
    
    mov ax, 1
    call scroll_by
    
    pop ax
    ret

; Прокрутка вниз на одну строку
scroll_down:
    push ax
    
    mov ax, -1
    call scroll_by
    
    pop ax
    ret

; Прокрутка на заданное количество строк
; Вход: ax = количество строк (положительное - вверх, отрицательное - вниз)
scroll_by:
    push bx
    
    ; Обновляем позицию прокрутки
    mov bx, [scroll_pos]
    sub bx, ax
    
    ; Проверяем границы
    test bx, bx
    jns .check_max
    xor bx, bx
    jmp .set_pos
    
.check_max:
    mov ax, [content_size]
    sub ax, [visible_size]
    cmp bx, ax
    jle .set_pos
    mov bx, ax
    
.set_pos:
    mov [scroll_pos], bx
    
    ; Перерисовываем полосу прокрутки
    call draw_scrollbar
    
    pop bx
    ret

; Рисование стрелки вверх
; Вход: bx = x центра, cx = y центра, al = цвет
draw_up_arrow:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    
    ; Рисуем три линии, формирующие стрелку
    sub bx, 3      ; Начало первой линии
    add cx, 2      ; Конец стрелки
    mov dx, bx
    add dx, 6      ; Конец первой линии
    push cx
    call draw_line
    pop cx
    
    sub bx, 2      ; Начало второй линии
    dec cx
    mov dx, bx
    add dx, 4      ; Конец второй линии
    push cx
    call draw_line
    pop cx
    
    dec bx         ; Начало третьей линии
    dec cx
    mov dx, bx
    add dx, 2      ; Конец третьей линии
    call draw_line
    
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret

; Рисование стрелки вниз
; Вход: bx = x центра, cx = y центра, al = цвет
draw_down_arrow:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    
    ; Рисуем три линии, формирующие стрелку
    sub bx, 3      ; Начало первой линии
    sub cx, 2      ; Начало стрелки
    mov dx, bx
    add dx, 6      ; Конец первой линии
    push cx
    call draw_line
    pop cx
    
    sub bx, 2      ; Начало второй линии
    inc cx
    mov dx, bx
    add dx, 4      ; Конец второй линии
    push cx
    call draw_line
    pop cx
    
    dec bx         ; Начало третьей линии
    inc cx
    mov dx, bx
    add dx, 2      ; Конец третьей линии
    call draw_line
    
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret

section .data
    dragging_thumb db 0     ; Флаг перетаскивания ползунка

section .bss
    scrollbar_x resw 1      ; X координата полосы прокрутки
    scrollbar_y resw 1      ; Y координата полосы прокрутки
    scrollbar_height resw 1 ; Высота полосы прокрутки
    content_size resw 1     ; Полный размер содержимого
    visible_size resw 1     ; Видимый размер содержимого
    scroll_pos resw 1       ; Текущая позиция прокрутки
    thumb_size resw 1       ; Размер ползунка
    thumb_pos resw 1        ; Позиция ползунка
    drag_start_y resw 1     ; Начальная y позиция при перетаскивании
    drag_start_pos resw 1   ; Начальная позиция прокрутки при перетаскивании
