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

#import "SMCHelper.h"

@implementation SMCHelper

+ ( NSString * )fourCCString: ( uint32_t )value
{
    uint8_t c1 = ( uint8_t )( ( value >> 24 ) & 0xFF );
    uint8_t c2 = ( uint8_t )( ( value >> 16 ) & 0xFF );
    uint8_t c3 = ( uint8_t )( ( value >>  8 ) & 0xFF );
    uint8_t c4 = ( uint8_t )( ( value >>  0 ) & 0xFF );

    return [ NSString stringWithFormat: @"%c%c%c%c", c1, c2, c3, c4 ];
}

+ ( uint32_t )fourCC: ( NSString * )value
{
    NSString   * padded = [ value stringByPaddingToLength: 4 withString: @"\0" startingAtIndex: 0 ];
    const char * cp     = padded.UTF8String;
    uint32_t      c1    = ( uint32_t )cp[ 0 ];
    uint32_t      c2    = ( uint32_t )cp[ 1 ];
    uint32_t      c3    = ( uint32_t )cp[ 2 ];
    uint32_t      c4    = ( uint32_t )cp[ 3 ];

    return ( c1 << 24 ) | ( c2 << 16 ) | ( c3 << 8 ) | c4;
}

+ ( int8_t )int8: ( NSData * )data
{
    return ( int8_t )[ self uint8: data ];
}

+ ( int16_t )int16: ( NSData * )data
{
    return ( int16_t )[ self uint16: data ];
}

+ ( int32_t )int32: ( NSData * )data
{
    return ( int32_t )[ self uint32: data ];
}

+ ( int64_t )int64: ( NSData * )data
{
    return ( int64_t )[ self uint64: data ];
}

+ ( uint8_t )uint8: ( NSData * )data
{
    if( data.length != 1 )
    {
        return 0;
    }

    const uint8_t * bytes = data.bytes;

    return bytes[ 0 ];
}

+ ( uint16_t )uint16: ( NSData * )data
{
    if( data.length != 2 )
    {
        return 0;
    }

    const uint8_t * bytes = data.bytes;

    uint16_t u1 = ( uint16_t )( ( uint16_t )bytes[ 0 ] << 8 );
    uint16_t u2 = ( uint16_t )( ( uint16_t )bytes[ 1 ] << 0 );

    return u1 | u2;
}

+ ( uint32_t )uint32: ( NSData * )data
{
    if( data.length != 4 )
    {
        return 0;
    }

    const uint8_t * bytes = data.bytes;

    uint32_t u1 = ( uint32_t )bytes[ 0 ] << 24;
    uint32_t u2 = ( uint32_t )bytes[ 1 ] << 16;
    uint32_t u3 = ( uint32_t )bytes[ 2 ] <<  8;
    uint32_t u4 = ( uint32_t )bytes[ 3 ] <<  0;

    return u1 | u2 | u3 | u4;
}

+ ( uint64_t )uint64: ( NSData * )data
{
    if( data.length != 8 )
    {
        return 0;
    }

    const uint8_t * bytes = data.bytes;

    uint64_t u1 = ( uint64_t )bytes[ 0 ] << 56;
    uint64_t u2 = ( uint64_t )bytes[ 1 ] << 48;
    uint64_t u3 = ( uint64_t )bytes[ 2 ] << 40;
    uint64_t u4 = ( uint64_t )bytes[ 3 ] << 32;
    uint64_t u5 = ( uint64_t )bytes[ 4 ] << 24;
    uint64_t u6 = ( uint64_t )bytes[ 5 ] << 16;
    uint64_t u7 = ( uint64_t )bytes[ 6 ] <<  8;
    uint64_t u8 = ( uint64_t )bytes[ 7 ] <<  0;

    return u1 | u2 | u3 | u4 | u5 | u6 | u7 | u8;
}

+ ( float )float32: ( NSData * )data
{
    return ( float )[ self uint32: data ];
}

+ ( double )float64: ( NSData * )data
{
    return ( double )[ self uint64: data ];
}

+ ( double )ioFloat: ( NSData * )data
{
    if( data.length != 8 )
    {
        return 0;
    }

    uint64_t u64      = [ self uint64: data ];
    double integral   = ( double )( u64 >> 16 );
    double mask       = pow( 2.0, 16.0 ) - 1.0;
    double fractional = ( double )( u64 & ( uint64_t )mask ) / ( double )( 1 << 16 );

    return integral + fractional;
}

+ ( double )sp78: ( NSData * )data
{
    if( data.length != 2 )
    {
        return 0;
    }

    const uint8_t * bytes = data.bytes;

    double b1 = ( double )( bytes[ 1 ] & 0x7F );
    double b2 = ( double )( bytes[ 0 ] ) / ( double )( 1 << 8 );

    return b1 + b2;
}

+ ( nullable NSData * )reversedData: ( NSData * )data
{
    if( data.length <= 1 )
    {
        return data;
    }

    const uint8_t * bytes    = data.bytes;
    uint8_t       * reversed = malloc( data.length );

    if( reversed == nil )
    {
        return nil;
    }

    for( NSUInteger i = 0; i < data.length; i++ )
    {
        reversed[ data.length - ( i + 1 ) ] = bytes[ i ];
    }

    return [ NSData dataWithBytesNoCopy: reversed length: data.length freeWhenDone: YES ];
}

+ ( nullable NSString * )stringWithData: ( NSData * )data
{
    NSData * reversed = [ self reversedData: data ];

    if( reversed == nil )
    {
        return nil;
    }

    return [ [ NSString alloc ] initWithData: reversed encoding: NSUTF8StringEncoding ];
}

+ ( nullable NSString * )printableStringWithData: ( NSData * )data
{
    NSData * reversed = [ self reversedData: data ];

    if( reversed == nil )
    {
        return nil;
    }

    NSMutableString * str   = [ NSMutableString new ];
    const char      * bytes = reversed.bytes;

    for( NSUInteger i = 0; i < data.length; i++ )
    {
        [ str appendFormat: @"%c", ( isprint( bytes[ i ] ) ? bytes[ i ] : '.' ) ];
    }

    return str;
}

+ ( nullable id )valueForData: ( NSData * )data type: ( uint32_t )type
{
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wfour-char-constants"

    switch( type )
    {
        case 'si8 ': return [ NSNumber numberWithChar:     [ self int8:  data ] ];
        case 'si16': return [ NSNumber numberWithShort:    [ self int16: data ] ];
        case 'si32': return [ NSNumber numberWithInt:      [ self int32: data ] ];
        case 'si64': return [ NSNumber numberWithLongLong: [ self int64: data ] ];

        case 'ui8 ': return [ NSNumber numberWithUnsignedChar:     [ self uint8:  data ] ];
        case 'ui16': return [ NSNumber numberWithUnsignedShort:    [ self uint16: data ] ];
        case 'ui32': return [ NSNumber numberWithUnsignedInt:      [ self uint32: data ] ];
        case 'ui64': return [ NSNumber numberWithUnsignedLongLong: [ self uint64: data ] ];

        case 'flt ': return [ NSNumber numberWithFloat:  [ self float32: data ] ];
        case 'ioft': return [ NSNumber numberWithDouble: [ self ioFloat: data ] ];
        case 'sp78': return [ NSNumber numberWithDouble: [ self sp78:    data ] ];

        case 'flag': return [ NSNumber numberWithBool: [ self uint8: data ] == 1 ];

        case 'ch8*': return [ self stringWithData: data ];

        default:     return nil;
    }

    #pragma clang diagnostic pop
}

+ ( NSError * )errorWithTitle: ( NSString * )title message: ( NSString * )message code: ( NSInteger )code
{
    NSDictionary * info =
    @{
        NSLocalizedDescriptionKey:             title,
        NSLocalizedRecoverySuggestionErrorKey: message
    };

    return [ [ NSError alloc ] initWithDomain: NSCocoaErrorDomain code: code userInfo: info ];
}

@end
