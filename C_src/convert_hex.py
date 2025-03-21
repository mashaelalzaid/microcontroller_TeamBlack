import sys
import argparse

def convert_to_little_endian(hex_string):
    """Converts a hex string to little-endian format."""
    hex_string = hex_string.replace(" ", "").upper()  # Remove spaces and ensure uppercase
    
    # Process 4 bytes (8 hex characters) at a time
    results = []
    for i in range(0, len(hex_string), 8):
        word = hex_string[i:i+8]
        if len(word) == 8:
            # Convert to little-endian format (reverse byte order)
            little_endian_word = "0x" + word[6:8] + word[4:6] + word[2:4] + word[0:2]
            results.append(little_endian_word)
    
    return results

def main():
    # Set up command line argument parsing
    parser = argparse.ArgumentParser(description='Convert hex strings to little-endian format')
    parser.add_argument('input_file', help='Path to input file')
    parser.add_argument('output_file', help='Path to output file')
    args = parser.parse_args()
    
    try:
        with open(args.input_file, 'r') as infile, open(args.output_file, 'w') as outfile:
            for line in infile:
                line = line.strip()
                if not line:  # Skip empty lines
                    continue
                if line.startswith("@"):  # Skip lines starting with '@'
                    continue
                
                results = convert_to_little_endian(line)
                for result in results:
                    outfile.write(result + '\n')
        
        print(f"Conversion complete. Results written to {args.output_file}")
    
    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"An error occurred: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()