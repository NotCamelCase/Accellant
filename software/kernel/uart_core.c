#include "uart_core.h"

#include "memory_map.h"

static volatile uint32_t* const uart_ptr = (volatile uint32_t*)MMIO_UART_BASE_ADDRESS;

static __attribute__((constructor)) void uart_init(void)
{
    uart_set_baud_rate(UART_DEFAULT_BAUD_RATE);
}

void uart_set_baud_rate(uint32_t baudRate)
{
    uint32_t rate = ((CPU_CLOCK_FREQ_MHZ * 1000000) / (16 * baudRate)) - 1;
    uart_ptr[UART_REG_SET_BAUD_RATE] = rate;
}

void uart_write_byte(uint8_t val)
{
    // Wait for space
    while (uart_tx_full()) ;

    uart_ptr[UART_REG_WRITE_DATA] = val;
}

void uart_read_byte(uint8_t* val)
{
    *val = (uint8_t)uart_ptr[UART_REG_GET_DATA];
}

bool uart_rx_empty()
{
    return READ_BIT(uart_ptr[UART_REG_GET_STATUS], UART_BIT_RX_EMPTY);
}

bool uart_rx_full()
{
    return READ_BIT(uart_ptr[UART_REG_GET_STATUS], UART_BIT_RX_FULL);
}

bool uart_tx_empty()
{
    return READ_BIT(uart_ptr[UART_REG_GET_STATUS], UART_BIT_TX_EMPTY);
}

bool uart_tx_full()
{
    return READ_BIT(uart_ptr[UART_REG_GET_STATUS], UART_BIT_TX_FULL);
}