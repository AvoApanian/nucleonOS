CXXFLAGS = -m64 -ffreestanding -fno-pic -mno-red-zone -O2 -Wall -Wextra
LDFLAGS  = -T kernel/linker.ld -nostdlib

all: os.img

# --- Kernel ---
kernel/start.o: kernel/start.asm
	nasm -f elf64 $< -o $@

kernel/main.o: kernel/main.cpp
	g++ $(CXXFLAGS) -c $< -o $@

kernel/kernel.elf: kernel/start.o kernel/main.o kernel/linker.ld
	ld $(LDFLAGS) -o $@ kernel/start.o kernel/main.o

kernel/kernel.bin: kernel/kernel.elf
	objcopy -O binary $< $@

# --- Stage2 ---
bootloader/stage2.bin: bootloader/stage2.asm
	nasm -f bin $< -o $@

# --- Génération config.inc à partir des tailles réelles ---
bootloader/config.inc: bootloader/stage2.bin kernel/kernel.bin
	@STAGE2_SIZE=$$(stat -c%s bootloader/stage2.bin); \
	STAGE2_SECTORS=$$(( (STAGE2_SIZE + 511) / 512 )); \
	KERNEL_SIZE=$$(stat -c%s kernel/kernel.bin); \
	KERNEL_SECTORS=$$(( (KERNEL_SIZE + 511) / 512 )); \
	KERNEL_LBA=$$(( 1 + STAGE2_SECTORS )); \
	echo "STAGE2_SECTORS equ $$STAGE2_SECTORS" > bootloader/config.inc; \
	echo "KERNEL_SECTORS equ $$KERNEL_SECTORS" >> bootloader/config.inc; \
	echo "KERNEL_LBA     equ $$KERNEL_LBA" >> bootloader/config.inc; \
	truncate -s $$(( STAGE2_SECTORS * 512 )) bootloader/stage2.bin

# --- Bootloader (dépend de config.inc) ---
bootloader/boot.bin: bootloader/boot.asm bootloader/config.inc
	nasm -f bin -I bootloader/ bootloader/boot.asm -o bootloader/boot.bin

# --- Image finale ---
os.img: bootloader/boot.bin bootloader/stage2.bin kernel/kernel.bin
	cat bootloader/boot.bin bootloader/stage2.bin kernel/kernel.bin > os.img

clean:
	rm -f kernel/*.o kernel/kernel.elf kernel/kernel.bin \
	      bootloader/stage2.bin bootloader/boot.bin bootloader/config.inc os.img

.PHONY: all clean
