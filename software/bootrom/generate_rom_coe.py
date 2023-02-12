import sys
import binascii

def main():
    out_file = open("boot.coe", 'w')
    out_file.write("memory_initialization_radix=16;\n")
    out_file.write("memory_initialization_vector=\n")

    with open(sys.argv[1], 'rb') as f:
        while True:
            word = f.read(4)
            if not word:
                break

            out_file.write(binascii.hexlify(word[::-1]).decode() + ",\n")

if __name__ == '__main__':
    main()
    
