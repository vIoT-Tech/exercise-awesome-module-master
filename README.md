# AwesomeModule

## Overview and Usage

The [AwesomeModule](vhdl/AwesomeModule.vhd) is a DMA that stores miracle data to the host memory.
To read the miracle data:

1. Enable the DONE interrupt.
2. Set up the buffer target address and size for the next transfer (chunk of data).
3. Start the transfer.
4. Wait for the DONE interrupt.
5. Repeat at step (2) for the next buffer.

## Test Bench

A [cocotb](https://www.cocotb.org/) [test bench](tb/tb_awesome_module.py) is provided to demonstrate the basic usage of the model.
The test bench provides a virtual memory `tb.mem` into which the miracle data is stored by the AwesomeModule.

The [setup.sh](setup.sh) script can be used to install all of the following dependencies (tested with Ubuntu 24.04; might work on other Ubuntu or Debian versions):

- cocotb
- pytest
- [ghdl](http://ghdl.free.fr/)
- [gtkwave](https://gtkwave.sourceforge.net/)

The [run.sh](run.sh) can be used to run the test within the pytest framework. The test will generate a `wave.gcd` file with all recorded waveworms that can
be inspected with gtkwave: `gtkwave wave.gcd`.

## Ports

Port           | Role   | Clock Domain | Description
---------------|--------|--------------|---------------------------------------
clk            | in     | N/A          | Clock
rst            | in     | clk          | Active-high, clock synchronous reset
irq            | out    | clk          | Level-sensitive interrupt
s\_axi\_ctrl   | slave  | clk          | AXI4-Lite status und control register interface
m\_axi\_data   | master | clk          | AXI4 memory access interface

## Register Description

### Overview

Address |  Description
--------|-------------------------------------------
0x00    | Interrupt Status (IS)
0x04    | Interrupt Enable (IE)
0x08    | Global Interrupt Enable (GIE)
0x0C    | Control (CTRL)
0x10    | Buffer target address, low 32-bit (BUF\_ADDR\_L)
0x14    | Buffer target address, high 32-bit (BUF\_ADDR\_H)
0x18    | Buffer size (BUF\_SIZE)

### Interrupt Status (IS)

Read: Status of pending interrupts.

Write: Clear pending interupts by writing `1` to the corresponding status bit(s).

Bit | Description
----|----------------
0   | DONE: The last buffer transfer finished successfully
1   | ERROR: Error during transmission

### Interrupt Enable (IE)

Per-interrupt mask (enable/disable). Disabled sources will not generate a `irq` output.

Bit | Description
----|-------------
0   | DONE
1   | ERROR

### Global Interrupt Enable (GIE)

Globally enable/disable interrupts.
When disabled, no interrupts will be generated.
When enabled, the enabled interrupt sources (as defined by IE register) will generate an interrupt output.

Bit | Description
----|--------------
0   | Global Interrupt Enable

### Control (CTRL)

This register provides strobe register to initiiate the following actions:

Bit | Description
----|-----------------------------
0   | (Request to) Start transfer. Resets to `0` automatically when the requested transfer started. Buffer target address and size must be set up before.
31  | Soft reset.  Resets to `0` immediately.

### Buffer target address (BUF\_ADDR\_L, BUF\_ADDR\_H)

This set of registers defines the buffer target address for the next transfer (little endian byte order).

### Buffer size (BUF\_SIZE)

This register defines the size of the buffer for the next transfer (little endian byte order).

