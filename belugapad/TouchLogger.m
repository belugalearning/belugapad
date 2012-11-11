//
//  TouchLogger.m
//  belugapad
//
//  Created by Nicholas Cartwright on 23/08/2012.
//
//

#import "TouchLogger.h"


@interface TouchLogger ()
{
    @private
    uint nextTouchIndex;
    NSMutableSet *activeTouches;
}

-(NSString*)touchPhaseToString:(UITouchPhase)phase;

// TouchVals exists to obviate NSDictionary look-ups
typedef struct
{
    NSMutableArray *events;
    CGPoint lastPoint;
} TouchVals;
@end


@implementation TouchLogger
@synthesize allTouches;

-(id)init
{
    self = [super init];
    if (self)
    {
        nextTouchIndex = 0;
        allTouches = [[NSMutableSet alloc] init];
        activeTouches = [[NSMutableSet alloc] init];
    }
    return self;
}

-(void)logTouches:(NSSet*)touches
{
    NSNumber *date = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
    NSMutableSet *unmatchedActiveTouches = [[activeTouches mutableCopy] autorelease];
    
    for (UITouch *touch in touches)
    {
        CGPoint p = [touch locationInView:touch.view];
        
        NSDictionary *e = @{
            @"date": date
            , @"phase": [self touchPhaseToString:touch.phase]
            , @"x": [NSNumber numberWithFloat:p.x]
            , @"y": [NSNumber numberWithFloat:p.y]
        };
        
        if (touch.phase == UITouchPhaseBegan) // new Touch
        {
            NSMutableArray *events = [NSMutableArray arrayWithObject:e];
            [(NSMutableSet*)allTouches addObject:@{ @"index":[NSNumber numberWithInt:nextTouchIndex++], @"events":events }];
            
            TouchVals *tv = malloc(sizeof(TouchVals));
            tv->events = events;
            tv->lastPoint = p;
            [activeTouches addObject:[NSValue valueWithPointer:tv]];
        }
        else // match the touch with a Touch & add touch to its events
        {
            CGPoint prevPos = [touch previousLocationInView:touch.view];
            float nearestDSq;
            NSValue *nearestTVAddress = nil;
            TouchVals *nearestTV = nil;
            TouchVals *tv;
            
            for (NSValue *tvAddress in unmatchedActiveTouches)
            {
                tv = [tvAddress pointerValue];
                float dX = tv->lastPoint.x - prevPos.x;
                float dY = tv->lastPoint.y - prevPos.y;
                float dSq = dX*dX + dY*dY;
                if (!nearestTV || dSq < nearestDSq)
                {
                    nearestTVAddress = tvAddress;
                    nearestTV = tv;
                    nearestDSq = dSq;
                }
            }
            if (nearestTV)
            {
                [nearestTV->events addObject:e];
                nearestTV->lastPoint = p;
                [unmatchedActiveTouches removeObject:nearestTVAddress];
                
                if (touch.phase == UITouchPhaseCancelled || touch.phase == UITouchPhaseEnded)
                {
                    [activeTouches removeObject:nearestTVAddress];
                    free(nearestTV);
                }
            }
            else
            {
                // TODO: LOG APP ERROR!! - not enough active Touches
            }
        }
    }
}

-(void)reset
{
    for (NSValue *tvAddress in activeTouches) free([tvAddress pointerValue]);
    [activeTouches removeAllObjects];
    [(NSMutableSet*)allTouches removeAllObjects];
    nextTouchIndex = 0;
}

-(NSString*)touchPhaseToString:(UITouchPhase)phase
{
    switch (phase) {
        case UITouchPhaseBegan: return @"UITouchPhaseBegan";
        case UITouchPhaseCancelled: return @"UITouchPhaseCancelled";
        case UITouchPhaseEnded: return @"UITouchPhaseEnded";
        case UITouchPhaseMoved: return @"UITouchPhaseMoved";
        case UITouchPhaseStationary: return @"UITTouchPhaseStationary";
    }
}

-(void)dealloc
{
    if (allTouches) [allTouches release];
    allTouches = nil;
    if (activeTouches)
    {
        for (NSValue *tvAddress in activeTouches) free([tvAddress pointerValue]);
        [activeTouches release];
        activeTouches = nil;
    }
    [super dealloc];
}

@end
