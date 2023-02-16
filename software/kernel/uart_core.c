#include "uart_core.h"

#include "memory_map.h"
#include "common.h"

static volatile uint32_t* uart_ptr = (volatile uint32_t*)MMIO_UART_BASE_ADDRESS;

void uart_init(uint32_t baudRate)
{
    uart_set_baud_rate(baudRate);
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

bool uart_read_byte(uint8_t* val)
{
    if (uart_rx_empty())
    {
        return false;
    }
    else
    {
        *val = (uint8_t)uart_ptr[UART_REG_GET_DATA];
        return true;
    }
}

bool uart_rx_empty()
{
    return READ_BIT(uart_ptr[UART_REG_GET_STATUS], UART_BITFIELD_RX_EMPTY);
}

bool uart_rx_full()
{
    return READ_BIT(uart_ptr[UART_REG_GET_STATUS], UART_BITFIELD_RX_FULL);
}

bool uart_tx_empty()
{
    return READ_BIT(uart_ptr[UART_REG_GET_STATUS], UART_BITFIELD_TX_EMPTY);
}

bool uart_tx_full()
{
    return READ_BIT(uart_ptr[UART_REG_GET_STATUS], UART_BITFIELD_TX_FULL);
}