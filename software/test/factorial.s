
00000000 <main>:
    0:        00700513        addi x10 x0 7
    4:        010000ef        jal x1 16 <fact>
    8:        00050593        addi x11 x10 0
    c:        00a00893        addi x17 x0 10
    10:        00000073        ecall

00000014 <fact>:
    14:        ff010113        addi x2 x2 -16
    18:        00112423        sw x1 8 x2
    1c:        00a12023        sw x10 0 x2
    20:        fff50293        addi x5 x10 -1
    24:        0002d863        bge x5 x0 16 <nfact>
    28:        00100513        addi x10 x0 1
    2c:        01010113        addi x2 x2 16
    30:        00008067        jalr x0 x1 0

00000034 <nfact>:
    34:        fff50513        addi x10 x10 -1
    38:        fddff0ef        jal x1 -36 <fact>
    3c:        00050313        addi x6 x10 0
    40:        00012503        lw x10 0 x2
    44:        00812083        lw x1 8 x2
    48:        01010113        addi x2 x2 16
    4c:        02650533        mul x10 x10 x6
    50:        00008067        jalr x0 x1 0
