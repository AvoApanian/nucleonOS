#include "../types.hpp"
#include "SDT.hpp"

bool validateSDTChecksum(const ACPISDTHeader* table)
{
    if(table == nullptr)
        return false;

    uint8_t sum = 0;

    for(uint32_t i = 0; i < table->length; i++)
    {
        sum += ((const uint8_t*)table)[i];
    }

    return sum == 0;
}
