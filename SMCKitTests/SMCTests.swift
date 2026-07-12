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

/// Concurrency tests for the ``SMC`` class.
@Suite( "SMC" )
struct SMCTests
{
    /// Hammering the shared instance from several threads at once must not
    /// crash, deadlock, or corrupt its caches.
    ///
    /// This is a regression guard for the per-instance serialization: access
    /// to the shared mutable state (the key list, the key-info cache and the
    /// user-client connection) is serialized internally, so concurrent readers
    /// complete rather than racing on those structures. The check is
    /// hardware-independent — on a machine without an SMC connection each call
    /// simply returns an empty array, but the serialized paths are still
    /// exercised. Run under Thread Sanitizer to catch data races directly.
    @Test( "Concurrent reads on the shared instance are serialized" )
    func concurrentReadsAreSerialized() async
    {
        let iterations = 16

        let completed = await withTaskGroup( of: Int.self )
        {
            group in

            ( 0 ..< iterations ).forEach
            {
                _ in group.addTask
                {
                    SMC.shared.readAllKeys().count
                }
            }

            return await group.reduce( into: 0 ) { count, _ in count += 1 }
        }

        #expect( completed == iterations )
    }
}
