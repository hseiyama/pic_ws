	CPU	68000
	SUPMODE	ON

ENTRY	EQU	$00008000	; Entry address

	ORG	ENTRY

TEST1:
	;; ABCD
	ABCD.B	D0,D1
	ABCD.B	-(A1),-(A0)
	;; ADD
	ADD.B	3(A0),D0
	ADD.W	D0,3(A0)
	ADD.L	#$8000,D0
	;; ADDA
	ADDA.W	3(A0),A0
	ADDA.L	$8002,A0
	;; ADDI
	ADDI.B	#$33,D0
	ADDI.W	#$4444,3(A0)
	ADDI.L	#$55555555,$00008100
	;; ADDQ
	ADDQ.B	#1,D0
	ADDQ.W	#7,3(A0)
	ADDQ.L	#8,$00008100
	;; ADDX
	ADDX.B	D0,D1
	ADDX.W	-(A0),-(A1)
	ADDX.L	D0,D1
	;; AND
	AND.B	3(A0,D1.W),D0
	AND.W	D0,3(A0,D1.W)
	AND.L	#$8000,D0
	;; ANDI
	ANDI.B	#$33,D0
	ANDI.W	#$4444,3(A0,D1.W)
	ANDI.L	#$55555555,$00008100
	;; ANDI to CCR
	ANDI.B	#$88,CCR
	;; ANDI to SR
	ANDI.W	#$88,SR
	;; ASL
	ASL.B	D1,D0
	ASL.B	#7,D0
;	ASL.B	3(A0,D1.W)	; NG(Destination==Memory)
	ASL.W	D1,D0
	ASL.W	#7,D0
	ASL.W	3(A0,D1.W)
	ASL.L	D1,D0
	ASL.L	#7,D0
;	ASL.L	3(A0,D1.W)	; NG(Destination==Memory)
	;; ASR
	ASR.B	D1,D0
	ASR.W	3(A0,D1.W)
	ASR.L	#7,D0
	;; Bcc
BCC0:	BCC.B	BCC0
	BCS.B	BCC0
	BEQ.B	BCC0
	BGE.B	BCC0
	BGT.B	BCC0
	BHI.B	BCC0
	BLE.B	BCC0
	BLS.B	BCC0
	BLT.B	BCC0
	BMI.B	BCC0
	BNE.B	BCC0
	BPL.B	BCC0
	BVC.B	BCC0
	BVS.B	BCC0
	BCC.W	TEST1
	BCS.W	TEST1
	BEQ.W	TEST1
	BGE.W	TEST1
	BGT.W	TEST1
	BHI.W	TEST1
	BLE.W	TEST1
	BLS.W	TEST1
	BLT.W	TEST1
	BMI.W	TEST1
	BNE.W	TEST1
	BPL.W	TEST1
	BVC.W	TEST1
	BVS.W	TEST1
	SAVE			; Start(For MC68030)
	CPU	68030
;	BCC.L	LONG0		; Assemble error
;	BCS.L	LONG0		; Assemble error
;	BEQ.L	LONG0		; Assemble error
;	BGE.L	LONG0		; Assemble error
;	BGT.L	LONG0		; Assemble error
;	BHI.L	LONG0		; Assemble error
;	BLE.L	LONG0		; Assemble error
;	BLS.L	LONG0		; Assemble error
;	BLT.L	LONG0		; Assemble error
;	BMI.L	LONG0		; Assemble error
;	BNE.L	LONG0		; Assemble error
;	BPL.L	LONG0		; Assemble error
;	BVC.L	LONG0		; Assemble error
;	BVS.L	LONG0		; Assemble error
	DC.W	$64FF,$0001,$FF5E	; BCC.L
	DC.W	$65FF,$0001,$FF5A	; BCS.L
	DC.W	$67FF,$0001,$FF56	; BEQ.L
	DC.W	$6CFF,$0001,$FF52	; BGE.L
	DC.W	$6EFF,$0001,$FF4E	; BGT.L
	DC.W	$62FF,$0001,$FF4A	; BHI.L
	DC.W	$6FFF,$0001,$FF46	; BLE.L
	DC.W	$63FF,$0001,$FF42	; BLS.L
	DC.W	$6DFF,$0001,$FF3E	; BLT.L
	DC.W	$6BFF,$0001,$FF3A	; BMI.L
	DC.W	$66FF,$0001,$FF36	; BNE.L
	DC.W	$6AFF,$0001,$FF32	; BPL.L
	DC.W	$68FF,$0001,$FF2E	; BVC.L
	DC.W	$69FF,$0001,$FF2A	; BVS.L
	RESTORE			; End(For MC68030)
	;; BCHG
;	BCHG.B	D1,D0		; NG(Destination==Dn)
	BCHG.B	#7,3(A0,D1.W)
	BCHG.L	D1,D0
	BCHG.L	#31,D0
;	BCHG.L	#31,3(A0,D1.W)	; NG(Destination<>Dn)
	;; BCLR
	BCLR.B	#7,3(A0,D1.W)
	BCLR.L	D1,D0
	BCLR.L	#31,D0
	;; BRA
BRA0:	BRA.B	BRA0
	BRA.W	TEST1
	SAVE			; Start(For MC68030)
	CPU	68030
;	BRA.L	LONG0		; Assemble error
	DC.W	$60FF,$0001,$FEB4	; BRA.L
	RESTORE			; End(For MC68030)
	;; BSET
	BSET.B	#7,3(A0,D1.W)
	BSET.L	D1,D0
	BSET.L	#31,D0
	;; BSR
BSR0:	BSR.B	BSR0
	BSR.W	TEST1
	SAVE			; Start(For MC68030)
	CPU	68030
;	BSR.L	LONG0		; Assemble error
	DC.W	$61FF,$0001,$FEB4	; BRA.L
	RESTORE			; End(For MC68030)
	;; BTST
	BTST.B	#7,3(A0,D1.W)
	BTST.L	D1,D0
	BTST.L	#31,D0
	;; CHK
	CHK.W	3(A0,D1.W),D0
	CHK.L	#$10008000,D0
	;; CLR
	CLR.B	D0
	CLR.W	3(A0,D1.W)
	CLR.L	$00018000
	;; CMP
	;; CMPA
	;; CMPI
	;; CMPM.B (An)+,(An)+
	;; CMPM.W (An)+,(An)+
	;; CMPM.L (An)+,(An)+
	;; DBCC
	;; DBCS
	;; DBEQ
	;; DBF
	DBF.W D0,TEST1
	;; DBGE
	;; DBGT
	;; DBHI
	;; DBLE
	;; DBLS
	;; DBLT
	;; DBMI
	;; DBNE
	;; DBPL
	;; DBT
	;; DBVC
	;; DBVS
	;; DIVS
	;; DIVU
	;; EOR
	;; EORI
	;; EORI.B #<data>,CCR
	;; EORI.W #<data>,SR
	;; EXG.L Dn,Dn
	;; EXG.L An,An
	;; EXG.L Dn,An
	;; EXT.W Dn
	;; EXT.L Dn
	;; ILLEGAL
	ILLEGAL
	;; JMP
	;; JSR
	;; LEA
	;; LINK.W An,#<dsiplacement>
	;; LSL
	;; LSR
	;; MOVE
	;; MOVE.L USP,An
	;; MOVE.L An,USP
	;; MOVEA
	;; MOVEC
	SAVE
	CPU	68030
	MOVEC.L	SFC,D0
	MOVEC.L	D0,SFC
	MOVEC.L	DFC,D0
	MOVEC.L	D0,DFC
	MOVEC.L	CACR,D0
	MOVEC.L	D0,CACR
	MOVEC.L	USP,D0
	MOVEC.L	D0,USP
	MOVEC.L	VBR,D0
	MOVEC.L	D0,VBR
	MOVEC.L	CAAR,D0
	MOVEC.L	D0,CAAR
	MOVEC.L	MSP,D0
	MOVEC.L	D0,MSP
	MOVEC.L	ISP,D0
	MOVEC.L	D0,ISP
	RESTORE
	;; MOVEM
	;; MOVEP.W Dn,d(An)
	;; MOVEP.W d(An),Dn
	;; MOVEP.L Dn,d(An)
	;; MOVEP.L d(An),Dn
	;; MOVEQ.L #<data>,Dn
	;; MULS
	;; MULU
	;; NBCD
	;; NEG
	;; NEGX
	;; NOP
	;; NOT
	;; OR
	;; ORI
	;; ORI.B #<data>,CCR
	;; ORI.W #<data>,SR
	;; PEA
	;; RESET
	;; ROL
	;; ROR
	;; ROXL
	;; ROXR
	;; RTE
	;; RTR
	;; RTS
	;; SBCD
	;; SCC
	;; SCS
	;; SEQ
	;; SF
	;; SGE
	;; SGT
	;; SHI
	;; SLE
	;; SLS
	;; SLT
	;; SMI
	;; SNE
	;; SPL
	;; ST
	;; SVC
	;; SVS
	;; SUB
	;; SUBA
	;; SUBI
	;; SUBQ
	;; SUBX
	;; SWAP.W Dn
	;; TAS
	;; TRAP #<vector>
	;; TRAPV
	;; TST
	;; ULINK An

	ORG	$10008000

LONG0:	DS.L	1

	END
