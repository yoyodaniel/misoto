//
//  DebugLog.swift
//  Misoto
//
//  Overrides the global `print()` function so that log output is
//  completely stripped from Release builds.  No changes needed in
//  existing call-sites — they continue to call `print(...)` as before.
//

import Foundation

/// Shadows Swift's built-in `print` so that it becomes a no-op in Release builds.
/// In Debug builds it forwards to `Swift.print` as usual.
@inline(__always)
func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    let output = items.map { "\($0)" }.joined(separator: separator)
    Swift.print(output, terminator: terminator)
    #endif
}
