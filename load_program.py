import serial
import os
import sys
import time

def send_uart(inst, data):
    # Open the serial port
    ser = serial.Serial('/dev/ttyUSB1', baudrate=9600, timeout=1, stopbits=serial.STOPBITS_ONE, parity=serial.PARITY_EVEN)
    try:
        # Send handshake byte
        ser.write(b'\xAA') # Single byte handshake
        response = ser.read(1) # Wait for acknowledgment
        time.sleep(0.1)
        print(f"Received handshake response: {response.hex()}") # Print the received handshake response
        
        for filename in [inst, data]:
            with open(filename, 'r') as file:
                lines = file.readlines()
                # Ignore the first line
                data_lines = lines[1:]
                # Convert data to bytes
                data_bytes = bytearray()
                for line in data_lines:
                    bytes_str = line.strip().split()
                    for byte_str in bytes_str:
                        data_bytes.append(int(byte_str, 16))
                
                # Send file size byte by byte
                file_size = len(data_bytes)
                size_bytes = file_size.to_bytes(4, 'big')
                
                # Send each byte of the size separately and print result
                print(f"Sending file size: {file_size} ({size_bytes.hex()})")
                for i in range(4):
                    ser.write(bytes([size_bytes[i]]))
                    # response = ser.read(1) # Receive echo
                    # print(f"Sent byte: {hex(size_bytes[i])} | Received echo: {response.hex()}")
                
                # Send file data byte by byte with the same structure
                print(f"Sending file data ({len(data_bytes)} bytes)")
                for i, byte in enumerate(data_bytes):
                    ser.write(bytes([byte])) # Send one byte
                    # response = ser.read(1) # Receive echo
                    # print(f"Sent byte {i+1}/{len(data_bytes)}: {hex(byte)} | Received echo: {response.hex()}")
                    
                print(f"File {filename} sent successfully.")
                
        print("Both files sent successfully.")
        
    except Exception as e:
        print(f"Error: {e}")
    finally:
        ser.close()

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 load_program.py <inst.mem> <data.mem>")
        sys.exit(1)
    
    send_uart(sys.argv[1], sys.argv[2])