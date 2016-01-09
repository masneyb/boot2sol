; http://faydoc.tripod.com/cpu/index.htm
; http://www.nasm.us/doc/nasmdoc0.html
; http://www.ctyme.com/intr/int-10.htm
; http://www.theasciicode.com.ar/

%define top_row_num	5d
%define bottom_row_num	9d
%define first_stack_col 5d
%define stack_spacing	10d
%define all_cards_len	104d

%define end_of_pile		01111111b
%define pile_next_ptr_mask	end_of_pile

%define draw_down_pile_number   0
%define draw_up_pile_number     1
;%define draw_down_pile_number	13
;%define draw_up_pile_number	7

	BITS 16

	mov ax, 0x07c0	; Where we're loaded
	mov ds, ax	; Data segment

	mov ax, 0x9000	; Set up stack
	mov ss, ax
	mov sp, 0x0ffff	; Grows downwards!

game_loop:
					; Set the video resolution. This also clears
					; the screen.
	mov ax, 12h          		; high = 0, set video mode routine
					; low = 12h = G  80x30  8x16  640x480   16/256K  .   A000 VGA,ATI VIP
	int 10h

; There are 14 pile positions available. Iterate through each pile's linked
; list of cards.
; - The 7 piles at the bottom row grow down as new cards are added
; - The 7 piles at the top stay at the same row so that only the last card
;   in the pile is shown.

print_stacks:
	mov dh, top_row_num     	; Current cursor row
	mov dl, first_stack_col 	; Current cursor column

	xor cx, cx			; Current stack number; start at 0
top_of_stack:
	mov bl, byte [pile_pointers+ecx] ; Index of the current stack head
show_stack_card:
	and bx, pile_next_ptr_mask	; Filter out shown bit
	cmp bl, end_of_pile		; At end of pile?
	je nextstack

	mov ax, [first_card+ebx]	; Current card

	pusha

	mov cl, al
	bt cx, 7
	jc print_shown_card

print_hidden_card:
	; Set cursor position
	mov ah, 02h		; Set cursor position
	xor bh, bh		; Page number 0
	mov bl, byte 7d
	int 10h

	mov al, byte '-'
	mov ah, 0eh		; Teletype output
	int 10h
	int 10h

	jmp finished_printing

print_shown_card:
	; Fetch the card value
	mov cl, ah
	and cx, 000fh
	push cx				; Save the current card value

	; Fetch the card family
	mov cl, ah
	shr cl, 6d
	xor ch, ch

	; Set cursor position
	mov ah, 02h		; Set cursor position
	xor bh, bh		; Page number 0
	mov bl, byte [family_colors+ecx]
	int 10h

	; Display the card value...
	pop ax				; Get the previously saved card value
	mov al, byte [card_values+eax]
	mov ah, 0eh		; Teletype output
	int 10h

	; And the card family symbol...
	mov al, byte [family_symbols+ecx]
	mov ah, 0eh		; Teletype output
	int 10h

finished_printing:
	popa

	cmp cl, 7h			; Are we at the bottom left pile?
	jl dumpstack_nextcard		; Only increment the cursor row if on the bottom row
	add dh,2d			; Increment cursor row only on bottom row

dumpstack_nextcard:
	mov bl, al			; Update next card pointer
	jmp show_stack_card

nextstack:
	cmp cl, 13d
	je process_keyboard_input

	inc cl

	cmp cl, 7h			; What stack are we processing?
	je next_stack_first_bottom_row	; Beginning of bottom row?
	jl next_stack_top_row		; Still on the top row?
					; Otherwise we are on the bottom row
	add dl, stack_spacing		; Increment cursor column
	mov dh, bottom_row_num		; Reset cursor row
	jmp top_of_stack

next_stack_top_row:
	add dl, stack_spacing		; Increment cursor column
	mov dh, top_row_num		; Reset cursor row
	jmp top_of_stack

next_stack_first_bottom_row:		; We are at the beginning of the
					; first stack on the bottom row.
	mov dh, bottom_row_num		; current cursor row
	mov dl, first_stack_col		; current cursor column
	jmp top_of_stack

process_keyboard_input:
	xor ah, ah
	int 16h

	cmp al, 'd'
	je draw_command

	cmp al, 'm'
	je move_command

	jmp game_loop

; ---------------------------------------------------------------------------

; inputs:
; - dx - the source pile number
; - cx - the card number within the pile on the source
; - bx - the destination pile

perform_move_command:
	push bx				; Save the destination pile nmber

	push dx				; Save the current source pile number since we need it
					; if the pile becomes empty.

	; Note: find_bottom_of_pile uses the cl register to find the desired card
	xor ah, ah
	mov al, byte [pile_pointers+edx]; Source pile
	call find_bottom_of_pile

	pop cx				; Fetch the current source pile number

        cmp dl, end_of_pile
        je .move_source_pile_now_empty

	mov [first_card+edx], byte 0xff	; Set null byte on next to last entry
	jmp .move_save_card

.move_source_pile_now_empty:
        mov [pile_pointers+ecx], byte end_of_pile

.move_save_card:
	pop dx				; Fetch the destination pile number

	push ax				; Save our card

	cmp [pile_pointers+edx], byte end_of_pile ; Is the destination pile already empty?
	jne .move_dest_pile_has_cards

	pop bx				; Old ax; card moved from source pile
	mov [pile_pointers+edx], byte bl
	ret

.move_dest_pile_has_cards:
	mov cl, 0xff			; Select last card in list
	xor ah, ah
	mov al, byte [pile_pointers+edx]; Destination pile
	call find_bottom_of_pile

	pop bx				; Old ax; card moved from source pile

	or bl, 10000000b;		; Ensure the previous card is shown
	mov [first_card+eax], byte bl	; Set the next pointer to the card that was moved
	ret

; ---------------------------------------------------------------------------

find_bottom_of_pile:
	mov dx, end_of_pile
.loop:
	dec cl		; Check to see if the counter is zero yet
	jz .break

	mov bl, byte [first_card+eax]
	and bx, pile_next_ptr_mask	; Filter out shown bit
	cmp bl, end_of_pile
	je .break
	mov dx, ax
	mov ax, bx
	jmp .loop
.break:
	ret

; ---------------------------------------------------------------------------

draw_command:
	cmp [pile_pointers+draw_down_pile_number], byte end_of_pile
	jne .draw_source_pile_has_cards

	; No cards left to pull. Swap the piles
	mov al, byte [pile_pointers+draw_up_pile_number]
	mov bl, byte [pile_pointers+draw_down_pile_number]
	mov [pile_pointers+draw_up_pile_number], byte bl
	mov [pile_pointers+draw_down_pile_number], byte al
	jmp game_loop

.draw_source_pile_has_cards:
	mov dx, draw_down_pile_number	; Input for perform_move_command: source pile number
	mov cl, 0xff			; Card number within the source pile. Max out the
					; counter for find_bottom_of_pile so that we get
					; the last card. This will be sufficient for the
					; number of the cards present.
	mov bx, draw_up_pile_number	; Input for perform_move_command: destination pile number
	call perform_move_command
	jmp game_loop

; ---------------------------------------------------------------------------

read_keyboard_input:
	xor ax, ax			; Read keyboard input
	int 16h
	sub al, 'a'			; Subtract ASCII 'a' to get index
	ret

; ---------------------------------------------------------------------------

; Pile indexes
; a b _ d e f g
; h i j k l m n

; Example keyboard input: mndk
; - move
; - Source pile: n (see map above)
; - 4th from top
; - Destination pile: k (see map above)

move_command:
	call read_keyboard_input
	xor dh, dh
	mov dl, al			; Input for perform_move_command: source pile number

	call read_keyboard_input
	mov cl, al			; Input for perform_move_command: card number in pile
	inc cl				; This counter is zero based

	call read_keyboard_input
	xor bh, bh
	mov bl, al			; Input for perform_move_command: source pile number

	call perform_move_command

	jmp game_loop

; ---------------------------------------------------------------------------

	card_values db ' A23456789TJQK'
	family_colors db 7d, 7d, 4d, 4d
	family_symbols db 'CSDH'

	; Family - 2 bits
	; - 1 1 hearts
	; - 1 0 diamond
	; - 0 1 spades
	; - 0 0 clubs
	; - First bit is the color (1=black, 0=red)
	; Unused - 2 bits
	; Card - 4 bits
	; - A=1, 2, 3-10, J=11, Q=12, K=13

	; Shown? - 1 bit
	; Pointer to next - 7 bits - 0xff - end of list

	; FIXME - we are currently 7 cards short due to our program size exceeding 510 bytes
	first_card dw 10_0_0_1010_0_0000010b ; TD  - Top of deck stack - 0000000
	dw 01_0_0_1100_0_0000100b ; QS  - 0000010
	dw 00_0_0_1100_0_0000110b ; QC  - 0000100
	dw 11_0_0_0010_0_0001000b ; 2H  - 0000110
	dw 11_0_0_1000_0_0001010b ; 8H  - 0001000
	dw 00_0_0_0001_0_0001100b ; AC  - 0001010
	dw 10_0_0_1000_0_0001110b ; 8D  - 0001100
	dw 11_0_0_1001_0_0010000b ; 9H  - 0001110
	dw 11_0_0_0111_0_0010010b ; 7H  - 0010000
	dw 00_0_0_0101_0_0010100b ; 5C  - 0010010
	dw 00_0_0_0011_0_0010110b ; 3C  - 0010100
	dw 00_0_0_0010_0_0011000b ; 2C  - 0010110
	dw 10_0_0_0101_0_0011010b ; 5D  - 0011000
	dw 01_0_0_0111_0_0011100b ; 7S  - 0011010
	dw 10_0_0_1001_0_0011110b ; 9D  - 0011100
	dw 00_0_0_1011_0_1111111b ; JC  - 0011110
	dw 00_0_0_0110_1_1111111b ; 6C+ - Drawn card - 0100000
	dw 00_0_0_1000_1_1111111b ; 8C+ - Beginning of stack 7 - 0100010
	dw 01_0_0_1010_0_0100110b ; TS  - Beginning of stack 8 - 0100100
	dw 01_0_0_0001_1_1111111b ; AS+ - 0100110
	dw 00_0_0_0100_0_0101010b ; 4C  - Beginning of stack 9 - 0101000
	dw 01_0_0_0100_0_0101100b ; 4S  - 0101010
	dw 01_0_0_1000_1_1111111b ; 8S+ - 0101100
	dw 10_0_0_0110_0_0110000b ; 6D  - Beginning of stack 10 - 0101110
	dw 01_0_0_0010_0_0110010b ; 2S  - 0110000
	dw 01_0_0_0110_0_0110100b ; 6S  - 0110010
	dw 11_0_0_1011_1_1111111b ; JH+ - 0110100
	dw 10_0_0_0111_0_0111000b ; 7D  - Beginning of stack 11 - 0110110
	dw 10_0_0_0001_0_0111010b ; AD  - 0111000
	dw 10_0_0_0100_0_0111100b ; 4D  - 0111010
	dw 11_0_0_0100_0_0111110b ; 4H  - 0111100
	dw 00_0_0_0111_1_1111111b ; 7C+ - 0111110
	dw 11_0_0_1101_0_1000010b ; KH  - Beginning of stack 12 - 1000000
	dw 01_0_0_1101_0_1000100b ; KS  - 1000010
	dw 00_0_0_1101_0_1000110b ; KC  - 1000100
	dw 10_0_0_1011_0_1001000b ; JD  - 1000110
	dw 10_0_0_0011_0_1001010b ; 3D  - 1001000
	dw 01_0_0_1011_1_1111111b ; JS+ - 1001010
	dw 10_0_0_1100_0_1001110b ; QD  - Beginning of stack 13 - 1001100
	dw 01_0_0_1001_0_1010000b ; 9S  - 1001110
	dw 11_0_0_0011_0_1010010b ; 3H  - 1010000
	dw 10_0_0_0010_0_1010100b ; 2D  - 1010010
	dw 00_0_0_1010_0_1010110b ; TC  - 1010100
	dw 11_0_0_0101_0_1011000b ; 5H  - 1010110
	dw 00_0_0_1001_1_1111111b ; 9C+ - 1011000

	pile_pointers db 00000000b
	db 0100000b
	db 1111111b
	db 1111111b
	db 1111111b
	db 1111111b
	db 1111111b
	db 0100010b
	db 0100100b
	db 0101000b
	db 0101110b
	db 0110110b
	db 1000000b
	db 1001100b

	times 510-($-$$) db 0
	dw 0AA55h  ; Boot signature
