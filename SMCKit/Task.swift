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

/// Runs an external process synchronously and captures its output.
///
/// `Task` wraps `Process`, collecting the child process's standard output and
/// standard error in the background while waiting for it to exit. It is used to
/// invoke command-line tools such as `system_profiler`.
internal class Task
{
    /// The underlying process being run.
    private var task: Process

    /// The pipe capturing the process's standard output.
    private var pipeOut: Pipe

    /// The pipe capturing the process's standard error.
    private var pipeErr: Pipe

    /// The process's exit status, or `nil` until it has exited.
    public private( set ) var terminationStatus: Int32?

    /// The data collected from the process's standard output.
    public private( set ) var standardOutput: Data

    /// The data collected from the process's standard error.
    public private( set ) var standardError: Data

    /// Runs an executable to completion, capturing its output.
    ///
    /// - Parameters:
    ///   - executable: The URL of the executable to run.
    ///   - arguments:  The command-line arguments to pass.
    ///   - input:      Optional data to write to the process's standard input.
    /// - Returns: A finished `Task` on success, or `nil` if launching the
    ///   process raised an exception.
    public class func run( executable: URL, arguments: [ String ], input: Data? ) -> Task?
    {
        let task = Task( executable: executable, arguments: arguments )

        do
        {
            try SMCException.doTry
            {
                task.run( input: input )
            }

            return task
        }
        catch
        {
            return nil
        }
    }

    /// Creates a task and configures its pipes and notifications.
    ///
    /// - Parameters:
    ///   - executable: The URL of the executable to run.
    ///   - arguments:  The command-line arguments to pass.
    private init( executable: URL, arguments: [ String ] )
    {
        self.pipeOut = Pipe()
        self.pipeErr = Pipe()
        self.task    = Process()

        self.task.launchPath     = executable.path
        self.task.arguments      = arguments
        self.task.standardOutput = self.pipeOut
        self.task.standardError  = self.pipeErr

        self.standardOutput = Data()
        self.standardError  = Data()

        NotificationCenter.default.addObserver( self, selector: #selector( self.dataAvailableForStandardOutput( _: ) ), name: NSNotification.Name.NSFileHandleDataAvailable, object: self.pipeOut.fileHandleForReading )
        NotificationCenter.default.addObserver( self, selector: #selector( self.dataAvailableForStandardError( _: )  ), name: NSNotification.Name.NSFileHandleDataAvailable, object: self.pipeErr.fileHandleForReading )

        self.pipeOut.fileHandleForReading.waitForDataInBackgroundAndNotify()
        self.pipeErr.fileHandleForReading.waitForDataInBackgroundAndNotify()
    }

    /// Removes the notification observers registered in `init`.
    ///
    /// The two `NSFileHandleDataAvailable` observers are registered against the
    /// pipes' read handles for the lifetime of the task. Removing them here
    /// avoids leaving stale registrations in the default `NotificationCenter`
    /// once the task is deallocated.
    deinit
    {
        NotificationCenter.default.removeObserver( self )
    }

    /// Launches the process, optionally feeds it input, and waits for it to
    /// exit.
    ///
    /// - Parameter input: Optional data to write to the process's standard
    ///   input before waiting for it to finish.
    private func run( input: Data? )
    {
        if let _ = input
        {
            self.task.standardInput = Pipe()
        }

        self.task.launch()

        if let input = input, let pipe = self.task.standardInput as? Pipe
        {
            let handle = pipe.fileHandleForWriting

            handle.write( input )
            try? handle.close()
        }

        self.task.waitUntilExit()

        self.terminationStatus = self.task.terminationStatus
    }

    /// Appends newly available standard-output data and re-arms the
    /// notification.
    ///
    /// - Parameter notification: The `NSFileHandleDataAvailable` notification
    ///   posted by the standard-output file handle.
    @objc
    private func dataAvailableForStandardOutput( _ notification: Notification )
    {
        guard let handle = notification.object as? FileHandle?,
              let data   = handle?.availableData
        else
        {
            return
        }

        self.standardOutput.append( data )
        handle?.waitForDataInBackgroundAndNotify()
    }

    /// Appends newly available standard-error data and re-arms the
    /// notification.
    ///
    /// - Parameter notification: The `NSFileHandleDataAvailable` notification
    ///   posted by the standard-error file handle.
    @objc
    private func dataAvailableForStandardError( _ notification: Notification )
    {
        guard let handle = notification.object as? FileHandle?,
              let data = handle?.availableData
        else
        {
            return
        }

        self.standardError.append( data )
        handle?.waitForDataInBackgroundAndNotify()
    }
}
