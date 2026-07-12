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

/// Gathers descriptive information about the current machine.
///
/// The details are used to build the header of an SMC dump: the current date,
/// the operating-system version, and hardware information obtained from
/// `system_profiler` (falling back to the `hw.model` sysctl value).
internal class MachineDetails
{
    /// Unavailable; `MachineDetails` exposes only static members.
    private init()
    {}

    /// The full list of machine details as label/value pairs.
    ///
    /// Combines the date, the system version and either the parsed hardware
    /// details or, as a fallback, the raw hardware model identifier.
    public static var all: [ ( String, String ) ]
    {
        [
            [ ( "Date",           self.date ) ],
            [ ( "System Version", self.systemVersion ) ],
            self.hardwareDetails ?? [ ( "Model Identifier", self.hardwareModel ) ],
        ]
        .flatMap
        {
            $0
        }
    }

    /// The current date and time, formatted as an ISO-8601 string.
    public static var date: String
    {
        ISO8601DateFormatter().string( from: Date())
    }

    /// The operating-system version string reported by `ProcessInfo`.
    public static var systemVersion: String
    {
        ProcessInfo.processInfo.operatingSystemVersionString
    }

    /// The hardware model identifier from the `hw.model` sysctl.
    ///
    /// Returns `"--"` if the value cannot be read.
    public static var hardwareModel: String
    {
        var length: size_t = 0

        guard sysctlbyname( "hw.model", nil, &length, nil, 0 ) == 0, length > 0
        else
        {
            return "--"
        }

        var model = [ CChar ]( repeating: 0,  count: length )

        guard sysctlbyname( "hw.model", &model, &length, nil, 0 ) == 0, length > 0
        else
        {
            return "--"
        }

        return String( cString: model )
    }

    /// Hardware details parsed from `system_profiler`'s hardware data type.
    ///
    /// Runs `system_profiler SPHardwareDataType`, extracts each `label: value`
    /// line and keeps only the keys listed in ``validHardwareDetailsKeys``.
    ///
    /// - Returns: The label/value pairs, or `nil` if the tool cannot be run,
    ///   its output cannot be decoded, or no matching keys are found.
    public static var hardwareDetails: [ ( String, String ) ]?
    {
        guard let task = Task.run( executable: URL( fileURLWithPath: "/usr/sbin/system_profiler" ), arguments: [ "SPHardwareDataType" ], input: nil )
        else
        {
            return nil
        }

        guard let output = String( data: task.standardOutput, encoding: .utf8 )
        else
        {
            return nil
        }

        return self.parseHardwareDetails( output )
    }

    /// Parses `system_profiler` hardware output into label/value pairs.
    ///
    /// Each `label: value` line is matched with a single, reused regular
    /// expression, and only the keys listed in ``validHardwareDetailsKeys`` are
    /// kept. The match range spans the whole line in UTF-16 code units, so lines
    /// containing multi-unit characters (emoji, combining marks, ...) are not
    /// truncated.
    ///
    /// - Parameter output: The raw text emitted by `system_profiler`.
    /// - Returns: The matching label/value pairs, or `nil` if the pattern cannot
    ///   be compiled or none of the wanted keys are present.
    internal static func parseHardwareDetails( _ output: String ) -> [ ( String, String ) ]?
    {
        guard let regex = try? NSRegularExpression( pattern: "\\s*([^:]+):\\s*(.+)" )
        else
        {
            return nil
        }

        let details: [ ( String, String ) ] = output.split( separator: "\n" ).map
        {
            String( $0 )
        }
        .compactMap
        {
            let string  = $0 as NSString
            let range   = NSRange( location: 0, length: string.length )
            let matches = regex.matches( in: $0, range: range )

            guard let match = matches.first, match.numberOfRanges == 3
            else
            {
                return nil
            }

            let label = string.substring( with: match.range( at: 1 ) )
            let value = string.substring( with: match.range( at: 2 ) )

            return ( label, value )
        }
        .filter
        {
            self.validHardwareDetailsKeys.contains( $0.0 )
        }

        return details.isEmpty ? nil : details
    }

    /// The set of `system_profiler` hardware keys to keep in
    /// ``hardwareDetails``.
    private static var validHardwareDetailsKeys: [ String ]
    {
        [
            "Model Name",
            "Model Identifier",
            "Model Number",
            "Chip",
            "Total Number of Cores",
            "Memory",
        ]
    }
}
