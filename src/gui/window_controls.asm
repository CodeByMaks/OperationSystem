[bits 16]
%include "config.inc"

section .text
    global draw_window_controls
    global handle_window_control_click
    global maximize_window
    global minimize_window
    global restore_window
    global close_window
    
    extern draw_rectangle
    extern draw_line
    extern mouse_is_over_window
    extern wm_destroy_window
    extern wm_draw_all

; Структура для хранения информации о нормальном состоянии окна
struc WindowState
    .x:      resw 1
    .y:      resw 1
    .width:  resw 1
    .height: resw 1
endstruc

; Рисование кнопок управления окном
; Вход: ax = id окна, bx = x, cx = y, dx = width
draw_window_controls:
    push bp
    mov bp, sp
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Сохраняем координаты
    mov [window_x], bx
    mov [window_y], cx
    mov [window_width], dx
    
    ; Вычисляем позицию кнопки закрытия
    mov bx, dx
    sub bx, WINDOW_BTN_WIDTH
    sub bx, WINDOW_BTN_MARGIN
    
    ; Рисуем кнопку закрытия
    push bx                  ; x
    push cx                  ; y
    push word WINDOW_BTN_WIDTH
    push word WINDOW_BTN_HEIGHT
    mov al, COLOR_RED
    call draw_button
    call draw_close_icon
    add sp, 8
    
    ; Вычисляем позицию кнопки развертывания
    sub bx, WINDOW_BTN_WIDTH
    sub bx, WINDOW_BTN_SPACING
    
    ; Рисуем кнопку развертывания/восстановления
    push bx
    push cx
    push word WINDOW_BTN_WIDTH
    push word WINDOW_BTN_HEIGHT
    mov al, COLOR_LGRAY
    call draw_button
    
    ; Определяем, какую иконку рисовать
    test byte [window_flags], WINDOW_FLAG_MAXIMIZED
    jz .draw_maximize_icon
    call draw_restore_icon
    jmp .next_button
.draw_maximize_icon:
    call draw_maximize_icon
    
.next_button:
    add sp, 8
    
    ; Вычисляем позицию кнопки свертывания
    sub bx, WINDOW_BTN_WIDTH
    sub bx, WINDOW_BTN_SPACING
    
    ; Рисуем кнопку свертывания
    push bx
    push cx
    push word WINDOW_BTN_WIDTH
    push word WINDOW_BTN_HEIGHT
    mov al, COLOR_LGRAY
    call draw_button
    call draw_minimize_icon
    add sp, 8
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop bp
    ret

; Обработка клика по кнопкам управления
; Вход: ax = id окна, bx = x, cx = y
; Выход: ax = 1 если клик обработан, 0 если нет
handle_window_control_click:
    push bp
    mov bp, sp
    push bx
    push cx
    push dx
    
    ; Проверяем клик по кнопке закрытия
    mov dx, [window_width]
    sub dx, WINDOW_BTN_WIDTH
    sub dx, WINDOW_BTN_MARGIN
    
    call is_click_in_button
    test ax, ax
    jz .check_maximize
    
    ; Закрываем окно
    mov ax, [window_id]
    call close_window
    mov ax, 1
    jmp .done
    
.check_maximize:
    ; Проверяем клик по кнопке развертывания
    sub dx, WINDOW_BTN_WIDTH
    sub dx, WINDOW_BTN_SPACING
    
    call is_click_in_button
    test ax, ax
    jz .check_minimize
    
    ; Разворачиваем/восстанавливаем окно
    test byte [window_flags], WINDOW_FLAG_MAXIMIZED
    jz .do_maximize
    
    call restore_window
    jmp .handled
    
.do_maximize:
    call maximize_window
    
.handled:
    mov ax, 1
    jmp .done
    
.check_minimize:
    ; Проверяем клик по кнопке свертывания
    sub dx, WINDOW_BTN_WIDTH
    sub dx, WINDOW_BTN_SPACING
    
    call is_click_in_button
    test ax, ax
    jz .not_handled
    
    ; Сворачиваем окно
    call minimize_window
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

; Проверка, находится ли клик в пределах кнопки
; Вход: bx = x клика, cx = y клика, dx = x кнопки
; Выход: ax = 1 если да, 0 если нет
is_click_in_button:
    push bp
    mov bp, sp
    
    ; Проверяем x координату
    cmp bx, dx
    jl .not_in_button
    add dx, WINDOW_BTN_WIDTH
    cmp bx, dx
    jg .not_in_button
    
    ; Проверяем y координату
    mov dx, [window_y]
    cmp cx, dx
    jl .not_in_button
    add dx, WINDOW_BTN_HEIGHT
    cmp cx, dx
    jg .not_in_button
    
    mov ax, 1
    jmp .done
    
.not_in_button:
    xor ax, ax
    
.done:
    pop bp
    ret

; Развертывание окна
maximize_window:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    
    ; Сохраняем текущее состояние окна
    mov ax, [window_id]
    call save_window_state
    
    ; Устанавливаем новые размеры
    xor bx, bx              ; x = 0
    xor cx, cx              ; y = 0
    mov dx, SCREEN_WIDTH    ; width = screen_width
    mov di, SCREEN_HEIGHT
    sub di, TASKBAR_HEIGHT  ; height = screen_height - taskbar_height
    
    call set_window_position
    
    ; Устанавливаем флаг развернутого окна
    or byte [window_flags], WINDOW_FLAG_MAXIMIZED
    
    ; Перерисовываем окно
    call wm_draw_all
    
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret

; Свертывание окна
minimize_window:
    push bp
    mov bp, sp
    push ax
    
    ; Сохраняем текущее состояние окна если оно не сохранено
    test byte [window_flags], WINDOW_FLAG_MAXIMIZED
    jnz .already_saved
    
    mov ax, [window_id]
    call save_window_state
    
.already_saved:
    ; Устанавливаем флаг свернутого окна
    or byte [window_flags], WINDOW_FLAG_MINIMIZED
    
    ; Скрываем окно
    mov byte [window_visible], 0
    
    ; Перерисовываем все окна
    call wm_draw_all
    
    pop ax
    pop bp
    ret

; Восстановление окна
restore_window:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    
    ; Восстанавливаем сохраненное состояние
    mov ax, [window_id]
    call restore_window_state
    
    ; Сбрасываем флаги
    and byte [window_flags], ~(WINDOW_FLAG_MAXIMIZED | WINDOW_FLAG_MINIMIZED)
    
    ; Показываем окно
    mov byte [window_visible], 1
    
    ; Перерисовываем все окна
    call wm_draw_all
    
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret

; Закрытие окна
close_window:
    push bp
    mov bp, sp
    push ax
    
    ; Уничтожаем окно
    mov ax, [window_id]
    call wm_destroy_window
    
    ; Перерисовываем все окна
    call wm_draw_all
    
    pop ax
    pop bp
    ret

; Сохранение состояния окна
; Вход: ax = id окна
save_window_state:
    push bp
    mov bp, sp
    push bx
    push cx
    push dx
    push di
    
    ; Находим структуру окна
    mov bx, ax
    shl bx, 3      ; Умножаем на размер структуры WindowState
    add bx, window_states
    
    ; Сохраняем текущее состояние
    mov ax, [window_x]
    mov [bx + WindowState.x], ax
    mov ax, [window_y]
    mov [bx + WindowState.y], ax
    mov ax, [window_width]
    mov [bx + WindowState.width], ax
    mov ax, [window_height]
    mov [bx + WindowState.height], ax
    
    pop di
    pop dx
    pop cx
    pop bx
    pop bp
    ret

; Восстановление состояния окна
; Вход: ax = id окна
restore_window_state:
    push bp
    mov bp, sp
    push bx
    push cx
    push dx
    push di
    
    ; Находим структуру окна
    mov bx, ax
    shl bx, 3      ; Умножаем на размер структуры WindowState
    add bx, window_states
    
    ; Восстанавливаем состояние
    mov ax, [bx + WindowState.x]
    mov [window_x], ax
    mov ax, [bx + WindowState.y]
    mov [window_y], ax
    mov ax, [bx + WindowState.width]
    mov [window_width], ax
    mov ax, [bx + WindowState.height]
    mov [window_height], ax
    
    pop di
    pop dx
    pop cx
    pop bx
    pop bp
    ret

; Рисование иконки закрытия
draw_close_icon:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    
    ; Получаем координаты центра кнопки
    mov bx, [bp + 4]   ; x
    add bx, WINDOW_BTN_WIDTH / 2
    mov cx, [bp + 6]   ; y
    add cx, WINDOW_BTN_HEIGHT / 2
    
    ; Рисуем крестик
    mov al, COLOR_WHITE
    sub bx, 3
    sub cx, 3
    mov dx, bx
    add dx, 6
    mov di, cx
    add di, 6
    call draw_line     ; Диагональ \
    
    sub bx, 3
    add cx, 6
    mov dx, bx
    add dx, 6
    mov di, cx
    sub di, 6
    call draw_line     ; Диагональ /
    
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret

; Рисование иконки развертывания
draw_maximize_icon:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    
    ; Получаем координаты кнопки
    mov bx, [bp + 4]   ; x
    mov cx, [bp + 6]   ; y
    
    ; Рисуем прямоугольник
    add bx, 2
    add cx, 2
    mov dx, WINDOW_BTN_WIDTH - 4
    mov di, WINDOW_BTN_HEIGHT - 4
    mov al, COLOR_WHITE
    call draw_rectangle
    
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret

; Рисование иконки восстановления
draw_restore_icon:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    
    ; Получаем координаты кнопки
    mov bx, [bp + 4]   ; x
    mov cx, [bp + 6]   ; y
    
    ; Рисуем два наложенных прямоугольника
    add bx, 3
    add cx, 3
    mov dx, WINDOW_BTN_WIDTH - 6
    mov di, WINDOW_BTN_HEIGHT - 6
    mov al, COLOR_WHITE
    call draw_rectangle
    
    sub bx, 2
    sub cx, 2
    call draw_rectangle
    
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret

; Рисование иконки свертывания
draw_minimize_icon:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    
    ; Получаем координаты кнопки
    mov bx, [bp + 4]   ; x
    mov cx, [bp + 6]   ; y
    
    ; Рисуем горизонтальную линию
    add bx, 2
    add cx, WINDOW_BTN_HEIGHT - 4
    mov dx, WINDOW_BTN_WIDTH - 4
    mov al, COLOR_WHITE
    call draw_line
    
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret

section .data
    window_states resb MAX_WINDOWS * WindowState_size  ; Сохраненные состояния окон

section .bss
    window_id resw 1        ; ID текущего окна
    window_x resw 1         ; X координата окна
    window_y resw 1         ; Y координата окна
    window_width resw 1     ; Ширина окна
    window_height resw 1    ; Высота окна
    window_flags resb 1     ; Флаги состояния окна
    window_visible resb 1   ; Флаг видимости окна
