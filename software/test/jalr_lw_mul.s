li x1 5
li x2 -4
mul x3 x1 x2
jalr x20 x0 taken

taken:
    sw x3 32(x0)
    lw x4 32(x0)
    
    mul x5 x3 x4
    mul x6 x3 x4
    sub x7 x5 x6
    sw x7 96(x0)
    mul x1 x7 x7
    lw x8 96(x0)
