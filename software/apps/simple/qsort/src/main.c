#include <stdlib.h>

#include "../../../../kernel/common.h"

int compare(const void* a, const void* b)
{
    return *(int*)a - *(int*)b;
}

bool verify(int* numbers, int N)
{
    for (int i = 0; i < N-1; i++)
    {
        if (numbers[i] > numbers[i + 1])
            return false;
    }

    return true;
}

int main(void)
{
    // Brief delay to let putty catch up w/ the program
    timer_sleep(1000);

    const int N = 100;
    int* numbers = (int*)malloc(N * sizeof(int));

    for (int i = 0; i < N; i++)
    {
        numbers[i] = rand() % N;
    }

    qsort(numbers, N, sizeof(int), compare);

    if (verify(numbers, N))
    {
        printf("PASS\n");
        for (int i = 0; i < N; i++)
        {
            printf("%d\n", numbers[i]);
        }
    }
    else
    {
        printf("FAIL\n");
    }

    return 0;
}