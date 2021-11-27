//
//  AppDelegate.m
//  WindowCaptureTest
//
//  Created by Administrator on 2021-11-27.
//

#import "AppDelegate.h"

#import "ZoomingWindow.h"

@interface AppDelegate ()

@property (strong) IBOutlet NSWindow *window;

@property (strong) ZoomingWindow *zoomingWindow;
@property (strong) NSWindow *correctColor;
@property (strong) NSWindow *wrongColor;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

- (IBAction)compareColors:(id)sender {
    if (_correctColor)
        [_correctColor close];
    if (_wrongColor)
        [_wrongColor close];
    if (_zoomingWindow)
        [_zoomingWindow close];

    _zoomingWindow = [[ZoomingWindow alloc] init];

    [_zoomingWindow showWindow:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CALayer *rightColor = [self.zoomingWindow takeSnapshot];
        self.correctColor = [[NSWindow alloc] initWithContentRect:rightColor.frame styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable backing:NSBackingStoreBuffered defer:NO screen:NSScreen.mainScreen];
        self.correctColor.title = @"Correct Color";
        NSView *correctView = self.correctColor.contentView;
        correctView.wantsLayer = YES;
        [correctView setLayer:rightColor];
        rightColor.frame = correctView.frame;
        [self.correctColor makeKeyAndOrderFront:nil];

        [self.zoomingWindow close];
        self.zoomingWindow = [[ZoomingWindow alloc] init];

        [self.zoomingWindow hideWindow];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            CALayer *wrongColor = [self.zoomingWindow takeSnapshot];
            self.wrongColor = [[NSWindow alloc] initWithContentRect:wrongColor.frame styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable backing:NSBackingStoreBuffered defer:NO screen:NSScreen.mainScreen];
            self.wrongColor.title = @"Wrong Color";
            NSView *wrongView = self.wrongColor.contentView;
            wrongView.wantsLayer = YES;
            [wrongView.layer addSublayer:wrongColor];
            wrongColor.frame = wrongView.frame;

            [self.wrongColor makeKeyAndOrderFront:nil];
            [self.zoomingWindow close];
            self.zoomingWindow = nil;
        });
    });
}

- (IBAction)zoomWindow:(id)sender {
    if (!_zoomingWindow) {
        [self zoomInWindow];
    } else {
        [self zoomOutWindow];
    }
}

- (void)zoomInWindow {
    if (_zoomingWindow) {
        [_zoomingWindow close];
        _zoomingWindow = nil;
    }

    _zoomingWindow = [[ZoomingWindow alloc] init];

    NSRect targetFrame = _zoomingWindow.window.frame;

    [_zoomingWindow hideWindow];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.zoomingWindow animateIn:targetFrame];
    });
}

- (void)zoomOutWindow {
    [_zoomingWindow animateOut];
    _zoomingWindow = nil;
}

@end
