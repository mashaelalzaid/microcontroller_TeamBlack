import serial
import time
import signal
import sys

# Set this to True to send LSB first (right to left), or False for MSB first (left to right)
SEND_LSB_FIRST = True

# Flag to control listening loop
listening = True

def signal_handler(sig, frame):
    """Handle Ctrl+C to gracefully exit the listening loop"""
    global listening
    print("\nStopping UART listener...")
    listening = False
    sys.exit(0)

# def read_hex_from_file(file_path):
#     """Reads hex instructions from a file and returns a list of bytes (optionally reversed)."""
#     instructions = []
#     number_of_lines = 0
#     try:
#         with open(file_path, 'r') as file:
#             for line_number, line in enumerate(file, start=1):
#                 line = line.strip().replace(" ", "").lower()  # Remove spaces and normalize case
#                 if line.startswith("0x"):  # Remove '0x' prefix if present
#                     line = line[2:]
#                 if line:  # Ensure it's not empty
#                     number_of_lines += 1
#                     try:
#                         byte_data = bytes.fromhex(line.zfill(8))  # Ensure even-length (4-byte instructions)
#                         if SEND_LSB_FIRST:
#                             byte_data = byte_data[::-1]  # Reverse byte order (LSB first)
#                         instructions.append(byte_data)
#                     except ValueError:
#                         print(f"Skipping invalid hex line: {line}")
#     except FileNotFoundError:
#         print(f"Error: File '{file_path}' not found.")
#     return instructions, number_of_lines

def read_hex_from_file(file_path, send_lsb_first=False):
    """
    Reads hex instructions from a file with format like:
    @10000000
    10 00 01 37 FF F1 01 13 00 80 00 EF 00 00 00 6F
    
    Returns a list of bytes and the total number of bytes read.
    """
    instructions = []
    total_bytes = 0
    
    try:
        with open(file_path, 'r') as file:
            file_content = file.read().strip()
            
            # Handle empty file case
            if not file_content:
                return [bytes.fromhex('00') for _ in range(4)], 4
                
            lines = file_content.split('\n')
            skip_first_line = False
            
            for line in lines:
                line = line.strip()
                # Skip empty lines
                if not line:
                    continue
                    
                # Skip the first line that starts with '@'
                if skip_first_line and line.startswith('@'):
                    skip_first_line = False
                    continue
                    
                # Remove any whitespace and process the line
                hex_values = line.split()
                for hex_byte in hex_values:
                    try:
                        # Convert each hex byte string to actual byte
                        byte_data = bytes.fromhex(hex_byte)
                        if send_lsb_first:
                            byte_data = byte_data[::-1]  # Reverse byte order if needed
                        instructions.append(byte_data)
                        total_bytes += 1
                    except ValueError:
                        print(f"Skipping invalid hex byte: {hex_byte}")
                
                skip_first_line = False
                
    except FileNotFoundError:
        print(f"Error: File '{file_path}' not found.")
        # Handle file not found as empty file
        return [bytes.fromhex('00') for _ in range(4)], 0
        
    return instructions, total_bytes

def send_word(ser, word, count, order):
    """Send a single instruction and receive response."""
    ser.reset_input_buffer()
    ser.reset_output_buffer()

    for byte in word:
        print(f"Sent Byte: {hex(byte)}")  # Print each sent byte
        ser.write(bytes([byte]))  # Send byte-by-byte
        ser.flush()

    # Wait for a response
    timeout = 15.0  # Maximum wait time in seconds
    start_time = time.time()

    while ser.in_waiting == 0:  # Wait until data is available
        if time.time() - start_time > timeout:
            print("Error: No response received within timeout!")
            return
    # Receive response byte-by-byte
    print("Received Bytes:")
    while ser.in_waiting:  # Read byte-by-byte
        received_byte = ser.read(1)  # Read one byte at a time
        print(f"Received Byte: {received_byte.hex()}")  # Print received byte in hex format

def continuous_listener(ser):
    """Continuously listen for incoming data on the serial port"""
    print("\n--- Starting continuous UART listener ---")
    print("Press Ctrl+C to stop listening\n")
    
    global listening
    buffer = bytearray()
    
    while listening:
        if ser.in_waiting > 0:
            byte = ser.read(1)
            buffer.append(int.from_bytes(byte, byteorder='big'))
            print(f"Received: 0x{byte.hex()}")
            
            # If we have collected 4 bytes, interpret as a word
            if len(buffer) == 4:
                word_value = int.from_bytes(buffer, byteorder='little' if SEND_LSB_FIRST else 'big')
                print(f"Complete Word: 0x{word_value:08x}")
                buffer.clear()
        else:
            # Small delay to prevent CPU hogging
            time.sleep(0.1)

def continuous_test(ser,file_path,send_hello):
    """Reads hex instructions from a file, sends via serial, and receives responses."""

    # Register signal handler for Ctrl+C
    signal.signal(signal.SIGINT, signal_handler)

    # Read instructions from file
    words, count = read_hex_from_file(file_path)
    if not words:
        print("No valid hex found in the file.")
        return
    
    order = "LSB first (Right to Left)" if SEND_LSB_FIRST else "MSB first (Left to Right)"
    if(send_hello):
        # Send Hello Signal 0xAA and wait for 0x55
        hello = 0xAA
        hello_bytes = hello.to_bytes(4, byteorder='little' if SEND_LSB_FIRST else 'big')
        send_word(ser, hello_bytes, 0, order)
    # Send size of bytes to be sent
    count_bytes = count.to_bytes(4, byteorder='little' if SEND_LSB_FIRST else 'big')
    send_word(ser, count_bytes, 0, order)
    
    # Send all words from file
    for word in words:
        send_word(ser, word, count, order)
    
    # Switch to continuous listening mode
    # continuous_listener(ser)


if __name__ == "__main__":
    try:
        ser = serial.Serial('/dev/ttyUSB1', baudrate=9600, timeout=1, stopbits=serial.STOPBITS_ONE, parity=serial.PARITY_EVEN)
        print(f"Connected to {ser.port}")
        file_path = "C_src/machine_inst.mem"
        continuous_test(ser,file_path,True)
        file_path = "C_src/machine_data.mem"
        continuous_test(ser,file_path,False)
    except serial.SerialException as e:
        print(f"Error: {e}")
    finally:
        if 'ser' in locals() and ser.is_open:
            ser.close()
            print("Port closed")