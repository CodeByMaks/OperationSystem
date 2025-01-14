# Пытаемся найти NASM в разных местах
$nasmPaths = @(
    "C:\Program Files\NASM\nasm.exe",
    "C:\Program Files (x86)\NASM\nasm.exe",
    "nasm.exe"  # если NASM в PATH
)

$NASM = $null
foreach ($path in $nasmPaths) {
    if (Get-Command $path -ErrorAction SilentlyContinue) {
        $NASM = $path
        break
    }
}

if ($null -eq $NASM) {
    Write-Error "NASM не найден. Пожалуйста, установите NASM и добавьте его в PATH"
    exit 1
}

# Пытаемся найти QEMU в разных местах
$qemuPaths = @(
    "C:\Program Files\qemu\qemu-system-x86_64.exe",
    "C:\Program Files (x86)\qemu\qemu-system-x86_64.exe",
    "qemu-system-x86_64.exe"  # если QEMU в PATH
)

$QEMU = $null
foreach ($path in $qemuPaths) {
    if (Get-Command $path -ErrorAction SilentlyContinue) {
        $QEMU = $path
        break
    }
}

if ($null -eq $QEMU) {
    Write-Error "QEMU не найден. Пожалуйста, установите QEMU и добавьте его в PATH"
    exit 1
}

# Компилируем загрузчик
Write-Host "Компиляция boot.asm..."
& $NASM -f bin boot.asm -o boot.bin

if (-not $?) {
    Write-Error "Ошибка при компиляции boot.asm"
    exit 1
}

# Создаем пустой образ размером 1.44 MB
Write-Host "Создание образа диска..."
$imageSize = 1474560
$buffer = New-Object byte[] $imageSize
[System.IO.File]::WriteAllBytes("os.img", $buffer)

# Копируем загрузчик в начало образа
$bootloader = [System.IO.File]::ReadAllBytes("boot.bin")
[System.IO.File]::WriteAllBytes("os.img", $bootloader + $buffer[$bootloader.Length..($imageSize-1)])

# Запускаем в QEMU
Write-Host "Запуск в QEMU..."
& $QEMU -fda os.img
