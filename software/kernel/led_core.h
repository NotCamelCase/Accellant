#pragma once

#include <stdint.h>

typedef enum
{
    LED_REG_SET_LED = 0
} LED_REG;

void led_set_value(uint32_t val);