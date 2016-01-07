; http://www.nasm.us/doc/nasmdoc0.html
; https://www.cs.uaf.edu/2006/fall/cs301/support/x86/
; www.ctyme.com/intr/int-10.htm

  BITS 16

  mov ax, 07C0h		; Where we're loaded
  mov ds, ax		; Data segment

  mov ax, 9000h		; Set up stack
  mov ss, ax
  mov sp, 0FFFFh	; Grows downwards!

  mov ah, 0		; Set video mode routine
  mov al, 12h		; 12h = G  80x30  8x16  640x480   16/256K  .   A000 VGA,ATI VIP
  int 10h		; Call BIOS

  call print_lower_stacks

;	jmp loopy
; loopy:
; 	mov ah, 0
; 	int 16h
; 	cmp al, 'd'
; 	je main_draw
; 
; 	cmp al, 'm'
; 	je main_move
; 
; 	call print_invalid_op
;   jmp loopy
; 
; print_invalid_op:
; 	mov dl, 0d
; 	mov dh, 0d
; 	mov bl, 4d
; 	mov bh, 0d
; 	mov ah, 02h
; 	int 10h
; 
; 	mov si, invalid_op
;   mov ah, 0Eh
;   .loop:
;       lodsb
;       cmp al, 0x00
;       je .done
;       int 10h
;       jmp .loop
;   .done:
;       ret
; 
; main_draw:
; 	jmp loopy
; 
; main_move:
; 	jmp loopy

; ---------------------------------------------------------------------------

print_card:
  pusha					; Save all registers
  call fetch_card_value
  push cx				; Save the current card value
  call fetch_card_family
  mov bl, byte [family_colors+ecx]
  pop ax				; Get the previously saved card value
  mov al, byte [card_values+eax]
  call print_char			; Print the card value (i.e. 2, 3, K, etc)
  mov al, byte [family_symbols+ecx]
  inc dl				; Move cursor over one for family
  call print_char			; Print card family
  popa
  ret

print_char:
  pusha
  mov ah, 02h
  mov bh, 0
  int 10h
  mov ah, 0Eh
  int 10h
  popa
  ret

; ---------------------------------------------------------------------------

fetch_card_pile:
  mov cl, byte [eax+1]
  shr cl, 4d
  mov ch, 0d
  ret

fetch_card_value:
  mov cl, byte [eax+1]
  shl cl, 4d
  shr cl, 4d
  mov ch, 0d
  ret

fetch_card_family:
  mov cl, byte [eax]
  shr cl, 6d
  mov ch, 0d
  ret

fetch_card_shown:
  mov cl, byte [eax]
  shl cl, 2d
  shr cl, 7d
  mov ch, 0d
  ret

fetch_card_pile_pos:
  mov cl, byte [eax]
  shl cl, 3d
  shr cl, 3d
  mov ch, 0d
  ret

; ---------------------------------------------------------------------------

	;; print the stacks
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
print_lower_stacks:
	pusha
	;; need to store the pile number somewhere
	;; need to store the current card number somewhere this corresponds to the position in stack
	mov ch, 7h		;the current stack - will iterate from 7-13
	mov cl, 0d 		;current card number
	mov bx, first_card		;current mem location (gets incremented by 2 each iteration) (from 152 - 256)
	mov dh, 11d
	mov dl, 5d
findcard:
	mov al, [bx+1]
	and al, 11110000b
	shr al, 4d
	cmp al, ch
	je stackmatch
	add bx,2
	cmp bx, first_card + 104d
	je next_stack
	jmp findcard

stackmatch:
	mov al, [bx]
	and al, 00011111b
	cmp al, cl
	je cardmatch
	add bx,2d
	cmp bx, first_card + 104d
	je next_stack
	jmp findcard

cardmatch:
	mov ax, bx
	call print_card
	add dh,2d
	inc cl
	jmp findcard

next_stack:			;we have finished one stack, increment stack, if < 14 continue, else done
	inc ch
	cmp ch, 14d
	je finished
	mov cl, 0d
	add dl, 4d
	mov dh, 11d
	jmp findcard

finished:
	popa
	ret


  ; ---------------------------------------------------------------------------


.data:
  card_values db ' A23456789TJQK'
  family_colors db 7d, 7d, 4d, 4d
  family_symbols db 'CSDH'

  ; Pile - 4 bits
  ; - 0-6 top row piles (2 is always empty)
  ; Card - 4 bits
  ; - A=1, 2, 3-10, J=11, Q=12, K=13

  ; Family - 2 bits
  ; - 1 1 hearts
  ; - 1 0 diamond
  ; - 0 1 spades
  ; - 0 0 clubs
  ; - First bit is the color (1=black, 0=red)
  ; Shown? - 1 bit
  ; Position in current pile - 5 bits

  first_card dw 1101_1010_01_0_00000b
  dw 1101_1100_01_0_00001b
  dw 1101_0011_00_0_00010b
  dw 1101_0111_11_0_00011b
  dw 1101_1011_01_0_00100b
  dw 1101_1001_01_0_00101b
  dw 1101_0111_01_1_00110b
  dw 1100_1101_11_0_00000b
  dw 1100_1011_11_0_00001b
  dw 1100_1010_00_0_00010b
  dw 1100_0101_00_0_00011b
  dw 1100_0100_01_0_00100b
  dw 1100_1000_10_1_00101b
  dw 1011_1011_10_0_00000b
  dw 1011_1010_11_0_00001b
  dw 1011_0110_11_0_00010b
  dw 1011_1101_01_0_00011b
  dw 1011_0101_01_1_00100b
  dw 1010_0001_00_0_00000b
  dw 1010_0001_10_0_00001b
  dw 1010_1100_11_0_00010b
  dw 1010_1000_01_1_00011b
  dw 1001_1000_00_0_00000b
  dw 1001_0110_00_0_00001b
  dw 1001_0001_01_1_00010b
  dw 1000_0011_11_0_00000b
  dw 1000_0110_01_1_00001b
  dw 0111_1101_00_1_00000b
  dw 0001_1010_10_1_00000b
  dw 0000_0101_11_0_00000b
  dw 0000_0111_00_0_00001b
  dw 0000_1100_00_0_00010b
  dw 0000_0100_10_0_00011b
  dw 0000_0101_10_0_00100b
  dw 0000_0011_10_0_00101b
  dw 0000_1101_10_0_00110b
  dw 0000_1000_11_0_00111b
  dw 0000_0100_00_0_01000b
  dw 0000_1011_00_0_01001b
  dw 0000_1100_10_0_01010b
  dw 0000_1001_11_0_01011b
  dw 0000_1001_00_0_01100b
  dw 0000_0010_01_0_01101b
  dw 0000_0010_10_0_01110b
  dw 0000_0010_00_0_01111b
  dw 0000_0111_10_0_10000b
  dw 0000_0010_11_0_10001b
  dw 0000_0011_01_0_10010b
  dw 0000_0100_11_0_10011b
  dw 0000_0110_10_0_10100b
  dw 0000_1001_10_0_10101b
  dw 0000_0001_11_0_10110b

  ; Card positions. Cards with a + are shown.
  ; 5H  TD+                     KC+ 3H  8C  AC  JD  KH  TS  
  ; 7C                              6S+ 6C  AD  TH  JH  QS  
  ; QC                                  AS+ QH  6H  TC  3C  
  ; 4D                                      8S+ KS  5C  7H  
  ; 5D                                          5S+ 4S  JS  
  ; 3D                                              8D+ 9S  
  ; KD                                                  7S+ 
  ; 8H                                                      
  ; 4C                                                      
  ; JC                                                      
  ; QD                                                      
  ; 9H                                                      
  ; 9C                                                      
  ; 2S                                                      
  ; 2D                                                      
  ; 2C                                                      
  ; 7D                                                      
  ; 2H                                                      
  ; 3S                                                      
  ; 4H                                                      
  ; 6D                                                      
  ; 9D                                                      
  ; AH                                                      

  invalid_op db 'NO', 0x00

  times 510-($-$$) db 0
  dw 0AA55h  ; Boot signature
