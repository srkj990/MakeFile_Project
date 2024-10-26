#include <stdio.h>
int main1()
{
   char name[50];
   int marks, i, num;
   printf("Enter number of students: ");
   scanf("%d", &num);
   FILE *fptr;
   fptr = (fopen("C:\\student.txt", "a"));
   if(fptr == NULL)
   {
       printf("Error!");
   }
   for(i = 0; i < num; ++i)
   {
      printf("For student%d\nEnter name: ", i+1);
      scanf("%s", name);
      printf("Enter marks: ");
      scanf("%d", &marks);
      fprintf(fptr,"\nName: %s \nMarks=%d \n", name, marks);
   }
   return 0;
}