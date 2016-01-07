boot: boot.asm
	nasm -f bin -o boot.bin boot.asm

sol: sol.asm
	nasm -f elf -o sol.o sol.asm
	ld -m elf_i386 -o sol sol.o

floppy: clean boot
	mkdosfs -C floppy.img 1440
	dd status=noxfer conv=notrunc if=boot.bin of=floppy.img

run: floppy
	qemu-system-i386 floppy.img

objdump: boot
	objdump -D -b binary -mi386 -Maddr16,data16 boot.bin

clean:
	rm -f boot.bin floppy.img sol sol.o
