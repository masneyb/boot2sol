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

loop:
	mov ah, 02h	; Set cursor position
	mov bh, 0	; In graphics mode
	mov dh, 5	; Row
	mov dl, 10	; Column
	int 10h		; Call BIOS

	mov si, text_string
	call print_string
	inc bl		; Change colour
	jmp loop

	text_string db 'Bare metal rules! ', 0

print_string:
	mov ah, 0Eh	; Print character routine
.repeat:
	lodsb
	cmp al, 0
	je .done
	int 10h		; Call BIOS
	jmp .repeat
.done:
	ret

.data
        ; Family - 2 bits
        ; - 1 1 spade
        ; - 1 0 club
        ; - 0 1 heart
        ; - 0 0 diamond
        ; - First bit is the color (1=black, 0=red)
        ; Card - 4 bits
        ; - A=1, 2, 3-10, J=11, Q=12, K=13
        ; Pile - 4 bits
        ; - 0-6 top row piles (2 is always empty)
        ; Shown? - 1 bit
        ; Position in current pile - 5 bits

        card dw 11_1000_0000_1_00010b
        dw 11_0010_1000_0_00001b

	times 510-($-$$) db 0
	dw 0AA55h	; Boot signature
