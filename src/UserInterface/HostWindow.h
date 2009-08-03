//
//  HostWindow.h
//  MacSword2
//
//  Created by Manfred Bergmann on 05.04.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 This class is used as first responder for all the main menu actions.
 */
@interface HostWindow : NSWindow {

}

- (IBAction)leftSideBarHideShow:(id)sender;
- (IBAction)rightSideBarHideShow:(id)sender;
- (IBAction)switchToRefLookup:(id)sender;
- (IBAction)switchToIndexLookup:(id)sender;
- (IBAction)navigationBack:(id)sender;
- (IBAction)navigationForward:(id)sender;
- (IBAction)fullScreenModeOnOff:(id)sender;
- (IBAction)performClose:(id)sender;

@end