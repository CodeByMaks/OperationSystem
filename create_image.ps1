# Создаем пустой файл размером 1.44 МБ (1474560 байт)
$imageSize = 1474560
$imagePath = "os.img"

# Создаем пустой файл
$buffer = New-Object byte[] $imageSize
[System.IO.File]::WriteAllBytes($imagePath, $buffer)

# Копируем загрузчик в начало образа
$bootLoader = [System.IO.File]::ReadAllBytes("boot.bin")
$stream = [System.IO.File]::OpenWrite($imagePath)
$stream.Write($bootLoader, 0, $bootLoader.Length)
$stream.Close()

Write-Host "Образ диска создан успешно!"
