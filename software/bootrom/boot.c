#include <stdint.h>

#define LED_REG     0xff000000
#define TIMER_REG   0xff000100

#define CPU_CLOCK_FREQ_MHZ  100

uint32_t time_ms(void)
{
    volatile uint32_t* pTimerBase = (volatile uint32_t*)TIMER_REG;
    return *pTimerBase / (CPU_CLOCK_FREQ_MHZ * 1000);
}

// Wait idle for 'val ms
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

int main(void)
{
    uint32_t ctr = 0;

    while (1)
    {
        // Turn on all LEDs
        SetLed(ctr++);

        // Sleep for 500 ms
        Sleep(500);

        // Turn off all LEDs
        SetLed(0x0);

        // Sleep for 500 ms
        Sleep(500);
    }
}