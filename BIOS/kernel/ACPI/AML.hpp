#pragma once

#include "../types.hpp"
#include "SDT.hpp"

#define AML_ZERO_OP            0x00
#define AML_ONE_OP             0x01
#define AML_ALIAS_OP           0x06
#define AML_NAME_OP            0x08
#define AML_BYTE_PREFIX        0x0A
#define AML_WORD_PREFIX        0x0B
#define AML_DWORD_PREFIX       0x0C
#define AML_STRING_PREFIX      0x0D
#define AML_QWORD_PREFIX       0x0E
#define AML_SCOPE_OP           0x10
#define AML_BUFFER_OP          0x11
#define AML_PACKAGE_OP         0x12
#define AML_VAR_PACKAGE_OP     0x13
#define AML_METHOD_OP          0x14
#define AML_EXT_OP_PREFIX      0x5B
#define AML_ROOT_CHAR          '\\'
#define AML_PARENT_PREFIX_CHAR '^'
#define AML_DUAL_NAME_PREFIX   0x2E
#define AML_MULTI_NAME_PREFIX  0x2F
#define AML_ONES_OP            0xFF

#define AML_EXT_REGION_OP      0x80
#define AML_EXT_FIELD_OP       0x81
#define AML_EXT_DEVICE_OP      0x82
#define AML_EXT_PROCESSOR_OP   0x83
#define AML_EXT_POWER_RES_OP   0x84
#define AML_EXT_THERMAL_OP     0x85

#define AML_MAX_OBJECTS        256
#define AML_NAME_MAX_LEN       256

enum AMLObjectType
{
	AML_OBJECT_SCOPE,
	AML_OBJECT_DEVICE,
	AML_OBJECT_NAME,
	AML_OBJECT_METHOD,
	AML_OBJECT_REGION,
	AML_OBJECT_FIELD,
	AML_OBJECT_BUFFER,
	AML_OBJECT_PACKAGE
};

struct AMLObject
{
	char name[AML_NAME_MAX_LEN];
	AMLObjectType type;

	uint32_t valueLow;
	uint32_t valueHigh;

	AMLObject* parent;
};

struct AMLNamespace
{
	AMLObject objects[AML_MAX_OBJECTS];
	uint32_t count;

	AMLObject* currentScope;
};

struct AMLParser
{
	const uint8_t* buffer;
	const uint8_t* cursor;
	uint32_t length;
	uint32_t offset;

	AMLNamespace* ns;
};

void amlInitParser(AMLParser* parser, const uint8_t* buffer, uint32_t length, AMLNamespace* ns);

uint8_t amlPeekByte(AMLParser* parser);
uint8_t amlReadByte(AMLParser* parser);

uint32_t amlReadPackageLength(AMLParser* parser);

bool amlReadNameSeg(AMLParser* parser, char* out);
bool amlReadNameString(AMLParser* parser, char* out, uint32_t maxLen);

void amlReadInteger(AMLParser* parser, uint8_t opcode, uint32_t* low, uint32_t* high);

void amlParseObject(AMLParser* parser, uint32_t* outLow, uint32_t* outHigh, bool* outIsInteger);
void amlParseTermList(AMLParser* parser, uint32_t endOffset);

void amlParseDSDT(const ACPISDTHeader* dsdt);

void namespaceInit(AMLNamespace* ns);
AMLObject* namespaceAddObject(AMLNamespace* ns, const char* name, AMLObjectType type);
void namespacePrintPath(AMLObject* object);
void namespaceDump(AMLNamespace* ns);