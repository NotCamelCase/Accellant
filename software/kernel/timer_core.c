#include "timer_core.h"

#include "memory_map.h"
#include "common.h"

static volatile uint32_t* timer_ptr = (volatile uint32_t*)MMIO_TIMER_BASE_ADDRESS;

uint32_t timer_get_cycle_count()
{
    return timer_ptr[TIMER_REG_CYCLE_CTR];
}

uint32_t timer_get_time_ms()
{
    return timer_get_cycle_count() / (CPU_CLOCK_FREQ_MHZ * 1000);
}