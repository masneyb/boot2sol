boot: boot.asm
	nasm -felf -Fdwarf -g -o boot.elf boot.asm
	objcopy -O binary boot.elf boot.bin

sol: sol.asm
	nasm -f elf -o sol.o sol.asm
	ld -m elf_i386 -o sol sol.o

floppy: clean boot
	mkdosfs -C floppy.img 1440
	dd status=noxfer conv=notrunc if=boot.bin of=floppy.img

run: floppy
	qemu-system-i386 floppy.img

debug: floppy
	qemu-system-i386 floppy.img -s -S

objdump: boot
	objdump -mi8086 -Mintel -D -b binary boot.bin --adjust-vma 0x7c00

clean:
	rm -f boot.bin floppy.img sol sol.o
