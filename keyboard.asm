[bits 16]

; Драйвер клавиатуры
keyboard_init:
    ; Инициализация буфера клавиатуры
    mov word [kb_buffer_start], 0
    mov word [kb_buffer_end], 0
    
    ; Установка обработчика прерывания
    cli
    mov ax, 0
    mov es, ax
    mov word [es:0x24], keyboard_handler
    mov word [es:0x26], cs
    sti
    ret

; Обработчик прерывания клавиатуры
keyboard_handler:
    pusha
    
    ; Чтение скан-кода
    in al, 0x60
    
    ; Сохранение в буфер
    mov di, [kb_buffer_end]
    mov [kb_buffer + di], al
    inc di
    and di, 0x0F      ; Циклический буфер на 16 байт
    mov [kb_buffer_end], di
    
    ; Отправка EOI
    mov al, 0x20
    out 0x20, al
    
    popa
    iret

; Чтение символа из буфера
keyboard_read:
    mov di, [kb_buffer_start]
    cmp di, [kb_buffer_end]
    je .no_key
    
    mov al, [kb_buffer + di]
    inc di
    and di, 0x0F
    mov [kb_buffer_start], di
    ret
    
.no_key:
    xor al, al
    ret

; Данные
kb_buffer times 16 db 0   ; Буфер клавиатуры
kb_buffer_start dw 0      ; Начало буфера
kb_buffer_end dw 0        ; Конец буфера
