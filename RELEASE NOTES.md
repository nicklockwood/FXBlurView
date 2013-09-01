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