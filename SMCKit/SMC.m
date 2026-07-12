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

#import "SMC.h"
#import "SMC-Internal.h"

#ifdef SMC_STATIC
#import "SMC-Swift.h"
#else
#import <SMCKit/SMCKit-Swift.h>
#endif

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wfour-char-constants"

/*!
 * @const       kSMCKeyNKEY
 * @abstract    The @c '#KEY' key, whose value holds the total number of SMC
 *              keys.
 */
const uint32_t kSMCKeyNKEY = '#KEY';

/*!
 * @const       kSMCKeyACID
 * @abstract    The @c 'ACID' key, identifying the AC power adapter information.
 */
const uint32_t kSMCKeyACID = 'ACID';

#pragma clang diagnostic push

@import IOKit;

NS_ASSUME_NONNULL_BEGIN

/*!
 * @category    SMC()
 * @abstract    Private interface holding the SMC connection state and the
 *              low-level IOKit communication primitives.
 */
@interface SMC()

/*!
 * @property    connection
 * @abstract    The IOKit connection to the @c AppleSMC service, or
 *              @c IO_OBJECT_NULL when no connection is open.
 */
@property( nonatomic, readwrite, assign ) io_connect_t connection;

/*!
 * @property    keys
 * @abstract    The cached list of SMC key codes, boxed as @c NSNumber values.
 * @discussion  Populated lazily on the first call to @c readAllKeys:.
 */
@property( nonatomic, readwrite, strong ) NSMutableArray< NSNumber * > * keys;

/*!
 * @property    keyInfoCache
 * @abstract    A cache mapping key codes to their @c SMCKeyInfoData metadata.
 * @discussion  Each value is an @c NSValue boxing an @c SMCKeyInfoData struct
 *              by value, avoiding repeated SMC round-trips. Boxing by value
 *              (rather than wrapping a heap pointer) keeps the cache free of
 *              manual memory management.
 */
@property( nonatomic, readwrite, strong ) NSMutableDictionary< NSNumber *, NSValue * > * keyInfoCache;

/*!
 * @property    queue
 * @abstract    The serial queue that serializes access to the instance's
 *              mutable state and its user-client connection.
 * @discussion  Created in @c -init. The public @c readAllKeys: entry point
 *              dispatches its work synchronously onto this queue, so concurrent
 *              callers of the same instance - in particular the process-wide
 *              @c shared instance - cannot race on @c keys, @c keyInfoCache or
 *              @c connection, nor interleave on the single user-client session.
 */
@property( nonatomic, readwrite, strong ) dispatch_queue_t queue;

/*!
 * @method      readAllKeysUnsynchronized:
 * @abstract    Implements @c readAllKeys: without acquiring @c queue.
 * @param       filter The optional per-key filter block; see @c readAllKeys:.
 * @return      The array of decoded @c SMCData objects.
 * @discussion  Must only be called from within a block running on @c queue.
 *              @c readAllKeys: is the single synchronization boundary; every SMC
 *              access it triggers already runs on @c queue, so the private
 *              helpers it calls do not lock again and cannot deadlock
 *              re-entrantly.
 */
- ( NSArray< SMCData * > *  )readAllKeysUnsynchronized: ( BOOL ( ^ _Nullable )( uint32_t ) )filter;

/*!
 * @method      callSMCFunction:input:output:
 * @abstract    Performs a single structured call against the SMC user client.
 * @param       function The SMC selector to invoke (e.g. @c kSMCHandleYPCEvent).
 * @param       input    The populated request structure.
 * @param       output   On return, the response structure from the SMC.
 * @return      @c YES on success, otherwise @c NO.
 * @discussion  Dispatches the structured call on the already-open user-client
 *              session, which @c readAllKeys: opens once around a batch.
 */
- ( BOOL )callSMCFunction: ( uint32_t )function input: ( const SMCParamStruct * )input output: ( SMCParamStruct * )output;

/*!
 * @method      openUserClientSession
 * @abstract    Opens a session on the SMC user client.
 * @return      @c YES on success, otherwise @c NO.
 * @discussion  Opened once around a batch of reads by @c readAllKeys: rather
 *              than around each structured call. Must be balanced by
 *              @c closeUserClientSession.
 */
- ( BOOL )openUserClientSession;

/*!
 * @method      closeUserClientSession
 * @abstract    Closes the session opened by @c openUserClientSession.
 */
- ( void )closeUserClientSession;

/*!
 * @method      readSMCKeyInfo:forKey:
 * @abstract    Retrieves the metadata (size, type, attributes) for a key.
 * @param       info On return, the metadata for the key.
 * @param       key  The key code to query.
 * @return      @c YES on success, otherwise @c NO.
 * @discussion  Results are cached in @c keyInfoCache and served from there on
 *              subsequent calls for the same key.
 */
- ( BOOL )readSMCKeyInfo: ( SMCKeyInfoData * )info forKey: ( uint32_t )key;

/*!
 * @method      readSMCKey:atIndex:
 * @abstract    Retrieves the key code located at a given enumeration index.
 * @param       key   On return, the key code at the requested index.
 * @param       index The zero-based index into the SMC key table.
 * @return      @c YES on success, otherwise @c NO.
 */
- ( BOOL )readSMCKey: ( uint32_t * )key atIndex: ( uint32_t )index;

/*!
 * @method      readSMCKey:buffer:maxSize:keyInfo:
 * @abstract    Reads the raw value of a key into a caller-provided buffer.
 * @param       key     The key code to read.
 * @param       buffer  The destination buffer for the value bytes.
 * @param       maxSize On input, the capacity of @c buffer; on output, the
 *                      number of bytes written.
 * @param       keyInfo On return, the key's metadata. May be @c NULL.
 * @return      @c YES on success, otherwise @c NO (including when @c buffer is
 *              too small to hold the value).
 * @discussion  Value bytes are byte-swapped from the SMC's big-endian ordering,
 *              except for @c kSMCKeyACID which is copied verbatim.
 */
- ( BOOL )readSMCKey: ( uint32_t )key buffer: ( uint8_t * )buffer maxSize: ( uint32_t * )maxSize keyInfo: ( SMCKeyInfoData * _Nullable )keyInfo;

/*!
 * @method      readSMCKeyCount
 * @abstract    Reads the total number of keys exposed by the SMC.
 * @return      The number of keys, or @c 0 on failure.
 * @discussion  Reads and decodes the value of the @c kSMCKeyNKEY key.
 */
- ( uint32_t )readSMCKeyCount;

/*!
 * @method      readInteger:size:
 * @abstract    Decodes a little-endian unsigned integer from a byte buffer.
 * @param       data The buffer holding the value bytes.
 * @param       size The number of bytes to decode; must not exceed
 *                   @c sizeof( uint32_t ).
 * @return      The decoded value, or @c 0 if @c size is too large.
 */
- ( uint32_t )readInteger: ( uint8_t * )data size: ( uint32_t )size;

@end

NS_ASSUME_NONNULL_END

@implementation SMC

/*!
 * @method      shared
 * @abstract    Returns the lazily-created, process-wide shared instance.
 * @return      The shared @c SMC instance.
 */
+ ( SMC * )shared
{
    static dispatch_once_t once;
    static SMC           * instance;

    dispatch_once
    (
        &once,
        ^( void )
        {
            instance = [ SMC new ];
        }
    );

    return instance;
}

/*!
 * @method      init
 * @abstract    Initializes the instance and opens its SMC connection.
 * @return      An initialized @c SMC instance.
 * @discussion  Allocates the key and key-info caches and attempts to open the
 *              connection to the @c AppleSMC service.
 */
- ( instancetype )init
{
    if( ( self = [ super init ] ) )
    {
        self.keys         = [ NSMutableArray new ];
        self.keyInfoCache = [ NSMutableDictionary new ];
        self.queue        = dispatch_queue_create( "com.xs-labs.SMCKit.SMC", DISPATCH_QUEUE_SERIAL );

        [ self open: nil ];
    }

    return self;
}

/*!
 * @method      dealloc
 * @abstract    Closes the SMC connection when the instance is deallocated.
 */
- ( oneway void )dealloc
{
    [ self close ];
}

/*!
 * @method      readAllKeys:
 * @abstract    Reads the value of every SMC key, optionally filtered.
 * @param       filter An optional block invoked with each key code; return
 *                     @c YES to include the key or @c NO to skip it. Pass
 *                     @c nil to read every key.
 * @return      An array of @c SMCData objects for the keys read successfully,
 *              or an empty array if the connection is not open.
 * @discussion  On the first call the key table is enumerated and cached in
 *              @c keys. Keys that fail to read are skipped. Access is
 *              serialized on a per-instance serial queue, so this method is
 *              safe to call concurrently - including on @c shared. Concurrent
 *              calls on the same instance are serialized and may block.
 */
- ( NSArray< SMCData * > *  )readAllKeys: ( BOOL ( ^ _Nullable )( uint32_t ) )filter
{
    __block NSArray< SMCData * > * items = @[];

    dispatch_sync
    (
        self.queue,
        ^( void )
        {
            items = [ self readAllKeysUnsynchronized: filter ];
        }
    );

    return items;
}

/*!
 * @method      readAllKeysUnsynchronized:
 * @abstract    Implements @c readAllKeys:; must be called on the serial
 *              @c queue.
 * @param       filter The optional per-key filter block; see @c readAllKeys:.
 * @return      An array of @c SMCData objects for the keys read successfully,
 *              or an empty array if the connection is not open or the
 *              user-client session cannot be opened.
 * @discussion  Opens the user-client session once for the whole batch (via
 *              @c openUserClientSession) and closes it when done, so the
 *              per-key reads do not each pay an open/close round-trip.
 */
- ( NSArray< SMCData * > *  )readAllKeysUnsynchronized: ( BOOL ( ^ _Nullable )( uint32_t ) )filter
{
    if( self.connection == IO_OBJECT_NULL )
    {
        return @[];
    }

    if( [ self openUserClientSession ] == NO )
    {
        return @[];
    }

    if( self.keys.count == 0 )
    {
        uint32_t count = [ self readSMCKeyCount ];

        for( uint32_t i = 0; i < count; i++ )
        {
            uint32_t key = 0;

            if( [ self readSMCKey: &key atIndex: i ] == NO )
            {
                continue;
            }

            if( key != 0 )
            {
                [ self.keys addObject: [ NSNumber numberWithUnsignedInt: key ] ];
            }
        }
    }

    NSMutableArray< SMCData * > * items = [ [ NSMutableArray alloc ] initWithCapacity: self.keys.count ];

    for( NSNumber * key in self.keys )
    {
        if( filter != nil && filter( key.unsignedIntValue ) == NO )
        {
            continue;
        }

        SMCKeyInfoData info;
        uint8_t        data[ 32 ];
        uint32_t       size = sizeof( data );

        if( [ self readSMCKey: key.unsignedIntValue buffer: data maxSize: &size keyInfo: &info ] == NO )
        {
            continue;
        }

        SMCData * item = [ [ SMCData alloc ] initWithKey: key.unsignedIntValue type: info.dataType data: [ NSData dataWithBytes: data length: size ] ];

        [ items addObject: item ];
    }

    [ self closeUserClientSession ];

    return items;
}

/*!
 * @method      open:
 * @abstract    Opens the connection to the @c AppleSMC IOKit service.
 * @param       error On failure, set to an @c NSError describing the problem.
 *                    May be @c NULL.
 * @return      @c YES if the connection is open (or was already open),
 *              otherwise @c NO.
 */
- ( BOOL )open: ( NSError * _Nullable __autoreleasing * )error
{
    if( self.connection != IO_OBJECT_NULL )
    {
        return YES;
    }

    io_service_t smc = IOServiceGetMatchingService( kIOMasterPortDefault, IOServiceMatching( "AppleSMC" ) );

    if( smc == IO_OBJECT_NULL )
    {
        if( error )
        {
            *( error ) = [ SMCHelper errorWithTitle: @"Cannot Open SMC" message: @"Unable to retrieve the SMC service." code: -1 ];
        }

        return NO;
    }

    io_connect_t  connection = IO_OBJECT_NULL;
    kern_return_t result     = IOServiceOpen( smc, mach_task_self(), 0, &connection );

    if( result != kIOReturnSuccess || connection == IO_OBJECT_NULL )
    {
        if( error )
        {
            *( error ) = [ SMCHelper errorWithTitle: @"Cannot Open SMC" message: @"Unable to open the SMC service." code: -1 ];
        }

        return NO;
    }

    self.connection = connection;

    return YES;
}

/*!
 * @method      close
 * @abstract    Closes the connection to the @c AppleSMC IOKit service.
 * @return      @c YES if the connection is closed (or was already closed),
 *              otherwise @c NO.
 */
- ( BOOL )close
{
    if( self.connection == IO_OBJECT_NULL )
    {
        return YES;
    }

    if( IOServiceClose( self.connection ) != kIOReturnSuccess )
    {
        return NO;
    }

    self.connection = IO_OBJECT_NULL;

    return YES;
}

/*!
 * @method      callSMCFunction:input:output:
 * @abstract    Performs a single structured call against the SMC user client.
 * @param       function The SMC selector to invoke (e.g. @c kSMCHandleYPCEvent).
 * @param       input    The populated request structure.
 * @param       output   On return, the response structure from the SMC.
 * @return      @c YES on success, otherwise @c NO.
 * @discussion  Dispatches the structured call on the already-open user-client
 *              session. The session is opened once around a batch of reads by
 *              @c readAllKeys: (via @c openUserClientSession), not around each
 *              call, so this method does not open or close it.
 */
- ( BOOL )callSMCFunction: ( uint32_t )function input: ( const SMCParamStruct * )input output: ( SMCParamStruct * )output
{
    size_t        inputSize  = sizeof( SMCParamStruct );
    size_t        outputSize = sizeof( SMCParamStruct );
    kern_return_t result     = IOConnectCallStructMethod( self.connection, function, input, inputSize, output, &outputSize );

    return result == kIOReturnSuccess;
}

/*!
 * @method      openUserClientSession
 * @abstract    Opens a session on the SMC user client.
 * @return      @c YES on success, otherwise @c NO.
 * @discussion  Sends @c kSMCUserClientOpen on @c connection. Called once around
 *              a batch of reads by @c readAllKeys: rather than around every
 *              structured call, avoiding the many redundant open/close
 *              round-trips a full enumeration would otherwise perform. Must be
 *              balanced by @c closeUserClientSession.
 */
- ( BOOL )openUserClientSession
{
    return IOConnectCallMethod( self.connection, kSMCUserClientOpen, NULL, 0, NULL, 0, NULL, NULL, NULL, NULL ) == kIOReturnSuccess;
}

/*!
 * @method      closeUserClientSession
 * @abstract    Closes the session opened by @c openUserClientSession.
 * @discussion  Sends @c kSMCUserClientClose on @c connection, balancing a prior
 *              successful @c openUserClientSession at the end of a batch.
 */
- ( void )closeUserClientSession
{
    IOConnectCallMethod( self.connection, kSMCUserClientClose, NULL, 0, NULL, 0, NULL, NULL, NULL, NULL );
}

/*!
 * @method      readSMCKeyInfo:forKey:
 * @abstract    Retrieves the metadata (size, type, attributes) for a key.
 * @param       info On return, the metadata for the key.
 * @param       key  The key code to query.
 * @return      @c YES on success, otherwise @c NO.
 * @discussion  Results are cached in @c keyInfoCache; a cached entry is served
 *              without contacting the SMC.
 */
- ( BOOL )readSMCKeyInfo: ( SMCKeyInfoData * )info forKey: ( uint32_t )key
{
    if( info == NULL || key == 0 )
    {
        return NO;
    }

    {
        NSValue * cached = self.keyInfoCache[ [ NSNumber numberWithUnsignedInt: key ] ];

        if( cached != nil )
        {
            [ cached getValue: info size: sizeof( SMCKeyInfoData ) ];

            return YES;
        }
    }

    SMCParamStruct input;
    SMCParamStruct output;

    bzero( &input, sizeof( SMCParamStruct ) );
    bzero( &output, sizeof( SMCParamStruct ) );

    input.data8 = kSMCGetKeyInfo;
    input.key   = key;

    if( [ self callSMCFunction: kSMCHandleYPCEvent input: &input output: &output ] == NO )
    {
        return NO;
    }

    if( output.result != kSMCSuccess )
    {
        return NO;
    }

    *( info ) = output.keyInfo;

    self.keyInfoCache[ [ NSNumber numberWithUnsignedInt: key ] ] = [ NSValue valueWithBytes: &( output.keyInfo ) objCType: @encode( SMCKeyInfoData ) ];

    return YES;
}

/*!
 * @method      readSMCKey:atIndex:
 * @abstract    Retrieves the key code located at a given enumeration index.
 * @param       key   On return, the key code at the requested index.
 * @param       index The zero-based index into the SMC key table.
 * @return      @c YES on success, otherwise @c NO.
 */
- ( BOOL )readSMCKey: ( uint32_t * )key atIndex: ( uint32_t )index
{
    if( key == NULL )
    {
        return NO;
    }

    SMCParamStruct input;
    SMCParamStruct output;

    bzero( &input, sizeof( SMCParamStruct ) );
    bzero( &output, sizeof( SMCParamStruct ) );

    input.data8  = kSMCGetKeyFromIndex;
    input.data32 = index;

    if( [ self callSMCFunction: kSMCHandleYPCEvent input: &input output: &output ] == NO )
    {
        return NO;
    }

    if( output.result != kSMCSuccess )
    {
        return NO;
    }

    *( key ) = output.key;

    return YES;
}

/*!
 * @method      readSMCKey:buffer:maxSize:keyInfo:
 * @abstract    Reads the raw value of a key into a caller-provided buffer.
 * @param       key     The key code to read.
 * @param       buffer  The destination buffer for the value bytes.
 * @param       maxSize On input, the capacity of @c buffer; on output, the
 *                      number of bytes written.
 * @param       keyInfo On return, the key's metadata. May be @c NULL.
 * @return      @c YES on success, otherwise @c NO (including when @c buffer is
 *              too small to hold the value).
 * @discussion  The value bytes are reversed from the SMC's big-endian ordering
 *              into little-endian, except for @c kSMCKeyACID which is copied
 *              verbatim.
 */
- ( BOOL )readSMCKey: ( uint32_t )key buffer: ( uint8_t * )buffer maxSize: ( uint32_t * )maxSize keyInfo: ( SMCKeyInfoData * _Nullable )keyInfo
{
    if( key == 0 || buffer == NULL || maxSize == NULL )
    {
        return NO;
    }

    SMCKeyInfoData info;

    if( [ self readSMCKeyInfo: &info forKey: key ] == NO )
    {
        return NO;
    }

    SMCParamStruct input;
    SMCParamStruct output;

    bzero( &input, sizeof( SMCParamStruct ) );
    bzero( &output, sizeof( SMCParamStruct ) );

    input.key              = key;
    input.data8            = kSMCReadKey;
    input.keyInfo.dataSize = info.dataSize;

    if( [ self callSMCFunction: kSMCHandleYPCEvent input: &input output: &output ] == NO )
    {
        return NO;
    }

    if( output.result != kSMCSuccess )
    {
        return NO;
    }

    if( *( maxSize ) < info.dataSize )
    {
        return NO;
    }

    if( keyInfo != NULL )
    {
        *( keyInfo ) = info;
    }

    *( maxSize ) = info.dataSize;

    bzero( buffer, *( maxSize ) );

    for( uint32_t i = 0; i < info.dataSize; i++ )
    {
        if( key == kSMCKeyACID )
        {
            buffer[ i ] = output.bytes[ i ];
        }
        else
        {
            buffer[ i ] = output.bytes[ info.dataSize - ( i + 1 ) ];
        }
    }

    return YES;
}

/*!
 * @method      readSMCKeyCount
 * @abstract    Reads the total number of keys exposed by the SMC.
 * @return      The number of keys, or @c 0 on failure.
 * @discussion  Reads the value of @c kSMCKeyNKEY and decodes it as an integer.
 */
- ( uint32_t )readSMCKeyCount
{
    uint8_t  data[ 8 ];
    uint32_t size = sizeof( data );

    bzero( data, size );

    if( [ self readSMCKey: kSMCKeyNKEY buffer: data maxSize: &size keyInfo: NULL ] == NO )
    {
        return 0;
    }

    return [ self readInteger: data size: size ];
}

/*!
 * @method      readInteger:size:
 * @abstract    Decodes a little-endian unsigned integer from a byte buffer.
 * @param       data The buffer holding the value bytes.
 * @param       size The number of bytes to decode; must not exceed
 *                   @c sizeof( uint32_t ).
 * @return      The decoded value, or @c 0 if @c size is too large.
 */
- ( uint32_t )readInteger: ( uint8_t * )data size: ( uint32_t )size
{
    uint32_t n = 0;

    if( size > sizeof( uint32_t ) )
    {
        return 0;
    }

    for( uint32_t i = 0; i < size; i++ )
    {
        n |= ( uint32_t )( data[ i ] ) << ( i * 8 );
    }

    return n;
}

@end
