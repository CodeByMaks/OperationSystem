; Конфигурационные константы

; Системные константы
SCREEN_WIDTH     equ 320
SCREEN_HEIGHT    equ 200
GUI_MODE         equ 0x13    ; 320x200, 256 цветов
SCREEN_SEGMENTS  equ 0xA000

; Сегменты памяти
KERNEL_SEGMENT   equ 0x1000

; Цвета интерфейса
COLOR_BLACK      equ 0x00
COLOR_BLUE       equ 0x01
COLOR_GREEN      equ 0x02
COLOR_CYAN       equ 0x03
COLOR_RED        equ 0x04
COLOR_MAGENTA    equ 0x05
COLOR_BROWN      equ 0x06
COLOR_LIGHTGRAY  equ 0x07
COLOR_DARKGRAY   equ 0x08
COLOR_LIGHTBLUE  equ 0x09
COLOR_LIGHTGREEN equ 0x0A
COLOR_LIGHTCYAN  equ 0x0B
COLOR_LIGHTRED   equ 0x0C
COLOR_PINK       equ 0x0D
COLOR_YELLOW     equ 0x0E
COLOR_WHITE      equ 0x0F

; Настройки рабочего стола
DESKTOP_COLOR    equ COLOR_BLUE
TASKBAR_HEIGHT   equ 20
TASKBAR_COLOR    equ COLOR_LIGHTGRAY

; Настройки окон
WINDOW_BORDER_COLOR      equ COLOR_WHITE
WINDOW_TITLEBAR_COLOR   equ COLOR_DARKGRAY
WINDOW_TITLEBAR_HEIGHT  equ 18
WINDOW_MIN_WIDTH       equ 100
WINDOW_MIN_HEIGHT      equ 80
WINDOW_BUTTON_WIDTH    equ 16
WINDOW_BUTTON_HEIGHT   equ 14

; Настройки иконок
ICON_SIZE       equ 16    ; Размер иконки в пикселях
ICON_SPACING     equ 48
ICON_TEXT_COLOR  equ COLOR_WHITE
ICON_TEXT_BG     equ COLOR_BLUE

; Настройки меню
MENU_BG_COLOR    equ COLOR_LIGHTGRAY
MENU_TEXT_COLOR  equ COLOR_BLACK
MENU_BORDER_COLOR equ COLOR_DARKGRAY
MENU_ITEM_HEIGHT equ 20

; Настройки курсора
CURSOR_WIDTH     equ 16
CURSOR_HEIGHT    equ 16
CURSOR_COLOR     equ COLOR_WHITE

; Системные сообщения
MAX_MSG_LENGTH   equ 256

; Максимальные значения
MAX_WINDOWS      equ 10
MAX_ICONS        equ 20
MAX_MENU_ITEMS   equ 15

; Константы для шрифта
FONT_HEIGHT         equ 8
FONT_WIDTH          equ 8

; Константы для процессов
MAX_PROCESSES       equ 16
PROCESS_ENTRY_SIZE  equ 32
PROCESS_STATE_INACTIVE equ 0
PROCESS_STATE_ACTIVE  equ 1
PROCESS_STATE_BLOCKED equ 2

; Константы для памяти
MEMORY_START        equ 0x1000
MEMORY_SIZE         equ 0xF000
MAX_MEMORY_BLOCKS   equ 256

; Константы для файловой системы
SECTOR_SIZE         equ 512
MAX_FILE_SIZE       equ 65535
MAX_FILES           equ 64
MAX_FILENAME_LENGTH equ 12
