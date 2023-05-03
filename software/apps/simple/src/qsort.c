#include "qsort.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

static int compare(const void* a, const void* b)
{
    return *(int*)a - *(int*)b;
}

static bool verify(int* numbers, int N)
{
    for (int i = 0; i < N-1; i++)
    {
        if (numbers[i] > numbers[i + 1])
            return false;
    }

    return true;
}

void test_qsort(void)
{
    const int N = 100;
    int* numbers = (int*)malloc(N * sizeof(int));

    for (int i = 0; i < N; i++)
    {
        numbers[i] = rand() % N;
    }

    qsort(numbers, N, sizeof(int), compare);

    if (verify(numbers, N))
        printf("PASS\n");
    else
        printf("FAIL\n");

    free(numbers);
}