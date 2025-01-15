[bits 16]

; Константы
CMD_BUFFER_SIZE equ 256

; Цвета
COLOR_PROMPT    equ 0x0B    ; Светло-голубой
COLOR_ERROR     equ 0x0C    ; Светло-красный
COLOR_SUCCESS   equ 0x0A    ; Светло-зеленый
COLOR_INFO      equ 0x0F    ; Белый
COLOR_DEFAULT   equ 0x07    ; Светло-серый

section .text

; Инициализация оболочки
shell_init:
    ; Очищаем экран
    call video_clear
    
    ; Устанавливаем цвет и выводим приветствие
    mov al, COLOR_INFO
    call video_set_color
    mov si, welcome_msg
    call video_print
    
    ; Возвращаем стандартный цвет
    mov al, COLOR_DEFAULT
    call video_set_color
    ret

; Основной цикл оболочки
shell_loop:
    ; Выводим приглашение
    mov al, COLOR_PROMPT
    call video_set_color
    mov si, prompt
    call video_print
    mov al, COLOR_DEFAULT
    call video_set_color
    
    ; Читаем команду
    mov di, cmd_buffer
    call read_cmd
    
    ; Обрабатываем команду
    mov si, cmd_buffer
    call process_cmd
    
    jmp shell_loop

; Чтение команды
read_cmd:
    xor cx, cx          ; Счетчик символов
.loop:
    mov ah, 0           ; Функция BIOS - чтение символа
    int 16h             ; Вызов BIOS
    
    cmp al, 13          ; Enter?
    je .done
    
    cmp al, 8           ; Backspace?
    je .backspace
    
    cmp cx, CMD_BUFFER_SIZE-1  ; Проверка на переполнение
    je .loop
    
    mov [di], al        ; Сохраняем символ
    inc di
    inc cx
    
    mov ah, 0Eh         ; Выводим символ
    int 10h
    
    jmp .loop

.backspace:
    test cx, cx         ; Буфер пустой?
    jz .loop
    
    dec di              ; Удаляем последний символ
    dec cx
    
    mov ah, 0Eh         ; Стираем символ на экране
    mov al, 8
    int 10h
    mov al, ' '
    int 10h
    mov al, 8
    int 10h
    
    jmp .loop

.done:
    mov byte [di], 0    ; Завершающий ноль
    mov ah, 0Eh         ; Новая строка
    mov al, 13
    int 10h
    mov al, 10
    int 10h
    ret

; Обработка команды
process_cmd:
    ; Пропускаем пробелы в начале
    call skip_spaces
    
    ; Проверяем пустую строку
    cmp byte [si], 0
    je .done
    
    ; Сравниваем с известными командами
    mov di, cmd_help
    call strcmp
    jc do_help
    
    mov di, cmd_shutdown
    call strcmp
    jc do_shutdown
    
    mov di, cmd_ls
    call strcmp
    jc do_ls
    
    mov di, cmd_cd
    call strcmp
    jc do_cd
    
    mov di, cmd_cat
    call strcmp
    jc do_cat
    
    mov di, cmd_write
    call strcmp
    jc do_write
    
    mov di, cmd_create
    call strcmp
    jc do_create
    
    mov di, cmd_delete
    call strcmp
    jc do_delete
    
    ; Неизвестная команда
    mov al, COLOR_ERROR
    call video_set_color
    mov si, shell_error_msg
    call video_print
    mov al, COLOR_DEFAULT
    call video_set_color
    
.done:
    ret

do_help:
    mov al, COLOR_INFO
    call video_set_color
    mov si, help_msg
    call video_print
    mov al, COLOR_DEFAULT
    call video_set_color
    ret

do_shutdown:
    mov si, shutdown_msg
    call video_print
    ; Выполняем выключение сразу
    mov ax, 0x5307
    mov bx, 0x0001
    mov cx, 0x0003
    int 0x15
    ; Если не поддерживается APM, просто зависаем
    cli
    hlt
    jmp $

do_ls:
    call fs_list_files
    ret

do_cd:
    ; Пропускаем имя команды
    call skip_word
    call skip_spaces
    
    ; Проверяем аргумент
    cmp byte [si], 0
    je .no_arg
    
    ; Меняем директорию
    call fs_change_dir
    jmp .done
    
.no_arg:
    mov al, COLOR_ERROR
    call video_set_color
    mov si, error_no_arg
    call video_print
    mov al, COLOR_DEFAULT
    call video_set_color
    
.done:
    ret

do_cat:
    ; Пропускаем имя команды
    call skip_word
    call skip_spaces
    
    ; Проверяем аргумент
    cmp byte [si], 0
    je .no_arg
    
    ; Читаем файл
    call fs_read_file
    jmp .done
    
.no_arg:
    mov al, COLOR_ERROR
    call video_set_color
    mov si, error_no_arg
    call video_print
    mov al, COLOR_DEFAULT
    call video_set_color
    
.done:
    ret

do_write:
    ; Пропускаем имя команды
    call skip_word
    call skip_spaces
    
    ; Проверяем аргумент
    cmp byte [si], 0
    je .no_arg
    
    ; Записываем в файл
    call fs_write_file
    jmp .done
    
.no_arg:
    mov al, COLOR_ERROR
    call video_set_color
    mov si, error_no_arg
    call video_print
    mov al, COLOR_DEFAULT
    call video_set_color
    
.done:
    ret

do_create:
    ; Пропускаем имя команды
    call skip_word
    call skip_spaces
    
    ; Проверяем аргумент
    cmp byte [si], 0
    je .no_arg
    
    ; Создаем файл
    call fs_create_file
    jmp .done
    
.no_arg:
    mov al, COLOR_ERROR
    call video_set_color
    mov si, error_no_arg
    call video_print
    mov al, COLOR_DEFAULT
    call video_set_color
    
.done:
    ret

do_delete:
    ; Пропускаем имя команды
    call skip_word
    call skip_spaces
    
    ; Проверяем аргумент
    cmp byte [si], 0
    je .no_arg
    
    ; Удаляем файл
    call fs_delete_file
    jmp .done
    
.no_arg:
    mov al, COLOR_ERROR
    call video_set_color
    mov si, error_no_arg
    call video_print
    mov al, COLOR_DEFAULT
    call video_set_color
    
.done:
    ret

; Вспомогательные функции
skip_word:
    lodsb
    test al, al
    jz .done
    cmp al, ' '
    jne skip_word
.done:
    ret

skip_spaces:
    lodsb
    test al, al
    jz .done
    cmp al, ' '
    je skip_spaces
    dec si
.done:
    ret

strcmp:
    push si
    push di
.loop:
    mov al, [si]
    mov ah, [di]
    inc si
    inc di
    test al, al
    jz .check_end
    cmp al, ah
    jne .not_equal
    jmp .loop
.check_end:
    test ah, ah
    jz .equal
.not_equal:
    pop di
    pop si
    clc
    ret
.equal:
    pop di
    pop si
    stc
    ret

section .data
    prompt db '> ', 0
    welcome_msg db 'HeroX OS v1.1', 13, 10
                db 'Developed by Maks Donfort', 13, 10
                db '(c) 2025 All rights reserved', 13, 10, 0
    help_msg db 'Available commands:', 13, 10
            db '  help     - Show this help', 13, 10
            db '  ls       - List files', 13, 10
            db '  cd       - Change directory', 13, 10
            db '  cat      - View file contents', 13, 10
            db '  write    - Write to file', 13, 10
            db '  create   - Create new file', 13, 10
            db '  delete   - Delete file', 13, 10
            db '  shutdown - Power off system', 13, 10, 0
    
    cmd_help db 'help', 0
    cmd_shutdown db 'shutdown', 0
    cmd_ls db 'ls', 0
    cmd_cd db 'cd', 0
    cmd_cat db 'cat', 0
    cmd_write db 'write', 0
    cmd_create db 'create', 0
    cmd_delete db 'delete', 0
    
    shell_error_msg db 'Error: Unknown command', 13, 10, 0
    error_no_arg db 'Error: Missing argument', 13, 10, 0
    shell_success_msg db 'Operation successful', 13, 10, 0
    shutdown_msg db 'Shutting down...', 13, 10, 0

section .bss
    cmd_buffer resb CMD_BUFFER_SIZE
