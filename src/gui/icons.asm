[bits 16]

section .data
; Данные иконки папки (16x16 пикселей)
folder_icon:
    db 0,0,0,0,0,14,14,14,14,14,14,14,0,0,0,0
    db 0,0,0,14,14,14,14,14,14,14,14,14,14,0,0,0
    db 0,0,14,14,14,14,14,14,14,14,14,14,14,14,0,0
    db 0,14,14,14,14,14,14,14,14,14,14,14,14,14,14,0
    db 0,14,14,14,14,14,14,14,14,14,14,14,14,14,14,0
    db 0,14,14,14,14,14,14,14,14,14,14,14,14,14,14,0
    db 0,14,14,14,14,14,14,14,14,14,14,14,14,14,14,0
    db 0,14,14,14,14,14,14,14,14,14,14,14,14,14,14,0
    db 0,14,14,14,14,14,14,14,14,14,14,14,14,14,14,0
    db 0,14,14,14,14,14,14,14,14,14,14,14,14,14,14,0
    db 0,14,14,14,14,14,14,14,14,14,14,14,14,14,14,0
    db 0,14,14,14,14,14,14,14,14,14,14,14,14,14,14,0
    db 0,14,14,14,14,14,14,14,14,14,14,14,14,14,14,0
    db 0,0,14,14,14,14,14,14,14,14,14,14,14,14,0,0
    db 0,0,0,14,14,14,14,14,14,14,14,14,14,0,0,0
    db 0,0,0,0,0,14,14,14,14,14,14,14,0,0,0,0

; Данные иконки файла (16x16 пикселей)
file_icon:
    db 0,0,15,15,15,15,15,15,15,15,15,15,0,0,0,0
    db 0,0,15,15,15,15,15,15,15,15,15,15,15,0,0,0
    db 0,0,15,7,7,7,7,7,7,7,7,15,15,0,0,0
    db 0,0,15,7,7,7,7,7,7,7,7,15,15,0,0,0
    db 0,0,15,7,7,7,7,7,7,7,7,15,15,0,0,0
    db 0,0,15,7,7,7,7,7,7,7,7,15,15,0,0,0
    db 0,0,15,7,7,7,7,7,7,7,7,15,15,0,0,0
    db 0,0,15,7,7,7,7,7,7,7,7,15,15,0,0,0
    db 0,0,15,7,7,7,7,7,7,7,7,15,15,0,0,0
    db 0,0,15,7,7,7,7,7,7,7,7,15,15,0,0,0
    db 0,0,15,7,7,7,7,7,7,7,7,15,15,0,0,0
    db 0,0,15,7,7,7,7,7,7,7,7,15,15,0,0,0
    db 0,0,15,15,15,15,15,15,15,15,15,15,15,0,0,0
    db 0,0,15,15,15,15,15,15,15,15,15,15,15,0,0,0
    db 0,0,0,15,15,15,15,15,15,15,15,15,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

; Структура иконки на рабочем столе
struc desktop_icon
    .x:      resw 1    ; X координата
    .y:      resw 1    ; Y координата
    .type:   resb 1    ; Тип иконки (0 = папка, 1 = файл)
    .name:   resb 12   ; Имя иконки (11 символов + null)
    .size:   resb 0
endstruc

; Массив иконок на рабочем столе
desktop_icons:
    ; Иконка 1 - папка "Documents"
    istruc desktop_icon
        at desktop_icon.x,    dw 20
        at desktop_icon.y,    dw 20
        at desktop_icon.type, db 0
        at desktop_icon.name, db 'Documents', 0, 0, 0, 0
    iend
    
    ; Иконка 2 - файл "README"
    istruc desktop_icon
        at desktop_icon.x,    dw 20
        at desktop_icon.y,    dw 60
        at desktop_icon.type, db 1
        at desktop_icon.name, db 'README', 0, 0, 0, 0, 0, 0
    iend

num_icons dw 2  ; Количество иконок

section .text
; Функция отрисовки иконки
; Вход:
;   ax = x координата
;   bx = y координата
;   cl = тип иконки (0 = папка, 1 = файл)
draw_icon:
    push es
    push di
    push si
    push dx
    push cx
    push bx
    push ax
    
    ; Настройка сегмента видеопамяти
    mov dx, 0xA000
    mov es, dx
    
    ; Вычисляем позицию в видеопамяти
    mov di, bx          ; Y координата
    mov dx, 320
    mul dx              ; ax = y * 320
    add di, ax          ; di = y * 320 + x
    
    ; Выбираем источник данных иконки
    test cl, cl         ; Проверяем тип иконки
    jz .folder_icon
    mov si, file_icon
    jmp .draw
.folder_icon:
    mov si, folder_icon
    
.draw:
    ; Рисуем иконку 16x16
    mov dx, 16          ; Высота иконки
.draw_row:
    mov cx, 16          ; Ширина иконки
    push di
.draw_pixel:
    lodsb               ; Загружаем цвет пикселя
    test al, al         ; Если цвет 0, пропускаем (прозрачность)
    jz .skip_pixel
    mov [es:di], al     ; Рисуем пиксель
.skip_pixel:
    inc di
    loop .draw_pixel
    
    pop di
    add di, 320         ; Следующая строка
    dec dx
    jnz .draw_row
    
    pop ax
    pop bx
    pop cx
    pop dx
    pop si
    pop di
    pop es
    ret

; Функция отрисовки текста под иконкой
; Вход:
;   ax = x координата
;   bx = y координата
;   si = указатель на строку
draw_icon_text:
    push es
    push di
    push si
    push dx
    push cx
    push bx
    push ax
    
    ; Настройка сегмента видеопамяти
    mov dx, 0xA000
    mov es, dx
    
    ; Вычисляем позицию в видеопамяти (16 пикселей ниже иконки)
    add bx, 18          ; Y координата текста
    mov di, bx
    mov dx, 320
    mul dx
    add di, ax
    
    ; Рисуем текст белым цветом
    mov ah, 0x0E        ; Функция телетайпа BIOS
    mov bl, 15          ; Белый цвет
.draw_char:
    lodsb               ; Загружаем символ
    test al, al         ; Проверяем конец строки
    jz .done
    int 0x10            ; Вызов BIOS для вывода символа
    jmp .draw_char
    
.done:
    pop ax
    pop bx
    pop cx
    pop dx
    pop si
    pop di
    pop es
    ret

; Функция отрисовки всех иконок
draw_all_icons:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push si
    
    mov si, desktop_icons
    mov cx, [num_icons]
    
.draw_next:
    ; Загружаем координаты и тип иконки
    mov ax, [si + desktop_icon.x]
    mov bx, [si + desktop_icon.y]
    mov cl, [si + desktop_icon.type]
    
    ; Рисуем иконку
    call draw_icon
    
    ; Рисуем текст
    lea dx, [si + desktop_icon.name]
    push si
    mov si, dx
    call draw_icon_text
    pop si
    
    ; Переходим к следующей иконке
    add si, desktop_icon.size
    loop .draw_next
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret
