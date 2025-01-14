[bits 16]

; Драйвер видео
video_init:
    ; Установка видеорежима
    mov ax, 0x0003    ; 80x25 текстовый режим
    int 0x10
    
    ; Очистка экрана
    call video_clear
    ret

; Очистка экрана
video_clear:
    mov ax, 0x0600    ; Прокрутка вверх (очистка)
    mov bh, 0x07      ; Атрибуты (серый на черном)
    xor cx, cx        ; Верхний левый угол (0,0)
    mov dx, 0x184F    ; Нижний правый угол (24,79)
    int 0x10
    ret

; Установка курсора
video_set_cursor:
    mov ah, 0x02      ; Функция установки курсора
    mov bh, 0         ; Страница 0
    int 0x10
    ret

; Вывод символа
video_putchar:
    mov ah, 0x0E      ; Функция телетайпа
    int 0x10
    ret

; Вывод строки
video_print:
    mov ah, 0x0E
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    ret

; Вывод строки с атрибутами
video_print_attr:
    mov ah, 0x09      ; Функция вывода с атрибутами
    mov bh, 0         ; Страница 0
    mov cx, 1         ; Один символ
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    inc dl            ; Следующая позиция
    call video_set_cursor
    jmp .loop
.done:
    ret

; Прокрутка экрана
video_scroll:
    mov ah, 0x06      ; Прокрутка вверх
    mov al, 1         ; На одну строку
    mov bh, 0x07      ; Атрибуты
    mov cx, 0x0000    ; Верхний левый угол
    mov dx, 0x184F    ; Нижний правый угол
    int 0x10
    ret
