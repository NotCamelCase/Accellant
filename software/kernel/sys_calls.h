#pragma once

#include <sys/stat.h>

#ifdef __cplusplus
extern "C" {
#endif
int _fstat(int /*fd*/, struct stat* st);
int _isatty(int /*fd*/);
int _lseek(int /*fd*/, int /*offset*/, int /*whence*/);
void _exit(int /*status*/);
int _close(int /*fd*/);
void _kill(int /*pid*/, int /*sig*/);
int _getpid(void);
int _write(int /*fd*/, char* buf, int count);
int _read(int /*fd*/, char* buf, int count);
int _brk(void* addr);
void* _sbrk(int incr);
#if __cplusplus
}
#endif
