//
//  iCarouselMac.h
//  iCarouselExample
//
//  Created by Sushant Prakash on 5/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>


typedef enum
{
    iCarouselTypeLinear = 0,
    iCarouselTypeRotary,
    iCarouselTypeInvertedRotary,
    iCarouselTypeCylinder,
    iCarouselTypeInvertedCylinder,
    iCarouselTypeCoverFlow,
    iCarouselTypeCustom
}
iCarouselType;


@protocol iCarouselMacDataSource, iCarouselMacDelegate;

@interface iCarouselMac : NSView
{
    id<iCarouselMacDelegate> delegate;
    id<iCarouselMacDataSource> dataSource;
    iCarouselType type;
    
    float perspective;
    float decelerationRate;
    
    NSInteger numberOfItems;
    NSInteger numberOfPlaceholders;
    NSInteger maxNumberOfItemsToShow;
    NSUInteger numberOfItemsShown;
    BOOL scrollEnabled;
    BOOL bounces;
    
    NSView* contentView;
    NSMutableDictionary* itemViews;
    NSInteger itemsShownIndex;
    NSMutableArray* placeholderViews;
    NSInteger previousItemIndex;
    float itemWidth;

    NSTimer* timer;
    NSTimeInterval previousTime;
    // hack.. records click (as opposed to down/drag/up) so carouselStopped: msg is not sent to delegate
    NSTimeInterval startTime;
    NSTimer* scrollWheelTimer;
    
    float scrollOffset;
    float startOffset;
    float endOffset;
    
    BOOL decelerating;
    BOOL isDragging;
    BOOL scrolling;
    float currentVelocity;
    BOOL didClick;
    
    NSTimeInterval lastTime;
}

@property (nonatomic, assign) IBOutlet id<iCarouselMacDataSource> dataSource;
@property (nonatomic, assign) IBOutlet id<iCarouselMacDelegate> delegate;
@property (nonatomic, assign) iCarouselType type;
@property (nonatomic, assign) float perspective;
@property (nonatomic, assign) float decelerationRate;
@property (nonatomic, assign) BOOL scrollEnabled;
@property (nonatomic, assign) BOOL bounces;
@property (nonatomic, readonly) NSInteger numberOfItems;
@property (nonatomic, readonly) NSInteger numberOfPlaceholders;
@property (nonatomic, assign) NSInteger maxNumberOfItemsToShow;
@property (nonatomic, readonly) NSUInteger numberOfItemsShown;
@property (nonatomic, readonly) NSInteger currentItemIndex;
@property (nonatomic, retain, readonly) NSMutableDictionary *itemViews;
@property (nonatomic, retain, readonly) NSMutableArray *placeholderViews;
@property (nonatomic, readonly) float itemWidth;

- (void)scrollToItemAtIndex:(NSUInteger)index animated:(BOOL)animated;
- (void)removeItemAtIndex:(NSUInteger)index animated:(BOOL)animated;
- (void)insertItemAtIndex:(NSUInteger)index animated:(BOOL)animated;
- (void)reloadData;

@end


@protocol iCarouselMacDataSource <NSObject>

- (NSUInteger)numberOfItemsInCarousel:(iCarouselMac *)carousel;
- (NSView *)carousel:(iCarouselMac *)carousel viewForItemAtIndex:(NSUInteger)index;

@optional

- (void)carouselRemovedView:(iCarouselMac*)carousel forIndex:(NSInteger)index;
- (NSUInteger)numberOfPlaceholdersInCarousel:(iCarouselMac *)carousel;
- (NSView *)carouselPlaceholderView:(iCarouselMac *)carousel;

@end


@protocol iCarouselMacDelegate <NSObject>

@optional

// would like to know whether user is causing the scroll or not

- (void)carouselDidScroll:(iCarouselMac *)carousel;
- (void)carouselCurrentItemIndexUpdated:(iCarouselMac *)carousel;
- (void)carouselStopped:(iCarouselMac *)carousel;
- (void)carouselCurrentItemTapped:(iCarouselMac *)carousel location:(NSPoint)location;

- (float)carouselItemWidth:(iCarouselMac *)carousel;
- (BOOL)carouselShouldWrap:(iCarouselMac *)carousel;
- (CATransform3D)carousel:(iCarouselMac *)carousel transformForItemView:(NSView *)view withOffset:(float)offset;

@end