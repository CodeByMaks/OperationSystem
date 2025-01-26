[bits 16]
[org 0x2000]  ; Смещение модуля desktop

%include "config.inc"

; Смещения внешних функций
graphics_offset    equ 0x4000
mouse_driver_offset equ 0x5000

draw_rectangle     equ graphics_offset + 0x0000
draw_text         equ graphics_offset + 0x0100
draw_icon         equ graphics_offset + 0x0200

mouse_get_position equ mouse_driver_offset + 0x0300

section .text
    global init_desktop
    global draw_desktop_icons
    global handle_desktop_click

; Инициализация рабочего стола
init_desktop:
    push bp
    mov bp, sp
    
    ; Очистка экрана синим цветом
    mov ax, 0
    mov bx, 0
    mov cx, SCREEN_WIDTH
    mov dx, SCREEN_HEIGHT
    mov si, DESKTOP_COLOR
    call far [cs:draw_rectangle_far]
    
    ; Инициализация иконок
    mov word [icon_count], DEFAULT_ICON_COUNT
    
    pop bp
    ret

; Отрисовка иконок рабочего стола
draw_desktop_icons:
    push bp
    mov bp, sp
    
    mov cx, 0          ; Счетчик иконок
    
.draw_loop:
    cmp cx, [icon_count]
    jge .done
    
    push cx
    
    ; Вычисление позиции иконки
    mov ax, cx
    mov bx, ICON_SPACING_Y
    mul bx
    add ax, ICON_START_Y
    push ax            ; y позиция
    
    mov ax, ICON_START_X
    push ax            ; x позиция
    
    ; Получение указателя на имя иконки
    mov bx, cx
    shl bx, 1         ; умножаем на 2 для получения смещения в таблице
    mov si, [icon_names + bx]
    
    ; Отрисовка иконки
    call far [cs:draw_icon_far]
    
    ; Отрисовка текста под иконкой
    mov ax, [bp-2]    ; y позиция
    add ax, ICON_SIZE
    push ax
    mov ax, [bp-4]    ; x позиция
    push ax
    push si           ; текст
    mov ax, ICON_TEXT_COLOR
    push ax
    call far [cs:draw_text_far]
    
    pop cx
    inc cx
    jmp .draw_loop
    
.done:
    pop bp
    ret

; Обработка клика по рабочему столу
handle_desktop_click:
    push bp
    mov bp, sp
    
    call far [cs:mouse_get_position_far]
    
    ; Проверка попадания в иконку
    mov cx, 0          ; Счетчик иконок
    
.check_loop:
    cmp cx, [icon_count]
    jge .no_hit
    
    ; Вычисление границ иконки
    mov bx, cx
    mov ax, bx
    mov dx, ICON_SPACING_Y
    mul dx
    add ax, ICON_START_Y    ; y1
    push ax
    
    add ax, ICON_SIZE       ; y2
    push ax
    
    mov ax, ICON_START_X    ; x1
    push ax
    
    add ax, ICON_SIZE       ; x2
    push ax
    
    ; Проверка попадания
    mov ax, [mouse_x]
    cmp ax, [bp-8]         ; x2
    jg .next_icon
    
    cmp ax, [bp-6]         ; x1
    jl .next_icon
    
    mov ax, [mouse_y]
    cmp ax, [bp-4]         ; y2
    jg .next_icon
    
    cmp ax, [bp-2]         ; y1
    jl .next_icon
    
    ; Попадание найдено
    mov ax, cx
    jmp .done
    
.next_icon:
    inc cx
    jmp .check_loop
    
.no_hit:
    mov ax, -1
    
.done:
    pop bp
    ret

section .data
    icon_count dw 0
    icon_names dw icon_name1, icon_name2, icon_name3, icon_name4
    icon_name1 db 'My Computer', 0
    icon_name2 db 'Documents', 0
    icon_name3 db 'Terminal', 0
    icon_name4 db 'Settings', 0
    
    DEFAULT_ICON_COUNT equ 4
    ICON_SIZE equ 32
    ICON_START_X equ 20
    ICON_START_Y equ 20
    ICON_SPACING_Y equ 64
    ICON_TEXT_COLOR equ 0x0F
    DESKTOP_COLOR equ 0x01

    ; Таблица дальних вызовов
    draw_rectangle_far dd draw_rectangle
    draw_text_far dd draw_text
    draw_icon_far dd draw_icon
    mouse_get_position_far dd mouse_get_position

section .bss
    mouse_x resd 1  ; Позиция мыши X
    mouse_y resd 1  ; Позиция мыши Y
