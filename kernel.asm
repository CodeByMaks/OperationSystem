[bits 16]
[org 0x1000]

; Точка входа в ядро
start:
    ; Инициализация ядра
    call init_video
    call init_keyboard
    call init_timer
    
    ; Показываем приветствие
    mov si, kernel_msg
    call print_string
    
    ; Запускаем основной цикл
    jmp main_loop

; Инициализация видео
init_video:
    mov ax, 0x0003    ; Текстовый режим 80x25
    int 0x10
    ret

; Инициализация клавиатуры
init_keyboard:
    ; Устанавливаем обработчик прерывания клавиатуры
    cli
    mov ax, 0
    mov es, ax
    mov word [es:0x24], keyboard_handler
    mov word [es:0x26], cs
    sti
    ret

; Инициализация таймера
init_timer:
    ; Устанавливаем обработчик прерывания таймера
    cli
    mov ax, 0
    mov es, ax
    mov word [es:0x20], timer_handler
    mov word [es:0x22], cs
    sti
    ret

; Обработчик клавиатуры
keyboard_handler:
    push ax
    in al, 0x60       ; Читаем скан-код клавиши
    mov [last_key], al
    pop ax
    iret

; Обработчик таймера
timer_handler:
    push ax
    inc word [ticks]
    mov al, 0x20
    out 0x20, al
    pop ax
    iret

; Основной цикл
main_loop:
    ; Проверяем нажатие клавиш
    mov al, [last_key]
    cmp al, 0x01      ; ESC
    je shutdown
    
    ; Показываем меню
    call show_menu
    
    ; Обрабатываем выбор
    call handle_input
    
    jmp main_loop

; Показ меню
show_menu:
    mov si, menu_msg
    call print_string
    ret

; Обработка ввода
handle_input:
    mov ah, 0
    int 0x16
    
    cmp al, '1'
    je run_terminal
    cmp al, '2'
    je run_calculator
    cmp al, '3'
    je run_calendar
    ret

; Запуск терминала
run_terminal:
    mov si, term_msg
    call print_string
    ret

; Запуск калькулятора
run_calculator:
    mov si, calc_msg
    call print_string
    ret

; Запуск календаря
run_calendar:
    mov si, cal_msg
    call print_string
    ret

; Выключение
shutdown:
    mov si, shutdown_msg
    call print_string
    cli
    hlt

; Функция вывода строки
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
kernel_msg db 'MyOS Kernel loaded!', 13, 10, 0
menu_msg db 'Menu:', 13, 10
         db '1. Terminal', 13, 10
         db '2. Calculator', 13, 10
         db '3. Calendar', 13, 10
         db 'ESC to shutdown', 13, 10, 0
term_msg db 'Terminal started', 13, 10, 0
calc_msg db 'Calculator started', 13, 10, 0
cal_msg db 'Calendar started', 13, 10, 0
shutdown_msg db 'Shutting down...', 13, 10, 0

; Переменные
ticks dw 0
last_key db 0
