SMCKit
======

[![Build Status](https://img.shields.io/github/actions/workflow/status/macmade/SMCKit/ci-mac.yaml?label=macOS&logo=apple)](https://github.com/macmade/SMCKit/actions/workflows/ci-mac.yaml)
[![Issues](http://img.shields.io/github/issues/macmade/SMCKit.svg?logo=github)](https://github.com/macmade/SMCKit/issues)
![Status](https://img.shields.io/badge/status-active-brightgreen.svg?logo=git)
![License](https://img.shields.io/badge/license-mit-brightgreen.svg?logo=open-source-initiative)  
[![Contact](https://img.shields.io/badge/follow-@macmade-blue.svg?logo=twitter&style=social)](https://twitter.com/macmade)
[![Sponsor](https://img.shields.io/badge/sponsor-macmade-pink.svg?logo=github-sponsors&style=social)](https://github.com/sponsors/macmade)

### About

SMCKit is a macOS framework providing read access to the SMC (System Management
Controller) private API.

The SMC exposes hundreds of keys describing hardware sensors and state -
temperatures, fan speeds, voltages, power and more. SMCKit opens a connection to
the `AppleSMC` IOKit service, enumerates those keys, reads their raw values, and
decodes them into native Swift types.

### Features

  - Read-only access to every SMC key exposed by the hardware.
  - Automatic decoding of the common SMC value types (`si8`/`si16`/`si32`/`si64`,
    `ui8`/`ui16`/`ui32`/`ui64`, `flt`, `ioft`, `sp78`, `flag`, `ch8*`), with the
    raw bytes always available alongside the decoded value.
  - Thread-safe access: each `SMC` instance - including the process-wide `shared`
    instance - serializes access to its own connection and caches, so it can be
    used from multiple threads concurrently.
  - A ready-made, formatted dump of every key through `SMCDump`.
  - Objective-C compatible: the public API is exposed to both Swift and
    Objective-C.

### Usage

The main entry point is the `SMC` class. Use the process-wide `shared` instance
and call `readAllKeys`, optionally passing a filter block to select which keys
to read:

```swift
import SMCKit

// Read every SMC key.
let all = SMC.shared.readAllKeys()

for data in all
{
    print( "\( data.keyName ) (\( data.typeName )): \( data.value ?? "?" )" )
}

// Read only a subset of keys, using the filter block.
let temperatures = SMC.shared.readAllKeys
{
    SMCHelper.fourCC( value: $0 ).hasPrefix( "T" )
}
```

Each key is returned as an `SMCData` object, bundling:

  - `key` / `keyName` - the key code, as a raw `UInt32` and its four-character
    string form.
  - `type` / `typeName` - the value type code, likewise raw and as a string.
  - `data` - the raw value bytes.
  - `value` - the value decoded into a native Swift type according to its type,
    or `nil` when the type is not recognized.

`SMCHelper` provides the stateless decoding routines (four-character-code
conversion, integer/floating-point/fixed-point/string decoding) should you need
to work with raw values directly.

### smc-dump

The project also provides a command-line tool called `smc-dump`, which prints a
formatted, aligned table of every SMC key - preceded by a header describing the
machine - to standard output. It is built on top of the framework's `SMCDump`
class.

It can be installed via Homebrew:

    brew install --HEAD macmade/tap/smc-dump

### Requirements

  - macOS 10.15 or later
  - Xcode / Swift 5

### Building

The repository ships an Xcode project with the following schemes:

  - `SMCKit` - the framework, plus its unit tests.
  - `libSMC` - a static library variant of the same code.
  - `smc-dump` - the command-line tool.

Clone the repository with its submodules and build with Xcode or `xcodebuild`:

    git clone --recursive https://github.com/macmade/SMCKit.git
    cd SMCKit
    xcodebuild -project SMCKit.xcodeproj -scheme SMCKit

License
-------

Project is released under the terms of the MIT License.

Repository Infos
----------------

    Owner:          Jean-David Gadina - XS-Labs
    Web:            www.xs-labs.com
    Blog:           www.noxeos.com
    Twitter:        @macmade
    GitHub:         github.com/macmade
    LinkedIn:       ch.linkedin.com/in/macmade/
    StackOverflow:  stackoverflow.com/users/182676/macmade
