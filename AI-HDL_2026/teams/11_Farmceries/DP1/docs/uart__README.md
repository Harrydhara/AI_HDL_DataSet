# UART Peripheral Implementation

Complete UART peripheral with FIFOs, hardware flow control, and production-grade features.

## Overview

This directory contains a **complete, tested UART peripheral** ready for CPU integration. The implementation includes:

- **Core UART**: Baud rate generator, transmitter, receiver
- **FIFOs**: 16-byte TX/RX buffers with watermark detection
- **Hardware Flow Control**: RTS/CTS handshaking
- **Register Interface**: Memory-mapped CPU control
- **Test Coverage**: 37/37 tests passing

## Architecture

```
uart_peripheral (top-level module)
    ├── uart_baud_generator    - Configurable baud rate timing
    ├── uart_tx                - Transmitter (parallel → serial)
    ├── uart_rx                - Receiver (serial → parallel)
    ├── uart_fifo (x2)         - TX/RX 16-byte buffers
    ├── uart_tx_flow           - TX flow control logic
    ├── uart_rts_gen           - RTS generation based on RX FIFO
    └── uart_register_interface - CPU memory-mapped registers
```

## Integration

**For TinyQV CPU Integration**:
```verilog
uart_peripheral uart (
    .clk(clk),
    .rst_n(rst_n),
    
    // CPU interface
    .address(periph_addr[3:0]),
    .data_in(periph_wdata),
    .data_write_n(periph_wstrb),
    .data_read_n(periph_rstrb),
    .data_out(periph_rdata),
    .data_ready(periph_ready),
    
    // UART pins
    .uart_rx_pin(uart_rx),
    .uart_tx_pin(uart_tx),
    
    // Flow control
    .cts_n(uart_cts),
    .rts_n(uart_rts),
    
    .interrupt(uart_int)
);
```

## Modules

### Core UART
- **uart_baud_generator.v** - Programmable baud rate clock (9600-921600)
- **uart_tx.v** - 8N1 transmitter with start/stop bits
- **uart_rx.v** - 8N1 receiver with error detection

### Enhanced Features
- **uart_fifo.v** - Parameterizable FIFO (16-byte depth)
- **uart_tx_flow.v** - CTS-based transmitter flow control
- **uart_rts_gen.v** - RTS generation based on RX FIFO level

### Integration
- **uart_register_interface.v** - CPU memory-mapped registers
- **uart_peripheral.v** - Complete peripheral (integrates all modules)

## Test Results

**Status**: ✅ 37/37 tests passing

- Baud generator: 3/3 PASS
- TX/RX basic: 5/5 PASS  
- FIFOs: 6/6 PASS
- Flow control: 4/4 PASS
- Register interface: 5/5 PASS
- Loopback/integration: 14/14 PASS

Run tests: `cd ../../test && make -f test_uart_loopback.mk`

## Register Map

See [../../docs/uart/UART_REGISTERS.md](../../docs/uart/UART_REGISTERS.md) for complete register documentation.

## Documentation

Complete documentation available in `dp-1/docs/uart/`:
- Block diagrams and timing diagrams
- UART fundamentals and protocol details
- Register specifications
- Integration guides

## Related Implementations

- **Basic UART**: This module (standalone serial communication)
- **Secure UART**: See `dp-1/docs/secure-uart/` for AES-encrypted UART peripheral

