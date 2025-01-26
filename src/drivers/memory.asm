[bits 16]

section .text
    ; Helper function to write word to memory
    ; Input: BX = address, AX = value
    write_word:
        mov [bx], ax       ; Write the value directly using DS
        ret

    ; Helper function to read word from memory
    ; Input: BX = address
    ; Output: AX = value
    read_word:
        mov ax, [bx]      ; Read the value directly using DS
        ret

    ; Initialize memory manager
    memory_init:
        ; Инициализация менеджера памяти
        push es
        
        ; Очищаем память для структур данных
        mov ax, 0
        mov es, ax
        mov di, memory_map
        mov cx, 256
        rep stosw
        
        ; Получаем карту памяти через BIOS
        mov ax, 0xE801
        int 0x15
        jc .error
        
        ; Сохраняем информацию о памяти
        mov [mem_kb_1m], ax    ; Память до 16 МБ в КБ
        mov [mem_kb_16m], bx   ; Память после 16 МБ в 64КБ блоках
        
        ; Initialize first block
        mov bx, HEAP_START - 0x10000  ; Adjust for kernel segment
        mov ax, HEAP_SIZE
        call write_word    ; Write block size
        
        ; Mark block as free
        add bx, 2
        xor ax, ax        ; 0 = free
        call write_word
        
        pop es
        ret
        
    .error:
        ; В случае ошибки предполагаем минимум памяти
        mov word [mem_kb_1m], 640
        mov word [mem_kb_16m], 0
        pop es
        ret

    ; Allocate memory block
    ; Input: AX = size needed
    ; Output: BX = pointer to allocated block (0 if failed)
    memory_alloc:
        push ax
        push cx
        push dx
        push si
        
        ; Add header size to requested size
        add ax, HEADER_SIZE
        
        ; Round up to MIN_BLOCK
        add ax, MIN_BLOCK - 1
        and ax, ~(MIN_BLOCK - 1)
        
        mov cx, ax        ; Save size in CX
        
        ; Start at beginning of heap
        mov bx, HEAP_START - 0x10000  ; Adjust for kernel segment
        
    .find_block:
        ; Read block size
        call read_word
        mov dx, ax        ; Save size in DX
        test dx, dx       ; If size is 0, we've reached the end
        jz .alloc_fail
        
        ; Read block status
        add bx, 2
        call read_word
        test ax, ax       ; Is block free?
        jnz .next_block
        
        ; Check if block is big enough
        cmp dx, cx
        jb .next_block
        
        ; Found a suitable block
        sub bx, 2         ; Back to start of block
        mov ax, cx        ; Get requested size
        call write_word   ; Update block size
        
        add bx, 2
        mov ax, 1         ; Mark as allocated
        call write_word
        
        add bx, 2         ; Skip header
        jmp .alloc_done
        
    .next_block:
        sub bx, 2         ; Back to start of block
        add bx, dx        ; Move to next block
        jmp .find_block
        
    .alloc_fail:
        xor bx, bx        ; Return NULL
        
    .alloc_done:
        pop si
        pop dx
        pop cx
        pop ax
        ret

    ; Free memory block
    ; Input: BX = pointer to block
    memory_free:
        test bx, bx       ; Check for NULL
        jz .free_done
        
        push ax
        push bx
        
        sub bx, HEADER_SIZE  ; Point to header
        
        ; Mark block as free
        add bx, 2
        xor ax, ax
        call write_word
        
        pop bx
        pop ax
        
    .free_done:
        ret

section .data
    mem_kb_1m dw 0    ; Память до 16 МБ в КБ
    mem_kb_16m dw 0   ; Память после 16 МБ в 64КБ блоках

section .bss
    memory_map resw 256  ; Карта памяти

; Constants
HEAP_START equ 0x12000   ; Start of heap (8KB from kernel start at 0x10000)
HEAP_SIZE  equ 0x7000    ; Heap size (28KB)
HEADER_SIZE equ 4        ; Block header size
MIN_BLOCK equ 16         ; Minimum block size
