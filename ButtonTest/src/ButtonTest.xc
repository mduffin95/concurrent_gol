/*
 * ButtonTest.xc
 *
 *  Created on: 26 Nov 2015
 *      Author: matth
 */

#include <gpio.h>
#include <platform.h>

// GPIO port declarations
on tile[0] : in port explorer_buttons = XS1_PORT_4E;
on tile[0] : out port explorer_leds = XS1_PORT_4F;

void gpio_handler(client input_gpio_if button_1, client input_gpio_if button_2,
client output_gpio_if led_green, client output_gpio_if rgb_led_blue,
client output_gpio_if rgb_led_green, client output_gpio_if rgb_led_red) {
    // LED state
    unsigned int green_led_state = 0;
    unsigned int rgb_led_state = 0;

    // Initial button event state, active low
    button_1.event_when_pins_eq(0);
    button_2.event_when_pins_eq(0);

    while (1) {
        select {
            // Triggered by events on button 1
            case button_1.event():
                if (button_1.input() == 0) {
                    green_led_state = ~green_led_state;
                    led_green.output(green_led_state);
                    // Set button event state to active high for debounce
                    button_1.event_when_pins_eq(1);
                } else {
                    // Debounce button
                    delay_milliseconds(50);
                    button_1.event_when_pins_eq(0);
                }
                break;
            case button_2.event():
                if (button_2.input() == 0) {
                    rgb_led_red.output(0);
                    rgb_led_green.output(0);
                    rgb_led_blue.output(0);
                    rgb_led_state++;
                    rgb_led_state %= 4;
                    switch (rgb_led_state) {
                    case 1:
                        rgb_led_red.output(1);
                        break;
                    case 2:
                        rgb_led_green.output(1);
                        break;
                    case 3:
                        rgb_led_blue.output(1);
                        break;
                    }
                    // Set button event state to active high for debounce
                    button_2.event_when_pins_eq(1);
                } else {
                    // Debounce button
                    delay_milliseconds(50);
                    button_2.event_when_pins_eq(0);
                }
                break;
        }
    }
}

int main() {
    input_gpio_if i_explorer_buttons[2];
    output_gpio_if i_explorer_leds[4];
    par {
        on tile[0] : input_gpio_with_events(i_explorer_buttons, 2, explorer_buttons, null);
        on tile[0] : output_gpio(i_explorer_leds, 4, explorer_leds, null);
        on tile[0] : gpio_handler(i_explorer_buttons[0], i_explorer_buttons[1],
        i_explorer_leds[0], i_explorer_leds[1],
        i_explorer_leds[2], i_explorer_leds[3]);
    }
    return 0;
}

