#include "sys_calls.h"

#include <ctype.h>
#include <unistd.h>
#include <errno.h>
#undef errno
extern int errno;

#include "uart_core.h"

extern char __heap_start[];
extern char __heap_end[];
static char *__heap = __heap_start;

void *__dso_handle;

char *__env[1] = {0};
char **environ = __env;

int wait(int *status)
{
    errno = ECHILD;
    return -1;
}

int unlink(const char *__path)
{
    errno = ENOENT;
    return -1;
}

int times(struct tms *buf)
{
    return -1;
}

int open(const char *name, int flags, int mode)
{
    return -1;
}

int link(const char *__path1, const char *__path2)
{
    errno = EMLINK;
    return -1;
}

int fork(void)
{
    errno = EAGAIN;
    return -1;
}

int execve(const char *, char *const *, char *const *)
{
    errno = ENOMEM;
    return -1;
}

int _fstat(int /*fd*/, struct stat *st)
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
    while (true)
        ;
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

int _write(int /*fd*/, char *buf, int count)
{
    int written = 0;

    for (int i = 0; i < count; i++)
    {
        uart_write_byte((uint8_t)(*buf++));
        ++written;
    }

    return written;
}

int _read(int /*fd*/, char *buf, int count)
{
    int read = 0;

    bool abort = false;
    while ((read < count) && (!abort))
    {
        uint8_t nc;
        uart_read_byte(&nc);

        *buf++ = nc;
        read++;

        abort = isspace(nc);
    }

    return read;
}

int _brk(void *addr)
{
    __heap = (char *)addr;
    return 0;
}

void *_sbrk(int incr)
{
    char *prevHeap = __heap;
    // Heap-allocated memory increased
    __heap += incr;

    return (void *)prevHeap;
}

int __cxa_atexit(void (*destructor)(void *), void *arg, void *dso)
{
    return -1;
}