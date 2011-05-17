//
//  iCarouselExampleViewControllerMac.m
//  iCarouselExample
//
//  Created by Sushant Prakash on 5/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "iCarouselExampleViewControllerMac.h"

@interface iCarouselExampleViewControllerMac ()

@property (nonatomic, assign) BOOL wrap;

@end

@implementation iCarouselExampleViewControllerMac

@synthesize carousel;
@synthesize wrap;

- (void)dealloc
{
    [carousel release];
    [super dealloc];
}

#pragma mark -
#pragma mark View lifecycle

- (void) setView:(NSView *)view
{
    wrap = YES;
    [super setView:view];
    carousel.type = iCarouselTypeCoverFlow;
    carousel.maxNumberOfItemsToShow = 10;
    [wrapCheckbox setState:(wrap ? NSOnState : NSOffState)];
}

- (IBAction)switchCarouselType:(id)sender
{
    NSString* title = [[sender title] lowercaseString];
    if ([title isEqual:@"linear"]) 
    {
        carousel.type = iCarouselTypeLinear;
    }
    else if ([title isEqual:@"coverflow"])
    {
        carousel.type = iCarouselTypeCoverFlow;
    }
    else if ([title isEqual:@"rotary"])
    {
        carousel.type = iCarouselTypeRotary;
    }
    else if ([title isEqual:@"inverted rotary"])
    {
        carousel.type = iCarouselTypeInvertedRotary;
    }
    else if ([title isEqual:@"cylinder"])
    {
        carousel.type = iCarouselTypeCylinder;
    }
    else if ([title isEqual:@"inverted cylinder"])
    {
        carousel.type = iCarouselTypeInvertedCylinder;
    }
    else if ([title isEqual:@"custom"])
    {
        carousel.type = iCarouselTypeCustom;
    }
}

- (IBAction)toggleWrap:(id)sender
{
    wrap = !wrap;
    
    [wrapCheckbox setState:(wrap ? NSOnState : NSOffState)];
    
    [carousel reloadData];
}


#pragma mark -
#pragma mark iCarouselDataSource methods

- (NSUInteger)numberOfItemsInCarousel:(iCarouselMac *)carousel
{
    return 1200;
}

- (NSView *)carousel:(iCarouselMac *)carousel viewForItemAtIndex:(NSUInteger)index
{
    //create a numbered view
    NSImage* image = [NSImage imageNamed:@"page.png"];
    NSImageView* view = [[[NSImageView alloc] initWithFrame:NSMakeRect(0,0,image.size.width,image.size.height)] autorelease];
    [view setImage:image];
    [view setImageScaling:NSImageScaleAxesIndependently];
    
    NSTextField *label = [[[NSTextField alloc] initWithFrame:NSMakeRect(0,view.bounds.size.height/4,view.bounds.size.width,view.bounds.size.height/2)] autorelease];
    [label setStringValue:[NSString stringWithFormat:@"%i", index]];
    [label setBackgroundColor:[NSColor clearColor]];
    [label setBordered:NO];
    [label setSelectable:NO];
    [label setAlignment:NSCenterTextAlignment];
    [label setFont:[NSFont fontWithName:[[label font] fontName] size:50]];
    [view addSubview:label];
    return view;
}

#pragma mark -
#pragma mark iCarouselDelegate Methods

- (void) carouselDidScroll:(iCarouselMac *)carousel
{
    [progressBar startAnimation:self];
    [progressBar setHidden:NO];
}

- (void) carouselCurrentItemIndexUpdated:(iCarouselMac *)theCarousel
{
    [indexField setStringValue:[NSString stringWithFormat:@"%ld", (long)carousel.currentItemIndex]]; 
}

- (void)carouselStopped:(iCarouselMac *)theCarousel
{
    [progressBar stopAnimation:self];
    [progressBar setHidden:YES];
}

- (float)carouselItemWidth:(iCarouselMac *)carousel
{
    //slightly wider than item view
    return 260;
}

- (CATransform3D)carousel:(iCarouselMac *)carousel transformForItemView:(NSView *)view withOffset:(float)offset
{
    //implement 'flip3D' style carousel
    
    //set opacity based on distance from camera
    view.layer.opacity = 1.0 - fminf(fmaxf(offset, 0.0), 1.0);
    
    //do 3d transform
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = self.carousel.perspective;
    transform = CATransform3DRotate(transform, M_PI / 8.0, 0, 1.0, 0);
    return CATransform3DTranslate(transform, 0.0, 0.0, offset * self.carousel.itemWidth);
}

- (BOOL)carouselShouldWrap:(iCarouselMac *)carousel
{
    //wrap all carousels
    return wrap;
}


@end
