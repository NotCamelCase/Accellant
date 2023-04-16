#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>

#include "bubble_sort.h"

static void swap(int* a, int* b)
{
    int t = *b;
    *b = *a;
    *a = t;
}

static void sort_numbers(int* numbers, const int N)
{
    for (int i = 0; i < N; i++)
    {
        for (int j = i+1; j < N; j++)
        {
            if (numbers[i] > numbers[j])
            {
                swap(&numbers[j], &numbers[i]);
            }
        }
    }
}

void test_bubble_sort(void)
{
    const int N = 10;
    int* numbers = (int*)malloc(N * sizeof(int));

    // Wait for user to input N numbers
    for (int n = 0; n < N; n++)
    {
        printf("Enter a new number: ");
        scanf("%d", &numbers[n]);
    }

    // Sort the inputs
    sort_numbers(&numbers[0], N);

    printf("Inputs sorted: {");
    for (int n = 0; n < N-1; n++)
    {
        printf("%d, ", numbers[n]);
    }

    printf("%d}\n", numbers[N-1]);

    free(numbers);
}