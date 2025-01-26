[bits 16]
%include "config.inc"

section .text
    global mouse_event_handler
    global mouse_get_position
    global mouse_get_buttons
    global mouse_is_over_window
    global mouse_is_over_taskbar
    
    extern wm_get_window_at
    extern wm_bring_to_front
    extern wm_start_window_drag

; Обработчик событий мыши
; Вход: нет
; Выход: нет
mouse_event_handler:
    pusha
    
    ; Получаем текущую позицию мыши
    call mouse_get_position    ; Возвращает в ax = x, bx = y
    mov [mouse_x], ax
    mov [mouse_y], bx
    
    ; Получаем состояние кнопок
    call mouse_get_buttons     ; Возвращает в al битовую маску кнопок
    mov [mouse_buttons], al
    
    ; Проверяем, изменилось ли состояние кнопок
    mov bl, [mouse_prev_buttons]
    xor bl, al                 ; bl = изменившиеся биты
    mov [mouse_prev_buttons], al
    
    test bl, MOUSE_LEFT_BUTTON
    jz .check_right_button
    
    ; Левая кнопка изменила состояние
    test al, MOUSE_LEFT_BUTTON
    jz .left_button_up
    
    ; Левая кнопка нажата
    ; Проверяем, находится ли курсор над окном
    push word [mouse_x]
    push word [mouse_y]
    call wm_get_window_at
    add sp, 4
    
    test ax, ax               ; ax = 0, если окно не найдено
    jz .check_taskbar
    
    ; Курсор над окном - начинаем перетаскивание
    push ax                   ; ID окна
    call wm_bring_to_front
    call wm_start_window_drag
    add sp, 2
    jmp .done
    
.check_taskbar:
    ; Проверяем клик по панели задач
    call mouse_is_over_taskbar
    test ax, ax
    jz .done
    
    ; Обрабатываем клик по панели задач
    call handle_taskbar_click
    jmp .done
    
.left_button_up:
    ; Левая кнопка отпущена
    mov byte [mouse_dragging], 0
    jmp .done
    
.check_right_button:
    test bl, MOUSE_RIGHT_BUTTON
    jz .done
    
    ; Правая кнопка изменила состояние
    test al, MOUSE_RIGHT_BUTTON
    jz .right_button_up
    
    ; Правая кнопка нажата - показываем контекстное меню
    push word [mouse_x]
    push word [mouse_y]
    call show_context_menu
    add sp, 4
    jmp .done
    
.right_button_up:
    ; Правая кнопка отпущена
    jmp .done
    
.done:
    popa
    ret

; Получение текущей позиции мыши
; Выход: ax = x, bx = y
mouse_get_position:
    push cx
    push dx
    
    mov ax, 0x0003      ; Получить позицию мыши
    int 0x33
    
    shr cx, 1           ; Преобразуем координаты из микки в пиксели
    mov ax, cx          ; x в ax
    mov bx, dx          ; y в bx
    
    pop dx
    pop cx
    ret

; Получение состояния кнопок мыши
; Выход: al = битовая маска кнопок
mouse_get_buttons:
    push bx
    push cx
    push dx
    
    mov ax, 0x0003      ; Получить состояние кнопок
    int 0x33
    
    mov al, bl          ; Копируем состояние кнопок в al
    
    pop dx
    pop cx
    pop bx
    ret

; Проверка, находится ли мышь над окном
; Вход: ax = x, bx = y, cx = window_id
; Выход: ax = 1 если да, 0 если нет
mouse_is_over_window:
    push bp
    mov bp, sp
    push bx
    push cx
    push dx
    
    ; Получаем параметры окна
    mov cx, [bp+8]      ; window_id
    call get_window_rect
    
    ; Проверяем x координату
    mov dx, [bp+6]      ; x
    cmp dx, ax          ; x < window.x?
    jl .not_over
    add ax, [window_width]
    cmp dx, ax          ; x > window.x + width?
    jg .not_over
    
    ; Проверяем y координату
    mov dx, [bp+4]      ; y
    cmp dx, bx          ; y < window.y?
    jl .not_over
    add bx, [window_height]
    cmp dx, bx          ; y > window.y + height?
    jg .not_over
    
    mov ax, 1           ; Курсор над окном
    jmp .done
    
.not_over:
    xor ax, ax          ; Курсор не над окном
    
.done:
    pop dx
    pop cx
    pop bx
    pop bp
    ret

; Проверка, находится ли мышь над панелью задач
; Вход: нет (использует текущие координаты мыши)
; Выход: ax = 1 если да, 0 если нет
mouse_is_over_taskbar:
    push bx
    
    mov ax, [mouse_y]
    mov bx, SCREEN_HEIGHT
    sub bx, TASKBAR_HEIGHT
    cmp ax, bx          ; y >= screen_height - taskbar_height?
    jl .not_over
    
    mov ax, 1
    jmp .done
    
.not_over:
    xor ax, ax
    
.done:
    pop bx
    ret

section .data
    mouse_dragging db 0        ; Флаг перетаскивания окна
    
section .bss
    mouse_x resw 1            ; Текущая x координата мыши
    mouse_y resw 1            ; Текущая y координата мыши
    mouse_buttons resb 1      ; Текущее состояние кнопок
    mouse_prev_buttons resb 1 ; Предыдущее состояние кнопок
