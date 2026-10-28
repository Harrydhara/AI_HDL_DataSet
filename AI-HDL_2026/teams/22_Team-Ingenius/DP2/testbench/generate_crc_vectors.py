import binascii

def crc32_ieee(word):
    # Convert 32-bit word to bytes, little-endian (LSB-first)
    data = word.to_bytes(4, byteorder='little')
    # Start with seed = 0xFFFFFFFF
    crc = binascii.crc32(data, 0xFFFFFFFF) & 0xFFFFFFFF
    # Apply final XOR
    return crc ^ 0xFFFFFFFF

def main():
    test_vectors = [
        0xA5A5A5A5,
        0x5A5A5A5A,
        0x00000000,
        0xFFFFFFFF,
        0x12345678,
        0xDEADBEEF
    ]
    for w in test_vectors:
        print(f"Input {w:08X} -> Expected CRC {crc32_ieee(w):08X}")

if __name__ == "__main__":
    main()
