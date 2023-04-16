#pragma once

#include <stdbool.h>

int bsearch_compare(const void* a, const void* b);
bool bsearch_verify(int* numbers, int N, int k);
void test_bsearch(void);
