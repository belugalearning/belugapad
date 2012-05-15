//
//  PipelineNodeSliceInstance.m
//  belugapad
//
//  Created by Gareth Jenkins on 30/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PipelineNodeSliceInstance.h"
#import "NodeSlice.h"

@implementation PipelineNodeSliceInstance

@dynamic nodeSliceId, pipeline, type;

-(id)initForNodeSlice:(NodeSlice*)nodeslice andPipeline:(NSArray*)pipeline
{
    self=[super initWithDocument:nil];
    if(self)
    {
        self.database=nodeslice.database;
        self.type=@"pipelinenodesliceinstance";
        self.nodeSliceId=nodeslice.document.documentID;
        self.pipeline=[pipeline copy];
    }
    
    return self;
}

-(NSArray*)evaluatePreRequisites
{
    //todo: return a weighted list of prerequisites and their completion state 
    return nil;
}

@end
