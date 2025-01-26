[BITS 16]

; Константы
CMD_BUFFER_SIZE equ 256
ARG_BUFFER_SIZE equ 256

; Цвета
COLOR_PROMPT  equ 0x0A   ; Зеленый на черном
COLOR_ERROR   equ 0x0C   ; Красный на черном
COLOR_DEFAULT equ 0x07   ; Серый на черном
COLOR_INFO    equ 0x0B   ; Голубой на черном

section .text
    global shell_start
    extern exit_flag    ; Объявляем флаг как внешний
    extern print_string ; Объявляем функцию вывода строки

shell_start:
    ; Выводим приветствие
    mov si, welcome_msg
    call print_string
    
    ; Входим в основной цикл
    jmp shell_loop

; Основной цикл оболочки
shell_loop:
    ; Проверяем флаг выхода
    mov al, [exit_flag]
    test al, al
    jnz exit_shell

    ; Выводим приглашение
    mov si, prompt
    call print_string
    
    ; Читаем команду
    mov di, cmd_buffer
    xor cx, cx          ; Счетчик символов
    
.read_char:
    ; Читаем символ
    mov ah, 0x00    ; Функция для чтения символа
    int 16h         ; Вызываем прерывание BIOS
    
    ; Проверяем Enter
    cmp al, 13
    je .enter_pressed
    
    ; Проверяем Backspace
    cmp al, 8
    je .backspace
    
    ; Проверяем, что символ печатный
    cmp al, ' '
    jb .read_char
    cmp al, '~'
    ja .read_char
    
    ; Проверяем, есть ли место в буфере
    cmp cx, CMD_BUFFER_SIZE - 2
    jae .read_char
    
    ; Сохраняем символ и выводим его
    stosb           ; Сохраняем символ в буфере
    inc cx          ; Увеличиваем счетчик
    
    ; Выводим символ
    mov ah, 0x0E
    mov bh, 0
    int 10h
    
    jmp .read_char

.backspace:
    ; Проверяем, есть ли что удалять
    test cx, cx
    jz .read_char
    
    ; Удаляем последний символ
    dec di
    dec cx
    
    ; Выводим backspace
    mov ah, 0x0E
    mov al, 8
    int 10h
    mov al, ' '
    int 10h
    mov al, 8
    int 10h
    
    jmp .read_char

.enter_pressed:
    ; Добавляем нулевой байт в конец строки
    mov byte [di], 0
    
    ; Добавляем перевод строки
    mov ah, 0x0E
    mov al, 13  ; CR
    int 10h
    mov al, 10  ; LF
    int 10h
    
    ; Проверяем, не пустая ли команда
    mov si, cmd_buffer
    cmp byte [si], 0
    je .cmd_done
    
    ; Копируем первое слово в cmd_word
    mov si, cmd_buffer
    mov di, cmd_word
    call get_first_word
    
    ; Сравниваем команды
    mov si, cmd_word
    
    mov di, cmd_help    ; Проверяем "help"
    call strcmp
    jc .do_help
    
    mov si, cmd_word
    mov di, cmd_info    ; Проверяем "info"
    call strcmp
    jc .do_info
    
    mov si, cmd_word
    mov di, cmd_quit    ; Проверяем "quit"
    call strcmp
    jc .do_shutdown
    
    mov si, cmd_word
    mov di, cmd_q       ; Проверяем "q"
    call strcmp
    jc .do_shutdown
    
    ; Если дошли до сюда - команда неизвестна
    mov si, msg_unknown_cmd
    call print_string
    
    jmp .cmd_done

.do_help:
    mov si, msg_help
    call print_string
    jmp .cmd_done

.do_info:
    mov si, msg_info
    call print_string
    jmp .cmd_done

.do_shutdown:
    mov byte [exit_flag], 1
    jmp .cmd_done

.cmd_done:
    ; Очищаем буфер команды
    mov di, cmd_buffer
    mov cx, CMD_BUFFER_SIZE
    xor al, al
    rep stosb
    
    jmp shell_loop

exit_shell:
    ret

; Функция сравнения строк (возвращает CF=1 если строки равны)
strcmp:
    push ax
    push si
    push di
    
.compare:
    mov al, [si]
    mov ah, [di]
    
    ; Проверяем на конец строки
    test al, al
    jz .check_end
    test ah, ah
    jz .not_equal
    
    ; Сравниваем символы (игнорируя регистр)
    or al, 0x20     ; Преобразуем в нижний регистр
    or ah, 0x20
    cmp al, ah
    jne .not_equal
    
    inc si
    inc di
    jmp .compare

.check_end:
    test ah, ah
    jnz .not_equal
    ; Строки равны
    pop di
    pop si
    pop ax
    stc             ; CF=1 (строки равны)
    ret

.not_equal:
    pop di
    pop si
    pop ax
    clc             ; CF=0 (строки не равны)
    ret

; Функция получения первого слова из строки
get_first_word:
    push ax
    push si
    push di
    push cx
    
    mov cx, 31      ; Максимальная длина слова (32 байта с нулем)
    
    ; Пропускаем начальные пробелы
.skip_spaces:
    lodsb
    cmp al, ' '
    je .skip_spaces
    cmp al, 0
    je .end
    
    ; Копируем слово
    stosb           ; Сохраняем первый символ
    dec cx
.copy_loop:
    test cx, cx     ; Проверяем, есть ли место в буфере
    jz .end         ; Если нет - заканчиваем
    
    lodsb
    cmp al, ' '
    je .end
    cmp al, 0
    je .end
    cmp al, 13      ; CR
    je .end
    cmp al, 10      ; LF
    je .end
    
    stosb
    dec cx
    jmp .copy_loop
    
.end:
    xor al, al
    stosb           ; Завершающий нуль
    pop cx
    pop di
    pop si
    pop ax
    ret

section .data
    ; Приветственное сообщение
    welcome_msg db 'HeroX OS v1.1', 13, 10
               db 'Developed by Maks Donfort', 13, 10
               db '(c) 2025 All rights reserved', 13, 10
               db 'Type "help" for available commands', 13, 10, 0
    
    ; Приглашение командной строки
    prompt db '> ', 0
    
    ; Сообщения справки
    msg_help db 'Available commands:', 13, 10
            db '  help    - Show this help message', 13, 10
            db '  info    - Show system information', 13, 10
            db '  quit, q - Exit the system', 13, 10, 0
    
    msg_info db 'HeroX OS v1.1', 13, 10
            db 'A simple operating system', 13, 10
            db 'Memory: 640K', 13, 10
            db 'Storage: Floppy Disk', 13, 10, 0
    
    msg_unknown_cmd db 'Unknown command. Type "help" for available commands', 13, 10, 0
    
    ; Команды
    cmd_help db 'help', 0
    cmd_info db 'info', 0
    cmd_quit db 'quit', 0
    cmd_q db 'q', 0
    
    ; Буферы для команд
    cmd_buffer times CMD_BUFFER_SIZE db 0
    cmd_word times 32 db 0
