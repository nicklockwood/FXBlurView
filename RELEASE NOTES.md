Version 1.4.4

- Fixed pixelation issue on Retina iPads

Version 1.4.3

- Fixed error when compiling for iOS 6.1 SDK using Xcode 5

Version 1.4.2

- Fixed issue where shadow or ghosting could appear at edge of blur view
- Now conforms to -Wextra warning level

Version 1.4.1

- Fixed minor memory leak in the setUp method

Version 1.4

- More intelligent scheduling when multiple dynamic FXBlurView instances are shown on screen at once
- Added global and individual methods for disabling blur (e.g. so you can disable blur on iPhone 4 and below for consistency with other apps on iOS 7)
- Added Multiples views example

Version 1.3.3

- Fixed console warning when adding an FXBlurView of zero size to the window

Version 1.3.2

- Fixed issue with pixelation on non-Retina devices
- Tweaked performance/quality tradeoff

Version 1.3.1

- Improved blur quality (1.3 was slightly blocky)

Version 1.3

- Added tintColor property
- Significant performance improvement by reducing snapshot scale based in proportion to blur radius
- Views placed in front of the FXBlurView in the hierarchy are no longer included in the blur effect
- Fixed issue where blurView was sometimes partially transparent
- Added example showing how to implement an iOS7 control center-style overlay
- FXBlurView now requires ARC

Version 1.2

- Added +setUpdatesEnabled and +setUpdatesDisabled methods to globally enable/disable dynamic blur updates (e.g. when performing an animation)
- Added -updateIterval method to control CPU load when updating
- Changed runloop mode to reduce interference with scrolling, etc

Version 1.1

- Added ability to set number of blur iterations
- Fixed setNeedsDisplay behavior when dynamic = NO
- Reduced memory allocations in blur algorithm
- Added dynamic mode toggle to example app

Version 1.0

- Initial release