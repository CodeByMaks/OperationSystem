[BITS 16]

; Константы файловой системы
MAX_FILES       equ 64    ; Максимальное количество файлов
MAX_NAME_LEN    equ 32    ; Максимальная длина имени файла
MAX_FILE_SIZE   equ 4096  ; Максимальный размер файла

section .text

; Инициализация файловой системы
fs_init:
    push ax
    push bx
    push cx
    push si
    
    ; Очищаем таблицу файлов
    mov si, file_table
    mov cx, MAX_FILES * (MAX_NAME_LEN + 2)  ; Размер таблицы
    xor al, al
    
.clear:
    mov [si], al
    inc si
    loop .clear
    
    pop si
    pop cx
    pop bx
    pop ax
    ret

; Создание файла
; SI = имя файла
fs_create_file:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Проверяем существование файла
    call fs_find_file
    jnc .find_free
    
    ; Файл уже существует
    mov si, msg_file_exists
    call video_print
    stc
    jmp .done
    
.find_free:
    ; Ищем свободное место в таблице
    mov si, file_table
    mov cx, MAX_FILES
    
.next_entry:
    mov al, [si]
    test al, al
    jz .create_file     ; Нашли свободное место
    
    add si, MAX_NAME_LEN + 2
    loop .next_entry
    
    ; Нет свободного места
    mov si, msg_no_space
    call video_print
    stc
    jmp .done
    
.create_file:
    ; Копируем имя файла
    push si             ; Сохраняем указатель на начало записи
    mov di, si
    pop si
    
    ; Очищаем запись
    push cx
    mov cx, MAX_NAME_LEN + 2
    xor al, al
    rep stosb
    pop cx
    
    ; Копируем имя файла
    mov di, si
    mov cx, MAX_NAME_LEN
    
.copy_name:
    mov al, [si]
    test al, al
    jz .name_done
    
    mov [di], al
    inc si
    inc di
    loop .copy_name
    
.name_done:
    ; Устанавливаем размер файла
    mov word [di], 0
    
    ; Операция успешна
    clc
    
.done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Удаление файла
; SI = имя файла
fs_delete_file:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Ищем файл
    call fs_find_file
    jnc .not_found
    
    ; Очищаем запись
    mov cx, MAX_NAME_LEN + 2
    xor al, al
    rep stosb
    
    ; Операция успешна
    clc
    jmp .done
    
.not_found:
    mov si, msg_file_not_found
    call video_print
    stc
    
.done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Поиск файла
; SI = имя файла
; Возвращает:
; CF = 1 если файл найден
; DI = указатель на запись файла
fs_find_file:
    push ax
    push bx
    push cx
    push dx
    push si
    
    mov di, file_table
    mov cx, MAX_FILES
    
.next:
    ; Проверяем, не пустая ли запись
    mov al, [di]
    test al, al
    jz .skip
    
    ; Сравниваем имена
    push si
    push di
    call strcmp
    pop di
    pop si
    je .found
    
.skip:
    add di, MAX_NAME_LEN + 2
    loop .next
    
    ; Файл не найден
    clc
    jmp .done
    
.found:
    ; Файл найден
    stc
    
.done:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Сравнение строк
; Вход: SI = строка 1, DI = строка 2, CX = длина
; Выход: ZF = 1 если строки равны
strcmp:
    push ax
    push si
    push di
    push cx
    
.loop:
    mov al, [si]
    cmp al, [di]
    jne .not_equal
    inc si
    inc di
    loop .loop
    
    ; Строки равны
    pop cx
    pop di
    pop si
    pop ax
    xor ax, ax     ; Устанавливаем ZF = 1
    ret
    
.not_equal:
    pop cx
    pop di
    pop si
    pop ax
    or ax, 1       ; Сбрасываем ZF
    ret

; Список файлов
fs_list_files:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Начинаем с начала таблицы
    mov si, file_table
    mov cx, MAX_FILES
    
.next:
    ; Проверяем, не пустая ли запись
    mov al, [si]
    test al, al
    jz .skip
    
    ; Выводим имя файла
    push si
    call video_print
    
    ; Выводим размер
    mov al, ' '
    mov ah, 0Eh
    int 10h
    
    add si, MAX_NAME_LEN
    lodsw           ; Загружаем размер
    
    push si
    mov bx, ax
    call print_number
    
    mov si, msg_bytes
    call video_print
    pop si
    
.skip:
    add si, MAX_NAME_LEN + 2
    loop .next
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Чтение файла
; SI = имя файла
fs_read_file:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Ищем файл
    call fs_find_file
    jnc .not_found
    
    ; Выводим содержимое
    add di, MAX_NAME_LEN
    mov ax, [di]    ; Получаем размер
    mov cx, ax      ; Сохраняем размер в CX
    
    add di, 2       ; Переходим к данным
    
.read_loop:
    mov al, [di]
    mov ah, 0Eh
    int 10h
    
    inc di
    loop .read_loop
    
    ; Операция успешна
    clc
    jmp .done
    
.not_found:
    mov si, msg_file_not_found
    call video_print
    stc
    
.done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Запись в файл
; SI = имя файла
fs_write_file:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Ищем файл
    call fs_find_file
    jnc .not_found
    
    ; Получаем текст от пользователя
    push di
    mov si, prompt_text
    call video_print
    pop di
    
    ; Сохраняем указатель на данные
    add di, MAX_NAME_LEN + 2
    
    ; Читаем текст
    xor cx, cx          ; Счетчик символов
    
.read_loop:
    ; Читаем символ
    mov ah, 0
    int 16h
    
    ; Проверяем Enter
    cmp al, 13
    je .done_reading
    
    ; Проверяем максимальный размер
    cmp cx, MAX_FILE_SIZE
    jae .read_loop
    
    ; Сохраняем символ
    mov [di], al
    inc di
    inc cx
    
    ; Выводим символ
    mov ah, 0Eh
    int 10h
    
    jmp .read_loop
    
.done_reading:
    ; Сохраняем размер
    sub di, MAX_NAME_LEN + 2
    mov [di], cx
    
    ; Операция успешна
    clc
    jmp .done
    
.not_found:
    mov si, msg_file_not_found
    call video_print
    stc
    
.done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Вывод числа
; AX = число для вывода
print_number:
    push ax
    push bx
    push cx
    push dx
    
    ; Если число 0, выводим его сразу
    test ax, ax
    jnz .convert
    
    mov al, '0'
    mov ah, 0Eh
    int 10h
    jmp .done
    
.convert:
    mov bx, 10          ; Основание системы счисления
    xor cx, cx          ; Счетчик цифр
    
.divide:
    xor dx, dx
    div bx              ; Делим на 10
    push dx             ; Сохраняем остаток (цифру)
    inc cx              ; Увеличиваем счетчик
    test ax, ax         ; Проверяем частное
    jnz .divide         ; Если не 0, продолжаем деление
    
.print:
    pop ax              ; Извлекаем цифру
    add al, '0'         ; Преобразуем в ASCII
    mov ah, 0Eh         ; Функция вывода символа
    int 10h             ; Выводим цифру
    loop .print         ; Повторяем для всех цифр
    
.done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

section .data
    msg_file_exists db 'Error: File already exists', 13, 10, 0
    msg_no_space db 'Error: No free space', 13, 10, 0
    msg_file_not_found db 'Error: File not found', 13, 10, 0
    msg_bytes db ' bytes', 13, 10, 0
    prompt_text db 'Enter text: ', 0

section .bss
    file_table resb MAX_FILES * (MAX_NAME_LEN + 2)
