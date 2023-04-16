#include <stdlib.h>

#include "qsort.h"
#include "linked_list.h"
#include "bubble_sort.h"
#include "bsearch.h"
#include "ranpi.h"

#include "../../../kernel/common.h"

int main(void)
{
    // Brief delay to let putty catch up w/ the program
    timer_sleep(1000);

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