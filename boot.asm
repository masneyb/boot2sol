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


	call draw_board
	jmp $

	;; card location should be ax
	;; does not modify cursor position
print_card:
	call fetch_card_value
	cmp cl, 10d
	jg face_card
	jl number_card
print_card_done:
	call print_char
	ret
face_card:
	cmp cl, 11d
	je jack

	cmp cl, 12d
	je queen

	cmp cl, 13d
	je king
jack:
	mov al, 'J'
	jmp print_card_done
queen:
	mov al, 'Q'
	jmp print_card_done
king:
	mov al, 'K'
	jmp print_card_done
number_card:
	mov al, 'N'
	jmp print_card_done

print_char:
	mov ah, 02h
	mov bh, 0
	mov bl, 5
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
	ret

; fetch_card_value
; - eax - input - address of card
; - dl - output - card value
fetch_card_value:
	mov cl, byte [eax+1]
	shl cl, 4
	shr cl, 4
	ret

; fetch_card_family
; - eax - input - address of card
; - dl - output - card family
fetch_card_family:
	mov cl, byte [eax]
	shr cl, 6
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

.print_bottom_piles:
	mov dh, 11d
	mov dl, 0d
	mov al, '|'
line1:
	call print_char
	inc dh
	cmp dh, 21d
	jne line1
	mov dh, 11d
	mov dl, 10d
line2:
	call print_char
	inc dh
	cmp dh, 21d
	jne line2
	mov dh, 11d
	mov dl, 20d
line3:
	call print_char
	inc dh
	cmp dh, 21d
	jne line3
	mov dh, 11d
	mov dl, 30d
line4:
	call print_char
	inc dh
	cmp dh, 21d
	jne line4
	mov dh, 11d
	mov dl, 40d
line5:
	call print_char
	inc dh
	cmp dh, 21d
	jne line5
	mov dh, 11d
	mov dl, 50d
line6
	call print_char
	inc dh
	cmp dh, 21d
	jne line6
	mov dh, 11d
	mov dl, 60d
line7:
	call print_char
	inc dh
	cmp dh, 21d
	jne line7
	mov dh, 11d
	mov dl, 70d
line8:
	call print_char
	inc dh
	cmp dh, 21d
	jne line8
	mov dh, 11d
	mov dl, 80d
line9:
	call print_char
	inc dh
	cmp dh, 21d
	jne line9
	mov dh, 11d
	mov dl, 90d
	
	;; the lines for bottom stacks are finished printing, now to invidually print each stack with
	;; the proper number of facedown cards and the top card

print_stack_7:
	;; this needs to do the following:
	;; search for card that belongs in the current position of this deck (looping from 0-?)
	;; two modes:
	;; Mode1	The first mode is automatically set.
	;; 	This mode remains until a card is found that should be "Shown"
	;; 	The first mode prints just tops of cards to signify face down cards
	;; Mode2	this mode prints face up cards towards the top of the stack
	;; 	This mode will continue until no more cards exist in the stack
	;; 	This will simply print the next cards value (King of Spades)
	;; 	They should be printed one on top of the other
	;; as this subroutine will be used 7 times make sure it can be called for each stack

	popdx
	ret
print_lower_stacks:
	push ax
	push bx
	push cx
	push dx
	;; need to store the pile number somewhere
	;; need to store the current card number somewhere this corresponds to the position in stack
	mov ch, 7h		;the current stack - will iterate from 7-13
	mov cl, 0d 		;current card number
	mov bx, card		;current mem location (gets incremented by 2 each iteration) (from 152 - 256)
	mov dh, 11d
	mov dl, 5d
findcard:
	mov al, [bx]
	and al, 11110000b
	cmp al, ch
	je stackmatch
	inc bx
	inc bx
	cmp bx, card + 52
	je next_stack
	jmp findcard
	
stackmatch:	
	mov al, [bx+1]
	and al, 00011111b
	cmp al, cl
	je cardmatch
	inc bx
	inc bx
	cmp bx, card + 52
	je next_stack
	jmp findcard

cardmatch:	
	mov ax, bx
	call printcard
	inc dh
	inc dh
	dec dl
	jmp findcard

next_stack:			;we have finished one stack, increment stack, if < 13 continue, else done
	inc ch
	cmp ch, eh
	je finished
	jmp findcard
	
finished:	
	pop dx
	pop cx
	pop bx
	pop ax
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
