#include <stdint.h>
#include <stdbool.h>
#include <string.h>

#define LED_REG     0xff000000
#define TIMER_REG   0xff000100
#define UART_REG    0xff000200

#define CPU_CLOCK_FREQ_MHZ  100
#define BAUD_RATE           9600

#define READ_BIT(x, n) ((x >> n) & 0x1)
#define SET_BIT(x, n) (x |= (1 << n))

void set_baud_rate(int rate)
{
    volatile uint32_t* pUART = (volatile uint32_t*)UART_REG;

    int crate = ((CPU_CLOCK_FREQ_MHZ * 1000000) / (16 * rate)) - 1;
    pUART[1] = crate;
}

void set_led(uint32_t val)
{
    volatile uint32_t* pLedBase = (volatile uint32_t*)LED_REG;
    *pLedBase = val;
}

bool rx_empty(void)
{
    volatile uint32_t* pUART = (volatile uint32_t*)UART_REG;
    return READ_BIT(pUART[2], 0);
}

bool rx_full(void)
{
    volatile uint32_t* pUART = (volatile uint32_t*)UART_REG;
    return READ_BIT(pUART[2], 1);
}

bool tx_empty(void)
{
    volatile uint32_t* pUART = (volatile uint32_t*)UART_REG;
    return READ_BIT(pUART[2], 2);
}

bool tx_full(void)
{
    volatile uint32_t* pUART = (volatile uint32_t*)UART_REG;
    return READ_BIT(pUART[2], 3);
}

void write_serial_byte(unsigned char c)
{
    volatile uint32_t* pUART = (volatile uint32_t*)UART_REG;
    while (tx_full()) {} // Wait idle for space
    pUART[3] = c;
}

int main(void)
{
    set_led(0b0);

    // Init UART
    set_baud_rate(BAUD_RATE);

    const char* helloWorld = "Hello, World!\n";
    const int len = strlen(helloWorld) + 1; // Include \0

    set_led(0b0101);

    // Print out Hello, World! in a loop
    while (true)
    {
        for (int i = 0; i < len; i++)
        {
            write_serial_byte(helloWorld[i]);
        }
    }

    return 0;
}