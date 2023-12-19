default: build/brasm

build/:
	mkdir -p build/

build/brasm.o: build/ brasm.asm
	nasm -f elf64 brasm.asm -o build/brasm.o

build/brasm: build/brasm.o
	ld -m elf_x86_64 -s -nostdlib -N build/brasm.o -o build/brasm

.PHONY: clean
clean:
	rm -rf build
