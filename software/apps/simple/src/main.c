#include <stdio.h>
#include <stdlib.h>

#include "qsort.h"
#include "linked_list.h"
#include "bubble_sort.h"
#include "bsearch.h"
#include "ranpi.h"

#include "../../../kernel/common.h"

int main(void)
{
#if 1
    // Brief delay to let putty catch up w/ the program on FPGA
    timer_sleep(100);
#endif

    printf("***** QSORT *****\n");
    test_qsort();

    printf("***** LINKED LIST *****\n");
    test_linked_list();

    printf("***** BINARY SEARCH *****\n");
    test_bsearch();

    printf("***** RANPI *****\n");
    test_ranpi();

    printf("***** BUBBLE SORT *****\n");
    test_bubble_sort();

    return 0;
}