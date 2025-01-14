[bits 16]
[org 0x0000]      ; Загружаемся в сегмент 0x1000

; Точка входа в ядро
start:
    ; Настраиваем сегменты
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0xFFFE

    ; Очищаем экран
    mov ax, 0x0003    ; Текстовый режим 80x25
    int 0x10

    ; Показываем приветствие
    mov si, kernel_msg
    call print_string

    ; Показываем меню
    call show_menu

main_loop:
    ; Ждем нажатия клавиши
    mov ah, 0
    int 0x16        ; Ждем нажатие клавиши

    ; Проверяем нажатую клавишу
    cmp al, '1'
    je .option1
    cmp al, '2'
    je .option2
    cmp al, '3'
    je .option3
    cmp al, 27      ; ESC
    je shutdown
    jmp main_loop

.option1:
    mov si, msg_option1
    call print_string
    jmp main_loop

.option2:
    mov si, msg_option2
    call print_string
    jmp main_loop

.option3:
    mov si, msg_option3
    call print_string
    jmp main_loop

; Выключение системы
shutdown:
    mov si, msg_shutdown
    call print_string
    cli             ; Отключаем прерывания
    hlt            ; Останавливаем процессор

; Показать меню
show_menu:
    mov si, menu_msg
    call print_string
    ret

; Процедура вывода строки
print_string:
    mov ah, 0x0E
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    ret

; Данные
kernel_msg db 'Kernel started successfully!', 13, 10, 0
menu_msg db 13, 10, 'Menu:', 13, 10
         db '1. Hello World', 13, 10
         db '2. Show Time', 13, 10
         db '3. Clear Screen', 13, 10
         db 'ESC to shutdown', 13, 10, 0
msg_option1 db 'Hello, World!', 13, 10, 0
msg_option2 db 'Current time feature coming soon...', 13, 10, 0
msg_option3 db 'Clearing screen...', 13, 10, 0
msg_shutdown db 'Shutting down...', 13, 10, 0

; Заполняем нулями до конца сектора
times 512-($-$$) db 0
