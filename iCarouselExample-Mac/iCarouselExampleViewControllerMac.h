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
    
    IBOutlet NSTextField* indexField;
    IBOutlet NSTextField* countField;
    IBOutlet NSProgressIndicator* progressIndicator;
    IBOutlet NSButton* wrapCheckbox;
    IBOutlet NSSlider* slider;
    
    NSInteger numItems;
}

@property (nonatomic, retain) IBOutlet iCarouselMac *carousel;

- (IBAction)switchCarouselType:(id)sender;
- (IBAction)toggleWrap:(id)sender;
- (IBAction) sliderChanged:(id)sender;

@end
