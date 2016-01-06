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

; fetch_card_family
; - eax - input - address of card 
; - dl - output - card family
fetch_card_family:
	mov dl, byte [eax]
	shr dl, 2
	ret

section .data
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
