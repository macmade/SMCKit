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

/// Produces a formatted, human-readable dump of every SMC key.
///
/// The dump lists each key alongside its type, data length, decoded value and
/// raw bytes, preceded by a header describing the machine.
@objc
public class SMCDump: NSObject
{
    /// Unavailable; `SMCDump` exposes only class methods.
    private override init()
    {}

    /// Reads every SMC key and renders them as an aligned text table.
    ///
    /// The keys are sorted case-insensitively by name and each column is padded
    /// to a common width. A machine-description header is prepended.
    ///
    /// - Returns: The formatted dump, or an empty string if no keys could be
    ///   read.
    @objc
    public class func produce() -> String
    {
        let data = SMC.shared.readAllKeys().sorted
        {
            $0.keyName.localizedCaseInsensitiveCompare( $1.keyName ) == .orderedAscending
        }

        if data.isEmpty
        {
            return ""
        }

        let descriptions = data.map
        {
            self.description( for: $0 )
        }

        let l1 = descriptions.reduce( 0 ) { max( $0, $1.0.count ) }
        let l2 = descriptions.reduce( 0 ) { max( $0, $1.1.count ) }
        let l3 = descriptions.reduce( 0 ) { max( $0, $1.2.count ) }
        let l4 = descriptions.reduce( 0 ) { max( $0, $1.3.count ) }
        let l5 = descriptions.reduce( 0 ) { max( $0, $1.4.count ) }

        let separator = "".padding( toLength: l1 + l2 + l3 + l4 + l5 + 16, withPad: "#", startingAt: 0 )
        let header    = self.header().map { "# \( $0 )" }.joined( separator: "\n" )
        let lines     = descriptions.map
        {
            let s1 = $0.0.padding( toLength: l1, withPad: " ", startingAt: 0 )
            let s2 = $0.1.padding( toLength: l2, withPad: " ", startingAt: 0 )
            let s3 = $0.2.padding( toLength: l3, withPad: " ", startingAt: 0 )
            let s4 = $0.3.padding( toLength: l4, withPad: " ", startingAt: 0 )
            let s5 = $0.4

            return "\( s1 )\t\( s2 )\t\( s3 )\t\( s4 )\t\( s5 )"
        }
        .joined( separator: "\n" )

        return "\( separator )\n\( header )\n\( separator )\n\( lines )"
    }

    /// Builds the five column strings describing a single key.
    ///
    /// - Parameter data: The key/value pair to describe.
    /// - Returns: A tuple of the key name, type name, data length, decoded
    ///   value and raw byte string.
    private class func description( for data: SMCData ) -> ( String, String, String, String, String )
    {
        (
            data.keyName,
            data.typeName,
            self.dataLengthDescription( for: data ),
            self.valueDescription( for: data ),
            self.dataDescription( for: data )
        )
    }

    /// Renders a key's decoded value as a display string.
    ///
    /// Integers are printed as-is, floating-point values with two decimals,
    /// flags as `True`/`False`, and C strings via their printable form. Unknown
    /// types yield an empty string.
    ///
    /// - Parameter data: The key/value pair whose value to render.
    /// - Returns: The value's display string.
    private class func valueDescription( for data: SMCData ) -> String
    {
        switch data.typeName
        {
            case "si8 ": return "\( data.value as? Int8  ?? 0 )"
            case "si16": return "\( data.value as? Int16 ?? 0 )"
            case "si32": return "\( data.value as? Int32 ?? 0 )"
            case "si64": return "\( data.value as? Int64 ?? 0 )"

            case "ui8 ": return "\( data.value as? UInt8  ?? 0 )"
            case "ui16": return "\( data.value as? UInt16 ?? 0 )"
            case "ui32": return "\( data.value as? UInt32 ?? 0 )"
            case "ui64": return "\( data.value as? UInt64 ?? 0 )"

            case "flt ": return "\( String( format: "%.02f", data.value as? Float  ?? 0 ) )"
            case "ioft": return "\( String( format: "%.02f", data.value as? Double ?? 0 ) )"
            case "sp78": return "\( String( format: "%.02f", data.value as? Double ?? 0 ) )"

            case "flag": return ( data.value as? Bool ?? false ) ? "True" : "False"

            case "ch8*": return SMCHelper.printableString( data: data.data ) ?? ""

            default:     return ""
        }
    }

    /// Renders a key's raw bytes as an uppercase hexadecimal string.
    ///
    /// - Parameter data: The key/value pair whose bytes to render.
    /// - Returns: The concatenated two-digit hexadecimal representation of each
    ///   byte.
    private class func dataDescription( for data: SMCData ) -> String
    {
        var string = ""

        data.data.forEach
        {
            string.append( String( format: "%02X", $0 ) )
        }

        return string
    }

    /// Renders a key's data length with the correct singular/plural unit.
    ///
    /// - Parameter data: The key/value pair whose length to describe.
    /// - Returns: A string such as `"1 byte"` or `"4 bytes"`.
    private class func dataLengthDescription( for data: SMCData ) -> String
    {
        if data.data.count == 1
        {
            return "\( data.data.count ) byte"
        }

        return "\( data.data.count ) bytes"
    }

    /// Builds the lines of the dump header.
    ///
    /// - Returns: The title, a blank spacer line, and the machine-detail lines.
    private class func header() -> [ String ]
    {
        [
            [ "smc-dump" ],
            [ "" ],
            self.headerParts(),
        ]
        .flatMap
        {
            $0
        }
    }

    /// Formats the machine details as aligned `label: value` lines.
    ///
    /// - Returns: One padded line per machine detail.
    private class func headerParts() -> [ String ]
    {
        let all = MachineDetails.all
        let l1  = all.reduce( 0 ) { max( $0, $1.0.count ) }

        return all.map
        {
            let s1 = "\( $0.0 ):".padding( toLength: l1 + 1, withPad: " ", startingAt: 0 )
            let s2 = $0.1

            return "\( s1 )\t\( s2 )"
        }
    }
}
