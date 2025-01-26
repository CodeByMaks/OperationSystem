; Конфигурация проекта HeroX OS

; Системные константы
SYS_VERSION     equ '1.1'
BOOT_DRIVE      equ 0x00
KERNEL_SEGMENT  equ 0x1000
KERNEL_OFFSET   equ 0x0000
STACK_SEGMENT   equ 0x0000
STACK_OFFSET    equ 0xFFFF

; Размеры буферов
SECTOR_SIZE     equ 512
MAX_SECTORS     equ 18
BUFFER_SIZE     equ 8192
KEYBOARD_BUFFER_SIZE equ 32     ; Размер буфера клавиатуры
COMMAND_BUFFER_SIZE  equ 256    ; Размер буфера команд

; Константы для видеорежима
GUI_MODE        equ 0x13    ; 320x200, 256 цветов
SCREEN_WIDTH    equ 320     ; Ширина экрана в пикселях
SCREEN_HEIGHT   equ 200     ; Высота экрана в пикселях

; Цвета
COLOR_BLACK     equ 0x00
COLOR_BLUE      equ 0x01
COLOR_GREEN     equ 0x02
COLOR_CYAN      equ 0x03
COLOR_RED       equ 0x04
COLOR_MAGENTA   equ 0x05
COLOR_BROWN     equ 0x06
COLOR_LGRAY     equ 0x07
COLOR_DGRAY     equ 0x08
COLOR_LBLUE     equ 0x09
COLOR_LGREEN    equ 0x0A
COLOR_LCYAN     equ 0x0B
COLOR_LRED      equ 0x0C
COLOR_LMAGENTA  equ 0x0D
COLOR_YELLOW    equ 0x0E
COLOR_WHITE     equ 0x0F

; Константы для окон
WINDOW_BORDER_SIZE  equ 1       ; Толщина рамки окна
WINDOW_TITLE_HEIGHT equ 14      ; Высота заголовка окна
WINDOW_MIN_WIDTH    equ 50      ; Минимальная ширина окна
WINDOW_MIN_HEIGHT   equ 30      ; Минимальная высота окна
MAX_WINDOWS         equ 10      ; Максимальное количество окон

; Кнопки управления окном
WINDOW_BTN_WIDTH    equ 12      ; Ширина кнопки управления
WINDOW_BTN_HEIGHT   equ 12      ; Высота кнопки управления
WINDOW_BTN_SPACING  equ 2       ; Расстояние между кнопками
WINDOW_BTN_MARGIN   equ 2       ; Отступ от края окна

; Константы для изменения размера окна
RESIZE_BORDER_SIZE  equ 4       ; Размер области для изменения размера
RESIZE_CORNER_SIZE  equ 8       ; Размер угла для изменения размера

; Константы для прокрутки
SCROLL_BAR_WIDTH    equ 16      ; Ширина полосы прокрутки
SCROLL_BTN_HEIGHT   equ 16      ; Высота кнопок прокрутки
SCROLL_MIN_THUMB    equ 20      ; Минимальный размер ползунка

; Константы для панели задач
TASKBAR_HEIGHT      equ 20      ; Высота панели задач
TASKBAR_BUTTON_WIDTH equ 50     ; Ширина кнопки на панели задач

; Константы для мыши
MOUSE_LEFT_BUTTON   equ 0x01
MOUSE_RIGHT_BUTTON  equ 0x02
MOUSE_MIDDLE_BUTTON equ 0x04

; Флаги состояния системы
SYS_FLAG_GUI_ACTIVE equ 0x01    ; GUI активен
SYS_FLAG_MOUSE_INIT equ 0x02    ; Мышь инициализирована

; Флаги состояния окна
WINDOW_FLAG_NORMAL    equ 0x00  ; Обычное состояние
WINDOW_FLAG_MAXIMIZED equ 0x01  ; Развернуто
WINDOW_FLAG_MINIMIZED equ 0x02  ; Свернуто
WINDOW_FLAG_DRAGGING  equ 0x04  ; Перетаскивается
WINDOW_FLAG_RESIZING  equ 0x08  ; Изменяется размер

; Флаги области изменения размера
RESIZE_NONE   equ 0x00
RESIZE_LEFT   equ 0x01
RESIZE_RIGHT  equ 0x02
RESIZE_TOP    equ 0x04
RESIZE_BOTTOM equ 0x08
RESIZE_TL     equ RESIZE_TOP | RESIZE_LEFT
RESIZE_TR     equ RESIZE_TOP | RESIZE_RIGHT
RESIZE_BL     equ RESIZE_BOTTOM | RESIZE_LEFT
RESIZE_BR     equ RESIZE_BOTTOM | RESIZE_RIGHT

; Константы для управления процессами
MAX_PROCESSES         equ 16    ; Максимальное количество процессов
PROCESS_ENTRY_SIZE    equ 32    ; Размер записи о процессе
PROCESS_STATE_FREE    equ 0     ; Процесс свободен
PROCESS_STATE_READY   equ 1     ; Процесс готов к выполнению
PROCESS_STATE_RUNNING equ 2     ; Процесс выполняется
PROCESS_STATE_BLOCKED equ 3     ; Процесс заблокирован

; Типы диалоговых окон
DIALOG_OK           equ 0       ; Диалог с кнопкой OK
DIALOG_OK_CANCEL    equ 1       ; Диалог с кнопками OK и Cancel
DIALOG_YES_NO       equ 2       ; Диалог с кнопками Yes и No
DIALOG_YES_NO_CANCEL equ 3      ; Диалог с кнопками Yes, No и Cancel

; Идентификаторы кнопок окна
BTN_CLOSE      equ 0x01
BTN_MAXIMIZE   equ 0x02
BTN_MINIMIZE   equ 0x03
BTN_RESTORE    equ 0x04

; Флаги системы
USE_GUI         equ 1       ; 1 = использовать графический режим
DEBUG_MODE      equ 0       ; 1 = включить отладочные сообщения
