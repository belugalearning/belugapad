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
    NSMutableSet *allTouches;
    NSMutableSet *activeTouches;
}

-(NSString*)touchPhaseToString:(UITouchPhase)phase;

// TouchVals exists to obviate NSDictionary look-ups thus improving performance
typedef struct
{
    NSMutableArray *events;
    CGPoint lastPoint;
} TouchVals;
@end


@implementation TouchLogger

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
    // Touch: id/index + events
    
    NSNumber *date = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
    NSMutableSet *unmatchedActiveTouches = [[activeTouches mutableCopy] autorelease];
    
    for (UITouch *touch in touches)
    {
        CGPoint p = [touch locationInView:nil];
        NSDictionary *e = @{
            @"date": date
            , @"phase": [self touchPhaseToString:touch.phase]
            , @"x": [NSNumber numberWithFloat:p.x]
            , @"y": [NSNumber numberWithFloat:p.y]
        };
        
        if (touch.phase == UITouchPhaseBegan) // new Touch
        {
            NSMutableArray *events = [NSMutableArray arrayWithObject:e];
            NSDictionary *Touch = @{ @"index":[NSNumber numberWithInt:nextTouchIndex++], @"events":events };
            [allTouches addObject:Touch];
            
            TouchVals *tv = malloc(sizeof(TouchVals));
            tv->events = events;
            tv->lastPoint = p;
            [activeTouches addObject:[NSValue valueWithPointer:tv]];
        }
        else // match the touch with a Touch & add touch to its events
        {
            CGPoint prevPos = [touch previousLocationInView:nil];
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
                [tv->events addObject:e];
                tv->lastPoint = p;
                [unmatchedActiveTouches removeObject:nearestTVAddress];
                
                if (touch.phase == UITouchPhaseCancelled || touch.phase == UITouchPhaseEnded)
                {
                    [activeTouches removeObject:nearestTVAddress];
                    free(nearestTVAddress);
                }
            }
            else
            {
                // TODO: LOG APP ERROR!! - not enough active Touches
            }
        }
    }
}

-(NSSet*)flush
{
    NSSet *Touches = [[allTouches copy] autorelease];
    [allTouches removeAllObjects];
    for (NSValue *tvAddress in activeTouches)
    {
        TouchVals *tv = [tvAddress pointerValue];
        free(tv);
    }
    [activeTouches removeAllObjects];
    nextTouchIndex = 0;
    return Touches;
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
    if (activeTouches)
    {
        for (NSValue *tvAddress in activeTouches)
        {
            TouchVals *tv = [tvAddress pointerValue];
            free(tv);
        }
        [activeTouches release];
    }
    [super dealloc];
}

@end
