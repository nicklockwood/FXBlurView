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