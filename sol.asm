; http://www.nasm.us/doc/nasmdoc0.html
; https://www.cs.uaf.edu/2006/fall/cs301/support/x86/

section .text
	global _start

_start:
	; Test writing to the data
	;mov [card], byte 00_00_1101b

	mov eax, card
	call fetch_card_family

	mov eax, 1
	mov bl, dl
	int 80h

; fetch_card_pile
; - eax - input - address of card 
; - dl - output - card pile
fetch_card_pile:
	mov dl, byte [eax+1]
	shr dl, 4
	ret

; fetch_card_value
; - eax - input - address of card 
; - dl - output - card value
fetch_card_value:
	mov dl, byte [eax+1]
	shl dl, 4
	shr dl, 4
	ret

; fetch_card_family
; - eax - input - address of card 
; - dl - output - card family
fetch_card_family:
	mov dl, byte [eax]
	shr dl, 6
	ret

section .data
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

