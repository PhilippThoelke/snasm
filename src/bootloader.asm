org 0x7c00
bits 16

; set video mode to Graphics 320 x 200 pixels with 256 colors
mov ah, 0
mov al, 0x13
int 0x10

; initialize constants
width: equ 320
height: equ 200
grid_size: equ 10

; allocate global variables
direction: dw 1
snake_length: dw 1
apple_x: dw 1
apple_y: dw 1

call reset_snake
call reset_apple

loop:
	; clear the screen with black color
	mov bh, 0
	call clear

	call keyboard_input
	call update_snake
	call draw_snake
	call draw_apple
	call draw_grid
	
	; sleep for 1 second
	mov ax, 100
	call sleep
	jmp loop

; exit program, halt forever
jmp halt

reset_snake:
	mov ax, 2
	mov [direction], ax
	mov ax, 1
	mov [snake_length], ax
	mov ax, 2
	mov [snake_top+0], ax
	mov ax, 3
	mov [snake_top+2], ax
	ret

reset_apple:
	; random value (time since midnight) to dx
	xor ax, ax
	int 0x1a

	; set x coordinate to rand % num_cols
	mov ax, dx
	xor dx, dx
	mov cx, width / grid_size
	div cx
	mov [apple_x], dx

	; random value (time since midnight) to dx
	xor ax, ax
	int 0x1a

	; set y coordinate to rand % num_rows
	mov ax, dx
	xor dx, dx
	mov cx, height / grid_size
	div cx
	mov [apple_y], dx
	ret

keyboard_input:
	; check if the keyboard buffer is non-empty
	xor ax, ax
	mov ah, 0x01
	int 0x16
	jz .done

	; retrieve pressed key and store in ah
	mov ah, 0x00
	int 0x16

	; set direction variable according to the pressed key
	cmp ah, 0x4b
	je .left
	cmp ah, 0x48
	je .up
	cmp ah, 0x4d
	je .right
	cmp ah, 0x50
	je .down

	.done:
		ret

	.left:
		; skip when moving right
		mov ax, [direction]
		cmp ax, 2
		je .done
		; set direction to left (0)
		mov ax, 0
		mov [direction], ax
		ret
	.up:
		; skip when moving down
		mov ax, [direction]
		cmp ax, 3
		je .done
		; set direction to left (1)
		mov ax, 1
		mov [direction], ax
		ret
	.right:
		; skip when moving left
		mov ax, [direction]
		cmp ax, 0
		je .done
		; set direction to left (2)
		mov ax, 2
		mov [direction], ax
		ret
	.down:
		; skip when moving up
		mov ax, [direction]
		cmp ax, 1
		je .done
		; set direction to left (3)
		mov ax, 3
		mov [direction], ax
		ret

update_snake:
	; shift segment data by one
	mov cx, [snake_length]
	.copy_loop:
		push cx

		; compute current segment address: 4*(cx-1)+snake_top
		mov ax, 4
		sub cx, 1
		mul cx
		mov bx, ax
		add bx, snake_top

		; copy data to the next segment
		mov ax, [bx+0]
		mov [bx+4], ax
		mov ax, [bx+2]
		mov [bx+6], ax

		pop cx
		loop .copy_loop

	; create new head segment
	mov ax, [direction]
	cmp ax, 0
	je .left					; move head left
	cmp ax, 1
	je .up						; move head up
	cmp ax, 2
	je .right					; move head right
	cmp ax, 3
	je .down					; move head down
	ret

	.left:
		mov ax, [snake_top+0]
		sub ax, 1
		mov [snake_top+0], ax
		jmp .done
	.up:
		mov ax, [snake_top+2]
		sub ax, 1
		mov [snake_top+2], ax
		jmp .done
	.right:
		mov ax, [snake_top+0]
		add ax, 1
		mov [snake_top+0], ax
		jmp .done
	.down:
		mov ax, [snake_top+2]
		add ax, 1
		mov [snake_top+2], ax
		jmp .done

	.done:
	mov cx, [snake_length]
	.bite_loop:
		push cx

		; don't check for the head colliding with itself
		cmp cx, 1
		je .continue

		; compute current segment address: 4*(cx-1)+snake_top
		mov ax, 4
		sub cx, 1
		mul cx
		mov bx, ax
		add bx, snake_top

		; check for x overlap
		mov ax, [snake_top+0]
		cmp ax, [bx+0]
		jne .continue
		; ceck for y overlap
		mov ax, [snake_top+2]
		cmp ax, [bx+2]
		jne .continue

		; game over
		call reset_snake
		call reset_apple
		pop cx
		ret

		.continue:
		pop cx
		loop .bite_loop

	; do apple and snake head x coordinate match?
	mov ax, [snake_top+0]
	cmp ax, [apple_x]
	jne .abort
	; do apple and snake head y coordinate match?
	mov ax, [snake_top+2]
	cmp ax, [apple_y]
	jne .abort

	mov ax, [snake_length]
	inc ax
	mov [snake_length], ax
	call reset_apple

	.abort:
		ret

draw_snake:
	mov ax, grid_size
	mov [square_top+4], ax		; set width to grid_size
	mov [square_top+6], ax		; set height to grid_size
	mov ax, 12
	mov [square_top+8], ax		; set snake color

	mov cx, [snake_length]
	.loop:
		push cx

		; compute current segment address: 4*(cx-1)+snake_top
		mov ax, 4
		sub cx, 1
		mul cx
		mov bx, ax
		add bx, snake_top

		; compute x position from grid index
		mov dx, grid_size
		mov ax, [bx+0]
		mul dx
		mov [square_top+0], ax

		; compute y position from grid index
		mov dx, grid_size
		mov ax, [bx+2]
		mul dx
		mov [square_top+2], ax
		
		call square					; draw current snake segment

		pop cx
		loop .loop
	ret

draw_apple:
	mov ax, grid_size
	mov [square_top+4], ax		; set width to grid_size
	mov [square_top+6], ax		; set height to grid_size
	mov ax, 2
	mov [square_top+8], ax		; set snake color

	; compute screen space x coordinate
	mov dx, grid_size
	mov ax, [apple_x]
	mul dx
	mov [square_top+0], ax

	; compute screen space y coordinate
	mov dx, grid_size
	mov ax, [apple_y]
	mul dx
	mov [square_top+2], ax

	call square
	ret

; include magic bootloader word at the end of the first sector
times 510-($-$$) db 0
dw 0xaa55

draw_grid:
	; set color to white
	mov ax, 31
	mov [square_top+8], ax		; color = white

	; initialize variables for horizontal bars
	mov ax, 0
	mov [square_top+0], ax		; x = 0
	mov ax, grid_size
	mov [square_top+2], ax		; y = 0
	mov ax, width
	mov [square_top+4], ax		; w = 320
	mov ax, 1
	mov [square_top+6], ax		; h = 1
	.horizontal:
		call square				; draw grid line
		; increment vertical bar position by grid_size
		mov ax, [square_top+2]
		add ax, grid_size
		mov [square_top+2], ax
		; continue until the bottom is reached
		mov ax, [square_top+2]
		cmp ax, height
		jb .horizontal

	; initialize variables for vertical bars
	mov ax, grid_size
	mov [square_top+0], ax		; x = 0
	mov ax, 0
	mov [square_top+2], ax		; y = 0
	mov ax, 1
	mov [square_top+4], ax		; w = 1
	mov ax, height
	mov [square_top+6], ax		; h = 200
	.vertical:
		call square				; draw grid line
		; increment horizontal bar position by grid_size
		mov ax, [square_top+0]
		add ax, grid_size
		mov [square_top+0], ax
		; continue until the right is reached
		mov ax, [square_top+0]
		cmp ax, width
		jb .vertical
	ret

; [square_top] = x, [square_top+2] = y, [square_top+4] = w, [square_top+6] = h, [square_top+8] = color
square:
	; store starting location in si (y * width + x)
	mov ax, [square_top+2]
	mov cx, width
	mul cx
	add ax, [square_top]
	mov si, ax

	mov ax, [square_top+4]		; store width in ax
	mov bx, [square_top+6]		; store height in bx
	mov dl, [square_top+8]		; store color in dl
	
	; initialize the segment register to start at the video memory (after this accessing the stack uses a different segment)
	push ds						; store current value of ds
	push ax						; store current value of ax
	mov ax, 0xa000				; store the start of video memory (0xa0000) / 0x10 in ax
	mov ds, ax					; set the segment register ds to the start of video memory
	pop ax						; restore ax

	; drawing loop
	mov cx, bx					; set the loop counter to the square's height
	.yloop:
		push cx					; save counter from outer y-loop
		mov cx, ax				; set loop counter to the square's width
		.xloop:
			mov [ds:si], dl		; write to video memory
			inc si				; next pixel to the right
			loop .xloop
		pop cx
		sub si, ax				; move si to the left border
		add si, width			; move to the next row
		loop .yloop
	pop ds						; restore segment register
	ret

; bh = clear color
clear:
	mov ah, 0x06				; scroll up window
	mov al, 0					; clear screen
	mov ch, 0					; upper row number
	mov cl, 0					; left column number
	mov dh, 24					; lower row number
	mov dl, 39					; right column number
	int 0x10
	ret

; ax = duration in milliseconds
sleep:
	; multiply ax by 1000 to convert from milliseconds to microseconds
	mov cx, 1000
	mul cx
	; write duration in microseconds to cx:dx
	mov cx, dx
	mov dx, ax
	; call interrupt 0x15 with al=0, ah=0x86 -> wait for cx:dx microseconds
	xor al, al
	mov ah, 0x86
	int 0x15
	ret

halt:
	cli
	hlt
	jmp halt

times 0x5000 - 512 db 0

; declare some storage space right after the bootloader code
square_top: resw 5				; reserve 5 words for drawing squares (x, y, w, h, color)
snake_top: resw 1024			; reserve 1k words for all snake parts
