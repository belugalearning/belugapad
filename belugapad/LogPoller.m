//
//  LogPoller.m
//  belugapad
//
//  Created by Nicholas Cartwright on 21/08/2012.
//
//

#import "LogPoller.h"
#import "LogPollingProtocols.h"

@interface LogPoller()
{
    @private
    NSMutableSet *tickState;
    NSTimer *timer;
}

-(void)tick:(NSTimer*)aTimer;
-(NSString*)generateUUID;

typedef enum
{
    LP_ADD,
    LP_EXISTS,
    LP_REMOVE
} LP_POLLEE_STATUS;

typedef struct
{
    id<LogPolling,NSObject> pollee;
    LP_POLLEE_STATUS status;
    CGPoint position;
} PolleeState;
@end


@implementation LogPoller
@synthesize ticksDeltas;

-(id)init
{
    self = [super init];
    if (self)
    {
        ticksDeltas = [[NSMutableArray alloc] init];
        tickState = [[NSMutableSet alloc] init];
    }
    return self;
}

-(void)resetAndStartPolling
{
    [ticksDeltas removeAllObjects];
    [tickState removeAllObjects];
    [self resumePolling];
}

-(void)stopPolling
{
    if (timer)
    {
        [timer invalidate];
        timer = nil;
    }
}

-(void)resumePolling
{
    if (timer) [timer invalidate];
    timer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                             target:self
                                           selector:@selector(tick:)
                                           userInfo:nil
                                            repeats:YES];
}

-(void)registerPollee:(id<LogPolling,NSObject>)pollee
{
    PolleeState *ps;
    
    for (NSValue *psAddress in tickState)
    {
        ps = [psAddress pointerValue];
        if (ps->pollee == pollee)
        {
            if (ps->status == LP_REMOVE) ps->status = LP_EXISTS;
            return;
        }
    }
    
    ps = malloc(sizeof(PolleeState));
    ps->pollee = pollee;
    ps->status = LP_ADD;
    
    [tickState addObject:[NSValue valueWithPointer:ps]];
    
    if (!pollee.logPollId) pollee.logPollId = [self generateUUID];
}

-(void)unregisterPollee:(id<LogPolling>)pollee
{
    PolleeState *ps;
    
    for (NSValue *psAddress in tickState)
    {
        ps = [psAddress pointerValue];
        if (ps->pollee == pollee)
        {
            if (ps->status == LP_ADD)
            {
                [tickState removeObject:psAddress];
                free(ps);
            } else {
                ps->status = LP_REMOVE;
            }
            return;
        }
    }
}

-(void)tick:(NSTimer*)aTimer
{
    NSMutableArray *tickDelta = [NSMutableArray array];
    NSMutableSet *toRemove = [NSMutableSet set];
    
    for (NSValue *psAddress in tickState)
    {
        PolleeState *ps = [psAddress pointerValue];
        id<LogPolling,NSObject> pollee = ps->pollee;
        NSMutableDictionary *deltaPState = [NSMutableDictionary dictionary];
        
        switch (ps->status)
        {
            case LP_ADD:
                ps->status = LP_EXISTS;
                [deltaPState setValue:@"ADD" forKey:@"status"];
                [deltaPState setValue:pollee.logPollType forKey:@"type"];
                [deltaPState setValue:[NSString stringWithFormat:@"%p", pollee] forKey:@"memoryAddress"];
                
                if ([pollee conformsToProtocol:@protocol(LogPollPositioning)])
                {
                    CGPoint p = ((id<LogPollPositioning>)pollee).logPollPosition;
                    ps->position = p;
                    [deltaPState setValue:[NSNumber numberWithFloat:p.x] forKey:@"x"];
                    [deltaPState setValue:[NSNumber numberWithFloat:p.y] forKey:@"y"];
                }
                break;
            case LP_EXISTS:
                if ([pollee conformsToProtocol:@protocol(LogPollPositioning)])
                {
                    CGPoint p = ((id<LogPollPositioning>)pollee).logPollPosition;
                    if (p.x != ps->position.x)
                    {
                        [deltaPState setValue:[NSNumber numberWithFloat:p.x] forKey:@"x"];
                        ps->position.x = p.x;
                    }
                    if (p.y != ps->position.y)
                    {
                        [deltaPState setValue:[NSNumber numberWithFloat:p.y] forKey:@"y"];
                        ps->position.y = p.y;
                    }
                }
                break;
            case LP_REMOVE:
                [deltaPState setValue:@"REMOVE" forKey:@"status"];
                [toRemove addObject:psAddress];
                free(ps);
                break;
        }
        
        if ([deltaPState count])
        {
            [deltaPState setValue:pollee.logPollId forKey:@"id"];
            [tickDelta addObject:deltaPState];
        }
    }
    
    [tickState minusSet:toRemove];
    
    if ([tickDelta count])
    {
        NSNumber *date = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
        [ticksDeltas addObject:[NSDictionary dictionaryWithObjectsAndKeys:date, @"date", tickDelta, @"delta", nil]];
    }
}

-(NSString*)generateUUID
{
    CFUUIDRef UUIDRef = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef UUIDSRef = CFUUIDCreateString(kCFAllocatorDefault, UUIDRef);
    NSString *uuid = [NSString stringWithFormat:@"%@", UUIDSRef];
    
    CFRelease(UUIDRef);
    CFRelease(UUIDSRef);
    
    return uuid;
}

-(void)dealloc
{
    if (timer) [timer invalidate];
    if (ticksDeltas) [ticksDeltas release];
    if (tickState)
    {
        for (NSValue *psAddress in tickState)
        {
            PolleeState *ps = [psAddress pointerValue];
            free(ps);
        }
        [tickState release];
    }
    
    [super dealloc];
}

@end
