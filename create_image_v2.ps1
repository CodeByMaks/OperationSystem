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

# Копируем загрузчик в начало буфера
[Array]::Copy($bootLoader, 0, $buffer, 0, $bootLoader.Length)

# Записываем образ на диск
[System.IO.File]::WriteAllBytes($imagePath, $buffer)

Write-Host "Образ диска создан успешно! Размер загрузчика: $($bootLoader.Length) байт"
