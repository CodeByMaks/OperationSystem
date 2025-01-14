# Создаем пустой файл размером 1.44 МБ (1474560 байт)
$imageSize = 1474560
$imagePath = "os.img"

# Создаем пустой файл нужного размера
$buffer = [byte[]]::new($imageSize)
for ($i = 0; $i -lt $imageSize; $i++) {
    $buffer[$i] = 0
}

# Читаем загрузчик
$bootLoader = [System.IO.File]::ReadAllBytes("boot.bin")
if ($bootLoader.Length -gt 512) {
    Write-Error "Загрузчик больше 512 байт!"
    exit 1
}

# Читаем ядро
$kernel = [System.IO.File]::ReadAllBytes("kernel.bin")
Write-Host "Размер ядра: $($kernel.Length) байт"

# Копируем загрузчик в начало буфера
[Array]::Copy($bootLoader, 0, $buffer, 0, $bootLoader.Length)

# Копируем ядро начиная со второго сектора
[Array]::Copy($kernel, 0, $buffer, 512, $kernel.Length)

# Записываем образ на диск
[System.IO.File]::WriteAllBytes($imagePath, $buffer)

Write-Host "Образ диска создан успешно!"
Write-Host "Размер загрузчика: $($bootLoader.Length) байт"
Write-Host "Размер ядра: $($kernel.Length) байт"
Write-Host "Общий размер: $($bootLoader.Length + $kernel.Length) байт"
