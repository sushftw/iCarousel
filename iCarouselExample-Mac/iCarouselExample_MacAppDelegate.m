//
//  iCarouselExample_MacAppDelegate.m
//  iCarouselExample-Mac
//
//  Created by Sushant Prakash on 5/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "iCarouselExample_MacAppDelegate.h"
#import "iCarouselExampleViewControllerMac.h"

@implementation iCarouselExample_MacAppDelegate

@synthesize window;
@synthesize viewController=_viewController;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [window setContentView:self.viewController.view];
    [window makeFirstResponder:self.viewController.carousel];
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

- (void) dealloc
{
    [window release];
    [_viewController release];
}

@end
