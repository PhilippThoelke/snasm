build : build/SmOl.iso

run : build/SmOl.iso
	qemu-system-x86_64 -cdrom build/SmOl.iso

clean :
	rm -rf build

build/SmOl.iso : build/bootloader.bin
	mkdir build/iso
	dd if=/dev/zero of=build/iso/floppy.img bs=1024 count=1440
	dd if=build/bootloader.bin of=build/iso/floppy.img seek=0 conv=notrunc
	mkisofs -V 'SmOl' -input-charset iso8859-1 -o build/SmOl.iso -b floppy.img build/iso/
	rm -rf build/iso

build/bootloader.bin : src/bootloader.asm
	mkdir -p build
	nasm -fbin src/bootloader.asm -o build/bootloader.bin
