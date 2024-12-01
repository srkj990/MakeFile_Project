#include "FreeRTOS.h"
#include "task.h"
#include "stdint.h"
uint8_t ucHeap[ configTOTAL_HEAP_SIZE ];
// Task function prototypes
void vTask1(void *pvParameters);
void vTask2(void *pvParameters);

int main(void)
{
    // Create tasks
    xTaskCreate(vTask1, "Task1", configMINIMAL_STACK_SIZE, NULL, 1, NULL);
    xTaskCreate(vTask2, "Task2", configMINIMAL_STACK_SIZE, NULL, 1, NULL);

    // Start the scheduler
    vTaskStartScheduler();

    // The program should never reach here
    for (;;);
}

void vTask1(void *pvParameters)
{
    for (;;)
    {
        // Task 1 code
        Sub_main1();
    }
}

void vTask2(void *pvParameters)
{
    for (;;)
    {
        // Task 2 code
        Sub_main2();
    }
}
