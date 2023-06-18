li x1 8
li x2 4
li x3 0xdeadbeef
mul x4 x1 x2
sw x5 0(x4)
lw x6 0(x4)

// Results:
// x0:  0
// x1:  0x8
// x2:  0x4
// x3:  0xdeadbeef
// x4:  0x20
// x5:  0xdeadbeef