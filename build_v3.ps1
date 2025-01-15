# Пути к инструментам
$NASM = "nasm"
$QEMU = "C:\Program Files\qemu\qemu-system-x86_64.exe"

# Компилируем загрузчик
Write-Host "Компиляция boot.asm..."
& $NASM -f bin boot.asm -o boot.bin
if (-not $?) {
    Write-Error "Ошибка при компиляции boot.asm"
    exit 1
}

# Компилируем ядро
Write-Host "Компиляция kernel.asm..."
& $NASM -f bin kernel.asm -I ./ -o kernel.bin
if (-not $?) {
    Write-Error "Ошибка при компиляции kernel.asm"
    exit 1
}

# Создаем образ диска
Write-Host "Создание образа диска..."
& .\create_image_v3.ps1

# Запускаем в QEMU
Write-Host "Запуск в QEMU..."
& $QEMU -fda os.img -boot a
