/*
 * AccelTest.xc
 *
 *  Created on: 27 Nov 2015
 *      Author: matth
 */

#include <i2c.h>
#include <stdio.h>
#include <platform.h>
//#include <xs1.h>

void accelerometer(client i2c_master_if i2c);
void output_accelerometer_values(int x, int y, int z);

// I2C interface ports
port p_scl = XS1_PORT_1E;
port p_sda = XS1_PORT_1F;
port p_led = XS1_PORT_4F;


// FXOS8700EQ register address defines
#define FXOS8700EQ_I2C_ADDR 0x1E
#define FXOS8700EQ_XYZ_DATA_CFG_REG 0x0E
#define FXOS8700EQ_CTRL_REG_1 0x2A
#define FXOS8700EQ_DR_STATUS 0x0
#define FXOS8700EQ_OUT_X_MSB 0x1
#define FXOS8700EQ_OUT_X_LSB 0x2
#define FXOS8700EQ_OUT_Y_MSB 0x3
#define FXOS8700EQ_OUT_Y_LSB 0x4
#define FXOS8700EQ_OUT_Z_MSB 0x5
#define FXOS8700EQ_OUT_Z_LSB 0x6


void accelerometer(client i2c_master_if i2c) {
    i2c_regop_res_t result;
    char status_data = 0;

    // Configure FXOS8700EQ
    result = i2c.write_reg(FXOS8700EQ_I2C_ADDR, FXOS8700EQ_XYZ_DATA_CFG_REG, 0x01);
    if (result != I2C_REGOP_SUCCESS) {
    printf("I2C write reg failed\n");
    }
    // Enable FXOS8700EQ
    result = i2c.write_reg(FXOS8700EQ_I2C_ADDR, FXOS8700EQ_CTRL_REG_1, 0x01);
    if (result != I2C_REGOP_SUCCESS) {
    printf("I2C write reg failed\n");
    }


    while (1) {
        // Wait for data ready from FXOS8700EQ
        do {
            status_data = i2c.read_reg(FXOS8700EQ_I2C_ADDR, FXOS8700EQ_DR_STATUS, result);
        } while (!status_data & 0x08);

        int x,y,z;
        x = read_acceleration(i2c, FXOS8700EQ_OUT_X_MSB);
        y = read_acceleration(i2c, FXOS8700EQ_OUT_Y_MSB);
        z = read_acceleration(i2c, FXOS8700EQ_OUT_Z_MSB);

        output_accelerometer_values(x,y,z);
    }
}

void output_accelerometer_values(int x, int y, int z) {
int rgb_led_value = 0;
if (x > 0) {
rgb_led_value |= 0x2;
}
if (y > 0) {
rgb_led_value |= 0x4;
}
if (z > 0) {
rgb_led_value |= 0x8;
}
p_led <: rgb_led_value;
printf("X = %d, Y = %d, Z = %d \r", x, y, z);
}


int main(void) {
    i2c_master_if i2c[1];
    par {
        i2c_master(i2c, 1, p_scl, p_sda, 10);
        accelerometer(i2c[0]);
    }
    return 0;
}

