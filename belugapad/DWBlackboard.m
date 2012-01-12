//
//  Blackboard.m
//
//  Created by Gareth Jenkins on 29/09/2011.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DWBlackboard.h"


@implementation DWBlackboard

@synthesize DropObject;
@synthesize PickupObject;
@synthesize AllStores;

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
    AllStores=[[NSMutableArray alloc] init];
}



@end
