#include "led_core.h"

#include "memory_map.h"
#include "common.h"

static volatile uint32_t* const led_ptr = (volatile uint32_t*)MMIO_LED_BASE_ADDRESS;

void led_set_value(uint32_t val)
{
    led_ptr[LED_REG_SET_LED] = val;
}