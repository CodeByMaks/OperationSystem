[bits 16]

; Константы
MAX_FILES       equ 64
MAX_NAME_LEN    equ 12
MAX_PATH_LEN    equ 256
SECTOR_SIZE     equ 512

section .text

; Инициализация файловой системы
fs_init:
    push ax
    push bx
    
    ; Очищаем таблицу файлов
    mov ax, 0
    mov di, file_table
    mov cx, MAX_FILES * (MAX_NAME_LEN + 4)
    rep stosb
    
    ; Инициализируем текущий путь
    mov byte [current_path], '/'
    mov byte [current_path + 1], 0
    
    pop bx
    pop ax
    ret

; Список файлов в текущей директории
fs_list_files:
    push si
    push di
    
    mov si, ls_header
    call print_string
    
    mov si, file_table
    mov cx, MAX_FILES
    
.next_file:
    mov al, [si]
    test al, al
    jz .skip_file
    
    push cx
    mov di, si
    call print_string
    mov al, 13
    call print_char
    mov al, 10
    call print_char
    pop cx
    
.skip_file:
    add si, MAX_NAME_LEN + 4
    loop .next_file
    
    pop di
    pop si
    ret

; Чтение файла
fs_read_file:
    push si
    push di
    
    ; Ищем файл
    call find_file
    test ax, ax
    jz .not_found
    
    ; Выводим содержимое
    mov si, ax
    add si, MAX_NAME_LEN
    call print_string
    jmp .done
    
.not_found:
    mov si, error_not_found
    call print_string
    
.done:
    pop di
    pop si
    ret

; Запись в файл
fs_write_file:
    push si
    push di
    
    ; Ищем файл
    call find_file
    test ax, ax
    jz .not_found
    
    ; Запрашиваем текст
    mov si, prompt_text
    call print_string
    
    ; Читаем текст
    mov di, buffer
    call read_line
    
    ; Сохраняем текст
    mov si, buffer
    mov di, ax
    add di, MAX_NAME_LEN
    call copy_string
    
    mov si, success_msg
    call print_string
    jmp .done
    
.not_found:
    mov si, error_not_found
    call print_string
    
.done:
    pop di
    pop si
    ret

; Создание файла
fs_create_file:
    push si
    push di
    
    ; Ищем свободное место
    call find_free_slot
    test ax, ax
    jz .no_space
    
    ; Копируем имя файла
    mov di, ax
    mov si, buffer
    call copy_string
    
    mov si, success_msg
    call print_string
    jmp .done
    
.no_space:
    mov si, error_no_space
    call print_string
    
.done:
    pop di
    pop si
    ret

; Удаление файла
fs_delete_file:
    push si
    push di
    
    ; Ищем файл
    call find_file
    test ax, ax
    jz .not_found
    
    ; Очищаем запись
    mov di, ax
    mov al, 0
    mov cx, MAX_NAME_LEN + 4
    rep stosb
    
    mov si, success_msg
    call print_string
    jmp .done
    
.not_found:
    mov si, error_not_found
    call print_string
    
.done:
    pop di
    pop si
    ret

; Смена директории
fs_change_dir:
    push si
    push di
    
    ; Проверяем путь
    cmp byte [si], '/'
    je .root
    
    ; Относительный путь
    mov di, current_path
    call append_path
    jmp .done
    
.root:
    ; Абсолютный путь
    mov di, current_path
    call copy_string
    
.done:
    mov si, success_msg
    call print_string
    
    pop di
    pop si
    ret

; Вспомогательные функции
find_file:
    push bx
    push cx
    push dx
    
    mov si, buffer
    mov di, file_table
    mov cx, MAX_FILES
    
.next:
    push si
    push di
    call compare_string
    pop di
    pop si
    je .found
    
    add di, MAX_NAME_LEN + 4
    loop .next
    
    xor ax, ax
    jmp .done
    
.found:
    mov ax, di
    
.done:
    pop dx
    pop cx
    pop bx
    ret

find_free_slot:
    push bx
    push cx
    push dx
    
    mov di, file_table
    mov cx, MAX_FILES
    
.next:
    mov al, [di]
    test al, al
    jz .found
    
    add di, MAX_NAME_LEN + 4
    loop .next
    
    xor ax, ax
    jmp .done
    
.found:
    mov ax, di
    
.done:
    pop dx
    pop cx
    pop bx
    ret

print_string:
    push ax
    
.next:
    mov al, [si]
    test al, al
    jz .done
    
    call print_char
    inc si
    jmp .next
    
.done:
    pop ax
    ret

print_char:
    push ax
    push bx
    
    mov ah, 0Eh
    mov bh, 0
    int 10h
    
    pop bx
    pop ax
    ret

read_line:
    push ax
    push bx
    xor cx, cx
    
.next:
    mov ah, 0
    int 16h
    
    cmp al, 13
    je .done
    
    cmp al, 8
    je .backspace
    
    cmp cx, MAX_PATH_LEN-1
    je .next
    
    mov [di], al
    inc di
    inc cx
    
    mov ah, 0Eh
    mov bh, 0
    int 10h
    
    jmp .next
    
.backspace:
    test cx, cx
    jz .next
    
    dec di
    dec cx
    
    mov ah, 0Eh
    mov al, 8
    int 10h
    mov al, ' '
    int 10h
    mov al, 8
    int 10h
    
    jmp .next
    
.done:
    mov byte [di], 0
    
    mov ah, 0Eh
    mov al, 13
    int 10h
    mov al, 10
    int 10h
    
    pop bx
    pop ax
    ret

copy_string:
    push ax
    
.next:
    mov al, [si]
    mov [di], al
    inc si
    inc di
    test al, al
    jnz .next
    
    pop ax
    ret

compare_string:
    push ax
    
.next:
    mov al, [si]
    mov ah, [di]
    inc si
    inc di
    test al, al
    jz .check_end
    cmp al, ah
    jne .not_equal
    jmp .next
    
.check_end:
    test ah, ah
    jz .equal
    
.not_equal:
    pop ax
    clc
    ret
    
.equal:
    pop ax
    stc
    ret

append_path:
    push ax
    push si
    
    ; Ищем конец текущего пути
    mov si, di
.find_end:
    mov al, [si]
    test al, al
    jz .found_end
    inc si
    jmp .find_end
    
.found_end:
    ; Добавляем слэш если нужно
    cmp byte [si-1], '/'
    je .copy
    mov byte [si], '/'
    inc si
    
.copy:
    ; Копируем новый путь
    mov di, si
    call copy_string
    
    pop si
    pop ax
    ret

section .data
    ls_header db 'Files in current directory:', 13, 10, 0
    prompt_text db 'Enter text: ', 0
    error_not_found db 'Error: File not found', 13, 10, 0
    error_no_space db 'Error: No space left', 13, 10, 0
    success_msg db 'Operation successful', 13, 10, 0

section .bss
    file_table resb MAX_FILES * (MAX_NAME_LEN + 4)
    current_path resb MAX_PATH_LEN
    buffer resb MAX_PATH_LEN
