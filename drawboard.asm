	;; This prints the outlines of the cards as well as the divider between the top and bottom
	;; of the board. Simply call print_separators to achieve this.
print_separators:

	push dx
	mov dh, 10d
	mov dl, 0d

printhorizontaldivider:	
	mov al, '-'
	call print_char
	inc dl
	cmp dl, 255d
	jne printhorizontaldivider

	mov dh, 0d
	mov dl, 10d
	mov al, '|'
vertline1:	
	call print_char
	inc dh
	cmp dh, 10d
	jne vertline1
	mov dh, 0d
	mov dl, 30d
vertline2:
	call print_char
	inc dh
	cmp dh,10d
	jne vertline2
	mov dh, 0d
	mov dl, 40d
vertline3:
	call print_char
	inc dh
	cmp dh,10d
	jne vertline3
	mov dh,	0d
	mov dl,	50d
vertline4:
	call print_char
	inc dh
	cmp dh,10d
	jne vertline4
	mov dh, 0d
	mov dl, 60d
vertline5:
	call print_char
	inc dh
	cmp dh,10d
	jne vertline5
	mov dh, 0d
	mov dl, 60d
vertline6:
	call print_char
	inc dh
	cmp dh,10d
	jne vertline6
	mov dh, 0d
	mov dl, 70d
vertline7:
	call print_char
	inc dh
	cmp dh,10d
	jne vertline7
	mov dh, 0d
	mov dl, 50d
	
	
	popdx
	ret
