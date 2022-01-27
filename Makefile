build : build/snake.iso

run : build/snake.iso
	qemu-system-x86_64 -cdrom build/snake.iso

clean :
	rm -rf build

build/snake.iso : build/bootloader.bin
	mkdir build/iso
	dd if=/dev/zero of=build/iso/floppy.img bs=1024 count=1440
	dd if=build/bootloader.bin of=build/iso/floppy.img seek=0 conv=notrunc
	mkisofs -V 'snake' -input-charset iso8859-1 -o build/snake.iso -b floppy.img build/iso/
	rm -rf build/iso

build/bootloader.bin : src/bootloader.asm
	mkdir -p build
	nasm -fbin src/bootloader.asm -o build/bootloader.bin
