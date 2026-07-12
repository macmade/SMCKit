/*******************************************************************************
 * The MIT License (MIT)
 *
 * Copyright (c) 2026, Jean-David Gadina - www.xs-labs.com
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

import Foundation
@testable import SMCKit
import Testing

/// Unit tests for the value-decoding helpers in ``SMCHelper``.
@Suite( "SMCHelper" )
struct SMCHelperTests
{
    // MARK: - Four-character codes

    /// A four-character-code value is rendered from its bytes, most significant
    /// byte first.
    @Test( "fourCC renders a value as a four-character string" )
    func fourCC()
    {
        #expect( SMCHelper.fourCC( value: 0x234B4559 ) == "#KEY" )
        #expect( SMCHelper.fourCC( value: 0x75693332 ) == "ui32" )
        #expect( SMCHelper.fourCC( value: 0x666C6167 ) == "flag" )
    }

    // MARK: - Unsigned integers

    /// An 8-bit unsigned integer is read from a single byte.
    @Test( "uint8 decodes a single byte" )
    func uint8()
    {
        #expect( SMCHelper.uint8( data: Data( [ 0x2A ] ) ) == 42 )
        #expect( SMCHelper.uint8( data: Data( [ 0xFF ] ) ) == 255 )
    }

    /// A 16-bit unsigned integer is assembled big-endian from two bytes.
    @Test( "uint16 decodes two big-endian bytes" )
    func uint16()
    {
        #expect( SMCHelper.uint16( data: Data( [ 0x12, 0x34 ] ) ) == 0x1234 )
    }

    /// A 32-bit unsigned integer is assembled big-endian from four bytes.
    @Test( "uint32 decodes four big-endian bytes" )
    func uint32()
    {
        #expect( SMCHelper.uint32( data: Data( [ 0x12, 0x34, 0x56, 0x78 ] ) ) == 0x12345678 )
    }

    /// A 64-bit unsigned integer is assembled big-endian from eight bytes.
    @Test( "uint64 decodes eight big-endian bytes" )
    func uint64()
    {
        #expect( SMCHelper.uint64( data: Data( [ 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08 ] ) ) == 0x0102030405060708 )
    }

    /// Buffers of the wrong length decode to zero rather than reading out of
    /// bounds.
    @Test( "Integer decoders reject wrongly-sized buffers" )
    func integerWrongSizeReturnsZero()
    {
        #expect( SMCHelper.uint8(  data: Data() )                 == 0 )
        #expect( SMCHelper.uint8(  data: Data( [ 0x01, 0x02 ] ) ) == 0 )
        #expect( SMCHelper.uint16( data: Data( [ 0x01 ] ) )       == 0 )
        #expect( SMCHelper.uint32( data: Data( [ 0x01, 0x02 ] ) ) == 0 )
        #expect( SMCHelper.uint64( data: Data( [ 0x01 ] ) )       == 0 )
    }

    // MARK: - Signed integers

    /// Signed integers reinterpret the unsigned bit pattern.
    @Test( "Signed integers reinterpret the unsigned bit pattern" )
    func signedIntegers()
    {
        #expect( SMCHelper.int8(  data: Data( [ 0xFF ] ) )                                     == -1 )
        #expect( SMCHelper.int8(  data: Data( [ 0x80 ] ) )                                     == -128 )
        #expect( SMCHelper.int8(  data: Data( [ 0x7F ] ) )                                     == 127 )
        #expect( SMCHelper.int16( data: Data( [ 0xFF, 0xFF ] ) )                               == -1 )
        #expect( SMCHelper.int16( data: Data( [ 0x80, 0x00 ] ) )                               == -32768 )
        #expect( SMCHelper.int32( data: Data( [ 0xFF, 0xFF, 0xFF, 0xFF ] ) )                   == -1 )
        #expect( SMCHelper.int64( data: Data( [ 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF ] ) ) == -1 )
    }

    // MARK: - Floating-point

    /// A 32-bit IEEE-754 value is decoded from its big-endian bit pattern.
    @Test( "float32 decodes an IEEE-754 single-precision value" )
    func float32()
    {
        #expect( SMCHelper.float32( data: Data( [ 0x3F, 0x80, 0x00, 0x00 ] ) ) == 1.0 )
        #expect( SMCHelper.float32( data: Data( [ 0xC0, 0x00, 0x00, 0x00 ] ) ) == -2.0 )
    }

    /// A 64-bit IEEE-754 value is decoded from its big-endian bit pattern.
    @Test( "float64 decodes an IEEE-754 double-precision value" )
    func float64()
    {
        #expect( SMCHelper.float64( data: Data( [ 0x3F, 0xF0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ] ) ) == 1.0 )
    }

    /// The `ioft` fixed-point format splits a 64-bit value into a 48-bit
    /// integral part and a 16-bit fractional part.
    @Test( "ioFloat decodes the ioft fixed-point format" )
    func ioFloat()
    {
        // 0x18000 = ( 1 << 16 ) | 0x8000 -> 1 + 0.5
        #expect( SMCHelper.ioFloat( data: Data( [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x80, 0x00 ] ) ) == 1.5 )
        #expect( SMCHelper.ioFloat( data: Data( [ 0x01 ] ) )                                           == 0 )
    }

    /// The `sp78` fixed-point format uses the low byte for the integral part
    /// and the high byte for the fractional part.
    @Test( "sp78 decodes the sp78 fixed-point format" )
    func sp78()
    {
        #expect( SMCHelper.sp78( data: Data( [ 0x80, 0x14 ] ) ) == 20.5 )
        #expect( SMCHelper.sp78( data: Data( [ 0x00, 0x19 ] ) ) == 25.0 )
        #expect( SMCHelper.sp78( data: Data( [ 0x14 ] ) )       == 0 )
    }

    // MARK: - Strings

    /// A string is decoded from the reversed byte buffer.
    @Test( "string decodes reversed UTF-8 bytes" )
    func string()
    {
        #expect( SMCHelper.string( data: Data( [ 0x42, 0x41 ] ) ) == "AB" )
        #expect( SMCHelper.string( data: Data() )                 == nil )
    }

    /// Non-printable bytes are replaced with dots in the printable form.
    @Test( "printableString replaces non-printable bytes with dots" )
    func printableString()
    {
        #expect( SMCHelper.printableString( data: Data( [ 0x42, 0x41 ] ) ) == "AB" )
        #expect( SMCHelper.printableString( data: Data( [ 0x41, 0x01 ] ) ) == ".A" )
        #expect( SMCHelper.printableString( data: Data() )                 == nil )
    }

    // MARK: - Typed value decoding

    /// Byte-order-independent types are decoded to their native values.
    @Test( "value decodes single-byte and flag types" )
    func valueForType()
    {
        #expect( SMCHelper.value( for: Data( [ 0x2A ] ), type: 0x75693820 ) as? UInt8 == 42 )    // "ui8 "
        #expect( SMCHelper.value( for: Data( [ 0xFF ] ), type: 0x73693820 ) as? Int8  == -1 )    // "si8 "
        #expect( SMCHelper.value( for: Data( [ 0x01 ] ), type: 0x666C6167 ) as? Bool  == true )  // "flag"
        #expect( SMCHelper.value( for: Data( [ 0x00 ] ), type: 0x666C6167 ) as? Bool  == false ) // "flag"
        #expect( SMCHelper.value( for: Data( [ 0x42, 0x41 ] ), type: 0x6368382A ) as? String == "AB" ) // "ch8*"
    }

    /// The multi-byte types are decoded correctly from the *reversed*
    /// (little-endian) buffers that `SMC.m` hands to ``SMCHelper/value(for:type:)``.
    ///
    /// The `flt`/`ioft` samples are real post-reversal buffers read from an
    /// Apple Silicon SMC (their decoded values are physically-correct sensor
    /// readings). This test is the regression guard for the `flt`/`ioft` byte
    /// order: applying a `.byteSwapped` compensation to those cases — as a
    /// naive symmetry argument with the integer cases would suggest — turns
    /// each of these into an IEEE denormal or an absurd magnitude and fails
    /// here. The integer and `sp78` cases round out the previously-untested
    /// `value(for:type:)` path for the reversed multi-byte types.
    @Test( "value decodes reversed multi-byte buffers" )
    func valueDecodesReversedMultiByteTypes()
    {
        // flt: real post-reversal buffers, chosen for exact representation.
        #expect( SMCHelper.value( for: Data( [ 0x42, 0x10, 0x00, 0x00 ] ), type: 0x666C7420 ) as? Float ==  36.0 )  // TDBP
        #expect( SMCHelper.value( for: Data( [ 0x42, 0xC8, 0x00, 0x00 ] ), type: 0x666C7420 ) as? Float == 100.0 )  // ceU0
        #expect( SMCHelper.value( for: Data( [ 0xC2, 0xC8, 0x00, 0x00 ] ), type: 0x666C7420 ) as? Float == -100.0 ) // cmDd

        // ioft: real post-reversal buffers (whole-degree temperature readings).
        #expect( SMCHelper.value( for: Data( [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x22, 0x00, 0x00 ] ), type: 0x696F6674 ) as? Double == 34.0 ) // TG0H
        #expect( SMCHelper.value( for: Data( [ 0x00, 0x00, 0x00, 0x00, 0x00, 0x21, 0x00, 0x00 ] ), type: 0x696F6674 ) as? Double == 33.0 ) // TG0C

        // Unsigned integers: value() reverses relative to the raw helper, so a
        // reversed buffer decodes to the natural big-endian value.
        #expect( SMCHelper.value( for: Data( [ 0x34, 0x12 ] ),                                     type: 0x75693136 ) as? UInt16 == 0x1234 )             // ui16
        #expect( SMCHelper.value( for: Data( [ 0x78, 0x56, 0x34, 0x12 ] ),                         type: 0x75693332 ) as? UInt32 == 0x12345678 )         // ui32
        #expect( SMCHelper.value( for: Data( [ 0x08, 0x07, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01 ] ), type: 0x75693634 ) as? UInt64 == 0x0102030405060708 ) // ui64

        // sp78: same helper as the raw path, compensating through its indexing.
        #expect( SMCHelper.value( for: Data( [ 0x00, 0x19 ] ), type: 0x73703738 ) as? Double == 25.0 ) // sp78
    }

    /// An unrecognized type code decodes to `nil`.
    @Test( "value returns nil for an unknown type" )
    func valueForUnknownType()
    {
        #expect( SMCHelper.value( for: Data( [ 0x00 ] ), type: 0x00000000 ) == nil )
    }

    // MARK: - Errors

    /// An error built from a title and message carries them as the localized
    /// description and recovery suggestion.
    @Test( "error builds an NSError from a title and message" )
    func errorFromTitleAndMessage()
    {
        let error = SMCHelper.error( title: "Title", message: "Message", code: 42 )

        #expect( error.domain                                                      == NSCocoaErrorDomain )
        #expect( error.code                                                        == 42 )
        #expect( error.localizedDescription                                        == "Title" )
        #expect( error.userInfo[ NSLocalizedRecoverySuggestionErrorKey ] as? String == "Message" )
    }

    /// An error built from an exception carries the exception's reason as its
    /// recovery suggestion and populates a localized description.
    @Test( "error builds an NSError from an exception" )
    func errorFromException()
    {
        let exception = NSException( name: NSExceptionName( "TestException" ), reason: "Because", userInfo: nil )
        let error     = SMCHelper.error( exception: exception )

        #expect( error.domain                                                       == NSCocoaErrorDomain )
        #expect( error.userInfo[ NSLocalizedDescriptionKey ]                        != nil )
        #expect( error.userInfo[ NSLocalizedRecoverySuggestionErrorKey ] as? String == "Because" )
    }
}
