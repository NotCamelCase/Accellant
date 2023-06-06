#include "timer_core.h"

#include "memory_map.h"
#include "common.h"

static volatile uint32_t* const timer_ptr = (volatile uint32_t*)MMIO_TIMER_BASE_ADDRESS;

static __attribute__((constructor)) void timer_init(void)
{
    // Insert a dummy wait on FPGA to give a chance e.g. to connect UART console post-boot
#if ACCELLANT_SILICON
    timer_sleep(100);
#endif
}

uint32_t timer_get_cycle_count()
{
    return timer_ptr[TIMER_REG_CYCLE_CTR];
}

uint32_t timer_get_time_ms()
{
    return timer_get_cycle_count() / (CPU_CLOCK_FREQ_MHZ * 1000);
}

void timer_sleep(uint32_t val)
{
    uint32_t start = timer_get_time_ms();
    uint32_t now = 0;

    do {
        now = timer_get_time_ms();
    } while ((now - start) < val);
}