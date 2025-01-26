BUILD_DIR = build
SRC_DIR = src

all: os.img

# Создание директории сборки
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Компиляция компонентов
$(BUILD_DIR)/boot.bin: $(SRC_DIR)/boot/boot.asm | $(BUILD_DIR)
	nasm -f bin $< -o $@

$(BUILD_DIR)/kernel.bin: $(SRC_DIR)/kernel/kernel.asm | $(BUILD_DIR)
	nasm -f bin $< -o $@

# Создание образа системы
os.img: $(BUILD_DIR)/boot.bin $(BUILD_DIR)/kernel.bin
	dd if=/dev/zero of=$(BUILD_DIR)/os.img bs=512 count=2880
	dd if=$(BUILD_DIR)/boot.bin of=$(BUILD_DIR)/os.img conv=notrunc bs=512 count=1
	dd if=$(BUILD_DIR)/kernel.bin of=$(BUILD_DIR)/os.img conv=notrunc bs=512 seek=1
	cp $(BUILD_DIR)/os.img .

clean:
	rm -rf $(BUILD_DIR)
	rm -f os.img

run: os.img
	qemu-system-x86_64 -fda os.img
