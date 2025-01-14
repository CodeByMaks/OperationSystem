[org 0x7c00]
[bits 16]

; Загрузчик (Bootloader)
jmp boot_start

; Данные BIOS Parameter Block (BPB)
bpb_oem_id          db 'MYOS    '   ; 8 байт
bpb_bytes_per_sector dw 512
bpb_sectors_per_cluster db 1
bpb_reserved_sectors dw 1
bpb_fat_count       db 2
bpb_root_entries    dw 224
bpb_total_sectors   dw 2880         ; 1.44 MB
bpb_media_type      db 0xF0         ; 3.5" флоппи
bpb_sectors_per_fat dw 9
bpb_sectors_per_track dw 18
bpb_heads           dw 2
bpb_hidden_sectors  dd 0
bpb_large_sectors   dd 0

; Расширенный загрузочный блок
ebr_drive_number    db 0            ; 0x00 для флоппи
ebr_reserved        db 0
ebr_signature       db 0x29
ebr_volume_id       dd 0x12345678
ebr_volume_label    db 'MYOS DISK  ' ; 11 байт
ebr_system_id       db 'FAT12   '    ; 8 байт

boot_start:
    ; Инициализация сегментов
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    ; Сохраняем номер загрузочного диска
    mov [ebr_drive_number], dl

    ; Выводим сообщение о загрузке
    mov si, loading_msg
    call print_string

    ; Загружаем ядро (сектор 2, 6 секторов)
    mov ax, 0x1000    ; Сегмент для загрузки
    mov es, ax
    xor bx, bx        ; Смещение
    mov ah, 0x02      ; Функция чтения
    mov al, 6         ; Количество секторов
    mov ch, 0         ; Цилиндр 0
    mov cl, 2         ; Начинаем со второго сектора
    mov dh, 0         ; Головка 0
    mov dl, [ebr_drive_number]
    int 0x13
    jc disk_error     ; Если CF=1, произошла ошибка

    ; Сообщение об успешной загрузке ядра
    mov si, kernel_loaded_msg
    call print_string

    ; Переходим к ядру
    jmp 0x1000:0x0000

disk_error:
    mov si, disk_error_msg
    call print_string
    jmp $

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
loading_msg db 'Loading MYOS...', 13, 10, 0
disk_error_msg db 'Disk error!', 13, 10, 0
kernel_loaded_msg db 'Kernel loaded, jumping to kernel...', 13, 10, 0

; Заполняем остаток сектора
times 510-($-$$) db 0
dw 0xAA55
