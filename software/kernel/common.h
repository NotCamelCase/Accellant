#pragma once

#define READ_BIT(x, n) ((x >> n) & 0x1)
#define SET_BIT(x, n) (x |= (1 << n))

#define CPU_CLOCK_FREQ_MHZ  100

#include "timer_core.h"
#include "led_core.h"
#include "printf.h"