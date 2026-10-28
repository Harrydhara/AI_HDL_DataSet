#!/usr/bin/env python3
import binascii

def crc32_ieee_for_words(words):
    # Concatenate words as bytes in the same order the DUT shifts them:
    # each 32-bit word -> little-endian bytes (LSB-first)
    data = b''.join(w.to_bytes(4, byteorder='little') for w in words)
    crc = binascii.crc32(data, 0xFFFFFFFF) & 0xFFFFFFFF
    return crc ^ 0xFFFFFFFF

vectors = [
    (0xA5A5A5A5,),
    (0x5A5A5A5A,),
    (0x00000000,),
    (0xFFFFFFFF,),
    (0x12345678,),
    (0xDEADBEEF,)
]

for v in vectors:
    print(f"Input {v[0]:08X} -> CRC {crc32_ieee_for_words(v):08X}")
