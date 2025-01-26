# Скрипт сборки HeroX OS

# Параметры сборки
$BUILD_DIR = "../build"
$SRC_DIR = "../src"
$NASM = "nasm"
$QEMU = "qemu-system-i386"

# Очистка build директории
Write-Host "Очистка build директории..."
if (Test-Path $BUILD_DIR) {
    Remove-Item -Path "$BUILD_DIR/*" -Recurse -Force
}
else {
    New-Item -ItemType Directory -Path $BUILD_DIR
}

# Компиляция загрузчика
Write-Host "Компиляция boot.asm..."
& $NASM -f bin "$SRC_DIR/boot/boot.asm" -o "$BUILD_DIR/boot.bin"
if (-not $?) {
    Write-Error "Ошибка при компиляции boot.asm"
    exit 1
}

# Компиляция ядра
Write-Host "Компиляция kernel.asm..."
& $NASM -f bin "$SRC_DIR/kernel/kernel.asm" -o "$BUILD_DIR/kernel.bin"
if (-not $?) {
    Write-Error "Ошибка при компиляции kernel.asm"
    exit 1
}

# Создание образа диска
Write-Host "Создание образа диска..."
$imageSize = 1474560
$image = New-Object byte[] $imageSize
[System.IO.File]::WriteAllBytes("$BUILD_DIR/os.img", $image)

# Копируем загрузчик
$bootSector = [System.IO.File]::ReadAllBytes("$BUILD_DIR/boot.bin")
[System.IO.File]::WriteAllBytes("$BUILD_DIR/os.img", $bootSector + $image[$bootSector.Length..($imageSize-1)])

# Копируем ядро
$kernel = [System.IO.File]::ReadAllBytes("$BUILD_DIR/kernel.bin")
$image = [System.IO.File]::ReadAllBytes("$BUILD_DIR/os.img")
[Array]::Copy($kernel, 0, $image, 512, $kernel.Length)
[System.IO.File]::WriteAllBytes("$BUILD_DIR/os.img", $image)

Write-Host "Сборка завершена успешно!"

# Запуск в QEMU
Write-Host "Запуск в QEMU..."
& $QEMU -fda "$BUILD_DIR/os.img"
