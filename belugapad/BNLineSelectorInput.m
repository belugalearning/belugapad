//
//  BNLineSelectorInput.m
//  belugapad
//
//  Created by David Amphlett on 13/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BNLineSelectorInput.h"
#import "BLMath.h"
#import "global.h"
#import "DWSelectorGameObject.h"
#import "NLineConsts.h"
#import "DWRamblerGameObject.h"
#import "NLine.h"

@implementation BNLineSelectorInput

-(BNLineSelectorInput *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BNLineSelectorInput*)[super initWithGameObject:aGameObject withData:data];
    selector=(DWSelectorGameObject*)gameObject;
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    
    if(messageType==kDWsetupStuff)
    {
        
    }
    if(messageType==kDWhandleTap)
    {
        CGPoint loc=[[payload objectForKey:POS] CGPointValue];

        if([BLMath DistanceBetween:selector.pos and:loc] < kSelectorProximity)
        {
            // if the tap is on the selector - do stuff
            [self doSelection];
        }
    }
    
    if(messageType==kDWdoSelection)
    {
        [self doSelection];
    }
}

-(void)doSelection
{
    if(selectorVarPos < [selector.PopulateVariableNames count] && selector.WatchRambler.Value!=oldSelection)
    {
        if(!gameWorld.Blackboard.ProblemVariableSubstitutions) gameWorld.Blackboard.ProblemVariableSubstitutions=[[[NSMutableDictionary alloc] init] autorelease];
        
        //create a k/v pair on the gw's var sub list using the rambler's current value and the current populate var
        [gameWorld.Blackboard.ProblemVariableSubstitutions setObject:[NSNumber numberWithInt:selector.WatchRambler.Value] forKey:[selector.PopulateVariableNames objectAtIndex:selectorVarPos]]; 
        
        DLog(@"selected %f for variable %@", selector.WatchRambler.Value, [selector.PopulateVariableNames objectAtIndex:selectorVarPos]);
        
        [gameObject handleMessage:kDWrenderSelection andPayload:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:selector.WatchRambler.Value] forKey:@"VALUE"] withLogLevel:0];
        
        NSLog(@"%@", gameWorld.Blackboard.ProblemVariableSubstitutions);
        
        //next time populate the next variable
        selectorVarPos++;
        
        //if there are no more vars to populate, tell the scene the problem state changed
        if(selectorVarPos>=[selector.PopulateVariableNames count])
        {
            [[gameWorld GameScene] problemStateChanged];
        }
        
        oldSelection=selector.WatchRambler.Value;
    }
    
    else {
        DLog(@"selection var pos already exceeds variable count available");
    }
}

-(void)doUpdate:(ccTime)delta
{
    
    
}


@end
