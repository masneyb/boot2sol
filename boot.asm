; http://www.nasm.us/doc/nasmdoc0.html
; https://www.cs.uaf.edu/2006/fall/cs301/support/x86/
; www.ctyme.com/intr/int-10.htm

%define top_row_num	5d
%define bottom_row_num	9d
%define first_stack_col 5d
%define stack_spacing	10d
%define all_cards_len	104d

  BITS 16

  mov ax, 07C0h		; Where we're loaded
  mov ds, ax		; Data segment

  mov ax, 9000h		; Set up stack
  mov ss, ax
  mov sp, 0FFFFh	; Grows downwards!

  mov ah, 0		; Set video mode routine
  mov al, 12h		; 12h = G  80x30  8x16  640x480   16/256K  .   A000 VGA,ATI VIP
  int 10h		; Call BIOS

game_loop:
  call print_status_message
  call print_stacks

  mov [status_message], word invalid_op_message
  jmp game_loop

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
; 	call print_invalid_op_message
;   jmp loopy
; 
; 
; main_draw:
; 	jmp loopy
; 
; main_move:
; 	jmp loopy

; ---------------------------------------------------------------------------

print_status_message:
  ; FIXME - handle empty status messages. Truncate ok_message to 0 once done.

  mov dl, 0d
  mov dh, 0d
  mov bl, 4d
  mov bh, 0d
  mov ah, 02h
  int 10h

  mov si, [status_message]
  mov ah, 0Eh
.loop:
  lodsb
  cmp al, 0x00
  je .done
  int 10h
  jmp .loop
.done:
  ret

; ---------------------------------------------------------------------------

print_card:
  ; FIXME - show -- if the card is not shown

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
print_stacks:
	pusha

	;; FIXME - clear screen

	;; need to store the pile number somewhere
	;; need to store the current card number somewhere this corresponds to the position in stack
	mov ch, 0h		;the current stack - will iterate from 0-13
	mov cl, 0d 		;current card number
	mov bx, first_card	;current mem location (gets incremented by 2 each iteration) (from 152 - 256)
	mov dh, top_row_num	;current cursor row
	mov dl, first_stack_col	;current cursor column
findcard:
	mov al, [bx+1]			; Fetch the card pile
	and al, 11110000b
	shr al, 4d
	cmp al, ch
	je stackmatch
	add bx,2				; Move card pointer
	cmp bx, first_card + all_cards_len	; End of cards?
	je next_stack
	jmp findcard

stackmatch:
	mov al, [bx]				; Fetch the card pile position
	and al, 00011111b
	cmp al, cl
	je cardmatch
	add bx,2d				; Move card pointer
	cmp bx, first_card + all_cards_len	; End of cards?
	je next_stack
	jmp findcard

cardmatch:
	mov ax, bx
	call print_card
	cmp ch, 7h
	jl cardmatch_nextcard		; Only increment the cursor row if in bottom row
	add dh,2d			; Increment cursor row only on bottom row
cardmatch_nextcard:
	inc cl				; Next card number
	add bx,2d                       ; Move card pointer
	jmp findcard

next_stack:				; We have finished one stack, increment stack, if < 14 continue, else done
	mov bx, first_card		; Reset pointer to beginning of cards
	inc ch
	cmp ch, 14d
	je finished
	mov cl, 0d			; Proces first card

	cmp ch, 7h			; What stack are we processing?
	je next_stack_first_bottom_row	; Beginning of bottom row?
	jl next_stack_top_row		; Still on the top row?
					; Otherwise we are on the bottom row
	add dl, stack_spacing		; Increment cursor column
	mov dh, bottom_row_num		; Reset cursor row
	jmp findcard

next_stack_top_row:
	add dl, stack_spacing		; Increment cursor column
	mov dh, top_row_num		; Reset cursor row
	jmp findcard

next_stack_first_bottom_row:		; We are at the beginning of the
					; first stack on the bottom row.
	mov dh, bottom_row_num		; current cursor row
	mov dl, first_stack_col		; current cursor column
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

  first_card dw 1101_1001_00_0_00000b ; 9C 
  dw 1101_1101_01_0_00001b ; KS 
  dw 1101_0111_00_0_00010b ; 7C 
  dw 1101_0011_10_0_00011b ; 3D 
  dw 1101_0111_01_0_00100b ; 7S 
  dw 1101_1000_10_0_00101b ; 8D 
  dw 1101_0111_10_1_00110b ; 7D+
  dw 1100_1010_11_0_00000b ; TH 
  dw 1100_1001_11_0_00001b ; 9H 
  dw 1100_0010_10_0_00010b ; 2D 
  dw 1100_1011_00_0_00011b ; JC 
  dw 1100_0101_00_0_00100b ; 5C 
  dw 1100_1010_10_1_00101b ; TD+
  dw 1011_0011_00_0_00000b ; 3C 
  dw 1011_0010_11_0_00001b ; 2H 
  dw 1011_1000_01_0_00010b ; 8S 
  dw 1011_0110_01_0_00011b ; 6S 
  dw 1011_1100_11_1_00100b ; QH+
  dw 1010_1010_01_0_00000b ; TS 
  dw 1010_0001_01_0_00001b ; AS 
  dw 1010_0100_00_0_00010b ; 4C 
  dw 1010_0100_10_1_00011b ; 4D+
  dw 1001_0110_10_0_00000b ; 6D 
  dw 1001_1011_01_0_00001b ; JS 
  dw 1001_1011_11_1_00010b ; JH+
  dw 1000_0001_10_0_00000b ; AD 
  dw 1000_0111_11_1_00001b ; 7H+
  dw 0111_0100_01_1_00000b ; 4S+
  dw 0001_1101_10_1_00000b ; KD+
  dw 0000_0011_01_0_00000b ; 3S 
  dw 0000_0010_01_0_00001b ; 2S 
  dw 0000_0101_11_0_00010b ; 5H 
  dw 0000_0011_11_0_00011b ; 3H 
  dw 0000_1001_01_0_00100b ; 9S 
  dw 0000_1101_11_0_00101b ; KH 
  dw 0000_0110_11_0_00110b ; 6H 
  dw 0000_1001_10_0_00111b ; 9D 
  dw 0000_0010_00_0_01000b ; 2C 
  dw 0000_0100_11_0_01001b ; 4H 
  dw 0000_1010_00_0_01010b ; TC 
  dw 0000_1100_00_0_01011b ; QC 
  dw 0000_0001_00_0_01100b ; AC 
  dw 0000_0101_01_0_01101b ; 5S 
  dw 0000_0001_11_0_01110b ; AH 
  dw 0000_1101_00_0_01111b ; KC 
  dw 0000_1100_01_0_10000b ; QS 
  dw 0000_0101_10_0_10001b ; 5D 
  dw 0000_1000_00_0_10010b ; 8C 
  dw 0000_1000_11_0_10011b ; 8H 
  dw 0000_1100_10_0_10100b ; QD 
  dw 0000_0110_00_0_10101b ; 6C 
  dw 0000_1011_10_0_10110b ; JD 

  ; Card positions. Cards with a + are shown.
  ; 3S  KD+                     4S+ AD  6D  TS  3C  TH  9C  
  ; 2S                              7H+ JS  AS  2H  9H  KS  
  ; 5H                                  JH+ 4C  8S  2D  7C  
  ; 3H                                      4D+ 6S  JC  3D  
  ; 9S                                          QH+ 5C  7S  
  ; KH                                              TD+ 8D  
  ; 6H                                                  7D+ 
  ; 9D                                                      
  ; 2C                                                      
  ; 4H                                                      
  ; TC                                                      
  ; QC                                                      
  ; AC                                                      
  ; 5S                                                      
  ; AH                                                      
  ; KC                                                      
  ; QS                                                      
  ; 5D                                                      
  ; 8C                                                      
  ; 8H                                                      
  ; QD                                                      
  ; 6C                                                      
  ; JD                         

  status_message dw ok_message
  ok_message db 'Ready', 0x00
  invalid_op_message db 'NO', 0x00

  times 510-($-$$) db 0
  dw 0AA55h  ; Boot signature
