[bits 16]
[org 0x3000]  ; Смещение модуля window_system

%include "config.inc"

; Структура Window
struc Window
    .x:      resw 1    ; Позиция X
    .y:      resw 1    ; Позиция Y
    .width:  resw 1    ; Ширина
    .height: resw 1    ; Высота
    .state:  resb 1    ; Состояние окна
    .title:  resb 32   ; Заголовок окна
endstruc

; Состояния окна
WINDOW_STATE_NORMAL    equ 0
WINDOW_STATE_MINIMIZED equ 1
WINDOW_STATE_MAXIMIZED equ 2

; Смещения внешних функций
graphics_offset    equ 0x4000
mouse_driver_offset equ 0x5000

draw_rectangle     equ graphics_offset + 0x0000
draw_text         equ graphics_offset + 0x0100
draw_line         equ graphics_offset + 0x0300

mouse_get_status  equ mouse_driver_offset + 0x0400

section .text
    global init_window_system
    global create_window
    global destroy_window
    global draw_windows
    global handle_window_event

; Инициализация оконной системы
init_window_system:
    push bp
    mov bp, sp
    
    mov word [window_count], 0
    mov byte [active_window], -1
    
    pop bp
    ret

; Создание нового окна
; Вход: ax = x, dx = y, cx = width, si = height, di = заголовок
create_window:
    push bp
    mov bp, sp
    push di      ; Сохраняем указатель на заголовок
    
    ; Проверка на максимальное количество окон
    cmp word [window_count], MAX_WINDOWS
    jge .error
    
    ; Получение индекса нового окна
    mov di, [window_count]
    
    ; Сохранение параметров окна
    mov bx, di
    imul bx, Window_size
    
    mov [windows + bx + Window.x], ax
    mov [windows + bx + Window.y], dx
    mov [windows + bx + Window.width], cx
    mov [windows + bx + Window.height], si
    mov byte [windows + bx + Window.state], WINDOW_STATE_NORMAL
    
    ; Копирование заголовка
    mov cx, MAX_TITLE_LENGTH
    lea di, [windows + bx + Window.title]
    pop si      ; Восстанавливаем указатель на заголовок
    rep movsb
    
    ; Увеличение счетчика окон
    inc word [window_count]
    
    ; Возврат индекса окна
    mov ax, [window_count]
    dec ax
    jmp .done
    
.error:
    mov ax, -1
    
.done:
    pop bp
    ret

; Отрисовка всех окон
draw_windows:
    push bp
    mov bp, sp
    
    mov cx, 0  ; Счетчик окон
    
.draw_loop:
    cmp cx, [window_count]
    jge .done
    
    push cx
    
    ; Получение указателя на структуру окна
    mov bx, cx
    imul bx, Window_size
    add bx, windows
    
    ; Отрисовка рамки окна
    mov ax, [bx + Window.x]
    mov dx, [bx + Window.y]
    mov si, [bx + Window.width]
    mov di, [bx + Window.height]
    
    push ax  ; x
    push dx  ; y
    push si  ; width
    push di  ; height
    mov ax, WINDOW_BORDER_COLOR
    push ax
    call far [cs:draw_rectangle_far]
    
    ; Отрисовка заголовка
    mov ax, [bx + Window.x]
    add ax, 5
    push ax  ; x
    mov dx, [bx + Window.y]
    add dx, 5
    push dx  ; y
    lea si, [bx + Window.title]
    push si  ; текст
    mov ax, WINDOW_TITLE_COLOR
    push ax
    call far [cs:draw_text_far]
    
    ; Отрисовка кнопок управления
    call draw_window_controls
    
    pop cx
    inc cx
    jmp .draw_loop
    
.done:
    pop bp
    ret

; Обработка событий окна
handle_window_event:
    push bp
    mov bp, sp
    
    call far [cs:mouse_get_status_far]
    
    ; Проверка на клик
    test cl, 1
    jz .done
    
    ; Поиск окна под курсором
    mov cx, [window_count]
    dec cx
    
.check_loop:
    cmp cx, -1
    je .done
    
    ; Получение указателя на структуру окна
    mov bx, cx
    imul bx, Window_size
    add bx, windows
    
    ; Проверка попадания в окно
    mov dx, [bx + Window.x]
    mov ax, [mouse_x]
    cmp ax, dx
    jl .next_window
    
    add dx, [bx + Window.width]
    cmp ax, dx
    jg .next_window
    
    mov dx, [bx + Window.y]
    mov ax, [mouse_y]
    cmp ax, dx
    jl .next_window
    
    add dx, [bx + Window.height]
    cmp ax, dx
    jg .next_window
    
    ; Окно найдено
    mov [active_window], cl
    call handle_window_controls
    jmp .done
    
.next_window:
    dec cx
    jmp .check_loop
    
.done:
    pop bp
    ret

; Вспомогательные функции
draw_window_controls:
    ret

handle_window_controls:
    ret

section .data
    MAX_WINDOWS equ 10
    MAX_TITLE_LENGTH equ 32
    WINDOW_BORDER_COLOR equ 0x07
    WINDOW_TITLE_COLOR equ 0x0F

    ; Таблица дальних вызовов
    draw_rectangle_far dd draw_rectangle
    draw_text_far dd draw_text
    draw_line_far dd draw_line
    mouse_get_status_far dd mouse_get_status

section .bss
    windows resb Window_size * MAX_WINDOWS
    window_count resw 1
    active_window resb 1
    mouse_x resd 1
    mouse_y resd 1
