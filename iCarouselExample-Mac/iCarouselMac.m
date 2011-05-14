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
@property (nonatomic, retain) NSArray *itemViews;
@property (nonatomic, retain) NSArray *placeholderViews;
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
@synthesize contentView;
@synthesize itemViews;
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
    
    contentView = [[NSView alloc] initWithFrame:self.bounds];
    [contentView setWantsLayer:YES];
    contentView.layer.masksToBounds = NO;
    //    [contentView.layer setBackgroundColor:CGColorGetConstantColor(kCGColorBlack)];
    
    [self addSubview:contentView];
    
    //    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
    //    [contentView addGestureRecognizer:panGesture];
    //    [panGesture release];
    
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

- (id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame]))
    {
		[self setup];
	}
	return self;
}

- (void)setDataSource:(id<iCarouselMacDataSource>)_dataSource
{
    dataSource = _dataSource;
    [self reloadData];
}

- (void)setDelegate:(id<iCarouselMacDelegate>)_delegate
{
    delegate = _delegate;
    [self layOutItemViews];
}

- (void)setType:(iCarouselType)_type
{
    type = _type;
    [self layOutItemViews];
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

- (CATransform3D)transformForItemView:(NSView *)view withOffset:(float)offset
{    
    //set up base transform
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = perspective;
    //transform = CATransform3DTranslate(transform, -offset * itemWidth, 0, 0);
    
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
            
            
            
            //           transform = CATransform3DTranslate(transform, view.layer.bounds.size.width/2*.5, 0, 0);
            transform =  CATransform3DRotate(transform, -clampedOffset * M_PI_2 * tilt, 0, 1, 0);
            
            //            transform = CATransform3DTranslate(transform, -view.layer.bounds.size.width/2, 0, 0);
            
            //            transform = CATransform3DTranslate(transform, 0, -view.layer.bounds.size.height/2, 0);
            
            
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
    
    
    // guess i don't need this since the contentView has a layer now
    // gah, cannot get rid of border
    //   [containerView setWantsLayer:YES];
    //    containerView.layer.borderWidth = 0.0;
    //    [view setWantsLayer:YES];
    //    view.layer.borderWidth = 0.0;
    
    [containerView addSubview:view];
    
    //    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
    //    tapGesture.numberOfTapsRequired = 1;
    //    tapGesture.delegate = self;
    //    [containerView addGestureRecognizer:tapGesture];
    //    [tapGesture release];
    
    return containerView;
}

- (void)transformItemView:(NSView *)view atIndex:(NSInteger)index
{
    // NSLog(@"transforming item view at index: %ld", (long) index);
    NSLog(@"self bounds: %@", NSStringFromRect(self.bounds));
    //NSLog(@"view bounds: %@", NSStringFromRect(view.bounds));
    
    view.superview.bounds = view.bounds;
    
    
    view.frame = NSMakeRect((view.bounds.size.width-view.frame.size.width)/2.0,
                            (view.bounds.size.height-view.frame.size.height)/2.0,
                            view.frame.size.width,
                            view.frame.size.height);
    
    //NSLog(@"view frame: %@", NSStringFromRect(view.frame));
    
    // anchor point is in center of view.superview
    [view.superview setFrameOrigin:NSMakePoint((self.bounds.size.width)/2.0, (self.bounds.size.height)/2.0)];
    
    NSLog(@"superview frame: %@", NSStringFromRect(view.superview.frame));
    
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
    
    //transform view
    //view.superview.frame = NSMakeRect(view.superview.frame.origin.x + offset*itemWidth, view.superview.frame.origin.y, view.superview.frame.size.width, view.superview.frame.size.height);
    //    NSLog(@"for index %lx, frame: %@", (long) index, NSStringFromRect(view.superview.frame));
    view.superview.layer.anchorPoint = CGPointMake(.5, .5);
    
    //    NSLog(@"super bounds: %@", NSStringFromRect(view.superview.layer.bounds));
    //    NSLog(@"super frame: %@", NSStringFromRect(view.superview.layer.frame));
    //    
    //    NSLog(@"bounds: %@", NSStringFromRect(view.layer.bounds));
    //    NSLog(@"frame: %@", NSStringFromRect(view.layer.frame));
    //    
    //    NSLog(@"anchor: %@", NSStringFromPoint(NSPointFromCGPoint(view.layer.anchorPoint)));
    
    view.superview.layer.transform = [self transformForItemView:view withOffset:offset];
    [view.superview.layer removeAllAnimations];  // transform and transition
    
    //    NSLog(@"animations: %@", [view.superview.layer animationKeys]);
}

- (void) resizeSubviewsWithOldSize:(NSSize)oldSize
{
    [super resizeSubviewsWithOldSize:oldSize];
    
    contentView.frame = self.bounds;
    [self layOutItemViews];   
}

// ios only
//- (void)layoutSubviews
//{
//}

- (void)transformItemViews
{
    //NSLog(@"transform item views, scroll offset: %f", scrollOffset);
    //lay out items
    for (NSUInteger i = 0; i < numberOfItems; i++)
    {
        NSView *view = [itemViews objectAtIndex:i];
        [self transformItemView:view atIndex:i];
        
        //        view.userInteractionEnabled = (i == self.currentItemIndex);
    }
    
    //bring current view to front
    if ([itemViews count])
    {
        [contentView addSubview:[[itemViews objectAtIndex:self.currentItemIndex] superview]];
    }
    
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
    
    
    // on mac this never gets initialized, so is nan to beginwith
    if (isnan(scrollOffset))
    {
        scrollOffset = 0;
    }
    
    //adjust scroll offset
    scrollOffset = scrollOffset / prevItemWidth * itemWidth;
    
    //transform views
    [self transformItemViews];
    
    //call delegate
    if (prevItemWidth != itemWidth && [delegate respondsToSelector:@selector(carouselDidScroll:)])
    {
        [delegate carouselDidScroll:self];
    }
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
    
    //load new views
    numberOfItems = [dataSource numberOfItemsInCarousel:self];
    self.itemViews = [NSMutableArray arrayWithCapacity:numberOfItems];
    for (NSUInteger i = 0; i < numberOfItems; i++)
    {
        NSView *view = [dataSource carousel:self viewForItemAtIndex:i];
        if (view == nil)
        {
            view = [[[NSView alloc] init] autorelease];
        }
        [(NSMutableArray *)itemViews addObject:view];
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
    
    //set item width (may be overidden by delegate)
    itemWidth = [([itemViews count]? [itemViews objectAtIndex:0]: self) bounds].size.width;
    
    //layout views
    [self layOutItemViews];
}

- (NSInteger)clampedIndex:(NSInteger)index
{
    //NSLog(@"clamping index: %lx", (long)index);
    if ([self shouldWrap])
    {
        return (index + numberOfItems) % numberOfItems;
    }
    else
    {
        return MIN(MAX(index, 0), numberOfItems - 1);
    }
}

- (NSInteger)currentItemIndex
{	
    //NSLog(@"current scroll offset: %f", scrollOffset);
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
    NSView *itemView = [itemViews objectAtIndex:index];
    
    if (animated)
    {
        //        [NSView beginAnimations:nil context:nil];
        //        [NSView setAnimationCurve:NSViewAnimationCurveEaseInOut];
        //        [NSView setAnimationDuration:0.1];
        
        //        itemView.superview.alpha = 0.0;
        itemView.superview.layer.opacity = 0.0;
        //        [itemView.superview setHidden:YES];
        
        //[NSView commitAnimations];
        [itemView.superview performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.1];
        
        //        [NSView beginAnimations:nil context:nil];
        //        [NSView setAnimationCurve:NSViewAnimationCurveEaseInOut];
        //        [NSView setAnimationDuration:0.4];
    }
    else
    {
        [itemView.superview removeFromSuperview];
    }
    
    [(NSMutableArray *)itemViews removeObjectAtIndex:index];
    numberOfItems --;
    [self transformItemViews];
    
    //    if (animated)
    //    {
    //        [NSView commitAnimations];
    //    }
}

- (void)insertItemAtIndex:(NSUInteger)index animated:(BOOL)animated
{
    numberOfItems ++;
    
    NSView *itemView = [dataSource carousel:self viewForItemAtIndex:index];
    [(NSMutableArray *)itemViews insertObject:itemView atIndex:index];
    [contentView addSubview:[self containView:itemView]];
    [self transformItemView:itemView atIndex:index];
    
    //    [itemView.superview setHidden:YES];
    itemView.superview.layer.opacity = 0.0;
    //itemView.superview.alpha = 0.0;
    
    if (animated)
    {
        //        [NSView beginAnimations:nil context:nil];
        //        [NSView setAnimationCurve:NSViewAnimationCurveEaseInOut];
        //        [NSView setAnimationDuration:0.4];
        [self transformItemViews];   
        //        [NSView commitAnimations];
        //        
        //        [NSView beginAnimations:nil context:nil];
        //        [NSView setAnimationCurve:NSViewAnimationCurveEaseInOut];
        //        [NSView setAnimationDelay:0.3];
        //        [NSView setAnimationDuration:0.1];
        
        //        [itemView.superview setHidden:NO];
        itemView.superview.layer.opacity = 1.0;
        //        itemView.superview.alpha = 1.0;
        
        //        [NSView commitAnimations];
    }
    else
    {
        [self transformItemViews]; 
        //        [itemView.superview setHidden:NO];
        itemView.superview.layer.opacity = 1.0;
        //        itemView.superview.alpha = 1.0;
    }
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
    [self transformItemViews];
    if ([delegate respondsToSelector:@selector(carouselDidScroll:)])
    {
        [delegate carouselDidScroll:self];
    }
    NSInteger currentItemIndex = self.currentItemIndex;
    if (previousItemIndex != currentItemIndex && [delegate respondsToSelector:@selector(carouselCurrentItemIndexUpdated:)])
    {
        previousItemIndex = currentItemIndex;
        if (currentItemIndex > -1)
        {
            [delegate carouselCurrentItemIndexUpdated:self];
        }
    }
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

- (void) mouseDown:(NSEvent *)theEvent
{
    //NSLog(@"current index: %lx", (long) self.currentItemIndex);
    
    if (scrollEnabled)
    {
        lastTime = [theEvent timestamp];
        scrolling = NO;
        decelerating = NO;
    }
}

- (void) mouseDragged:(NSEvent *)theEvent
{
    if (scrollEnabled)
    {
        float translation = [theEvent deltaX];
        NSInteger index = round(scrollOffset / itemWidth);
        float factor = ([self shouldWrap] || (index >= 0 && index < numberOfItems))? 1.0: 0.5;
        
        NSTimeInterval thisTime = [theEvent timestamp];
        currentVelocity = (translation / (thisTime - lastTime)) * factor;
        //NSLog(@"velocity: %f", currentVelocity);
        lastTime = thisTime;
        scrollOffset -= translation * factor;
        [self didScroll];
    }
}

- (void) mouseUp:(NSEvent *)theEvent
{
    if (scrollEnabled)
    {
        decelerating = YES;
    }
}

//- (void)didPan:(UIPanGestureRecognizer *)panGesture
//{
//    if (scrollEnabled)
//    {
//        switch (panGesture.state)
//        {
//            case UIGestureRecognizerStateBegan:
//            {
//                scrolling = NO;
//                decelerating = NO;
//                previousTranslation = [panGesture translationInView:self].x;
//                break;
//            }
//            case UIGestureRecognizerStateEnded:
//            case UIGestureRecognizerStateCancelled:
//            {
//                decelerating = YES;
//            }
//            default:
//            {
//                float translation = [panGesture translationInView:self].x - previousTranslation;
//                previousTranslation = [panGesture translationInView:self].x;
//                NSInteger index = round(scrollOffset / itemWidth);
//                float factor = ([self shouldWrap] || (index >= 0 && index < numberOfItems))? 1.0: 0.5;
//                currentVelocity = [panGesture velocityInView:self].x * factor;
//                scrollOffset -= translation * factor;
//                [self didScroll];
//            }
//        }
//    }
//}

//- (void)didTap:(UITapGestureRecognizer *)tapGesture
//{
//    NSView *itemView = [tapGesture.view.subviews objectAtIndex:0];
//    NSInteger index = [itemViews indexOfObject:itemView];
//    if (index != NSNotFound)
//    {
//        [self scrollToItemAtIndex:index animated:YES];
//    }
//}
//
//- (BOOL)gestureRecognizerShouldBegin:(UITapGestureRecognizer *)tapGesture
//{
//    NSView *itemView = [tapGesture.view.subviews objectAtIndex:0];
//    NSInteger index = [itemViews indexOfObject:itemView];
//    return (index != self.currentItemIndex);
//}

#pragma mark -
#pragma mark Memory management

- (void)dealloc
{	
    [timer invalidate];
    [contentView release];
    [itemViews release];
    [placeholderViews release];
    [super dealloc];
}

@end
