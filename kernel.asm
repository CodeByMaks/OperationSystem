[bits 16]
[org 0x0000]      ; Ядро загружается в 0x1000:0x0000

section .text
    global kernel_start
    
    ; Внешние функции
    extern video_init
    extern video_print
    extern video_set_color
    extern video_clear
    extern keyboard_init
    extern memory_init
    extern fs_init
    extern shell_init
    extern shell_loop

kernel_start:
    ; Устанавливаем сегменты
    mov ax, cs
    mov ds, ax      ; DS = CS
    mov es, ax      ; ES = CS
    mov ss, ax      ; SS = CS
    mov sp, 0xFFF0  ; Стек ниже ядра
    
    ; Сохраняем номер загрузочного диска
    mov [boot_drive], dl
    
    ; Очищаем экран
    call video_clear
    
    ; Инициализируем видео
    call video_init
    
    ; Выводим приветствие
    mov al, 0x0F    ; Белый цвет
    call video_set_color
    mov si, msg_kernel
    call video_print
    
    ; Инициализируем подсистемы
    call keyboard_init
    call memory_init
    call fs_init
    
    ; Инициализация оболочки
    call shell_init
    
    ; Запуск основного цикла
    call shell_loop
    
    ; Бесконечный цикл (не должны сюда попасть)
    cli
    hlt
    jmp $

section .data
    msg_kernel db 'HeroX OS Kernel v1.0', 13, 10, 0
    boot_drive db 0

section .bss
    kernel_stack resb 4096

; Включаем все необходимые файлы
%include "video.asm"
%include "keyboard.asm"
%include "memory.asm"
%include "fs.asm"
%include "shell.asm"
