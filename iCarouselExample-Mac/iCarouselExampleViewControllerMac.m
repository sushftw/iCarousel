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
    
//    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Select Carousel Type"
//                                                       delegate:self
//                                              cancelButtonTitle:nil
//                                         destructiveButtonTitle:nil
//                                              otherButtonTitles:@"Linear", @"Rotary", @"Inverted Rotary", @"Cylinder", @"Inverted Cylinder", @"CoverFlow", @"Custom", nil];
//    [sheet showInView:self.view];
//    [sheet release];
}

- (IBAction)toggleWrap
{
    wrap = !wrap;
    //navItem.rightBarButtonItem.title = wrap? @"Wrap: ON": @"Wrap: OFF";
    [carousel reloadData];
}

//#pragma mark -
//#pragma mark UIActionSheet methods
//
//- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
//{
//    //restore view opacities to normal
//    for (UIView *view in carousel.itemViews)
//    {
//        view.alpha = 1.0;
//    }
//    
//    carousel.type = buttonIndex;
//    navItem.title = [actionSheet buttonTitleAtIndex:buttonIndex];
//}

#pragma mark -
#pragma mark iCarousel methods

- (NSUInteger)numberOfItemsInCarousel:(iCarouselMac *)carousel
{
    return 1200;
}

- (NSView *)carousel:(iCarouselMac *)carousel viewForItemAtIndex:(NSUInteger)index
{
    //create a numbered view
    //NSView *view = [[[NSImageView alloc] initWithImage:[NSImage imageNamed:@"page.png"]] autorelease];
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

- (float)carouselItemWidth:(iCarouselMac *)carousel
{
    //slightly wider than item view
    return 260;
}

- (CATransform3D)carousel:(iCarouselMac *)carousel transformForItemView:(NSView *)view withOffset:(float)offset
{
    //implement 'flip3D' style carousel
    
    //set opacity based on distance from camera
    //view.alpha = 1.0 - fminf(fmaxf(offset, 0.0), 1.0);
    
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
