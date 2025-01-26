[bits 16]

section .text
    global mouse_init
    global mouse_handler
    global mouse_get_position
    global mouse_get_buttons

; Инициализация мыши
mouse_init:
    push ax
    push es
    
    ; Установка обработчика прерывания мыши (INT 33h)
    mov ax, 0
    int 33h
    
    ; Проверка наличия мыши
    test ax, ax
    jz .no_mouse
    
    ; Показать курсор мыши
    mov ax, 1
    int 33h
    
    ; Установка границ курсора
    mov ax, 7       ; Функция установки горизонтальных границ
    xor cx, cx      ; Минимальная X координата
    mov dx, [screen_width]
    dec dx          ; Максимальная X координата
    int 33h
    
    mov ax, 8       ; Функция установки вертикальных границ
    xor cx, cx      ; Минимальная Y координата
    mov dx, [screen_height]
    dec dx          ; Максимальная Y координата
    int 33h
    
.no_mouse:
    pop es
    pop ax
    ret

; Получение позиции мыши
; Выход: CX = X координата, DX = Y координата
mouse_get_position:
    push ax
    push bx
    
    mov ax, 3       ; Функция получения позиции
    int 33h
    
    shr cx, 1       ; Преобразуем микки в пиксели
    
    pop bx
    pop ax
    ret

; Получение состояния кнопок мыши
; Выход: BX = состояние кнопок (bit 0 = левая, bit 1 = правая)
mouse_get_buttons:
    push ax
    push cx
    push dx
    
    mov ax, 3       ; Функция получения состояния
    int 33h
    
    pop dx
    pop cx
    pop ax
    ret

section .data
    screen_width  dw 320    ; Ширина экрана
    screen_height dw 200    ; Высота экрана

section .bss
    mouse_x resw 1         ; Текущая X координата мыши
    mouse_y resw 1         ; Текущая Y координата мыши
    mouse_buttons resb 1   ; Состояние кнопок мыши
