#include <stdint.h>

#define LED_REG     0xff000000
#define TIMER_REG   0xff000100
#define UART_REG    0xff000200

#define CPU_CLOCK_FREQ_MHZ  100

#define READ_BIT(x, n) ((x >> n) & 0x1)
#define SET_BIT(x, n) (x |= (1 << n))

extern int* _etext;
extern int* _srodata;
extern int* _erodata;

uint32_t time_ms(void)
{
    volatile uint32_t* pTimerBase = (volatile uint32_t*)TIMER_REG;
    return *pTimerBase / (CPU_CLOCK_FREQ_MHZ * 1000);
}

void Sleep(uint32_t val)
{
    uint32_t start = time_ms();
    uint32_t now = 0;

    do
    {
        now = time_ms();
    } while ((now - start) < val);
}

void SetLed(uint32_t val)
{
    volatile uint32_t* pLedBase = (volatile uint32_t*)LED_REG;
    *pLedBase = val;
}

void write_serial_byte(unsigned char c)
{
    volatile uint32_t* pUART = (volatile uint32_t*)UART_REG;
    while (READ_BIT(pUART[2], 3)) {};
    pUART[3] = c;
}

uint32_t str_len(const char* word)
{
    const char* pStart = word;
    uint32_t i = 0;

    while (*pStart++ != '\0')
    {
        ++i;
    }

    return i;
}

int main(void)
{
    SetLed(0xf);

    int *src = (int*)(&_etext);
    int *dst = (int*)(&_srodata);
    int *end = (int*)(&_erodata);

    // Copy read-only data from ROM to RAM prior to execution
    while (dst < end)
        *dst++ = *src++;

    uint32_t ctr = 0;

    while (1)
    {
        SetLed(0x0);

        Sleep(500);

        const char* helloWorld = "Hello, World!\n";
        const uint32_t length = str_len(helloWorld);

        for (uint32_t i = 0; i < length; i++)
        {
            char nextChar = helloWorld[i];
            write_serial_byte(nextChar);
        }

        SetLed(ctr++);

        // Sleep for 500 ms
        Sleep(500);
    }
}