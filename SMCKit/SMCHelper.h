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

@interface SMCHelper: NSObject

- ( instancetype )init NS_UNAVAILABLE;

+ ( NSString * )fourCCString: ( uint32_t )value;
+ ( uint32_t )fourCC: ( NSString * )value;

+ ( int8_t  )int8:  ( NSData * )data;
+ ( int16_t )int16: ( NSData * )data;
+ ( int32_t )int32: ( NSData * )data;
+ ( int64_t )int64: ( NSData * )data;

+ ( uint8_t  )uint8:  ( NSData * )data;
+ ( uint16_t )uint16: ( NSData * )data;
+ ( uint32_t )uint32: ( NSData * )data;
+ ( uint64_t )uint64: ( NSData * )data;

+ ( float  )float32: ( NSData * )data;
+ ( double )float64: ( NSData * )data;
+ ( double )ioFloat: ( NSData * )data;
+ ( double )sp78:    ( NSData * )data;

+ ( nullable NSData * )reversedData: ( NSData * )data;
+ ( nullable NSString * )stringWithData: ( NSData * )data;
+ ( nullable id )valueForData: ( NSData * )data type: ( uint32_t )type;

+ ( NSError * )errorWithTitle: ( NSString * )title message: ( NSString * )message code: ( NSInteger )code;

@end

NS_ASSUME_NONNULL_END
