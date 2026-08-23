BUILD_DIR = runable

CXXFLAGS = -m32 -ffreestanding -fno-pic -fno-stack-protector -mno-sse -mno-sse2 -mno-mmx -mno-80387 -O2 -Wall -Wextra
LDFLAGS  = -m elf_i386 -T BIOS/kernel/linker.ld -nostdlib

OVMF_CODE = /usr/share/edk2/x64/OVMF_CODE.4m.fd
OVMF_VARS = /usr/share/edk2/x64/OVMF_VARS.4m.fd

ESP_IMG = $(BUILD_DIR)/UEFIRun/esp.img

CPP_FILES := $(shell find BIOS/kernel -name "*.cpp")
OBJ_FILES := $(CPP_FILES:%.cpp=$(BUILD_DIR)/%.o)

VGA_OBJ = runable/BIOS/driver/vga/vga.o
STRING_OBJ = runable/BIOS/driver/string/string.o

.PHONY: all bios uefi clean run-bios run-uefi

all: bios

# ========== BIOS ==========
bios: $(BUILD_DIR)/BIOSRun/os.img

$(BUILD_DIR)/%.o: %.cpp
	mkdir -p $(dir $@)
	g++ $(CXXFLAGS) -c $< -o $@

$(BUILD_DIR)/BIOS/kernel/start.o: BIOS/kernel/start.asm
	mkdir -p $(dir $@)
	nasm -f elf32 $< -o $@

runable/BIOS/driver/vga/vga.o:
	mkdir -p runable/BIOS/driver/vga/
	g++ $(CXXFLAGS) -c BIOS/driver/vga/vga.cpp -o runable/BIOS/driver/vga/vga.o

runable/BIOS/driver/string/string.o:
	mkdir -p runable/BIOS/driver/string/
	g++ $(CXXFLAGS) -c BIOS/driver/string/string.cpp -o runable/BIOS/driver/string/string.o

$(BUILD_DIR)/BIOS/kernel/kernel.elf: $(BUILD_DIR)/BIOS/kernel/start.o $(OBJ_FILES) $(VGA_OBJ) $(STRING_OBJ) BIOS/kernel/linker.ld
	ld $(LDFLAGS) -o $@ $(BUILD_DIR)/BIOS/kernel/start.o $(OBJ_FILES) $(VGA_OBJ) $(STRING_OBJ)

$(BUILD_DIR)/BIOS/kernel/kernel.bin: $(BUILD_DIR)/BIOS/kernel/kernel.elf
	objcopy -O binary $< $@

$(BUILD_DIR)/BIOS/stage2.bin: BIOS/bootloader/stage2.asm
	mkdir -p $(dir $@)
	nasm -f bin $< -o $@

$(BUILD_DIR)/BIOS/config.inc: $(BUILD_DIR)/BIOS/stage2.bin $(BUILD_DIR)/BIOS/kernel/kernel.bin
	@STAGE2_SIZE=$$(stat -c%s $(BUILD_DIR)/BIOS/stage2.bin); \
	STAGE2_SECTORS=$$(( (STAGE2_SIZE + 511) / 512 )); \
	KERNEL_SIZE=$$(stat -c%s $(BUILD_DIR)/BIOS/kernel/kernel.bin); \
	KERNEL_SECTORS=$$(( (KERNEL_SIZE + 511) / 512 )); \
	KERNEL_LBA=$$(( 1 + STAGE2_SECTORS )); \
	echo "STAGE2_SECTORS equ $$STAGE2_SECTORS" > $@; \
	echo "KERNEL_SECTORS equ $$KERNEL_SECTORS" >> $@; \
	echo "KERNEL_LBA     equ $$KERNEL_LBA" >> $@; \
	truncate -s $$(( STAGE2_SECTORS * 512 )) $(BUILD_DIR)/BIOS/stage2.bin

$(BUILD_DIR)/BIOS/boot.bin: BIOS/bootloader/boot.asm $(BUILD_DIR)/BIOS/config.inc
	mkdir -p $(dir $@)
	nasm -f bin -I $(BUILD_DIR)/BIOS/ BIOS/bootloader/boot.asm -o $@

$(BUILD_DIR)/BIOSRun/os.img: $(BUILD_DIR)/BIOS/boot.bin $(BUILD_DIR)/BIOS/stage2.bin $(BUILD_DIR)/BIOS/kernel/kernel.bin
	mkdir -p $(dir $@)
	cat $^ > $@

run-bios: bios
	qemu-system-x86_64 -drive file=$(BUILD_DIR)/BIOSRun/os.img,format=raw

# ========== UEFI ==========
uefi: $(BUILD_DIR)/UEFIRun/BOOTX64.EFI

$(BUILD_DIR)/UEFI/bootx64.o: UEFI/bootloader/bootx64.asm
	mkdir -p $(dir $@)
	nasm -f win64 $< -o $@

$(BUILD_DIR)/UEFIRun/BOOTX64.EFI: $(BUILD_DIR)/UEFI/bootx64.o UEFI/bootloader/linker.ls
	mkdir -p $(dir $@)
	ld -m i386pep \
	  --image-base 0x140000000 \
	  --section-alignment 0x1000 \
	  --file-alignment 0x200 \
	  -T UEFI/bootloader/linker.ls \
	  -subsystem 10 \
	  -e efiMain \
	  -o $@ \
	  $(BUILD_DIR)/UEFI/bootx64.o

# Image FAT32 reelle, remplie via mtools (pas de sudo, pas de mount)
$(ESP_IMG): $(BUILD_DIR)/UEFIRun/BOOTX64.EFI
	mkdir -p $(dir $@)
	dd if=/dev/zero of=$@ bs=1M count=64
	mkfs.fat -F32 $@
	mmd -i $@ ::EFI
	mmd -i $@ ::EFI/BOOT
	mcopy -i $@ $(BUILD_DIR)/UEFIRun/BOOTX64.EFI ::EFI/BOOT/BOOTX64.EFI

run-uefi: uefi $(ESP_IMG)
	@if [ ! -f $(BUILD_DIR)/UEFIRun/OVMF_VARS.fd ]; then \
		cp $(OVMF_VARS) $(BUILD_DIR)/UEFIRun/OVMF_VARS.fd; \
	fi
	qemu-system-x86_64 \
		-drive format=raw,file=$(ESP_IMG) \
		-drive if=pflash,format=raw,readonly=on,file=$(OVMF_CODE) \
		-drive if=pflash,format=raw,file=$(BUILD_DIR)/UEFIRun/OVMF_VARS.fd \
		-boot menu=off

clean:
	rm -rf $(BUILD_DIR)
