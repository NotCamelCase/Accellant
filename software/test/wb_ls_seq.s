li x1 5
li x2 4
li x3 17
li x4 0x1234

# Fill Set 0 Way 0
sw x1 0(x0)
sw x2 4(x0)
sw x3 8(x0)
sw x4 12(x0)

# Fill Set 1 Way 0
sw x1 16(x0)
sw x2 20(x0)
sw x3 24(x0)
sw x4 28(x0)

# Fill Set 0 Way 1
sw x1 32(x0)
sw x2 36(x0)
sw x3 40(x0)
sw x4 44(x0)

# Fill Set 1 Way 1
sw x1 48(x0)
sw x2 52(x0)
sw x3 56(x0)
sw x4 60(x0)

# Readback
lw x1 0(x0)
lw x2 4(x0)
lw x3 8(x0)
lw x4 12(x0)

lw x5 16(x0)
lw x6 20(x0)
lw x7 24(x0)
lw x8 28(x0)

lw x1 32(x0)
lw x2 36(x0)
lw x3 40(x0)
lw x4 44(x0)

lw x5 48(x0)
lw x6 52(x0)
lw x7 56(x0)
lw x8 60(x0)

# Writeback

# Fill Set 0 Way 0
sw x4 64(x0)
sw x3 68(x0)
sw x2 72(x0)
sw x1 76(x0)

# Fill Set 1 Way 0
sw x5 80(x0)
sw x6 84(x0)
sw x7 88(x0)
sw x8 92(x0)

# Fill Set 0 Way 1
sw x1 96(x0)
sw x2 100(x0)
sw x3 104(x0)
sw x4 108(x0)

# Fill Set 1 Way 1
sw x8 112(x0)
sw x7 116(x0)
sw x6 120(x0)
sw x5 124(x0)

# Readback
lw x1 64(x0)
lw x2 68(x0)
lw x3 72(x0)
lw x4 76(x0)

lw x5 80(x0)
lw x6 84(x0)
lw x7 88(x0)
lw x8 92(x0)

lw x1 96(x0)
lw x2 100(x0)
lw x3 104(x0)
lw x4 108(x0)

lw x5 112(x0)
lw x6 116(x0)
lw x7 120(x0)
lw x8 124(x0)