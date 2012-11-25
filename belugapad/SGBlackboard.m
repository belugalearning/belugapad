//
//  SGBlackboard.m
//
//  Created by Gareth Jenkins on 14/06/2012.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//


#import "SGBlackboard.h"


@implementation SGBlackboard

@synthesize RenderLayer;
@synthesize inProblemSetup;
@synthesize islandData;
@synthesize MaxObjectDistance;

-(id) init
{
    if((self=[super init]))
    {
    
        [self loadData];
    }
    
    return self;
}

-(void)loadData
{

}

-(void)dealloc
{
    self.RenderLayer=nil;
    self.btxeIconBatch=nil;
    
    self.islandData=nil;
    self.debugDrawNode=nil;
    
    [super dealloc];
}



@end
