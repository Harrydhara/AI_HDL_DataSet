#include "aes_driver.h"
#include <stdio.h>
#include <string.h>

// NIST test vector (same as your testbench)
const uint8_t test_key[16] = {
    0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6,
    0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c
};

const uint8_t test_plain[16] = {
    0x32, 0x43, 0xf6, 0xa8, 0x88, 0x5a, 0x30, 0x8d,
    0x31, 0x31, 0x98, 0xa2, 0xe0, 0x37, 0x07, 0x34
};

const uint8_t expected_cipher[16] = {
    0x39, 0x25, 0x84, 0x1d, 0x02, 0xdc, 0x09, 0xfb,
    0xdc, 0x11, 0x85, 0x97, 0x19, 0x6a, 0x0b, 0x32
};

int main(void) {
    uint8_t cipher[16];
    uint8_t decrypted[16];
    int i;
    
    printf("AES-128 Hardware Test\n");
    printf("=====================\n\n");
    
    // Test encryption
    printf("Encryption test...\n");
    aes_encrypt(test_key, test_plain, cipher);
    
    printf("Ciphertext: ");
    for (i = 0; i < 16; i++) {
        printf("%02x", cipher[i]);
    }
    printf("\n");
    
    if (memcmp(cipher, expected_cipher, 16) == 0) {
        printf("✓ Encryption PASSED\n\n");
    } else {
        printf("✗ Encryption FAILED\n\n");
        return 1;
    }
    
    // Test decryption
    printf("Decryption test...\n");
    aes_decrypt(test_key, cipher, decrypted);
    
    printf("Decrypted:  ");
    for (i = 0; i < 16; i++) {
        printf("%02x", decrypted[i]);
    }
    printf("\n");
    
    if (memcmp(decrypted, test_plain, 16) == 0) {
        printf("✓ Decryption PASSED\n\n");
    } else {
        printf("✗ Decryption FAILED\n\n");
        return 1;
    }
    
    printf("All tests PASSED!\n");
    return 0;
}
