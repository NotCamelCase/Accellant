#pragma once

#include <stdint.h>
#include <stdbool.h>

#include "common.h"

#define UART_DEFAULT_BAUD_RATE  460800

#ifdef __cplusplus
extern "C" {
#endif
typedef enum {
    UART_REG_GET_DATA       = 0,
    UART_REG_SET_BAUD_RATE  = 1,
    UART_REG_GET_STATUS     = 2,
    UART_REG_WRITE_DATA     = 3
} UART_REG;

typedef enum {
    UART_BIT_RX_EMPTY  = 0,
    UART_BIT_RX_FULL   = 1,
    UART_BIT_TX_EMPTY  = 2,
    UART_BIT_TX_FULL   = 3
} UART_BITFIELD;

void uart_set_baud_rate(uint32_t baudRate);
void uart_write_byte(uint8_t val);

// Caller should probe for data availability
void uart_read_byte(uint8_t* val);

bool uart_rx_empty(void);
bool uart_rx_full(void);
bool uart_tx_empty(void);
bool uart_tx_full(void);
#if __cplusplus
}
#endif