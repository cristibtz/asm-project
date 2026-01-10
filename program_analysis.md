# Assembly Program Analysis: XOR File Encryptor

## Overview
This is an x86 assembly program written for EMU8086 that implements a simple XOR-based file encryption/decryption utility. It reads a file, XORs its contents with a repeating password key, displays the result, and saves it to a new file with a `.xored` extension.

## Program Flow

### 1. Command Line Argument Parsing
The program expects two command-line arguments:
```
program filename password
```

**Process:**
- Reads command line starting at memory address `81h`
- Command line length stored at `80h`
- Validates that arguments exist, otherwise shows usage instructions
- Skips leading spaces before each argument

### 2. Filename Extraction
- Copies the first argument (filename) to the `filename` buffer
- Maximum filename length: 12 characters (8.3 DOS filename format)
- Stops at space, carriage return (0Dh), or max length
- Null-terminates the filename string

### 3. Password Extraction
- Skips spaces after filename
- Copies the second argument (password) to the `password` buffer
- Maximum password length: 20 characters
- Stores actual password length in `pass_len` variable
- Null-terminates (implied by the parsing logic)

### 4. Output Filename Generation
The `create_output_name` routine:
- Copies input filename to `out_filename` buffer
- Appends `.xored` extension
- Example: `test.txt` → `test.txt.xored`

### 5. File Reading
- Opens the input file in read-only mode (DOS interrupt 21h, function 3Dh)
- Reads up to 128 bytes into the `buffer` (DOS interrupt 21h, function 3Fh)
- Stores actual bytes read in `bytes_read`
- **Limitation:** Only processes first 128 bytes of the file

### 6. XOR Encryption
The core encryption logic in `print_n_xor_loop`:

```
For each byte in buffer:
    1. Load byte from buffer
    2. XOR with current password character
    3. Advance password index
    4. If password index reaches end, reset to 0 (repeating key)
    5. Display XORed character to screen
    6. Store XORed byte back to buffer
```

**Key characteristics:**
- Uses repeating-key XOR cipher
- Password wraps around if text is longer than password
- Validates that password length ≤ file length

### 7. Output File Creation
- Creates new file with the `.xored` extension (DOS interrupt 21h, function 3Ch)
- Writes all XORed bytes from buffer (DOS interrupt 21h, function 40h)
- Closes both input and output files (DOS interrupt 21h, function 3Eh)

## Data Structures

| Variable | Size | Purpose |
|----------|------|---------|
| `filename` | 80 bytes | Input filename buffer |
| `out_filename` | 90 bytes | Output filename buffer |
| `handle` | 2 bytes (word) | Input file handle |
| `out_handle` | 2 bytes (word) | Output file handle |
| `buffer` | 128 bytes | File content buffer |
| `bytes_read` | 2 bytes (word) | Number of bytes actually read |
| `password` | 20 bytes | Password buffer |
| `pass_len` | 2 bytes (word) | Actual password length |

## Error Handling

The program handles several error conditions:

1. **No arguments:** Shows usage instructions
2. **File open failure:** "Error: couldnt open file"
3. **File read failure:** "Error: cant read file"
4. **Password too long:** "Text cant be shorter than password"
5. **Output file creation failure:** "Failed to create output file"
6. **Write failure:** "Failed to write to output file"

## Key Features

### Strengths
1. ✓ Proper command-line argument parsing
2. ✓ Handles spaces in arguments correctly
3. ✓ Error handling for file operations
4. ✓ Debug output showing parsed filename and password
5. ✓ Repeating-key XOR (standard Vigenère cipher approach)

### Limitations
1. ✗ **128-byte file size limit** - only processes first 128 bytes
2. ✗ Password length must be ≤ file length
3. ✗ Filename limited to 12 characters (8.3 format)
4. ✗ Password limited to 20 characters
5. ✗ No verification of successful file operations in some cases
6. ✗ XOR encryption is cryptographically weak

## Security Considerations

⚠️ **This is NOT secure encryption:**
- XOR cipher with repeating key is vulnerable to frequency analysis
- No authentication or integrity checking
- Prone to known-plaintext attacks
- Suitable only for educational purposes or basic obfuscation

## Usage Example

```bash
# Encrypt a file
program test.txt mypassword

# Output: Creates test.txt.xored
# The program displays the encrypted content on screen

# To decrypt, run again on the encrypted file
program test.txt.xored mypassword
# Output: Creates test.txt.xored.xored with original content
```

**Note:** XOR encryption is symmetric - running the same operation twice restores the original data.

## DOS Interrupts Used

| Interrupt | Function | Purpose |
|-----------|----------|---------|
| INT 21h, AH=3Dh | Open file | Opens file for reading |
| INT 21h, AH=3Fh | Read file | Reads bytes from file |
| INT 21h, AH=3Ch | Create file | Creates new file |
| INT 21h, AH=40h | Write file | Writes bytes to file |
| INT 21h, AH=3Eh | Close file | Closes file handle |

## Potential Improvements

1. Process files larger than 128 bytes (read in chunks)
2. Remove password length restriction
3. Add file size validation before processing
4. Implement progress indicator for large files
5. Add option to overwrite vs. create new file
6. Use stronger encryption algorithm
7. Add file integrity checking (checksums)
