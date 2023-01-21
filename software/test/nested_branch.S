addi x1 x0 8
addi x2 x0 4
add x3 x1 x2
sub x4 x1 x2
j taken
mul x3 x1 x2
j not_taken
div x4 x1 x2
not_taken:
div x1 x1 x1
mul x2 x2 x2
taken:
add x5 x3 x4
sub x6 x3 x4

// Results:
// x0:  0
// x1:  0x8
// x2:  0x4
// x3:  0xc
// x4:  0x4
// x5:  0x10
// x6:  0x8