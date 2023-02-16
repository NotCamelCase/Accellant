#include <stdint.h>
#include <stdbool.h>

#define LED_REG     0xff000000
#define TIMER_REG   0xff000100
#define UART_REG    0xff000200

#define CPU_CLOCK_FREQ_MHZ  100
#define LOADER_BAUD_RATE    460800

#define READ_BIT(x, n) ((x >> n) & 0x1)
#define SET_BIT(x, n) (x |= (1 << n))

#define SDRAM_BASE_ADDRESS  0x0

#define CMD_PING    0x11
#define CMD_ACK     0x22

void set_baud_rate(int rate)
{
    volatile uint32_t* pUART = (volatile uint32_t*)UART_REG;

    int crate = ((CPU_CLOCK_FREQ_MHZ * 1000000) / (16 * rate)) - 1;
    pUART[1] = crate;
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

void write_serial_integer(uint32_t val)
{
    for (int i = 0; i < 4; i++)
    {
        unsigned char t = val & 0xff;
        val >>= 8;

        write_serial_byte(t);
    }
}

unsigned char read_serial_byte(void)
{
    while (rx_empty()) ; // Wait idle for data
    volatile uint32_t* pUART = (volatile uint32_t*)UART_REG;
    return (unsigned char)pUART[0];
}

uint32_t read_serial_int(void)
{
    uint32_t b0 = read_serial_byte();
    uint32_t b1 = read_serial_byte();
    uint32_t b2 = read_serial_byte();
    uint32_t b3 = read_serial_byte();

    return (b3 << 24) | (b2 << 16) | (b1 << 8) | b0;
}

void set_led(uint32_t val)
{
    volatile uint32_t* pLedBase = (volatile uint32_t*)LED_REG;
    *pLedBase = val;
}

void transfer_data()
{
    uint8_t* pDataPtr = (uint8_t*)SDRAM_BASE_ADDRESS;
    uint32_t programSize = read_serial_int();

    for (uint32_t i = 0; i < programSize; i++)
    {
        *pDataPtr++ = read_serial_byte();
    }
}

void execute_app(uint32_t baseAddress)
{
    asm volatile ("jalr %0" : : "r" (baseAddress));
}

int main(void)
{
    set_led(0b0);

    set_baud_rate(LOADER_BAUD_RATE);

    set_led(0b1111);

    while (read_serial_byte() != CMD_PING)
    {
        // Wait for a ping from the loader
    }

    set_led(0b1100);

    // Send ACK to accept incoming data
    write_serial_byte(CMD_ACK);
    set_led(0b0011);

    // Read program data into RAM
    transfer_data();
    set_led(0b1010);

    // Commit entire D$ to main memory so that the newly copied program data (instructions & data) are made visible to I$
    asm volatile ("csrw pmpcfg1, x0");

    // Jump to the beginning of SDRAM where app instructions & data have just been copied to
    execute_app(SDRAM_BASE_ADDRESS);

    return 0;
}