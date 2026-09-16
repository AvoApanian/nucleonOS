#include "../types.hpp"
#include "../../driver/vga/vga.hpp"

#include "AML.hpp"

static uint32_t amlClampEnd(AMLParser* parser, uint32_t end)
{
	if(end > parser->length)
	{
		vga("AML: WARNING: END OFFSET CLAMPED, PKGLENGTH INCOHERENT", 0x04, 1);

		vga("AML: WARNING: REQUESTED END:", 0x04, 0);
		vgaHex(end, 0x04);

		vga("AML: WARNING: BUFFER LENGTH:", 0x04, 0);
		vgaHex(parser->length, 0x04);

		return parser->length;
	}

	return end;
}

void amlInitParser(AMLParser* parser, const uint8_t* buffer, uint32_t length, AMLNamespace* ns)
{
	vga("AML: INIT PARSER", 0x0F, 1);

	vga("AML: BUFFER ADDRESS:", 0x0F, 0);
	vgaHex((uint32_t)buffer, 0x0F);

	vga("AML: BUFFER LENGTH:", 0x0F, 0);
	vgaHex(length, 0x0F);

	parser->buffer = buffer;
	parser->cursor = buffer;
	parser->length = length;
	parser->offset = 0;
	parser->ns = ns;

	vga("AML: PARSER READY", 0x0A, 1);
}

uint8_t amlPeekByte(AMLParser* parser)
{
	if(parser->offset >= parser->length)
	{
		vga("AML: PEEK OUT OF BOUNDS", 0x04, 1);
		return 0;
	}

	return parser->cursor[0];
}

uint8_t amlReadByte(AMLParser* parser)
{
	if(parser->offset >= parser->length)
	{
		vga("AML: READ OUT OF BOUNDS", 0x04, 1);
		return 0;
	}

	uint8_t value = parser->cursor[0];

	parser->cursor++;
	parser->offset++;

	return value;
}

uint32_t amlReadPackageLength(AMLParser* parser)
{
	vga("AML: PKGLENGTH: START", 0x0F, 1);

	uint32_t startOffset = parser->offset;

	uint8_t leadByte = amlReadByte(parser);

	vga("AML: PKGLENGTH: LEAD BYTE:", 0x0F, 0);
	vgaHex((uint32_t)leadByte, 0x0F);

	uint8_t byteCount = (leadByte >> 6) & 0x03;

	vga("AML: PKGLENGTH: EXTRA BYTES:", 0x0F, 0);
	vgaHex((uint32_t)byteCount, 0x0F);

	uint32_t length = 0;

	if(byteCount == 0)
	{
		length = leadByte & 0x3F;
	}
	else
	{
		length = leadByte & 0x0F;

		for(uint8_t i = 0; i < byteCount; i++)
		{
			uint8_t b = amlReadByte(parser);

			vga("AML: PKGLENGTH: EXTRA BYTE:", 0x0F, 0);
			vgaHex((uint32_t)b, 0x0F);

			length |= ((uint32_t)b) << (4 + 8 * i);
		}
	}

	vga("AML: PKGLENGTH: VALUE:", 0x0F, 0);
	vgaHex(length, 0x0F);

	uint32_t consumed = parser->offset - startOffset;

	vga("AML: PKGLENGTH: BYTES CONSUMED:", 0x0F, 0);
	vgaHex(consumed, 0x0F);

	vga("AML: PKGLENGTH: END", 0x0A, 1);

	return length;
}

bool amlReadNameSeg(AMLParser* parser, char* out)
{
	vga("AML: NAMESEG: START", 0x0F, 1);

	for(uint32_t i = 0; i < 4; i++)
	{
		uint8_t c = amlReadByte(parser);

		vga("AML: NAMESEG: BYTE:", 0x0F, 0);
		vgaHex((uint32_t)c, 0x0F);

		out[i] = (char)c;
	}

	out[4] = '\0';

	vga("AML: NAMESEG: RESULT:", 0x0F, 0);
	vga(out, 0x0B, 1);

	return true;
}

bool amlReadNameString(AMLParser* parser, char* out, uint32_t maxLen)
{
	vga("AML: NAMESTRING: START", 0x0F, 1);

	uint32_t pos = 0;

	while(amlPeekByte(parser) == AML_ROOT_CHAR)
	{
		uint8_t c = amlReadByte(parser);

		vga("AML: NAMESTRING: ROOT CHAR", 0x0F, 1);

		if(pos < maxLen - 1)
		{
			out[pos++] = (char)c;
		}
	}

	while(amlPeekByte(parser) == AML_PARENT_PREFIX_CHAR)
	{
		uint8_t c = amlReadByte(parser);

		vga("AML: NAMESTRING: PARENT PREFIX", 0x0F, 1);

		if(pos < maxLen - 1)
		{
			out[pos++] = (char)c;
		}
	}

	uint8_t prefix = amlPeekByte(parser);

	if(prefix == 0x00)
	{
		amlReadByte(parser);

		vga("AML: NAMESTRING: NULL NAME", 0x0F, 1);

		out[pos] = '\0';

		return true;
	}

	uint32_t segCount = 1;

	if(prefix == AML_DUAL_NAME_PREFIX)
	{
		amlReadByte(parser);

		vga("AML: NAMESTRING: DUAL NAME PREFIX", 0x0F, 1);

		segCount = 2;
	}
	else if(prefix == AML_MULTI_NAME_PREFIX)
	{
		amlReadByte(parser);

		segCount = amlReadByte(parser);

		vga("AML: NAMESTRING: MULTI NAME PREFIX, SEGCOUNT:", 0x0F, 0);
		vgaHex(segCount, 0x0F);
	}

	for(uint32_t i = 0; i < segCount; i++)
	{
		char seg[5];

		amlReadNameSeg(parser, seg);

		if(i > 0 && pos < maxLen - 1)
		{
			out[pos++] = '.';
		}

		for(uint32_t j = 0; j < 4 && pos < maxLen - 1; j++)
		{
			out[pos++] = seg[j];
		}
	}

	out[pos] = '\0';

	vga("AML: NAMESTRING: RESULT:", 0x0F, 0);
	vga(out, 0x0B, 1);

	vga("AML: NAMESTRING: END", 0x0A, 1);

	return true;
}

void amlReadInteger(AMLParser* parser, uint8_t opcode, uint32_t* low, uint32_t* high)
{
	vga("AML: INTEGER: START", 0x0F, 1);

	*low = 0;
	*high = 0;

	switch(opcode)
	{
		case AML_ZERO_OP:

			vga("AML: INTEGER: ZERO", 0x0A, 1);

			*low = 0;

			break;

		case AML_ONE_OP:

			vga("AML: INTEGER: ONE", 0x0A, 1);

			*low = 1;

			break;

		case AML_ONES_OP:

			vga("AML: INTEGER: ONES", 0x0A, 1);

			*low = 0xFFFFFFFF;
			*high = 0xFFFFFFFF;

			break;

		case AML_BYTE_PREFIX:
		{
			uint8_t value = amlReadByte(parser);

			vga("AML: INTEGER: BYTE VALUE:", 0x0F, 0);
			vgaHex((uint32_t)value, 0x0F);

			*low = value;

			break;
		}

		case AML_WORD_PREFIX:
		{
			uint32_t value = 0;

			value |= (uint32_t)amlReadByte(parser);
			value |= (uint32_t)amlReadByte(parser) << 8;

			vga("AML: INTEGER: WORD VALUE:", 0x0F, 0);
			vgaHex(value, 0x0F);

			*low = value;

			break;
		}

		case AML_DWORD_PREFIX:
		{
			uint32_t value = 0;

			value |= (uint32_t)amlReadByte(parser);
			value |= (uint32_t)amlReadByte(parser) << 8;
			value |= (uint32_t)amlReadByte(parser) << 16;
			value |= (uint32_t)amlReadByte(parser) << 24;

			vga("AML: INTEGER: DWORD VALUE:", 0x0F, 0);
			vgaHex(value, 0x0F);

			*low = value;

			break;
		}

		case AML_QWORD_PREFIX:
		{
			uint32_t lowValue = 0;
			uint32_t highValue = 0;

			lowValue |= (uint32_t)amlReadByte(parser);
			lowValue |= (uint32_t)amlReadByte(parser) << 8;
			lowValue |= (uint32_t)amlReadByte(parser) << 16;
			lowValue |= (uint32_t)amlReadByte(parser) << 24;

			highValue |= (uint32_t)amlReadByte(parser);
			highValue |= (uint32_t)amlReadByte(parser) << 8;
			highValue |= (uint32_t)amlReadByte(parser) << 16;
			highValue |= (uint32_t)amlReadByte(parser) << 24;

			vga("AML: INTEGER: QWORD LOW:", 0x0F, 0);
			vgaHex(lowValue, 0x0F);

			vga("AML: INTEGER: QWORD HIGH:", 0x0F, 0);
			vgaHex(highValue, 0x0F);

			*low = lowValue;
			*high = highValue;

			break;
		}

		default:

			vga("AML: INTEGER: UNKNOWN OPCODE", 0x04, 1);

			break;
	}

	vga("AML: INTEGER: END", 0x0A, 1);
}

void amlParseObject(AMLParser* parser, uint32_t* outLow, uint32_t* outHigh, bool* outIsInteger)
{
	vga("AML: OBJECT: START", 0x0F, 1);

	if(outIsInteger != nullptr)
	{
		*outIsInteger = false;
	}

	uint8_t opcode = amlReadByte(parser);

	vga("AML: OBJECT: OPCODE:", 0x0F, 0);
	vgaHex((uint32_t)opcode, 0x0F);

	switch(opcode)
	{
		case AML_ZERO_OP:
		case AML_ONE_OP:
		case AML_ONES_OP:
		case AML_BYTE_PREFIX:
		case AML_WORD_PREFIX:
		case AML_DWORD_PREFIX:
		case AML_QWORD_PREFIX:
		{
			uint32_t low = 0;
			uint32_t high = 0;

			amlReadInteger(parser, opcode, &low, &high);

			if(outLow != nullptr)
			{
				*outLow = low;
			}

			if(outHigh != nullptr)
			{
				*outHigh = high;
			}

			if(outIsInteger != nullptr)
			{
				*outIsInteger = true;
			}

			break;
		}

		case AML_STRING_PREFIX:
		{
			vga("AML: OBJECT: STRING", 0x0F, 1);

			char str[128];
			uint32_t i = 0;

			while(amlPeekByte(parser) != 0x00 && i < sizeof(str) - 1)
			{
				str[i++] = (char)amlReadByte(parser);
			}

			str[i] = '\0';

			if(amlPeekByte(parser) == 0x00)
			{
				amlReadByte(parser);
			}

			vga(str, 0x0B, 1);

			break;
		}

		case AML_BUFFER_OP:
		{
			vga("AML: OBJECT: BUFFER OP", 0x0A, 1);

			uint32_t startOffset = parser->offset;

			uint32_t pkgLength = amlReadPackageLength(parser);

			uint32_t endOffset = amlClampEnd(parser, startOffset + pkgLength);

			vga("AML: OBJECT: BUFFER: END OFFSET:", 0x0F, 0);
			vgaHex(endOffset, 0x0F);

			if(parser->offset < endOffset)
			{
				amlParseObject(parser, nullptr, nullptr, nullptr);
			}

			vga("AML: OBJECT: BUFFER: SKIPPING RAW BYTES", 0x0F, 1);

			while(parser->offset < endOffset)
			{
				amlReadByte(parser);
			}

			vga("AML: OBJECT: BUFFER: END", 0x0A, 1);

			break;
		}

		case AML_PACKAGE_OP:
		case AML_VAR_PACKAGE_OP:
		{
			vga("AML: OBJECT: PACKAGE OP", 0x0A, 1);

			uint32_t startOffset = parser->offset;

			uint32_t pkgLength = amlReadPackageLength(parser);

			uint32_t endOffset = amlClampEnd(parser, startOffset + pkgLength);

			uint8_t numElements = amlReadByte(parser);

			vga("AML: OBJECT: PACKAGE: NUM ELEMENTS:", 0x0F, 0);
			vgaHex((uint32_t)numElements, 0x0F);

			vga("AML: OBJECT: PACKAGE: SKIPPING ELEMENTS", 0x0F, 1);

			while(parser->offset < endOffset)
			{
				amlReadByte(parser);
			}

			vga("AML: OBJECT: PACKAGE: END", 0x0A, 1);

			break;
		}

		default:
		{
			vga("AML: OBJECT: NAMESTRING (REWIND)", 0x0F, 1);

			parser->cursor--;
			parser->offset--;

			char name[256];

			amlReadNameString(parser, name, sizeof(name));

			break;
		}
	}

	vga("AML: OBJECT: END", 0x0A, 1);
}

void amlParseTermList(AMLParser* parser, uint32_t endOffset)
{
	endOffset = amlClampEnd(parser, endOffset);

	vga("AML: TERMLIST: START", 0x0F, 1);

	vga("AML: TERMLIST: END OFFSET:", 0x0F, 0);
	vgaHex(endOffset, 0x0F);

	while(parser->offset < endOffset)
	{
		vga("AML: TERMLIST: ----------------", 0x0F, 1);

		vga("AML: TERMLIST: CURRENT OFFSET:", 0x0F, 0);
		vgaHex(parser->offset, 0x0F);

		uint8_t opcode = amlReadByte(parser);

		vga("AML: TERMLIST: OPCODE:", 0x0F, 0);
		vgaHex((uint32_t)opcode, 0x0F);

		switch(opcode)
		{
			case AML_NAME_OP:
			{
				vga("AML: TERMLIST: NAME OP", 0x0A, 1);

				char name[256];

				amlReadNameString(parser, name, sizeof(name));

				vga("AML: TERMLIST: NAME:", 0x0F, 0);
				vga(name, 0x0B, 1);

				uint32_t low = 0;
				uint32_t high = 0;
				bool isInteger = false;

				amlParseObject(parser, &low, &high, &isInteger);

				AMLObject* object =
					namespaceAddObject(parser->ns, name, AML_OBJECT_NAME);

				if(object != nullptr && isInteger)
				{
					object->valueLow = low;
					object->valueHigh = high;

					vga("AML: TERMLIST: NAME VALUE STORED:", 0x0A, 0);
					vgaHex(low, 0x0A);
				}

				break;
			}

			case AML_SCOPE_OP:
			{
				vga("AML: TERMLIST: SCOPE OP", 0x0A, 1);

				uint32_t startOffset = parser->offset;

				uint32_t pkgLength = amlReadPackageLength(parser);

				uint32_t scopeEnd = amlClampEnd(parser, startOffset + pkgLength);

				char name[256];

				amlReadNameString(parser, name, sizeof(name));

				vga("AML: TERMLIST: SCOPE NAME:", 0x0F, 0);
				vga(name, 0x0B, 1);

				AMLObject* object =
					namespaceAddObject(parser->ns, name, AML_OBJECT_SCOPE);

				AMLObject* previousScope = parser->ns->currentScope;

				parser->ns->currentScope = object;

				amlParseTermList(parser, scopeEnd);

				parser->ns->currentScope = previousScope;

				break;
			}

			case AML_METHOD_OP:
			{
				vga("AML: TERMLIST: METHOD OP", 0x0A, 1);

				uint32_t startOffset = parser->offset;

				uint32_t pkgLength = amlReadPackageLength(parser);

				uint32_t methodEnd = amlClampEnd(parser, startOffset + pkgLength);

				char name[256];

				amlReadNameString(parser, name, sizeof(name));

				vga("AML: TERMLIST: METHOD NAME:", 0x0F, 0);
				vga(name, 0x0B, 1);

				uint8_t methodFlags = amlReadByte(parser);

				vga("AML: TERMLIST: METHOD FLAGS:", 0x0F, 0);
				vgaHex((uint32_t)methodFlags, 0x0F);

				AMLObject* object =
					namespaceAddObject(parser->ns, name, AML_OBJECT_METHOD);

				if(object != nullptr)
				{
					object->valueLow = methodFlags & 0x07;
				}

				vga("AML: TERMLIST: METHOD BODY SKIPPED (PAS ENCORE EXECUTE)", 0x0F, 1);

				while(parser->offset < methodEnd)
				{
					amlReadByte(parser);
				}

				break;
			}

			case AML_EXT_OP_PREFIX:
			{
				uint8_t extOpcode = amlReadByte(parser);

				vga("AML: TERMLIST: EXT OPCODE:", 0x0F, 0);
				vgaHex((uint32_t)extOpcode, 0x0F);

				switch(extOpcode)
				{
					case AML_EXT_DEVICE_OP:
					{
						vga("AML: TERMLIST: DEVICE OP", 0x0A, 1);

						uint32_t startOffset = parser->offset;

						uint32_t pkgLength = amlReadPackageLength(parser);

						uint32_t deviceEnd = amlClampEnd(parser, startOffset + pkgLength);

						char name[256];

						amlReadNameString(parser, name, sizeof(name));

						vga("AML: TERMLIST: DEVICE NAME:", 0x0F, 0);
						vga(name, 0x0B, 1);

						AMLObject* object =
							namespaceAddObject(parser->ns, name, AML_OBJECT_DEVICE);

						AMLObject* previousScope = parser->ns->currentScope;

						parser->ns->currentScope = object;

						amlParseTermList(parser, deviceEnd);

						parser->ns->currentScope = previousScope;

						break;
					}

					case AML_EXT_REGION_OP:
					{
						vga("AML: TERMLIST: OPERATION REGION OP", 0x0A, 1);

						char name[256];

						amlReadNameString(parser, name, sizeof(name));

						vga("AML: TERMLIST: REGION NAME:", 0x0F, 0);
						vga(name, 0x0B, 1);

						uint8_t regionSpace = amlReadByte(parser);

						vga("AML: TERMLIST: REGION SPACE:", 0x0F, 0);
						vgaHex((uint32_t)regionSpace, 0x0F);

						uint8_t offsetOpcode = amlReadByte(parser);

						uint32_t offLow = 0;
						uint32_t offHigh = 0;

						amlReadInteger(parser, offsetOpcode, &offLow, &offHigh);

						vga("AML: TERMLIST: REGION OFFSET:", 0x0F, 0);
						vgaHex(offLow, 0x0F);

						uint8_t lenOpcode = amlReadByte(parser);

						uint32_t lenLow = 0;
						uint32_t lenHigh = 0;

						amlReadInteger(parser, lenOpcode, &lenLow, &lenHigh);

						vga("AML: TERMLIST: REGION LENGTH:", 0x0F, 0);
						vgaHex(lenLow, 0x0F);

						AMLObject* object =
							namespaceAddObject(parser->ns, name, AML_OBJECT_REGION);

						if(object != nullptr)
						{
							object->valueLow = regionSpace;
							object->valueHigh = offLow;
						}

						break;
					}

					case AML_EXT_FIELD_OP:
					{
						vga("AML: TERMLIST: FIELD OP", 0x0A, 1);

						uint32_t startOffset = parser->offset;

						uint32_t pkgLength = amlReadPackageLength(parser);

						uint32_t fieldEnd = amlClampEnd(parser, startOffset + pkgLength);

						char name[256];

						amlReadNameString(parser, name, sizeof(name));

						vga("AML: TERMLIST: FIELD REGION NAME:", 0x0F, 0);
						vga(name, 0x0B, 1);

						uint8_t fieldFlags = amlReadByte(parser);

						vga("AML: TERMLIST: FIELD FLAGS:", 0x0F, 0);
						vgaHex((uint32_t)fieldFlags, 0x0F);

						AMLObject* object =
							namespaceAddObject(parser->ns, name, AML_OBJECT_FIELD);

						if(object != nullptr)
						{
							object->valueLow = fieldFlags;
						}

						vga("AML: TERMLIST: FIELD LIST SKIPPED", 0x0F, 1);

						while(parser->offset < fieldEnd)
						{
							amlReadByte(parser);
						}

						break;
					}

					default:

						vga("AML: TERMLIST: EXT OPCODE NON GERE, ARRET DU SCOPE", 0x04, 1);

						parser->offset = endOffset;
						parser->cursor = parser->buffer + endOffset;

						break;
				}

				break;
			}

			default:

				vga("AML: TERMLIST: OPCODE NON GERE, ARRET DU SCOPE", 0x04, 1);

				parser->offset = endOffset;
				parser->cursor = parser->buffer + endOffset;

				break;
		}
	}

	vga("AML: TERMLIST: END", 0x0A, 1);
}

void namespaceInit(AMLNamespace* ns)
{
	vga("AML: NAMESPACE: INIT", 0x0F, 1);

	ns->count = 0;
	ns->currentScope = nullptr;
}

AMLObject* namespaceAddObject(AMLNamespace* ns, const char* name, AMLObjectType type)
{
	if(ns->count >= AML_MAX_OBJECTS)
	{
		vga("AML: NAMESPACE: FULL, CANNOT ADD:", 0x04, 0);
		vga(name, 0x04, 1);

		return nullptr;
	}

	AMLObject* object = &ns->objects[ns->count];

	ns->count++;

	uint32_t i = 0;

	while(name[i] != '\0' && i < sizeof(object->name) - 1)
	{
		object->name[i] = name[i];
		i++;
	}

	object->name[i] = '\0';

	object->type = type;
	object->valueLow = 0;
	object->valueHigh = 0;
	object->parent = ns->currentScope;

	vga("AML: NAMESPACE: ADD:", 0x0A, 0);
	vga(object->name, 0x0B, 1);

	return object;
}

void namespacePrintPath(AMLObject* object)
{
	if(object == nullptr)
	{
		return;
	}

	if(object->parent != nullptr)
	{
		namespacePrintPath(object->parent);
		vga(".", 0x0F, 0);
	}

	vga(object->name, 0x0B, 0);
}

static const char* namespaceTypeName(AMLObjectType type)
{
	switch(type)
	{
		case AML_OBJECT_SCOPE:
			return "SCOPE";

		case AML_OBJECT_DEVICE:
			return "DEVICE";

		case AML_OBJECT_NAME:
			return "NAME";

		case AML_OBJECT_METHOD:
			return "METHOD";

		case AML_OBJECT_REGION:
			return "REGION";

		case AML_OBJECT_FIELD:
			return "FIELD";

		case AML_OBJECT_BUFFER:
			return "BUFFER";

		case AML_OBJECT_PACKAGE:
			return "PACKAGE";
	}

	return "UNKNOWN";
}

void namespaceDump(AMLNamespace* ns)
{
	vga("================================", 0x0F, 1);
	vga("AML: NAMESPACE DUMP", 0x0A, 1);
	vga("================================", 0x0F, 1);

	vga("AML: NAMESPACE: OBJECT COUNT:", 0x0F, 0);
	vgaHex(ns->count, 0x0F);

	for(uint32_t i = 0; i < ns->count; i++)
	{
		AMLObject* object = &ns->objects[i];

		vga("PATH: ", 0x0F, 0);
		namespacePrintPath(object);
		vga("", 0x0F, 1);

		vga("  TYPE:", 0x0F, 0);
		vga(namespaceTypeName(object->type), 0x0B, 1);

		vga("  VALUE LOW:", 0x0F, 0);
		vgaHex(object->valueLow, 0x0F);

		vga("  VALUE HIGH:", 0x0F, 0);
		vgaHex(object->valueHigh, 0x0F);
	}

	vga("================================", 0x0F, 1);
	vga("AML: NAMESPACE DUMP END", 0x0A, 1);
	vga("================================", 0x0F, 1);
}

void amlParseDSDT(const ACPISDTHeader* dsdt)
{
	vga("================================", 0x0F, 1);
	vga("AML: PARSE DSDT: START", 0x0A, 1);
	vga("================================", 0x0F, 1);

	if(dsdt == nullptr)
	{
		vga("AML: PARSE DSDT: NULL POINTER", 0x04, 1);
		return;
	}

	uint32_t amlAddress = (uint32_t)dsdt + sizeof(ACPISDTHeader);

	uint32_t amlLength = dsdt->length - sizeof(ACPISDTHeader);

	vga("AML: PARSE DSDT: AML ADDRESS:", 0x0F, 0);
	vgaHex(amlAddress, 0x0F);

	vga("AML: PARSE DSDT: AML LENGTH:", 0x0F, 0);
	vgaHex(amlLength, 0x0F);

	if(amlLength == 0)
	{
		vga("AML: PARSE DSDT: BUFFER AML VIDE", 0x04, 1);
		return;
	}

	static AMLNamespace ns;

	namespaceInit(&ns);

	AMLParser parser;

	amlInitParser(&parser, (const uint8_t*)amlAddress, amlLength, &ns);

	amlParseTermList(&parser, amlLength);

	vga("================================", 0x0F, 1);
	vga("AML: PARSE DSDT: FINISHED", 0x0A, 1);
	vga("================================", 0x0F, 1);

	namespaceDump(&ns);
}