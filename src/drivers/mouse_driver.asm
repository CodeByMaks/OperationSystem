[bits 16]
[org 0x5000]  ; Смещение модуля mouse_driver

%include "config.inc"

; Смещения внешних функций
graphics_offset    equ 0x4000

draw_rectangle     equ graphics_offset + 0x0000

section .text
    global init_mouse
    global update_mouse
    global draw_cursor
    global mouse_get_position
    global mouse_get_status

; Инициализация мыши
init_mouse:
    push bp
    mov bp, sp
    
    ; Сброс мыши
    mov ax, 0
    int 0x33
    
    ; Проверка наличия мыши
    test ax, ax
    jz .no_mouse
    
    ; Включение курсора мыши
    mov ax, 1
    int 0x33
    
    ; Установка начальных координат
    mov word [mouse_x], SCREEN_WIDTH / 2
    mov word [mouse_y], SCREEN_HEIGHT / 2
    mov byte [mouse_buttons], 0
    
    mov ax, 1    ; Успех
    jmp .done
    
.no_mouse:
    mov ax, 0    ; Ошибка
    
.done:
    pop bp
    ret

; Обновление состояния мыши
update_mouse:
    push bp
    mov bp, sp
    
    ; Получение состояния мыши
    mov ax, 3
    int 0x33
    
    ; Сохранение состояния кнопок
    mov [mouse_buttons], bl
    
    ; Преобразование координат (CX = X, DX = Y)
    shr cx, 1    ; Делим X на 2 (из-за режима 320x200)
    mov [mouse_x], cx
    mov [mouse_y], dx
    
    pop bp
    ret

; Отрисовка курсора мыши
draw_cursor:
    push bp
    mov bp, sp
    
    ; Сохранение регистров
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Отрисовка курсора (простой прямоугольник)
    mov ax, [mouse_x]
    mov dx, [mouse_y]
    mov si, CURSOR_WIDTH
    mov di, CURSOR_HEIGHT
    mov bx, CURSOR_COLOR
    call far [cs:draw_rectangle_far]
    
    ; Восстановление регистров
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    
    pop bp
    ret

; Получение позиции мыши
; Выход: ax = x, dx = y
mouse_get_position:
    mov ax, [mouse_x]
    mov dx, [mouse_y]
    ret

; Получение состояния мыши
; Выход: ax = x, dx = y, cl = кнопки
mouse_get_status:
    mov ax, [mouse_x]
    mov dx, [mouse_y]
    mov cl, [mouse_buttons]
    ret

section .data
    CURSOR_WIDTH equ 8
    CURSOR_HEIGHT equ 12
    CURSOR_COLOR equ 0x0F    ; Белый цвет
    
    ; Таблица дальних вызовов
    draw_rectangle_far dd draw_rectangle

section .bss
    mouse_x resw 1       ; Позиция X
    mouse_y resw 1       ; Позиция Y
    mouse_buttons resb 1 ; Состояние кнопок
