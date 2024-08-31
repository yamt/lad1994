.186

	model	small
	codeseg
	assume	ds:@code
	org	100h


CHR_NUM	equ	8+2
CUR_PLN	equ	0e000h

start:
	jmp	main


cur0	label	byte
	db	11111000b
	db	11110000b
	db	11100000b
	db	11010000b
	db	10001000b
	db	00000100b
	db	00000010b
	db	00000001b

pal	db	0,0,0
	db	8,8,8
	db	10,10,10
	db	2,12,2
	db	15,15,15
	db	15,15,8
	db	6,6,6
	db	11,5,15

	db	8 dup(15,15,15)

cur_adr	dw	offset cur0
chr_adr	dw	offset chr

cur_x	dw	320
cur_y	dw	200
dat_adr	dw	?
vrm_adr	dw	?

ad_tmp0	dw	?
ad_tmp1	dw	?

button	db	0ffh

main:
	push	ds
	xor	ax,ax
	mov	ds,ax
	or	byte ptr ds:[500h],100000b
	pop	ds

	call	setgai
	call	ginit
	call	gcls
	
	mov	ah,12h		;テキスト関係
	int	18h

	lea	si,pal
	call	setpal
	call	put_cur

	mov	dx,0ffffh
	call	put_gai
	lea	di,hks_y
	xor	ax,ax
	stosw
	stosw

	call	load_map
	call	manu_map
	call	manu_map2
	call	put_map

main_loop:
	mov	dx,0ffffh
	call	put_gai
	call	vwait
	xor	dx,dx
	call	put_gai
	call	clr_cur
	call	put_cur
	call	key_read
	call	mouse_read
	mov	al,button
	not	al
	and	al,0a0h
	jz	main_loop

	xor	bx,bx
	shl	al,1
	adc	bx,bx
	shl	bx,1
	add	bx,offset chr_n
	call	set_chr
	jmp	main_loop


proc	key_read
	push	ds
	xor	ax,ax
	mov	ds,ax
	mov	ax,word ptr [ds:52ah]
	mov	dx,word	ptr [ds:52ah+3]
	pop	ds
	shr	ax,1
	jc	quit
	test	dl,1000000b
	jnz	save_end
	mov	cx,CHR_NUM
hhhh:
	shr	ax,1
	jc	iiii
	loop	hhhh
iiii:
	or	cx,cx
	jz	kr_end
	neg	cx
	add	cx,CHR_NUM
	mov	chr_n2,cl

kr_end:
	ret


endp

save_end:
	call	save_map
quit:
	mov	ah,11h		;テキスト関係
	int	18h

	call	ginit
	call	flush_key_buf
	call	gcls

	xor	ax,ax		;ファンクションキーを元に戻す
	mov	es,ax
	test	byte ptr es:[711h],1
	jz	not_fnc
	lea	si,fnc_on
esc_loop:
	lodsb
	or	al,al
	jz	not_fnc
	int	29h
	jmp	esc_loop
not_fnc:

	mov	ax,4c00h
	int	21h



proc	put_gai
	mov	gai_flg,dx

	xor	dx,dx
	call	put_gai_main
	inc	dx
	call	put_gai_main
	inc	dx
	call	put_gai_main
	inc	dx
put_gai_main:
	lea	bx,hks_y
	add	bx,dx
	add	bx,dx
	mov	ax,[bx]
	xor	bx,bx
	xchg	bl,ah
	shl	bx,2
	shl	ax,5
	add	bx,ax
	shl	ax,2
	add	bx,ax

	push	ds
	mov	ax,0a000h
	mov	ds,ax
	mov	ax,dx

	shl	ax,8
	add	ax,2156h
	org	$+1
gai_flg	label	word
	org	$-1
	and	ax,0
	mov	[bx],ax
	mov	[bx+2],ax

	pop	ds
	ret

endp


proc	put_cur
	push	es
	mov	dx,cur_y
	mov	ax,dx
	shl	dx,2
	add	dx,ax
	shl	dx,4	;dx*=80

	mov	cx,cur_x
	mov	di,cx
	shr	di,3
	and	cl,111b
	add	di,dx

	mov	ad_tmp0,cx
	mov	ad_tmp1,di

	mov	ax,CUR_PLN
	mov	es,ax

	mov	si,cur_adr

	mov	bp,8
bbbb:
	lodsb
	mov	ah,0
	ror	ax,cl
	stosw
	add	di,80-2
	dec	bp
	jnz	bbbb

	pop	es
	ret
endp

proc	clr_cur
	mov	di,ad_tmp1
	push	ds es
	mov	ax,CUR_PLN
	mov	es,ax
	xor	ax,ax
	mov	cx,8
cccc:
	stosw
	add	di,80-2
	loop	cccc
	
	pop	es ds
	ret
endp

proc	mouse_read
	mov	dx,7fddh
	mov	al,00010000b
	out	dx,al
	mov	al,10010000b
	out	dx,al
	mov	dx,7fd9h
	in	al,dx
	ror	ax,4
	mov	dx,7fddh
	mov	al,10110000b
	out	dx,al
	mov	dx,7fd9h
	in	al,dx
	rol	ax,4
	cbw
	add	ax,cur_x
	mov	bx,640-8
	cmp	ax,bx
	jna	dddd
	mov	ax,bx
	jns	dddd
	xor	ax,ax
dddd:
	mov	cur_x,ax

	mov	dx,7fddh
	mov	al,11010000b
	out	dx,al
	mov	dx,7fd9h
	in	al,dx
	ror	ax,4
	mov	dx,7fddh
	mov	al,11110000b
	out	dx,al
	mov	dx,7fd9h
	in	al,dx
	mov	button,al
	rol	ax,4
	cbw
	add	ax,cur_y

	mov	bx,400-8
	cmp	ax,bx
	jna	eeee
	mov	ax,bx
	jns	eeee
	xor	ax,ax
eeee:
	mov	cur_y,ax

	shr	ax,4
	mov	bx,cur_x
	shr	bx,4
	shl	ax,3
	add	bx,ax
	shl	ax,2
	add	bx,ax
	add	bx,offset maptmp
	mov	dat_adr,bx

	shl	ax,1+4
	mov	bx,cur_x
	shr	bx,4
	shl	bx,1
	add	bx,ax
	shr	ax,2
	add	bx,ax
	mov	vrm_adr,bx


	ret
endp

proc	gcls
	push	es
	mov	ax,CUR_PLN
	mov	es,ax
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

	mov	ah,16h
	mov	dx,0e100h
	int	18h

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

proc	set_chr
	cmp	cur_y,16*16
	jnb	not_fld
	cmp	cur_x,26*16
	jnb	not_fld

	mov	al,[bx]
	cbw
	cmp	al,8
	jnb	hk_js
	mov	bx,dat_adr
	mov	byte ptr [bx],al
	mov	di,vrm_adr
	call	put_chr
	ret
not_fld:
	mov	ax,cur_x
	shr	ax,4
	cmp	ax,9
	ja	not_palchg
	mov	[bx],al
not_palchg:

	ret
endp


hk_js:
	sub	al,8
	lea	bx,hks_y
	add	bx,ax
	add	bx,ax
;	push	bx
;	xor	dx,dx
;	call	put_gai
;	pop	bx

	mov	ax,cur_y
	shr	ax,4
	mov	dx,ax
	mov	[bx  ],al
	mov	ax,cur_x
	shr	ax,4
	mov	[bx+1],al

;	mov	dx,0ffffh
;	call	put_gai

	ret


proc	put_chr
	mov	si,ax
	shl	ax,5
	shl	si,6
	add	si,ax
	add	si,offset chr

	push	es
	mov	ax,0a800h
	mov	es,ax
	mov	cx,16
$01:
	movsw
	add	di,80-2
	loop	$01
	
	sub	di,80*16
	mov	ax,0b000h
	mov	es,ax
	mov	cx,16
$02:
	movsw
	add	di,80-2
	loop	$02

	sub	di,80*16
	mov	ax,0b800h
	mov	es,ax
	mov	cx,16
$03:
	movsw
	add	di,80-2
	loop	$03

	pop	es
	ret
endp

proc	setpal
	mov	ah,0
palset_loop1:
	mov	dx,0a8h
	mov	al,ah
	out	dx,al
palset_loop2:
	lodsb
	inc	dx
	inc	dx
	out	dx,al
	jp	palset_loop2
	inc	ah
	cmp	ah,16
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


proc	setgai

	mov	ax,1b01h
	int	18h

        mov     al,24
        out     7ah,al
        mov     al,1fh
        out     78h,al

	mov	bx,cs
	mov	cx,offset gaijim
	mov	dx,7621h
	mov	ah,1ah
gset_loop:
	pusha
	int	18h
	popa

	inc	dx
	add	cx,2*16
	cmp	dx,7621h+4
	jnz	gset_loop
	
	mov	ax,1b00h
	int	18h
	
	ret
endp


proc	load_map

	call	init_tmp2
	call	open_handle
	jc	lm_end

	mov	ah,3fh
	lea	dx,dat_len
	mov	bx,handle
	mov	cx,1+4
	int	21h
	mov	ah,3fh
	lea	dx,datatmp
	mov	cx,800h
	int	21h

	mov	ax,word ptr jos_y
	xor	bx,bx
	xchg	bl,ah
	shl	ax,3
	add	bx,ax
	shl	ax,2
	add	bx,ax
	add	bx,offset maptmp

	mov	dl,dat_len
	mov	dh,0
	sub	dx,1+4-2
	shr	dx,1
	mov	cx,701h
	lea	di,datatmp
	xor	ax,ax
	call	dat2map

	call	close_handle

lm_end:
	ret
endp

proc	dat2map
	push	bx
	add	bx,ax
	cmp	byte ptr [bx+40*25],1
	jz	d2m_end
	mov	byte ptr [bx+40*25],1
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
	push	si
	call	dat2map
	pop	si
	cmp	si,offset vects+4*2
	jnz	d2m_loop
d2m_end:
	pop	bx
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
	xor	di,di
	lea	si,maptmp
	mov	cl,25
loop_y:
	mov	ch,40
loop_x:
	push	cx
	lodsb
	cbw
	inc	ax
	jz	not_put
	push	si
	dec	ax
	call	put_chr
	pop	si
	sub	di,80*16
not_put:
	inc	di
	inc	di
	pop	cx
	dec	ch
	jnz	loop_x
	add	di,80*15
	loop	loop_y

;	mov	dx,0ffffh
;	call	put_gai

	ret
endp

proc	save_map
	call	init_tmp2

	mov	ax,word ptr jos_y
	xor	bx,bx
	xchg	bl,ah
	mov	cx,bx
	shl	ax,3
	add	bx,ax
	shl	ax,2
	add	bx,ax
	add	bx,offset maptmp

	mov	sp_save,sp

	cmp	byte ptr [bx],0
	jnz	map_error

	lea	di,datatmp
	xor	ax,ax
	call	map2dat

	lea	si,datatmp
	mov	cx,di
	sub	cx,si
	lea	di,maptmp
	mov	dx,16
pack_loop:
	lodsb
	shl	al,8-3
	call	pack	;３ビット
	call	pack
	call	pack
	loop	pack_loop
	cmp	dl,16
	jz	pack_end
	xchg	ax,bx	;最後が１ワードに満たない時
	mov	cl,dl
	shl	ax,cl
	stosw
pack_end:


	call	make_handle

cut_00_loop:
	dec	di
	dec	di
	cmp	word ptr [di],0
	jz	cut_00_loop
	inc	di
	inc	di

	mov	ax,di
	sub	ax,offset maptmp
	add	ax,1+4
	mov	dat_len,al

	mov	ah,40h
	mov	bx,handle
	mov	cx,1+4
	lea	dx,dat_len
	int	21h
	mov	ah,40h
	lea	dx,maptmp
	mov	cx,di
	sub	cx,dx
	int	21h

	call	close_handle

	ret
endp

proc	pack
	shl	al,1
	rcl	bx,1
	dec	dx
	jz	p0
	ret
p0:
	xchg	ax,bx
	stosw
	xchg	ax,bx
	mov	dl,16
	ret
endp

map_error:
	org	$+1
sp_save	label	word
	org	$-1
	mov	sp,0
	pop	ax		;非道

	mov	ah,17h	;beep
	int	18h
	call	vwait
	mov	ah,18h
	int	18h

	ret

proc	map2dat
	push	bx
	add	bx,ax

	cmp	bx,offset maptmp	;マップ適性判定(いいかげん)
	jc	map_error
;	cmp	bx,offset maptmp+40*25
;	jnc	map_error
	cmp	byte ptr [bx],-1
	jz	map_error

	cmp	byte ptr [bx+40*25],1
	jz	m2d_end
	mov	byte ptr [bx+40*25],1
	mov	al,[bx]
	dec	al
	stosb
;	cmp	al,1	;壁
	jz	m2d_end
	lea	si,vects
m2d_loop:
	lodsw
	push	si
	call	map2dat
	pop	si
	cmp	si,offset vects+4*2
	jnz	m2d_loop
m2d_end:
	pop	bx
	ret
endp

vects	dw	-1,+40,+1,-40,-1

proc	close_handle
	mov	ah,3eh
	mov	bx,handle
	int	21h
	ret
endp

proc	open_handle
	mov	ax,3d00h
	lea	dx,path
	int	21h
	mov	handle,ax
	ret
endp

proc	make_handle
	mov	ah,3ch
	lea	dx,path
	xor	cx,cx
	int	21h
	jc	mh_error
	mov	handle,ax
	ret
mh_error:
	jmp	quit
endp

proc	init_tmp2
	lea	di,maptmp2
	xor	ax,ax
	mov	cx,40*25/2
	rep	stosw
	ret
endp

proc	manu_map2
	lea	si,maptmp
	mov	cx,40*25
manu_map2_loop:
	lodsb
	add	al,2
	adc	al,-2
	mov	[si-1],al
	loop	manu_map2_loop

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


;	***** CODE No.     1 *****
gaijim	db	2 dup(?)
;博士１
	db	03h,080h,05h,040h,05h,040h,07h,0c0h,06h,0c0h,03h,080h,0fh,0e0h,017h,0d0h,027h,0c8h,027h,0c8h,07h,0c0h,04h,040h,04h,040h,0ch,060h,01ch,070h,00h,00h
;助手１
	db	03h,0a0h,0ch,060h,0fh,0e0h,07h,0c0h,01h,00h,01fh,0f0h,029h,0e8h,04fh,0e4h,0e9h,0eeh,0afh,0eah,0fh,0e0h,04h,040h,0eh,0e0h,0eh,0e0h,0eh,0e0h,00h,00h

	db	00000000b,00000000b
	db	01111111b,11111000b
	db	01100000b,00001100b
	db	01100000b,00000110b
	db	01100000b,00000110b
	db	01100000b,00000110b
	db	01100000b,00001100b
	db	01111111b,11111000b
	db	01100001b,10000000b
	db	01100000b,11000000b
	db	01100000b,01100000b
	db	01100000b,00110000b
	db	01100000b,00011000b
	db	01100000b,00001100b
	db	01100000b,00000110b
	db	00000000b,00000000b

	db	00000000b,00000000b
	db	01100000b,00000000b
	db	01100000b,00000000b
	db	01100000b,00000000b
	db	01100000b,00000000b
	db	01100000b,00000000b
	db	01100000b,00000000b
	db	01100000b,00000000b
	db	01100000b,00000000b
	db	01100000b,00000000b
	db	01100000b,00000000b
	db	01100000b,00000000b
	db	01100000b,00000000b
	db	01100000b,00000000b
	db	01111111b,11111110b
	db	00000000b,00000000b

fnc_on	db	1bh,'[>1l',0



chr	label	byte
;床
	db	00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
	db	0ffh,0feh,0ffh,0feh,0ffh,0feh,0ffh,0feh,0ffh,0feh,0ffh,0feh,0ffh,0feh,0ffh,0feh,0ffh,0feh,0ffh,0feh,0ffh,0feh,0ffh,0feh,0ffh,0feh,0ffh,0feh,0ffh,0feh,00h,00h
	db	0ffh,0feh,0ffh,0feh,0ffh,0feh,0ffh,0feh,0ffh,0feh,0ffh,0feh,0ffh,0feh,0ffh,0feh,0ffh,0feh,0ffh,0feh,0ffh,0feh,0ffh,0feh,0ffh,0feh,0ffh,0feh,0ffh,0feh,00h,00h

;壁
	db	0ffh,0eeh,0ffh,0feh,0ffh,0feh,0ffh,0feh,0ffh,0feh,0ffh,0feh,0ffh,0feh,07fh,0fch,0ffh,0feh,0ffh,0feh,0ffh,0feh,0ffh,0feh,0ffh,0feh,0ffh,0feh,0efh,0feh,00h,00h
	db	0ffh,0feh,0ffh,0eeh,0ffh,0eeh,0ffh,0eeh,0ffh,0eeh,0ffh,0eeh,0ffh,0eeh,080h,02h,0efh,0feh,0efh,0feh,0efh,0feh,0efh,0feh,0efh,0feh,0efh,0feh,0ffh,0feh,00h,00h
	db	0ffh,0feh,0ffh,0eeh,0ffh,0eeh,0ffh,0eeh,0ffh,0eeh,0ffh,0eeh,0ffh,0eeh,080h,02h,0efh,0feh,0efh,0feh,0efh,0feh,0efh,0feh,0efh,0feh,0efh,0feh,0ffh,0feh,00h,00h

;小包
	db	07eh,0fch,0ffh,0feh,0ffh,0feh,0ffh,0feh,0ffh,0feh,0feh,0feh,0feh,0feh,078h,03ch,0feh,0feh,0feh,0feh,0ffh,0feh,0ffh,0feh,0ffh,0feh,0ffh,0feh,07eh,0fch,00h,00h
	db	07fh,0fch,0feh,0feh,0feh,0feh,0feh,0feh,0feh,0feh,0ffh,0feh,0ffh,0feh,086h,0c2h,0ffh,0feh,0ffh,0feh,0feh,0feh,0feh,0feh,0feh,0feh,0feh,0feh,07fh,0fch,00h,00h
	db	00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,01h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h

;爆弾
	db	01h,00h,09h,020h,022h,088h,0eh,0e0h,059h,034h,011h,010h,033h,098h,0ceh,0e6h,033h,098h,011h,010h,059h,034h,0eh,0e0h,022h,088h,09h,020h,01h,00h,00h,00h
	db	0f1h,01eh,0cfh,0e6h,0bdh,07ah,0b1h,01ah,066h,0cch,06eh,0ech,04eh,0e4h,0f0h,01eh,04eh,0e4h,06eh,0ech,066h,0cch,0b1h,01ah,0bdh,07ah,0cfh,0e6h,0f1h,01eh,00h,00h
	db	0f0h,01eh,0c6h,0c6h,09dh,072h,0b1h,01ah,020h,08h,060h,0ch,041h,04h,033h,098h,041h,04h,060h,0ch,020h,08h,0b1h,01ah,09dh,072h,0c6h,0c6h,0f0h,01eh,00h,00h

;ライト←
	db	01fh,00h,015h,0e0h,04ah,0e8h,045h,070h,080h,0bah,080h,042h,080h,03ah,080h,042h,080h,03ah,080h,042h,080h,0bah,045h,070h,04ah,0e8h,015h,0e0h,01fh,00h,00h,00h
	db	0e0h,08eh,0eah,012h,0b5h,014h,0bah,08eh,03fh,044h,03fh,0bch,03fh,0c4h,03fh,0bch,03fh,0c4h,03fh,0bch,03fh,044h,0bah,08eh,0b5h,014h,0eah,012h,0e0h,08eh,00h,00h
	db	020h,08eh,040h,012h,060h,04h,060h,02h,0e0h,04h,0e0h,018h,0e0h,04h,0e0h,018h,0e0h,04h,0e0h,018h,0e0h,04h,060h,02h,060h,04h,040h,012h,020h,08eh,00h,00h

;ライト↓
	db	0fh,0e0h,00h,00h,02ah,0a8h,01ah,0b0h,07ah,0bch,075h,05ch,068h,02ch,0d0h,016h,0a0h,0ah,0c0h,06h,0a0h,0ah,0c0h,06h,00h,00h,030h,018h,0fh,0e0h,00h,00h
	db	0d0h,016h,0bfh,0fah,095h,052h,065h,04ch,05h,040h,0ah,0a0h,097h,0d2h,02fh,0e8h,05fh,0f4h,03fh,0f8h,05fh,0f4h,03fh,0f8h,0ffh,0feh,0c0h,06h,0f0h,01eh,00h,00h
	db	0d0h,016h,0aah,0aah,085h,042h,045h,044h,00h,00h,00h,00h,080h,02h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,0bfh,0fah,07fh,0fch,0fh,0e0h,00h,00h

;ライト→
	db	01h,0f0h,0fh,050h,02eh,0a4h,01dh,044h,0bah,02h,084h,02h,0b8h,02h,084h,02h,0b8h,02h,084h,02h,0bah,02h,01dh,044h,02eh,0a4h,0fh,050h,01h,0f0h,00h,00h
	db	0e2h,0eh,090h,0aeh,051h,05ah,0e2h,0bah,045h,0f8h,07bh,0f8h,047h,0f8h,07bh,0f8h,047h,0f8h,07bh,0f8h,045h,0f8h,0e2h,0bah,051h,05ah,090h,0aeh,0e2h,0eh,00h,00h
	db	0e2h,08h,090h,04h,040h,0ch,080h,0ch,040h,0eh,030h,0eh,040h,0eh,030h,0eh,040h,0eh,030h,0eh,040h,0eh,080h,0ch,040h,0ch,090h,04h,0e2h,08h,00h,00h

;ライト↑
	db	0fh,0e0h,030h,018h,00h,00h,0c0h,06h,0a0h,0ah,0c0h,06h,0a0h,0ah,0d0h,016h,068h,02ch,075h,05ch,07ah,0bch,01ah,0b0h,02ah,0a8h,00h,00h,0fh,0e0h,00h,00h
	db	0f0h,01eh,0c0h,06h,0ffh,0feh,03fh,0f8h,05fh,0f4h,03fh,0f8h,05fh,0f4h,02fh,0e8h,097h,0d2h,0ah,0a0h,05h,040h,065h,04ch,095h,052h,0bfh,0fah,0d0h,016h,00h,00h
	db	0fh,0e0h,07fh,0fch,0bfh,0fah,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,080h,02h,00h,00h,00h,00h,045h,044h,085h,042h,0aah,0aah,0d0h,016h,00h,00h


path	db	'_tmp_.tmp',0


dat_len	db	0
hks_y	db	17
hks_x	db	8
jos_y	db	17
jos_x	db	9
	db	18
chr_n	db	0
	db	16
chr_n2	db	1

maptmp	db	16 dup(26 dup(-1),40-26 dup(-2))
	db	40 dup(-2)
	db	0,1,2,3,4,5,6,7,0,0,30 dup(-2)
	db	25-16-2 dup(40 dup(-2))
maptmp2	db	40*25 dup(?)

handle	dw	?

datatmp	db	?

	end	start
