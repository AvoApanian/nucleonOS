#pragma once

#include "../types.hpp"
#include "SDT.hpp"

struct FADT
{
    ACPISDTHeader header;

    uint32_t firmwareCtrl;
    uint32_t dsdt;

    uint8_t reserved1;
    uint8_t preferredPowerManagementProfile;

    uint16_t sciInterrupt;
    uint32_t smiCommandPort;

    uint8_t acpiEnable;
    uint8_t acpiDisable;
    uint8_t s4BiosRequest;
    uint8_t pStateControl;

    uint32_t pm1aEventBlock;
    uint32_t pm1bEventBlock;

    uint32_t pm1aControlBlock;
    uint32_t pm1bControlBlock;

    uint32_t pm2ControlBlock;
    uint32_t pmTimerBlock;

    uint32_t gpe0Block;
    uint32_t gpe1Block;

    uint8_t pm1EventLength;
    uint8_t pm1ControlLength;
    uint8_t pm2ControlLength;
    uint8_t pmTimerLength;

    uint8_t gpe0BlockLength;
    uint8_t gpe1BlockLength;

    uint8_t gpe1Base;
    uint8_t cStateControl;

    uint16_t worstC2Latency;
    uint16_t worstC3Latency;

    uint16_t flushSize;
    uint16_t flushStride;

    uint8_t dutyOffset;
    uint8_t dutyWidth;

    uint8_t dayAlarm;
    uint8_t monthAlarm;
    uint8_t century;

    uint16_t bootArchitectureFlags;
    uint8_t reserved2;

    uint32_t flags;
};

FADT* getFADT(uint32_t address);
