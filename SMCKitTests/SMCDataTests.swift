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
import Testing
@testable import SMCKit

/// Unit tests for ``SMCData``, which decodes a raw SMC key/value pair.
@Suite( "SMCData" )
struct SMCDataTests
{
    /// The initializer stores the raw key, type and data, and derives their
    /// four-character-code names.
    @Test( "init stores raw values and derives names" )
    func initStoresRawValuesAndNames()
    {
        let data = SMCData( key: 0x234B4559, type: 0x75693820, data: Data( [ 0x2A ] ) )

        #expect( data.key      == 0x234B4559 )
        #expect( data.type     == 0x75693820 )
        #expect( data.data     == Data( [ 0x2A ] ) )
        #expect( data.keyName  == "#KEY" )
        #expect( data.typeName == "ui8 " )
    }

    /// A single-byte unsigned value is decoded into ``SMCData/value``.
    @Test( "init decodes an unsigned 8-bit value" )
    func initDecodesUInt8Value()
    {
        let data = SMCData( key: 0x54433050, type: 0x75693820, data: Data( [ 0x2A ] ) ) // "TC0P" / "ui8 "

        #expect( data.value as? UInt8 == 42 )
    }

    /// A flag value is decoded into a boolean.
    @Test( "init decodes a flag value" )
    func initDecodesFlagValue()
    {
        let on  = SMCData( key: 0x464E756D, type: 0x666C6167, data: Data( [ 0x01 ] ) ) // type "flag"
        let off = SMCData( key: 0x464E756D, type: 0x666C6167, data: Data( [ 0x00 ] ) )

        #expect( on.value  as? Bool == true )
        #expect( off.value as? Bool == false )
    }

    /// A C-string value is decoded from the reversed bytes.
    @Test( "init decodes a ch8* string value" )
    func initDecodesStringValue()
    {
        let data = SMCData( key: 0x234B4559, type: 0x6368382A, data: Data( [ 0x42, 0x41 ] ) ) // type "ch8*"

        #expect( data.value as? String == "AB" )
    }

    /// An unrecognized type leaves ``SMCData/value`` `nil` while still exposing
    /// the raw data.
    @Test( "init leaves value nil for an unknown type" )
    func initUnknownTypeLeavesValueNil()
    {
        let data = SMCData( key: 0x234B4559, type: 0x00000000, data: Data( [ 0x01, 0x02 ] ) )

        #expect( data.value == nil )
        #expect( data.data  == Data( [ 0x01, 0x02 ] ) )
    }
}
