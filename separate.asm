.186
	model	small
	codeseg

	org	100h

start:
	mov	ax,3d00h
	lea	dx,path
	int	21h
	jc	sp_end
	xchg	bx,ax
	mov	ah,3fh
	lea	dx,tmp
	mov	si,dx
	mov	cx,0ffffh
	int	21h
	jc	sp_end
	mov	di,ax
	mov	ah,3eh
	int	21h


sepa_loop:
	mov	al,[si]
	mov	ah,0
	or	ax,ax
	jz	sp_end

	push	si ax

	mov	bx,offset path2+3
	inc	stage
	mov	ax,stage
	mov	cx,4
	mov	bp,10
loop_stg_no:
	cwd
	div	bp
	xchg	ax,dx
	add	al,'0'
	mov	[bx],al
	dec	bx
	xchg	ax,dx
	loop	loop_stg_no

	mov	ah,3ch
	xor	cx,cx
	lea	dx,path2
	int	21h
	jc	sp_end
	xchg	bx,ax

	pop	cx dx
	mov	ah,40h
	int	21h
	jc	sp_end

	mov	ah,3eh
	int	21h

	xchg	ax,cx
	mov	si,dx
	add	si,ax
	sub	di,ax
	jnz	sepa_loop

sp_end:
	int	20h

stage	dw	0

path	db	'lstg.dat',0
path2	db	'0000lstg.s1',0

tmp	dw	0

	end	start
