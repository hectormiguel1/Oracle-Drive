#ifndef ZTRTOOL_H
#define ZTRTOOL_H

#include "../common.h"

#ifdef __cplusplus
extern "C" {
#endif

    // Enums matching ZTREnums.cs

    typedef enum {
        ZTR_ACTION_X = 0,
        ZTR_ACTION_C = 1,
        ZTR_ACTION_C2 = 2
    } ZTRAction;

    typedef enum {
        ZTR_GAME_FF13_1 = 0,
        ZTR_GAME_FF13_2 = 1,
        ZTR_GAME_FF13_3 = 2
    } ZTRGameCode;

    typedef enum {
        ZTR_ENCODING_AUTO = 0,
        ZTR_ENCODING_CH = 1,
        ZTR_ENCODING_KR = 2,
        ZTR_ENCODING_LJ = 3
    } ZTREncoding;

    // Data Structures
    
    typedef struct {
        const char* id;
        const char* text;
    } ZtrEntry;

    typedef struct {
        const char* key;
        const char* value;
    } ZtrKeyMapping;

    typedef struct {
        ZtrEntry* entries;
        int entry_count;
        ZtrKeyMapping* mappings;
        int mapping_count;
    } ZtrResultData;

    // Exported Functions

    /**
     * Initializes the ZTR tool library (registers code pages).
     */
    ZTRTOOL_H void ztr_init();

    /**
     * Extracts a ZTR file to TXT (on disk).
     * @param inZtrFile Path to the input .ztr file.
     * @param gameCode Game code switch.
     * @param encodingSwitch Encoding switch.
     * @return Result object (success or error).
     */
    ZTRTOOL_H Result ztr_extract(const char* inZtrFile, int gameCode, int encodingSwitch);

    /**
     * Extracts a ZTR file and returns the parsed data in memory.
     * @param inZtrFile Path to the input .ztr file.
     * @param gameCode Game code switch.
     * @param encodingSwitch Encoding switch.
     * @return Result containing pointer to ZtrResultData. 
     *         Use free_result() to free the entire structure.
     */
    ZTRTOOL_H Result ztr_extract_data(const char* inZtrFile, int gameCode, int encodingSwitch);

    /**
     * Converts a TXT file to ZTR.
     * @param inTxtFile Path to the input .txt file.
     * @param gameCode Game code switch.
     * @param encodingSwitch Encoding switch.
     * @param actionSwitch Action switch (compress/uncompress).
     * @return Result object (success or error).
     */
    ZTRTOOL_H Result ztr_convert(const char* inTxtFile, int gameCode, int encodingSwitch, int actionSwitch);

    /**
     * Packs ZtrResultData into a .ZTR file.
     * @param data Pointer to ZtrResultData structure.
     * @param outZtrFile Path to the output .ztr file.
     * @param gameCode Game code switch.
     * @param encodingSwitch Encoding switch.
     * @param actionSwitch Action switch (compress/uncompress).
     * @return Result object (success or error).
     */
    ZTRTOOL_H Result ztr_pack_data(ZtrResultData* data, const char* outZtrFile, int gameCode, int encodingSwitch, int actionSwitch);

    /**
     * Dumps ZtrResultData to a text file (ID |:| Text).
     * @param data Pointer to ZtrResultData structure.
     * @param outTxtFile Path to the output .txt file.
     * @return Result object (success or error).
     */
    ZTRTOOL_H Result ztr_dump_data(ZtrResultData* data, const char* outTxtFile);

#ifdef __cplusplus
}
#endif

#endif // ZTRTOOL_H
