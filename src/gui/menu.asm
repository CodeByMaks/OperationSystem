[bits 16]
%include "config.inc"

section .text
    global menu_init
    global menu_show
    global menu_hide
    global menu_handle_click
    global show_context_menu
    global show_main_menu
    
    extern draw_rectangle
    extern draw_text
    extern mouse_get_position
    extern mouse_get_buttons

; Структура элемента меню:
; - word x
; - word y
; - word width
; - word height
; - byte active
; - byte reserved
; - word parent_id
; - word next_id
; - word submenu_id
; - byte text_length
; - byte text[32]

MENU_ITEM_SIZE equ 48

; Инициализация системы меню
menu_init:
    push ax
    push bx
    
    ; Очищаем список меню
    mov word [active_menu], 0
    mov word [menu_count], 0
    
    ; Создаем главное меню
    mov ax, MENU_MAIN
    call create_main_menu
    
    ; Создаем контекстное меню
    mov ax, MENU_CONTEXT
    call create_context_menu
    
    pop bx
    pop ax
    ret

; Показать меню
; Вход: ax = id меню, bx = x, cx = y
menu_show:
    push bp
    mov bp, sp
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Сохраняем параметры
    mov [menu_x], bx
    mov [menu_y], cx
    mov [active_menu], ax
    
    ; Находим меню по id
    call find_menu
    mov si, ax          ; si = указатель на меню
    
    ; Рисуем фон меню
    mov bx, [menu_x]
    mov cx, [menu_y]
    mov dx, [si + 4]    ; width
    mov di, [si + 6]    ; height
    mov al, COLOR_LGRAY
    call draw_rectangle
    
    ; Рисуем рамку
    mov al, COLOR_BLACK
    dec bx
    dec cx
    add dx, 2
    add di, 2
    call draw_rectangle
    
    ; Рисуем элементы меню
    mov si, [si + 12]   ; first_item
    
.draw_items:
    test si, si
    jz .done
    
    ; Рисуем элемент меню
    push si
    call draw_menu_item
    add sp, 2
    
    ; Следующий элемент
    mov si, [si + 10]   ; next_item
    jmp .draw_items
    
.done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop bp
    ret

; Скрыть меню
menu_hide:
    push ax
    
    mov word [active_menu], 0
    
    ; Перерисовываем область под меню
    ; TODO: Реализовать восстановление фона
    
    pop ax
    ret

; Обработка клика по меню
; Вход: bx = x, cx = y
; Выход: ax = 1 если клик обработан, 0 если нет
menu_handle_click:
    push bp
    mov bp, sp
    push bx
    push cx
    push dx
    push si
    
    ; Проверяем, есть ли активное меню
    mov ax, [active_menu]
    test ax, ax
    jz .not_handled
    
    ; Находим меню по id
    call find_menu
    mov si, ax
    
    ; Проверяем, попал ли клик в область меню
    mov dx, [menu_x]
    cmp bx, dx
    jl .not_handled
    add dx, [si + 4]    ; width
    cmp bx, dx
    jg .not_handled
    
    mov dx, [menu_y]
    cmp cx, dx
    jl .not_handled
    add dx, [si + 6]    ; height
    cmp cx, dx
    jg .not_handled
    
    ; Находим элемент меню, по которому был клик
    mov si, [si + 12]   ; first_item
    
.check_items:
    test si, si
    jz .not_handled
    
    ; Проверяем координаты элемента
    mov dx, [si]        ; item_x
    cmp bx, dx
    jl .next_item
    add dx, [si + 4]    ; width
    cmp bx, dx
    jg .next_item
    
    mov dx, [si + 2]    ; item_y
    cmp cx, dx
    jl .next_item
    add dx, [si + 6]    ; height
    cmp cx, dx
    jg .next_item
    
    ; Клик по элементу меню
    push si
    call handle_menu_item_click
    add sp, 2
    
    mov ax, 1
    jmp .done
    
.next_item:
    mov si, [si + 10]   ; next_item
    jmp .check_items
    
.not_handled:
    xor ax, ax
    
.done:
    pop si
    pop dx
    pop cx
    pop bx
    pop bp
    ret

; Показать контекстное меню
; Вход: bx = x, cx = y
show_context_menu:
    push ax
    
    ; Скрываем текущее меню, если есть
    call menu_hide
    
    ; Показываем контекстное меню
    mov ax, MENU_CONTEXT
    call menu_show
    
    pop ax
    ret

; Показать главное меню
show_main_menu:
    push ax
    push bx
    push cx
    
    ; Скрываем текущее меню, если есть
    call menu_hide
    
    ; Вычисляем позицию главного меню
    xor bx, bx          ; x = 0
    mov cx, SCREEN_HEIGHT
    sub cx, TASKBAR_HEIGHT  ; y = screen_height - taskbar_height
    
    ; Показываем главное меню
    mov ax, MENU_MAIN
    call menu_show
    
    pop cx
    pop bx
    pop ax
    ret

; Создание главного меню
; Вход: ax = id меню
create_main_menu:
    push bp
    mov bp, sp
    push bx
    push cx
    push dx
    push si
    
    ; Создаем меню
    call create_menu
    mov si, ax
    
    ; Добавляем пункты меню
    mov bx, main_menu_items
    
.add_items:
    mov cl, [bx]        ; Длина текста
    test cl, cl
    jz .done
    
    ; Добавляем пункт меню
    push word [bx + 1]  ; submenu_id
    push bx             ; text
    push cx             ; text_length
    push si             ; menu
    call add_menu_item
    add sp, 8
    
    ; Следующий пункт
    add bx, 4
    add bx, cx
    jmp .add_items
    
.done:
    pop si
    pop dx
    pop cx
    pop bx
    pop bp
    ret

; Создание контекстного меню
; Вход: ax = id меню
create_context_menu:
    push bp
    mov bp, sp
    push bx
    push cx
    push dx
    push si
    
    ; Создаем меню
    call create_menu
    mov si, ax
    
    ; Добавляем пункты меню
    mov bx, context_menu_items
    
.add_items:
    mov cl, [bx]        ; Длина текста
    test cl, cl
    jz .done
    
    ; Добавляем пункт меню
    push word [bx + 1]  ; submenu_id
    push bx             ; text
    push cx             ; text_length
    push si             ; menu
    call add_menu_item
    add sp, 8
    
    ; Следующий пункт
    add bx, 4
    add bx, cx
    jmp .add_items
    
.done:
    pop si
    pop dx
    pop cx
    pop bx
    pop bp
    ret

section .data
    ; Константы для идентификаторов меню
    MENU_MAIN       equ 1
    MENU_CONTEXT    equ 2
    MENU_FILE       equ 3
    MENU_EDIT       equ 4
    MENU_VIEW       equ 5
    MENU_HELP       equ 6
    
    ; Пункты главного меню
    main_menu_items:
        db 4, "File", 0, MENU_FILE
        db 4, "Edit", 0, MENU_EDIT
        db 4, "View", 0, MENU_VIEW
        db 4, "Help", 0, MENU_HELP
        db 0  ; Конец списка
        
    ; Пункты контекстного меню
    context_menu_items:
        db 4, "Copy", 0, 0
        db 5, "Paste", 0, 0
        db 6, "Delete", 0, 0
        db 0  ; Конец списка

section .bss
    active_menu resw 1     ; ID активного меню
    menu_count resw 1      ; Количество созданных меню
    menu_x resw 1          ; X координата текущего меню
    menu_y resw 1          ; Y координата текущего меню
    menus resb 1024        ; Буфер для хранения меню
    menu_items resb 2048   ; Буфер для хранения элементов меню
