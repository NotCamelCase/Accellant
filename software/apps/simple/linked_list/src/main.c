#include <stdlib.h>

#include "../../../../kernel/common.h"

typedef struct LinkedList {
    int                 item;
    struct LinkedList*  next;
} LinkedList;

void insert_item(LinkedList** tail, int i)
{
    LinkedList* newElem = (LinkedList*)malloc(sizeof(LinkedList));
    newElem->item = i;
    newElem->next = NULL;

    (*tail)->next = newElem;
    *tail = newElem;
}

bool find_item(LinkedList* head, int i)
{
    LinkedList* current = head;

    while (current != NULL)
    {
        if (current->item == i)
            return true;

        current = current->next;
    }

    return false;
}

int main(void)
{
    // Brief delay to let putty catch up w/ the program
    timer_sleep(1000);

    // Create a linked-list of numbers 0 -> N and see if we can successfully traverse it
    LinkedList* head = (LinkedList*)malloc(sizeof(LinkedList));
    head->next = NULL;
    head->item = 0;

    const int N = 1234;

    LinkedList* tail = head;

    for (int i = 1; i < N; i++)
    {
        insert_item(&tail, i);
    }

    int find = rand() % N;

    if (find_item(head, find))
        printf("PASS: Found %d\n", find);
    else
        printf("FAIL: No %d\n", find);

    return 0;
}