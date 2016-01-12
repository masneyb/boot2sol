# Production targets
boot: boot.asm
	nasm -f bin -o boot.bin boot.asm

floppy: clean boot
	mkdosfs -C floppy.img 1440
	dd status=noxfer conv=notrunc if=boot.bin of=floppy.img

run: floppy
	qemu-system-i386 -soundhw all floppy.img

objdump: boot
	objdump -mi8086 -Mintel -D -b binary boot.bin --adjust-vma 0x7c00


# Debug targets
debugboot: boot.asm
	nasm -felf -Fdwarf -g -o boot.elf boot.asm
	objcopy -O binary boot.elf boot.bin

debugfloppy: clean debugboot
	mkdosfs -C floppy.img 1440
	dd status=noxfer conv=notrunc if=boot.bin of=floppy.img

debug: debugfloppy
	qemu-system-i386 floppy.img -s -S


clean:
	rm -f boot.bin boot.elf floppy.img
