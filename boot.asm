; http://www.nasm.us/doc/nasmdoc0.html
; https://www.cs.uaf.edu/2006/fall/cs301/support/x86/
; www.ctyme.com/intr/int-10.htm
; Initial code from Linux Voice Issue #14

	BITS 16

	mov ax, 07C0h	; Where we're loaded
	mov ds, ax	; Data segment

	mov ax, 9000h	; Set up stack
	mov ss, ax
	mov sp, 0FFFFh	; Grows downwards!

	mov ah, 0	; Set video mode routine
	mov al, 12h	; 12h = G  80x30  8x16  640x480   16/256K  .   A000 VGA,ATI VIP
	int 10h		; Call BIOS


	mov dh, 5d
	mov dl, 10d
	mov al, 'H'
	call print_char
	jmp $

print_char:
	mov ah, 02h
	mov bh, 0
	mov bl, 5
	int 10h
	mov ah, 0Eh
	int 10h
	ret

	times 510-($-$$) db 0
	dw 0AA55h	; Boot signature
