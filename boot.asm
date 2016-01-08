; http://www.nasm.us/doc/nasmdoc0.html
; http://www.ctyme.com/intr/int-10.htm
; http://www.theasciicode.com.ar/

%define top_row_num	5d
%define bottom_row_num	9d
%define first_stack_col 5d
%define stack_spacing	10d
%define all_cards_len	104d

%define end_of_pile	01111111b

%define ok_message		' '
%define invalid_op_message	'!'

%define draw_down_pile_number   0
%define draw_up_pile_number     1
;%define draw_down_pile_number	13
;%define draw_up_pile_number	7

	BITS 16

	mov ax, 0x07c0	; Where we're loaded
	mov ds, ax		; Data segment

	mov ax, 0x9000	; Set up stack
	mov ss, ax
	mov sp, 0x0ffff	; Grows downwards!

game_loop:
			; Set the video resolution. This also clears
			; the screen.
	mov ax, 12h           ; high = 0, set video mode routine
				; low = 12h = G  80x30  8x16  640x480   16/256K  .   A000 VGA,ATI VIP
	int 10h		; Call BIOS

	; Print status message. First set the cursor
	xor dx, dx		; row 0, column 0
	mov bx, 4d
	mov ah, 02h		; set cursor position
	int 10h

	; Now show the message
	mov al, [status_message]
	mov ah, 0eh		; Teletype output
	int 10h

print_stacks:
	mov dh, top_row_num     	; Current cursor row
	mov dl, first_stack_col 	; Current cursor column

	xor cx, cx			; Current stack number; start at 0
top_of_stack:
	mov bl, byte [pile_pointers+ecx] ; Index of the current stack head
show_stack_card:
	and bx, 01111111b	; Filter out shown bit
	cmp bl, end_of_pile
	je nextstack

	mov ax, first_card		; Card with the index
	add ax, bx
print_card:
	pusha

	; Fetch the card value
	mov cl, byte [eax+1]
	and cx, 000fh
	push cx				; Save the current card value

	; Fetch the card family
	mov cl, byte [eax+1]
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

	popa

; Finished printing card

	cmp cl, 7h
	jl dumpstack_nextcard		; Only increment the cursor row if in bottom row
	add dh,2d			; Increment cursor row only on bottom row

dumpstack_nextcard:
	mov bl, byte [eax]		; Update next card pointer
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

	mov [status_message], byte invalid_op_message
	jmp game_loop

; ---------------------------------------------------------------------------

find_bottom_of_pile:
	mov dx, end_of_pile
.loop:
	dec cl		; Check to see if the counter is zero yet
	jz .break

	mov bl, byte [first_card+eax]
	and bx, 01111111b
	cmp bl, end_of_pile
	je .break
	mov dx, ax
	mov ax, bx
	jmp .loop
.break:
	ret

; ---------------------------------------------------------------------------

; FIXME - bug when the open draw pile has no cards

draw_command:
	mov cl, 0xff		; Max out the counter for find_bottom_of_pile
				; This will be sufficient for all of the cards
				; that will be present.
	xor ah, ah

	cmp [pile_pointers+draw_down_pile_number], byte end_of_pile
	jne .draw_source_pile_has_cards

	; No cards left to pull. Swap the piles
	mov al, byte [pile_pointers+draw_up_pile_number]
	mov [pile_pointers+draw_down_pile_number], byte al

	call find_bottom_of_pile

	mov [first_card+edx], byte 0xff	; Set null byte on next to last entry
	mov [pile_pointers+draw_up_pile_number], byte al
	jmp game_loop

.draw_source_pile_has_cards:
	mov al, byte [pile_pointers+draw_down_pile_number]	; Source pile
	call find_bottom_of_pile

	cmp dl, end_of_pile
	je .draw_source_pile_empty

	mov [first_card+edx], byte 0xff	; Set null byte on next to last entry
	jmp .save_card

.draw_source_pile_empty:
	mov [pile_pointers+draw_down_pile_number], byte end_of_pile

.save_card:

	push ax				; Save our card

	mov al, byte [pile_pointers+draw_up_pile_number]	; Destination pile
	call find_bottom_of_pile

	pop bx				; Old ax; card moved from source pile

	mov [first_card+eax], byte bl		; Set the next pointer to the card that was moved
	jmp game_loop

; ---------------------------------------------------------------------------

; Pile indexes
; a b _ d e f g
; h i j k l m n

; Example keyboard input: mn4k
; - move
; - Source pile: n (see map above)
; - 4th from top
; - Destination pile: k (see map above)

move_command:
	xor ah, ah			; Read keyboard input. The source pile (a-n)
	int 16h
	mov dl, al			; Store it in our counter
	sub dl, 'a'			; Subtract ASCII 'a' to get index
	xor dh, dh

	xor ah, ah			; Read keyboard input. The number of cards to move.
	int 16h
	mov cl, al			; Store it in our counter
	sub cl, '0'			; Subtract ASCII '0' to get index

	push dx				; Save the current source pile number since we need it
					; if the pile becomes empty.

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
	push ax				; Save our card

	xor ah, ah			; Read keyboard input. The destination pile (a-n)
	int 16h
	mov dl, al			; Store it in our counter
	sub dl, 'a'			; Subtract ASCII 'a' to get index
	xor dh, dh

	cmp [pile_pointers+edx], byte end_of_pile ; Is the destination pile already empty?
	jne .move_dest_pile_has_cards

	pop bx				; Old ax; card moved from source pile
	mov [pile_pointers+edx], byte bl
	jmp game_loop

.move_dest_pile_has_cards:
	mov cl, 0xff			; Select last card in list
	xor ah, ah
	mov al, byte [pile_pointers+edx]; Destination pile
	call find_bottom_of_pile

	pop bx				; Old ax; card moved from source pile

	mov [first_card+eax], byte bl		; Set the next pointer to the card that was moved

	jmp game_loop

; ---------------------------------------------------------------------------

	card_values db ' A23456789TJQK'
	family_colors db 7d, 7d, 4d, 4d
	family_symbols db 'CSDH'
	;family_symbols db 0x06d,0x05d,0x04d,0x03d
	;FIXME - why can't we show the symbols instaed?

	; Family - 2 bits
	; - 1 1 hearts
	; - 1 0 diamond
	; - 0 1 spades
	; - 0 0 clubs
	; - First bit is the color (1=black, 0=red)
	; Shown? - 1 bit
	; Unused - 1 bit
	; Card - 4 bits
	; - A=1, 2, 3-10, J=11, Q=12, K=13

	; Pointer to next - 8 bits - 0xff - end of list

	first_card dw 11_0_0_0110_0_0000010b ; 6H  - Top of deck stack - 0000000
	dw 10_0_0_1000_0_0000100b ; 8D  - 0000010
	dw 10_0_0_1010_0_0000110b ; TD  - 0000100
	dw 11_0_0_0111_0_0001000b ; 7H  - 0000110
	dw 00_0_0_1000_0_1111111b ; 8C  - 0001000
	dw 11_0_0_1101_1_1111111b ; KH+ - Drawn card - 0001010
	dw 10_0_0_0010_1_1111111b ; 2D+ - Beginning of stack 7 - 0001100
	dw 10_0_0_1101_0_0010000b ; KD  - Beginning of stack 8 - 0001110
	dw 01_0_0_1001_1_1111111b ; 9S+ - 0010000
	dw 00_0_0_0011_0_0010100b ; 3C  - Beginning of stack 9 - 0010010
	dw 01_0_0_0111_0_0010110b ; 7S  - 0010100
	dw 00_0_0_1010_1_1111111b ; TC+ - 0010110
	dw 00_0_0_0010_0_0011010b ; 2C  - Beginning of stack 10 - 0011000
	dw 01_0_0_1100_0_0011100b ; QS  - 0011010
	dw 10_0_0_0101_0_0011110b ; 5D  - 0011100
	dw 01_0_0_0110_1_1111111b ; 6S+ - 0011110
	dw 01_0_0_0010_0_0100010b ; 2S  - Beginning of stack 11 - 0100000
	dw 11_0_0_1011_0_0100100b ; JH  - 0100010
	dw 11_0_0_0011_0_0100110b ; 3H  - 0100100
	dw 10_0_0_0111_0_0101000b ; 7D  - 0100110
	dw 10_0_0_0110_1_1111111b ; 6D+ - 0101000
	dw 00_0_0_1011_0_0101100b ; JC  - Beginning of stack 12 - 0101010
	dw 00_0_0_0101_0_0101110b ; 5C  - 0101100
	dw 00_0_0_0110_0_0110000b ; 6C  - 0101110
	dw 11_0_0_1001_0_0110010b ; 9H  - 0110000
	dw 11_0_0_0001_0_0110100b ; AH  - 0110010
	dw 00_0_0_1101_1_1111111b ; KC+ - 0110100
	dw 10_0_0_0011_0_0111000b ; 3D  - Beginning of stack 13 - 0110110
	dw 10_0_0_1001_0_0111010b ; 9D  - 0111000
	dw 01_0_0_1010_0_0111100b ; TS  - 0111010
	dw 01_0_0_1000_0_0111110b ; 8S  - 0111100
	dw 01_0_0_1101_0_1000000b ; KS  - 0111110
	dw 11_0_0_0010_0_1000010b ; 2H  - 1000000
	dw 11_0_0_0101_1_1111111b ; 5H+ - 1000010

	pile_pointers db 00000000b
	db 0001010b
	db 1111111b
	db 1111111b
	db 1111111b
	db 1111111b
	db 1111111b
	db 0001100b
	db 0001110b
	db 0010010b
	db 0011000b
	db 0100000b
	db 0101010b
	db 0110110b

	status_message db ok_message

;	times 510-($-$$) db 0
;	dw 0AA55h  ; Boot signature
