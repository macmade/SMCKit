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

/// Unit tests for the external-process wrapper ``Task``.
///
/// These exercise the output-capture path against real command-line tools, so
/// they do not depend on any SMC hardware.
@Suite( "Task" )
struct TaskTests
{
    /// Standard output is captured verbatim.
    @Test( "run captures standard output" )
    func capturesStandardOutput()
    {
        let task = Task.run( executable: URL( fileURLWithPath: "/bin/echo" ), arguments: [ "Hello, World!" ], input: nil )

        #expect( task != nil )
        #expect( task?.terminationStatus == 0 )
        #expect( String( data: task?.standardOutput ?? Data(), encoding: .utf8 ) == "Hello, World!\n" )
    }

    /// Standard error is captured independently of standard output.
    @Test( "run captures standard error" )
    func capturesStandardError()
    {
        let task = Task.run( executable: URL( fileURLWithPath: "/bin/sh" ), arguments: [ "-c", "echo out; echo err 1>&2" ], input: nil )

        #expect( task != nil )
        #expect( String( data: task?.standardOutput ?? Data(), encoding: .utf8 ) == "out\n" )
        #expect( String( data: task?.standardError  ?? Data(), encoding: .utf8 ) == "err\n" )
    }

    /// A large amount of output — well beyond the pipe buffer — is captured in
    /// full, with no missed chunk and no deadlock.
    ///
    /// Regression guard for the notification-based capture: the background
    /// `NSFileHandleDataAvailable` observers, re-armed after each chunk and
    /// pumped by the run loop that `waitUntilExit()` spins, must collect output
    /// larger than the 64 KB pipe buffer without truncation or stalling.
    @Test( "run captures large output without truncation" )
    func capturesLargeOutput()
    {
        let count = 1_000_000
        let task  = Task.run( executable: URL( fileURLWithPath: "/usr/bin/head" ), arguments: [ "-c", "\( count )", "/dev/zero" ], input: nil )

        #expect( task != nil )
        #expect( task?.terminationStatus == 0 )
        #expect( task?.standardOutput.count == count )
    }

    /// Data provided as input is written to the process's standard input and
    /// echoed back on its standard output.
    @Test( "run feeds standard input to the process" )
    func writesStandardInput()
    {
        let input = Data( "piped input".utf8 )
        let task  = Task.run( executable: URL( fileURLWithPath: "/bin/cat" ), arguments: [], input: input )

        #expect( task != nil )
        #expect( task?.terminationStatus == 0 )
        #expect( task?.standardOutput == input )
    }

    /// The process's exit code is exposed through `terminationStatus`.
    @Test( "run reports the termination status" )
    func reportsTerminationStatus()
    {
        let success = Task.run( executable: URL( fileURLWithPath: "/usr/bin/true" ), arguments: [], input: nil )
        let failure = Task.run( executable: URL( fileURLWithPath: "/bin/sh" ), arguments: [ "-c", "exit 7" ], input: nil )

        #expect( success?.terminationStatus == 0 )
        #expect( failure?.terminationStatus == 7 )
    }

    /// Launching a non-existent executable is caught and reported as a `nil`
    /// task rather than crashing.
    @Test( "run returns nil when the executable cannot be launched" )
    func returnsNilOnLaunchFailure()
    {
        let task = Task.run( executable: URL( fileURLWithPath: "/nonexistent/executable" ), arguments: [], input: nil )

        #expect( task == nil )
    }
}
