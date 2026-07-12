/*******************************************************************************
 * The MIT License (MIT)
 *
 * Copyright (c) 2023, Jean-David Gadina - www.xs-labs.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the Software), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 ******************************************************************************/

/*!
 * @header      SMC-Internal.h
 * @abstract    Private declarations mirroring the interface exposed by the
 *              @c AppleSMC.kext kernel extension.
 * @discussion  The enumerations and structures declared here are dictated by
 *              the SMC user client and must match the kernel extension's
 *              binary layout exactly. They are used to build the request and
 *              response buffers passed to @c IOConnectCallStructMethod when
 *              communicating with the System Management Controller.
 *
 *              Reference:
 *
 *                - https://github.com/apple-oss-distributions/IOKitUser
 *                - https://opensource.apple.com/source/IOKitUser/
 *                - https://opensource.apple.com/source/IOKitUser/IOKitUser-647.6/pwr_mgt.subproj/IOPMLibPrivate.c
 */

@import IOKit;

/*!
 * @enum        SMC Result Codes
 * @abstract    Result codes reported by the SMC in a response's @c result field.
 * @discussion  Do not modify - defined by @c AppleSMC.kext.
 * @constant    kSMCKeyNotFound The requested key does not exist on this machine.
 */
enum
{
    kSMCKeyNotFound = 0x84
};

/*!
 * @enum        SMC Status Codes
 * @abstract    Generic success and error status values used by the SMC.
 * @discussion  Do not modify - defined by @c AppleSMC.kext.
 * @constant    kSMCSuccess The operation completed successfully.
 * @constant    kSMCError   The operation failed.
 */
enum
{
    kSMCSuccess = 0,
    kSMCError   = 1
};

/*!
 * @enum        SMC Selectors
 * @abstract    Selectors identifying the operation to perform on the SMC user
 *              client.
 * @discussion  Do not modify - defined by @c AppleSMC.kext. These values are
 *              passed to @c IOConnectCallMethod / @c IOConnectCallStructMethod
 *              (or carried in a request's @c data8 field) to select the desired
 *              SMC operation.
 * @constant    kSMCUserClientOpen  Open a session on the SMC user client.
 * @constant    kSMCUserClientClose Close a session on the SMC user client.
 * @constant    kSMCHandleYPCEvent  Dispatch a structured SMC command.
 * @constant    kSMCReadKey         Read the value associated with a key.
 * @constant    kSMCWriteKey        Write a value to a key.
 * @constant    kSMCGetKeyCount     Retrieve the total number of keys.
 * @constant    kSMCGetKeyFromIndex Retrieve the key located at a given index.
 * @constant    kSMCGetKeyInfo      Retrieve metadata (size, type) for a key.
 */
enum
{
    kSMCUserClientOpen  = 0,
    kSMCUserClientClose = 1,
    kSMCHandleYPCEvent  = 2,
    kSMCReadKey         = 5,
    kSMCWriteKey        = 6,
    kSMCGetKeyCount     = 7,
    kSMCGetKeyFromIndex = 8,
    kSMCGetKeyInfo      = 9
};

/*!
 * @typedef     SMCVersion
 * @abstract    Firmware version information reported by the SMC.
 * @discussion  Do not modify - defined by @c AppleSMC.kext.
 * @field       major    The major version component.
 * @field       minor    The minor version component.
 * @field       build    The build version component.
 * @field       reserved Reserved padding; unused.
 * @field       release  The release version component.
 */
typedef struct
{
    unsigned char  major;
    unsigned char  minor;
    unsigned char  build;
    unsigned char  reserved;
    unsigned short release;
}
SMCVersion;

/*!
 * @typedef     SMCPLimitData
 * @abstract    Power-limit data used by the SMC.
 * @discussion  Do not modify - defined by @c AppleSMC.kext.
 * @field       version   The structure version.
 * @field       length    The structure length, in bytes.
 * @field       cpuPLimit The CPU power limit.
 * @field       gpuPLimit The GPU power limit.
 * @field       memPLimit The memory power limit.
 */
typedef struct
{
    uint16_t version;
    uint16_t length;
    uint32_t cpuPLimit;
    uint32_t gpuPLimit;
    uint32_t memPLimit;
}
SMCPLimitData;

/*!
 * @typedef     SMCKeyInfoData
 * @abstract    Metadata describing a single SMC key.
 * @discussion  Do not modify - defined by @c AppleSMC.kext.
 * @field       dataSize       The size, in bytes, of the key's value.
 * @field       dataType       The four-character type code of the key's value.
 * @field       dataAttributes The key's attribute flags.
 */
typedef struct
{
    uint32_t dataSize;
    uint32_t dataType;
    uint8_t  dataAttributes;
}
SMCKeyInfoData;

/*!
 * @typedef     SMCParamStruct
 * @abstract    The request/response structure exchanged with the SMC user
 *              client.
 * @discussion  Do not modify - defined by @c AppleSMC.kext. The same structure
 *              layout is used both as input and output of
 *              @c IOConnectCallStructMethod. Only a subset of fields is
 *              relevant to any given operation.
 * @field       key        The four-character key code.
 * @field       vers       The SMC firmware version information.
 * @field       pLimitData The power-limit data.
 * @field       keyInfo    The key metadata (size, type, attributes).
 * @field       result     The result code returned by the SMC.
 * @field       status     The status code returned by the SMC.
 * @field       data8      An 8-bit operand, typically the operation selector.
 * @field       data32     A 32-bit operand, typically a key index.
 * @field       bytes      The raw value payload, up to 32 bytes.
 */
typedef struct
{
    uint32_t       key;
    SMCVersion     vers;
    SMCPLimitData  pLimitData;
    SMCKeyInfoData keyInfo;
    uint8_t        result;
    uint8_t        status;
    uint8_t        data8;
    uint32_t       data32;
    uint8_t        bytes[ 32 ];
}
SMCParamStruct;

/*!
 * @const       kSMCKeyNKEY
 * @abstract    The SMC key (@c '#KEY') whose value holds the total number of
 *              keys exposed by the SMC.
 */
extern const uint32_t kSMCKeyNKEY;

/*!
 * @const       kSMCKeyACID
 * @abstract    The SMC key (@c 'ACID') identifying the AC power adapter
 *              information.
 * @discussion  This key is treated specially when reading, as its bytes are
 *              not byte-swapped like other keys.
 */
extern const uint32_t kSMCKeyACID;
