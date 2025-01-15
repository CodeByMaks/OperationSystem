all: os.img

# Компиляция компонентов
boot.bin: boot.asm
	nasm -f bin boot.asm -o boot.bin

kernel.bin: kernel.asm memory.asm process.asm video.asm keyboard.asm shell.asm
	nasm -f bin kernel.asm -o kernel.bin

# Создание образа системы
os.img: boot.bin kernel.bin
	dd if=/dev/zero of=os.img bs=512 count=2880
	dd if=boot.bin of=os.img conv=notrunc bs=512 count=1
	dd if=kernel.bin of=os.img conv=notrunc bs=512 seek=1

clean:
	rm -f *.bin os.img

run: os.img
	qemu-system-x86_64 -fda os.img
