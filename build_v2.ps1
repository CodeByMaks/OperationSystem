# Пути к инструментам
$NASM = "nasm"
$QEMU = "C:\Program Files\qemu\qemu-system-x86_64.exe"  # Измените путь, если QEMU установлен в другом месте
$BUILD_DIR = "build"
$SRC_DIR = "src"

# Создаем директорию сборки, если она не существует
if (-not (Test-Path $BUILD_DIR)) {
    New-Item -ItemType Directory -Path $BUILD_DIR | Out-Null
}

# Проверяем наличие QEMU
if (-not (Test-Path $QEMU)) {
    Write-Error "QEMU не найден по пути $QEMU. Пожалуйста, установите QEMU или укажите правильный путь."
    exit 1
}

# Компилируем загрузчик
Write-Host "Компиляция boot.asm..."
& $NASM -f bin -I "$SRC_DIR" "$SRC_DIR/boot/boot.asm" -o "$BUILD_DIR/boot.bin"
if (-not $?) {
    Write-Error "Ошибка при компиляции boot.asm"
    exit 1
}

# Компилируем ядро со всеми включенными модулями
Write-Host "Компиляция kernel.asm..."
& $NASM -f bin -I "$SRC_DIR" "$SRC_DIR/kernel/kernel.asm" -o "$BUILD_DIR/kernel.bin"
if (-not $?) {
    Write-Error "Ошибка при компиляции kernel.asm"
    exit 1
}

# Компилируем модуль GUI
Write-Host "Компиляция gui.asm..."
& $NASM -f bin -I "$SRC_DIR" "$SRC_DIR/gui/gui.asm" -o "$BUILD_DIR/gui.bin"
if (-not $?) {
    Write-Error "Ошибка при компиляции gui.asm"
    exit 1
}

# Компилируем модуль клавиатуры
Write-Host "Компиляция keyboard.asm..."
& $NASM -f bin -I "$SRC_DIR" "$SRC_DIR/drivers/keyboard.asm" -o "$BUILD_DIR/keyboard.bin"
if (-not $?) {
    Write-Error "Ошибка при компиляции keyboard.asm"
    exit 1
}

# Компилируем модуль видео
Write-Host "Компиляция video.asm..."
& $NASM -f bin -I "$SRC_DIR" "$SRC_DIR/drivers/video.asm" -o "$BUILD_DIR/video.bin"
if (-not $?) {
    Write-Error "Ошибка при компиляции video.asm"
    exit 1
}

# Создаем образ системы
Write-Host "Создание образа системы..."
& .\create_image_v3.ps1
if (-not $?) {
    Write-Error "Ошибка при создании образа системы"
    exit 1
}

# Проверяем, что образ создан
$imagePath = Join-Path $BUILD_DIR "os.img"
if (-not (Test-Path $imagePath)) {
    Write-Error "Образ системы не был создан по пути $imagePath"
    exit 1
}

# Запускаем QEMU
Write-Host "Запуск QEMU..."
& $QEMU -fda $imagePath
