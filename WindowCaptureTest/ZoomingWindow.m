//
//  ZoomingWindow.m
//  WindowCaptureTest
//
//  Created by Administrator on 2021-11-27.
//

#import "ZoomingWindow.h"

#import <QuartzCore/QuartzCore.h>


@interface InfoPanel : NSWindow

@property BOOL disableConstrainedWindow;

@end

@implementation InfoPanel

- (NSRect)constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen *)screen {
    return (_disableConstrainedWindow ? frameRect : [super constrainFrameRect:frameRect toScreen:screen]);
}

@end


@interface ZoomingWindow () <NSWindowDelegate>

@end

@implementation ZoomingWindow

- (void)windowDidLoad {
    [super windowDidLoad];
    self.window.delegate = self;

    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}


- (instancetype)init {
    self = [super initWithWindowNibName:@"ZoomingWindow"];
    if (self) {

    }

    return self;
}



#pragma mark animation

- (NSWindow *)makeAndPrepareSnapshotWindow:(NSRect)startingframe {
    CALayer *snapshotLayer = [self takeSnapshot];
    NSWindow *snapshotWindow = [self createFullScreenWindow];
    [snapshotWindow.contentView.layer addSublayer:snapshotLayer];

    // Compute the frame of the snapshot layer such that the snapshot is
    // positioned on startingframe.
    NSRect snapshotLayerFrame =
    [snapshotWindow convertRectFromScreen:startingframe];

    snapshotLayer.frame = snapshotLayerFrame;
    [snapshotWindow orderFront:nil];
    return snapshotWindow;
}

- (CALayer *)takeSnapshot {
    CGImageRef windowImageRef =
    CGWindowListCreateImage(CGRectNull,
                            kCGWindowListOptionIncludingWindow,
                            (CGWindowID)[self.window windowNumber],
                            kCGWindowImageBoundsIgnoreFraming);

    CALayer *snapshotLayer = [[CALayer alloc] init];

    snapshotLayer.frame = self.window.frame;
    snapshotLayer.contents = CFBridgingRelease(windowImageRef);
    snapshotLayer.anchorPoint = CGPointMake(0, 0);

    return snapshotLayer;
}

- (void)animateIn:(NSRect)targetFrame {
    NSRect screenRect = NSScreen.mainScreen.visibleFrame;
    NSRect startingFrame = NSMakeRect(NSMidX(screenRect), NSMidY(screenRect), 100, 100);
    NSWindow *snapshotWindow = [self makeAndPrepareSnapshotWindow:startingFrame];
    CALayer *snapshotLayer =  snapshotWindow.contentView.layer.sublayers.firstObject;

    NSRect finalLayerFrame = [snapshotWindow convertRectFromScreen:targetFrame];
    snapshotLayer.frame = [snapshotWindow convertRectFromScreen:startingFrame];


    CABasicAnimation *transformAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
    CGFloat scaleFactorX = NSWidth(finalLayerFrame) / NSWidth(snapshotLayer.frame);
    CGFloat scaleFactorY = NSHeight(finalLayerFrame) / NSHeight(snapshotLayer.frame);
    transformAnimation.toValue=[NSValue valueWithCATransform3D:CATransform3DMakeScale(scaleFactorX, scaleFactorY, 1)];
    transformAnimation.removedOnCompletion = NO;
    transformAnimation.fillMode = kCAFillModeForwards;

    // Prepare the animation from the current position to the new position
    CABasicAnimation *positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    positionAnimation.fromValue = [snapshotLayer valueForKey:@"position"];
    NSPoint point = finalLayerFrame.origin;
    positionAnimation.toValue = [NSValue valueWithPoint:point];
    positionAnimation.fillMode = kCAFillModeForwards;

    [NSAnimationContext
     runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 4;
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

        snapshotLayer.position = point;
        [snapshotLayer addAnimation:positionAnimation forKey:@"position"];
        [snapshotLayer addAnimation:transformAnimation forKey:@"transform"];
    } completionHandler:^{
        [self.window setFrame:targetFrame display:YES];
        [self showWindow:nil];
        snapshotWindow.contentView.hidden = YES;
        [snapshotWindow.windowController close];
    }];
}

- (void)animateOut {
    NSWindow *snapshotWindow = [self makeAndPrepareSnapshotWindow:self.window.frame];
    NSView *snapshotView = snapshotWindow.contentView;
    CALayer *snapshotLayer = snapshotView.layer.sublayers.firstObject;


    NSRect currentFrame = snapshotLayer.frame;
    NSRect screenRect = NSScreen.mainScreen.visibleFrame;
    NSRect targetFrame = NSMakeRect(NSMidX(screenRect), NSMidY(screenRect), 0, 0);

    NSRect finalLayerFrame = [snapshotWindow convertRectFromScreen:targetFrame];

    [snapshotLayer removeFromSuperlayer];
    [snapshotWindow.contentView.layer addSublayer:snapshotLayer];

    CABasicAnimation *transformAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
    CGFloat scaleFactorX = NSWidth(finalLayerFrame) / NSWidth(currentFrame);
    CGFloat scaleFactorY = NSHeight(finalLayerFrame) / NSHeight(currentFrame);
    transformAnimation.toValue=[NSValue valueWithCATransform3D:CATransform3DMakeScale(scaleFactorX, scaleFactorY, 1)];
    transformAnimation.removedOnCompletion = NO;
    transformAnimation.fillMode = kCAFillModeForwards;

    CABasicAnimation *positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    positionAnimation.fromValue = [snapshotLayer valueForKey:@"position"];
    NSPoint point = finalLayerFrame.origin;
    positionAnimation.toValue = [NSValue valueWithPoint:point];
    positionAnimation.fillMode = kCAFillModeForwards;

    [NSAnimationContext
     runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 4;
        [self.window orderOut:nil];
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [snapshotLayer addAnimation:positionAnimation forKey:@"position"];
        [snapshotLayer addAnimation:transformAnimation forKey:@"transform"];
    } completionHandler:^{
        snapshotView.hidden = YES;
        [snapshotWindow.windowController close];
    }];
}

-(void)hideWindow {
    // So we need to get a screenshot of the window without flashing.
    // First, we find the frame that covers all the connected screens.
    CGRect allWindowsFrame = CGRectZero;

    for(NSScreen *screen in [NSScreen screens]) {
        allWindowsFrame = NSUnionRect(allWindowsFrame, screen.frame);
    }

    // Position our window to the very right-most corner out of visible range, plus padding for the shadow.
    CGRect frame = (CGRect){
        .origin = CGPointMake(CGRectGetWidth(allWindowsFrame) + 2 * 19.f, 0),
        .size = self.window.frame.size
    };

    // This is where things get nasty. Against what the documentation states, windows seem to be constrained
    // to the screen, so we override "constrainFrameRect:toScreen:" to return the original frame, which allows
    // us to put the window off-screen.
    ((InfoPanel *)self.window).disableConstrainedWindow = YES;

    [self.window setFrame:frame display:YES];
    [self showWindow:nil];
    [self.window makeKeyAndOrderFront:nil];
}

- (NSWindow *)createFullScreenWindow {
    NSWindow *fullScreenWindow = [[NSWindow alloc] initWithContentRect:(CGRect){ .size = NSScreen.mainScreen.frame.size }
                  styleMask:NSWindowStyleMaskBorderless
                    backing:NSBackingStoreBuffered
                      defer:NO
                     screen:NSScreen.mainScreen
    ];

    fullScreenWindow.animationBehavior = NSWindowAnimationBehaviorNone;
    fullScreenWindow.backgroundColor = NSColor.clearColor;
    fullScreenWindow.movableByWindowBackground = NO;
    fullScreenWindow.ignoresMouseEvents = YES;
    fullScreenWindow.level = self.window.level;
    fullScreenWindow.hasShadow = NO;
    fullScreenWindow.opaque = NO;
    NSView *contentView = [[NSView alloc] initWithFrame:NSZeroRect];
    contentView.wantsLayer = YES;
    contentView.layerContentsRedrawPolicy = NSViewLayerContentsRedrawNever;
    fullScreenWindow.contentView = contentView;
    return fullScreenWindow;
}

@end
