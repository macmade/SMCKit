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

/// Represents a single key/value pair read from the SMC.
///
/// An `SMCData` object bundles the raw key and type codes, the raw value
/// bytes, their human-readable four-character-code representations, and the
/// value decoded into a native Swift type when possible.
@objc
public class SMCData: NSObject
{
    /// The SMC key code, as a 32-bit four-character code.
    @objc public private( set ) dynamic var key: UInt32

    /// The SMC value type code, as a 32-bit four-character code.
    @objc public private( set ) dynamic var type: UInt32

    /// The raw value bytes associated with the key.
    @objc public private( set ) dynamic var data: Data

    /// The key code rendered as a four-character string.
    @objc public private( set ) dynamic var keyName: String

    /// The type code rendered as a four-character string.
    @objc public private( set ) dynamic var typeName: String

    /// The value decoded into a native type according to ``type``,
    /// or `nil` when the type is not recognized.
    @objc public private( set ) dynamic var value: Any?

    /// Creates a data object and decodes its value.
    ///
    /// - Parameters:
    ///   - key:  The SMC key code.
    ///   - type: The SMC value type code.
    ///   - data: The raw value bytes.
    @objc
    public init( key: UInt32, type: UInt32, data: Data )
    {
        self.key      = key
        self.type     = type
        self.data     = data
        self.keyName  = SMCHelper.fourCC( value: key )
        self.typeName = SMCHelper.fourCC( value: type )
        self.value    = SMCHelper.value( for: data, type: type )
    }
}
