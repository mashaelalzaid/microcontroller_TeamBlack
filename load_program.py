import serial
import time

# Set this to True to send LSB first (right to left), or False for MSB first (left to right)
SEND_LSB_FIRST = True  

def read_hex_from_file(file_path):
    """Reads hex instructions from a file and returns a list of bytes (optionally reversed)."""
    instructions = []
    try:
        with open(file_path, 'r') as file:
            for line in file:
                line = line.strip().replace(" ", "").lower()  # Remove spaces and normalize case
                if line.startswith("0x"):  # Remove '0x' prefix if present
                    line = line[2:]
                if line:  # Ensure it's not empty
                    try:
                        byte_data = bytes.fromhex(line.zfill(8))  # Ensure even-length (4-byte instructions)
                        if SEND_LSB_FIRST:
                            byte_data = byte_data[::-1]  # Reverse byte order (LSB first)
                        instructions.append(byte_data)
                    except ValueError:
                        print(f"Skipping invalid hex line: {line}")
    except FileNotFoundError:
        print(f"Error: File '{file_path}' not found.")
    return instructions

def send_instruction(ser, instruction, count, order):
    """Send a single instruction and receive response."""
    ser.reset_input_buffer()
    ser.reset_output_buffer()

    print(f"Sending instruction {count + 1} ({order}):")
    
    for byte in instruction:
        print(f"Sent Byte: {hex(byte)}")  # Print each sent byte
        ser.write(bytes([byte]))  # Send byte-by-byte
        ser.flush()
        time.sleep(0.0)  # Small delay between bytes

    # **Ensure we wait for a response**
    timeout = 10.0  # Maximum wait time in seconds
    start_time = time.time()

    while ser.in_waiting == 0:  # Wait until data is available
        if time.time() - start_time > timeout:
            print("Error: No response received within timeout!")
            return

    # **Receive response byte-by-byte**
    print("Received Bytes:")
    while ser.in_waiting:  # Read byte-by-byte
        received_byte = ser.read(1)  # Read one byte at a time
        print(f"Received Byte: {received_byte.hex()}")  # Print received byte in hex format

def continuous_test(file_path):
    """Reads hex instructions from a file, sends via serial, and receives responses."""
    try:
        ser = serial.Serial('/dev/ttyUSB1', baudrate=9600, timeout=1, stopbits=serial.STOPBITS_ONE, parity=serial.PARITY_EVEN)
        print(f"Connected to {ser.port}")

        # Read instructions from file
        instructions = read_hex_from_file(file_path)
        if not instructions:
            print("No valid hex instructions found in the file.")
            return

        count = 0
        order = "LSB first (Right to Left)" if SEND_LSB_FIRST else "MSB first (Left to Right)"

        # **Send all instructions from file**
        for instruction in instructions:
            send_instruction(ser, instruction, count, order)
            count += 1
            time.sleep(0.0) 

        # **Send 0x00000013 (NOP) until count reaches 512**
        NOP_INSTRUCTION = [0x13, 0x00, 0x00, 0x00]  # 0x00000013 in little-endian format

        while count < 512:
            send_instruction(ser, NOP_INSTRUCTION, count, order)
            count += 1
            time.sleep(0.0)

    except serial.SerialException as e:
        print(f"Error: {e}")
    finally:
        print("Port closed")


if __name__ == "__main__":
    file_path = "Bootmachine.mem"  
    continuous_test(file_path)
