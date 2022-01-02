00000000 <main>:
	0:		00100513		addi x10 x0 1
	4:		00300593		addi x11 x0 3
	8:		00500613		addi x12 x0 5
	c:		00400693		addi x13 x0 4
	10:		044000ef		jal x1 68 <complexMul>
	14:		00058293		addi x5 x11 0
	18:		00050513		addi x10 x10 0
	1c:		00a00893		addi x17 x0 10
	20:		00000073		ecall
00000024 <myMult>:
	24:		02000293		addi x5 x0 32
	28:		00000e13		addi x28 x0 0
0000002c <start>:
	2c:		00058313		addi x6 x11 0
	30:		00137313		andi x6 x6 1
	34:		00030463		beq x6 x0 8 <shift>
	38:		00ae0e33		add x28 x28 x10
0000003c <shift>:
	3c:		00151513		slli x10 x10 1
	40:		4015d593		srai x11 x11 1
	44:		fff28293		addi x5 x5 -1
	48:		fe0292e3		bne x5 x0 -28 <start>
	4c:		000e0513		addi x10 x28 0
	50:		00008067		jalr x0 x1 0
00000054 <complexMul>:
	54:		fe410113		addi x2 x2 -28
	58:		00012c23		sw x0 24 x2
	5c:		00012a23		sw x0 20 x2
	60:		00112823		sw x1 16 x2
	64:		00a12623		sw x10 12 x2
	68:		00b12423		sw x11 8 x2
	6c:		00c12223		sw x12 4 x2
	70:		00d12023		sw x13 0 x2
	74:		00060593		addi x11 x12 0
	78:		fadff0ef		jal x1 -84 <myMult>
	7c:		00a12a23		sw x10 20 x2
	80:		00812503		lw x10 8 x2
	84:		00012583		lw x11 0 x2
	88:		f9dff0ef		jal x1 -100 <myMult>
	8c:		01412283		lw x5 20 x2
	90:		40a283b3		sub x7 x5 x10
	94:		00712a23		sw x7 20 x2
	98:		00c12503		lw x10 12 x2
	9c:		00012583		lw x11 0 x2
	a0:		f85ff0ef		jal x1 -124 <myMult>
	a4:		00a12c23		sw x10 24 x2
	a8:		00812503		lw x10 8 x2
	ac:		00412583		lw x11 4 x2
	b0:		f75ff0ef		jal x1 -140 <myMult>
	b4:		00050593		addi x11 x10 0
	b8:		01812283		lw x5 24 x2
	bc:		00b285b3		add x11 x5 x11
	c0:		01412503		lw x10 20 x2
	c4:		01012083		lw x1 16 x2
	c8:		01c10113		addi x2 x2 28
	cc:		00008067		jalr x0 x1 0