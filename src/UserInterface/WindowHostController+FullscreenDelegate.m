//
//  WindowHostController+FullscreenDelegate.m
//  Eloquent
//
//  Created by Manfred Bergmann on 19.02.10.
//  Copyright 2010 Software by MABE. All rights reserved.
//

#import "WindowHostController+FullscreenDelegate.h"
#import "WindowHostController+SideBars.h"
#import "ToolbarController.h"


@implementation WindowHostController (FullscreenDelegate)

- (void)goingToFullScreenMode {
    inFullScreenTransition = YES;
    CocoLog(LEVEL_DEBUG, @"going to fullscreen");
    
    NSView *topView = [contentViewController topAccessoryView];
    [topView removeFromSuperview];
    [toolbarController setScopebarView:topView];
}

- (void)goneToFullScreenMode {
    CocoLog(LEVEL_DEBUG, @"gone to fullscreen");
    inFullScreenTransition = NO;
    [self forceReload:nil];
}

- (void)leavingFullScreenMode {
    inFullScreenTransition = YES;
    CocoLog(LEVEL_DEBUG, @"leaving fullscreen");
    
    NSView *topView = [contentViewController topAccessoryView];
    [topView removeFromSuperview];
    [scopebarViewPlaceholder setContentView:topView];
    [[toolbarController toolbarHUDView] removeFromSuperview];
}

- (void)leftFullScreenMode {
    CocoLog(LEVEL_DEBUG, @"left fullscreen");
    inFullScreenTransition = NO;
    [self forceReload:nil];
}

- (IBAction)fullScreenModeOnOff:(id)sender {
    [view fullScreenModeOnOff:sender];
}

- (void)windowWillEnterFullScreen:(NSNotification *)notification {
    CocoLog(LEVEL_DEBUG, @"going to fullscreen");
    
    inFullScreenTransition = YES;
}

- (void)windowDidEnterFullScreen:(NSNotification *)notification {
    CocoLog(LEVEL_DEBUG, @"gone to fullscreen");
    
    inFullScreenTransition = NO;
    [self forceReload:nil];
}

- (void)windowWillExitFullScreen:(NSNotification *)notification {
    CocoLog(LEVEL_DEBUG, @"leaving fullscreen");
    
    inFullScreenTransition = YES;
}

- (void)windowDidExitFullScreen:(NSNotification *)notification {
    CocoLog(LEVEL_DEBUG, @"left fullscreen");
    
    inFullScreenTransition = NO;
    [self forceReload:nil];
}

@end
