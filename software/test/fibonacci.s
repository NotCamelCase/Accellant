main:                                   # @main
        li      a0, 7
        call    Fib
        ecall
        
Fib:                                # @Fib(int)
        addi    sp, sp, -16
        sw      ra, 12(sp)                      # 4-byte Folded Spill
        sw      s0, 8(sp)                       # 4-byte Folded Spill
        sw      s1, 4(sp)                       # 4-byte Folded Spill
        sw      s2, 0(sp)                       # 4-byte Folded Spill
        li      a2, 2
        li      a1, 1
        blt     a0, a2, LBB0_4
        li      s0, 0
        addi    s1, a0, 2
        li      s2, 3
LBB0_2:                                # =>This Inner Loop Header: Depth=1
        addi    a0, s1, -3
        call    Fib
        addi    s1, s1, -2
        add     s0, a0, s0
        bltu    s2, s1, LBB0_2
        addi    a1, s0, 1
LBB0_4:
        mv      a0, a1
        lw      ra, 12(sp)                      # 4-byte Folded Reload
        lw      s0, 8(sp)                       # 4-byte Folded Reload
        lw      s1, 4(sp)                       # 4-byte Folded Reload
        lw      s2, 0(sp)                       # 4-byte Folded Reload
        addi    sp, sp, 16
        ret