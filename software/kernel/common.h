#pragma once

#define READ_BIT(x, n) ((x >> n) & 0x1)
#define SET_BIT(x, n) (x |= (1 << n))

#define ARRAY_SIZE(x) (sizeof(x) / sizeof(x[0]))

#define CPU_CLOCK_FREQ_MHZ  100