//
//  AdpRepeatThisPipelineInserter.m
//  belugapad
//
//  Created by gareth on 03/09/2012.
//
//

#import "AdpRepeatThisPipelineInserter.h"
#import "ContentService.h"
#import "Pipeline.h"
#import "Problem.h"

@implementation AdpRepeatThisPipelineInserter

-(void)buildInserts
{
    int insMax=[[adplineSettings objectForKey:@"INSERTER_REPEAT_PROBLEM_COUNT"] intValue];

    //check there is at least one previous
    if(contentService.pipelineIndex > 0)
    {
        //repeat those in order, going backwards from current index (and inserting at front)
        for(int i=contentService.pipelineIndex-1; i>=0 && (contentService.pipelineIndex-i)<=insMax; i--)
        {
            Problem *p=[contentService.currentPipeline.flattenedProblems objectAtIndex:i];
            [self.viableInserts insertObject:@{@"PROBLEM_ID" : p._id} atIndex:0];
        }
        
        if(contentService.pipelineIndex < insMax)
            [self.decisionInformation setObject:[NSNumber numberWithInt:insMax-contentService.pipelineIndex] forKey:@"INSERT_TRUNCATED_BY"];
    }
    else
    {
        //write some diecision data about this
        [self.decisionInformation setObject:[NSNumber numberWithInt:contentService.pipelineIndex] forKey:@"CANNOT_INSERT_WITH_PIPELINE_INDEX"];
    }

}

@end
