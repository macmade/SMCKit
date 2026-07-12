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

/// Unit tests for the `system_profiler` output parsing in ``MachineDetails``.
@Suite( "MachineDetails" )
struct MachineDetailsTests
{
    /// A representative slice of `system_profiler SPHardwareDataType` output.
    ///
    /// The `Chip` value deliberately contains multi-unit characters (each rocket
    /// is one `Character` but two UTF-16 code units) to exercise the match-range
    /// handling.
    private static let sample = [
        "Hardware:",
        "",
        "    Hardware Overview:",
        "",
        "      Model Name: MacBook Air",
        "      Model Identifier: Mac16,12",
        "      Chip: Apple M4 🚀🚀🚀🚀",
        "      Total Number of Cores: 10 (4 performance and 6 efficiency)",
        "      Memory: 32 GB",
        "      Serial Number (system): X0X0X0X0X0",
    ]
    .joined( separator: "\n" )

    /// Only the wanted keys are kept; section headers and other keys are
    /// dropped.
    @Test( "parseHardwareDetails keeps only the wanted keys" )
    func parsesWantedKeys()
    {
        let details = Dictionary( MachineDetails.parseHardwareDetails( Self.sample ) ?? [] ) { first, _ in first }

        #expect( details[ "Model Name" ]            == "MacBook Air" )
        #expect( details[ "Model Identifier" ]      == "Mac16,12" )
        #expect( details[ "Total Number of Cores" ] == "10 (4 performance and 6 efficiency)" )
        #expect( details[ "Memory" ]                == "32 GB" )

        #expect( details[ "Serial Number (system)" ] == nil )
        #expect( details[ "Hardware Overview" ]       == nil )
    }

    /// The match range spans the whole line in UTF-16 units, so a value made of
    /// multi-unit characters is not truncated.
    ///
    /// Regression guard for the range bug: with `NSMakeRange(0, string.count)`
    /// the scan would stop after two rockets and drop the rest of the value.
    @Test( "parseHardwareDetails scans the whole line in UTF-16 units" )
    func parsesMultiUnitCharactersWithoutTruncation()
    {
        let details = Dictionary( MachineDetails.parseHardwareDetails( Self.sample ) ?? [] ) { first, _ in first }

        #expect( details[ "Chip" ] == "Apple M4 🚀🚀🚀🚀" )
    }

    /// Output with no wanted key (or empty output) yields `nil`.
    @Test( "parseHardwareDetails returns nil when no wanted key is present" )
    func returnsNilWhenNoWantedKey()
    {
        #expect( MachineDetails.parseHardwareDetails( "" )                    == nil )
        #expect( MachineDetails.parseHardwareDetails( "Foo: bar\nBaz: qux" )  == nil )
    }
}
