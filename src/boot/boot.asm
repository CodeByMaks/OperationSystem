[bits 16]
[org 0x7C00]

; Константы
STACK_SEGMENT equ 0x0000
STACK_OFFSET  equ 0x7C00
KERNEL_SEGMENT equ 0x1000
KERNEL_OFFSET  equ 0x0000
KERNEL_SIZE    equ 32          ; Количество секторов для загрузки

; Переход на точку входа
jmp short start
nop

; BPB (BIOS Parameter Block)
OEMLabel        db "MSDOS5.0"   ; OEM Label
BytesPerSector  dw 512          ; Bytes per sector
SectorsPerCluster db 1          ; Sectors per cluster
ReservedSectors dw 1            ; Reserved sectors
NumFATs         db 2            ; Number of FATs
RootDirEntries  dw 224          ; Root directory entries
TotalSectors    dw 2880         ; Total sectors (2880 * 512 = 1.44MB)
MediaType       db 0xF0         ; Media type (F0 = 3.5" floppy)
SectorsPerFAT   dw 9            ; Sectors per FAT
SectorsPerTrack dw 18           ; Sectors per track
NumHeads        dw 2            ; Number of heads
HiddenSectors   dd 0            ; Hidden sectors
TotalSectorsBig dd 0            ; Total sectors (if > 65535)
DriveNumber     db 0            ; Drive number
Reserved1       db 0            ; Reserved
BootSignature   db 0x29         ; Boot signature
VolumeID        dd 0x12345678   ; Volume ID
VolumeLabel     db "HeroX OS    "; Volume label (11 bytes)
FileSystem      db "FAT12   "   ; File system type (8 bytes)

; Code starts here
start:
    ; Инициализация сегментных регистров
    cli
    xor ax, ax          ; ax = 0
    mov ds, ax          ; ds = 0
    mov es, ax          ; es = 0
    mov ss, ax          ; ss = 0
    mov sp, STACK_OFFSET ; sp = 0x7C00
    sti

    ; Сохранение номера загрузочного диска
    mov [boot_drive], dl
    
    ; Вывод приветственного сообщения
    mov si, msg_loading
    call print_string
    
    ; Сброс дисковой системы
    xor ax, ax
    mov dl, [boot_drive]
    int 0x13
    jc disk_error
    
    ; Загрузка ядра
    mov ax, KERNEL_SEGMENT
    mov es, ax          ; es = KERNEL_SEGMENT
    xor bx, bx          ; ES:BX = адрес буфера для загрузки

    ; Чтение секторов
    mov ah, 0x02        ; Функция чтения секторов
    mov al, KERNEL_SIZE ; Количество секторов для чтения
    mov ch, 0           ; Цилиндр 0
    mov cl, 2           ; Начиная со второго сектора
    mov dh, 0           ; Головка 0
    mov dl, [boot_drive] ; Номер диска
    int 0x13            ; Чтение секторов
    jc disk_error       ; Если ошибка - переход на обработчик
    
    ; Проверка количества прочитанных секторов
    cmp al, KERNEL_SIZE
    jne sectors_error
    
    ; Вывод сообщения об успешной загрузке
    mov si, msg_ok
    call print_string
    
    ; Переход к ядру
    mov dl, [boot_drive]  ; Передаем номер загрузочного диска
    jmp KERNEL_SEGMENT:KERNEL_OFFSET

; Вспомогательные функции
print_string:
    mov ah, 0x0E
    mov bx, 0x0007      ; Светло-серый цвет
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    ret

; Обработка ошибки диска
disk_error:
    mov si, msg_disk_error
    call print_string
    mov si, msg_retry
    call print_string
    xor ah, ah
    int 0x16            ; Ждем нажатия клавиши
    jmp start           ; Пробуем снова

; Ошибка чтения секторов
sectors_error:
    mov si, msg_sectors_error
    call print_string
    jmp $

; Данные
msg_loading db 'Loading HeroX OS...', 13, 10, 0
msg_ok db 'OK', 13, 10, 0
msg_disk_error db 'Error reading disk!', 13, 10, 0
msg_retry db 'Press any key to retry...', 13, 10, 0
msg_sectors_error db 'Error: Not all sectors read!', 13, 10, 0
boot_drive db 0

; Заполнение до 510 байт
times 510-($-$$) db 0

; Загрузочная сигнатура
dw 0xAA55
