# Пути к инструментам
$NASM = "nasm"
$QEMU = "C:\Program Files\qemu\qemu-system-x86_64.exe"  # Измените путь, если QEMU установлен в другом месте

# Проверяем наличие QEMU
if (-not (Test-Path $QEMU)) {
    Write-Error "QEMU не найден по пути $QEMU. Пожалуйста, установите QEMU или укажите правильный путь."
    exit 1
}

# Компилируем загрузчик
Write-Host "Компиляция boot.asm..."
& $NASM -f bin boot.asm -o boot.bin
if (-not $?) {
    Write-Error "Ошибка при компиляции boot.asm"
    exit 1
}

# Компилируем ядро
Write-Host "Компиляция kernel.asm..."
& $NASM -f bin kernel.asm -o kernel.bin
if (-not $?) {
    Write-Error "Ошибка при компиляции kernel.asm"
    exit 1
}

# Компилируем драйверы
Write-Host "Компиляция драйверов..."
& $NASM -f bin keyboard.asm -o keyboard.bin
if (-not $?) {
    Write-Error "Ошибка при компиляции keyboard.asm"
    exit 1
}
& $NASM -f bin video.asm -o video.bin
if (-not $?) {
    Write-Error "Ошибка при компиляции video.asm"
    exit 1
}

# Создаем образ диска
Write-Host "Создание образа диска..."

# Создаем пустой образ размером 1.44 MB
$imageSize = 1474560
$buffer = New-Object byte[] $imageSize
[System.IO.File]::WriteAllBytes("os.img", $buffer)

# Копируем загрузчик
$bootloader = [System.IO.File]::ReadAllBytes("boot.bin")
[System.IO.File]::WriteAllBytes("os.img", $bootloader)

# Копируем ядро, начиная со второго сектора
$kernel = [System.IO.File]::ReadAllBytes("kernel.bin")
$keyboard = [System.IO.File]::ReadAllBytes("keyboard.bin")
$video = [System.IO.File]::ReadAllBytes("video.bin")

# Объединяем все компоненты
$components = $kernel + $keyboard + $video
[System.IO.File]::WriteAllBytes("os.img", [byte[]]@([System.IO.File]::ReadAllBytes("os.img")[0..511] + $components))

# Запускаем в QEMU
Write-Host "Запуск в QEMU..."
& $QEMU -fda os.img -boot a
