#include "linked_list.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

#include "../../../kernel/common.h"

typedef struct LinkedList {
    int                 item;
    struct LinkedList*  next;
} LinkedList;

static void insert_item(LinkedList** tail, int i)
{
    LinkedList* newElem = (LinkedList*)malloc(sizeof(LinkedList));
    newElem->item = i;
    newElem->next = NULL;

    (*tail)->next = newElem;
    *tail = newElem;
}

static LinkedList* init_list(int n)
{
    LinkedList* head = (LinkedList*)malloc(sizeof(LinkedList));
    head->item = 0;
    head->next = NULL;

    LinkedList* tail = head;
    for (int i = 1; i < n; i++)
    {
        insert_item(&tail, i);
    }

    return head;
}

static void free_list(LinkedList* head)
{
    LinkedList* current = head;
    while (current != NULL)
    {
        LinkedList* next = current->next;
        free(current);
        current = next;
    }
}

static bool find_item(LinkedList* head, int i)
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

void test_linked_list(void)
{
    static const int N = 750;

    // Create a linked-list of numbers 0 -> N and see if we can successfully traverse it
    LinkedList* head = init_list(N);

    int find = rand() % N;

    if (find_item(head, find))
        printf("PASS: Found %d\n", find);
    else
        printf("FAIL: No %d\n", find);

    free_list(head);
}