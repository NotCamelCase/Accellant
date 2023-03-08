#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <unistd.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <termios.h>

#define LOADER_BAUD_RATE    460800

#define CMD_PING    0x11
#define CMD_ACK     0x22

int uart_init(const char* path)
{
    int fd = -1;

    if (path == NULL)
    {
        printf("ERROR: Missing device path!\n");
        return -1;
    }

    fd = open(path, O_RDWR | O_NOCTTY);
    printf("Opened device: %s\n", path);

    struct termios uartPort;
    memset(&uartPort, 0x0, sizeof(uartPort));

    // UART baud rate
    cfsetspeed(&uartPort, LOADER_BAUD_RATE);

    uartPort.c_cflag |= (CS8 | CLOCAL | CREAD);
    uartPort.c_cflag &= ~(PARENB | CSTOPB | CSIZE | CRTSCTS);

    uartPort.c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL | IXON);
    uartPort.c_oflag &= ~OPOST;
    uartPort.c_lflag &= ~(ECHO | ECHONL | ICANON | ISIG | IEXTEN);
    uartPort.c_cc[VMIN] = 1;
    uartPort.c_cc[VTIME] = 0;

    if (tcsetattr(fd, TCSANOW, &uartPort) != 0)
    {
        printf("ERROR: Setting uart port settings\n");
        return -1;
    }

    // Flush any existing content
    tcflush(fd, TCIOFLUSH);

    return fd;
}

void uart_shutdown(int fd)
{
    close(fd);
}

bool read_byte(int fd, unsigned char* val)
{
    if (read(fd, val, 1) == -1)
    {
        printf("ERROR: Receiving byte from UART\n");
        return false;
    }

    return true;
}

bool read_integer(int fd, uint32_t* val)
{
    *val = 0;

    for (int i = 0; i < 4; i++)
    {
        unsigned char temp;
        if (read_byte(fd, &temp) == false)
        {
            return false;
        }

        *val = *val | ((uint32_t)temp << 24);
    }

    return true;
}

bool write_byte(int fd, unsigned char val)
{
    if (write(fd, &val, 1) == -1)
    {
        printf("ERROR: Transmitting byte to UART\n");
        return false;
    }

    return true;
}

bool write_integer(int fd, uint32_t val)
{
    for (int i = 0; i < 4; i++)
    {
        unsigned char t = val & 0xff;
        val >>= 8;

        if (!write_byte(fd, t))
        {
            printf("ERROR: Writing integer %d\n", val);
            return false;
        }
    }

    return true;
}

bool read_binary_file(const char* path, unsigned char** buffer, uint32_t* length)
{
    FILE* programFile = fopen(path, "r");
    if (!programFile)
    {
        printf("ERROR: Opening %s.hex file\n", path);
        return false;
    }

    // Get the file size in bytes
    long fileLength = 0;
    fseek(programFile, 0, SEEK_END);
    fileLength = ftell(programFile);
    fseek(programFile, 0, SEEK_SET);

    printf("Program binary size: %ld bytes\n", fileLength);

    // Read entire file into a buffer
    unsigned char* pBuffer = malloc(fileLength);
    if (fread(pBuffer, fileLength, 1, programFile) == 0)
    {
        printf("ERROR: Reading file\n");
        return false;
    }

    fclose(programFile);

    *buffer = pBuffer;
    *length = fileLength;

    return true;
}

void wait_for_ack(int fd, uint32_t ack)
{
    while (true)
    {
        unsigned char val = 0;
        if (!read_byte(fd, &val))
        {
            printf("ERROR: Failed to receive ACK\n");
            return;
        }
        else if (val == ack)
        {
            printf("ACK received\n");
            break;
        }
    }
}

int main(int argc, char** argv)
{
    unsigned char* buffer;  // Program data
    uint32_t programSize;   // Data size in bytes

    if (!read_binary_file(argv[1], &buffer, &programSize))
    {
        return 0;
    }

    printf("Device path: %s\n", argv[2]);

    int fd = uart_init(argv[2]);
    if (fd == -1)
    {
        printf("ERROR: uart_init()\n");
        return 0;
    }

    printf("UART serial port initialized\n");

    // Ping the target before transmitting .hex data
    printf("Pinging...\n");
    write_byte(fd, CMD_PING);

    // Handshake before proceeding w/ data transfer
    wait_for_ack(fd, CMD_ACK);

    // Transfer program size and data
    write_integer(fd, programSize);

    if (!write(fd, buffer, programSize))
    {
        printf("ERROR: Failed to transfer program data\n");
        free(buffer);

        return 0;
    }

    printf("Data transfer complete\n");

    uart_shutdown(fd);
    free(buffer);

    return 0;
}