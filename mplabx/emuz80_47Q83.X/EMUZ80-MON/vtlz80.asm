	page 0
	cpu z80
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;  Very Tiny Language
;
;  Original Source Code was written by T. Nakagawa
;  Source code Language : C
;  	2004/05/23
;  	2004/06/26
;	http://middleriver.chagasi.com/electronics/vtl.html
;
; This code was compiled by SDCC 4.2.0(X64)
; and converted assemble source code by Akihito Honda
;	2023/03/31
;
; Useing Assembler : The Macroassembler AS (1.42 Beta [Bld 227])
; http://john.ccac.rwth-aachen.de:8000/as/
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; target AKI-80, EMUZ80, SuperMEZ80, MEZZ180

AKI80 = 0
RAM12K = 0
RAM8K = 0
SUPER_MEZ = 0
SUPER_MEZ_FULL = 0
SBCZ80 = 1

	if AKI80
RAM_B		equ	8000h
WORK_B		equ	RAM_B
WORK_END	equ	0FE00H
USTACK		equ	0FE90H
MSIZE		equ	7d00h
S_CODE		equ	7500h
	endif

	if RAM12K
RAM_B		equ	0C000h
WORK_B		equ	RAM_B
WORK_END	equ	0EE00H
USTACK		equ	0EE90H
MSIZE		equ	2d00h
S_CODE		equ	7500h
	endif

	if RAM8K
RAM_B		equ	8000h
WORK_B		equ	RAM_B
WORK_END	equ	9E00H
USTACK		equ	9E90H
MSIZE		equ	1E00h
S_CODE		equ	7500h
	endif

	if SUPER_MEZ
RAM_B		equ	40h
;WORK_B		equ	end_code
WORK_END	equ	0FE00H
USTACK		equ	0FE90H
MSIZE		equ	0F400h
S_CODE		equ	RAM_B
	endif

	if SUPER_MEZ_FULL
RAM_B		equ	8000h
WORK_B		equ	RAM_B
WORK_END	equ	0FE00H
USTACK		equ	0FE90H
MSIZE		equ	7d00h
S_CODE		equ	7500h
	endif

	if SBCZ80
RAM_B		equ	8000h
WORK_B		equ	RAM_B
WORK_END	equ	0BE00H
USTACK		equ	0BE90H
MSIZE		equ	3E00h
S_CODE		equ	7500h
	endif

	org	S_CODE

INIT:
	jp	ENTRY		;COLD START
	jp	_warm_boot	;WARM START

_putchr:
	rst	8
	ret

_c_getch:
	rst	10h
	ret

_c_kbhit:
	rst	18h
	jp	z, nokey
	scf	; key exist : CF = 1
	ret
nokey:
	or	a ; No key : CF= 0
	ret

_getchr:
	call	_c_getch
	call	_putchr
	ret

_srand:	; input hl

	ld	(SEED), hl
	ld	(SEEDX), hl
	ret

_rand:	; output de
	push	hl
	
	ld	de, (SEEDX)
	ld	a, d
	or	e
	jr	nz, RND3
	
	ld	de, 1
RND3:
	ld	h, d
	ld	l, e	; mov hl, de
	
	sla	l
	rl	h
	sla	l
	rl	h
	sla	l
	rl	h
	sla	l
	rl	h
	sla	l
	rl	h	; shl hl, 5

	ld	a, e
	xor	l
	ld	l, a
	ld	a, d
	xor	h
	ld	h, a	; xor hl, de
	ld	d, h
	ld	e, l	; de = hl

	sra	h
	rr	l
	sra	h
	rr	l
	sra	h
	rr	l	; sra hl, 3

	ld	a, e
	xor	l
	ld	e, a
	ld	a, d
	xor	h
	ld	d, a	; xor de, hl

	ld	b, d
	ld	c, e	; push de

	ld	de, (SEED)
	ld	a, d
	or	e
	jr	nz, RND4

	ld	de, 1
RND4:
	ld	(SEEDX), de
	ld	h, d
	ld	l, e

	sra	l
	rr	h
	ld	a, d
	xor	h
	ld	d, a
	ld	a, e
	xor	l
	ld	e, a	; xor de, hl

	ld	h, b
	ld	l, c	; pop hl
	
	ld	a, d
	xor	h
	ld	d, a
	ld	a, e
	xor	l
	ld	e, a	; xor de, hl

	ld	(SEED), de	; 0 - FFFFH : -32768 ~ 32767
	ld	h, d
	ld	l, e
	pop	hl
	ret		; output DE

_mach_fin:
	ld	c, 1		; return unimon
	rst	30h

ENTRY:		;COLD START
	ld	sp, USTACK
	ld	h, 0
	ld	l, h
	jp	_main

_warm_boot:
	ld	sp, USTACK
	ld	l, 1
	jp	_main		;key=1

mulint:
	ld	c, l
	ld	b, h
	xor	a
	ld	l, a
	or	b
	ld	b, 10h
	jr	nz, mul01
	ld	b, 8
	ld	a, c

mul00:
	add	hl, hl

mul01:	rl	c
	rla
	jr	nc, mul02
	add	hl,de

mul02:
	djnz	mul00
	ex	de, hl
	ret

moduint:
	call	divuint
	ex	de, hl
	ret

divuint:
	ld	a ,e
	and	80h
	or	d
	jr	nz, div_2
	ld	b, 10h
	adc	hl, hl

div_0:
	rla
	sub	e
	jr	nc, div_1
	add	a, e

div_1:
	ccf
	adc	hl, hl
	djnz	div_0

	ld	e, a
	ex	de, hl
	ret

div_2:
	ld	b, 09
	ld	a, l
	ld	l, h
	ld	h, 00
	rr	l

div_3:
	adc	hl, hl
	sbc	hl, de
	jr	nc, div_4
	add	hl, de

div_4:
	ccf
	rla
	djnz	div_3
	rl	b
	ld	d, b
	ld	e, a
	ret

;vtl.c:61: void breakCheck()
;----------------------------------
; Function breakCheck
; ---------------------------------
_breakCheck:
;vtl.c:65: if (c_kbhit()) {/* check keyin */
	call	_c_kbhit
	ret	NC

;vtl.c:66: c = c_getch();
	call	_c_getch
;vtl.c:67: if(c == 0x03) warm_boot();-		/* force warm boot */
	sub	03h
	jp	Z,_warm_boot
	ret
;vtl.c:71: int main(int key) {
;----------------------------------
; Function main
; ---------------------------------
_main:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	iy, -10
	add	iy, sp
	ld	sp, iy
;vtl.c:75: if (!key) {
	ld	a, h
	or	l
	jr	NZ, ma150
;vtl.c:77: WRITEW(Lmt, MSIZE);-/* RAM End */
	ld	hl, MSIZE
	ld	(_Lct + 88), hl
;vtl.c:78: WRITEW(Bnd, Obj);-	/* Program End */
	ld	hl, 0108h
	ld	(_Lct + 80), hl
;vtl.c:80: srand(1458); /* for RND function */
	ld	hl, 05b2h
	call	_srand
;vtl.c:81: putstr("VTL-C SBCZ80 edition.");
	ld	hl, str_0
	call	_putstr
ma150:
;vtl.c:84: putstr("\r\nOK");
	ld	hl, str_1
	call	_putstr
;vtl.c:85: nmsg:
ma103:
;vtl.c:86: ptr = Lbf + 2;-			/* ptr = 138 */
	ld	hl, 8ah
	ex	(sp), hl
;vtl.c:87: getln(ptr);-				/* buffer address = Lct+138 */
	ld	hl, 8ah
	call	_getln
;vtl.c:88: if (!getnm(&ptr, &n)) {
	ld	hl, 2
	add	hl, sp
	ex	de, hl
	ld	hl, 0
	add	hl, sp
	call	_getnm
	ld	a, d
	or	e
	jp	NZ, ma133
;vtl.c:91: line = Lbf;
	ld	(ix-6), 88h
	ld	(ix-5), 0
;vtl.c:92: WRITEW(line, 0);-/* line = 0 */
	ld	bc, _Lct+0
	ld	hl, 0
	ld	(_Lct + 136), hl
;vtl.c:93: WRITEW(Pcc, 0);-	/* Pcc = 0 */
	ld	(_Lct + 74), hl
ma136:
;vtl.c:95: breakCheck();
	push	bc
	call	_breakCheck
	pop	de
	pop	hl
	push	hl
	push	de
	call	_ordr
	pop	bc
;vtl.c:97: if (READW(Pcc) == 0 || READW(Pcc) == READW(line)) {
	ld	hl, (_Lct + 74)
	ld	a, h
	or	l
	jr	Z, ma110
	ld	de, (_Lct + 74)
	ld	a, (ix-6)
	add	a, c
	ld	(ix-2), a
	ld	a, (ix-5)
	adc	a, b
	ld	(ix-1), a
	ld	l, (ix-2)


	ld	h, (ix-1)


	ld	a, (hl)
	inc	hl
	ld	h, (hl)

	ld	l, a


	cp	a
	sbc	hl, de
	jr	NZ, ma111
ma110:
;vtl.c:99: if (line == Lbf) break;-/* ダイレクトモードの場合 */
	ld	a, (ix-6)
	ld	d, (ix-5)
	sub	88h
	or	d
	jr	Z, ma150
;vtl.c:100: line = nxtln(line);
	push	bc
	ld	l, (ix-6)


	ld	h, (ix-5)


	call	_nxtln
	pop	bc
	ld	(ix-6), e
	ld	(ix-5), d
;vtl.c:101: if (line == READW(Bnd)) break;-/* 最終行まで実行した場合 */
	ld	hl, (_Lct + 80)
	cp	a
	sbc	hl, de
	jp	Z,ma150
	jr	ma112
ma111:
;vtl.c:104: WRITEW(Svp, READW(line) + 1);
	ld	l, (ix-2)


	ld	h, (ix-1)


	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	inc	de
	ld	(_Lct + 70), de
;vtl.c:105: if (fndln(&line)) break;
	push	bc
	ld	hl, 6
	add	hl, sp
	call	_fndln
	pop	bc
	ld	a, d
	or	e
	jp	NZ, ma150
ma112:
;vtl.c:107: WRITEW(Pcc, READW(line));
	ld	l, (ix-6)
	ld	h, (ix-5)
	add	hl, bc
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	ld	(_Lct + 74), de
;vtl.c:108: ptr = line + 2 + 1;
	ld	e, (ix-6)
	ld	d, (ix-5)
	inc	de
	inc	de
	inc	de
	inc	sp
	inc	sp
	push	de
	jp	ma136
ma133:
;vtl.c:111: if (n == 0) {
	ld	a, (ix-7)
	or	(ix-8)
	jr	NZ, ma130
;vtl.c:113: for (ptr = Obj; ptr != READW(Bnd); ) {
	ld	hl, 0108h
	ex	(sp), hl
ma139:
	ld	hl, _Lct+80
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	pop	hl
	push	hl
	cp	a
	sbc	hl, bc
	jp	Z,ma150
;vtl.c:114: breakCheck();
	call	_breakCheck
;vtl.c:115: putnm(READW(ptr));
	ld	a, _Lct & 0ffh
	add	a, (ix-10)
	ld	l, a


	ld	a, _Lct >> 8
	adc	a, (ix-9)
	ld	h, a


	ld	c, (hl)
	inc	hl
	ld	h, (hl)

	ld	l, c


	call	_putnm
;vtl.c:116: ptr += 2;
	pop	bc
	push	bc
	inc	bc
	inc	bc
	inc	sp
	inc	sp
	push	bc
;vtl.c:117: putl(&ptr, '\0');
	xor	a
	push	af
	inc	sp
	ld	hl, 1
	add	hl, sp
	call	_putl
;vtl.c:118: crlf();
	call	_crlf
	jr	ma139
ma130:
;vtl.c:125: WRITEW(Pcc, n);
	ld	bc, _Lct
	ld	de, _Lct + 74
	ld	a, (ix-8)
	ld	(de), a
	inc	de
	ld	a, (ix-7)
	ld	(de), a
;vtl.c:126: if (!fndln(&cur) && READW(cur) == n) {
	ld	hl, 4
	add	hl, sp
	push	bc
	call	_fndln
	pop	bc
;vtl.c:128: for (dst = cur; src != READW(Bnd); WRITEB(dst++, READB(src++))) ;
;vtl.c:126: if (!fndln(&cur) && READW(cur) == n) {
	ld	a, d
	or	e
	jr	NZ, ma118
	ld	l, (ix-6)
	ld	h, (ix-5)
	add	hl, bc
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	ld	l, (ix-8)
	ld	h, (ix-7)
	cp	a
	sbc	hl, de
	jr	NZ, ma118
;vtl.c:127: src = nxtln(cur);
	push	bc
	ld	l, (ix-6)


	ld	h, (ix-5)


	call	_nxtln
	pop	bc
;vtl.c:128: for (dst = cur; src != READW(Bnd); WRITEB(dst++, READB(src++))) ;
	ld	a, (ix-6)
	ld	(ix-2), a
	ld	a, (ix-5)
	ld	(ix-1), a
ma142:
	ld	hl, (_Lct + 80)
	cp	a
	sbc	hl, de
	jr	Z, ma116
	ld	l, (ix-2)
	ld	h, (ix-1)
	add	hl, bc
	inc	(ix-2)
	jr	NZ, ma281
	inc	(ix-1)
ma281:
	push	bc
	pop	iy
	add	iy, de
	inc	de
	ld	a, (iy+0)
	ld	(hl), a
	jr	ma142
ma116:
;vtl.c:129: WRITEW(Bnd, dst);
	ld	hl, _Lct + 80
	ld	a, (ix-2)
	ld	(hl), a
	inc	hl
	ld	a, (ix-1)
	ld	(hl), a
ma118:
;vtl.c:132: if (READB(ptr) == '\0') goto nmsg;-	/*continue;*/
	pop	hl
	push	hl
	add	hl, bc
	ld	a, (hl)
	or	a
	jp	Z, ma103
;vtl.c:133: for (m = 3, tmp = ptr; READB(tmp) != '\0'; m++, tmp++) ;
	pop	de
	push	de
	ld	(ix-2), 03
	ld	(ix-1), 0
ma145:
	ld	l, c
	ld	h, b
	add	hl, de
	ld	a, (hl)
	or	a
	jr	Z, ma122
	inc	(ix-2)
	jr	NZ, ma282
	inc	(ix-1)
ma282:
	inc	de
	jr	ma145
ma122:
;vtl.c:134: if (READW(Bnd) + m < READW(Lmt)) {
	ld	hl, (_Lct + 80)
	ld	a, l
	add	a, (ix-2)
	ld	e, a
	ld	a, h
	adc	a, (ix-1)
	ld	d, a
	ld	hl, (_Lct + 88)
	ld	a, e
	sub	l
	ld	a, d
	sbc	a, h
	jp	NC, ma150
;vtl.c:135: src = READW(Bnd);
	ld	de, (_Lct + 80)
;vtl.c:136: WRITEW(Bnd, READW(Bnd) + m);
	ld	hl, (_Lct + 80)
	ld	a, (ix-2)
	add	a, l
	ld	(ix-4), a
	ld	a, (ix-1)
	adc	a, h
	ld	(ix-3), a
	ld	hl, _Lct + 80
	ld	a, (ix-4)
	ld	(hl), a
	inc	hl
	ld	a, (ix-3)
	ld	(hl), a
;vtl.c:137: for (dst = READW(Bnd); src != cur; WRITEB(--dst, READB(--src))) ;
	dec	hl
	ld	a, (hl)
	ld	(ix-2), a
	inc	hl
	ld	a, (hl)
	ld	(ix-1), a
ma148:
	ld	l, (ix-6)
	ld	h, (ix-5)
	cp	a
	sbc	hl, de
	jr	Z, ma123
	ld	l, (ix-2)
	ld	h, (ix-1)
	dec	hl
	ld	(ix-2), l
	ld	(ix-1), h
	add	hl, bc
	dec	de
	push	bc
	pop	iy
	add	iy, de
	ld	a, (iy+0)
	ld	(hl), a
	jr	ma148
ma123:
;vtl.c:138: WRITEW(src, n);
	ld	l, c
	ld	h, b
	add	hl, de
	ld	a, (ix-8)
	ld	(hl), a
	inc	hl
	ld	a, (ix-7)
	ld	(hl), a
;vtl.c:139: src += 2;
	inc	de
	inc	de
	ld	(ix-4), e
	ld	(ix-3), d
;vtl.c:140: while (WRITEB(src++, READB(ptr++)) != '\0') ;
	ld	a, (ix-10)
	ld	(ix-2), a
	ld	a, (ix-9)
	ld	(ix-1), a
ma124:
	ld	l, (ix-4)
	ld	h, (ix-3)
	add	hl, bc
	inc	(ix-4)
	jr	NZ, ma284
	inc	(ix-3)
ma284:
	ld	e, (ix-2)
	ld	d, (ix-1)
	inc	(ix-2)
	jr	NZ, ma285
	inc	(ix-1)
ma285:
	ld	a, (ix-2)
	ld	(ix-10), a
	ld	a, (ix-1)
	ld	(ix-9), a
	ld	a, e
	add	a, c
	ld	e, a
	ld	a, d
	adc	a, b
	ld	d, a
	ld	a, (de)
	ld	(hl),a
	or	a
	jp	Z, ma103
;vtl.c:141: goto nmsg;-/* continue; */
;vtl.c:148: }
	jr	ma124

;vtl.c:155: static int fndln(unsigned short *ptr) {
;----------------------------------
; Function fndln
; ---------------------------------
_fndln:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	push	af
	ld	(ix-2), l
	ld	(ix-1), h
;vtl.c:156: for (*ptr = Obj; *ptr != READW(Bnd); *ptr = nxtln(*ptr)) {
	pop	bc
	pop	hl
	push	hl
	push	bc
	ld	(hl), 08
	inc	hl
	ld	(hl), 01
fn105:
	ld	l, (ix-2)
	ld	h, (ix-1)
	ld	a, (hl)
	ld	(ix-4), a
	inc	hl
	ld	a, (hl)
	ld	(ix-3), a
	ld	hl, (_Lct + 80)
	pop	bc
	push	bc
	cp	a
	sbc	hl, bc
	jr	Z, fn103
;vtl.c:157: if (READW(*ptr) >= READW(Pcc)) return 0;
	ld	a, _Lct & 0ffh
	add	a, (ix-4)
	ld	l, a


	ld	a, _Lct >> 8
	adc	a, (ix-3)
	ld	h, a


	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	ld	hl, (_Lct + 74)
	ld	a, c
	sub	l
	ld	a, b
	sbc	a, h
	jr	C, fn106
	ld	de, 0
	jr	fn107
fn106:
;vtl.c:156: for (*ptr = Obj; *ptr != READW(Bnd); *ptr = nxtln(*ptr)) {
	pop	hl
	push	hl
	call	_nxtln
	pop	bc
	pop	hl
	push	hl
	push	bc
	ld	(hl), e
	inc	hl
	ld	(hl), d
	jr	fn105
fn103:
;vtl.c:159: return 1;
	ld	de, 1
fn107:
;vtl.c:160: }
	ld	sp, ix
	pop	ix
	ret
;vtl.c:166: static unsigned short nxtln(unsigned short ptr) {
;----------------------------------
; Function nxtln
; ---------------------------------
_nxtln:
	ex	de, hl
;vtl.c:167: for (ptr += 2; READB(ptr++) != '\0'; ) ;
	inc	de
	inc	de
nx103:
	ld	hl, _Lct
	add	hl, de
	inc	de
	ld	a, (hl)
	or	a
	jr	NZ, nx103
;vtl.c:168: return ptr;
;vtl.c:169: }
	ret
;vtl.c:175: static void getln(unsigned short lbf) {
;----------------------------------
; Function getln
; ---------------------------------
_getln:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	dec	sp
	ld	c, l
	ld	b, h
;vtl.c:179: for (p = 0; ; ) {
	ld	de, 0
ge117:
;vtl.c:180: c = getchr();
	push	bc
	push	de
	call	_getchr
	pop	de
	pop	bc
;vtl.c:181: if (c == '\b') {
	ld	(ix-3), a
	sub	08
	jr	NZ, ge114
;vtl.c:182: if (p > 0) p--;
	xor	a
	cp	e
	sbc	a, d
	jp	PO, ge153
	xor	80h
ge153:
	jp	P, ge117
	dec	de
	jr	ge117
ge114:
;vtl.c:184: WRITEB(lbf + p, '\0');
	ld	(ix-2), c
	ld	(ix-1), b
;vtl.c:183: } else if (c == '\r') {
	ld	a, (ix-3)
	sub	0dh
	jr	NZ, ge111
;vtl.c:184: WRITEB(lbf + p, '\0');
	ld	l, (ix-2)
	ld	h, (ix-1)
	add	hl, de
	ld	de, _Lct
	add	hl, de
	ld	(hl), 0
;vtl.c:185: putchr('\n');
	ld	a, 0ah
	call	_putchr
;vtl.c:186: return;
	jr	ge119
ge111:
;vtl.c:187: } else if (c == 0x15 || p + 1 == 74) {
	ld	a, (ix-3)
	sub	15h
	jr	Z, ge106
	ld	l, e


	ld	h, d


	inc	hl
	ld	a, l
	sub	4ah
	or	h
	jr	NZ, ge107
ge106:
;vtl.c:188: crlf();
	push	bc
	call	_crlf
	pop	bc
;vtl.c:189: p = 0;
	ld	de, 0
	jr	ge117
ge107:
;vtl.c:190: } else if (c <= 0x1f) {
	ld	a, 1fh
	sub	(ix-3)
	jr	NC, ge117
;vtl.c:192: WRITEB(lbf + p++, c);
	ex	de, hl
	ld	a, l
	add	a, (ix-2)
	ld	l, a


	ld	a, h
	adc	a, (ix-1)
	ld	h, a


	push	de
	ld	de, _Lct
	add	hl, de
	pop	de
	ld	a, (ix-3)
	ld	(hl), a
	jr	ge117
ge119:
;vtl.c:195: }
	ld	sp, ix
	pop	ix
	ret
;vtl.c:203: static int getnm(unsigned short *ptr, unsigned short *n) {
;----------------------------------
; Function getnm
; ---------------------------------
_getnm:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	push	af
	push	af
	ld	(ix-2), l
	ld	(ix-1), h
	ld	(ix-4), e
	ld	(ix-3), d
;vtl.c:204: if (!num(*ptr)) return 0;
	ld	l, (ix-2)
	ld	h, (ix-1)
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	ex	de, hl
	call	_num
	ld	a, d
	or	e
	jr	NZ, gt102
	ld	de, 0
	jr	gt106
gt102:
;vtl.c:205: *n = 0;
	pop	bc
	pop	hl
	push	hl
	push	bc
	xor	a
	ld	(hl), a
	inc	hl
	ld	(hl), a
;vtl.c:206: do {
gt103:
;vtl.c:207: *n *= 10;
	ld	l, (ix-4)
	ld	h, (ix-3)
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	ld	l, c
	ld	h, b
	add	hl, hl
	add	hl, hl
	add	hl, bc
	add	hl, hl
	ex	de, hl
	pop	bc
	pop	hl
	push	hl
	push	bc
	ld	(hl), e
	inc	hl
	ld	(hl), d
;vtl.c:208: *n += READB((*ptr)++) - '0';
	ld	l, (ix-2)
	ld	h, (ix-1)
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	ld	l, c
	ld	h, b
	inc	hl
	ex	(sp), hl
	ld	l, (ix-2)
	ld	h, (ix-1)
	ld	a, (ix-6)
	ld	(hl), a
	inc	hl
	ld	a, (ix-5)
	ld	(hl), a
	ld	hl, _Lct
	add	hl, bc
	ld	c, (hl)
	ld	b, 0
	ld	a, c
	add	a, 0d0h
	ld	l, a


	ld	a, b
	adc	a, 0ffh
	ld	h, a


	add	hl, de
	ex	de, hl
	pop	bc
	pop	hl
	push	hl
	push	bc
	ld	(hl), e
	inc	hl
	ld	(hl), d
;vtl.c:209: } while (num(*ptr));
	pop	hl
	push	hl
	call	_num
	ld	a, d
	or	e
	jr	NZ, gt103
;vtl.c:210: return 1;
	ld	de, 1
gt106:
;vtl.c:211: }
	ld	sp, ix
	pop	ix
	ret
;vtl.c:217: static int num(unsigned short ptr) {
;----------------------------------
; Function num
; ---------------------------------
_num:
;vtl.c:218: return ('0' <= READB(ptr) && READB(ptr) <= '9');
	ld	de, _Lct
	add	hl, de
	ld	c, (hl)
	ld	a, c
	sub	30h
	jr	C, nu103
	ld	a, 39h
	sub	c
	jr	NC, nu104
nu103:
	ld	e, 00
	jr	nu105
nu104:
	ld	e, 01
nu105:
	ld	d, 00
;vtl.c:219: }
	ret
;vtl.c:225: static void ordr(unsigned short ptr) {
;----------------------------------
; Function ordr
; ---------------------------------
_ordr:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	push	af
	push	af
	dec	sp
	ld	(ix-2), l
	ld	(ix-1), h
;vtl.c:229: getvr(&ptr, &c, &adr);-/* 左辺値のアドレスを求める */
	ld	hl, 1
	add	hl, sp
	push	hl
	ld	hl, 2
	add	hl, sp
	ex	de, hl
	ld	hl, 7
	add	hl, sp
	call	_getvr
;vtl.c:230: ptr++;-/* 代入の'='を読み飛ばす */
	inc	(ix-2)
	jr	NZ, or134
	inc	(ix-1)
or134:
;vtl.c:232: if (READB(ptr) == '"') {
	ld	bc, _Lct
	ld	l, (ix-2)
	ld	h, (ix-1)
	add	hl, bc
	ld	a, (hl)
	sub	22h
	jr	NZ, or110
;vtl.c:233: ptr++;
	inc	(ix-2)
	jr	NZ, or137
	inc	(ix-1)
or137:
;vtl.c:234: putl(&ptr, '"');
	push	bc
	ld	a, 22h
	push	af
	inc	sp
	ld	hl, 8
	add	hl, sp
	call	_putl
	pop	bc
;vtl.c:235: if (READB(ptr) != ';') crlf();
	ld	l, (ix-2)
	ld	h, (ix-1)
	add	hl, bc
	ld	a, (hl)
	sub	3bh
	jr	Z, or111
	call	_crlf
	jr	or111
or110:
;vtl.c:239: expr(&ptr, &val);-/* 右辺値を計算する */
	push	bc
	ld	hl, 5
	add	hl, sp
	ex	de, hl
	ld	hl, 7
	add	hl, sp
	call	_expr
	pop	bc
;vtl.c:241: if (c == '$') {
	ld	a, (ix-7)
	sub	24h
	jr	NZ, or107
;vtl.c:242: putchr(val & 0xff);
	ld	a, (ix-4)
	call	_putchr
	jr	or111
or107:
;vtl.c:243: } else if ((c -= '?') == 0) {
	ld	a, (ix-7)
	add	a, 0c1h
	ld	(ix-7), a
	or	a
	jr	NZ, or104
;vtl.c:244: putnm(val);
	ld	l, (ix-4)


	ld	h, (ix-3)


	call	_putnm
	jr	or111
or104:
;vtl.c:248: WRITEW(adr, val);
	ld	l, (ix-6)
	ld	h, (ix-5)
	add	hl, bc
	ld	a, (ix-4)
	ld	(hl), a
	inc	hl
	ld	a, (ix-3)
	ld	(hl), a
;vtl.c:256: r = rand();
	push	bc
	call	_rand
	pop	bc
;vtl.c:258: WRITEW(Rnd, r);
	ld	(_Lct + 82), de
or111:
;vtl.c:261: return;
;vtl.c:262: }
	ld	sp, ix
	pop	ix
	ret
;vtl.c:268: static void expr(unsigned short *ptr, unsigned short *val) {
;----------------------------------
; Function expr
; ---------------------------------
_expr:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	ld	c, l
	ld	b, h
	inc	sp
	inc	sp
	push	de
;vtl.c:271: factr(ptr, val);
	push	bc
	pop	hl
	pop	de
	push	de
	push	hl
	ld	l, c


	ld	h, b


	call	_factr
	pop	bc
;vtl.c:272: while ((c = READB(*ptr)) != '\0' && c != ')') {
ex102:
	ld	l, c
	ld	h, b
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	ld	hl, _Lct
	add	hl, de
	ld	a, (hl)


	or	a,a
	jr	Z, ex104
	sub	29h
	jr	Z, ex104
;vtl.c:273: term(ptr, val);
	push	bc
	pop	hl
	pop	de
	push	de
	push	hl
	ld	l, c


	ld	h, b


	call	_term
	pop	bc
	jr	ex102
ex104:
;vtl.c:275: (*ptr)++;
	inc	de
	ld	a, e
	ld	(bc), a
	inc	bc
	ld	a, d
	ld	(bc), a
;vtl.c:276: return;
;vtl.c:277: }
	ld	sp, ix
	pop	ix
	ret
;vtl.c:283: static void factr(unsigned short *ptr, unsigned short *val) {
;----------------------------------
; Function factr
; ---------------------------------
_factr:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	push	af
	push	af
	dec	sp
	ld	c, l
	ld	b, h
	ld	(ix-2), e
	ld	(ix-1), d
;vtl.c:286: if (READB(*ptr) == '\0') {
	ld	l, c
	ld	h, b
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	ld	hl, _Lct
	add	hl, de
	ld	a, (hl)
	or	a
	jr	NZ, fa102
;vtl.c:287: *val = 0;
	ld	l, (ix-2)
	ld	h, (ix-1)
	xor	a
	ld	(hl), a
	inc	hl
	ld	(hl), a
;vtl.c:288: return;
	jp	fa114
fa102:
;vtl.c:291: if (getnm(ptr, val)) return;
	push	bc
	ld	e, (ix-2)
	ld	d, (ix-1)
	ld	l, c


	ld	h, b


	call	_getnm
	pop	bc
	ld	a, d
	or	e
	jp	NZ,fa114
;vtl.c:293: c = READB((*ptr)++);
	ld	l, c
	ld	h, b
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	ld	l, e
	ld	h, d
	inc	hl
	ld	(ix-4), l
	ld	(ix-3), h
	ld	l, c
	ld	h, b
	ld	a, (ix-4)
	ld	(hl), a
	inc	hl
	ld	a, (ix-3)
	ld	(hl), a
	ld	hl, _Lct
	add	hl, de
	ld	a, (hl)
	ld	(ix-7), a
;vtl.c:294: if (c == '?') {
	cp	3fh
	jr	NZ, fa112
;vtl.c:297: tmp = Lbf;
	ld	(ix-6), 88h
	ld	(ix-5), 0
;vtl.c:298: getln(tmp);
	ld	hl, 88h
	call	_getln
;vtl.c:299: expr(&tmp, val);
	ld	e, (ix-2)
	ld	d, (ix-1)
	ld	hl, 1
	add	hl, sp
	call	_expr
	jr	fa113
fa112:
;vtl.c:300: } else if (c == '$') {
	cp	24h
	jr	NZ, fa109
;vtl.c:301: *val = getchr();
	call	_getchr
	ld	c, a
	ld	b, 0
	ld	l, (ix-2)
	ld	h, (ix-1)
	ld	(hl), c
	inc	hl
	ld	(hl), b
	jr	fa113
fa109:
;vtl.c:302: } else if (c == '(') {
	sub	28h
	jr	NZ, fa106
;vtl.c:303: expr(ptr, val);
	ld	e, (ix-2)
	ld	d, (ix-1)
	ld	l, c


	ld	h, b


	call	_expr
	jr	fa113
fa106:
;vtl.c:307: (*ptr)--;
	ld	l, c
	ld	h, b
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	dec	de
	ld	l, c
	ld	h, b
	ld	(hl), e
	inc	hl
	ld	(hl), d
;vtl.c:308: getvr(ptr, &c, &adr);
	ld	hl, 1
	add	hl, sp
	push	hl
	ld	hl, 2
	add	hl, sp
	ex	de, hl
	ld	l, c


	ld	h, b


	call	_getvr
;vtl.c:309: *val = READW(adr);-/* 変数か配列の値を得る */
	ld	a, _Lct & 0ffh
	add	a, (ix-6)
	ld	l, a


	ld	a, _Lct >> 8
	adc	a, (ix-5)
	ld	h, a


	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	ld	l, (ix-2)
	ld	h, (ix-1)
	ld	(hl), c
	inc	hl
	ld	(hl), b
fa113:
;vtl.c:311: return;
fa114:
;vtl.c:312: }
	ld	sp, ix
	pop	ix
	ret
;vtl.c:318: static void term(unsigned short *ptr, unsigned short *val) {
;----------------------------------
; Function term
; ---------------------------------
_term:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	iy, -8
	add	iy, sp
	ld	sp, iy
	ld	c, l
	ld	b, h
	ld	(ix-2), e
	ld	(ix-1), d
;vtl.c:322: c = READB((*ptr)++);
	ld	l, c
	ld	h, b
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	ld	l, e
	ld	h, d
	inc	hl
	ld	(ix-4), l
	ld	(ix-3), h
	ld	l, c
	ld	h, b
	ld	a, (ix-4)
	ld	(hl), a
	inc	hl
	ld	a, (ix-3)
	ld	(hl), a
	ld	hl, _Lct
	add	hl, de
	ld	a, (hl)
	ld	(ix-3), a
;vtl.c:323: factr(ptr, &val2);
	ld	hl, 0
	add	hl, sp
	ex	de, hl
	ld	l, c


	ld	h, b


	call	_factr
;vtl.c:325: *val *= val2;
	ld	l, (ix-2)
	ld	h, (ix-1)
	ld	a, (hl)
	ld	(ix-6), a
	inc	hl
	ld	a, (hl)
	ld	(ix-5), a
;vtl.c:324: if (c == '*') {
	ld	a, (ix-3)
	sub	2ah
	jr	NZ, tm117
;vtl.c:325: *val *= val2;
	pop	de
	push	de
	ld	l, (ix-6)


	ld	h, (ix-5)


	call	mulint
	ld	l, (ix-2)
	ld	h, (ix-1)
	ld	(hl), e
	inc	hl
	ld	(hl), d
	jp	tm118
tm117:
;vtl.c:326: } else if (c == '+') {
	ld	a, (ix-3)
	sub	2bh
	jr	NZ, tm114
;vtl.c:327: *val += val2;
	ld	a, (ix-6)
	add	a, (ix-8)
	ld	(ix-4), a
	ld	a, (ix-5)
	adc	a, (ix-7)
	ld	(ix-3), a
	ld	l, (ix-2)
	ld	h, (ix-1)
	ld	a, (ix-4)
	ld	(hl), a
	inc	hl
	ld	a, (ix-3)
	ld	(hl), a
	jp	tm118
tm114:
;vtl.c:328: } else if (c == '-') {
	ld	a, (ix-3)
	sub	2dh
	jr	NZ, tm111
;vtl.c:329: *val -= val2;
	ld	a, (ix-6)
	sub	(ix-8)
	ld	c, a
	ld	a, (ix-5)
	sbc	a, (ix-7)
	ld	b, a
	ld	l, (ix-2)
	ld	h, (ix-1)
	ld	(hl), c
	inc	hl
	ld	(hl), b
	jp	tm118
tm111:
;vtl.c:330: } else if (c == '/') {
	ld	a, (ix-3)
	sub	2fh
	jr	NZ, tm108
;vtl.c:331: WRITEW(Rmd, *val % val2);
	pop	de
	push	de
	ld	l, (ix-6)


	ld	h, (ix-5)


	call	moduint
	ld	(_Lct + 78), de
;vtl.c:332: *val /= val2;
	ld	l, (ix-2)
	ld	h, (ix-1)
	ld	c, (hl)
	inc	hl
	ld	h, (hl)

	pop	de
	push	de
	ld	l, c


	call	divuint
	ld	l, (ix-2)
	ld	h, (ix-1)
	ld	(hl), e
	inc	hl
	ld	(hl), d
	jr	tm118
tm108:
;vtl.c:333: } else if (c == '=') {
	ld	a, (ix-3)
	sub	3dh
	jr	NZ, tm105
;vtl.c:334: *val = (*val == val2);
	ld	a, (ix-6)
	sub	(ix-8)
	jr	NZ, tm161
	ld	a, (ix-5)
	sub	(ix-7)
	ld	a, 01
	jr	Z, tm162
tm161:
	xor	a
tm162:
	ld	c, a
	ld	b, 0
	ld	l, (ix-2)
	ld	h, (ix-1)
	ld	(hl), c
	inc	hl
	ld	(hl), b
	jr	tm118
tm105:
;vtl.c:336: *val = (*val >= val2);
	ld	a, (ix-6)
	sub	(ix-8)
	ld	a, (ix-5)
	sbc	a, (ix-7)
	ld	a, 0
	rla
	ld	c, a
;vtl.c:335: } else if (c == '>') {
	ld	a, (ix-3)
	sub	3eh
	jr	NZ, tm102
;vtl.c:336: *val = (*val >= val2);
	ld	a, c
	xor	01
	ld	c, a
	ld	b, 0
	ld	l, (ix-2)
	ld	h, (ix-1)
	ld	(hl), c
	inc	hl
	ld	(hl), b
	jr	tm118
tm102:
;vtl.c:338: *val = (*val < val2);
	ld	b, 0
	ld	l, (ix-2)
	ld	h, (ix-1)
	ld	(hl), c
	inc	hl
	ld	(hl), b
tm118:
;vtl.c:340: return;
;vtl.c:341: }
	ld	sp, ix
	pop	ix
	ret
;vtl.c:347: static void getvr(unsigned short *ptr, unsigned char *c, unsigned short *adr)
;----------------------------------
; Function getvr
; ---------------------------------
_getvr:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	push	af
	push	af
	ld	c, l
	ld	b, h
	ld	(ix-2), e
	ld	(ix-1), d
;vtl.c:351: *c = READB((*ptr)++);
	ld	l, c
	ld	h, b
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	ld	l, e
	ld	h, d
	inc	hl
	ld	(ix-4), l
	ld	(ix-3), h
	ld	l, c
	ld	h, b
	ld	a, (ix-4)
	ld	(hl), a
	inc	hl
	ld	a, (ix-3)
	ld	(hl), a
	ld	hl, _Lct
	add	hl, de
	ld	d, (hl)
	ld	l, (ix-2)
	ld	h, (ix-1)
	ld	(hl), d
;vtl.c:352: if (*c == ':') {
	ld	l, (ix-2)
	ld	h, (ix-1)
	ld	e, (hl)
;vtl.c:354: *adr = READW(Bnd) + val * 2;
	ld	a, (ix+4)
	ld	(ix-4), a
	ld	a, (ix+5)
	ld	(ix-3), a
;vtl.c:352: if (*c == ':') {
	ld	a, d
	sub	3ah
	jr	NZ, gr105
;vtl.c:353: expr(ptr, &val);
	ld	hl, 0
	add	hl, sp
	ex	de, hl
	ld	l, c


	ld	h, b


	call	_expr
;vtl.c:354: *adr = READW(Bnd) + val * 2;
	ld	bc, (_Lct + 80)
	pop	hl
	push	hl
	add	hl, hl
	add	hl, bc
	ex	de, hl
	pop	bc
	pop	hl
	push	hl
	push	bc
	ld	(hl), e
	inc	hl
	ld	(hl), d
	jr	gr106
gr105:
;vtl.c:356: else if ( *c == 0x7f ) mach_fin();-/* DEL key */
	ld	a, e
	sub	7fh
	jr	NZ, gr102
	call	_mach_fin
	jr	gr106
gr102:
;vtl.c:357: else *adr = ((*c & 0x3f) + 2) * 2;
	ld	d, 0
	ld	a, e
	and	3fh
	ld	h, 0


	ld	l, a


	inc	hl
	inc	hl
	add	hl, hl
	ex	de, hl
	pop	bc
	pop	hl
	push	hl
	push	bc
	ld	(hl), e
	inc	hl
	ld	(hl), d
gr106:
;vtl.c:358: return;
;vtl.c:359: }
	ld	sp, ix
	pop	ix
	pop	hl
	pop	af
	jp	(hl)
;vtl.c:365: static void putl(unsigned short *ptr, unsigned char d) {
;----------------------------------
; Function putl
; ---------------------------------
_putl:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	ex	de, hl
;vtl.c:366: while (READB(*ptr) != d) putchr(READB((*ptr)++));
pl101:
	ld	l, e
	ld	h, d
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	ld	hl, _Lct
	add	hl, bc
	ex	(sp), hl
	pop	hl
	push	hl
	ld	l, (hl)

	inc	bc
	ld	a, (ix+4)
	sub	l
	jr	Z, pl103
	ld	l, e
	ld	h, d
	ld	(hl), c
	inc	hl
	ld	(hl), b
	pop	hl
	push	hl
	ld	c, (hl)
	push	de
	ld	a, c
	call	_putchr
	pop	de
	jr	pl101
pl103:
;vtl.c:367: (*ptr)++;
	ld	a, c
	ld	(de), a
	inc	de
	ld	a, b
	ld	(de), a
;vtl.c:368: return;
;vtl.c:369: }
	ld	sp, ix
	pop	ix
	pop	hl
	inc	sp
	jp	(hl)
;vtl.c:375: static void crlf(void) {
;----------------------------------
; Function crlf
; ---------------------------------
_crlf:
;vtl.c:376: putchr('\r');
	ld	a, 0dh
	call	_putchr
;vtl.c:377: putchr('\n');
	ld	a, 0ah
;vtl.c:378: return;
;vtl.c:379: }
	jp	_putchr
;vtl.c:385: static void putnm(unsigned short x) {
;----------------------------------
; Function putnm
; ---------------------------------
_putnm:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	dec	sp
	ex	de, hl
;vtl.c:389: ptr = Nbf + 5;
	ld	hl, 87h
	ex	(sp), hl
;vtl.c:390: WRITEB(ptr, '\0');
	ld	hl, _Lct + 135
	ld	(hl), 0
;vtl.c:391: do {
	pop	bc
	push	bc
pu101:
;vtl.c:392: y = x % 10;
	ex	de, hl
	push	hl
	push	bc
	ld	de, 0ah
	call	moduint
	pop	bc
	pop	hl
	ld	(ix-1), e
;vtl.c:393: x /= 10;
	push	bc
	ld	de, 0ah
	call	divuint
	pop	bc
;vtl.c:394: WRITEB(--ptr, y + '0');
	dec	bc
	inc	sp
	inc	sp
	push	bc
	ld	hl, _Lct
	add	hl, bc
	ld	a, (ix-1)
	add	a, 30h
	ld	(hl), a
;vtl.c:395: } while (x != 0);
	ld	a, d
	or	e
	jr	NZ, pu101
;vtl.c:396: putl(&ptr, '\0');
	inc	sp
	inc	sp
	push	bc
	xor	a
	push	af
	inc	sp
	ld	hl, 1
	add	hl, sp
	call	_putl
;vtl.c:397: return;
;vtl.c:398: }
	ld	sp, ix
	pop	ix
	ret
;vtl.c:404: static void putstr(char *str) {
;----------------------------------
; Function putstr
; ---------------------------------
_putstr:
;vtl.c:405: while (*str != '\0') putchr(*(str++));
	ld	a, (hl)
	or	a
	jp	Z,_crlf
	inc	hl
	ld	c, a
	push	hl
	ld	a, c
	call	_putchr
	pop	hl
;vtl.c:406: crlf();
;vtl.c:407: return;
;vtl.c:408: }
	jr	_putstr

str_0:	db	"VTL-C Z80 edition.", 0
str_1:	db	0dh, 0ah, "OK", 0


	db	($ & 0FF00H)+100H-$ dup(0FFH)

end_code:
	;;
	;; Work Area
	;;
	if SUPER_MEZ
	org	end_code
	else
	ORG	WORK_B
	endif

SEED:	ds	2
SEEDX:	ds	2
_Lct:		ds	WORK_END+1 - _Lct

	end
	