#pragma once

#include <sys/stat.h>

#ifdef __cplusplus
extern "C" {
#endif
int wait(int *status);
int unlink(const char *__path);
int times(struct tms *buf);
int open(const char *name, int flags, int mode);
int link (const char *__path1, const char *__path2);
int fork(void);
int execve(const char*, char* const*, char* const*);
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
int __cxa_atexit(void (*destructor) (void *), void *arg, void *dso);
#if __cplusplus
}
#endif