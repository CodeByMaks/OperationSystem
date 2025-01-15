# Создаем новый пустой образ размером 1.44 MB
Write-Host "Создание образа диска..."
$imageSize = 1474560  # 1.44 MB в байтах
[byte[]]$imageData = New-Object byte[] $imageSize
Set-Content -Path "os.img" -Value $imageData -Encoding Byte -Force

# Читаем загрузчик
Write-Host "Чтение загрузчика..."
$bootData = [System.IO.File]::ReadAllBytes("boot.bin")
if ($bootData.Length -gt 512) {
    Write-Error "Загрузчик больше 512 байт!"
    exit 1
}
Write-Host "Размер загрузчика: $($bootData.Length) байт"

# Читаем ядро
Write-Host "Чтение ядра..."
$kernelData = [System.IO.File]::ReadAllBytes("kernel.bin")
Write-Host "Размер ядра: $($kernelData.Length) байт"

# Открываем файл для записи
Write-Host "Копирование данных..."
$stream = [System.IO.File]::Open("os.img", [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)

try {
    # Копируем загрузчик в начало образа
    $stream.Seek(0, [System.IO.SeekOrigin]::Begin) | Out-Null
    $stream.Write($bootData, 0, $bootData.Length)

    # Копируем ядро после загрузчика (сектор 2)
    $stream.Seek(512, [System.IO.SeekOrigin]::Begin) | Out-Null
    $stream.Write($kernelData, 0, $kernelData.Length)
}
finally {
    # Закрываем поток
    $stream.Close()
    $stream.Dispose()
}

Write-Host "Образ диска создан успешно!"
Write-Host "Общий размер: $($bootData.Length + $kernelData.Length) байт"
