# Analog example

## Overview
This is a simple ADC that uses the idea of ramp-compare implementation.

## Files
- `top.v` — The `top` (e.g. 'main') module that connects the "ADC" module to the PWM module and the output of the PWM module to the blue LED.
- `pwm.v` — Simple, non-configurable module for 14-bit PWM.
- `sense.v` — The module that is responsible for measuring of the analog signal. The module does not include mux configuration, this is done in the top module.
- `Makefile` — The make build script that will produce the bitstream from the HDL. It makes uses of the open source tools `yosys`, `nextpnr`, `ecppack`, and `dfu-util` to go from hardware description to bitstream to running on the FPGA.

## How it works
The ADC contains a comparator and an RC circuit. An analog signal is applied to the positive input of the comparator and the negative input is the output of the RC circuit. When high signal is applied to the RC circuit input, the voltage on the capacitor will start to rise and as soon as it exceeds the voltage on the positive pin of comparator, the comparator output will change from 1 to 0.
If we count the ones (or zeros) during this period, we will get the relative value of the amplitude of the read signal.

The ECP5 FPGA does not have a comparator, but a differential input can be used instead, because according to the datasheet, the required minimum threshold between inputs is 100 mV, which is relatively small.

Since the input signal on the board is connected through the divider R44-R45, the capacitor needs to be charged to only half of VCC, i.e. ~1.65 V.

![Differential input curves](https://raw.githubusercontent.com/orangecrab-fpga/orangecrab-examples/refs/heads/main/verilog/analog_to_pwm/curves.png)

*Yellow curve - voltage at the output of the RC circuit (positive terminal of the differential input). Purple curve - voltage at the analog input (positive terminal of the differential input, the probe multiplier is set to 5X, instead of 10X, to estimate the voltage after the divider). Blue curve - output of the differential input.*

## Concepts Introduced
- Use of the built-in analog multiplexer and RC circuit to read the analog signal
- Use of a finite element machine

## Specification
### Frequency:
The cutoff frequency of the RC circuit is about 312 Hz.

### Samplerate:
The full cycle of one measurement consists of SETUP + CHARGE + DISCHARGE, which is ~1560 us/Sa or 640 Sa/s, respectively.

### Resolution:
There are 16969 cycles per charge cycle (15 bits incomplete), so the maximum output number should ideally be 16969 as well. However, practical tests show that the maximum number is less than 14 bits (about 13100).

## Downsides
### Offset:
As mentioned earlier, the differential input has a threshold of 100 mV, so the signals must be measured with this offset.
In addition, because the discharge time is selected as 3*RC, at the end of the cycle the capacitor is not fully discharged and still has some voltage around pins (about 5%). Situation can be improved by increasing the discharge time, but this will reduce the sampling rate.

### Nonlinear response:
The charge curve of a capacitor is not straight, so the dependence of the measurement result will be non-linear. This can be corrected with additional digital filters and/or, in the case of softcore, on the software side.

## Further Reading
- [Original code by Sylvain Munaut \<tnt@246tNt.com\>](https://gist.github.com/smunaut/bb87ed1ccbf6389977ab2be65f427625) — The code from which this example was adapted.
