; http://faydoc.tripod.com/cpu/index.htm
; http://www.nasm.us/doc/nasmdoc0.html
; http://www.ctyme.com/intr/int-10.htm
; http://www.theasciicode.com.ar/

%define top_row_num	5d
%define bottom_row_num	9d
%define first_stack_col 5d
%define stack_spacing	10d
%define all_cards_len	104d
%define top_row_first_col_num 0505h		; This is here as an optimization
						; to reduce the binary size by a byte.
						; (Yes, space is that tight.)

%define end_of_pile		00111111b
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
	mov dx, top_row_first_col_num	; Current cursor row / column. Combined into a
					; single call to save 1 byte.

	xor cx, cx			; Current stack number; start at 0
top_of_stack:
	mov bl, byte [pile_pointers+ecx] ; Index of the current stack head
show_stack_card:
	and bx, pile_next_ptr_mask	; Filter out shown bit
	cmp bl, end_of_pile		; At end of pile?
	je nextstack

	xor ah, ah			; Load card
	mov al, byte [first_card+ebx]

	pusha

	bt ax, 7
	jc print_shown_card

print_hidden_card:
	; Set cursor position
	mov ah, 02h		; Set cursor position
	xor bh, bh		; Page number 0
	mov bl, byte 7d
	int 10h

	mov ax, 0e2dh	; High byte - 0eh - teletype output
			; Low byte - 2dh - '-'
	int 10h
	int 10h		; Show a second -. This can be removed
			; to save an additional 2 bytes in the binary.

	jmp finished_printing

print_shown_card:
	push dx		; Save current cursor position
	; Look up the card value and family by dividing the current pointer by 13
	; pointer / 13 = family
	; pointer mod 13 = card value
	mov dx, 0
	mov ax, bx	; Load current card offset
	mov bx, 13	; Number of cards in a family
	div bx		; al has card family, ah has card value

	mov bx, dx	; Current card value
	mov cx, ax	; Current card family
	pop dx		; Restore cursor position

	push bx		; Save current card value

	; Set cursor position
	mov ah, 02h	; Set cursor position
	xor bh, bh	; Page number 0
	mov bl, byte [family_colors+ecx]
	int 10h

	; Display the card value...
	pop ax		; Get the previously saved card value
	mov al, byte [card_values+eax]
	mov ah, 0eh	; Teletype output
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
	mov bx, ax			; Update next card pointer
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

	jmp game_loop	; Error!

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

	; Once the piles have been swapped, let it draw one card off...

.draw_source_pile_has_cards:
	mov dx, draw_down_pile_number	; Input for perform_move_command: source pile number
	mov cl, 0xff			; Card number within the source pile. Max out the
					; counter for find_bottom_of_pile so that we get
					; the last card. This will be sufficient for the
					; number of the cards present.
	mov bx, draw_up_pile_number	; Input for perform_move_command: destination pile number
	call perform_move_command

	; FIXME - toggle the shown flags. Most likely integrate into perform_move_command.

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
	mov bl, al			; Input for perform_move_command: destination pile number

	; Don't allow moving any cards into the first 3 piles
	cmp bl, 3
	jl game_loop			; Error

	call perform_move_command

	jmp game_loop

; ---------------------------------------------------------------------------

	card_values db 'A23456789TJQK'
	family_colors db 7d, 7d, 4d, 4d
	family_symbols db 5, 6, 4, 3

	; Shown? - 1 bit
	; Unused
	; Pointer to next - 6 bits - 111111b - end of list
	; The pointer to next is used to calculate the card value and card family
	; - pointer / 13 = family
	; - pointer mod 13 = value

	first_card	db 0_0_010001b ; Current Position=000000, Current Card=AC, Next Card=5S
	db 0_0_100111b ; Current Position=000001, Current Card=2C, Next Card=AH
	db 0_0_011000b ; Current Position=000010, Current Card=3C, Next Card=QS
	db 0_0_011101b ; Current Position=000011, Current Card=4C, Next Card=4D
	db 0_0_001110b ; Current Position=000100, Current Card=5C, Next Card=2S
	db 0_0_010111b ; Current Position=000101, Current Card=6C, Next Card=JS
	db 0_0_001111b ; Current Position=000110, Current Card=7C, Next Card=3S
	db 0_0_011100b ; Current Position=000111, Current Card=8C, Next Card=3D
	db 0_0_010101b ; Current Position=001000, Current Card=9C, Next Card=9S
	db 0_0_000111b ; Current Position=001001, Current Card=TC, Next Card=8C
	db 0_0_000100b ; Current Position=001010, Current Card=JC, Next Card=5C
	db 0_0_110010b ; Current Position=001011, Current Card=QC, Next Card=QH
	db 1_0_111111b ; Current Position=001100, Current Card=KC, Next Card=End of Pile, Shown
	db 0_0_000110b ; Current Position=001101, Current Card=AS, Next Card=7C
	db 1_0_111111b ; Current Position=001110, Current Card=2S, Next Card=End of Pile, Shown
	db 0_0_100000b ; Current Position=001111, Current Card=3S, Next Card=7D
	db 0_0_001001b ; Current Position=010000, Current Card=4S, Next Card=TC
	db 0_0_010011b ; Current Position=010001, Current Card=5S, Next Card=7S
	db 0_0_100100b ; Current Position=010010, Current Card=6S, Next Card=JD
	db 1_0_111111b ; Current Position=010011, Current Card=7S, Next Card=End of Pile, Shown
	db 0_0_110000b ; Current Position=010100, Current Card=8S, Next Card=TH
	db 0_0_011011b ; Current Position=010101, Current Card=9S, Next Card=2D
	db 0_0_011111b ; Current Position=010110, Current Card=TS, Next Card=6D
	db 0_0_110001b ; Current Position=010111, Current Card=JS, Next Card=JH
	db 0_0_000000b ; Current Position=011000, Current Card=QS, Next Card=AC
	db 0_0_000001b ; Current Position=011001, Current Card=KS, Next Card=2C
	db 0_0_010010b ; Current Position=011010, Current Card=AD, Next Card=6S
	db 0_0_001011b ; Current Position=011011, Current Card=2D, Next Card=QC
	db 0_0_010100b ; Current Position=011100, Current Card=3D, Next Card=8S
	db 0_0_110011b ; Current Position=011101, Current Card=4D, Next Card=KH
	db 0_0_001101b ; Current Position=011110, Current Card=5D, Next Card=AS
	db 0_0_001100b ; Current Position=011111, Current Card=6D, Next Card=KC
	db 0_0_101111b ; Current Position=100000, Current Card=7D, Next Card=9H
	db 1_0_111111b ; Current Position=100001, Current Card=8D, Next Card=End of Pile, Shown
	db 0_0_101010b ; Current Position=100010, Current Card=9D, Next Card=4H
	db 0_0_111111b ; Current Position=100011, Current Card=TD, Next Card=End of Pile
	db 0_0_100011b ; Current Position=100100, Current Card=JD, Next Card=TD
	db 0_0_011110b ; Current Position=100101, Current Card=QD, Next Card=5D
	db 0_0_101000b ; Current Position=100110, Current Card=KD, Next Card=2H
	db 0_0_101100b ; Current Position=100111, Current Card=AH, Next Card=6H
	db 1_0_111111b ; Current Position=101000, Current Card=2H, Next Card=End of Pile, Shown
	db 1_0_111111b ; Current Position=101001, Current Card=3H, Next Card=End of Pile, Shown
	db 0_0_101001b ; Current Position=101010, Current Card=4H, Next Card=3H
	db 0_0_010000b ; Current Position=101011, Current Card=5H, Next Card=4S
	db 0_0_010110b ; Current Position=101100, Current Card=6H, Next Card=TS
	db 0_0_001010b ; Current Position=101101, Current Card=7H, Next Card=JC
	db 1_0_111111b ; Current Position=101110, Current Card=8H, Next Card=End of Pile, Shown
	db 0_0_011010b ; Current Position=101111, Current Card=9H, Next Card=AD
	db 1_0_111111b ; Current Position=110000, Current Card=TH, Next Card=End of Pile, Shown
	db 1_0_111111b ; Current Position=110001, Current Card=JH, Next Card=End of Pile, Shown
	db 0_0_101011b ; Current Position=110010, Current Card=QH, Next Card=5H
	db 0_0_000101b ; Current Position=110011, Current Card=KH, Next Card=6C

	pile_pointers	db 100101b ; Card=QD
	db 101110b ; Card=8H, Shown
	db 111111b ; Card=End of Pile
	db 111111b ; Card=End of Pile
	db 111111b ; Card=End of Pile
	db 111111b ; Card=End of Pile
	db 111111b ; Card=End of Pile
	db 100001b ; Card=8D, Shown
	db 100110b ; Card=KD
	db 100010b ; Card=9D
	db 101101b ; Card=7H
	db 000010b ; Card=3C
	db 000011b ; Card=4C
	db 011001b ; Card=KS

	times 510-($-$$) db 0
	dw 0AA55h  ; Boot signature

