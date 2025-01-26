# Путь к директории сборки
$BUILD_DIR = "build"

# Создаем директорию сборки, если она не существует
if (-not (Test-Path $BUILD_DIR)) {
    New-Item -ItemType Directory -Path $BUILD_DIR | Out-Null
}

# Создаем пустой образ диска размером 1.44 МБ
Write-Host "Создание образа диска..."
$imageSize = 1474560  # 1.44 MB
$image = [byte[]]::new($imageSize)

# Заполняем нулями
for ($i = 0; $i -lt $imageSize; $i++) {
    $image[$i] = 0
}

# Копируем загрузчик в первый сектор
Write-Host "Копирование загрузчика..."
$bootSector = [System.IO.File]::ReadAllBytes("$BUILD_DIR/boot.bin")
[Array]::Copy($bootSector, 0, $image, 0, $bootSector.Length)

# Компилируем и копируем ядро во второй сектор
Write-Host "Компиляция ядра..."
& "C:\Program Files\NASM\nasm.exe" -f bin ".\src\kernel\kernel.asm" -o "$BUILD_DIR/kernel.bin"
if (Test-Path "$BUILD_DIR/kernel.bin") {
    Write-Host "Копирование ядра..."
    $kernel = [System.IO.File]::ReadAllBytes("$BUILD_DIR/kernel.bin")
    [Array]::Copy($kernel, 0, $image, 512, $kernel.Length)  # 512 - начало второго сектора
} else {
    Write-Error "kernel.bin не создан!"
    exit 1
}

# Записываем образ
[System.IO.File]::WriteAllBytes("$BUILD_DIR/os.img", $image)
Write-Host "Образ системы создан"
