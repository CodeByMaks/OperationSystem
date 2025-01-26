[bits 16]
%include "config.inc"

section .text
    global show_dialog
    global close_dialog
    global handle_dialog_click
    
    extern draw_window
    extern draw_rectangle
    extern draw_text
    extern mouse_get_position
    extern wm_create_window
    extern wm_destroy_window
    extern wm_draw_all

; Структура диалога:
; - word id
; - word type
; - word result
; - byte title[32]
; - byte message[256]

; Показать диалоговое окно
; Вход: al = тип диалога, si = указатель на заголовок, di = указатель на сообщение
; Выход: ax = id диалога
show_dialog:
    push bp
    mov bp, sp
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Сохраняем параметры
    mov [dialog_type], al
    
    ; Копируем заголовок
    mov cx, 31          ; Максимальная длина - 1
    lea di, [dialog_title]
.copy_title:
    lodsb
    stosb
    test al, al
    jz .title_done
    loop .copy_title
    mov byte [di], 0    ; Завершающий нуль
.title_done:
    
    ; Копируем сообщение
    mov si, [bp + 8]    ; Указатель на сообщение
    mov cx, 255         ; Максимальная длина - 1
    lea di, [dialog_message]
.copy_message:
    lodsb
    stosb
    test al, al
    jz .message_done
    loop .copy_message
    mov byte [di], 0    ; Завершающий нуль
.message_done:
    
    ; Вычисляем размеры диалога
    mov bx, 200         ; Ширина диалога
    mov cx, 120         ; Высота диалога
    
    ; Вычисляем позицию диалога (по центру экрана)
    mov dx, SCREEN_WIDTH
    sub dx, bx
    shr dx, 1          ; dx = (screen_width - width) / 2
    
    mov di, SCREEN_HEIGHT
    sub di, TASKBAR_HEIGHT
    sub di, cx
    shr di, 1          ; di = (screen_height - taskbar_height - height) / 2
    
    ; Создаем окно диалога
    push si
    lea si, [dialog_title]
    call wm_create_window
    pop si
    
    mov [dialog_id], ax
    
    ; Рисуем содержимое диалога
    call draw_dialog_content
    
    mov ax, [dialog_id]
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop bp
    ret

; Закрыть диалоговое окно
; Вход: ax = id диалога
close_dialog:
    push ax
    
    ; Уничтожаем окно диалога
    call wm_destroy_window
    
    ; Очищаем данные диалога
    mov word [dialog_id], 0
    mov word [dialog_type], 0
    mov word [dialog_result], 0
    
    ; Перерисовываем все окна
    call wm_draw_all
    
    pop ax
    ret

; Обработка клика в диалоговом окне
; Вход: bx = x клика, cx = y клика
; Выход: ax = 1 если клик обработан, 0 если нет
handle_dialog_click:
    push bp
    mov bp, sp
    push bx
    push cx
    push dx
    
    ; Проверяем наличие активного диалога
    mov ax, [dialog_id]
    test ax, ax
    jz .not_handled
    
    ; Проверяем клик по кнопкам
    mov dx, [dialog_type]
    
    cmp dx, DIALOG_OK
    je .check_ok
    
    cmp dx, DIALOG_OK_CANCEL
    je .check_ok_cancel
    
    cmp dx, DIALOG_YES_NO
    je .check_yes_no
    
    cmp dx, DIALOG_YES_NO_CANCEL
    je .check_yes_no_cancel
    
    jmp .not_handled
    
.check_ok:
    call is_click_on_ok
    test ax, ax
    jz .not_handled
    
    mov word [dialog_result], 1
    mov ax, [dialog_id]
    call close_dialog
    mov ax, 1
    jmp .done
    
.check_ok_cancel:
    call is_click_on_ok
    test ax, ax
    jz .check_cancel1
    
    mov word [dialog_result], 1
    mov ax, [dialog_id]
    call close_dialog
    mov ax, 1
    jmp .done
    
.check_cancel1:
    call is_click_on_cancel
    test ax, ax
    jz .not_handled
    
    mov word [dialog_result], 0
    mov ax, [dialog_id]
    call close_dialog
    mov ax, 1
    jmp .done
    
.check_yes_no:
    call is_click_on_yes
    test ax, ax
    jz .check_no1
    
    mov word [dialog_result], 1
    mov ax, [dialog_id]
    call close_dialog
    mov ax, 1
    jmp .done
    
.check_no1:
    call is_click_on_no
    test ax, ax
    jz .not_handled
    
    mov word [dialog_result], 0
    mov ax, [dialog_id]
    call close_dialog
    mov ax, 1
    jmp .done
    
.check_yes_no_cancel:
    call is_click_on_yes
    test ax, ax
    jz .check_no2
    
    mov word [dialog_result], 1
    mov ax, [dialog_id]
    call close_dialog
    mov ax, 1
    jmp .done
    
.check_no2:
    call is_click_on_no
    test ax, ax
    jz .check_cancel2
    
    mov word [dialog_result], 0
    mov ax, [dialog_id]
    call close_dialog
    mov ax, 1
    jmp .done
    
.check_cancel2:
    call is_click_on_cancel
    test ax, ax
    jz .not_handled
    
    mov word [dialog_result], -1
    mov ax, [dialog_id]
    call close_dialog
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

; Рисование содержимого диалога
draw_dialog_content:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Получаем параметры окна диалога
    mov ax, [dialog_id]
    call get_window_rect
    
    ; Рисуем фон диалога
    mov al, COLOR_LGRAY
    call draw_rectangle
    
    ; Рисуем сообщение
    add bx, 10          ; Отступ слева
    add cx, 30          ; Отступ сверху
    lea si, [dialog_message]
    mov al, COLOR_BLACK
    call draw_text
    
    ; Рисуем кнопки в зависимости от типа диалога
    mov ax, [dialog_type]
    
    cmp ax, DIALOG_OK
    je .draw_ok
    
    cmp ax, DIALOG_OK_CANCEL
    je .draw_ok_cancel
    
    cmp ax, DIALOG_YES_NO
    je .draw_yes_no
    
    cmp ax, DIALOG_YES_NO_CANCEL
    je .draw_yes_no_cancel
    
    jmp .done
    
.draw_ok:
    call draw_ok_button
    jmp .done
    
.draw_ok_cancel:
    call draw_ok_button
    call draw_cancel_button
    jmp .done
    
.draw_yes_no:
    call draw_yes_button
    call draw_no_button
    jmp .done
    
.draw_yes_no_cancel:
    call draw_yes_button
    call draw_no_button
    call draw_cancel_button
    
.done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret

; Рисование кнопки OK
draw_ok_button:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    
    ; Вычисляем позицию кнопки
    mov bx, [window_width]
    sub bx, 80          ; Ширина кнопки
    shr bx, 1          ; Центрируем по горизонтали
    
    mov cx, [window_height]
    sub cx, 40          ; Отступ снизу
    
    ; Рисуем кнопку
    mov dx, 60          ; Ширина кнопки
    mov di, 25          ; Высота кнопки
    mov al, COLOR_LGRAY
    call draw_button
    
    ; Рисуем текст кнопки
    add bx, 20          ; Центрируем текст
    add cx, 8
    lea si, [ok_text]
    mov al, COLOR_BLACK
    call draw_text
    
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret

; Рисование кнопки Cancel
draw_cancel_button:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    
    ; Вычисляем позицию кнопки
    mov bx, [window_width]
    sub bx, 80          ; Ширина кнопки
    mov cx, [window_height]
    sub cx, 40          ; Отступ снизу
    
    ; Рисуем кнопку
    mov dx, 60          ; Ширина кнопки
    mov di, 25          ; Высота кнопки
    mov al, COLOR_LGRAY
    call draw_button
    
    ; Рисуем текст кнопки
    add bx, 12          ; Центрируем текст
    add cx, 8
    lea si, [cancel_text]
    mov al, COLOR_BLACK
    call draw_text
    
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret

; Рисование кнопки Yes
draw_yes_button:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    
    ; Вычисляем позицию кнопки
    mov bx, [window_width]
    sub bx, 140         ; Отступ от правого края
    mov cx, [window_height]
    sub cx, 40          ; Отступ снизу
    
    ; Рисуем кнопку
    mov dx, 60          ; Ширина кнопки
    mov di, 25          ; Высота кнопки
    mov al, COLOR_LGRAY
    call draw_button
    
    ; Рисуем текст кнопки
    add bx, 20          ; Центрируем текст
    add cx, 8
    lea si, [yes_text]
    mov al, COLOR_BLACK
    call draw_text
    
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret

; Рисование кнопки No
draw_no_button:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    
    ; Вычисляем позицию кнопки
    mov bx, [window_width]
    sub bx, 80          ; Отступ от правого края
    mov cx, [window_height]
    sub cx, 40          ; Отступ снизу
    
    ; Рисуем кнопку
    mov dx, 60          ; Ширина кнопки
    mov di, 25          ; Высота кнопки
    mov al, COLOR_LGRAY
    call draw_button
    
    ; Рисуем текст кнопки
    add bx, 22          ; Центрируем текст
    add cx, 8
    lea si, [no_text]
    mov al, COLOR_BLACK
    call draw_text
    
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret

; Проверка клика по кнопке OK
; Вход: bx = x клика, cx = y клика
; Выход: ax = 1 если клик по кнопке, 0 если нет
is_click_on_ok:
    push bp
    mov bp, sp
    push dx
    
    mov dx, [window_width]
    sub dx, 80          ; Ширина кнопки
    shr dx, 1          ; Центрируем по горизонтали
    
    call is_click_on_button
    
    pop dx
    pop bp
    ret

; Проверка клика по кнопке Cancel
; Вход: bx = x клика, cx = y клика
; Выход: ax = 1 если клик по кнопке, 0 если нет
is_click_on_cancel:
    push bp
    mov bp, sp
    push dx
    
    mov dx, [window_width]
    sub dx, 80          ; Ширина кнопки
    
    call is_click_on_button
    
    pop dx
    pop bp
    ret

; Проверка клика по кнопке Yes
; Вход: bx = x клика, cx = y клика
; Выход: ax = 1 если клик по кнопке, 0 если нет
is_click_on_yes:
    push bp
    mov bp, sp
    push dx
    
    mov dx, [window_width]
    sub dx, 140         ; Отступ от правого края
    
    call is_click_on_button
    
    pop dx
    pop bp
    ret

; Проверка клика по кнопке No
; Вход: bx = x клика, cx = y клика
; Выход: ax = 1 если клик по кнопке, 0 если нет
is_click_on_no:
    push bp
    mov bp, sp
    push dx
    
    mov dx, [window_width]
    sub dx, 80          ; Отступ от правого края
    
    call is_click_on_button
    
    pop dx
    pop bp
    ret

; Проверка клика по кнопке
; Вход: bx = x клика, cx = y клика, dx = x кнопки
; Выход: ax = 1 если клик по кнопке, 0 если нет
is_click_on_button:
    push bp
    mov bp, sp
    
    ; Проверяем x координату
    cmp bx, dx
    jl .not_on_button
    add dx, 60          ; Ширина кнопки
    cmp bx, dx
    jg .not_on_button
    
    ; Проверяем y координату
    mov dx, [window_height]
    sub dx, 40          ; Отступ снизу
    cmp cx, dx
    jl .not_on_button
    add dx, 25          ; Высота кнопки
    cmp cx, dx
    jg .not_on_button
    
    mov ax, 1
    jmp .done
    
.not_on_button:
    xor ax, ax
    
.done:
    pop bp
    ret

section .data
    ok_text db "OK", 0
    cancel_text db "Cancel", 0
    yes_text db "Yes", 0
    no_text db "No", 0

section .bss
    dialog_id resw 1         ; ID диалогового окна
    dialog_type resw 1       ; Тип диалога
    dialog_result resw 1     ; Результат диалога
    dialog_title resb 32     ; Заголовок диалога
    dialog_message resb 256  ; Сообщение диалога
