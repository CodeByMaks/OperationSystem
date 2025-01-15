[bits 16]

section .text

; Инициализация клавиатуры
keyboard_init:
    ; Инициализация клавиатуры
    mov ah, 0x00
    int 0x16      ; Сброс буфера клавиатуры
    ret

; Чтение символа с клавиатуры
; Возвращает: AL = ASCII код символа
keyboard_read:
    xor ax, ax      ; AH = 0 - чтение символа с ожиданием
    int 0x16        ; Вызываем BIOS
    ret

section .data
    kb_status db 0   ; Статус клавиатуры (Shift, Ctrl, Alt)

section .bss align=2
    ; Буфер клавиатуры
    KB_BUFFER_SIZE equ 32
    KB_BUFFER_MASK equ KB_BUFFER_SIZE-1
    kb_buffer resb KB_BUFFER_SIZE
    kb_buffer_start resw 1
    kb_buffer_end resw 1
