#!/usr/bin/env python3

def insert_instruction(input_file, output_file):
    """
    Read lines from input_file, and write to output_file with 0x00000013 inserted after each line.
    Handles the case where input_file and output_file are the same.
    
    Args:
        input_file (str): Path to the input file
        output_file (str): Path to the output file
    """
    # First read all lines from the input file
    with open(input_file, 'r') as f_in:
        lines = f_in.readlines()
    
    # Process the lines in memory
    processed_lines = []
    for line in lines:
        # Add the original line (stripped of trailing whitespace)
        processed_lines.append(line.rstrip())
        # Add the insertion
        processed_lines.append('0x00000013')
        processed_lines.append('0x00000013')
        processed_lines.append('0x00000013')
    
    # Write the processed lines to the output file
    with open(output_file, 'w') as f_out:
        for line in processed_lines:
            f_out.write(line + '\n')

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} input_file output_file")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    insert_instruction(input_file, output_file)
    print(f"Processed {input_file} and saved result to {output_file}")
