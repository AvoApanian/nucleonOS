BUILD_DIR = runable

CXXFLAGS = -m64 -ffreestanding -fno-pic -mno-red-zone -fno-stack-protector -O2 -Wall -Wextra
LDFLAGS  = -T kernel/linker.ld -nostdlib

# Cherche tous les .cpp
CPP_FILES := $(shell find kernel -name "*.cpp")

# Place les .o dans runable en gardant l'arborescence
OBJ_FILES := $(CPP_FILES:%.cpp=$(BUILD_DIR)/%.o)


all: os.img


# Crée les dossiers automatiquement
$(BUILD_DIR)/%.o: %.cpp
	mkdir -p $(dir $@)
	g++ $(CXXFLAGS) -c $< -o $@


# Assembleur kernel
$(BUILD_DIR)/kernel/start.o: kernel/start.asm
	mkdir -p $(dir $@)
	nasm -f elf64 $< -o $@


# Link kernel
$(BUILD_DIR)/kernel/kernel.elf: $(BUILD_DIR)/kernel/start.o $(OBJ_FILES) kernel/linker.ld
	ld $(LDFLAGS) -o $@ $(BUILD_DIR)/kernel/start.o $(OBJ_FILES)


# Kernel binary
$(BUILD_DIR)/kernel/kernel.bin: $(BUILD_DIR)/kernel/kernel.elf
	objcopy -O binary $< $@



# Stage2
$(BUILD_DIR)/bootloader/stage2.bin: bootloader/stage2.asm
	mkdir -p $(dir $@)
	nasm -f bin $< -o $@


# Génération config
$(BUILD_DIR)/bootloader/config.inc: $(BUILD_DIR)/bootloader/stage2.bin $(BUILD_DIR)/kernel/kernel.bin
	@STAGE2_SIZE=$$(stat -c%s $(BUILD_DIR)/bootloader/stage2.bin); \
	STAGE2_SECTORS=$$(( (STAGE2_SIZE + 511) / 512 )); \
	KERNEL_SIZE=$$(stat -c%s $(BUILD_DIR)/kernel/kernel.bin); \
	KERNEL_SECTORS=$$(( (KERNEL_SIZE + 511) / 512 )); \
	KERNEL_LBA=$$(( 1 + STAGE2_SECTORS )); \
	echo "STAGE2_SECTORS equ $$STAGE2_SECTORS" > $@; \
	echo "KERNEL_SECTORS equ $$KERNEL_SECTORS" >> $@; \
	echo "KERNEL_LBA     equ $$KERNEL_LBA" >> $@; \
	truncate -s $$(( STAGE2_SECTORS * 512 )) $(BUILD_DIR)/bootloader/stage2.bin


# Boot
$(BUILD_DIR)/bootloader/boot.bin: bootloader/boot.asm $(BUILD_DIR)/bootloader/config.inc
	mkdir -p $(dir $@)
	nasm -f bin -I $(BUILD_DIR)/bootloader/ bootloader/boot.asm -o $@



# Image finale
os.img: $(BUILD_DIR)/bootloader/boot.bin $(BUILD_DIR)/bootloader/stage2.bin $(BUILD_DIR)/kernel/kernel.bin
	cat $^ > $(BUILD_DIR)/os.img



clean:
	rm -rf $(BUILD_DIR)


.PHONY: all clean
