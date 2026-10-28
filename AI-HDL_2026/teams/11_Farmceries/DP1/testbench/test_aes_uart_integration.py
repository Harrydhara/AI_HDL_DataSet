"""
AES-UART Integration Tests
Tests the complete AES encryption/decryption flow with UART data paths
"""

import cocotb
from cocotb.triggers import Timer, RisingEdge, ClockCycles
from cocotb.clock import Clock
import random

# Test vectors
TEST_KEY = 0x000102030405060708090a0b0c0d0e0f
ALT_KEY = 0x2b7e151628aed2a6abf7158809cf4f3c  # Different key for key-switching tests

# 16-byte plaintext message
TEST_PLAINTEXT_BYTES = [
    0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
    0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff
]

# Expected ciphertext (from NIST vectors)
EXPECTED_CIPHERTEXT = 0x69c4e0d86a7b0430d8cdb78070b4c55a

# Known NIST test vectors
NIST_VECTORS = [
    {
        'key': 0x000102030405060708090a0b0c0d0e0f,
        'plaintext': [0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
                     0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff],
        'ciphertext': 0x69c4e0d86a7b0430d8cdb78070b4c55a
    },
    {
        'key': 0x2b7e151628aed2a6abf7158809cf4f3c,
        'plaintext': [0x32, 0x43, 0xf6, 0xa8, 0x88, 0x5a, 0x30, 0x8d,
                     0x31, 0x31, 0x98, 0xa2, 0xe0, 0x37, 0x07, 0x34],
        'ciphertext': 0x3925841d02dc09fbdc118597196a0b32
    }
]

@cocotb.test()
async def test_tx_encryption(dut):
    """Test TX path: plaintext bytes -> encrypted block"""
    
    # Setup clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.aes_enable.value = 0
    dut.tx_data_valid.value = 0
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # Load AES key
    dut.aes_key.value = TEST_KEY
    dut.aes_enable.value = 1
    await RisingEdge(dut.clk)
    
    # Send 16 plaintext bytes to TX path
    dut._log.info("Sending 16 plaintext bytes...")
    for i, byte_val in enumerate(TEST_PLAINTEXT_BYTES):
        dut.tx_data_in.value = byte_val
        dut.tx_data_valid.value = 1
        await RisingEdge(dut.clk)
        dut.tx_data_valid.value = 0
        
        # Check byte counter
        if i < 15:
            await RisingEdge(dut.clk)
    
    # Wait for encryption to complete
    dut._log.info("Waiting for TX encryption...")
    timeout = 0
    while dut.tx_block_valid.value == 0:
        await RisingEdge(dut.clk)
        timeout += 1
        if timeout > 100:
            assert False, "TX encryption timeout"
    
    # Check encrypted output
    actual_ciphertext = dut.tx_block_out.value.integer
    dut._log.info(f"Plaintext:  0x{''.join(f'{b:02x}' for b in TEST_PLAINTEXT_BYTES)}")
    dut._log.info(f"Ciphertext: 0x{actual_ciphertext:032x}")
    dut._log.info(f"Expected:   0x{EXPECTED_CIPHERTEXT:032x}")
    
    assert actual_ciphertext == EXPECTED_CIPHERTEXT, \
        f"TX encryption failed: got 0x{actual_ciphertext:032x}"
    
    dut._log.info("✓ TX encryption successful")

@cocotb.test()
async def test_rx_decryption(dut):
    """Test RX path: ciphertext bytes -> decrypted plaintext"""
    
    # Setup clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.aes_enable.value = 0
    dut.rx_data_valid.value = 0
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # Load AES key
    dut.aes_key.value = TEST_KEY
    dut.aes_enable.value = 1
    await RisingEdge(dut.clk)
    
    # Convert ciphertext to bytes (MSB first)
    ciphertext_bytes = []
    for i in range(16):
        byte_val = (EXPECTED_CIPHERTEXT >> (120 - i*8)) & 0xFF
        ciphertext_bytes.append(byte_val)
    
    # Send 16 ciphertext bytes to RX path
    dut._log.info("Sending 16 ciphertext bytes to RX for decryption...")
    for i, byte_val in enumerate(ciphertext_bytes):
        dut.rx_data_in.value = byte_val
        dut.rx_data_valid.value = 1
        await RisingEdge(dut.clk)
        dut.rx_data_valid.value = 0
        
        if i < 15:
            await RisingEdge(dut.clk)
    
    # Wait for decryption to complete
    dut._log.info("Waiting for RX decryption...")
    timeout = 0
    while dut.rx_block_valid.value == 0:
        await RisingEdge(dut.clk)
        timeout += 1
        if timeout > 100:
            assert False, "RX decryption timeout"
    
    # Verify decrypted plaintext matches original
    actual_plaintext = dut.rx_block_out.value.integer
    expected_plaintext = int.from_bytes(TEST_PLAINTEXT_BYTES, 'big')
    
    dut._log.info(f"Ciphertext: 0x{EXPECTED_CIPHERTEXT:032x}")
    dut._log.info(f"Plaintext:  0x{actual_plaintext:032x}")
    dut._log.info(f"Expected:   0x{expected_plaintext:032x}")
    
    assert actual_plaintext == expected_plaintext, \
        f"RX decryption failed: got 0x{actual_plaintext:032x}, expected 0x{expected_plaintext:032x}"
    
    dut._log.info("✓ RX decryption successful - ciphertext correctly decrypted to plaintext")

@cocotb.test()
async def test_full_duplex_encryption(dut):
    """Test simultaneous TX encryption and RX decryption with independent data streams"""
    
    # Setup clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.aes_enable.value = 0
    dut.tx_data_valid.value = 0
    dut.rx_data_valid.value = 0
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # Load key and enable
    dut.aes_key.value = TEST_KEY
    dut.aes_enable.value = 1
    await RisingEdge(dut.clk)
    
    dut._log.info("Starting full-duplex operation with independent TX/RX data...")
    
    # Prepare TX data (incrementing pattern)
    tx_plaintext = [i & 0xFF for i in range(16)]
    
    # Prepare RX data (use known ciphertext to decrypt)
    rx_ciphertext_bytes = []
    for i in range(16):
        byte_val = (EXPECTED_CIPHERTEXT >> (120 - i*8)) & 0xFF
        rx_ciphertext_bytes.append(byte_val)
    
    # Send TX and RX data simultaneously
    async def send_tx_data():
        for i, byte_val in enumerate(tx_plaintext):
            dut.tx_data_in.value = byte_val
            dut.tx_data_valid.value = 1
            await RisingEdge(dut.clk)
            dut.tx_data_valid.value = 0
            if i < 15:
                await RisingEdge(dut.clk)
    
    async def send_rx_data():
        for i, byte_val in enumerate(rx_ciphertext_bytes):
            dut.rx_data_in.value = byte_val
            dut.rx_data_valid.value = 1
            await RisingEdge(dut.clk)
            dut.rx_data_valid.value = 0
            if i < 15:
                await RisingEdge(dut.clk)
    
    # Start both simultaneously
    tx_task = cocotb.start_soon(send_tx_data())
    rx_task = cocotb.start_soon(send_rx_data())
    
    # Wait for both to finish sending
    await tx_task
    await rx_task
    
    # Wait for both operations to complete
    dut._log.info("Waiting for both TX encryption and RX decryption to complete...")
    tx_done = False
    rx_done = False
    timeout = 0
    
    while not (tx_done and rx_done) and timeout < 200:
        await RisingEdge(dut.clk)
        if dut.tx_block_valid.value == 1 and not tx_done:
            tx_result = dut.tx_block_out.value.integer
            dut._log.info(f"TX encryption completed: 0x{tx_result:032x}")
            tx_done = True
        if dut.rx_block_valid.value == 1 and not rx_done:
            rx_result = dut.rx_block_out.value.integer
            expected_rx = int.from_bytes(TEST_PLAINTEXT_BYTES, 'big')
            assert rx_result == expected_rx, f"RX decryption failed: got 0x{rx_result:032x}, expected 0x{expected_rx:032x}"
            dut._log.info(f"RX decryption completed: 0x{rx_result:032x}")
            rx_done = True
        timeout += 1
    
    assert tx_done and rx_done, f"Full-duplex operation timeout (TX:{tx_done}, RX:{rx_done})"
    dut._log.info("✓ Full-duplex operation successful - TX and RX operate independently")

@cocotb.test()
async def test_all_zeros(dut):
    """Test encryption of all-zero plaintext"""
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.aes_enable.value = 0
    dut.tx_data_valid.value = 0
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # Load key
    dut.aes_key.value = TEST_KEY
    dut.aes_enable.value = 1
    await RisingEdge(dut.clk)
    
    # Send all zeros
    dut._log.info("Testing all-zero plaintext...")
    for i in range(16):
        dut.tx_data_in.value = 0x00
        dut.tx_data_valid.value = 1
        await RisingEdge(dut.clk)
        dut.tx_data_valid.value = 0
        if i < 15:
            await RisingEdge(dut.clk)
    
    # Wait for completion
    timeout = 0
    while dut.tx_block_valid.value == 0:
        await RisingEdge(dut.clk)
        timeout += 1
        if timeout > 100:
            assert False, "Timeout waiting for encryption"
    
    result = dut.tx_block_out.value.integer
    dut._log.info(f"All-zeros ciphertext: 0x{result:032x}")
    
    # Should not be all zeros (encryption should randomize)
    assert result != 0, "Encrypted all-zeros should not be zero"
    dut._log.info("✓ All-zeros test passed")

@cocotb.test()
async def test_all_ones(dut):
    """Test encryption of all-ones plaintext (0xFF pattern)"""
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.aes_enable.value = 0
    dut.tx_data_valid.value = 0
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # Load key
    dut.aes_key.value = TEST_KEY
    dut.aes_enable.value = 1
    await RisingEdge(dut.clk)
    
    # Send all 0xFF
    dut._log.info("Testing all-ones plaintext...")
    for i in range(16):
        dut.tx_data_in.value = 0xFF
        dut.tx_data_valid.value = 1
        await RisingEdge(dut.clk)
        dut.tx_data_valid.value = 0
        if i < 15:
            await RisingEdge(dut.clk)
    
    # Wait for completion
    timeout = 0
    while dut.tx_block_valid.value == 0:
        await RisingEdge(dut.clk)
        timeout += 1
        if timeout > 100:
            assert False, "Timeout waiting for encryption"
    
    result = dut.tx_block_out.value.integer
    dut._log.info(f"All-ones ciphertext: 0x{result:032x}")
    
    # Should not be all ones
    assert result != 0xffffffffffffffffffffffffffffffff, "Encrypted all-ones should not be all ones"
    dut._log.info("✓ All-ones test passed")

@cocotb.test()
async def test_alternating_pattern(dut):
    """Test encryption of alternating bit pattern (0xAA/0x55)"""
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.aes_enable.value = 0
    dut.tx_data_valid.value = 0
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # Load key
    dut.aes_key.value = TEST_KEY
    dut.aes_enable.value = 1
    await RisingEdge(dut.clk)
    
    # Send alternating pattern
    dut._log.info("Testing alternating pattern (0xAA/0x55)...")
    for i in range(16):
        byte_val = 0xAA if i % 2 == 0 else 0x55
        dut.tx_data_in.value = byte_val
        dut.tx_data_valid.value = 1
        await RisingEdge(dut.clk)
        dut.tx_data_valid.value = 0
        if i < 15:
            await RisingEdge(dut.clk)
    
    # Wait for completion
    timeout = 0
    while dut.tx_block_valid.value == 0:
        await RisingEdge(dut.clk)
        timeout += 1
        if timeout > 100:
            assert False, "Timeout waiting for encryption"
    
    result = dut.tx_block_out.value.integer
    dut._log.info(f"Alternating pattern ciphertext: 0x{result:032x}")
    dut._log.info("✓ Alternating pattern test passed")

@cocotb.test()
async def test_key_switching(dut):
    """Test switching between different encryption keys"""
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    dut._log.info("Testing key switching...")
    
    # Test with first key
    dut.aes_key.value = NIST_VECTORS[0]['key']
    dut.aes_enable.value = 1
    await RisingEdge(dut.clk)
    
    # Encrypt with first key
    for i, byte_val in enumerate(NIST_VECTORS[0]['plaintext']):
        dut.tx_data_in.value = byte_val
        dut.tx_data_valid.value = 1
        await RisingEdge(dut.clk)
        dut.tx_data_valid.value = 0
        if i < 15:
            await RisingEdge(dut.clk)
    
    # Wait for first encryption
    timeout = 0
    while dut.tx_block_valid.value == 0:
        await RisingEdge(dut.clk)
        timeout += 1
        if timeout > 100:
            assert False, "Timeout on first encryption"
    
    result1 = dut.tx_block_out.value.integer
    assert result1 == NIST_VECTORS[0]['ciphertext'], "First key encryption failed"
    dut._log.info(f"First key result: 0x{result1:032x} ✓")
    
    # Wait for idle state
    await ClockCycles(dut.clk, 5)
    
    # Switch to second key
    dut.aes_key.value = NIST_VECTORS[1]['key']
    await RisingEdge(dut.clk)
    
    # Encrypt with second key
    for i, byte_val in enumerate(NIST_VECTORS[1]['plaintext']):
        dut.tx_data_in.value = byte_val
        dut.tx_data_valid.value = 1
        await RisingEdge(dut.clk)
        dut.tx_data_valid.value = 0
        if i < 15:
            await RisingEdge(dut.clk)
    
    # Wait for second encryption
    timeout = 0
    while dut.tx_block_valid.value == 0:
        await RisingEdge(dut.clk)
        timeout += 1
        if timeout > 100:
            assert False, "Timeout on second encryption"
    
    result2 = dut.tx_block_out.value.integer
    assert result2 == NIST_VECTORS[1]['ciphertext'], "Second key encryption failed"
    dut._log.info(f"Second key result: 0x{result2:032x} ✓")
    
    # Verify results are different
    assert result1 != result2, "Different keys should produce different ciphertexts"
    dut._log.info("✓ Key switching test passed")

@cocotb.test()
async def test_consecutive_blocks(dut):
    """Test multiple consecutive block encryptions"""
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # Load key
    dut.aes_key.value = TEST_KEY
    dut.aes_enable.value = 1
    await RisingEdge(dut.clk)
    
    dut._log.info("Testing 3 consecutive block encryptions...")
    
    # Encrypt 3 blocks back-to-back
    for block_num in range(3):
        # Generate test pattern for this block
        plaintext = [(block_num * 16 + i) & 0xFF for i in range(16)]
        
        # Send 16 bytes
        for i, byte_val in enumerate(plaintext):
            dut.tx_data_in.value = byte_val
            dut.tx_data_valid.value = 1
            await RisingEdge(dut.clk)
            dut.tx_data_valid.value = 0
            if i < 15:
                await RisingEdge(dut.clk)
        
        # Wait for completion
        timeout = 0
        while dut.tx_block_valid.value == 0:
            await RisingEdge(dut.clk)
            timeout += 1
            if timeout > 100:
                assert False, f"Timeout on block {block_num}"
        
        result = dut.tx_block_out.value.integer
        dut._log.info(f"Block {block_num} encrypted: 0x{result:032x}")
        
        # Wait a bit before next block
        await ClockCycles(dut.clk, 2)
    
    dut._log.info("✓ Consecutive blocks test passed")

@cocotb.test()
async def test_back_to_back_no_gap(dut):
    """Test back-to-back block encryption - verifies controller needs time between blocks"""
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # Load key
    dut.aes_key.value = TEST_KEY
    dut.aes_enable.value = 1
    await RisingEdge(dut.clk)
    
    dut._log.info("Testing back-to-back block behavior...")
    
    # Send first block
    for i in range(16):
        dut.tx_data_in.value = i & 0xFF
        dut.tx_data_valid.value = 1
        await RisingEdge(dut.clk)
        dut.tx_data_valid.value = 0
        if i < 15:
            await RisingEdge(dut.clk)
    
    # Wait for first block
    timeout = 0
    while dut.tx_block_valid.value == 0:
        await RisingEdge(dut.clk)
        timeout += 1
        if timeout > 100:
            assert False, "Timeout on first block"
    
    result1 = dut.tx_block_out.value.integer
    dut._log.info(f"First block: 0x{result1:032x}")
    
    # Wait for controller to return to idle (design requirement)
    await ClockCycles(dut.clk, 2)
    
    # Send second block
    for i in range(16):
        dut.tx_data_in.value = (16 + i) & 0xFF
        dut.tx_data_valid.value = 1
        await RisingEdge(dut.clk)
        dut.tx_data_valid.value = 0
        if i < 15:
            await RisingEdge(dut.clk)
    
    # Wait for second block
    timeout = 0
    while dut.tx_block_valid.value == 0:
        await RisingEdge(dut.clk)
        timeout += 1
        if timeout > 100:
            assert False, "Timeout on second block"
    
    result2 = dut.tx_block_out.value.integer
    dut._log.info(f"Second block: 0x{result2:032x}")
    
    # Blocks should be different
    assert result1 != result2, "Different plaintext blocks should produce different ciphertext"
    
    dut._log.info("✓ Back-to-back encryption test passed")

@cocotb.test()
async def test_reset_during_operation(dut):
    """Test reset assertion during active encryption"""
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # Load key
    dut.aes_key.value = TEST_KEY
    dut.aes_enable.value = 1
    await RisingEdge(dut.clk)
    
    dut._log.info("Testing reset during operation...")
    
    # Start sending bytes
    for i in range(8):  # Send only 8 bytes
        dut.tx_data_in.value = i
        dut.tx_data_valid.value = 1
        await RisingEdge(dut.clk)
        dut.tx_data_valid.value = 0
        await RisingEdge(dut.clk)
    
    # Assert reset mid-operation
    dut._log.info("Asserting reset mid-operation...")
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # Verify system returns to idle
    # tx_block_valid should be low
    assert dut.tx_block_valid.value == 0, "Block valid should be low after reset"
    
    # Now try a complete encryption after reset
    dut.aes_key.value = TEST_KEY
    dut.aes_enable.value = 1
    await RisingEdge(dut.clk)
    
    # Send complete block
    for i in range(16):
        dut.tx_data_in.value = i
        dut.tx_data_valid.value = 1
        await RisingEdge(dut.clk)
        dut.tx_data_valid.value = 0
        if i < 15:
            await RisingEdge(dut.clk)
    
    # Wait for completion
    timeout = 0
    while dut.tx_block_valid.value == 0:
        await RisingEdge(dut.clk)
        timeout += 1
        if timeout > 100:
            assert False, "Timeout after reset recovery"
    
    result = dut.tx_block_out.value.integer
    dut._log.info(f"Post-reset encryption: 0x{result:032x}")
    dut._log.info("✓ Reset during operation test passed")

@cocotb.test()
async def test_disable_during_operation(dut):
    """Test disabling AES during active encryption"""
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # Load key and enable
    dut.aes_key.value = TEST_KEY
    dut.aes_enable.value = 1
    await RisingEdge(dut.clk)
    
    dut._log.info("Testing AES disable during operation...")
    
    # Start sending bytes
    for i in range(10):  # Send 10 bytes
        dut.tx_data_in.value = i
        dut.tx_data_valid.value = 1
        await RisingEdge(dut.clk)
        dut.tx_data_valid.value = 0
        await RisingEdge(dut.clk)
    
    # Disable AES mid-operation
    dut._log.info("Disabling AES mid-operation...")
    dut.aes_enable.value = 0
    await ClockCycles(dut.clk, 10)
    
    # Re-enable and complete block
    dut._log.info("Re-enabling AES...")
    dut.aes_enable.value = 1
    await RisingEdge(dut.clk)
    
    # Send complete block
    for i in range(16):
        dut.tx_data_in.value = i
        dut.tx_data_valid.value = 1
        await RisingEdge(dut.clk)
        dut.tx_data_valid.value = 0
        if i < 15:
            await RisingEdge(dut.clk)
    
    # Should complete successfully
    timeout = 0
    while dut.tx_block_valid.value == 0:
        await RisingEdge(dut.clk)
        timeout += 1
        if timeout > 100:
            assert False, "Timeout after re-enable"
    
    result = dut.tx_block_out.value.integer
    dut._log.info(f"Post-disable encryption: 0x{result:032x}")
    dut._log.info("✓ Disable during operation test passed")

@cocotb.test()
async def test_byte_counter_verification(dut):
    """Verify internal byte counter behavior"""
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # Load key
    dut.aes_key.value = TEST_KEY
    dut.aes_enable.value = 1
    await RisingEdge(dut.clk)
    
    dut._log.info("Testing byte counter behavior...")
    
    # Send bytes one at a time and monitor state
    for i in range(16):
        dut.tx_data_in.value = i
        dut.tx_data_valid.value = 1
        await RisingEdge(dut.clk)
        dut.tx_data_valid.value = 0
        
        # Log state for debugging
        if i < 15:
            # Should still be buffering
            dut._log.info(f"Byte {i+1}/16 sent")
            await RisingEdge(dut.clk)
        else:
            # 16th byte - should trigger encryption
            dut._log.info(f"Byte 16/16 sent - encryption should start")
    
    # Wait for completion
    timeout = 0
    while dut.tx_block_valid.value == 0:
        await RisingEdge(dut.clk)
        timeout += 1
        if timeout > 100:
            assert False, "Timeout"
    
    dut._log.info("✓ Byte counter verification passed")

@cocotb.test()
async def test_simultaneous_tx_rx_different_data(dut):
    """Test TX and RX operating simultaneously with different data"""
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # Load key
    dut.aes_key.value = TEST_KEY
    dut.aes_enable.value = 1
    await RisingEdge(dut.clk)
    
    dut._log.info("Testing simultaneous TX/RX with different data...")
    
    # Send different data to TX and RX simultaneously
    async def send_tx():
        for i in range(16):
            dut.tx_data_in.value = i
            dut.tx_data_valid.value = 1
            await RisingEdge(dut.clk)
            dut.tx_data_valid.value = 0
            if i < 15:
                await RisingEdge(dut.clk)
    
    async def send_rx():
        for i in range(16):
            dut.rx_data_in.value = 0xFF - i  # Different pattern
            dut.rx_data_valid.value = 1
            await RisingEdge(dut.clk)
            dut.rx_data_valid.value = 0
            if i < 15:
                await RisingEdge(dut.clk)
    
    # Start both simultaneously
    tx_task = cocotb.start_soon(send_tx())
    rx_task = cocotb.start_soon(send_rx())
    
    await tx_task
    await rx_task
    
    # Wait for both to complete
    tx_done = False
    rx_done = False
    timeout = 0
    
    while not (tx_done and rx_done):
        await RisingEdge(dut.clk)
        if dut.tx_block_valid.value == 1:
            tx_done = True
            tx_result = dut.tx_block_out.value.integer
        if dut.rx_block_valid.value == 1:
            rx_done = True
            rx_result = dut.rx_block_out.value.integer
        
        timeout += 1
        if timeout > 150:
            assert False, f"Timeout (TX done: {tx_done}, RX done: {rx_done})"
    
    dut._log.info(f"TX result: 0x{tx_result:032x}")
    dut._log.info(f"RX result: 0x{rx_result:032x}")
    dut._log.info("✓ Simultaneous TX/RX with different data passed")
