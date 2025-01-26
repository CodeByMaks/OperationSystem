[bits 16]

section .text

; Инициализация клавиатуры
keyboard_init:
    ; Очищаем буфер клавиатуры
    mov ah, 0x00    ; Чтение символа (очистка буфера)
    int 0x16
    ret

; Чтение символа с клавиатуры
; Возвращает: AL = ASCII код символа
keyboard_read:
    mov ah, 0x00    ; Функция чтения символа
    int 0x16        ; Вызываем BIOS
    ret

; Проверка наличия символа в буфере
; Возвращает: ZF=1 если буфер пуст
keyboard_status:
    mov ah, 0x01    ; Функция проверки буфера
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
