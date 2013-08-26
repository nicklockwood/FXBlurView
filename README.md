Purpose
--------------

FXBlurView is a UIView subclass that replicates the iOS 7 realtime background blur effect, but works on iOS 5 and above. It is designed to be as fast and as simple to use as possible. FXBlurView offers two modes of operation: static, where the view is rendered only once when it is added to a superview (though it can be updated by calling setNeedsDisplay) or dynamic, where it will automatically redraw itself on a background thread as often as possible.


Supported iOS & SDK Versions
-----------------------------

* Supported build target - iOS 6.1 (Xcode 4.6.2, Apple LLVM compiler 4.2)
* Earliest supported deployment target - iOS 5.0
* Earliest compatible deployment target - iOS 5.0

NOTE: 'Supported' means that the library has been tested with this version. 'Compatible' means that the library should work on this iOS version (i.e. it doesn't rely on any unavailable SDK features) but is no longer being tested for compatibility and may require tweaking or bug fixes to run correctly.


ARC Compatibility
------------------

FXBlurView currently works either with or without ARC enabled.


Installation
---------------

To use FXBlurView, just drag the class files into your project and add the Accelerate framework. You can create FXBlurView instances programatically, or create them in Interface Builder by dragging an ordinary UIView into your view and setting its class to FXBlurView.

If you are using Interface Builder, to set the custom properties of FXBlurView (ones that are not supported by regular UIViews) either create an IBOutlet for your view and set the properties in code, or use the User Defined Runtime Attributes feature in Interface Builder (introduced in Xcode 4.2 for iOS 5+).


UIImage extensions
--------------------

FXBlurView extends UIImage with the following method:

    - (UIImage *)blurredImageWithRadius:(CGFloat)radius
                             iterations:(NSUInteger)iterations;

This method applies a blur effect and returns the resultant blurred image without modifying the original. The radius property controls the extent of the blur effect. The iterations property controls the number of iterations. More iterations means higher quality.


FXBlurView properties
----------------

	@property (nonatomic, getter = isDynamic) BOOL dynamic;
	
This property controls whether the blurView updates dynamically, or only once when the view is added to its superview. Defaults to YES. Note that is dynamic is set to NO, you can still force the view to update by calling setNeedsDisplay.

    @property (nonatomic, assign) NSUInteger iterations;

The number of blur iterations. More iterations improves the quality but reduces the performance. Defaults to 3 iterations.

    @property (nonatomic, assign) CGFloat blurRadius;	

This property controls the radius of the blur effect (in points). Defaults to a 40 point radius.