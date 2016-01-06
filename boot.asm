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

fetch_card_pile:
	mov dl, byte [eax+1]
	shr dl, 4
	ret

fetch_card_value:
        mov dl, byte [eax+1]
        shl dl, 4
        shr dl, 4
        ret

fetch_card_family:
        mov dl, byte [eax]
        shr dl, 6
        ret

fetch_card_shown:
        mov dl, byte [eax]
        shl dl, 2
        shr dl, 7
        ret

fetch_card_pile_pos:
        mov dl, byte [eax]
        shl dl, 3
        shr dl, 3
        ret

.data:
        ; Pile - 4 bits
        ; - 0-6 top row piles (2 is always empty)
        ; Card - 4 bits
        ; - A=1, 2, 3-10, J=11, Q=12, K=13
        
        ; Family - 2 bits
        ; - 1 1 spade
        ; - 1 0 club
        ; - 0 1 heart
        ; - 0 0 diamond
        ; - First bit is the color (1=black, 0=red)
        ; Shown? - 1 bit
        ; Position in current pile - 5 bits

        card dw 1011_1101_10_1_11001b
        dw 1111_0000_00_1_00010b

	times 510-($-$$) db 0
	dw 0AA55h	; Boot signature
