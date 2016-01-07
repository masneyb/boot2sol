; http://www.nasm.us/doc/nasmdoc0.html
; https://www.cs.uaf.edu/2006/fall/cs301/support/x86/
; www.ctyme.com/intr/int-10.htm

%define top_row_num	5d
%define bottom_row_num	9d
%define first_stack_col 5d
%define stack_spacing	10d
%define all_cards_len	104d

%define end_of_stack	0xff

  BITS 16

  ; Set this so that the CS register is set
  ; https://stackoverflow.com/questions/34548325/near-call-jump-tables-dont-always-work-in-a-bootloader
  jmp 0x07c0:$+5

  mov ax, 0x07c0	; Where we're loaded
  mov ds, ax		; Data segment

  mov ax, 0x9000	; Set up stack
  mov ss, ax
  mov sp, 0x0ffff	; Grows downwards!

  mov ah, 0		; Set video mode routine
  mov al, 12h		; 12h = G  80x30  8x16  640x480   16/256K  .   A000 VGA,ATI VIP
  int 10h		; Call BIOS

game_loop:
  mov ah, 06h		; Clear the screen
  mov al, 0
  int 10h

  call print_status_message
  call print_stacks
  call process_keyboard_input
  jmp game_loop

; ---------------------------------------------------------------------------

process_keyboard_input:
  mov ah, 0
  int 16h

  mov ecx, 0
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

check_win_state:
  mov dl, 3
.loop:
  mov ax, [stack_pointers+edl]
  cmp ax, 255d
  je .no_win
  mov ax, [first_card+eax]
  call count_stack
  cmp cl, 0d
  je .done
  inc dl
  cmp dl, 6
  je .done
  jmp .loop
.no_win:
  mov cl, 0d
.done:
  ret


count_stack:
.loop:
  mov dh, 1
  mov ax, [eax+1]
  cmp ax, 255
  je .check
  mov ax, [first_card+eax]
  jmp .loop
.check:
  cmp dh, 13d
  jne .no_win
  mov cl, 1d
  jmp .done
.no_win:
  mov cl, 0d
  jmp .done
.done:
  mov dh, 0d
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

fetch_card_value:
  mov cl, byte [eax+1]
  shl cl, 4d
  shr cl, 4d
  mov ch, 0d
  ret

fetch_card_family:
  mov cl, byte [eax+1]
  shr cl, 6d
  mov ch, 0d
  ret

;fetch_card_shown:
;  mov cl, byte [eax]
;  shl cl, 2d
;  shr cl, 7d
;  mov ch, 0d
;  ret

; ---------------------------------------------------------------------------

print_stacks:
	pusha

	mov dh, top_row_num     	; Current cursor row
	mov dl, first_stack_col 	; Current cursor column

	mov eax, 0h			; Clear 32 bit register
	mov ebx, 0h			; Clear 32 bit register
	mov ecx, 0d			; The current stack - will iterate from 0-13
top_of_stack:
	mov bl, byte [stack_pointers+ecx] ; Index of the current stack head
show_stack_card:
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
	popa
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

  first_card dw 01_0_0_0111_00000010b ; 7S  - Top of deck stack - 00000000
  dw 01_0_0_0011_00000100b ; 3S  - 00000010
  dw 00_0_0_0001_00000110b ; AC  - 00000100
  dw 01_0_0_0101_00001000b ; 5S  - 00000110
  dw 01_0_0_1011_00001010b ; JS  - 00001000
  dw 11_0_0_1000_00001100b ; 8H  - 00001010
  dw 11_0_0_0100_00001110b ; 4H  - 00001100
  dw 11_0_0_0001_00010000b ; AH  - 00001110
  dw 00_0_0_0111_00010010b ; 7C  - 00010000
  dw 10_0_0_1100_00010100b ; QD  - 00010010
  dw 00_0_0_1001_00010110b ; 9C  - 00010100
  dw 11_0_0_1101_00011000b ; KH  - 00010110
  dw 10_0_0_0111_00011010b ; 7D  - 00011000
  dw 10_0_0_0011_00011100b ; 3D  - 00011010
  dw 00_0_0_1011_00011110b ; JC  - 00011100
  dw 00_0_0_1010_00100000b ; TC  - 00011110
  dw 11_0_0_0011_00100010b ; 3H  - 00100000
  dw 11_0_0_1100_00100100b ; QH  - 00100010
  dw 00_0_0_0101_00100110b ; 5C  - 00100100
  dw 01_0_0_0110_00101000b ; 6S  - 00100110
  dw 10_0_0_0101_00101010b ; 5D  - 00101000
  dw 11_0_0_0111_00101100b ; 7H  - 00101010
  dw 00_0_0_0110_11111111b ; 6C  - 00101100
  dw 01_1_0_1010_11111111b ; TS+ - Drawn card - 00101110
  dw 00_1_0_1000_11111111b ; 8C+ - Beginning of stack 7 - 00110000
  dw 10_0_0_1001_00110100b ; 9D  - Beginning of stack 8 - 00110010
  dw 00_1_0_1100_11111111b ; QC+ - 00110100
  dw 01_0_0_0100_00111000b ; 4S  - Beginning of stack 9 - 00110110
  dw 00_0_0_0010_00111010b ; 2C  - 00111000
  dw 01_1_0_1101_11111111b ; KS+ - 00111010
  dw 10_0_0_0100_00111110b ; 4D  - Beginning of stack 10 - 00111100
  dw 11_0_0_0010_01000000b ; 2H  - 00111110
  dw 01_0_0_0010_01000010b ; 2S  - 01000000
  dw 00_1_0_0011_11111111b ; 3C+ - 01000010
  dw 10_0_0_0010_01000110b ; 2D  - Beginning of stack 11 - 01000100
  dw 01_0_0_1001_01001000b ; 9S  - 01000110
  dw 11_0_0_1010_01001010b ; TH  - 01001000
  dw 10_0_0_1010_01001100b ; TD  - 01001010
  dw 01_1_0_1000_11111111b ; 8S+ - 01001100
  dw 10_0_0_0110_01010000b ; 6D  - Beginning of stack 12 - 01001110
  dw 10_0_0_1000_01010010b ; 8D  - 01010000
  dw 10_0_0_0001_01010100b ; AD  - 01010010
  dw 10_0_0_1101_01010110b ; KD  - 01010100
  dw 00_0_0_1101_01011000b ; KC  - 01010110
  dw 01_1_0_0001_11111111b ; AS+ - 01011000
  dw 11_0_0_0101_01011100b ; 5H  - Beginning of stack 13 - 01011010
  dw 11_0_0_0110_01011110b ; 6H  - 01011100
  dw 10_0_0_1011_01100000b ; JD  - 01011110
  dw 00_0_0_0100_01100010b ; 4C  - 01100000
  dw 01_0_0_1100_01100100b ; QS  - 01100010
  dw 11_0_0_1001_01100110b ; 9H  - 01100100
  dw 11_1_0_1011_11111111b ; JH+ - 01100110

  stack_pointers db 00000000b
  db 00101110b
  db 11111111b
  db 11111111b
  db 11111111b
  db 11111111b
  db 11111111b
  db 00110000b
  db 00110010b
  db 00110110b
  db 00111100b
  db 01000100b
  db 01001110b
  db 01011010b

  status_message dw ok_message
  ok_message db 'OK', 0x0
  invalid_op_message db 'NO', 0x0
  draw_message db 'DR', 0x0
  move_message db 'MV', 0x0

  key_inputs db 'dm', 0x00
  key_actions dw draw_command, move_command

  times 510-($-$$) db 0
  dw 0AA55h  ; Boot signature
