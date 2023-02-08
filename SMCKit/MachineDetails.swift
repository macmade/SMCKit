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

internal class MachineDetails
{
    private init()
    {}

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

    public static var date: String
    {
        ISO8601DateFormatter().string( from: Date())
    }

    public static var systemVersion: String
    {
        ProcessInfo.processInfo.operatingSystemVersionString
    }

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

        let details: [ ( String, String ) ] = output.split( separator: "\n" ).map
        {
            String( $0 )
        }
        .compactMap
        {
            guard let regex = try? NSRegularExpression( pattern: "\\s*([^:]+):\\s*(.+)" )
            else
            {
                return nil
            }

            let matches = regex.matches( in: $0, range: NSMakeRange( 0, $0.count ) )

            guard let match = matches.first, match.numberOfRanges == 3
            else
            {
                return nil
            }

            let r1 = match.range( at: 1 )
            let r2 = match.range( at: 2 )

            let label = ( $0 as NSString ).substring( with: r1 )
            let value = ( $0 as NSString ).substring( with: r2 )

            return ( label, value )
        }
        .filter
        {
            self.validHardwareDetailsKeys.contains( $0.0 )
        }

        return details.isEmpty ? nil : details
    }

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
