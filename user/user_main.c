#include "ets_sys.h"
#include "osapi.h"
#include "gpio.h"
#include "os_type.h"
#include "user_config.h"

#ifdef DEBUG
#include "../gdbstub/gdbstub.h"
#endif

#define user_procTaskPrio        0
#define user_procTaskQueueLen    1
os_event_t    user_procTaskQueue[user_procTaskQueueLen];
static void user_procTask(os_event_t *events);
static volatile os_timer_t some_timer;

// do blinky stuff
void some_timerfunc(void *arg)
{
    if (GPIO_REG_READ(GPIO_OUT_ADDRESS) & BIT2)
    {
        // set GPIO2 to LOW
        gpio_output_set(0, BIT2, BIT2, 0);
    }
    else
    {
        // set GPIO2 to HIGH
        gpio_output_set(BIT2, 0, BIT2, 0);
    }
}

// do nothing function
static void ICACHE_FLASH_ATTR
user_procTask(os_event_t *events)
{
    os_delay_us(10);
}

// init function 
void ICACHE_FLASH_ATTR
user_init()
{
#ifdef DEBUG
    uart_div_modify(0, UART_CLK_FREQ / 115200);
    gdbstub_init();
#endif

    // initialize the GPIO subsystem.
    gpio_init();

    // set GPIO2 to output mode
    PIN_FUNC_SELECT(PERIPHS_IO_MUX_GPIO2_U, FUNC_GPIO2);

    // set GPIO2 low
    gpio_output_set(0, BIT2, BIT2, 0);

    // disarm timer
    os_timer_disarm(&some_timer);

    // setup timer
    os_timer_setfn(&some_timer, (os_timer_func_t *)some_timerfunc, NULL);

    // arm the timer
    // &some_timer is the pointer
    // 1000 is the fire time in ms
    // 0 for once and 1 for repeating
    os_timer_arm(&some_timer, 1000, 1);
    
    // start task
    system_os_task(user_procTask, user_procTaskPrio,user_procTaskQueue, user_procTaskQueueLen);
}
