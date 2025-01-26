# Пути к инструментам
$NASM = "C:\Program Files\NASM\nasm.exe"

# Создаем директорию сборки
$BUILD_DIR = "build"
if (-not (Test-Path $BUILD_DIR)) {
    New-Item -ItemType Directory -Path $BUILD_DIR | Out-Null
}

# Компилируем все модули
Write-Host "Компиляция модулей..."

# GUI модули
& $NASM -f bin -i ".\src" ".\src\gui\desktop.asm" -o "$BUILD_DIR/desktop.bin"
& $NASM -f bin -i ".\src" ".\src\gui\window_system.asm" -o "$BUILD_DIR/window_system.bin"
& $NASM -f bin -i ".\src" ".\src\gui\graphics.asm" -o "$BUILD_DIR/graphics.bin"
& $NASM -f bin -i ".\src" ".\src\gui\icons.asm" -o "$BUILD_DIR/icons.bin"

# Драйверы
& $NASM -f bin -i ".\src" ".\src\drivers\mouse_driver.asm" -o "$BUILD_DIR/mouse_driver.bin"

# Компилируем ядро
Write-Host "Компиляция kernel.asm..."
& $NASM -f bin -i ".\src" ".\src\kernel\kernel.asm" -o "$BUILD_DIR/kernel.bin"
if (-not $?) {
    Write-Error "Ошибка при компиляции kernel.asm"
    exit 1
}

# Компилируем загрузчик
Write-Host "Компиляция boot.asm..."
& $NASM -f bin -i ".\src" ".\src\boot\boot.asm" -o "$BUILD_DIR/boot.bin"
if (-not $?) {
    Write-Error "Ошибка при компиляции boot.asm"
    exit 1
}

# Создаем образ ОС
Write-Host "Создание образа ОС..."

# Удаляем старый образ если он существует
if (Test-Path "$BUILD_DIR/os.img") {
    Remove-Item "$BUILD_DIR/os.img" -Force
}

# Создаем пустой образ размером 1.44MB
$imageSize = 1474560
$nullBytes = New-Object byte[] $imageSize
[System.IO.File]::WriteAllBytes("$BUILD_DIR/os.img", $nullBytes)

# Читаем все бинарные файлы
$bootSector = [System.IO.File]::ReadAllBytes("$BUILD_DIR/boot.bin")
$kernel = [System.IO.File]::ReadAllBytes("$BUILD_DIR/kernel.bin")
$desktop = [System.IO.File]::ReadAllBytes("$BUILD_DIR/desktop.bin")
$windowSystem = [System.IO.File]::ReadAllBytes("$BUILD_DIR/window_system.bin")
$graphics = [System.IO.File]::ReadAllBytes("$BUILD_DIR/graphics.bin")
$icons = [System.IO.File]::ReadAllBytes("$BUILD_DIR/icons.bin")
$mouseDriver = [System.IO.File]::ReadAllBytes("$BUILD_DIR/mouse_driver.bin")

# Проверяем размер загрузочного сектора
if ($bootSector.Length -gt 512) {
    Write-Error "Загрузчик превышает размер сектора (512 байт)"
    exit 1
}

# Создаем итоговый массив байтов
$image = New-Object byte[] $imageSize

# Копируем загрузочный сектор
[Array]::Copy($bootSector, 0, $image, 0, $bootSector.Length)

# Копируем ядро
[Array]::Copy($kernel, 0, $image, 512, $kernel.Length)

# Копируем модули
$offset = 2048 # После ядра

# Desktop
[Array]::Copy($desktop, 0, $image, $offset, $desktop.Length)
$offset += [Math]::Ceiling($desktop.Length / 512.0) * 512

# Window System
[Array]::Copy($windowSystem, 0, $image, $offset, $windowSystem.Length)
$offset += [Math]::Ceiling($windowSystem.Length / 512.0) * 512

# Graphics
[Array]::Copy($graphics, 0, $image, $offset, $graphics.Length)
$offset += [Math]::Ceiling($graphics.Length / 512.0) * 512

# Icons
[Array]::Copy($icons, 0, $image, $offset, $icons.Length)
$offset += [Math]::Ceiling($icons.Length / 512.0) * 512

# Mouse Driver
[Array]::Copy($mouseDriver, 0, $image, $offset, $mouseDriver.Length)

# Записываем образ
[System.IO.File]::WriteAllBytes("$BUILD_DIR/os.img", $image)

Write-Host "os.img создан, размер: $((Get-Item "$BUILD_DIR/os.img").Length) байт"
