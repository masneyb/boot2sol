; http://www.nasm.us/doc/nasmdoc0.html
; https://www.cs.uaf.edu/2006/fall/cs301/support/x86/
; www.ctyme.com/intr/int-10.htm

%define top_row_num	5d
%define bottom_row_num	9d
%define first_stack_col 5d
%define stack_spacing	10d
%define all_cards_len	104d

%define end_of_stack	01111111b

  BITS 16

  ; Set this so that the CS register is set
  ; https://stackoverflow.com/questions/34548325/near-call-jump-tables-dont-always-work-in-a-bootloader
  jmp 0x07c0:$+5

  mov ax, 0x07c0	; Where we're loaded
  mov ds, ax		; Data segment

  mov ax, 0x9000	; Set up stack
  mov ss, ax
  mov sp, 0x0ffff	; Grows downwards!

  mov ax, 12h           ; high = 0, set video mode routine
  			; low = 12h = G  80x30  8x16  640x480   16/256K  .   A000 VGA,ATI VIP
  int 10h		; Call BIOS

game_loop:
  mov ax, 0600h		; Clear the screen
  int 10h

  call print_status_message
  call print_stacks
  call process_keyboard_input
  jmp game_loop

; ---------------------------------------------------------------------------

process_keyboard_input:
  xor ah, ah
  int 16h

  xor ecx, ecx
check_key:
  mov dl, byte [key_inputs+ecx]
  cmp dl, 0x0
  je key_not_mapped

  cmp al, [key_inputs+ecx]
  je key_found
  inc ecx
  jmp check_key
key_found:
  call [key_actions+2*ecx]
  jmp keydone
key_not_mapped:
  mov [status_message], word invalid_op_message
keydone:
  ret

; ---------------------------------------------------------------------------

draw_command:
  mov [status_message], word draw_message
  ret

; ---------------------------------------------------------------------------

move_command:
  mov [status_message], word move_message
  ret

; ---------------------------------------------------------------------------

print_status_message:
  xor dx, dx    ; row 0, column 0
  mov bx, 4d
  mov ah, 02h	; set cursor position
  int 10h

  mov si, [status_message]
  mov ah, 0eh
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
  mov ah, 02h		; Set cursor position
  xor bh, bh		; Page number 0
  int 10h
  mov ah, 0eh		; Teletype output
  int 10h
  popa
  ret

; ---------------------------------------------------------------------------

fetch_card_value:
  mov cl, byte [eax+1]
  shl cl, 4d
  shr cl, 4d
  xor ch, ch
  ret

fetch_card_family:
  mov cl, byte [eax+1]
  shr cl, 6d
  xor ch, ch
  ret

;fetch_card_shown:
;  mov cl, byte [eax]
;  shl cl, 2d
;  shr cl, 7d
;  xor ch, ch
;  ret

; ---------------------------------------------------------------------------

print_stacks:
	mov dh, top_row_num     	; Current cursor row
	mov dl, first_stack_col 	; Current cursor column

	xor eax, eax
	xor ebx, ebx
	xor ecx, ecx
top_of_stack:
	mov bl, byte [pile_pointers+ecx] ; Index of the current stack head
show_stack_card:
	and bl, 01111111b		; Filter out shown bit
	cmp bl, end_of_stack
	je nextstack

	mov ax, first_card		; Card with the index
	add ax, bx
	call print_card

	cmp ecx, 7h
	jl dumpstack_nextcard		; Only increment the cursor row if in bottom row
	add dh,2d			; Increment cursor row only on bottom row

dumpstack_nextcard:
	mov bl, byte [eax]		; Update next card pointer
	jmp show_stack_card

nextstack:
	cmp ecx, 13d
	je stackdone

	inc ecx

	cmp ecx, 7h			; What stack are we processing?
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

stackdone:
	ret

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
  ; Shown? - 1 bit
  ; Unused - 1 bit
  ; Card - 4 bits
  ; - A=1, 2, 3-10, J=11, Q=12, K=13

  ; Pointer to next - 8 bits - 0xff - end of list

  first_card dw 11_0_0_1001_0_0000010b ; 9H  - Top of deck stack - 0000000
  dw 10_0_0_0111_0_0000100b ; 7D  - 0000010
  dw 00_0_0_0110_0_0000110b ; 6C  - 0000100
  dw 01_0_0_0010_0_0001000b ; 2S  - 0000110
  dw 10_0_0_0001_0_0001010b ; AD  - 0001000
  dw 11_0_0_0010_0_0001100b ; 2H  - 0001010
  dw 00_0_0_0010_0_0001110b ; 2C  - 0001100
  dw 10_0_0_1001_0_0010000b ; 9D  - 0001110
  dw 01_0_0_1000_0_0010010b ; 8S  - 0010000
  dw 10_0_0_0110_0_0010100b ; 6D  - 0010010
  dw 10_0_0_1101_0_0010110b ; KD  - 0010100
  dw 00_0_0_0100_0_0011000b ; 4C  - 0010110
  dw 11_0_0_1011_0_0011010b ; JH  - 0011000
  dw 11_0_0_0111_0_0011100b ; 7H  - 0011010
  dw 11_0_0_1100_0_0011110b ; QH  - 0011100
  dw 01_0_0_0001_0_0100000b ; AS  - 0011110
  dw 00_0_0_0111_0_0100010b ; 7C  - 0100000
  dw 10_0_0_0010_0_0100100b ; 2D  - 0100010
  dw 01_0_0_1010_0_0100110b ; TS  - 0100100
  dw 00_0_0_1011_0_0101000b ; JC  - 0100110
  dw 10_0_0_0011_0_0101010b ; 3D  - 0101000
  dw 11_0_0_1000_0_0101100b ; 8H  - 0101010
  dw 01_0_0_1001_1_1111111b ; 9S+ - 0101100
  dw 01_0_0_0101_1_1111111b ; 5S+ - Drawn card - 0101110
  dw 00_0_0_0011_1_1111111b ; 3C+ - Beginning of stack 7 - 0110000
  dw 00_0_0_1000_0_0110100b ; 8C  - Beginning of stack 8 - 0110010
  dw 00_0_0_1010_1_1111111b ; TC+ - 0110100
  dw 11_0_0_1101_0_0111000b ; KH  - Beginning of stack 9 - 0110110
  dw 00_0_0_1100_0_0111010b ; QC  - 0111000
  dw 00_0_0_1001_1_1111111b ; 9C+ - 0111010
  dw 11_0_0_0110_0_0111110b ; 6H  - Beginning of stack 10 - 0111100
  dw 10_0_0_1011_0_1000000b ; JD  - 0111110
  dw 10_0_0_0100_0_1000010b ; 4D  - 1000000
  dw 11_0_0_0101_1_1111111b ; 5H+ - 1000010
  dw 11_0_0_1010_0_1000110b ; TH  - Beginning of stack 11 - 1000100
  dw 01_0_0_0011_0_1001000b ; 3S  - 1000110
  dw 11_0_0_0011_0_1001010b ; 3H  - 1001000
  dw 00_0_0_0101_0_1001100b ; 5C  - 1001010
  dw 01_0_0_1100_1_1111111b ; QS+ - 1001100
  dw 01_0_0_0100_0_1010000b ; 4S  - Beginning of stack 12 - 1001110
  dw 01_0_0_0111_0_1010010b ; 7S  - 1010000
  dw 10_0_0_0101_0_1010100b ; 5D  - 1010010
  dw 01_0_0_1101_0_1010110b ; KS  - 1010100
  dw 01_0_0_1011_0_1011000b ; JS  - 1010110
  dw 11_0_0_0100_1_1111111b ; 4H+ - 1011000
  dw 10_0_0_1000_0_1011100b ; 8D  - Beginning of stack 13 - 1011010
  dw 01_0_0_0110_0_1011110b ; 6S  - 1011100
  dw 00_0_0_0001_0_1100000b ; AC  - 1011110
  dw 11_0_0_0001_0_1100010b ; AH  - 1100000
  dw 10_0_0_1100_0_1100100b ; QD  - 1100010
  dw 00_0_0_1101_0_1100110b ; KC  - 1100100
  dw 10_0_0_1010_1_1111111b ; TD+ - 1100110

  pile_pointers db 00000000b
  db 0101110b
  db 1111111b
  db 1111111b
  db 1111111b
  db 1111111b
  db 1111111b
  db 0110000b
  db 0110010b
  db 0110110b
  db 0111100b
  db 1000100b
  db 1001110b
  db 1011010b

  status_message dw ok_message
  ok_message db 'OK', 0x0
  invalid_op_message db 'NO', 0x0
  draw_message db 'DR', 0x0
  move_message db 'MV', 0x0

  key_inputs db 'dm', 0x00
  key_actions dw draw_command, move_command

  times 510-($-$$) db 0
  dw 0AA55h  ; Boot signature
