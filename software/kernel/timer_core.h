#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif
typedef enum {
    TIMER_REG_CYCLE_CTR = 0
} TIMER_REG;

uint32_t timer_get_cycle_count(void);
uint32_t timer_get_time_ms(void);
#if __cplusplus
}
#endif