#include "sys_calls.h"

#include "uart_core.h"
#include "printf.h"

extern char     __heap_start[];
extern char     __heap_end[];
static char*    __heap = __heap_start;

int _fstat(int /*fd*/, struct stat* st)
{
    st->st_mode = S_IFCHR;

    return 0;
}

int _isatty(int /*fd*/)
{
    return 1;
}

int _lseek(int /*fd*/, int /*offset*/, int /*whence*/)
{
    return 0;
}

void _exit(int /*status*/)
{
    while (true) ;
}

int _close(int /*fd*/)
{
    return -1;
}

void _kill(int /*pid*/, int /*sig*/)
{
    return;
}

int _getpid(void)
{
    return -1;
}

int _write(int /*fd*/, char* buf, int count)
{
    int written = 0;

    for (int i = 0; i < count; i++)
    {
        uart_write_byte((uint8_t)(*buf++));
        ++written;
    }

    return written;
}

int _read(int /*fd*/, char* buf, int count)
{
    int read = 0;

    for (int i = 0; i < count; i++)
    {
        while (uart_rx_empty()) ;

        uart_read_byte((uint8_t*)buf++);
        read++;
    }

    return read;
}

void* _sbrk(int incr)
{
    char* prevHeap = __heap;
    // Heap-allocated memory increased
    __heap += incr;

    return (void*)prevHeap;
}

// _putchar for tiny printf
void _putchar(char c)
{
    uart_write_byte(c);
}