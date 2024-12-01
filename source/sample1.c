#include "../include/sample1.h"// Simple C program to display "Hello World"

unsigned char SampleArray[121072] = {0};

// Declare a constant array placed in the .rodata section
static int my_read_only_array[] = {1, 2, 3, 4, 5};

/* Create an array in the custom section */
__attribute__((section(".my_section"))) int custom_section_Array[100] = {0};


int Sub_main2()
{
   char name[50];
   int marks, i, num;
   //printf("Enter number of students: ");
   //scanf("%d", &num);
   for(i = 0; i < num; ++i)
   {
      //printf("For student%d\nEnter name: ", i+1);
      //scanf("%s", name);
      //printf("Enter marks: ");
      //scanf("%d", &marks);
      //printf("\nName: %s \nMarks=%d \n", name, marks);
   }
   return 0;
}