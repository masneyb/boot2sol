; http://www.nasm.us/doc/nasmdoc0.html
; https://www.cs.uaf.edu/2006/fall/cs301/support/x86/
; www.ctyme.com/intr/int-10.htm

  BITS 16

  mov ax, 07C0h  ; Where we're loaded
  mov ds, ax  ; Data segment

  mov ax, 9000h  ; Set up stack
  mov ss, ax
  mov sp, 0FFFFh  ; Grows downwards!

  mov ah, 0  ; Set video mode routine
  mov al, 12h  ; 12h = G  80x30  8x16  640x480   16/256K  .   A000 VGA,ATI VIP
  int 10h    ; Call BIOS

  mov dh, 5d
  mov dl, 10d
  mov ax, card
  ;call print_card
  call draw_board
;	jmp loopy

loopy:
	mov ah, 0
	int 16h
	cmp al, 'd'
	je main_draw

	cmp al, 'm'
	je main_move

	call print_invalid_op
  jmp loopy

print_invalid_op:
	mov dl, 0d
	mov dh, 0d
	mov bl, 4d
	mov bh, 0d
	mov ah, 02h
	int 10h

	mov si, invalid_op
  mov ah, 0Eh
  .loop:
      lodsb
      cmp al, 0x00
      je .done
      int 10h
      jmp .loop
  .done:
      ret

main_draw:
	jmp loopy

main_move:
	jmp loopy

print_card:
  call fetch_card_value
  push cx
  call fetch_card_family
  mov bl, byte [colors+ecx]
  pop ax
  mov al, byte [fv+eax]
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

; ---------------------------------------------------------------------------

fetch_card_pile:
  mov cl, byte [eax+1]
  shr cl, 4
  mov ch, 0
  ret

fetch_card_value:
  mov cl, byte [eax+1]
  shl cl, 4
  shr cl, 4
  mov ch, 0
  ret

fetch_card_family:
  mov cl, byte [eax]
  shr cl, 6
  mov ch, 0
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
	call print_card
	inc dh
	inc dh
	dec dl
	jmp findcard

next_stack:			;we have finished one stack, increment stack, if < 13 continue, else done
	inc ch
	cmp ch, 00001101b
	je finished
	jmp findcard

finished:
	pop dx
	pop cx
	pop bx
	pop ax
	ret


  ; ---------------------------------------------------------------------------


.data:
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

  fv db ' A23456789TJQK'
  colors db 7d, 7d, 4d, 4d
  symbols db 'CSDH'
  card dw 1101_1101_10_0_00000b
  dw 1101_0100_01_0_00001b
  dw 1101_1000_01_0_00010b
  dw 1101_0101_11_0_00011b
  dw 1101_0010_01_0_00100b
  dw 1101_0110_01_0_00101b
  dw 1101_1001_11_1_00110b
  dw 1100_0100_00_0_00000b
  dw 1100_1100_01_0_00001b
  dw 1100_1011_10_0_00010b
  dw 1100_0110_11_0_00011b
  dw 1100_0111_10_0_00100b
  dw 1100_0011_10_1_00101b
  dw 1011_1100_10_0_00000b
  dw 1011_0111_00_0_00001b
  dw 1011_1001_01_0_00010b
  dw 1011_1000_11_0_00011b
  dw 1011_0101_00_1_00100b
  dw 1010_1001_10_0_00000b
  dw 1010_0001_10_0_00001b
  dw 1010_1010_00_0_00010b
  dw 1010_0100_10_1_00011b
  dw 1001_0111_01_0_00000b
  dw 1001_0011_01_0_00001b
  dw 1001_1100_11_1_00010b
  dw 1000_0100_11_0_00000b
  dw 1000_1010_01_1_00001b
  dw 0111_1011_11_1_00000b
  dw 0001_1010_10_1_00000b
  dw 0000_0010_10_0_00000b
  dw 0000_0101_10_0_00001b
  dw 0000_0001_01_0_00010b
  dw 0000_1011_00_0_00011b
  dw 0000_1101_11_0_00100b
  dw 0000_0010_00_0_00101b
  dw 0000_1101_01_0_00110b
  dw 0000_0111_11_0_00111b
  dw 0000_0010_11_0_01000b
  dw 0000_0110_10_0_01001b
  dw 0000_0101_01_0_01010b
  dw 0000_0001_00_0_01011b
  dw 0000_1001_00_0_01100b
  dw 0000_0011_00_0_01101b
  dw 0000_1000_10_0_01110b
  dw 0000_0110_00_0_01111b
  dw 0000_1101_00_0_10000b
  dw 0000_0001_11_0_10001b
  dw 0000_1000_00_0_10010b
  dw 0000_0011_11_0_10011b
  dw 0000_1100_00_0_10100b
  dw 0000_1010_11_0_10101b
  dw 0000_1011_01_0_10110b

  invalid_op db 'NO', 0x00

  times 510-($-$$) db 0
  dw 0AA55h  ; Boot signature
