# SliceFixup

## Problem

The arm64e ABI was changed in iOS 14 (Xcode 11) and therefore any arm64e dylib compiled with Xcode 12 or newer does not support iOS 13. The old ABI was upwards compatible so for the longest time people were just compiling their dylibs with Xcode 11. This changed in iOS 15 now however, there are now issues with loading old ABI slices into new ABI processes. For whatever reason most dylibs still work fine, but one of mine (CraneSupport.dylib) was not working.

Back in the iOS 14 days, before I discovered the old ABI was upwards compatible, I made a script that uses a patched lipo to join together a slice of both the old and new arm64e ABIs. Now that this script is actually needed I tested it some more and discovered that dyld would always prefer the old ABI slice over the new ABI slice, which means that having the old slice in the binary always also breaks iOS 15.

## Solution

SliceFixup is a tool that, based on the iOS version it's running on, removes the incompatible arm64e slice, so that the outcome is a dylib that only has the supported slice in it, so everything works fine. It is supposed to be called in the `postinst` on all of the dylibs that require this fix (e.g. all dylibs that need to inject into an arm64e process). It does this by only removing the slice from the FAT header, so the actual slice is still in the binary, it's just not found.

Before you can use this tool, you need to setup something like [plipo_package.sh](https://github.com/opa334/CCSupport/blob/74762743acb839fcdcaeb61785fa54662b860542/plipo_package.sh) to have both an Xcode 11 and an Xcode 12+ slice in your dylibs.