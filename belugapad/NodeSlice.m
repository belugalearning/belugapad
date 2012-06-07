//
//  NodeSlice.m
//  belugapad
//
//  Created by Gareth Jenkins on 30/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NodeSlice.h"
#import "User.h"
#import "ConceptNode.h"



@interface NodeSlice()
{
    @private
    
}

-(void)populdateNodeWithPipelineId:(NSString *)pipelineId;

@end


@implementation NodeSlice

@dynamic userId, nodeId, pipelines, type;

-(id)initAndPopulateNodeSliceForUser:(User*)user andNode:(ConceptNode*)node
{
    self=[super initWithDocument:nil];
    if(self)
    {
        self.database=user.database;
        self.type=@"nodeslice";
        self.userId=user.document.documentID;
        self.nodeId=node._id;
        
        [self populateNode];
    }
    
    return self;
}

-(void)populdateNodeWithPipelineId:(NSString *)pipelineId
{
    if(self.pipelines.count==0)
    {
        //do the population specified
    }
    else {
        //do analysis based population
        [self populateNode];
    }
}

-(void)populateNode
{
    //todo: do analysis and populate
}



@end
