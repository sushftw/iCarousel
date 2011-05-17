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
    NSInteger numberOfItems;
    NSInteger numberOfPlaceholders;
    NSInteger maxNumberOfItemsToShow;
    
    NSView* contentView;
    NSMutableDictionary* itemViews;
    NSCache* itemViewCache;
    NSInteger itemsShownIndex;
    NSMutableArray* placeholderViews;
    NSInteger previousItemIndex;

    float currentVelocity;
    NSTimer* timer;
    NSTimeInterval previousTime;
    BOOL decelerating;
    BOOL scrollEnabled;
    float decelerationRate;
    BOOL bounces;
    BOOL isDragging;
    NSTimeInterval startTime;
    float previousTranslation;
    NSTimer* scrollWheelTimer;
    
    
    float itemWidth;
    float scrollOffset;
    float startOffset;
    float endOffset;
    BOOL scrolling;
    
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

- (NSUInteger)numberOfPlaceholdersInCarousel:(iCarouselMac *)carousel;
- (NSView *)carouselPlaceholderView:(iCarouselMac *)carousel;

@end


@protocol iCarouselMacDelegate <NSObject>

@optional

- (void)carouselDidScroll:(iCarouselMac *)carousel;
- (void)carouselCurrentItemIndexUpdated:(iCarouselMac *)carousel;
- (void)carouselStopped:(iCarouselMac *)carousel;

- (float)carouselItemWidth:(iCarouselMac *)carousel;
- (BOOL)carouselShouldWrap:(iCarouselMac *)carousel;
- (CATransform3D)carousel:(iCarouselMac *)carousel transformForItemView:(NSView *)view withOffset:(float)offset;

@end