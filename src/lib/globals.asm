[bits 16]

section .bss
    global exit_flag
    exit_flag resb 1    ; Флаг выхода
