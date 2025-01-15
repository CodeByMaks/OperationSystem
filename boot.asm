[bits 16]
[org 0x7c00]

; Константы
KERNEL_SEGMENT equ 0x1000
KERNEL_OFFSET  equ 0x0000
KERNEL_SIZE    equ 4    ; 4 сектора (2КБ)

start:
    ; Установка сегментных регистров
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00
    
    ; Сохраняем номер загрузочного диска
    mov [boot_drive], dl
    
    ; Очищаем экран
    mov ah, 0x00    ; Установка видеорежима
    mov al, 0x03    ; 80x25 цветной текст
    int 0x10
    
    ; Устанавливаем цвет текста
    mov ah, 0x0B    ; Установка цветовой палитры
    mov bh, 0x00    ; Фоновый цвет
    mov bl, 0x07    ; Светло-серый на черном
    int 0x10
    
    ; Выводим сообщение о загрузке
    mov si, msg_loading
    call print_string
    
    ; Сброс дисковой системы
    xor ah, ah
    int 0x13
    jc error
    
    ; Загружаем ядро
    mov bx, KERNEL_SEGMENT
    mov es, bx
    mov bx, KERNEL_OFFSET
    
    mov ah, 0x02        ; Функция чтения секторов
    mov al, KERNEL_SIZE ; Количество секторов
    mov ch, 0           ; Цилиндр 0
    mov cl, 2           ; Сектор 2 (сразу после загрузчика)
    mov dh, 0           ; Головка 0
    mov dl, [boot_drive]
    int 0x13
    jc error
    
    ; Проверяем, что все сектора загружены
    cmp al, KERNEL_SIZE
    jne error
    
    ; Выводим сообщение об успешной загрузке
    mov si, msg_ok
    call print_string
    
    ; Передаем управление ядру
    mov dl, [boot_drive]  ; Передаем номер загрузочного диска
    jmp KERNEL_SEGMENT:KERNEL_OFFSET

error:
    mov si, msg_error
    call print_string
    
    ; Выводим код ошибки
    mov al, ah
    call print_hex
    
    jmp $

; Вывод строки (SI = указатель на строку)
print_string:
    push ax
    push bx
    mov ah, 0x0E
    mov bh, 0
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    pop bx
    pop ax
    ret

; Вывод шестнадцатеричного числа в AL
print_hex:
    push ax
    push cx
    
    mov ah, 0x0E
    mov bl, al
    shr al, 4
    call .print_digit
    mov al, bl
    and al, 0x0F
    call .print_digit
    
    pop cx
    pop ax
    ret
    
.print_digit:
    cmp al, 10
    jb .decimal
    add al, 'A' - 10
    jmp .print
.decimal:
    add al, '0'
.print:
    int 0x10
    ret

; Данные
msg_loading db 'Loading HeroX OS...', 13, 10, 0
msg_ok      db 'OK', 13, 10, 0
msg_error   db 'Error loading HeroX! Code: ', 0
boot_drive  db 0

; Загрузочная сигнатура
times 510-($-$$) db 0
dw 0xAA55
