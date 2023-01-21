li x1 8
li x2 4
li x3 0xdeadbeef
mul x4 x1 x2
sw x3 0(x4)
lw x5 0(x4)

add x3 x1 x2
sw x3 0(x0)
lw x4 0(x0)

// Results:
// x0:  0
// x1:  0x8
// x2:  0x4
// x3:  0xc
// x4:  0xc
// x5:  0xdeadbeef