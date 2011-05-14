//
//  iCarouselExample_MacAppDelegate.h
//  iCarouselExample-Mac
//
//  Created by Sushant Prakash on 5/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class iCarouselExampleViewControllerMac;

@interface iCarouselExample_MacAppDelegate : NSObject <NSApplicationDelegate> {
@private
    NSWindow *window;
    iCarouselExampleViewControllerMac* _viewController;
}

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, retain) IBOutlet iCarouselExampleViewControllerMac *viewController;

@end
