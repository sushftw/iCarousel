//
//  iCarouselMac.m
//  iCarouselExample
//
//  Created by Sushant Prakash on 5/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "iCarouselMac.h"
#import <math.h>

@interface iCarouselMac ()

@property (nonatomic, retain) NSView *contentView;
@property (nonatomic, retain) NSMutableArray *itemViews;
@property (nonatomic, assign) NSInteger itemsShownIndex;
@property (nonatomic, retain) NSMutableArray *placeholderViews;
@property (nonatomic, assign) NSInteger previousItemIndex;
@property (nonatomic, assign) float itemWidth;
@property (nonatomic, assign) float scrollOffset;
@property (nonatomic, assign) float startOffset;
@property (nonatomic, assign) float endOffset;
@property (nonatomic, assign) BOOL scrolling;
@property (nonatomic, assign) NSTimeInterval startTime;
@property (nonatomic, assign) float currentVelocity;
@property (nonatomic, assign) NSTimer *timer;
@property (nonatomic, assign) NSTimeInterval previousTime;
@property (nonatomic, assign) BOOL decelerating;
@property (nonatomic, assign) float previousTranslation;


- (void)syncViews;
- (void)layOutItemViews;
- (void)transformItemView:(NSView *)view atIndex:(NSInteger)index;
- (BOOL)shouldWrap;
- (void)didScroll;

@end


@implementation iCarouselMac

@synthesize dataSource;
@synthesize delegate;
@synthesize type;
@synthesize perspective;
@synthesize numberOfItems;
@synthesize numberOfPlaceholders;
@synthesize maxNumberOfItemsToShow;
@synthesize contentView;
@synthesize itemViews;
@synthesize itemsShownIndex;
@synthesize placeholderViews;
@synthesize previousItemIndex;
@synthesize itemWidth;
@synthesize scrollOffset;
@synthesize currentVelocity;
@synthesize timer;
@synthesize previousTime;
@synthesize decelerating;
@synthesize scrollEnabled;
@synthesize decelerationRate;
@synthesize bounces;
@synthesize startOffset;
@synthesize endOffset;
@synthesize startTime;
@synthesize scrolling;
@synthesize previousTranslation;

- (void)setup
{
    // not sure if this is necessary
    [self setAcceptsTouchEvents:YES];
    
    perspective = -1.0/500.0;
    decelerationRate = 0.9;
    scrollEnabled = YES;
    bounces = YES;
    
    itemViews = [[NSMutableDictionary dictionary] retain];
    itemViewCache = [[NSCache alloc] init];
    maxNumberOfItemsToShow = INT_MAX;
    itemsShownIndex = 0;
    scrollOffset = 0;
    
    contentView = [[NSView alloc] initWithFrame:self.bounds];
    [contentView setWantsLayer:YES];
    contentView.layer.masksToBounds = NO;

    [self addSubview:contentView];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0/60.0 target:self selector:@selector(step) userInfo:nil repeats:YES];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{	
	if ((self = [super initWithCoder:aDecoder]))
    {
		[self setup];
        [self reloadData];
	}
	return self;
}

- (id)initWithFrame:(NSRect)frame
{
	if (((self = [super initWithFrame:frame])))
    {
		[self setup];
	}
	return self;
}

- (void)setDataSource:(id<iCarouselMacDataSource>)_dataSource
{
    if (dataSource == _dataSource)
    {
        return;
    }
    dataSource = _dataSource;
    [self reloadData];
}

- (void)setDelegate:(id<iCarouselMacDelegate>)_delegate
{
    if (delegate == _delegate)
    {
        return;
    }
    delegate = _delegate;
    [self syncViews]; // wrap change can change cards that are shown
}

- (void)setType:(iCarouselType)_type
{
    if (type == _type)
    {
        return;
    }
    type = _type;
    [self syncViews]; // wrap change can change the cards that are shown
}

- (void) setMaxNumberOfItemsToShow:(NSInteger)_maxNumberOfItemsToShow
{
    if (maxNumberOfItemsToShow == _maxNumberOfItemsToShow)
    {
        return;
    }
    
    maxNumberOfItemsToShow = _maxNumberOfItemsToShow;
    [self syncViews];
}

- (BOOL)shouldWrap
{
    if ([delegate respondsToSelector:@selector(carouselShouldWrap:)])
    {
        return [delegate carouselShouldWrap:self];
    }
    switch (type)
    {
        case iCarouselTypeRotary:
        case iCarouselTypeInvertedRotary:
        case iCarouselTypeCylinder:
        case iCarouselTypeInvertedCylinder:
            return YES;
        default:
            return NO;
    }
}

- (NSInteger)clampedIndex:(NSInteger)index
{
    if ([self shouldWrap])
    {
        return (index + numberOfItems) % numberOfItems;
    }
    else
    {
        return MIN(MAX(index, 0), numberOfItems - 1);
    }
}

- (CATransform3D)transformForItemView:(NSView *)view withOffset:(float)offset
{    
    //set up base transform
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = perspective;
    
    //perform transform
    switch (type)
    {
        case iCarouselTypeLinear:
        {
            return CATransform3DTranslate(transform, offset * itemWidth, 0, 0);
        }
        case iCarouselTypeRotary:
        case iCarouselTypeInvertedRotary:
        {
            float arc = M_PI * 2.0;
            float radius = itemWidth / 2.0 / tan(arc/2.0/numberOfItems);
            float angle = offset / numberOfItems * arc;
            
            if (type == iCarouselTypeInvertedRotary)
            {
                view.layer.doubleSided = NO;
                radius = -radius;
                angle = -angle;
            }
            
            return CATransform3DTranslate(transform, radius * sin(angle), 0, radius * cos(angle) - radius);
        }
        case iCarouselTypeCylinder:
        case iCarouselTypeInvertedCylinder:
        {
            float arc = M_PI * 2.0;
            float radius = itemWidth / 2.0 / tan(arc/2.0/numberOfItems);
            float angle = offset / numberOfItems * arc;
            
            if (type == iCarouselTypeInvertedCylinder)
            {
                view.layer.doubleSided = NO;
                radius = -radius;
                angle = -angle;
            }
            
            transform = CATransform3DTranslate(transform, 0, 0, -radius);
            transform = CATransform3DRotate(transform, angle, 0, 1, 0);
            return CATransform3DTranslate(transform, 0, 0, radius);
        }
        case iCarouselTypeCoverFlow:
        {
            float tilt = 0.9;
            float spacing = 0.25;
            
            float clampedOffset = fmax(-1.0, fmin(1.0, offset));
            float x = (clampedOffset * 0.5 * tilt + offset * spacing) * itemWidth;
            float z = fabs(clampedOffset) * -itemWidth * 0.5;
            
            transform = CATransform3DTranslate(transform, x, 0, z);
            
            transform =  CATransform3DRotate(transform, -clampedOffset * M_PI_2 * tilt, 0, 1, 0);
            
            
            return transform;
        }
        case iCarouselTypeCustom:
        default:
        {
            return [delegate carousel:self transformForItemView:view withOffset:offset];
        }
    }
}

- (NSView *)containView:(NSView *)view
{
    NSView *containerView = [[[NSView alloc] initWithFrame:view.frame] autorelease];
    
    [containerView addSubview:view];
    
    return containerView;
}

- (void)transformItemView:(NSView *)view atIndex:(NSInteger)index
{
    view.superview.bounds = view.bounds;
    
    [view setFrameOrigin:NSMakePoint((view.bounds.size.width-view.frame.size.width)/2.0, (view.bounds.size.height-view.frame.size.height)/2.0)];
    
    [view.superview setFrameOrigin:NSMakePoint((self.bounds.size.width)/2.0, (self.bounds.size.height)/2.0)];
    
    view.superview.layer.anchorPoint = CGPointMake(.5, .5);
    
    //calculate relative position
    float itemOffset = scrollOffset / itemWidth;
    float offset = index - itemOffset;
    if ([self shouldWrap])
    {
        if (offset > numberOfItems/2)
        {
            offset -= numberOfItems;
        }
        else if (offset < -numberOfItems/2)
        {
            offset += numberOfItems;
        }
    }
    
    view.superview.layer.transform = [self transformForItemView:view withOffset:offset];
    // remove transform and transition animations
    [view.superview.layer removeAllAnimations];  
}

- (void) resizeSubviewsWithOldSize:(NSSize)oldSize
{
    [super resizeSubviewsWithOldSize:oldSize];
    
    contentView.frame = self.bounds;
    [self layOutItemViews];   
}


- (void)transformItemViews
{
    //lay out items
    for (NSNumber* index in itemViews)
    {
        NSView *view = [itemViews objectForKey:index];
        [self transformItemView:view atIndex:[index unsignedIntegerValue]];
    }

    // sushftw: not sure this is necessary
    //bring current view to front
//    if ([itemViews count])
//    {
//        [contentView addSubview:[itemViews objectForKey:[NSNumber numberWithUnsignedInteger:self.currentItemIndex]]];
//    }
    
    //lay out placeholders
    for (NSInteger i = 0; i < numberOfPlaceholders; i++)
    {
        NSView *view = [placeholderViews objectAtIndex:i];
        [self transformItemView:view atIndex:-(i+1)];
    }
    for (NSInteger i = 0; i < numberOfPlaceholders; i++)
    {
        NSView *view = [placeholderViews objectAtIndex:i + numberOfPlaceholders];
        [self transformItemView:view atIndex:i + numberOfItems];
    }
}

- (void)layOutItemViews
{
    //record current item width
    float prevItemWidth = itemWidth;
    
    //set scrollview size
    if ([delegate respondsToSelector:@selector(carouselItemWidth:)])
    {
        itemWidth = [delegate carouselItemWidth:self];
    }
    else
    {
        itemWidth = [([itemViews count]? [[itemViews allValues] lastObject]: self) bounds].size.width;
    }
    
    
    //adjust scroll offset
    if (prevItemWidth > 0)
    {
        scrollOffset = scrollOffset / prevItemWidth * itemWidth;
    }
    
    //transform views
    [self transformItemViews];
    
    // sushftw: i don't think changing width should count as scrolling
//    if (prevItemWidth != itemWidth && [delegate respondsToSelector:@selector(carouselDidScroll:)])
//    {
//        [delegate carouselDidScroll:self];
//    }
}

- (void) syncViews
{        
    // set of all pages needed in buffer
	NSMutableSet *newViews = [NSMutableSet set];
    NSInteger numberOfItemsToShow = MIN(self.numberOfItems, self.maxNumberOfItemsToShow);
	for(NSInteger i = 0; i < numberOfItemsToShow; i++)
	{
        NSInteger index = [self clampedIndex:(self.currentItemIndex - numberOfItemsToShow/2 + i)];
        [newViews addObject:[NSNumber numberWithUnsignedInteger:index]];
	}
	
	// keys of cards to remove
	NSMutableArray *toRemove = [NSMutableArray array];
	for(NSNumber *cardDisplayed in itemViews)
	{
		if(![newViews containsObject:cardDisplayed])
		{
			[toRemove addObject:cardDisplayed];
		} 
		else
		{
			[newViews removeObject:cardDisplayed]; //already displayed
		}
	}
	
	// do this outside previous loop to avoid mutation while enumerating
	for(NSNumber* rem in toRemove)
	{
        NSView* view = [itemViews objectForKey:rem];
        [view.superview removeFromSuperview];
        [itemViews removeObjectForKey:rem];
	}
	
	// setup cards for those needing to be displayed
	for(NSNumber *viewToDisplay in newViews)
	{
        NSView* view = [itemViewCache objectForKey:viewToDisplay];
        if (view == nil)
        {
            view = [dataSource carousel:self viewForItemAtIndex:[viewToDisplay unsignedIntegerValue]];
            [itemViewCache setObject:view forKey:viewToDisplay];
        }
        if (view == nil)
        {
            view = [[[NSView alloc] init] autorelease];
        }
        [itemViews setObject:view forKey:viewToDisplay];
        [contentView addSubview:[self containView:view]];
    }
    
    
    //load placeholders
    if ([dataSource respondsToSelector:@selector(numberOfPlaceholdersInCarousel:)])
    {
        numberOfPlaceholders = [dataSource numberOfPlaceholdersInCarousel:self];
        self.placeholderViews = [NSMutableArray arrayWithCapacity:numberOfPlaceholders * 2];
        for (NSUInteger i = 0; i < numberOfPlaceholders * 2; i++)
        {
            NSView *view = [dataSource carouselPlaceholderView:self];
            if (view == nil)
            {
                view = [[[NSView alloc] init] autorelease];
            }
            [(NSMutableArray *)placeholderViews addObject:view];
            [contentView addSubview:[self containView:view]];
        }
    }
    
    self.itemsShownIndex = self.currentItemIndex;
    
    //layout views
    [self layOutItemViews];
}

- (void)reloadData
{
    //remove old views
    for (NSView *view in itemViews)
    {
        [view.superview removeFromSuperview];
    }
    for (NSView *view in placeholderViews)
    {
        [view.superview removeFromSuperview];
    }
    
    [itemViewCache removeAllObjects];
    
    [self.itemViews removeAllObjects];
    [self.placeholderViews removeAllObjects];
    
    numberOfItems = [dataSource numberOfItemsInCarousel:self];
    
    [self syncViews];
}

- (NSInteger)currentItemIndex
{	
    return [self clampedIndex:round(scrollOffset / itemWidth)];
}


- (void)scrollToItemAtIndex:(NSUInteger)index animated:(BOOL)animated
{	
    index = [self clampedIndex:index];
    previousItemIndex = self.currentItemIndex;
    if ([self shouldWrap] && previousItemIndex == 0 && index == numberOfItems - 1)
    {
        scrollOffset = itemWidth * numberOfItems;
        
    }
    else if ([self shouldWrap] && index == 0 && previousItemIndex == numberOfItems - 1)
    {
        scrollOffset = -itemWidth;
    }
    
    if (animated)
    {
        scrolling = YES;
        startTime = [[NSProcessInfo processInfo] systemUptime];
        startOffset = scrollOffset;
        endOffset = itemWidth * index;
    }
    else
    {
        scrollOffset = itemWidth * index;
        [self didScroll];
    }
}

- (void)removeItemAtIndex:(NSUInteger)index animated:(BOOL)animated
{
    [self reloadData];
    // sushftw: the efficient thing to do would be to change the cache entries
    // for all indexes > index, then call syncViews
    
//    numberOfItems --;
//    
//    
//    if (animated)
//    {
//        //        [NSView beginAnimations:nil context:nil];
//        //        [NSView setAnimationCurve:NSViewAnimationCurveEaseInOut];
//        //        [NSView setAnimationDuration:0.1];
//        
//        //        itemView.superview.alpha = 0.0;
//        itemView.superview.layer.opacity = 0.0;
//        //        [itemView.superview setHidden:YES];
//        
//        //[NSView commitAnimations];
//        [itemView.superview performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.1];
//        
//        //        [NSView beginAnimations:nil context:nil];
//        //        [NSView setAnimationCurve:NSViewAnimationCurveEaseInOut];
//        //        [NSView setAnimationDuration:0.4];
//    }
//    else
//    {
//        [itemView.superview removeFromSuperview];
//    }
//    
//    [itemViews removeObjectForKey:indexKey];
//    [self transformItemViews];
//    
//    //    if (animated)
//    //    {
//    //        [NSView commitAnimations];
//    //    }
}


- (void)insertItemAtIndex:(NSUInteger)index animated:(BOOL)animated
{
    [self reloadData];
    // sushftw: the efficient thing to do would be to change the cache entries
    // for all indexes >= index, then call syncViews
    
//    numberOfItems ++;
//    
//    
//    NSView *itemView = [dataSource carousel:self viewForItemAtIndex:index];
//    [(NSMutableArray *)itemViews insertObject:itemView atIndex:arrayIndex];
//    [contentView addSubview:[self containView:itemView]];
//    [self transformItemView:itemView atIndex:index];
//    
//    //    [itemView.superview setHidden:YES];
//    itemView.superview.layer.opacity = 0.0;
//    //itemView.superview.alpha = 0.0;
//    
//    if (animated)
//    {
//        //        [NSView beginAnimations:nil context:nil];
//        //        [NSView setAnimationCurve:NSViewAnimationCurveEaseInOut];
//        //        [NSView setAnimationDuration:0.4];
//        [self transformItemViews];   
//        //        [NSView commitAnimations];
//        //        
//        //        [NSView beginAnimations:nil context:nil];
//        //        [NSView setAnimationCurve:NSViewAnimationCurveEaseInOut];
//        //        [NSView setAnimationDelay:0.3];
//        //        [NSView setAnimationDuration:0.1];
//        
//        //        [itemView.superview setHidden:NO];
//        itemView.superview.layer.opacity = 1.0;
//        //        itemView.superview.alpha = 1.0;
//        
//        //        [NSView commitAnimations];
//    }
//    else
//    {
//        [self transformItemViews]; 
//        //        [itemView.superview setHidden:NO];
//        itemView.superview.layer.opacity = 1.0;
//        //        itemView.superview.alpha = 1.0;
//    }
}

- (void)didMoveToSuperview
{
    [self reloadData];
}

- (void)didScroll
{	
    if ([self shouldWrap])
    {
        float contentWidth = numberOfItems * itemWidth;
        if (scrollOffset < -itemWidth/2)
        {
            scrollOffset += contentWidth;
        }
        else if (scrollOffset >= contentWidth - itemWidth/2)
        {
            scrollOffset -= contentWidth;
        }
    }
    else if (!bounces)
    {
        scrollOffset = fmin(fmax(0.0, scrollOffset), numberOfItems * itemWidth - itemWidth);
    }
    if ([delegate respondsToSelector:@selector(carouselDidScroll:)])
    {
        [delegate carouselDidScroll:self];
    }
    NSInteger currentItemIndex = self.currentItemIndex;
    
    if (previousItemIndex != currentItemIndex)
    {
        previousItemIndex = currentItemIndex;
        if (currentItemIndex > -1 && [delegate respondsToSelector:@selector(carouselCurrentItemIndexUpdated:)])
        {
            [delegate carouselCurrentItemIndexUpdated:self];
        }
    }
    
    [self syncViews];
}

- (void)step
{
    NSTimeInterval currentTime = [[NSProcessInfo processInfo] systemUptime];
    NSTimeInterval deltaTime = currentTime - previousTime;
    previousTime = currentTime;
    
    if (scrolling)
    {
        NSTimeInterval time = (currentTime - startTime ) / 0.4;
        if (time >= 1.0)
        {
            time = 1.0;
            scrolling = NO;
        }
        float delta = (time < 0.5f)? 0.5f * pow(time * 2.0, 3.0): 0.5f * pow(time * 2.0 - 2.0, 3.0) + 1.0; //ease in/out
        scrollOffset = startOffset + (endOffset - startOffset) * delta;
        [self didScroll];
        if (scrolling == NO && [delegate respondsToSelector:@selector(carouselStopped:)])
        {
            [delegate carouselStopped:self];
        }
    }
    else if (decelerating)
    {
        float index = self.currentItemIndex;
        float offset = index - scrollOffset/itemWidth;
        float force = pow(offset, 2.0);
        force = fmin(force, 2.5);
        if (offset < 0)
        {
            force = - force;
        }
        
        currentVelocity -= force*itemWidth/2;
        currentVelocity *= decelerationRate;
        scrollOffset -= currentVelocity * deltaTime;
        if (fabs(currentVelocity) < itemWidth*0.5 && fabs(offset) < itemWidth*0.5)
        {
            decelerating = NO;
            [self scrollToItemAtIndex:index animated:YES];
        }
        [self didScroll];
    }
}

- (void) userStartedTranslating:(NSTimeInterval)timestamp
{
    if (scrollEnabled)
    {
        isDragging = YES;
        lastTime = timestamp;
        scrolling = NO;
        decelerating = NO;
    }
}

- (void) userFinishedTranslating
{
    if (scrollEnabled)
    {
        isDragging = NO;
        decelerating = YES;
    }
}

// theEvent can be from mouseDragged or scrollWheel
- (void) translateCarousel:(float)translation timestamp:(NSTimeInterval)thisTime
{
    if (scrollEnabled)
    {
        NSInteger index = round(scrollOffset / itemWidth);
        float factor = ([self shouldWrap] || (index >= 0 && index < numberOfItems))? 1.0: 0.5;
        
        currentVelocity = (translation / (thisTime - lastTime)) * factor;
        lastTime = thisTime;
        
        scrollOffset -= translation * factor;
        [self didScroll];
    }
}

- (void) mouseDown:(NSEvent *)theEvent
{    
    [self userStartedTranslating:[theEvent timestamp]];
}

- (void) mouseUp:(NSEvent *)theEvent
{
    [self userFinishedTranslating];
}

- (void) mouseDragged:(NSEvent *)theEvent
{
    [self translateCarousel:[theEvent deltaX] timestamp:[theEvent timestamp]];
}

#define ScrollWheelTranslationMultiplier 30.0
#define ScrollWheelOffDelay 0.1

- (void) scrollWheelFinished:(NSTimer*)theTimer
{
    scrollWheelTimer = nil;
    [self userFinishedTranslating];
}

- (void)scrollWheel:(NSEvent *)theEvent
{
    [scrollWheelTimer invalidate];
    scrollWheelTimer = nil;
    
    if (!isDragging)
    {
        [self userStartedTranslating:[theEvent timestamp]];
    }
    else
    {
        [self translateCarousel:(ScrollWheelTranslationMultiplier*[theEvent deltaY]) timestamp:[theEvent timestamp]];
    }
    
    scrollWheelTimer = [NSTimer scheduledTimerWithTimeInterval:ScrollWheelOffDelay target:self selector:@selector(scrollWheelFinished:) userInfo:nil repeats:NO];
}


#pragma mark -
#pragma mark Memory management

- (void)dealloc
{	
    [timer invalidate];
    [contentView release];
    [itemViews release];
    [itemViewCache release];
    [placeholderViews release];
    [super dealloc];
}

@end
