[bits 16]
%include "config.inc"

section .text
    global process_init
    global schedule_next_process
    global handle_interrupt

; Инициализация системы процессов
process_init:
    push ax
    push bx
    
    ; Очищаем таблицу процессов
    mov ax, 0
    mov bx, process_table
    mov cx, MAX_PROCESSES * PROCESS_ENTRY_SIZE
.clear_loop:
    mov byte [bx], 0
    inc bx
    loop .clear_loop
    
    ; Инициализируем текущий процесс
    mov word [current_process], 0
    
    pop bx
    pop ax
    ret

; Планировщик процессов
schedule_next_process:
    push ax
    push bx
    
    ; Получаем текущий процесс
    mov ax, [current_process]
    inc ax
    cmp ax, MAX_PROCESSES
    jb .check_process
    xor ax, ax  ; Если достигли максимума, начинаем сначала
    
.check_process:
    ; Проверяем, активен ли процесс
    mov bx, process_table
    imul bx, ax, PROCESS_ENTRY_SIZE
    cmp byte [bx], 1  ; 1 = активный процесс
    je .found_process
    
    ; Если процесс не активен, ищем следующий
    inc ax
    cmp ax, MAX_PROCESSES
    jb .check_process
    xor ax, ax  ; Если не нашли активных процессов, возвращаемся к началу
    
.found_process:
    mov [current_process], ax
    
    pop bx
    pop ax
    ret

; Обработчик прерываний
handle_interrupt:
    ; Пока просто возвращаем управление
    ret

section .data
    current_process dw 0  ; Индекс текущего процесса

section .bss
    process_table resb MAX_PROCESSES * PROCESS_ENTRY_SIZE  ; Таблица процессов
