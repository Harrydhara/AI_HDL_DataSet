"""
AES Core Full Encryption Tests  
Tests complete 10-round AES-128 encryption with NIST test vectors
"""

import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.clock import Clock

# NIST FIPS-197 Appendix C Test Vectors
# Test Vector 1
PLAINTEXT_1  = 0x00112233445566778899aabbccddeeff
KEY_1        = 0x000102030405060708090a0b0c0d0e0f
CIPHERTEXT_1 = 0x69c4e0d86a7b0430d8cdb78070b4c55a

# Test Vector 2 (all zeros)
PLAINTEXT_2  = 0x00000000000000000000000000000000
KEY_2        = 0x00000000000000000000000000000000
CIPHERTEXT_2 = 0x66e94bd4ef8a2c3b884cfa59ca342b2e

@cocotb.test()
async def test_aes_encryption_nist_vector_1(dut):
    """Test AES encryption with NIST test vector 1"""
    
    # Create clock
    clock = Clock(dut.clk, 10, units="ns")  # 100MHz clock
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.start.value = 0
    dut.mode.value = 0  # Encrypt mode
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # Load inputs
    dut.plaintext.value = PLAINTEXT_1
    dut.key.value = KEY_1
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    # Wait for encryption to complete
    while dut.done.value == 0:
        await RisingEdge(dut.clk)
    
    # Check output
    actual_ciphertext = dut.ciphertext.value.integer
    assert actual_ciphertext == CIPHERTEXT_1, \
        f"Encryption failed: got 0x{actual_ciphertext:032x}, expected 0x{CIPHERTEXT_1:032x}"
    
    dut._log.info(f"✓ NIST test vector 1 passed")
    dut._log.info(f"  Plaintext:  0x{PLAINTEXT_1:032x}")
    dut._log.info(f"  Key:        0x{KEY_1:032x}")
    dut._log.info(f"  Ciphertext: 0x{actual_ciphertext:032x}")

@cocotb.test()
async def test_aes_encryption_nist_vector_2(dut):
    """Test AES encryption with NIST test vector 2 (all zeros)"""
    
    # Create clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.start.value = 0
    dut.mode.value = 0  # Encrypt mode
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # Load inputs
    dut.plaintext.value = PLAINTEXT_2
    dut.key.value = KEY_2
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    # Wait for encryption to complete
    while dut.done.value == 0:
        await RisingEdge(dut.clk)
    
    # Check output
    actual_ciphertext = dut.ciphertext.value.integer
    assert actual_ciphertext == CIPHERTEXT_2, \
        f"Encryption failed: got 0x{actual_ciphertext:032x}, expected 0x{CIPHERTEXT_2:032x}"
    
    dut._log.info(f"✓ NIST test vector 2 (all zeros) passed")

@cocotb.test()
async def test_aes_timing(dut):
    """Verify AES encryption timing (~24 cycles)"""
    
    # Create clock  
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # Start encryption
    dut.plaintext.value = PLAINTEXT_1
    dut.key.value = KEY_1
    dut.mode.value = 0
    dut.start.value = 1
    
    start_time = cocotb.utils.get_sim_time(units='ns')
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    # Wait for done
    while dut.done.value == 0:
        await RisingEdge(dut.clk)
    
    end_time = cocotb.utils.get_sim_time(units='ns')
    elapsed_cycles = (end_time - start_time) / 10  # 10ns clock period
    
    dut._log.info(f"✓ Encryption completed in {elapsed_cycles:.0f} clock cycles")
    
    # Should be approximately 24 cycles (may vary slightly based on implementation)
    assert 15 <= elapsed_cycles <= 35, \
        f"Timing unexpected: {elapsed_cycles:.0f} cycles (expected ~24)"
TEST_VECTORS = [
    {
        'key': 0x000102030405060708090a0b0c0d0e0f,
        'plaintext': 0x00112233445566778899aabbccddeeff,
        'ciphertext': 0x69c4e0d86a7b0430d8cdb78070b4c55a
    },
    {
        'key': 0x2b7e151628aed2a6abf7158809cf4f3c,
        'plaintext': 0x3243f6a8885a308d313198a2e0370734,
        'ciphertext': 0x3925841d02dc09fbdc118597196a0b32
    }
]

@cocotb.test()
async def test_decrypt_nist_vector_1(dut):
    """Test decryption with NIST test vector 1"""
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.start.value = 0
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # Load test vector 1
    dut.key.value = TEST_VECTORS[0]['key']
    dut.plaintext.value = TEST_VECTORS[0]['ciphertext']  # Input is ciphertext for decryption
    dut.mode.value = 1  # Decrypt mode
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    # Wait for decryption to complete
    timeout = 0
    while dut.done.value == 0:
        await RisingEdge(dut.clk)
        timeout += 1
        if timeout > 100:
            assert False, "Decryption timeout"
    
    # Check result
    result = dut.ciphertext.value.integer
    expected = TEST_VECTORS[0]['plaintext']
    
    dut._log.info(f"Ciphertext: 0x{TEST_VECTORS[0]['ciphertext']:032x}")
    dut._log.info(f"Plaintext:  0x{result:032x}")
    dut._log.info(f"Expected:   0x{expected:032x}")
    
    assert result == expected, \
        f"Decryption failed: got 0x{result:032x}, expected 0x{expected:032x}"
    
    dut._log.info("✓ NIST vector 1 decryption passed")

@cocotb.test()
async def test_decrypt_nist_vector_2(dut):
    """Test decryption with NIST test vector 2"""
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.start.value = 0
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # Load test vector 2
    dut.key.value = TEST_VECTORS[1]['key']
    dut.plaintext.value = TEST_VECTORS[1]['ciphertext']  # Input is ciphertext for decryption
    dut.mode.value = 1  # Decrypt mode
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    # Wait for decryption to complete
    timeout = 0
    while dut.done.value == 0:
        await RisingEdge(dut.clk)
        timeout += 1
        if timeout > 100:
            assert False, "Decryption timeout"
    
    # Check result
    result = dut.ciphertext.value.integer
    expected = TEST_VECTORS[1]['plaintext']
    
    dut._log.info(f"Ciphertext: 0x{TEST_VECTORS[1]['ciphertext']:032x}")
    dut._log.info(f"Plaintext:  0x{result:032x}")
    dut._log.info(f"Expected:   0x{expected:032x}")
    
    assert result == expected, \
        f"Decryption failed: got 0x{result:032x}, expected 0x{expected:032x}"
    
    dut._log.info("✓ NIST vector 2 decryption passed")

@cocotb.test()
async def test_encrypt_decrypt_roundtrip(dut):
    """Test encryption followed by decryption returns original plaintext"""
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.start.value = 0
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    original_plaintext = 0xdeadbeefcafebabe0123456789abcdef
    test_key = TEST_VECTORS[0]['key']
    
    dut._log.info(f"Original plaintext: 0x{original_plaintext:032x}")
    
    # Step 1: Encrypt
    dut.key.value = test_key
    dut.plaintext.value = original_plaintext
    dut.mode.value = 0  # Encrypt mode
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    # Wait for encryption
    timeout = 0
    while dut.done.value == 0:
        await RisingEdge(dut.clk)
        timeout += 1
        if timeout > 100:
            assert False, "Encryption timeout"
    
    ciphertext = dut.ciphertext.value.integer
    dut._log.info(f"Ciphertext:         0x{ciphertext:032x}")
    
    # Wait between operations
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    
    # Step 2: Decrypt
    dut.plaintext.value = ciphertext  # Feed ciphertext as input
    dut.mode.value = 1  # Decrypt mode
    dut.start.value = 1
    await RisingEdge(dut.clk)
    dut.start.value = 0
    
    # Wait for decryption
    timeout = 0
    while dut.done.value == 0:
        await RisingEdge(dut.clk)
        timeout += 1
        if timeout > 100:
            assert False, "Decryption timeout"
    
    decrypted = dut.ciphertext.value.integer
    dut._log.info(f"Decrypted plaintext: 0x{decrypted:032x}")
    
    assert decrypted == original_plaintext, \
        f"Round-trip failed: got 0x{decrypted:032x}, expected 0x{original_plaintext:032x}"
    
    dut._log.info("✓ Encrypt-decrypt round-trip passed")
