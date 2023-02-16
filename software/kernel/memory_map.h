#pragma once

#define MMIO_BASE_ADDRESS       0xff000000
#define MMIO_LED_BASE_ADDRESS   (MMIO_BASE_ADDRESS + 0x0)   // Slot #0
#define MMIO_TIMER_BASE_ADDRESS (MMIO_BASE_ADDRESS + 0x100) // Slot #1
#define MMIO_UART_BASE_ADDRESS  (MMIO_BASE_ADDRESS + 0x200) // Slot #2