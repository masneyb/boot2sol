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
	mov ax, card
 	call print_card
	call draw_board
	jmp $


print_card:
	call fetch_card_value
	mov al, byte [fv+ecx]
	call fetch_card_family
	mov bl, byte [colors+ecx]
	call print_char
	mov al, byte [symbols+ecx]
	inc dl
	call print_char
	ret

print_char:
	mov ah, 02h
	mov bh, 0
	int 10h
	mov ah, 0Eh
	int 10h
	ret

; fetch_card_pile
; - eax - input - address of card
; - dl - output - card pile
fetch_card_pile:
	mov cl, byte [eax+1]
	shr cl, 4
	mov ch, 0
	ret

; fetch_card_value
; - eax - input - address of card
; - dl - output - card value
fetch_card_value:
	mov cl, byte [eax+1]
	shl cl, 4
	shr cl, 4
	mov ch, 0
	ret

; fetch_card_family
; - eax - input - address of card
; - dl - output - card family
fetch_card_family:
	mov cl, byte [eax]
	shr cl, 6
	mov ch, 0
	ret
draw_board:

	push dx
	mov dh, 10d
	mov dl, 0d

.printhorizontaldivider:
	mov al, '-'
	call print_char
	inc dl
	cmp dl, 255d
	jne .printhorizontaldivider

	mov dh, 0d
	mov dl, 10d
	mov al, '|'
.vertline1:
	call print_char
	inc dh
	cmp dh, 10d
	jne .vertline1
	mov dh, 0d
	mov dl, 30d
.vertline2:
	call print_char
	inc dh
	cmp dh,10d
	jne .vertline2
	mov dh, 0d
	mov dl, 40d
.vertline3:
	call print_char
	inc dh
	cmp dh,10d
	jne .vertline3
	mov dh,	0d
	mov dl,	50d
.vertline4:
	call print_char
	inc dh
	cmp dh,10d
	jne .vertline4
	mov dh, 0d
	mov dl, 60d
.vertline5:
	call print_char
	inc dh
	cmp dh,10d
	jne .vertline5
	mov dh, 0d
	mov dl, 60d
.vertline6:
	call print_char
	inc dh
	cmp dh,10d
	jne .vertline6
	mov dh, 0d
	mov dl, 70d
.vertline7:
	call print_char
	inc dh
	cmp dh,10d
	jne .vertline7
	mov dh, 5d
	mov dl, 4d
	mov al, '-'
.printdeck:
	call print_char
	inc dl
	cmp dl, 7d
	jne .printdeck

	popdx
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
				fv db ' A23456789TJQK'
				colors db 7d, 7d, 4d, 4d
				symbols db 'CSDH'
        card dw 1011_1101_10_1_11001b
        dw 1111_0000_00_1_00010b

	times 510-($-$$) db 0
	dw 0AA55h	; Boot signature
