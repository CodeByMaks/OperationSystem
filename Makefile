all: os.img

boot.bin: boot.asm
	nasm -f bin boot.asm -o boot.bin

os.img: boot.bin
	dd if=/dev/zero of=os.img bs=512 count=2880
	dd if=boot.bin of=os.img conv=notrunc

clean:
	rm -f boot.bin os.img

run: os.img
	qemu-system-x86_64 os.img
