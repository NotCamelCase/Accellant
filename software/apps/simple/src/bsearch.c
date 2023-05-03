#include "bsearch.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

static int compare(const void* a, const void* b)
{
    return *(int*)a - *(int*)b;
}

static bool verify(int* numbers, int N, int k)
{
    for (int i = 0; i < N; i++)
    {
        if (numbers[i] == k)
            return true;
    }

    return false;
}

void test_bsearch(void)
{
    const int N = 100;
    int* numbers = (int*)malloc(N * sizeof(int));

    for (int i = 0; i < N; i++)
    {
        numbers[i] = rand() % N;
    }

    qsort(numbers, N, sizeof(int), compare);

    int find = rand() % N;
    int* result = (int*)bsearch(&find, numbers, N, sizeof(int), compare);
    bool found = verify(numbers, N, find);

    if (found)
    {
        if ((result != NULL) && (find == *result))
            printf("PASS: Found %d\n", find);
        else
            printf("FAIL: Mismatch\n");
    }
    else
    {
        if (result == NULL)
            printf("PASS: Not found %d\n", find);
        else
            printf("FAIL: Mismatch\n");
    }

    free(numbers);
}
