"""
AES S-Box (SubBytes) Transformation Tests
Tests the forward and inverse S-Box lookup tables with known test vectors
"""

import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock

# Known S-Box test vectors from NIST FIPS-197
# Format: (input_byte, S-Box[input], InvS-Box[input])
SBOX_TEST_VECTORS = [
    (0x00, 0x63, 0x52),  # S-Box[0x00]=0x63, InvS-Box[0x00]=0x52
    (0x01, 0x7c, 0x09),  # S-Box[0x01]=0x7c, InvS-Box[0x01]=0x09
    (0x52, 0x00, 0x48),  # S-Box[0x52]=0x00, InvS-Box[0x52]=0x48
    (0x63, 0xfb, 0x00),  # S-Box[0x63]=0xfb, InvS-Box[0x63]=0x00
    (0x19, 0xd4, 0xd4),  # S-Box[0x19]=0xd4, InvS-Box[0x19]=0xd4
    (0xab, 0x62, 0xaa),  # S-Box[0xab]=0x62, InvS-Box[0xab]=0x0e
    (0xff, 0x16, 0x7d),  # S-Box[0xff]=0x16, InvS-Box[0xff]=0x7d
]

@cocotb.test()
async def test_sbox_forward(dut):
    """Test forward S-Box substitution"""
    
    # Set inverse mode to 0 (forward S-Box)
    dut.inverse.value = 0
    
    for test_input, expected_output, _ in SBOX_TEST_VECTORS:
        dut.data_in.value = test_input
        await Timer(1, units="ns")  # Combinational logic settling time
        
        actual_output = dut.data_out.value.integer
        assert actual_output == expected_output, \
            f"Forward S-Box failed: S-Box[0x{test_input:02x}] = 0x{actual_output:02x}, expected 0x{expected_output:02x}"
    
    dut._log.info("✓ All forward S-Box tests passed")

@cocotb.test()
async def test_sbox_inverse(dut):
    """Test inverse S-Box substitution using invertibility"""
    
    # Test that InvS-Box[S-Box[x]] = x for sample values
    test_values = [0x00, 0x01, 0x19, 0x52, 0x63, 0xab, 0xff]
    
    for test_val in test_values:
        # Forward: get S-Box[test_val]
        dut.inverse.value = 0
        dut.data_in.value = test_val
        await Timer(1, units="ns")
        sbox_result = dut.data_out.value.integer
        
        # Inverse: InvS-Box[S-Box[test_val]] should equal test_val
        dut.inverse.value = 1
        dut.data_in.value = sbox_result
        await Timer(1, units="ns")
        inv_sbox_result = dut.data_out.value.integer
        
        assert inv_sbox_result == test_val, \
            f"Inverse S-Box property failed: InvS-Box[S-Box[0x{test_val:02x}]] = 0x{inv_sbox_result:02x}, expected 0x{test_val:02x}"
    
    dut._log.info("✓ All inverse S-Box tests passed")

@cocotb.test()
async def test_sbox_invertibility(dut):
    """Test that S-Box and InvS-Box are true inverses"""
    
    # Test a representative sample of bytes
    test_bytes = [0x00, 0x01, 0x19, 0x53, 0x63, 0xab, 0xcd, 0xff]
    
    for test_byte in test_bytes:
        # Forward transformation
        dut.inverse.value = 0
        dut.data_in.value = test_byte
        await Timer(1, units="ns")
        forward_result = dut.data_out.value.integer
        
        # Inverse transformation of forward result
        dut.inverse.value = 1
        dut.data_in.value = forward_result
        await Timer(1, units="ns")
        inverse_result = dut.data_out.value.integer
        
        assert inverse_result == test_byte, \
            f"Invertibility failed: 0x{test_byte:02x} -> 0x{forward_result:02x} -> 0x{inverse_result:02x}"
    
    dut._log.info("✓ S-Box invertibility verified")
