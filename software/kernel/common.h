#pragma once

#define READ_BIT(x, n) ((x >> n) & 0x1)
#define SET_BIT(x, n) (x |= (1 << n))

#define CPU_CLOCK_FREQ_MHZ  100