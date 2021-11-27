//
//  ZoomingWindow.h
//  WindowCaptureTest
//
//  Created by Administrator on 2021-11-27.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZoomingWindow : NSWindowController

- (void)animateIn:(NSRect)targetFrame;
- (void)animateOut;
- (void)hideWindow;
- (CALayer *)takeSnapshot;
- (NSWindow *)createFullScreenWindow;

@end

NS_ASSUME_NONNULL_END
