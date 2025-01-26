[bits 16]

section .text
    global init_memory
    global alloc_memory
    global free_memory

; Инициализация менеджера памяти
init_memory:
    push bp
    mov bp, sp
    
    ; Очищаем таблицу распределения памяти
    mov cx, 256  ; Размер таблицы
    mov di, memory_table
    xor ax, ax
    rep stosw
    
    pop bp
    ret

; Выделение памяти
; Вход: ax = размер в байтах
; Выход: ax = адрес выделенной памяти или 0 если нет свободной памяти
alloc_memory:
    push bp
    mov bp, sp
    push bx
    push cx
    push dx
    
    ; Сохраняем размер
    mov bx, ax
    
    ; Ищем свободный блок подходящего размера
    mov cx, 256  ; Количество записей в таблице
    mov di, memory_table
    
.find_block:
    mov ax, [di]
    test ax, ax  ; Проверяем, свободен ли блок
    jz .found_block
    add di, 2
    loop .find_block
    
    ; Не нашли свободный блок
    xor ax, ax
    jmp .done
    
.found_block:
    ; Помечаем блок как занятый
    mov [di], bx
    
    ; Вычисляем адрес блока
    sub di, memory_table
    shr di, 1    ; Делим на 2, так как каждая запись 2 байта
    shl di, 4    ; Умножаем на 16 (размер блока)
    add di, heap_start
    
    mov ax, di   ; Возвращаем адрес
    
.done:
    pop dx
    pop cx
    pop bx
    pop bp
    ret

; Освобождение памяти
; Вход: ax = адрес для освобождения
free_memory:
    push bp
    mov bp, sp
    push bx
    
    ; Вычисляем индекс в таблице
    sub ax, heap_start
    shr ax, 4    ; Делим на 16 (размер блока)
    shl ax, 1    ; Умножаем на 2 (размер записи)
    
    ; Очищаем запись в таблице
    mov di, memory_table
    add di, ax
    xor ax, ax
    mov [di], ax
    
    pop bx
    pop bp
    ret

section .data
    heap_start equ 0x1000  ; Начальный адрес кучи

section .bss
    memory_table resw 256  ; Таблица распределения памяти (512 байт)
