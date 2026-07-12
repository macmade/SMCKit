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

import Foundation

/// A collection of stateless helpers for decoding SMC values and building
/// errors.
///
/// The SMC stores its values as raw byte buffers in big-endian order, tagged
/// with a four-character type code. This class turns those buffers into native
/// Swift values and provides convenience factories for `NSError`.
@objc
public class SMCHelper: NSObject
{
    /// Unavailable; `SMCHelper` exposes only class methods.
    private override init()
    {}

    /// Renders a 32-bit value as a four-character-code string.
    ///
    /// - Parameter value: The 32-bit value to render.
    /// - Returns: A four-character string built from the value's bytes.
    @objc( fourCC: )
    public class func fourCC( value: UInt32 ) -> String
    {
        let c1 = UInt8( ( value >> 24 ) & 0xFF )
        let c2 = UInt8( ( value >> 16 ) & 0xFF )
        let c3 = UInt8( ( value >>  8 ) & 0xFF )
        let c4 = UInt8( ( value >>  0 ) & 0xFF )

        return String( format: "%c%c%c%c", c1, c2, c3, c4 )
    }

    /// Decodes raw SMC bytes into a native value according to their type code.
    ///
    /// The buffer handed in here has already had its bytes reversed by
    /// `SMC.m -readSMCKey:buffer:maxSize:keyInfo:` (from the SMC's big-endian
    /// order into little-endian), so the multi-byte types need to undo that
    /// reversal. The integer cases do so with `.byteSwapped`; `sp78`
    /// compensates through its byte indexing.
    ///
    /// The `flt` and `ioft` cases deliberately do **not** apply a byte swap.
    /// This asymmetry with the integer cases is intentional and has been
    /// verified against live values on real hardware (Apple Silicon): the
    /// current decoding yields the correct floating-point results, whereas
    /// adding a `.byteSwapped` compensation turns them into IEEE denormals or
    /// absurd magnitudes. Do not "align" `flt`/`ioft` with the integer cases —
    /// see the regression test `valueDecodesReversedMultiByteTypes`.
    ///
    /// - Parameters:
    ///   - data: The raw value bytes.
    ///   - type: The SMC type code identifying how to interpret the bytes.
    /// - Returns: The decoded value (an integer, floating-point number, `Bool`
    ///   or `String` depending on the type), or `nil` when the type is not
    ///   recognized.
    @objc( valueForData:type: )
    public class func value( for data: Data, type: UInt32 ) -> Any?
    {
        switch self.fourCC( value: type )
        {
            case "si8 ": return self.int8(  data: data )
            case "si16": return self.int16( data: data ).byteSwapped
            case "si32": return self.int32( data: data ).byteSwapped
            case "si64": return self.int64( data: data ).byteSwapped

            case "ui8 ": return self.uint8(  data: data )
            case "ui16": return self.uint16( data: data ).byteSwapped
            case "ui32": return self.uint32( data: data ).byteSwapped
            case "ui64": return self.uint64( data: data ).byteSwapped

            case "flt ": return self.float32( data: data )
            case "ioft": return self.ioFloat( data: data )
            case "sp78": return self.sp78(    data: data )

            case "flag": return self.uint8( data: data ) == 1 ? true : false

            case "ch8*": return self.string( data: data )

            default:     return nil
        }
    }

    /// Decodes a signed 8-bit integer from a byte buffer.
    ///
    /// - Parameter data: The raw value bytes; must contain exactly one byte.
    /// - Returns: The decoded value, or `0` if the buffer size is wrong.
    @objc( int8: )
    public class func int8( data: Data ) -> Int8
    {
        Int8( bitPattern: self.uint8( data: data ) )
    }

    /// Decodes a signed, big-endian 16-bit integer from a byte buffer.
    ///
    /// - Parameter data: The raw value bytes; must contain exactly two bytes.
    /// - Returns: The decoded value, or `0` if the buffer size is wrong.
    @objc( int16: )
    public class func int16( data: Data ) -> Int16
    {
        Int16( bitPattern: self.uint16( data: data ) )
    }

    /// Decodes a signed, big-endian 32-bit integer from a byte buffer.
    ///
    /// - Parameter data: The raw value bytes; must contain exactly four bytes.
    /// - Returns: The decoded value, or `0` if the buffer size is wrong.
    @objc( int32: )
    public class func int32( data: Data ) -> Int32
    {
        Int32( bitPattern: self.uint32( data: data ) )
    }

    /// Decodes a signed, big-endian 64-bit integer from a byte buffer.
    ///
    /// - Parameter data: The raw value bytes; must contain exactly eight bytes.
    /// - Returns: The decoded value, or `0` if the buffer size is wrong.
    @objc( int64: )
    public class func int64( data: Data ) -> Int64
    {
        Int64( bitPattern: self.uint64( data: data ) )
    }

    /// Decodes an unsigned 8-bit integer from a byte buffer.
    ///
    /// - Parameter data: The raw value bytes; must contain exactly one byte.
    /// - Returns: The decoded value, or `0` if the buffer size is wrong.
    @objc( uint8: )
    public class func uint8( data: Data ) -> UInt8
    {
        guard data.count == 1
        else
        {
            return 0
        }

        return UInt8( data[ 0 ] )
    }

    /// Decodes an unsigned, big-endian 16-bit integer from a byte buffer.
    ///
    /// - Parameter data: The raw value bytes; must contain exactly two bytes.
    /// - Returns: The decoded value, or `0` if the buffer size is wrong.
    @objc( uint16: )
    public class func uint16( data: Data ) -> UInt16
    {
        guard data.count == 2
        else
        {
            return 0
        }

        let u1 = UInt16( data[ 0 ] ) << 8
        let u2 = UInt16( data[ 1 ] ) << 0

        return u1 | u2
    }

    /// Decodes an unsigned, big-endian 32-bit integer from a byte buffer.
    ///
    /// - Parameter data: The raw value bytes; must contain exactly four bytes.
    /// - Returns: The decoded value, or `0` if the buffer size is wrong.
    @objc( uint32: )
    public class func uint32( data: Data ) -> UInt32
    {
        guard data.count == 4
        else
        {
            return 0
        }

        let u1 = UInt32( data[ 0 ] ) << 24
        let u2 = UInt32( data[ 1 ] ) << 16
        let u3 = UInt32( data[ 2 ] ) <<  8
        let u4 = UInt32( data[ 3 ] ) <<  0

        return u1 | u2 | u3 | u4
    }

    /// Decodes an unsigned, big-endian 64-bit integer from a byte buffer.
    ///
    /// - Parameter data: The raw value bytes; must contain exactly eight bytes.
    /// - Returns: The decoded value, or `0` if the buffer size is wrong.
    @objc( uint64: )
    public class func uint64( data: Data ) -> UInt64
    {
        guard data.count == 8
        else
        {
            return 0
        }

        let u1 = UInt64( data[ 0 ] ) << 56
        let u2 = UInt64( data[ 1 ] ) << 48
        let u3 = UInt64( data[ 2 ] ) << 40
        let u4 = UInt64( data[ 3 ] ) << 32
        let u5 = UInt64( data[ 4 ] ) << 24
        let u6 = UInt64( data[ 5 ] ) << 16
        let u7 = UInt64( data[ 6 ] ) <<  8
        let u8 = UInt64( data[ 7 ] ) <<  0

        return u1 | u2 | u3 | u4 | u5 | u6 | u7 | u8
    }

    /// Decodes a 32-bit IEEE-754 floating-point value from a byte buffer.
    ///
    /// - Parameter data: The raw value bytes; must contain exactly four bytes.
    /// - Returns: The decoded value, or `0` if the buffer size is wrong.
    @objc( float32: )
    public class func float32( data: Data ) -> Float32
    {
        Float32( bitPattern: self.uint32( data: data ) )
    }

    /// Decodes a 64-bit IEEE-754 floating-point value from a byte buffer.
    ///
    /// - Parameter data: The raw value bytes; must contain exactly eight bytes.
    /// - Returns: The decoded value, or `0` if the buffer size is wrong.
    @objc( float64: )
    public class func float64( data: Data ) -> Float64
    {
        Float64( bitPattern: self.uint64( data: data ) )
    }

    /// Decodes an SMC `ioft` fixed-point value from a byte buffer.
    ///
    /// The value is a 64-bit quantity split into a 48-bit integral part and a
    /// 16-bit fractional part.
    ///
    /// - Parameter data: The raw value bytes; must contain exactly eight bytes.
    /// - Returns: The decoded value, or `0` if the buffer size is wrong.
    @objc( ioFloat: )
    public class func ioFloat( data: Data ) -> Double
    {
        guard data.count == 8
        else
        {
            return 0
        }

        let u64        = self.uint64( data: data )
        let integral   = Double( u64 >> 16 )
        let mask       = pow( 2.0, 16.0 ) - 1
        let fractional = Double( u64 & UInt64( mask ) ) / Double( 1 << 16 )

        return integral + fractional
    }

    /// Decodes an SMC `sp78` signed fixed-point value from a byte buffer.
    ///
    /// The value uses a sign/7-bit integral high byte and an 8-bit fractional
    /// low byte, as commonly used for temperature readings.
    ///
    /// - Parameter data: The raw value bytes; must contain exactly two bytes.
    /// - Returns: The decoded value, or `0` if the buffer size is wrong.
    @objc( sp78: )
    public class func sp78( data: Data ) -> Double
    {
        guard data.count == 2
        else
        {
            return 0
        }

        let b1 = Double( data[ 1 ] & 0x7F )
        let b2 = Double( data[ 0 ] ) / Double( 1 << 8 )

        return b1 + b2
    }

    /// Decodes a UTF-8 string from a byte buffer.
    ///
    /// The bytes are reversed before decoding, matching the SMC's byte order.
    ///
    /// - Parameter data: The raw value bytes.
    /// - Returns: The decoded string, or `nil` if the buffer is empty or is not
    ///   valid UTF-8.
    @objc( string: )
    public class func string( data: Data ) -> String?
    {
        guard data.count > 0
        else
        {
            return nil
        }

        return String( data: Data( data.reversed() ), encoding: .utf8 )
    }

    /// Builds a printable representation of a byte buffer.
    ///
    /// The bytes are reversed to match the SMC's byte order, and any
    /// non-printable byte is replaced with a dot (`.`). A trailing `NUL`
    /// terminator is appended when needed.
    ///
    /// - Parameter data: The raw value bytes.
    /// - Returns: The printable string, or `nil` if the buffer is empty.
    @objc( printableString: )
    public class func printableString( data: Data ) -> String?
    {
        var characters = data.reversed().map { isprint( Int32( $0 ) ) == 0 ? 46 : $0 }

        guard let last = characters.last
        else
        {
            return nil
        }

        if last != 0
        {
            characters.append( 0 )
        }

        return String( cString: characters )
    }

    /// Creates an error with a localized title and recovery message.
    ///
    /// - Parameters:
    ///   - title:   The localized description of the error.
    ///   - message: The localized recovery suggestion.
    ///   - code:    The error code.
    /// - Returns: An `NSError` in the Cocoa error domain.
    @objc
    public class func error( title: String, message: String, code: Int ) -> NSError
    {
        let info = [ NSLocalizedDescriptionKey: title, NSLocalizedRecoverySuggestionErrorKey: message ]

        return NSError( domain: NSCocoaErrorDomain, code: code, userInfo: info )
    }

    /// Creates an error from an Objective-C exception.
    ///
    /// The exception's name becomes the localized description and its reason,
    /// when present, becomes the recovery suggestion.
    ///
    /// - Parameter exception: The exception to convert.
    /// - Returns: An `NSError` in the Cocoa error domain.
    @objc
    public class func error( exception: NSException ) -> NSError
    {
        var info: [ String: Any ] = [ NSLocalizedDescriptionKey: exception.name ]

        if let reason = exception.reason
        {
            info[ NSLocalizedRecoverySuggestionErrorKey ] = reason
        }

        return NSError( domain: NSCocoaErrorDomain, code: 0, userInfo: info )
    }
}
