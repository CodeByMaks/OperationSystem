[bits 16]

section .text

; Инициализация видео
video_init:
    ; Установка видеорежима (80x25, цветной текст)
    mov ah, 0x00
    mov al, 0x03
    int 0x10
    
    ; Установка курсора
    mov ah, 0x02
    xor bh, bh
    xor dx, dx
    int 0x10
    
    ; Установка атрибутов по умолчанию
    mov byte [video_color], 0x07
    ret

; Очистка экрана
video_clear:
    push es
    push ax
    push cx
    push di
    
    ; Устанавливаем ES:DI на начало видеопамяти
    mov ax, 0xB800
    mov es, ax
    xor di, di
    
    ; Заполняем экран пробелами
    mov ax, 0x0720  ; Пробел с атрибутом 7 (серый на черном)
    mov cx, 2000    ; 80*25 символов
    rep stosw
    
    ; Возвращаем курсор в начало
    mov ah, 0x02
    xor bh, bh
    xor dx, dx
    int 0x10
    
    pop di
    pop cx
    pop ax
    pop es
    ret

; Вывод строки
; SI = указатель на строку (null-terminated)
video_print:
    push ax
    push bx
    
    mov ah, 0x0E    ; Функция телетайпа
    mov bh, 0       ; Страница 0
    mov bl, [video_color]
.loop:
    lodsb           ; Загружаем символ в AL
    test al, al     ; Проверяем на конец строки
    jz .done
    int 0x10        ; Выводим символ
    jmp .loop
.done:
    pop bx
    pop ax
    ret

; Установка цвета текста
; AL = цвет (старший полубайт - фон, младший - текст)
video_set_color:
    mov [video_color], al
    ret

section .data
    video_color db 0x07  ; Текущий цвет (по умолчанию серый на черном)
