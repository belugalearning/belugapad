//
//  UIView+UIView_DragLogPosition.m
//  belugapad
//
//  Created by Nicholas Cartwright on 20/11/2012.
//
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "UIView+UIView_DragLogPosition.h"

static char startPanCentreKey;

@implementation UIView (UIView_DragLogPosition)

-(void)registerForDragAndLog
{
    self.userInteractionEnabled = YES;
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [panRecognizer setMinimumNumberOfTouches:1];
    [panRecognizer setMaximumNumberOfTouches:1];
    [self addGestureRecognizer:panRecognizer];
    [panRecognizer release];
}

-(void)handlePan:(id)sender
{
    if([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateBegan) self.startPanCentre = @[@(self.center.x), @(self.center.y)];
    
    CGPoint translation = [(UIPanGestureRecognizer*)sender translationInView:self.superview];
    
    [self setCenter:CGPointMake([self.startPanCentre[0] floatValue] + translation.x, [self.startPanCentre[1] floatValue] + translation.y)];
    
    if([(UIPanGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) NSLog(@"origin:[%f,%f]   centre:[%f,%f]", self.frame.origin.x, self.frame.origin.y, [self.startPanCentre[0] floatValue] + translation.x, [self.startPanCentre[1] floatValue] + translation.y);
}

-(NSArray*)startPanCentre
{
    return objc_getAssociatedObject(self, &startPanCentreKey);
}

-(void)setStartPanCentre:(NSArray*)point
{
    objc_setAssociatedObject(self, &startPanCentreKey, point, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(void)dealloc
{
    objc_setAssociatedObject(self, &startPanCentreKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [super dealloc];
}

@end