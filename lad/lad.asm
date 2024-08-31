.186

	model	small
	codeseg

	org	100h
	assume	ds:@code
;X3

start:
	jmp	main


pal	db	0,0,0
	db	8,8,8
	db	11,11,11
	db	2,12,2
	db	15,15,15
	db	15,15,8
	db	6,6,6
	db	11,5,15

	db	0,0,0

	db	8,8,8
	db	14,14,14
	db	8,8,8
	db	15,15,15
	db	8,8,8

	db	8,8,7

	db	15,15,15

vects	dw	-1,+40,+1,-40,-1
vects2	dw	-100h,+1,+100h,-1

quit:


	mov	ah,0ch
	int	18h

;	mov	ah,11h		;テキスト関係
;	int	18h

	call	ginit
	call	flush_key_buf



;	mov	ax,4c00h
;	int	21h
	int	20h


main:
	push	ds
	xor	ax,ax
	mov	ds,ax
	or	byte ptr ds:[500h],100000b
	pop	ds


;	call	setgai
	call	read_datafile
	jc	quit

reload:
	call	ginit

	mov	ah,0dh
	int	18h
;	mov	ah,12h		;テキスト関係
;	int	18h

	lea	si,pal
	call	setpal

	call	load_map
	call	put_light
	call	make_light
	call	put_map

main_loop:
	call	key_read
	shr	ax,1
	jc	quit
	shr	ax,1
	jc	reload
	shr	ax,1
	jnc	not_inc_stg
	jmp	inc_stage
not_inc_stg:
	shr	ax,1
	jnc	not_dec_stg
	jmp	dec_stage
not_dec_stg:
	shr	ax,1
	jnc	not_jmp_stg
	jmp	jmp_stage
not_jmp_stg:
	mov	dl,move_m
	shr	ax,1
	jnc	n_spc
	xor	dl,1
n_spc:
	mov	move_m,dl
	mov	dh,0
	shl	dx,1
	mov	si,dx
	mov	bp,si	;相手
	xor	bp,2

	mov	bx,word ptr [offset hksm_y+si]
	inc	byte ptr [offset hksm_y+si+8]
	mov	dx,bx

	mov	cx,4
k_loop:
	shr	ax,1
	jc	k_loop_end
	loop	k_loop
	jmp	not_move
k_loop_end:
	dec	cx
	shl	cx,1
	add	cx,offset vects
	mov	di,cx

	xor	ax,ax
	xchg	bh,al
	shl	bx,3
	add	ax,bx
	shl	bx,2
	add	bx,ax
	add	bx,offset maptmp

	mov	ax,si
	shr	ax,1
	shr	ax,1
	sbb	ax,ax
	cmp	[bx+40*25],al
	jnz	not_move

	add	bx,[di]
	add	dx,[di+2*5]

	cmp	[bp+offset hksm_y],dx	;相手を押す
	jnz	not_push_hj
	add	bx,[di]
	cmp	byte ptr [bx],0
	jnz	not_move
	mov	ax,dx
	add	ax,[di+2*5]
	mov	[bp+offset hksm_y],ax

not_push_hj:

	mov	al,[bx]
	cmp	al,1
	jz	not_move		;壁だったら動けない
	jc	movable			;床だったら動く

	mov	cx,dx
	cmp	si,2
	jnz	not_jos
	cmp	al,3
	jnz	not_jos
	mov	byte ptr [bx],0
	mov	bp,0
	dec	bombs
	jmp	gotten
not_jos:

	mov	ax,bx
	add	bx,[di]		;向こう側が、
	add	dx,[di+2*5]
	cmp	byte ptr [bx],0
	jnz	not_move	;床以外だったら動かせないし、
	cmp	[bp+offset hksm_y],dx
	jz	not_move	;相手が居ても動かせない

	xchg	dx,cx		;動かす
	push	bx
	xchg	ax,bx
	mov	al,[bx]
	mov	byte ptr [bx],0
	pop	bx
	mov	[bx],al
	cbw
	mov	bp,ax
gotten:
	call	put_chr2
	push	dx si
	call	make_light
	pop	si dx
movable:
	mov	[si+offset hksm_y],dx	;移動

not_move:
	call	vwait
	call	put_gai


	mov	cx,bombs
	jcxz	inc_stage

	jmp	main_loop

jmp_stage:
	call	gcls
jmp_stage_loop:
	call	flush_key_buf
	mov	di,80*16*11+39-4
	call	vwait
	call	put_stage
key_in:
	mov	ah,6
	mov	dl,0ffh
	int	21h

	cmp	al,0dh
	jnz	n_j_s_r
	mov	ax,stage_m
	cmp	stage,ax
	jb	reload_n
n_j_s_r:
	sub	al,'0'
	cmp	al,10
	jnc	key_in
	cbw
	cwd
	xchg	cx,ax
	mov	ax,stage
	inc	ax
	mov	bx,10
	mul	bx
	add	ax,cx
	dec	ax
	mov	bx,10000
	div	bx
	mov	stage,dx
	jmp	jmp_stage_loop

dec_stage:
	mov	ax,stage
	dec	ax
	jmp	d2i
inc_stage:
	mov	ax,stage
	inc	ax
d2i:
	mov	bx,stage_m
	add	ax,bx
	cwd
	div	bx
	mov	stage,dx
reload_n:
	jmp	reload

proc	key_read
	push	es
	xor	ax,ax
	mov	es,ax
	mov	bx,52ah
	lea	si,key_tbl
key_loop:
	lodsw
	xlat	es:[bx]
	mov	cl,ah
	ror	ax,cl
	shr	ax,1
	rcl	dx,1
	cmp	si,offset key_tbl_end
	jnz	key_loop
	pop	es

	mov	ax,key_old
	mov	key_old,dx
	xor	ax,dx
	and	ax,dx
	ret
endp

key_tbl	label	byte
	db	7,3	;←
	db	7,5	;↓
	db	7,4	;→
	db	7,2	;↑
	db	6,4	;spc
	db	4,3	;j
	db	5,5	;b
	db	5,6	;n
	db	4,1	;g
	db	0,0	;esc

key_tbl_end	=	$

proc	make_light
	lea	di,maptmp2
	mov	cx,40*25/2
	xor	ax,ax
	rep	stosw
	lea	si,maptmp
ms_loop_0:
	lodsb
	sub	al,4
	js	not_shadow
	cbw
	shl	ax,1
	xchg	ax,bx
	mov	bx,[bx+offset vects]
	push	si
	dec	si
ms_loop_1:
	add	si,bx
	cmp	byte ptr [si],0
	jnz	not_floor
	
	mov	byte ptr [si+40*25],0ffh
	jmp	ms_loop_1
not_floor:
	pop	si
not_shadow:
	cmp	si,offset maptmp+40*25
	jnz	ms_loop_0
	;そのまま↓put_light を実行
endp


proc	put_light
	push	es
	mov	ax,0e000h
	mov	es,ax
	xor	di,di
	lea	si,maptmp2
	mov	dl,16	;25;X3
pl_loop_y:
	mov	dh,26	;40;X3
pl_loop_x:
	lodsb
	cmp	[si+40*25-1],al
	jz	not_wt
	mov	ah,al
	mov	cx,24	;16;X3
pl_loop_yy:
	stosw
	stosb	;X3
	add	di,80-3	;X3;-2
	loop	pl_loop_yy
	sub	di,80*24	;80*16;X3
not_wt:
	add	di,3	;X3
	dec	dh
	jnz	pl_loop_x
	add	di,80*23+2	;80*15;X3
	add	si,40-26	;X3'
	dec	dx
	jnz	pl_loop_y
	pop	es
	
	lea	si,maptmp2
	lea	di,maptmp3
	mov	cx,40*25/2
	rep	movsw
	ret
endp

proc	put_gai
	xor	dx,dx
	call	put_gai_main
	mov	dx,2
put_gai_main:
	lea	bx,hksm_y
	add	bx,dx
	mov	cx,[bx+4]
	xor	bp,bp
	call	put_chr2
	mov	cx,[bx]
	mov	[bx+4],cx
	mov	ax,[bx+8]
	shr	ax,3
	and	ax,1
	add	dx,ax
	mov	bp,dx
	add	bp,8
	call	put_chr2
	ret
endp

proc	gcls
	push	es
	push	0a800h
	pop	es
	mov	al,80h
	out	7ch,al
	xor	ax,ax
	out	7eh,al
	out	7eh,al
	out	7eh,al
	out	7eh,al
	xor	di,di
	mov	cx,04000h
	rep	stosw
	out	7ch,al
	pop	es

	ret
endp

	public	ginit
proc	ginit
	mov	al,41h
	out	6ah,al
	mov	al,1h
	out	6ah,al
	mov	ah,40h
	int	18h

	mov	ah,42h
	mov	ch,80h
	int	18h
	mov	al,08h
	out	68h,al
	mov	al,4bh
	out	0a2h,al
	mov	al,0
	out	0a0h,al
	
	out	0a4h,al	;ついでに
	out	0a6h,al
	call	gcls
	ret
endp


vwait:
	IN	AL,60H
	TEST	AL,20H
	JnZ	VWAIT
VWAIT2:	IN	AL,60H
	TEST	AL,20H
	JZ	VWAIT2
	ret

proc	put_chr2	;X2
	push	cx ax
	xor	ax,ax
	xchg	ch,al
	shl	cx,4+2
	mov	di,cx
	shl	cx,1
	add	cx,di
	mov	di,ax
	add	ax,cx
	shl	cx,2
	add	ax,cx
	shl	ax,1
	add	di,ax
	xchg	bp,ax
	call	put_chr
	pop	ax cx
	ret
endp

proc	put_chr
	inc	ax
	jz	not_put
	push	si
	shl	ax,3	;X3
	mov	si,ax
	shl	ax,1
	add	si,ax
	mov	ax,si
	shl	ax,1
	add	si,ax
	mov	ax,si
	shl	ax,1
	add	si,ax

	add	si,offset chr24-3*24*3	;chr-2*16*3;X3
	push	es
	mov	ax,0a800h
	mov	es,ax
	mov	cx,24	;16;X3
$01:
	movsw
	movsb	;X3
	add	di,80-3	;-2;X3
	loop	$01
	
	sub	di,80*24	;80*16;X3
	mov	ax,0b000h
	mov	es,ax
	mov	cx,24	;16;X3
$02:
	movsw
	movsb	;X3
	add	di,80-3	;-2;X3
	loop	$02

	sub	di,80*24	;80*16;X3
	mov	ax,0b800h
	mov	es,ax
	mov	cx,24	;16;X3
$03:
	movsw
	movsb	;X3
	add	di,80-3	;-2;X3
	loop	$03

	pop	es
	pop	si
	sub	di,80*24	;16;X3
not_put:
	ret
endp

proc	setpal
	mov	al,0
palset_loop1:
	mov	dx,0a8h
	out	dx,al
palset_loop2:
	inc	dx
	inc	dx
	outsb
	jp	palset_loop2
	inc	ax
	cmp	al,16
	jnz	palset_loop1
	ret
endp

proc	flush_key_buf
	push	ds
	xor	ax,ax
	mov	ds,ax
	cli
	mov	ds:[528h],ax
	mov	ax,ds:[526h]
	mov	ds:[524h],ax
	sti
	pop	ds
	ret
endp


proc	load_map
		;init_tmp
	lea	di,maptmp
	xor	ax,ax
	dec	ax
	mov	cx,40*25*2/2
	rep	stosw

	mov	si,stage
	shl	si,1
	mov	si,[offset fileptr+si]	;si <- ステージデータのオフセット

	mov	ax,word ptr ds:[si+3]	;jos_y
	xor	bx,bx
	xchg	bl,ah
	shl	ax,3
	add	bx,ax
	shl	ax,2
	add	bx,ax
	add	bx,offset maptmp

	mov	dl,ds:[si]			;dat_len
	mov	dh,0
	sub	dx,1+4-2
	shr	dx,1
	mov	cx,701h
	lea	di,[si+5]
	xor	ax,ax
	call	dat2map

	push	si
	call	manu_map
	pop	si

	inc	si
	lea	di,hksm_y
	push	si
	movsw
	movsw
	pop	si
	movsw
	movsw
	xor	ax,ax
	stosw
	stosw

lm_end:
	ret
endp

proc	manu_map
	lea	si,maptmp
mm_loop_0:
	cmp	byte ptr [si],0ffh
	jnz	not_soto
	mov	cx,4
mm_loop_1:
	mov	di,offset vects-2
	add	di,cx
	add	di,cx
	mov	bx,[di]
	cmp	byte ptr [si+bx],1
	xchg	bx,ax
	jnz	not_kado
	mov	bx,[di+2]
	cmp	byte ptr [si+bx],1
	jnz	not_kado
	add	bx,ax
	cmp	byte ptr [si+bx],1
	jz	not_kado
	mov	byte ptr [si],1
not_kado:
	loop	mm_loop_1
not_soto:
	add	si,1
	cmp	si,offset maptmp+40*25
	jnz	mm_loop_0

	ret
endp

proc	dat2map
	push	si
	push	bx
	add	bx,ax
	cmp	byte ptr [bx+40*25],0
	jz	d2m_end
	mov	byte ptr [bx+40*25],0
	call	unpack_dat
	call	unpack_dat
	call	unpack_dat
	inc	ax
	and	al,111b
	mov	[bx],al
	cmp	al,1	;壁
	jz	d2m_end
	lea	si,vects
d2m_loop:
	lodsw
	call	dat2map
	cmp	si,offset vects+4*2
	jnz	d2m_loop
d2m_end:
	pop	bx
	pop	si
	ret
endp

proc	unpack_dat
	dec	cl
	jz	u1
u0:
	shl	bp,1
	rcl	ax,1
	and	al,ch
	ret
u1:
	mov	bp,ds:[di]
	inc	di
	inc	di
	mov	cl,16
	dec	dx
	jnz	u0
	mov	ch,110b
	jmp	u0
endp

proc	put_map
	mov	di,-80*23-2	;15;X3
	lea	si,maptmp
	xor	dx,dx	;爆弾カウント用
	mov	cl,16	;25*2-1;X3
loop_y:
	add	di,80*23+2	;80*15;X3
	mov	ch,26	;40;X3
loop_x:
	push	cx
	lodsb
	cmp	al,3
	jnz	not_bomb
	inc	dx
not_bomb:
	cbw
	call	put_chr
	add	di,3	;X3
	pop	cx
	dec	ch
	jnz	loop_x
	add	si,40-26	;X3'
	loop	loop_y

	mov	bombs,dx

	mov	di,24*16*80+39-4
	call	put_stage

	call	put_gai

	ret
endp

proc	put_stage
	mov	bx,offset stg_msg+9
	mov	ax,stage
	inc	ax
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

	mov	al,1011b
	out	68h,al

	push	es
	mov	ax,0b800h
	mov	es,ax

	lea	si,[bx-5]
	mov	cl,10
put_loop:
	lodsb
ank:
	mov	ah,09h

byte_put:
	out	0a1h,al
	mov	al,ah
	out	0a3h,al

	mov	dl,00100000b
wr_loop_ank:
	mov	al,dl
	out	0a5h,al
	in	al,0a9h
	inc	dx

	mov	bx,ax
	shl	bx,1
	mov	bp,bx
	shl	bp,1
	not	bp
	and	ax,bp
	or	ax,bx

	stosb
	add	di,80-1
	cmp	dl,00100000b+16
	jnz	wr_loop_ank
	sub	di,80*16-1
	loop	put_loop


	mov	al,1010b
	out	68h,al

	pop	es
	ret
endp


proc	read_datafile

	mov	ax,3d00h
	lea	dx,path
	int	21h
	mov	handle,ax
	jc	orh_end

	xchg	bx,ax
	mov	ah,3fh
	mov	cx,0ffffh	;適当
	lea	dx,datatmp
	int	21h
	mov	bx,dx
	add	bx,ax
	mov	word ptr [bx],0

	lea	bx,datatmp
	lea	di,fileptr
	xor	cx,cx

msp_loop:
	mov	ax,bx
	stosw
	mov	al,[bx]
	mov	ah,0
	add	bx,ax
	or	ax,ax
	loopnz	msp_loop

	neg	cx
	dec	cx
	mov	stage_m,cx

	mov	ah,3eh
	mov	bx,handle
	int	21h
	ret

orh_end:
	ret
endp




path	db	'lstg.dat';,0

chr24	label	byte
;******* lad24rrr ******
	db	00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
	db	0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,00h,00h,00h
	db	0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,00h,00h,00h

	db	0ffh,0ffh,03eh,0ffh,0ffh,03eh,0ffh,0ffh,0beh,0ffh,0ffh,07eh,0ffh,0ffh,0beh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,07eh,0ffh,0ffh,0beh,0ffh,0ffh,07eh,0ffh,0ffh,0beh,01ch,00h,070h,0fbh,0ffh,0feh,0fdh,0ffh,0feh,0fbh,0ffh,0feh,0fdh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0fbh,0ffh,0feh,0fdh,0ffh,0feh,0fbh,0ffh,0feh,0f9h,0ffh,0feh,0f9h,0ffh,0feh,00h,00h,00h
	db	0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,07eh,0ffh,0ffh,0beh,0ffh,0ffh,07eh,0ffh,0ffh,03eh,0ffh,0ffh,03eh,0ffh,0ffh,0beh,0ffh,0ffh,07eh,0ffh,0ffh,0beh,0ffh,0ffh,07eh,0e3h,0ffh,08eh,0fdh,0ffh,0feh,0fbh,0ffh,0feh,0fdh,0ffh,0feh,0fbh,0ffh,0feh,0f9h,0ffh,0feh,0f9h,0ffh,0feh,0fdh,0ffh,0feh,0fbh,0ffh,0feh,0fdh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,00h,00h,00h
	db	0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,07eh,0ffh,0ffh,0beh,0ffh,0ffh,07eh,0ffh,0ffh,03eh,0ffh,0ffh,03eh,0ffh,0ffh,03eh,0ffh,0ffh,03eh,0ffh,0ffh,03eh,0ffh,0ffh,03eh,0e0h,00h,0eh,0f9h,0ffh,0feh,0f9h,0ffh,0feh,0f9h,0ffh,0feh,0f9h,0ffh,0feh,0f9h,0ffh,0feh,0f9h,0ffh,0feh,0fdh,0ffh,0feh,0fbh,0ffh,0feh,0fdh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,00h,00h,00h

	db	01fh,0efh,0f0h,03fh,0efh,0f8h,07fh,0ffh,0fch,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0efh,0feh,0ffh,0efh,0feh,03fh,083h,0f8h,0ffh,0efh,0feh,0ffh,0efh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,07fh,0ffh,0fch,03fh,0efh,0f8h,01fh,0efh,0f0h,00h,00h,00h
	db	0dfh,0efh,0f6h,0bfh,0ffh,0fah,07fh,0efh,0fch,0ffh,0efh,0feh,0ffh,0efh,0feh,0ffh,0efh,0feh,0ffh,0efh,0feh,0ffh,0efh,0feh,0ffh,0efh,0feh,0ffh,0ffh,0feh,0ffh,0ffh,0feh,040h,06ch,04h,0ffh,0ffh,0feh,0ffh,0ffh,0feh,0ffh,0efh,0feh,0ffh,0efh,0feh,0ffh,0efh,0feh,0ffh,0efh,0feh,0ffh,0efh,0feh,0ffh,0efh,0feh,07fh,0efh,0fch,0bfh,0ffh,0fah,0dfh,0efh,0f6h,00h,00h,00h
	db	0c0h,00h,06h,080h,00h,02h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,010h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,080h,00h,02h,0c0h,00h,06h,00h,00h,00h

	db	00h,00h,00h,00h,010h,00h,01h,01h,00h,00h,00h,00h,08h,06ch,020h,01h,0c7h,00h,03h,01h,080h,026h,010h,0c8h,04h,010h,040h,0ch,028h,060h,08h,054h,020h,041h,0abh,04h,08h,054h,020h,0ch,028h,060h,04h,010h,040h,026h,010h,0c8h,03h,01h,080h,01h,0c7h,00h,08h,06ch,020h,00h,00h,00h,01h,01h,00h,00h,010h,00h,00h,00h,00h,00h,00h,00h
	db	0ffh,01h,0feh,0fch,0feh,07eh,0f3h,0ffh,09eh,0efh,0ffh,0eeh,0dfh,093h,0f6h,0deh,038h,0f6h,0bch,0feh,07ah,0b9h,0efh,03ah,07bh,0efh,0bch,073h,0ffh,09ch,077h,0efh,0dch,07eh,044h,0fch,077h,0efh,0dch,073h,0ffh,09ch,07bh,0efh,0bch,0b9h,0efh,03ah,0bch,0feh,07ah,0deh,038h,0f6h,0dfh,093h,0f6h,0efh,0ffh,0eeh,0f3h,0ffh,09eh,0fch,0feh,07eh,0ffh,01h,0feh,00h,00h,00h
	db	0ffh,01h,0feh,0fch,0eeh,07eh,0f2h,0feh,09eh,0efh,0ffh,0eeh,0d7h,093h,0d6h,0deh,010h,0f6h,0bch,010h,07ah,098h,00h,032h,078h,00h,03ch,070h,00h,01ch,070h,010h,01ch,03eh,038h,0f8h,070h,010h,01ch,070h,00h,01ch,078h,00h,03ch,098h,00h,032h,0bch,010h,07ah,0deh,010h,0f6h,0d7h,093h,0d6h,0efh,0ffh,0eeh,0f2h,0feh,09eh,0fch,0eeh,07eh,0ffh,01h,0feh,00h,00h,00h

	db	00h,00h,00h,095h,054h,00h,0cfh,0ffh,0c0h,0a5h,055h,0b0h,0aah,0aah,088h,060h,01h,040h,040h,00h,0b6h,0d4h,00h,042h,088h,00h,0beh,0d4h,00h,042h,088h,00h,0beh,0d4h,00h,042h,088h,00h,0b6h,0d4h,00h,042h,088h,00h,0beh,0d4h,00h,042h,048h,00h,0beh,060h,01h,040h,0aah,0aah,088h,0a5h,055h,0b0h,0cfh,0ffh,0c0h,095h,054h,00h,00h,00h,00h,00h,00h,00h
	db	0ffh,0f1h,0feh,06ah,0aah,03eh,030h,00h,0eh,05ah,0aah,046h,055h,055h,072h,09fh,0feh,0bch,09fh,0ffh,048h,0bh,0ffh,0bch,017h,0ffh,040h,0bh,0ffh,0bch,017h,0ffh,040h,0bh,0ffh,0bch,017h,0ffh,048h,0bh,0ffh,0bch,017h,0ffh,040h,0bh,0ffh,0bch,097h,0ffh,040h,09fh,0feh,0bch,055h,055h,072h,05ah,0aah,046h,030h,00h,0eh,06ah,0aah,03eh,0ffh,0f1h,0feh,00h,00h,00h
	db	0ffh,0f1h,0feh,06ah,0aah,03eh,020h,00h,0eh,060h,00h,06h,070h,00h,02h,0f0h,00h,030h,0e8h,00h,08h,0e8h,00h,030h,0e0h,00h,00h,0e8h,00h,030h,0e0h,00h,00h,0e8h,00h,030h,0e0h,00h,08h,0e8h,00h,030h,0e0h,00h,00h,0e8h,00h,030h,0e0h,00h,00h,0f0h,00h,030h,070h,00h,02h,060h,00h,06h,020h,00h,0eh,06ah,0aah,03eh,0ffh,0f1h,0feh,00h,00h,00h

	db	03h,0ffh,080h,02h,0aah,080h,08h,0a2h,0a0h,012h,0aah,090h,012h,0aah,090h,025h,055h,048h,03ah,0aah,0b8h,034h,00h,058h,028h,00h,028h,070h,00h,01ch,028h,00h,028h,070h,00h,01ch,028h,00h,028h,070h,00h,01ch,028h,00h,028h,070h,00h,01ch,028h,00h,028h,071h,055h,01ch,028h,0aah,0a8h,041h,055h,04h,01ch,00h,070h,027h,055h,0c8h,079h,0ffh,03ch,00h,00h,00h
	db	0f8h,00h,03eh,0f5h,055h,05eh,0e7h,05dh,04eh,0cdh,055h,066h,0cdh,055h,066h,09ah,0aah,0b2h,085h,055h,042h,08bh,0ffh,0a2h,057h,0ffh,0d4h,0fh,0ffh,0e0h,057h,0ffh,0d4h,08fh,0ffh,0e2h,0d7h,0ffh,0d6h,08fh,0ffh,0e2h,0d7h,0ffh,0d6h,08fh,0ffh,0e2h,0d7h,0ffh,0d6h,08eh,0aah,0e2h,0d7h,055h,056h,0beh,0aah,0fah,0e0h,00h,0eh,0d8h,00h,036h,086h,00h,0c2h,00h,00h,00h
	db	0f8h,00h,03eh,0f0h,00h,01eh,0e2h,08h,0eh,0c5h,055h,046h,0c5h,055h,046h,080h,00h,02h,080h,00h,02h,080h,00h,02h,040h,00h,04h,00h,00h,00h,040h,00h,04h,080h,00h,02h,0c0h,00h,06h,080h,00h,02h,0c0h,00h,06h,080h,00h,02h,0c0h,00h,06h,080h,00h,02h,0c3h,055h,06h,08ch,00h,062h,0ffh,0ffh,0feh,0dfh,0ffh,0f6h,087h,0ffh,0c2h,00h,00h,00h

	db	00h,00h,00h,00h,055h,052h,07h,0ffh,0e6h,01bh,055h,04ah,022h,0aah,0aah,05h,00h,0ch,0fah,00h,024h,084h,00h,056h,0fah,00h,022h,084h,00h,056h,0dah,00h,022h,084h,00h,056h,0fah,00h,022h,084h,00h,056h,0fah,00h,022h,084h,00h,056h,0dah,00h,04h,05h,00h,0ch,022h,0aah,0aah,01bh,055h,04ah,07h,0ffh,0e6h,00h,055h,052h,00h,00h,00h,00h,00h,00h
	db	0ffh,01fh,0feh,0f8h,0aah,0ach,0e0h,00h,018h,0c4h,0aah,0b4h,09dh,055h,054h,07ah,0ffh,0f2h,05h,0ffh,0d2h,07bh,0ffh,0a0h,05h,0ffh,0d0h,07bh,0ffh,0a0h,025h,0ffh,0d0h,07bh,0ffh,0a0h,05h,0ffh,0d0h,07bh,0ffh,0a0h,05h,0ffh,0d0h,07bh,0ffh,0a0h,025h,0ffh,0f2h,07ah,0ffh,0f2h,09dh,055h,054h,0c4h,0aah,0b4h,0e0h,00h,018h,0f8h,0aah,0ach,0ffh,01fh,0feh,00h,00h,00h
	db	0ffh,01fh,0feh,0f8h,0aah,0ach,0e0h,00h,08h,0c0h,00h,0ch,080h,00h,01ch,018h,00h,01eh,00h,00h,0eh,018h,00h,02eh,00h,00h,0eh,018h,00h,02eh,020h,00h,0eh,018h,00h,02eh,00h,00h,0eh,018h,00h,02eh,00h,00h,0eh,018h,00h,02eh,020h,00h,02eh,018h,00h,01eh,080h,00h,01ch,0c0h,00h,0ch,0e0h,00h,08h,0f8h,0aah,0ach,0ffh,01fh,0feh,00h,00h,00h

	db	079h,0ffh,03ch,027h,055h,0c8h,01ch,00h,070h,041h,055h,04h,02ah,0aah,028h,071h,055h,01ch,028h,00h,028h,070h,00h,01ch,028h,00h,028h,070h,00h,01ch,028h,00h,028h,070h,00h,01ch,028h,00h,028h,070h,00h,01ch,028h,00h,028h,034h,00h,058h,03ah,0aah,0b8h,025h,055h,048h,012h,0aah,090h,012h,0aah,090h,0ah,08ah,020h,02h,0aah,080h,03h,0ffh,080h,00h,00h,00h
	db	086h,00h,0c2h,0d8h,00h,036h,0e0h,00h,0eh,0beh,0aah,0fah,0d5h,055h,0d6h,08eh,0aah,0e2h,0d7h,0ffh,0d6h,08fh,0ffh,0e2h,0d7h,0ffh,0d6h,08fh,0ffh,0e2h,0d7h,0ffh,0d6h,08fh,0ffh,0e2h,057h,0ffh,0d4h,0fh,0ffh,0e0h,057h,0ffh,0d4h,08bh,0ffh,0a2h,085h,055h,042h,09ah,0aah,0b2h,0cdh,055h,066h,0cdh,055h,066h,0e5h,075h,0ceh,0f5h,055h,05eh,0f8h,00h,03eh,00h,00h,00h
	db	087h,0ffh,0c2h,0dfh,0ffh,0f6h,0ffh,0ffh,0feh,08ch,00h,062h,0c1h,055h,086h,080h,00h,02h,0c0h,00h,06h,080h,00h,02h,0c0h,00h,06h,080h,00h,02h,0c0h,00h,06h,080h,00h,02h,040h,00h,04h,00h,00h,00h,040h,00h,04h,080h,00h,02h,080h,00h,02h,080h,00h,02h,0c5h,055h,046h,0c5h,055h,046h,0e0h,020h,08eh,0f0h,00h,01eh,0f8h,00h,03eh,00h,00h,00h


mens	label	byte

	db	00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
	db	0ffh,0c3h,0feh,0ffh,0bdh,0feh,0ffh,018h,0feh,0ffh,018h,0feh,0ffh,018h,0feh,0ffh,03ah,0feh,0ffh,066h,0feh,0ffh,06dh,0feh,0ffh,0bbh,0feh,0feh,038h,0feh,0fdh,0ffh,07eh,0f8h,07eh,03eh,0f3h,07eh,09eh,0ebh,07eh,0c6h,0ebh,07eh,0d6h,0e3h,07eh,0c6h,0ffh,07eh,0feh,0ffh,00h,0feh,0ffh,03ch,0feh,0ffh,03ch,0feh,0feh,0bdh,07eh,0fdh,0bdh,0beh,0fbh,0bdh,0deh,00h,00h,00h
	db	0ffh,0fbh,0feh,0ffh,0c1h,0feh,0ffh,0a2h,0feh,0ffh,0a2h,0feh,0ffh,0a2h,0feh,0ffh,0c4h,0feh,0ffh,088h,0feh,0ffh,011h,0feh,0ffh,083h,0feh,0ffh,0c7h,0feh,0feh,00h,0feh,0fch,080h,07eh,0fbh,080h,0beh,0f3h,080h,0f6h,0f3h,080h,0e6h,0e3h,080h,0c6h,0ffh,080h,0feh,0ffh,082h,0feh,0ffh,0beh,0feh,0ffh,0beh,0feh,0ffh,03eh,07eh,0feh,03eh,03eh,0fch,03eh,01eh,00h,00h,00h

	db	00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
	db	0ffh,0c3h,0feh,0ffh,0bdh,0feh,0ffh,018h,0feh,0ffh,018h,0feh,0ffh,018h,0feh,0e3h,03ah,0c6h,0ebh,066h,0d6h,0e3h,065h,0ceh,0f5h,0a3h,09eh,0f8h,028h,03eh,0fdh,0ffh,07eh,0feh,07eh,0feh,0ffh,07eh,0feh,0ffh,07eh,0feh,0ffh,07eh,0feh,0ffh,07eh,0feh,0ffh,07eh,0feh,0ffh,00h,0feh,0ffh,03ch,0feh,0ffh,03ch,0feh,0feh,0bdh,07eh,0fdh,0bdh,0beh,0fbh,0bdh,0deh,00h,00h,00h
	db	0ffh,0fbh,0feh,0ffh,0c1h,0feh,0ffh,0a2h,0feh,0ffh,0a2h,0feh,0ffh,0a2h,0feh,0fbh,0c4h,0f6h,0f3h,088h,0e6h,0ebh,09h,0eeh,0f1h,08bh,0deh,0fbh,0d7h,0beh,0fch,00h,07eh,0feh,080h,0feh,0ffh,080h,0feh,0ffh,080h,0feh,0ffh,080h,0feh,0ffh,080h,0feh,0ffh,080h,0feh,0ffh,082h,0feh,0ffh,0beh,0feh,0ffh,0beh,0feh,0ffh,03eh,07eh,0feh,03eh,03eh,0fch,03eh,01eh,00h,00h,00h

	db	00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
	db	0ffh,081h,03eh,0ffh,07ch,0beh,0fch,00h,0beh,0fdh,01h,0beh,0fch,0ffh,07eh,0feh,07eh,0feh,0ffh,01h,0feh,0fch,00h,03eh,0f9h,0ffh,09eh,0f0h,0fh,08eh,0e4h,01fh,086h,0cdh,0ffh,0a2h,0a4h,0fh,0a8h,078h,01fh,09eh,01h,0ffh,080h,031h,0ffh,08ch,0fdh,0ffh,0beh,0fch,082h,03eh,0fch,00h,03eh,0fdh,0e7h,0beh,0fdh,0e7h,0beh,0fdh,0e7h,0beh,0fdh,0e7h,0beh,00h,00h,00h
	db	0ffh,0fdh,0beh,0ffh,083h,03eh,0ffh,01h,03eh,0feh,0feh,03eh,0fdh,00h,07eh,0feh,080h,0feh,0ffh,011h,0feh,0ffh,0ffh,0beh,0feh,00h,05eh,0fah,010h,02eh,0f7h,0e0h,016h,0eeh,00h,02ah,0d6h,010h,034h,083h,0e0h,020h,08ah,00h,022h,032h,00h,0ch,0feh,00h,03eh,0fch,082h,03eh,0ffh,0efh,0beh,0feh,08h,03eh,0feh,08h,03eh,0feh,08h,03eh,0feh,08h,03eh,00h,00h,00h

	db	00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
	db	0ffh,081h,03eh,0ffh,07ch,0beh,0fch,00h,0beh,0fdh,01h,0beh,0fch,0ffh,07eh,0feh,07eh,0feh,0ffh,01h,0feh,0e0h,00h,06h,0c1h,0ffh,082h,0cch,0fh,0b2h,0a4h,01fh,0a8h,079h,0ffh,09eh,00h,0fh,080h,030h,01fh,08ch,0fdh,0ffh,0beh,0fdh,0ffh,0beh,0fdh,0ffh,0beh,0fch,082h,03eh,0fch,00h,03eh,0fdh,0e7h,0beh,0fdh,0e7h,0beh,0fdh,0e7h,0beh,0fdh,0e7h,0beh,00h,00h,00h
	db	0ffh,0fdh,0beh,0ffh,083h,03eh,0ffh,01h,03eh,0feh,0feh,03eh,0fdh,00h,07eh,0feh,080h,0feh,0ffh,011h,0feh,0ffh,0ffh,0f6h,0e2h,00h,0ah,0eeh,010h,03ah,0d7h,0e0h,034h,082h,00h,020h,08ah,010h,022h,033h,0e0h,0ch,0feh,00h,03eh,0feh,00h,03eh,0feh,00h,03eh,0fch,082h,03eh,0ffh,0efh,0beh,0feh,08h,03eh,0feh,08h,03eh,0feh,08h,03eh,0feh,08h,03eh,00h,00h,00h



key_old	dw	0
stage	dw	0		;(ステージＮｏ．)-1

stg_msg	db	'STAGE:',4 dup(?)

tmp	=	$

maptmp	db	40*25 dup(?)
maptmp2	db	40*25 dup(?)
maptmp3	db	40*25 dup(?)

fileptr	dw	2048 dup(?)	;面データのオフセット(2048面分)
stage_m	dw	?		;最終ステージＮｏ．

hksm_y	db	?
hksm_x	db	?
josm_y	db	?
josm_x	db	?
xy_olds	db	4 dup(?)
hksm_s	db	?
move_m	db	?
josm_s	db	?
	db	?

bombs	dw	?	;爆弾数

handle	dw	?

comment~
dat_len	db	?	;+0
hks_y	db	?	;+1
hks_x	db	?	;+2
jos_y	db	?	;+3
jos_x	db	?	;+4
datatmp	db	?	;+5
~

datatmp	db	?

	end	start
