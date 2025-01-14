[org 0x7c00]
[bits 16]

; Clear the screen
mov ah, 0x00
mov al, 0x03
int 0x10

; Print welcome message
mov si, msg
call print_string

; Initialize cursor position
mov ah, 0x02    ; Set cursor position
mov bh, 0x00    ; Page number
mov dh, 1       ; Row
mov dl, 0       ; Column
int 0x10

; Cursor blink loop
cursor_loop:
    mov si, cursor_chars     ; Load cursor characters array
    mov byte [current_char], 0  ; Reset counter

char_loop:
    ; Show cursor
    mov ah, 0x09            ; Write character and attribute at cursor position
    mov al, [si]            ; Get current cursor character
    mov bh, 0x00           ; Page number
    mov bl, 0x0B           ; Attribute (bright cyan on black)
    mov cx, 1              ; Number of times to write character
    int 0x10
    
    ; Shorter delay for smooth animation
    mov cx, 0x08           ; Outer loop count
    mov dx, 0xFFFF         ; Inner loop count
    call delay
    
    inc si                 ; Move to next character
    inc byte [current_char]
    cmp byte [current_char], 4  ; Check if we've shown all characters
    jl char_loop
    
    jmp cursor_loop        ; Repeat forever

; Delay function
delay:
    push cx
.outer_loop:
    mov cx, dx
.inner_loop:
    loop .inner_loop
    dec dx
    jnz .outer_loop
    pop cx
    ret

; Print string function
print_string:
    mov ah, 0x0e    ; BIOS teletype output
.loop:
    lodsb           ; Load next character
    test al, al     ; Check if end of string (0)
    jz .done        ; If zero, we're done
    int 0x10        ; Print character
    jmp .loop       ; Repeat for next character
.done:
    ret

; Data
msg db 'Welcome to MyOS!', 13, 10, 0
cursor_chars db '|', 219, '|', ' '  ; Вертикальная черта, полный блок, вертикальная черта, пробел
current_char db 0

; Boot sector magic
times 510-($-$$) db 0
dw 0xaa55
