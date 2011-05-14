//
//  iCarouselExampleViewControllerMac.h
//  iCarouselExample
//
//  Created by Sushant Prakash on 5/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "iCarouselMac.h"

@interface iCarouselExampleViewControllerMac : NSViewController<iCarouselMacDataSource, iCarouselMacDelegate>
{
@private
    
}

@property (nonatomic, retain) IBOutlet iCarouselMac *carousel;

- (IBAction)switchCarouselType;
- (IBAction)toggleWrap;

@end
