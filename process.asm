[bits 16]
%include "config.inc"

section .data
    process_table:    times (MAX_PROCESSES * PROCESS_ENTRY_SIZE) db 0
    current_process:  dw 0
    next_pid:        dw 1
    error_msg db 'Process error', 0
    success_msg db 'Operation successful', 0

section .text
    global init_processes
    global create_process
    global switch_process
    global terminate_process
    global get_current_process
    global schedule_next_process
    global process_init
    global process_create
    global process_exit
    global scheduler_interrupt
    global handle_shutdown
    global handle_file_operation

; Инициализация таблицы процессов
init_processes:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx

    ; Очищаем таблицу процессов
    mov ax, 0
    mov bx, process_table
    mov cx, MAX_PROCESSES * PROCESS_ENTRY_SIZE
    rep stosb

    ; Инициализируем текущий процесс
    mov word [current_process], 0
    mov word [next_pid], 1

    pop cx
    pop bx
    pop ax
    pop bp
    ret

; Создание нового процесса
; Вход: 
;   - stack: указатель на код процесса
;   - stack+2: размер стека процесса
; Выход:
;   - ax: PID нового процесса (0 если ошибка)
create_process:
    push bp
    mov bp, sp
    push bx
    push cx
    push dx
    push si
    push di

    ; Находим свободную запись в таблице процессов
    mov bx, process_table
    mov cx, MAX_PROCESSES
    
.find_free:
    mov al, [bx]
    test al, al
    jz .found_free
    add bx, PROCESS_ENTRY_SIZE
    loop .find_free
    
    ; Нет свободных слотов
    xor ax, ax
    jmp .exit

.found_free:
    ; Заполняем запись процесса
    mov ax, [next_pid]
    mov [bx], ax                    ; PID
    mov ax, [bp+4]                  ; Указатель на код
    mov [bx+2], ax
    mov ax, [bp+6]                  ; Размер стека
    mov [bx+4], ax
    mov word [bx+6], 0              ; Начальное состояние - готов
    
    ; Увеличиваем next_pid
    inc word [next_pid]
    
    ; Возвращаем PID
    mov ax, [bx]

.exit:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop bp
    ret 4

; Переключение на другой процесс
; Вход: ax - PID процесса
switch_process:
    push bp
    mov bp, sp
    push bx
    push cx
    push dx
    
    ; Сохраняем контекст текущего процесса
    mov bx, [current_process]
    test bx, bx
    jz .no_current
    
    ; Сохраняем регистры
    mov [bx+8], ax
    mov [bx+10], cx
    mov [bx+12], dx
    mov [bx+14], sp
    mov [bx+16], bp
    
.no_current:
    ; Находим новый процесс
    mov ax, [bp+4]
    mov bx, process_table
    mov cx, MAX_PROCESSES
    
.find_process:
    cmp [bx], ax
    je .found_process
    add bx, PROCESS_ENTRY_SIZE
    loop .find_process
    
    ; Процесс не найден
    jmp .exit
    
.found_process:
    ; Восстанавливаем контекст
    mov ax, [bx+8]
    mov cx, [bx+10]
    mov dx, [bx+12]
    mov sp, [bx+14]
    mov bp, [bx+16]
    
    ; Обновляем текущий процесс
    mov [current_process], bx
    
.exit:
    pop dx
    pop cx
    pop bx
    pop bp
    ret 2

; Завершение процесса
; Вход: ax - PID процесса
terminate_process:
    push bp
    mov bp, sp
    push bx
    push cx
    
    ; Находим процесс
    mov bx, process_table
    mov cx, MAX_PROCESSES
    
.find_process:
    cmp [bx], ax
    je .found_process
    add bx, PROCESS_ENTRY_SIZE
    loop .find_process
    jmp .exit
    
.found_process:
    ; Очищаем запись процесса
    push di
    mov di, bx
    mov cx, PROCESS_ENTRY_SIZE
    xor ax, ax
    rep stosb
    pop di
    
    ; Если это текущий процесс, сбрасываем указатель
    cmp [current_process], bx
    jne .exit
    mov word [current_process], 0
    
.exit:
    pop cx
    pop bx
    pop bp
    ret

; Получение текущего процесса
; Выход: ax - PID текущего процесса (0 если нет)
get_current_process:
    mov bx, [current_process]
    test bx, bx
    jz .no_process
    mov ax, [bx]
    ret
    
.no_process:
    xor ax, ax
    ret

; Планирование следующего процесса
schedule_next_process:
    push bp
    mov bp, sp
    push bx
    push cx
    
    ; Получаем текущий процесс
    mov bx, [current_process]
    test bx, bx
    jz .start_from_beginning
    
    ; Ищем следующий готовый процесс
    add bx, PROCESS_ENTRY_SIZE
    mov cx, MAX_PROCESSES - 1
    jmp .find_next
    
.start_from_beginning:
    mov bx, process_table
    mov cx, MAX_PROCESSES
    
.find_next:
    cmp byte [bx], 0               ; Проверяем, есть ли процесс
    je .next_entry
    cmp word [bx+6], 0            ; Проверяем состояние (0 = готов)
    je .found_next
    
.next_entry:
    add bx, PROCESS_ENTRY_SIZE
    loop .find_next
    
    ; Если не нашли, начинаем сначала
    mov bx, process_table
    mov cx, MAX_PROCESSES
    jmp .find_next
    
.found_next:
    ; Переключаемся на найденный процесс
    mov ax, [bx]
    call switch_process
    
    pop cx
    pop bx
    pop bp
    ret

; Initialize process manager
process_init:
    push bx
    push ax
    
    ; Initialize process list
    mov bx, current_process
    xor ax, ax
    call write_word        ; Set current_process to 0
    
    mov bx, next_pid
    mov ax, 1
    call write_word        ; Set next_pid to 1
    
    pop ax
    pop bx
    ret

; Enhanced process creation with error handling
process_create:
    push ebp
    mov ebp, esp
    
    ; Check available resources
    call check_resources
    test eax, eax
    jz .no_resources
    
    ; Allocate PCB
    mov ax, PCB_SIZE
    call memory_alloc
    test ax, ax
    jz .no_resources
    
    mov edx, eax          ; EDX = PCB address
    
    ; Allocate stack
    mov ax, [ebp + 8]     ; Stack size
    call memory_alloc
    test ax, ax
    jz .error_free_pcb
    mov ecx, eax          ; ECX = stack address
    
    ; Initialize PCB
    mov word [edx + PCB_NEXT], 0
    mov word [edx + PCB_PREV], 0
    mov word [edx + PCB_STATE], PROCESS_READY
    
    ; Get next process ID
    mov bx, next_pid
    call read_word
    inc ax
    call write_word        ; Update next_pid
    
    mov word [edx + PCB_PID], eax
    
    ; Set up stack and segments
    mov word [edx + PCB_SP], ecx
    mov word [edx + PCB_SS], ds
    mov word [edx + PCB_CS], cs
    
    ; Get current process
    mov bx, current_process
    call read_word
    mov ebx, eax
    
    test ebx, ebx
    jz .first_process
    
    ; Add to process list
    mov word [edx + PCB_NEXT], ebx
    mov word [ebx + PCB_PREV], edx
    
    jmp .done
    
.first_process:
    mov word [current_process], edx
    mov word [edx + PCB_NEXT], edx
    mov word [edx + PCB_PREV], edx
    
.done:
    mov eax, [edx + PCB_PID]
    jmp .exit
    
.error_free_pcb:
    push eax
    mov eax, edx
    call memory_free
    pop eax
    
.no_resources:
    xor eax, eax
    
.exit:
    mov esp, ebp
    pop ebp
    ret

; Exit current process
process_exit:
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Get current process
    mov bx, current_process
    call read_word
    mov si, ax
    test si, si
    jz .done
    
    ; Free stack
    mov bx, si
    add bx, PCB_SP
    call read_word
    push ax
    call memory_free
    
    ; Get next process
    mov bx, si
    add bx, PCB_NEXT
    call read_word
    mov di, ax         ; DI = next process
    
    cmp si, di        ; Last process?
    je .last_process
    
    ; Remove from list
    mov bx, si
    add bx, PCB_PREV
    call read_word     ; Get prev process
    push ax
    
    mov bx, di
    add bx, PCB_PREV
    pop ax
    call write_word    ; next->prev = prev
    
    mov bx, current_process
    mov ax, di
    call write_word    ; current = next
    jmp .free_pcb
    
.last_process:
    mov bx, current_process
    xor ax, ax
    call write_word    ; Clear current process
    
.free_pcb:
    mov ax, si
    call memory_free
    
.done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret

; Timer interrupt handler for process switching
scheduler_interrupt:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push ds
    push es
    
    ; Get current process
    mov bx, current_process
    call read_word
    mov si, ax
    test si, si
    jz .no_current_process
    
    ; Save current process context
    mov bx, si
    add bx, PCB_AX
    mov ax, [esp + 16]  ; Get saved AX from stack
    call write_word
    
    mov bx, si
    add bx, PCB_BX
    mov ax, [esp + 14]  ; Get saved BX from stack
    call write_word
    
    mov bx, si
    add bx, PCB_CX
    mov ax, [esp + 12]  ; Get saved CX from stack
    call write_word
    
    mov bx, si
    add bx, PCB_DX
    mov ax, [esp + 10]  ; Get saved DX from stack
    call write_word
    
    mov bx, si
    add bx, PCB_SI
    mov ax, [esp + 8]   ; Get saved SI from stack
    call write_word
    
    mov bx, si
    add bx, PCB_DI
    mov ax, [esp + 6]   ; Get saved DI from stack
    call write_word
    
    mov bx, si
    add bx, PCB_BP
    mov ax, [esp + 4]   ; Get saved BP from stack
    call write_word
    
    mov bx, si
    add bx, PCB_DS
    mov ax, [esp + 2]   ; Get saved DS from stack
    call write_word
    
    mov bx, si
    add bx, PCB_ES
    mov ax, [esp]       ; Get saved ES from stack
    call write_word
    
    ; Switch to next process
    mov bx, si
    add bx, PCB_NEXT
    call read_word
    mov si, ax
    
    mov bx, current_process
    mov ax, si
    call write_word
    
.no_current_process:
    ; Restore new process context
    mov bx, si
    add bx, PCB_AX
    call read_word
    mov [esp + 16], ax  ; Restore AX
    
    mov bx, si
    add bx, PCB_BX
    call read_word
    mov [esp + 14], ax  ; Restore BX
    
    mov bx, si
    add bx, PCB_CX
    call read_word
    mov [esp + 12], ax  ; Restore CX
    
    mov bx, si
    add bx, PCB_DX
    call read_word
    mov [esp + 10], ax  ; Restore DX
    
    mov bx, si
    add bx, PCB_SI
    call read_word
    mov [esp + 8], ax   ; Restore SI
    
    mov bx, si
    add bx, PCB_DI
    call read_word
    mov [esp + 6], ax   ; Restore DI
    
    mov bx, si
    add bx, PCB_BP
    call read_word
    mov [esp + 4], ax   ; Restore BP
    
    mov bx, si
    add bx, PCB_DS
    call read_word
    mov [esp + 2], ax   ; Restore DS
    
    mov bx, si
    add bx, PCB_ES
    call read_word
    mov [esp], ax       ; Restore ES
    
    pop es
    pop ds
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    iret

; New function: Handle system shutdown
handle_shutdown:
    ; Save system state
    call save_system_state
    
    ; Terminate all processes
    call terminate_all_processes
    
    ; Send ACPI shutdown signal
    mov dx, 0x604
    mov ax, 0x2000
    out dx, ax
    ret

; New function: Enhanced file operations handler
handle_file_operation:
    cmp al, SYS_CREATE
    je .create_file
    cmp al, SYS_DELETE
    je .delete_file
    cmp al, SYS_READ
    je .read_file
    cmp al, SYS_WRITE
    je .write_file
    ret

.create_file:
    ; File creation logic
    ret

.delete_file:
    ; File deletion logic
    ret

.read_file:
    ; File read logic
    ret

.write_file:
    ; File write logic
    ret

section .data align=2
    ; Константы для процессов
    MAX_PROCESSES       equ 16
    PROCESS_ENTRY_SIZE  equ 32
    
    ; Смещения в структуре процесса
    PROCESS_PID         equ 0   ; 2 байта
    PROCESS_CODE_PTR    equ 2   ; 2 байта
    PROCESS_STACK_SIZE  equ 4   ; 2 байта
    PROCESS_STATE       equ 6   ; 2 байта
    PROCESS_REGISTERS   equ 8   ; 16 байт (ax, cx, dx, sp, bp, si, di, flags)
    
    ; Состояния процесса
    PROCESS_READY       equ 0
    PROCESS_RUNNING     equ 1
    PROCESS_BLOCKED     equ 2
    PROCESS_TERMINATED  equ 3

; System call numbers
SYS_EXIT     equ 1
SYS_WRITE    equ 2
SYS_READ     equ 3
SYS_CREATE   equ 4
SYS_DELETE   equ 5
SYS_SHUTDOWN equ 6

; Process Control Block (PCB) structure
PCB_SIZE    equ 36      ; PCB size
PCB_NEXT    equ 0       ; Offset for next
PCB_PREV    equ 2       ; Offset for prev
PCB_STATE   equ 4       ; Offset for state
PCB_PID     equ 6       ; Offset for pid
PCB_SP      equ 8       ; Offset for sp
PCB_SS      equ 10      ; Offset for ss
PCB_IP      equ 12      ; Offset for ip
PCB_CS      equ 14      ; Offset for cs
PCB_FLAGS   equ 16      ; Offset for flags
PCB_AX      equ 18      ; Offset for ax
PCB_BX      equ 20      ; Offset for bx
PCB_CX      equ 22      ; Offset for cx
PCB_DX      equ 24      ; Offset for dx
PCB_SI      equ 26      ; Offset for si
PCB_DI      equ 28      ; Offset for di
PCB_BP      equ 30      ; Offset for bp
PCB_DS      equ 32      ; Offset for ds
PCB_ES      equ 34      ; Offset for es

; Process states
PROCESS_READY    equ 0
PROCESS_RUNNING  equ 1
PROCESS_BLOCKED  equ 2
PROCESS_ZOMBIE   equ 3
