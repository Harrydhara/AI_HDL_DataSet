//============================================================================
// AES-128 Hardware Accelerator Driver
//============================================================================

#ifndef AES_DRIVER_H
#define AES_DRIVER_H

#include <stdint.h>

// Base address
#define AES_BASE 0x80001000

// Register offsets
#define AES_CTRL     (*(volatile uint32_t*)(AES_BASE + 0x00))
#define AES_STATUS   (*(volatile uint32_t*)(AES_BASE + 0x04))
#define AES_INT_EN   (*(volatile uint32_t*)(AES_BASE + 0x08))
#define AES_INT_STAT (*(volatile uint32_t*)(AES_BASE + 0x0C))
#define AES_KEY0     (*(volatile uint32_t*)(AES_BASE + 0x10))
#define AES_KEY1     (*(volatile uint32_t*)(AES_BASE + 0x14))
#define AES_KEY2     (*(volatile uint32_t*)(AES_BASE + 0x18))
#define AES_KEY3     (*(volatile uint32_t*)(AES_BASE + 0x1C))
#define AES_DIN0     (*(volatile uint32_t*)(AES_BASE + 0x20))
#define AES_DIN1     (*(volatile uint32_t*)(AES_BASE + 0x24))
#define AES_DIN2     (*(volatile uint32_t*)(AES_BASE + 0x28))
#define AES_DIN3     (*(volatile uint32_t*)(AES_BASE + 0x2C))
#define AES_DOUT0    (*(volatile uint32_t*)(AES_BASE + 0x30))
#define AES_DOUT1    (*(volatile uint32_t*)(AES_BASE + 0x34))
#define AES_DOUT2    (*(volatile uint32_t*)(AES_BASE + 0x38))
#define AES_DOUT3    (*(volatile uint32_t*)(AES_BASE + 0x3C))

// Control register bits
#define AES_CTRL_START   (1 << 0)
#define AES_CTRL_DECRYPT (1 << 1)

// Status register bits
#define AES_STATUS_BUSY  (1 << 0)
#define AES_STATUS_DONE  (1 << 1)

/**
 * @brief Load 128-bit key into AES accelerator
 * @param key Pointer to 16-byte key (big-endian)
 */
static inline void aes_load_key(const uint8_t *key) {
    AES_KEY0 = (key[0] << 24) | (key[1] << 16) | (key[2] << 8) | key[3];
    AES_KEY1 = (key[4] << 24) | (key[5] << 16) | (key[6] << 8) | key[7];
    AES_KEY2 = (key[8] << 24) | (key[9] << 16) | (key[10] << 8) | key[11];
    AES_KEY3 = (key[12] << 24) | (key[13] << 16) | (key[14] << 8) | key[15];
}

/**
 * @brief Load 128-bit plaintext/ciphertext
 * @param data Pointer to 16-byte data (big-endian)
 */
static inline void aes_load_data(const uint8_t *data) {
    AES_DIN0 = (data[0] << 24) | (data[1] << 16) | (data[2] << 8) | data[3];
    AES_DIN1 = (data[4] << 24) | (data[5] << 16) | (data[6] << 8) | data[7];
    AES_DIN2 = (data[8] << 24) | (data[9] << 16) | (data[10] << 8) | data[11];
    AES_DIN3 = (data[12] << 24) | (data[13] << 16) | (data[14] << 8) | data[15];
}

/**
 * @brief Read 128-bit result
 * @param data Pointer to 16-byte output buffer (big-endian)
 */
static inline void aes_read_result(uint8_t *data) {
    uint32_t word;
    
    word = AES_DOUT0;
    data[0] = (word >> 24) & 0xFF;
    data[1] = (word >> 16) & 0xFF;
    data[2] = (word >> 8) & 0xFF;
    data[3] = word & 0xFF;
    
    word = AES_DOUT1;
    data[4] = (word >> 24) & 0xFF;
    data[5] = (word >> 16) & 0xFF;
    data[6] = (word >> 8) & 0xFF;
    data[7] = word & 0xFF;
    
    word = AES_DOUT2;
    data[8] = (word >> 24) & 0xFF;
    data[9] = (word >> 16) & 0xFF;
    data[10] = (word >> 8) & 0xFF;
    data[11] = word & 0xFF;
    
    word = AES_DOUT3;
    data[12] = (word >> 24) & 0xFF;
    data[13] = (word >> 16) & 0xFF;
    data[14] = (word >> 8) & 0xFF;
    data[15] = word & 0xFF;
}

/**
 * @brief Wait for operation to complete (polling)
 */
static inline void aes_wait_done(void) {
    while (!(AES_STATUS & AES_STATUS_DONE));
}

/**
 * @brief Encrypt 128-bit block
 * @param key 16-byte encryption key
 * @param plaintext 16-byte input
 * @param ciphertext 16-byte output
 */
void aes_encrypt(const uint8_t *key, const uint8_t *plaintext, uint8_t *ciphertext) {
    // Load key and data
    aes_load_key(key);
    aes_load_data(plaintext);
    
    // Start encryption (CTRL[1:0] = 01)
    AES_CTRL = AES_CTRL_START;
    
    // Wait for completion
    aes_wait_done();
    
    // Read result
    aes_read_result(ciphertext);
}

/**
 * @brief Decrypt 128-bit block
 * @param key 16-byte decryption key
 * @param ciphertext 16-byte input
 * @param plaintext 16-byte output
 */
void aes_decrypt(const uint8_t *key, const uint8_t *ciphertext, uint8_t *plaintext) {
    // Load key and data
    aes_load_key(key);
    aes_load_data(ciphertext);
    
    // Start decryption (CTRL[1:0] = 11)
    AES_CTRL = AES_CTRL_START | AES_CTRL_DECRYPT;
    
    // Wait for completion
    aes_wait_done();
    
    // Read result
    aes_read_result(plaintext);
}

#endif // AES_DRIVER_H
