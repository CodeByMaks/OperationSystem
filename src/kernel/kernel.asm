[bits 16]
[org 0x0000]      ; Загружаемся по адресу 0x1000:0x0000

section .text
    global _start

_start:
    ; Настройка сегментов
    mov ax, cs
    mov ds, ax
    mov es, ax
    
    ; Настройка стека
    mov ax, 0x2000
    mov ss, ax
    mov sp, 0xFFFF
    
    ; Очистка экрана (текстовый режим)
    mov ax, 0x0003  ; 80x25 текстовый режим
    int 0x10
    
    ; Вывод сообщения
    mov si, msg_start
    call print_string
    
    ; Ждем нажатия клавиши
    mov ah, 0
    int 0x16
    
    ; Переключаемся в графический режим
    mov ax, 0x0013  ; 320x200, 256 цветов
    int 0x10
    
    ; Заполняем экран темно-синим цветом
    mov ax, 0xA000
    mov es, ax
    xor di, di
    mov cx, 64000   ; 320*200 пикселей
    mov al, 1       ; Темно-синий цвет
    rep stosb

main_loop:
    ; Очищаем старый курсор
    call clear_cursor
    
    ; Проверяем клавиши управления курсором
    call check_keyboard
    
    ; Проверяем нажатие Enter
    call check_enter
    
    ; Рисуем прямоугольник с рамкой
    call draw_window
    
    ; Рисуем иконки
    call draw_desktop_icons
    
    ; Рисуем курсор
    call draw_cursor
    
    ; Задержка
    mov cx, 0x1FFF
    call delay
    
    ; Изменяем цвет рамки
    inc byte [border_color]
    and byte [border_color], 0x0F
    
    ; Проверяем нажатие клавиши ESC для выхода
    mov ah, 1
    int 0x16
    jz .continue
    
    mov ah, 0
    int 0x16
    cmp al, 27
    je exit_to_dos
    
.continue:
    jmp main_loop

; Проверка клавиатуры и обновление позиции курсора
check_keyboard:
    push ax
    push bx
    
    mov ah, 1       ; Проверяем буфер клавиатуры
    int 0x16
    jz .done        ; Если нет нажатия - выходим
    
    mov ah, 0       ; Получаем код клавиши
    int 0x16
    
    cmp ah, 48h     ; Вверх
    je .up
    cmp ah, 50h     ; Вниз
    je .down
    cmp ah, 4Bh     ; Влево
    je .left
    cmp ah, 4Dh     ; Вправо
    je .right
    jmp .done
    
.up:
    mov ax, [cursor_y]
    sub ax, 5       ; Шаг движения
    cmp ax, 0
    jl .done
    mov [cursor_y], ax
    jmp .done
    
.down:
    mov ax, [cursor_y]
    add ax, 5       ; Шаг движения
    cmp ax, 195     ; Максимальная Y координата
    jg .done
    mov [cursor_y], ax
    jmp .done
    
.left:
    mov ax, [cursor_x]
    sub ax, 5       ; Шаг движения
    cmp ax, 0
    jl .done
    mov [cursor_x], ax
    jmp .done
    
.right:
    mov ax, [cursor_x]
    add ax, 5       ; Шаг движения
    cmp ax, 315     ; Максимальная X координата
    jg .done
    mov [cursor_x], ax
    
.done:
    pop bx
    pop ax
    ret

; Проверка нажатия Enter и взаимодействия с иконками
check_enter:
    push ax
    push bx
    push cx
    push dx
    
    ; Проверяем, есть ли нажатие клавиши
    mov ah, 1
    int 0x16
    jz .done
    
    ; Получаем код клавиши
    mov ah, 0
    int 0x16
    
    ; Проверяем, является ли это Enter (код 0x1C)
    cmp ah, 0x1C
    jne .done
    
    ; Визуальная индикация нажатия Enter - изменим цвет фона
    mov ax, 0xA000
    mov es, ax
    mov di, 0
    mov cx, 1000
    mov al, 2  ; Зеленый цвет
    rep stosb
    
    ; Отображаем координаты курсора в верхнем правом углу
    mov ax, [cursor_x]
    mov bx, [cursor_y]
    
    ; Сохраняем координаты для проверки
    push ax
    push bx
    
    ; Выводим X координату
    mov ah, 0x0E
    mov al, 'X'
    int 0x10
    mov al, ':'
    int 0x10
    
    pop bx  ; Восстанавливаем Y
    pop ax  ; Восстанавливаем X
    
    ; Преобразуем X в десятичное число и выводим
    push bx
    mov bx, 10
    mov cx, 0
.convert_x:
    mov dx, 0
    div bx
    push dx
    inc cx
    test ax, ax
    jnz .convert_x
.print_x:
    pop dx
    add dl, '0'
    mov ah, 0x0E
    mov al, dl
    int 0x10
    loop .print_x
    
    ; Пробел между координатами
    mov ah, 0x0E
    mov al, ' '
    int 0x10
    
    ; Выводим Y координату
    mov al, 'Y'
    int 0x10
    mov al, ':'
    int 0x10
    
    pop ax  ; Восстанавливаем Y в ax
    
    ; Преобразуем Y в десятичное число и выводим
    mov bx, 10
    mov cx, 0
.convert_y:
    mov dx, 0
    div bx
    push dx
    inc cx
    test ax, ax
    jnz .convert_y
.print_y:
    pop dx
    add dl, '0'
    mov ah, 0x0E
    mov al, dl
    int 0x10
    loop .print_y
    
    ; Восстанавливаем координаты для проверки
    mov ax, [cursor_x]
    mov bx, [cursor_y]
    
    ; Обновленные координаты на основе реальной позиции курсора
    ; Проверяем X координату (90 <= x <= 120)
    cmp ax, 90
    jl .done
    cmp ax, 120
    jg .done
    
    ; Проверяем Y координату (20 <= y <= 30)
    cmp bx, 20
    jl .done
    cmp bx, 30
    jg .done
    
    ; Визуальная индикация успешного попадания в зону иконки
    mov ax, 0xA000
    mov es, ax
    mov di, 0
    mov cx, 1000
    mov al, 4  ; Красный цвет
    rep stosb
    
    ; Задержка перед выходом
    mov cx, 0xFFFF
.delay:
    loop .delay
    
    ; Если курсор над иконкой Shutdown, выходим в DOS
    jmp exit_to_dos
    
.done:
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Очистка курсора
clear_cursor:
    push ax
    push bx
    push cx
    push dx
    push di
    push es
    
    mov ax, 0xA000
    mov es, ax
    
    ; Вычисляем позицию в видеопамяти
    mov ax, [cursor_y]
    mov bx, 320
    mul bx
    add ax, [cursor_x]
    mov di, ax
    
    ; Очищаем область курсора (5x5 пикселей)
    mov al, 1       ; Цвет фона
    mov dx, 5       ; Высота курсора
.clear_loop_y:
    mov cx, 5       ; Ширина курсора
    push di
.clear_loop_x:
    mov [es:di], al
    inc di
    loop .clear_loop_x
    pop di
    add di, 320     ; Следующая строка
    dec dx
    jnz .clear_loop_y
    
    pop es
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Рисование курсора
draw_cursor:
    push ax
    push bx
    push cx
    push dx
    push di
    push es
    
    mov ax, 0xA000
    mov es, ax
    
    ; Вычисляем позицию в видеопамяти
    mov ax, [cursor_y]
    mov bx, 320
    mul bx
    add ax, [cursor_x]
    mov di, ax
    
    ; Рисуем курсор (5x5 пикселей)
    mov al, 15      ; Белый цвет
    mov dx, 5       ; Высота курсора
.draw_loop_y:
    mov cx, 5       ; Ширина курсора
    push di
.draw_loop_x:
    mov [es:di], al
    inc di
    loop .draw_loop_x
    pop di
    add di, 320     ; Следующая строка
    dec dx
    jnz .draw_loop_y
    
    pop es
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Рисование окна с рамкой
draw_window:
    push bp
    mov bp, sp
    
    ; Сохраняем регистры
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    mov ax, 0xA000
    mov es, ax
    
    ; Рисуем рамку
    mov di, 100*320 + 159  ; На 1 пиксель левее и выше прямоугольника
    mov al, [border_color] ; Цвет рамки
    mov dx, 52            ; Высота рамки
.draw_border_v:
    mov [es:di], al      ; Левая вертикальная линия
    mov [es:di+102], al  ; Правая вертикальная линия
    add di, 320
    dec dx
    jnz .draw_border_v
    
    mov di, 99*320 + 159  ; Верхняя горизонтальная линия
    mov cx, 102
.draw_border_h1:
    mov [es:di], al
    inc di
    loop .draw_border_h1
    
    mov di, 151*320 + 159 ; Нижняя горизонтальная линия
    mov cx, 102
.draw_border_h2:
    mov [es:di], al
    inc di
    loop .draw_border_h2
    
    ; Рисуем белый прямоугольник
    mov di, 100*320 + 160
    mov dx, 50
.draw_rect:
    push di
    mov cx, 100
.draw_line:
    mov byte [es:di], 15  ; Белый цвет
    inc di
    loop .draw_line
    pop di
    add di, 320
    dec dx
    jnz .draw_rect
    
    ; Восстанавливаем регистры
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    
    pop bp
    ret

; Задержка (cx = количество итераций)
delay:
    push ax
.loop:
    nop
    nop
    nop
    nop
    loop .loop
    pop ax
    ret

; Вывод строки (DS:SI)
print_string:
    mov ah, 0x0E
    mov bx, 0x0007  ; Светло-серый цвет
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    ret

; Выход в DOS
exit_to_dos:
    ; Возврат в текстовый режим
    mov ax, 0x0003
    int 0x10
    
    ; Выход в DOS
    mov ah, 4Ch     ; Функция DOS - завершение программы
    int 21h         ; DOS - системное прерывание

; Функция отрисовки иконки
; Вход:
;   ax = x координата
;   bx = y координата
;   si = указатель на данные иконки
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
    
    ; Вычисляем позицию в видеопамяти
    add bx, 18          ; Сдвигаем текст на 18 пикселей ниже иконки
    mov di, bx
    mov dx, 320
    mul dx              ; ax = y * 320
    add di, ax          ; di = y * 320 + x
    
    ; Сохраняем начальную позицию
    push di
    
    ; Очищаем область текста (высота 8 пикселей)
    mov dx, 8           ; Высота текста
.clear_text_area:
    mov cx, 64          ; Ширина области (8 символов * 8 пикселей)
    push di
.clear_pixel:
    mov byte [es:di], 1 ; Темно-синий цвет фона
    inc di
    loop .clear_pixel
    pop di
    add di, 320         ; Следующая строка
    dec dx
    jnz .clear_text_area
    
    ; Восстанавливаем начальную позицию
    pop di
    
    ; Рисуем текст
.next_char:
    lodsb               ; Загружаем символ
    test al, al         ; Проверяем конец строки
    jz .done
    
    ; Рисуем символ (простой прямоугольник 4x6 пикселей)
    push di
    mov dx, 6           ; Высота символа
.draw_char_row:
    mov cx, 4           ; Ширина символа
    push di
.draw_char_pixel:
    mov byte [es:di], 15 ; Белый цвет
    inc di
    loop .draw_char_pixel
    pop di
    add di, 320         ; Следующая строка
    dec dx
    jnz .draw_char_row
    pop di
    
    add di, 6           ; Пробел между символами
    jmp .next_char
    
.done:
    pop ax
    pop bx
    pop cx
    pop dx
    pop si
    pop di
    pop es
    ret

; Функция отрисовки всех иконок рабочего стола
draw_desktop_icons:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push si
    
    ; Рисуем иконку папки
    mov ax, 20          ; X координата
    mov bx, 20          ; Y координата
    mov si, folder_icon ; Данные иконки
    call draw_icon
    
    ; Рисуем текст "Documents"
    mov ax, 20
    mov bx, 20
    mov si, folder_name
    call draw_icon_text
    
    ; Рисуем иконку файла
    mov ax, 20
    mov bx, 60
    mov si, file_icon
    call draw_icon
    
    ; Рисуем текст "README"
    mov ax, 20
    mov bx, 60
    mov si, file_name
    call draw_icon_text
    
    ; Рисуем иконку выключения
    mov ax, 20          ; X координата
    mov bx, 100         ; Y координата
    mov si, shutdown_icon
    call draw_icon
    
    ; Рисуем рамку вокруг иконки выключения для визуализации зоны клика
    push es
    mov ax, 0xA000
    mov es, ax
    
    ; Верхняя линия
    mov di, 100
    mov dx, 320
    mov ax, 15
    mul dx
    add di, ax
    mov cx, 25
    mov al, 15  ; Белый цвет
    rep stosb
    
    ; Нижняя линия
    mov di, 120
    mov dx, 320
    mov ax, 15
    mul dx
    add di, ax
    mov cx, 25
    rep stosb
    
    ; Левая линия
    mov cx, 25
.draw_left:
    mov di, cx
    add di, 100
    mov dx, 320
    mov ax, 15
    mul dx
    add di, ax
    mov byte [es:di], 15
    loop .draw_left
    
    ; Правая линия
    mov cx, 25
.draw_right:
    mov di, cx
    add di, 100
    mov dx, 320
    mov ax, 40
    mul dx
    add di, ax
    mov byte [es:di], 15
    loop .draw_right
    
    pop es
    
    ; Рисуем текст "Shutdown"
    mov ax, 20
    mov bx, 100
    mov si, shutdown_name
    call draw_icon_text
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret

section .data
    msg_start db 'HeroX OS started. Press any key to enter graphics mode...', 13, 10
    db 'Use arrow keys to move cursor', 13, 10
    db 'Press ESC to exit', 13, 10, 0
    
    border_color db 9    ; Начальный цвет рамки
    cursor_x dw 160     ; Начальная X координата курсора
    cursor_y dw 100     ; Начальная Y координата курсора
    
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
    
    folder_name db 'Documents', 0
    file_name db 'README', 0
    
    ; Данные иконки выключения (16x16 пикселей)
    shutdown_icon:
        db 0,0,0,0,4,4,4,4,4,4,4,4,0,0,0,0
        db 0,0,0,4,4,4,4,4,4,4,4,4,4,0,0,0
        db 0,0,4,4,4,0,0,4,4,0,0,4,4,4,0,0
        db 0,4,4,4,0,0,0,4,4,0,0,0,4,4,4,0
        db 4,4,4,0,0,0,0,4,4,0,0,0,0,4,4,4
        db 4,4,0,0,0,0,0,4,4,0,0,0,0,0,4,4
        db 4,4,0,0,0,0,0,4,4,0,0,0,0,0,4,4
        db 4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
        db 4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
        db 4,4,0,0,0,0,0,4,4,0,0,0,0,0,4,4
        db 4,4,0,0,0,0,0,4,4,0,0,0,0,0,4,4
        db 4,4,4,0,0,0,0,4,4,0,0,0,0,4,4,4
        db 0,4,4,4,0,0,0,4,4,0,0,0,4,4,4,0
        db 0,0,4,4,4,0,0,4,4,0,0,4,4,4,0,0
        db 0,0,0,4,4,4,4,4,4,4,4,4,4,0,0,0
        db 0,0,0,0,4,4,4,4,4,4,4,4,0,0,0,0
    
    shutdown_name db 'Shutdown', 0
