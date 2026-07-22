#include "string.hpp"

bool memoryEqual(const uint8_t* a, const char* b, int size)
{
    for(int i = 0; i < size; i++)
    {
        if(a[i] != (uint8_t)b[i])
            return false;
    }

    return true;
}
