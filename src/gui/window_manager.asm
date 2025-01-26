[bits 16]
%include "config.inc"

section .text
    global wm_init
    global wm_create_window
    global wm_destroy_window
    global wm_draw_all
    global wm_get_window_at
    global wm_bring_to_front
    global wm_start_window_drag
    global wm_update_window_position
    
    extern draw_window
    extern mouse_get_position

; Структура окна:
; - word id
; - word x
; - word y
; - word width
; - word height
; - byte active
; - byte visible
; - word next_window
; - byte title_length
; - byte title[32]

WINDOW_SIZE equ 48

; Инициализация оконного менеджера
wm_init:
    push ax
    
    ; Инициализируем список окон
    mov word [window_count], 0
    mov word [active_window], 0
    mov word [first_window], 0
    mov byte [dragging_window], 0
    
    pop ax
    ret

; Создание нового окна
; Вход: bx = x, cx = y, dx = width, di = height, si = указатель на заголовок
; Выход: ax = id окна или 0 если ошибка
wm_create_window:
    push bp
    mov bp, sp
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Проверяем, есть ли место для нового окна
    mov ax, [window_count]
    cmp ax, MAX_WINDOWS
    jge .error
    
    ; Выделяем память для окна
    mov ax, WINDOW_SIZE
    mul word [window_count]
    add ax, windows
    mov di, ax
    
    ; Заполняем структуру окна
    inc word [window_count]
    mov ax, [window_count]
    mov [di], ax        ; id
    mov [di + 2], bx    ; x
    mov [di + 4], cx    ; y
    mov [di + 6], dx    ; width
    mov [di + 8], di    ; height
    mov byte [di + 10], 1  ; active
    mov byte [di + 11], 1  ; visible
    
    ; Копируем заголовок
    mov cx, 32          ; Максимальная длина заголовка
    mov si, [bp + 8]    ; Указатель на заголовок
    lea di, [di + 14]   ; Смещение для заголовка
    rep movsb
    
    ; Добавляем окно в список
    mov ax, [window_count]
    mov bx, [first_window]
    mov [first_window], ax
    mov [di + 12], bx   ; next_window
    
    ; Возвращаем id окна
    mov ax, [window_count]
    jmp .done
    
.error:
    xor ax, ax
    
.done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop bp
    ret

; Удаление окна
; Вход: ax = id окна
wm_destroy_window:
    push bp
    mov bp, sp
    push bx
    push cx
    push dx
    
    ; Находим окно по id
    call find_window
    test ax, ax
    jz .done
    
    ; Удаляем окно из списка
    mov bx, [first_window]
    cmp ax, bx
    jne .find_prev
    
    ; Окно первое в списке
    mov bx, [ax + 12]
    mov [first_window], bx
    jmp .remove
    
.find_prev:
    ; Ищем предыдущее окно
    mov dx, ax
    mov ax, bx
    
.find_prev_loop:
    mov bx, [ax + 12]
    cmp bx, dx
    je .found_prev
    mov ax, bx
    jmp .find_prev_loop
    
.found_prev:
    ; Обновляем ссылку на следующее окно
    mov bx, [dx + 12]
    mov [ax + 12], bx
    
.remove:
    ; Уменьшаем счетчик окон
    dec word [window_count]
    
    ; Очищаем память окна
    mov cx, WINDOW_SIZE
    mov di, ax
    xor al, al
    rep stosb
    
.done:
    pop dx
    pop cx
    pop bx
    pop bp
    ret

; Отрисовка всех окон
wm_draw_all:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Начинаем с первого окна
    mov si, [first_window]
    
.draw_loop:
    test si, si
    jz .done
    
    ; Проверяем видимость окна
    cmp byte [si + 11], 0  ; visible
    je .next_window
    
    ; Рисуем окно
    mov bx, [si + 2]    ; x
    mov cx, [si + 4]    ; y
    mov dx, [si + 6]    ; width
    mov di, [si + 8]    ; height
    lea ax, [si + 14]   ; title
    push ax
    call draw_window
    add sp, 2
    
.next_window:
    mov si, [si + 12]   ; next_window
    jmp .draw_loop
    
.done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Получить окно по координатам
; Вход: bx = x, cx = y
; Выход: ax = id окна или 0 если не найдено
wm_get_window_at:
    push bp
    mov bp, sp
    push bx
    push cx
    push dx
    push si
    
    ; Начинаем с первого окна
    mov si, [first_window]
    xor ax, ax
    
.check_loop:
    test si, si
    jz .done
    
    ; Проверяем видимость окна
    cmp byte [si + 11], 0  ; visible
    je .next_window
    
    ; Проверяем координаты
    mov dx, [si + 2]    ; x
    cmp bx, dx
    jl .next_window
    add dx, [si + 6]    ; width
    cmp bx, dx
    jg .next_window
    
    mov dx, [si + 4]    ; y
    cmp cx, dx
    jl .next_window
    add dx, [si + 8]    ; height
    cmp cx, dx
    jg .next_window
    
    ; Окно найдено
    mov ax, [si]        ; id
    jmp .done
    
.next_window:
    mov si, [si + 12]   ; next_window
    jmp .check_loop
    
.done:
    pop si
    pop dx
    pop cx
    pop bx
    pop bp
    ret

; Переместить окно на передний план
; Вход: ax = id окна
wm_bring_to_front:
    push bp
    mov bp, sp
    push bx
    push cx
    push dx
    
    ; Находим окно по id
    call find_window
    test ax, ax
    jz .done
    
    ; Если окно уже первое, ничего не делаем
    cmp ax, [first_window]
    je .done
    
    ; Находим предыдущее окно
    mov bx, [first_window]
    mov dx, ax
    
.find_prev_loop:
    mov cx, [bx + 12]
    cmp cx, dx
    je .found_prev
    mov bx, cx
    jmp .find_prev_loop
    
.found_prev:
    ; Обновляем ссылки
    mov cx, [dx + 12]
    mov [bx + 12], cx   ; prev->next = window->next
    mov cx, [first_window]
    mov [dx + 12], cx   ; window->next = first_window
    mov [first_window], dx  ; first_window = window
    
.done:
    pop dx
    pop cx
    pop bx
    pop bp
    ret

; Начать перетаскивание окна
; Вход: ax = id окна
wm_start_window_drag:
    push ax
    
    mov [dragging_window], ax
    
    ; Сохраняем начальную позицию мыши
    call mouse_get_position
    mov [drag_start_x], ax
    mov [drag_start_y], bx
    
    ; Сохраняем начальную позицию окна
    push ax
    call find_window
    mov bx, [ax + 2]    ; window_x
    mov cx, [ax + 4]    ; window_y
    mov [window_start_x], bx
    mov [window_start_y], cx
    pop ax
    
    pop ax
    ret

; Обновить позицию перетаскиваемого окна
; Вход: bx = новый x, cx = новый y
wm_update_window_position:
    push ax
    push bx
    push cx
    
    ; Проверяем, есть ли перетаскиваемое окно
    mov ax, [dragging_window]
    test ax, ax
    jz .done
    
    ; Находим окно
    call find_window
    test ax, ax
    jz .done
    
    ; Обновляем позицию
    mov [ax + 2], bx    ; x
    mov [ax + 4], cx    ; y
    
    ; Перерисовываем все окна
    call wm_draw_all
    
.done:
    pop cx
    pop bx
    pop ax
    ret

section .data
    window_count dw 0        ; Количество окон
    first_window dw 0        ; Указатель на первое окно
    active_window dw 0       ; ID активного окна
    dragging_window dw 0     ; ID перетаскиваемого окна
    drag_start_x dw 0        ; Начальная x позиция мыши при перетаскивании
    drag_start_y dw 0        ; Начальная y позиция мыши при перетаскивании
    window_start_x dw 0      ; Начальная x позиция окна при перетаскивании
    window_start_y dw 0      ; Начальная y позиция окна при перетаскивании

section .bss
    windows resb MAX_WINDOWS * WINDOW_SIZE  ; Буфер для хранения окон
