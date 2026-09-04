#include "vga.hpp"

#define VGA_COLS 80
#define VGA_ROWS 25

#define VGA_HEADER_ROWS 7
#define VGA_LOG_ROWS (VGA_ROWS - VGA_HEADER_ROWS)

#define LOG_LINES 500

struct VgaCell
{
	char ch;
	uint8_t color;
};

static volatile uint16_t* video =
	(volatile uint16_t*)0xB8000;

static VgaCell logBuffer[
	LOG_LINES
][
	VGA_COLS
];

static uint16_t cursorX = 0;

static uint32_t cursorY = 0;

static uint32_t totalLines = 1;

static uint32_t viewOffset = 0;

static const char* header[] =
{
	"        _   _            _                    ___   ____  ",
	"       | \\ | |          | |                  / _ \\ / ___| ",
	"       |  \\| |_   _  ___| | ___  ___  _ __  | | | |\\___ \\ ",
	"       | |\\  | | | |/ __| |/ _ \\/ _ \\| '_ \\ | | | | ___) |",
	"       | | \\ | |_| | (__| |  __/ (_) | | | || |_| |/____/ ",
	"       |_|  \\|\\__,_|\\___|_|\\___|\\___/|_| |_| \\___/        ",
};

static void vgaDrawHeader()
{
	for(uint32_t row = 0;
	    row < VGA_HEADER_ROWS;
	    row++){

		for(uint32_t col = 0;
		    col < VGA_COLS;
		    col++){

			video[
				row * VGA_COLS + col
			] =
				((uint16_t)0x01 << 8) |
				(uint8_t)' ';
		}
	}

	for(uint32_t row = 0;
	    row < 6;
	    row++){

		const char* text =
			header[row];

		uint32_t length = 0;

		while(text[length] != '\0'){

			length++;
		}

		uint32_t start = 0;

		if(length < VGA_COLS){

			start =
				(VGA_COLS - length) / 2;
		}

		uint8_t color = 0x0B;

		for(uint32_t col = 0;
		    col < length && col < VGA_COLS;
		    col++){

			video[
				row * VGA_COLS
				+ start
				+ col
			] =
				((uint16_t)color << 8) |
				(uint8_t)text[col];
		}
	}

	for(uint32_t col = 0;
	    col < VGA_COLS;
	    col++){

		video[
			6 * VGA_COLS + col
		] =
			((uint16_t)0x03 << 8) |
			(uint8_t)'-';
	}
}

static void vgaClearLine(
	uint32_t logicalLine
)
{
	VgaCell* line =
		logBuffer[
			logicalLine % LOG_LINES
		];

	for(uint32_t i = 0;
	    i < VGA_COLS;
	    i++){

		line[i].ch = ' ';
		line[i].color = 0x0F;
	}
}

static void vgaFollowBottom()
{
	if(totalLines > VGA_LOG_ROWS){

		viewOffset =
			totalLines - VGA_LOG_ROWS;
	}
	else{

		viewOffset = 0;
	}
}

void vgaRender()
{
	vgaDrawHeader();

	for(uint32_t row = 0;
	    row < VGA_LOG_ROWS;
	    row++){

		uint32_t logicalLine =
			viewOffset + row;

		bool exists =
			(logicalLine < totalLines) &&
			(
				totalLines <= LOG_LINES ||
				logicalLine >=
					totalLines - LOG_LINES
			);

		for(uint32_t col = 0;
		    col < VGA_COLS;
		    col++){

			char ch = ' ';
			uint8_t color = 0x0F;

			if(exists){

				VgaCell cell =
					logBuffer[
						logicalLine % LOG_LINES
					][col];

				ch = cell.ch;
				color = cell.color;
			}

			video[
				(row + VGA_HEADER_ROWS)
				* VGA_COLS
				+ col
			] =
				((uint16_t)color << 8) |
				(uint8_t)ch;
		}
	}
}

void vgaScrollView(
	int8_t direction
)
{
	uint32_t minOffset =
		(totalLines > LOG_LINES)
			? totalLines - LOG_LINES
			: 0;

	uint32_t maxOffset =
		(totalLines > VGA_LOG_ROWS)
			? totalLines - VGA_LOG_ROWS
			: 0;

	if(direction < 0){

		if(viewOffset > minOffset){

			viewOffset--;
		}
	}
	else if(direction > 0){

		if(viewOffset < maxOffset){

			viewOffset++;
		}
	}

	vgaRender();
}

static void vgaNewLine()
{
	cursorX = 0;

	cursorY++;

	totalLines =
		cursorY + 1;

	vgaClearLine(cursorY);
}

void vga(
	const char* text,
	uint8_t color,
	uint8_t newline
)
{
	for(uint32_t i = 0;
	    text[i] != '\0';
	    i++){

		if(cursorX >= VGA_COLS){

			vgaNewLine();
		}

		VgaCell& cell =
			logBuffer[
				cursorY % LOG_LINES
			][cursorX];

		cell.ch = text[i];

		cell.color = color;

		cursorX++;
	}

	if(newline == 1){

		vgaNewLine();
	}

	vgaFollowBottom();

	vgaRender();
}

void vgaHex(
	uint32_t value,
	uint8_t color
)
{
	char buffer[17];

	const char* hex =
		"0123456789ABCDEF";

	buffer[16] = '\0';

	for(int i = 15;
	    i >= 0;
	    i--){

		buffer[i] =
			hex[value & 0xF];

		value >>= 4;
	}

	vga(
		"0x",
		color,
		0
	);

	vga(
		buffer,
		color,
		1
	);
}
