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

NS_ASSUME_NONNULL_BEGIN

/*!
 * @class       SMCException
 * @abstract    A helper bridging Objective-C exceptions to @c NSError values.
 * @discussion  Objective-C exceptions cannot be caught from Swift. This helper
 *              runs a block inside an @c \@try / \@catch and converts any raised
 *              @c NSException into an @c NSError, allowing Swift callers to
 *              recover from exceptions thrown by lower-level APIs.
 */
@interface SMCException: NSObject

/*!
 * @method      init
 * @abstract    Unavailable; @c SMCException is not meant to be instantiated.
 * @discussion  The class exposes only class methods.
 */
- ( instancetype )init NS_UNAVAILABLE;

/*!
 * @method      doTry:error:
 * @abstract    Executes a block, capturing any Objective-C exception as an error.
 * @param       block The block to execute. Passing @c NULL is a no-op that
 *                    succeeds.
 * @param       error On return, if an exception was caught, set to an
 *                    @c NSError describing it. May be @c NULL.
 * @return      @c YES if the block completed without raising an exception,
 *              otherwise @c NO.
 */
+ ( BOOL )doTry: ( void ( ^ )( void ) )block error: ( NSError * __autoreleasing * )error;

@end

NS_ASSUME_NONNULL_END
