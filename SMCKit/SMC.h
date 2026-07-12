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

#import <Foundation/Foundation.h>

/*!
 * @class       SMCData
 * @abstract    Represents a single key/value pair read from the SMC.
 * @discussion  Forward-declared here and implemented in Swift; it carries the
 *              key code, its type code and the raw value bytes.
 */
@class SMCData;

NS_ASSUME_NONNULL_BEGIN

/*!
 * @class       SMC
 * @abstract    A high-level interface for reading keys from the macOS System
 *              Management Controller (SMC).
 * @discussion  The SMC exposes hundreds of keys describing hardware sensors and
 *              state (temperatures, fan speeds, voltages, power, ...). This
 *              class opens a connection to the @c AppleSMC IOKit service and
 *              enumerates and reads those keys.
 *
 *              Each instance serializes access to its own connection and
 *              internal caches, so an instance - including the process-wide
 *              @c shared instance - may be used from multiple threads
 *              concurrently. Calls on the same instance are serialized, so a
 *              concurrent call may block until an in-progress one completes.
 */
@interface SMC: NSObject

/*!
 * @property    shared
 * @abstract    A lazily-created, process-wide shared instance.
 * @discussion  The shared instance opens its SMC connection on first access.
 */
@property( class, nonatomic, readonly ) SMC * shared;

/*!
 * @method      init
 * @abstract    Creates a new instance and opens a connection to the SMC.
 * @return      An initialized @c SMC instance.
 * @discussion  Prefer @c shared unless a dedicated connection is required.
 */
- ( instancetype )init;

/*!
 * @method      readAllKeys:
 * @abstract    Reads the value of every SMC key, optionally filtered.
 * @param       filter An optional block invoked with each key code; return
 *                     @c YES to include the key or @c NO to skip it. Pass
 *                     @c nil to read every key.
 * @return      An array of @c SMCData objects for the keys that were read
 *              successfully, or an empty array if the SMC connection is not
 *              open. Keys that fail to read are silently skipped.
 * @discussion  The set of key codes is enumerated and cached on the first call.
 *              Safe to call concurrently; see the class discussion for the
 *              serialization contract.
 */
- ( NSArray< SMCData * > *  )readAllKeys: ( BOOL ( ^ _Nullable )( uint32_t ) )filter;

@end

NS_ASSUME_NONNULL_END
