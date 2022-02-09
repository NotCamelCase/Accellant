
00000000 <main>:
    0:        00700513        addi x10 x0 7
    4:        00c000ef        jal x1 12 <fact>
    8:        00a00893        addi x17 x0 10
    c:        00000073        ecall

00000010 <fact>:
    10:        ff010113        addi x2 x2 -16
    14:        00112423        sw x1 8 x2
    18:        00a12023        sw x10 0 x2
    1c:        fff50293        addi x5 x10 -1
    20:        0002d863        bge x5 x0 16 <nfact>
    24:        00100513        addi x10 x0 1
    28:        01010113        addi x2 x2 16
    2c:        00008067        jalr x0 x1 0

00000030 <nfact>:
    30:        fff50513        addi x10 x10 -1
    34:        fddff0ef        jal x1 -36 <fact>
    38:        00050313        addi x6 x10 0
    3c:        00012503        lw x10 0 x2
    40:        00812083        lw x1 8 x2
    44:        01010113        addi x2 x2 16
    48:        02650533        mul x10 x10 x6
    4c:        00008067        jalr x0 x1 0