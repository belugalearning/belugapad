//
//  AdpRepeatProblemInserter.m
//  belugapad
//
//  Created by gareth on 04/09/2012.
//
//

#import "AdpRepeatProblemInserter.h"
#import "ContentService.h"

@implementation AdpRepeatProblemInserter

-(void)buildInserts
{
    //if this problem has dvars, repeat it
    
    NSArray *dvars=[contentService.currentPDef objectForKey:@"DVARS"];
    if(dvars)
    {
        if(dvars.count>0)
        {
            //there are some dvars defined, assume this problem is dynamic & re-insert
            [self.viableInserts addObject:@{@"PROBLEM_ID" :[contentService.currentEpisode objectAtIndex:contentService.episodeIndex]}];
            
            //todo: add the avoid dvars stuff to this -- e.g. to prevent repeating with same values if possible
        }
    }
}

@end
