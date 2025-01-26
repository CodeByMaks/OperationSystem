[bits 16]
[org 0x0000]

section .text
    global video_init
    global video_clear
    global video_print
    global video_set_color
    global video_get_cursor
    global video_set_cursor
    global print_string
    global clear_screen
    global set_cursor

; Инициализация видео
video_init:
    ; Установка видеорежима
    mov ah, 0x00
    mov al, 0x03    ; 80x25 текстовый режим
    int 0x10
    ret

; Очистка экрана
video_clear:
    push ax
    push bx
    push cx
    push dx
    
    mov ah, 0x06    ; Прокрутка вверх
    mov al, 0       ; Очистить весь экран
    mov bh, 0x07    ; Атрибуты (серый на черном)
    mov ch, 0       ; Верхняя строка
    mov cl, 0       ; Левый столбец
    mov dh, 24      ; Нижняя строка
    mov dl, 79      ; Правый столбец
    int 0x10
    
    ; Установка курсора в начало
    mov ah, 0x02
    mov bh, 0
    mov dh, 0
    mov dl, 0
    int 0x10
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Установка цвета текста
; AL = цвет
video_set_color:
    mov [text_color], al
    ret

; Вывод строки
; SI = указатель на строку
video_print:
    push ax
    push bx
    push si         ; Сохраняем SI
    
    mov ah, 0x0E    ; Функция телетайпа
    mov bh, 0       ; Страница 0
    mov bl, [text_color] ; Цвет текста
.loop:
    lodsb           ; Загружаем символ
    test al, al     ; Проверяем на конец строки
    jz .done
    
    ; Проверяем на специальные символы
    cmp al, 13      ; Возврат каретки
    je .cr
    cmp al, 10      ; Перевод строки
    je .lf
    
    int 0x10        ; Выводим обычный символ
    jmp .loop
    
.cr:
    mov ah, 0x0E
    int 0x10
    jmp .loop
    
.lf:
    mov ah, 0x0E
    int 0x10
    jmp .loop
    
.done:
    pop si          ; Восстанавливаем SI
    pop bx
    pop ax
    ret

; Функция вывода строки
; Вход: SI = указатель на строку с нулевым окончанием
print_string:
    push ax
    push bx
    push si
    
    mov ah, 0x0E    ; Функция телетайпа
    mov bh, 0       ; Страница 0
    mov bl, 0x07    ; Цвет текста (серый)
    
.loop:
    lodsb           ; Загружаем символ
    test al, al     ; Проверяем на конец строки
    jz .done
    int 10h         ; Выводим символ
    jmp .loop
    
.done:
    pop si
    pop bx
    pop ax
    ret

; Очистка экрана
clear_screen:
    push ax
    push bx
    push cx
    push dx
    
    mov ah, 0x06    ; Прокрутка вверх
    mov al, 0       ; Очистить весь экран
    mov bh, 0x07    ; Атрибуты (серый на черном)
    mov ch, 0       ; Верхняя строка
    mov cl, 0       ; Левый столбец
    mov dh, 24      ; Нижняя строка
    mov dl, 79      ; Правый столбец
    int 0x10
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Установка позиции курсора
; Вход: DH = строка, DL = столбец
set_cursor:
    push ax
    push bx
    
    mov ah, 0x02    ; Функция установки курсора
    mov bh, 0       ; Страница 0
    int 0x10
    
    pop bx
    pop ax
    ret

section .data
    text_color db 0x07  ; Серый на черном по умолчанию
