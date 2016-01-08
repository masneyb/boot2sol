boot: boot.asm
	nasm -f bin -o boot.bin boot.asm

debugboot: boot.asm
	nasm -felf -Fdwarf -g -o boot.elf boot.asm
	objcopy -O binary boot.elf boot.bin

floppy: clean boot
	mkdosfs -C floppy.img 1440
	dd status=noxfer conv=notrunc if=boot.bin of=floppy.img

debugfloppy: clean debugboot
	mkdosfs -C floppy.img 1440
	dd status=noxfer conv=notrunc if=boot.bin of=floppy.img

run: floppy
	qemu-system-i386 floppy.img

debug: debugfloppy
	qemu-system-i386 floppy.img -s -S

objdump: boot
	objdump -mi8086 -Mintel -D -b binary boot.bin --adjust-vma 0x7c00

clean:
	rm -f boot.bin boot.elf floppy.img
